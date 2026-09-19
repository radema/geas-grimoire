---
name: quality-analysis
description: Structured Gold-table quality investigation for Delta Lake / Databricks Lakehouse pipelines. Use when investigating unexpected NULLs, NaN/Inf values, ghost rows, join coverage gaps, domain violations, or any data-value anomaly in a Gold layer table. Takes a table name and year range as input, produces a structured findings file with file references and bug classifications.
---

# Quality Analysis Skill

Produces a structured findings report for a Gold layer table. The investigation pattern was validated and refined through a structured retrospective (`<TICKET-ID>`, 4 workflows, 14 failure modes identified). Null handling decisions are governed by the council-reviewed policy in `docs/wiki/data_quality/null_policy.md`.

## Scope boundary

Use for **value anomalies** — unexpected NULL/NaN/Inf, ghost rows, join-coverage gaps, domain violations in a Gold table. For whether a KPI's formula matches its canonical definition, use the `assess-indicator` skill instead.

**Input required:**

- `TABLE_NAME` — fully-qualified Gold table (e.g. `catalog.gold.my_table_y`)
- `YEAR_RANGE` — years to examine (e.g. `2021-2024`)
- `PARTITION_KEY` — the column used to group quality checks (default: `year`; for time-series tables add a secondary grouping dimension such as region or entity)
- `COLUMNS_OF_INTEREST` — optional; if omitted, check all non-key numeric columns

**Output:** a `findings-<workflow>.md` file in the tracker folder, structured identically to prior findings files (e.g. `<tracker-folder>/<ticket>/findings-<workflow>.md`).

---

## Phase 1 — Surface Scan

Run the following SQL for each year in YEAR_RANGE, grouped by `year` AND the relevant partition key (e.g. region, category). Use Databricks MCP (`databricks-mcp-sql` skill) or a notebook.

```sql
-- 1. Per-column quality profile
SELECT
  year,
  <partition_key>,
  COUNT(*) AS total_rows,
  -- Repeat the block below for each metric column:
  SUM(CASE WHEN <col> IS NULL                                           THEN 1 ELSE 0 END) AS <col>_nulls,
  SUM(CASE WHEN isnan(<col>)                                            THEN 1 ELSE 0 END) AS <col>_nans,
  SUM(CASE WHEN <col> IN (CAST('inf' AS DOUBLE), CAST('-inf' AS DOUBLE)) THEN 1 ELSE 0 END) AS <col>_infs,
  ROUND(STDDEV(<col>), 4) AS <col>_stddev,
  MIN(<col>)              AS <col>_min,
  MAX(<col>)              AS <col>_max
FROM <TABLE_NAME>
WHERE year BETWEEN '<year_start>' AND '<year_end>'
GROUP BY year, <partition_key>
ORDER BY year, <partition_key>;

-- 2. Ghost rows (entity key is NULL)
SELECT year, COUNT(*) AS ghost_rows
FROM <TABLE_NAME>
WHERE <primary_key_col> IS NULL
GROUP BY year;

-- 3. Entity count per year (compare against dimension table)
SELECT year, COUNT(DISTINCT <primary_key_col>) AS distinct_entities
FROM <TABLE_NAME>
GROUP BY year ORDER BY year;
```

**Triage signals:**

| Signal                                                      | Interpretation                                      |
| ----------------------------------------------------------- | --------------------------------------------------- |
| `stddev > 0` AND `nulls > 0` for same year/partition        | Some data exists → investigate why rows are NULL    |
| `stddev = 0`, `min = max = 0`, prior years had `stddev > 0` | Likely `ZERO_MASKING` — absent source masked as 0   |
| `ghost_rows > 0`                                            | `GHOST_ROW` — Delta merge without post-write DELETE |
| `nans > 0` or `infs > 0`                                    | NaN/Inf guard missing (see council Decision 2)      |
| Column all-NULL but related columns non-NULL                | `MISSING_FILLNA_COLUMN` or `RATIO_BEFORE_FILLNA`    |
| Entity count drops vs dimension table count                 | `JOIN_YEAR_LOSS` or `TYPE_MISMATCH_JOIN`            |

> **Council note (Decision 2):** `NaN ≠ NULL` in Spark. `safe_div(0, 0)` returns `NaN`, not `Inf`. `IS NULL` does **not** catch `NaN`. A `nans > 0` result means the NaN guard is missing — it must run as a separate step before the Inf guard.

---

## Phase 2 — Source Coverage Check

For each upstream table (silver, staging, or external) that feeds TABLE_NAME:

```sql
SELECT year, COUNT(*) AS source_rows
FROM <upstream_catalog>.<schema>.<table>
GROUP BY year ORDER BY year;
```

Decision rule:

- Silver has 0 rows for a year AND Gold has 100% NULLs → **expected absence**; do not flag
- Silver has rows for a year AND Gold has unexpected NULLs → **investigate the pipeline**
- Source row count ≠ Gold entity count → potential `JOIN_YEAR_LOSS` or `DIMENSION_GAP`

---

## Phase 3 — Pipeline Trace

Trace each affected column end-to-end through the preparation code:

### 3a — Join stage (`00_gold_*.py` or equivalent)

- [ ] Is the `year` (or time) column sourced from the **left** side of every LEFT JOIN? A right-side year produces `year=NULL` for non-matching rows, which are silently dropped in downstream GROUP BY (`JOIN_YEAR_LOSS`).
- [ ] Are join key types consistent? (e.g. `bigint` vs `string`, padded vs unpadded code strings → `TYPE_MISMATCH_JOIN`)
- [ ] Are temp table writes using `overwriteSchema=true`? `mergeSchema=true` accumulates ghost columns from prior code versions (`GHOST_COLUMN`).

### 3b — Feature stage (`01_gold_*.py` or equivalent)

- [ ] Are all metric columns listed in `fillna_if_has_data` (or equivalent fill function)?
- [ ] Are derived ratios/percentages computed **after** `fillna_if_has_data` runs on their components? Computing before fill produces NULL/NULL ratios that are never corrected (`RATIO_BEFORE_FILLNA`).
- [ ] Do fill calls use a partition key (e.g. `partition_cols=["cod_reg"]`) rather than global aggregation? A global fill can overwrite legitimate NULLs in partitions with no data (`GLOBAL_FILLNA`).

> **Council note (Decision 5):** For flow/change metrics (e.g. `varperc_*`), the fill partition must include the **time dimension** (e.g. `year`) in addition to any geographic partition, to avoid mixing values from different census periods.

### 3c — Features module (`features_*.py` or equivalent)

- [ ] Do any `.otherwise(0)` / `ELSE 0` expressions operate on LEFT JOIN output columns **without** an all-null guard? Unconditional `.otherwise(0)` on absent source data = `ZERO_MASKING`.
- [ ] Are any fill calls in this module global (missing partition key)?

### 3d — Temp table schema check

```sql
DESCRIBE TABLE <catalog>.temp.<workflow_table>;
-- Expected: column count matches current pipeline code
-- Ghost columns (count > expected) → GHOST_COLUMN; apply overwriteSchema=true
```

### 3e — Domain validation

For bounded-domain metrics (indices, percentages, rates):

```sql
SELECT year, COUNT(*) AS out_of_range
FROM <TABLE_NAME>
WHERE <bounded_col> < <lower_bound> OR <bounded_col> > <upper_bound>
GROUP BY year;
```

> **Council note (Decision 4):** Before NULLing out-of-range values, write them to a data-quality audit table (`(entity_id, year, metric, raw_value, reason)`) so the diagnostic signal is preserved. The cap/floor logic must run **after** all `fillna` calls on components — a guard applied before fillna is inert because the ratio column is still `NULL/NULL` at guard time.

---

## Phase 4 — Bug Classification

| Class                   | Signal                                                                     | Null policy reference                     |
| ----------------------- | -------------------------------------------------------------------------- | ----------------------------------------- |
| `JOIN_YEAR_LOSS`        | `year IS NULL` rows in temp tables; NULL rows dropped in GROUP BY          | N/A — pipeline bug                        |
| `MISSING_FILLNA_COLUMN` | Column missing from fill list; `stddev > 0` regionally but column all-NULL | Fill after confirming source has data     |
| `RATIO_BEFORE_FILLNA`   | Ratio NULL even though components fill correctly; check code order         | Decision 4 execution order                |
| `GLOBAL_FILLNA`         | Partitions with no source data incorrectly filled with 0                   | Decision 5 partition rule                 |
| `GHOST_COLUMN`          | Temp table column count > current code; `mergeSchema=true` present         | N/A — write option bug                    |
| `GHOST_ROW`             | `ghost_rows > 0`; Delta merge without post-write DELETE                    | N/A — pipeline bug                        |
| `ZERO_MASKING`          | `stddev = 0` / all-zeros in years where source is absent                   | Decision 4 / null policy §5 anti-patterns |
| `TYPE_MISMATCH_JOIN`    | Join match rate drops; key types diverge (bigint vs string)                | N/A — schema bug                          |
| `DIMENSION_GAP`         | Ratio NULL but numerator non-NULL; dimension join anti-join returns rows   | N/A — data gap                            |
| `CODE_REGRESSION`       | All-NULL year partition; check VCS / Delta history for version bump        | N/A — deployment                          |
| `DOMAIN_VIOLATION`      | Value outside valid domain; check computation logic                        | Decision 3/4 domain guards                |

---

## Phase 5 — Pre-Output Checks (Council-Informed)

Before writing findings, verify these council-identified risks:

**Idempotency (insert-overwrite pipelines):** Can the pipeline be safely re-run for a year partition? NULL-filled values from a prior run must not silently overwrite newly-arrived sparse data in subsequent runs. Confirm the fill logic reads only current-run source data, not persisted prior-run NULL fills.

**dbt contract alignment (highest priority):** If the table is built by a dbt model with `contract: {enforced: true}`, check whether any NULL-producing decision conflicts with a `NOT NULL` column declaration. A correct semantic policy that violates the declared contract causes a hard Databricks runtime failure. Audit contracts first.

**Downstream consumer asymmetry:** BI tools (Tableau/Power BI) and ML pipelines handle NULLs differently. BI renders NULL as blank or zero depending on visualization type; pandas/sklearn silently drop NULL rows, producing biased training sets. Note per-consumer impact in the findings if relevant.

---

## Phase 6 — Output Format

Write findings to `<tracker-folder>/<TICKET-ID>-<shortname>/findings-<workflow>.md`:

```markdown
# Fix Guide — `<table_name>`

> Quality review of `<catalog>.<schema>.<table_name>`
> Date: <YYYY-MM-DD>

## Summary of findings

| #   | Issue         | File          | Lines | Bug class | Severity                 |
| --- | ------------- | ------------- | ----- | --------- | ------------------------ |
| 1   | <description> | `<file_path>` | L<N>  | `<CLASS>` | Critical/High/Medium/Low |

### Data impact

| Year   | Affected columns | Root cause                  |
| ------ | ---------------- | --------------------------- |
| <year> | <col_list>       | <class + brief description> |

## Step N — <Fix description>

**File:** `<relative_path>`
**Bug class:** `<CLASS>`
**Problem:** <description>

**Evidence:**
sql
<verification query showing the anomaly>

**Fix:** <before/after code or description>

**Verification:**
sql
<post-fix check — expected result>
```

---

## Validation Gate

Before closing the investigation:

- [ ] All column/year combinations with `stddev > 0` have NULL% < 5%, or absence is explained by source coverage
- [ ] `ghost_rows = 0` for all years
- [ ] No `NaN` or `Inf` values in any column
- [ ] Partitions with no source data show `NULL` (not `0`) for fill-eligible metrics
- [ ] Temp tables have ≤ expected column count (no ghost columns)
- [ ] Out-of-domain values audited before NULLing
- [ ] dbt contract alignment checked for non-nullable columns
- [ ] Findings file written and committed to the tracker folder

---

## References

- Bug classification taxonomy: `docs/wiki/data_quality/bug_taxonomy.md`
- Failure register (F-01 to F-14): `docs/wiki/data_quality/failure_register.md`
- Null/zero semantic policy: `docs/wiki/data_quality/null_policy.md`
- Council transcript: `<tracker-folder>/<TICKET-ID>-retrospective/council-transcript-<date>.md`
