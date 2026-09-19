---
name: assess-indicator
description: >-
  Audit a single Gold-layer KPI/indicator column against its official statistical definition
  (Eurostat / ISTAT / ILO / Worldbank / OECD / SDMX) and trace it back to source. Use for "is
  this KPI computed correctly?", "check the formula for column X", "verify how column Y is
  built", "audit indicator Z", "is the denominator scope right?", or any request to compare an
  implemented business metric against its canonical definition.
---

# Assess Indicator

Structured end-to-end audit of a single KPI/indicator column on a Gold table. Traces lineage from Gold SQL → Silver → Bronze → upstream statistical source, compares the implemented formula against the canonical definition (from a user-provided metadata card and/or external authority), validates magnitudes against published benchmarks via websearch, evaluates visualization readiness against the consumer viz app's indicator card, and emits a markdown assessment report. On bug detection, produces a JIRA ticket draft (markdown file only — never auto-pushed).

## Scope boundary

Use for **formula/definition correctness** — does the implemented KPI match its canonical statistical definition and published magnitudes. For value anomalies (unexpected NULL/NaN/Inf, ghost rows, join-coverage gaps, domain violations) use the `quality-analysis` skill instead.

**Templates** (under `templates/` in this skill):
- `templates/assessment_report.md` — copy as the starting point for every assessment; fill in each section as Phases 1–5b complete.
- `templates/jira_ticket.md` — copy only when Phase 7 triggers (i.e. a 🔴 verdict or a concrete cleanup action).

Always start by copying the assessment template to the output path; do not draft the report inline. Templates exist so the output is consistent across runs and across teammates.

Generalized from a worked example (Eurostat-vs-ISTAT labor-market KPI audit — see `references/worked-example-neet.md`). Key lessons baked in:
- ISTAT census permanente is the only comune-level source for occupation rates; LFS tops out at NUTS3.
- SDMX dataflows often publish both totals and breakdown slices in the same response — filtering only some dimensions causes silent double-counting unless the source publishes only the TOTAL slice.
- NaN ≠ NULL in DOUBLE columns; `WHERE col IS NULL` misses NaN.
- The first read of a CSV sample can mis-attribute columns; always confirm against the SDMX codelist before claiming a bug.

## Project policy: consumer viz app — `certified` and `status` flag rules (added 2026-05-26)

When the consumer is a metadata-driven catalog project (e.g. `<consumer-repo>/<metadata-path>`, such as `assets/metadata/indicators/*.yaml`), follow these conventions for the `certified` and `status` fields:

- **`certified: true|false`** is a function of **external-source coherence**, NOT provenance. Set `true` iff the Gold values agree with the authoritative external source (ISTAT/Eurostat/MEF/OECD/SDMX) within tolerance. Locally-computed ratios that reproduce the published value earn `true`. Passthrough columns that diverge (mis-named bucket, fillna mis-semantic, NACE rollup double-count) earn `false`. The `<TICKET-ID>` heuristic "locally-computed → certified:false" is **superseded** by this rule.
- **`status: ufficiale|provvisorio|...`** reflects pedigree. Set `ufficiale` if the value is either (a) direct passthrough from official source, OR (b) a simple manipulation of official inputs (ratio, scale, YoY, sum of canonical buckets) with a disclosed formula. Use `provvisorio`/`elaborato` for imputation, modeling, multi-source alignment.

The two flags are independent but should agree on the typical case. See `feedback_indicator_certified_status_rules.md` in the consumer app's project memory for the full coherence table and worked examples.

## Mandatory external-source verification

For every assessment, run an explicit comparison against the authoritative external source (SDMX query, ISTAT publication, Camera di Commercio benchmark, Eurostat ilc_*, OECD/World Bank series). The §3 metadata review MUST cite specific values and a §6 References block MUST list all URLs consulted. If the check cannot be run (offline, source unreachable), default `certified: false` and flag verification as deferred.

Precedent (a prior precedent): SDMX query on `<SDMX_DATAFLOW_ID>` for a sample entity/year revealed the all-category rollup value diverged ~3× from the Gold-table value — exposed a double-count from a missing dimension filter (e.g. `econ_activity_code`) that the static-only review had missed. External verification is the non-negotiable safeguard against silent upstream defects.

---

## Required inputs

Before starting, confirm with the user:

| Input | Example |
|---|---|
| `GOLD_TABLE` | `catalog.gold.<table>_y` |
| `KPI_COLUMN` | `<KPI_COLUMN>` |
| `METADATA_CARD` *(optional)* | path to indicator inventory (HTML/MD), JIRA ticket, Confluence page, or pasted snippet — anything that names the canonical source/formula |
| `YEAR_RANGE` *(optional, defaults to last 3 years)* | `2021-2024` |

If the metadata card isn't supplied, fall back to SDMX dataflow registry + websearch (Eurostat / ISTAT / ILO / Worldbank / OECD docs).

---

## Phase 1 — Lineage trace (Gold → Silver → Bronze → source)

Goal: locate every SQL/PySpark line that contributes to the KPI and identify the upstream source endpoint.

Steps:

1. **Grep the gold definition.** Find the model that emits `KPI_COLUMN`:
   ```bash
   grep -rn "KPI_COLUMN" preparation/dbt_models/ preparation/ 2>/dev/null
   ```
2. **Trace `ref()` / `source()` chains** until you reach a `silver.fact_*` or `silver.dim_*` table.
3. **Trace silver script** under `ingestion/*/silver_*.py` — record column renames, filters, NOT NULL/PK constraints applied.
4. **Trace bronze script** under `ingestion/*/bronze_*.py` — record the SDMX/REST endpoint, dataflow ID, `key_parts`, and dimensions wildcarded.
5. **For multi-source KPIs** (3+ files / open-ended), dispatch an `Explore` subagent — never sequentially read many files (CLAUDE.md rule).

Capture:
- Gold model file + line range
- Silver table FQN + script path
- Bronze table FQN + script path
- Source endpoint (full URL, dataflow ID, version)
- Dimensions in the source key

---

## Phase 2 — Source brief + canonical definition

Two outputs from this phase: a **Source brief** (what the upstream dataset actually contains — useful for colleagues unfamiliar with the source) and a **Canonical definition** (what the KPI is supposed to be per the issuing authority).

### 2a. Source brief (always produce — even when correctness is obvious)

Goal: a one-screen primer on the upstream source so a teammate who has never opened it can understand the shape of the data. This section exists because the most common failure mode in production is *not* a formula bug — it's misunderstanding what the source publishes (granularity, time coverage, dimension semantics). Always include it.

For each source identified in Phase 1, record:

- **Publisher + dataset name** (e.g. "ISTAT — Censimento permanente: Resident population 15+ by current activity status and age").
- **Endpoint type** (SDMX REST / CSV download / HTTP API / parquet drop / etc.) and concrete URL pattern.
- **Dimensions present** (for SDMX: pull live via the registry — `https://<host>/SDMXWS/rest/dataflow/<agency>/<id>/<version>` and the linked DSD). List every dimension name + a one-line description of its semantic content.
- **Codelist values for the dimensions used by the KPI** — verify the literals in SQL match an actual codelist label (query live via Databricks MCP: `SELECT DISTINCT <dim_col> FROM silver.<table>`).
- **Time coverage** (first year, last year, publication cadence — annual / quarterly / monthly).
- **Geographic coverage + granularity** (NUTS0/1/2/3, LAU, world, EU only, etc.).
- **What the source DOES NOT publish** — explicitly note gaps that the KPI implementation has to work around (e.g. "this dataflow does not publish an education-enrollment dimension at comune level").
- **Known idiosyncrasies** — e.g. negative-income bracket included; provisional vs final values; revisions policy; total-vs-breakdown row coexistence.

### 2b. Canonical definition

Priority order for the authoritative formula:

1. **User-supplied metadata card** — parse for indicator code, official source, dataflow ID, formula, age band, gender filter, scope.
2. **SDMX dataflow registry** — DSD concept descriptions often include the official definition.
3. **WebSearch** the canonical definition from the issuing body. **Use WebSearch whenever the metadata card does not state the formula explicitly — do not rely on prior knowledge alone.** Search the issuing-body's methodology page for the indicator code:
   - Eurostat: `https://ec.europa.eu/eurostat/databrowser/view/<code>` + the linked ESMS metadata page (search query: `Eurostat <code> ESMS methodology`).
   - ISTAT: `i.stat` / `dati.istat.it` / `esploradati.istat.it` (search query: `ISTAT <indicator_name> nota metodologica`).
   - ILO: `https://ilostat.ilo.org/topics/<topic>` (search query: `ILOSTAT <indicator> definition`).
   - Worldbank: `https://data.worldbank.org/indicator/<code>` (Series Metadata).
   - OECD: `https://data.oecd.org/<theme>` + the linked PDF.
   - National stat offices: search query `<office> <indicator> methodology PDF`.

   Fetch at least one authoritative URL via WebFetch / WebSearch and cite it in the References section. If WebSearch returns nothing useful for the exact KPI, fall back to the closest sibling indicator and document the gap.

Record in the report:
- Official formula (numerator / denominator) as a math expression.
- Age band, gender, geography, time aggregation.
- Codelist values that count as numerator vs denominator.
- Known caveats from the issuing body (e.g. ILO NEET requires BOTH employment status AND education enrollment status; ISTAT census permanente only publishes a `student` status at comune level — confirm whether the implementation handles this).

---

## Phase 3 — Formula comparison

Build a side-by-side table:

| Dimension | Implemented | Canonical | Match? |
|---|---|---|---|
| Numerator filter | `cur_act_stat='other condition' AND gender='T' AND age='Y15-24'` | NEET = not employed AND not in education/training, age 15-24 | ⚠️ proxy — no education dim |
| Denominator | `cur_act_stat='total' AND gender='T' AND age='Y15-24'` | population 15-24 | ✅ |
| Age band | 15-24 | 15-24 | ✅ |
| Gender | T (total) | T | ✅ |
| Geography | comune (LAU) | NUTS3 (Eurostat) / NUTS2 (ILO) | ⚠️ source forced by granularity requirement |
| Multiplier | × 100 | × 100 | ✅ |

Flag every mismatch with severity:
- 🔴 **Wrong** — formula deviates from canonical and would mislead consumers
- 🟡 **Proxy** — best-available given source constraints; document the gap
- 🟢 **Match**

---

## Phase 4 — Data inspection (Databricks MCP if available)

Use the `databricks-mcp-sql` skill to verify the source publishes what you think it does. Common traps:

1. **Single-slice vs breakdown rows.** SDMX endpoints often return *both* a TOTAL row and per-breakdown rows for unfiltered dimensions. Summing without explicit filters double-counts. Confirm with:
   ```sql
   SELECT DISTINCT <dim_col> FROM silver.<bronze_origin> WHERE year = <Y> LIMIT 50;
   ```
   for every dimension that is NOT explicitly filtered in the Gold SQL.

2. **NaN vs NULL.** Databricks SQL: `WHERE col IS NULL` misses NaN in DOUBLE columns. Use `WHERE col IS NULL OR isnan(col)`.

3. **Codelist alignment.** Pull the SDMX codelist (e.g. `CL_FORZE_LAV`) and confirm the string literal used in the Gold SQL (`'other condition'`, `'total'`, `'employed person'`) matches an actual codelist label. Misspelled labels silently return zero rows.

4. **Row-count sanity.** Compare `COUNT(*)` of bronze vs silver vs gold for the KPI's grain. Large drops = filter; large inflation = unfiltered breakdown dimension.

5. **Zero / null / inf distribution.** Per year, percentage of nulls/NaNs/zeros/inf for `KPI_COLUMN`. Reference the project's null-vs-zero policy in `docs/wiki/data_quality/null_policy.md`.

---

## Phase 4b — Coherence with common knowledge (websearch)

Goal: a formula can be algebraically correct yet produce values that are nonsensical (wrong unit, wrong scale, wrong subset). Catch this by comparing actual Gold values against externally-published benchmarks for the same indicator. Always perform this phase — even when the formula audit passed.

Steps:

1. **Pick reference entities + years.** Aim for 5–8 anchor points the user will recognize:
   - 2–3 large cities (Roma, Milano, Napoli) or NUTS regions
   - 1 small/peripheral entity (a Sardinian micro-comune, a southern province)
   - 1 known-extreme entity (Portofino for income, Locri for unemployment, etc.)
   - National aggregate if the gold table or a sibling table publishes one
   - The most recent year + one comparison year

2. **WebSearch the published reference values** for each anchor + year. Suggested queries:
   - `<indicator name> <city> <year> ISTAT`
   - `Eurostat <code> <NUTS region> <year>`
   - `<issuing body> annual report <year> <indicator>`
   - For Italy at comune level: `<comune> <indicator> open data Banca d'Italia / IRPET / Comuni-Italiani`.
   Always cite the URL the value came from.

3. **Build a coherence table** comparing Gold vs published, with absolute and relative deltas:

   | Entity | Year | Gold value | Published value | Source URL | Δ abs | Δ rel | Verdict |
   |---|---|---|---|---|---|---|---|
   | Roma | 2023 | 12.5% | 13.1% (ISTAT) | ... | -0.6 pp | -4.6% | ✅ within ±2 pp |
   | Milano | 2023 | 10.8% | 11.0% (ISTAT) | ... | -0.2 pp | -1.8% | ✅ |
   | Portofino | 2023 | 73.8% | ~70% (BdI study) | ... | +3.8 pp | +5.4% | ✅ |
   | Italy (national) | 2023 | 14.5% | 16.1% (Eurostat LFS) | ... | -1.6 pp | -9.9% | ⚠️ proxy gap |

4. **Classify each anchor:**
   - ✅ Within ±10% relative or ±2 absolute units (or whatever's tighter for the indicator class)
   - ⚠️ Outside that range but explained by a documented methodological substitution (e.g. census vs LFS)
   - 🔴 Outside that range with no explanation → likely scale/unit/subset bug

5. **National-level totals as a fast sanity gate.** If the indicator has a published national figure, compare it against the population-weighted aggregate of Gold values for the same year. A 30%+ deviation almost always indicates a unit or scale problem (the `× 100` bug class).

6. **Polarity sanity.** Pick the highest and lowest Gold value in the most recent year and ask: does the ranking match common knowledge? E.g. for unemployment rate, the highest-value comuni should be in the south; for income, the highest should be in Brianza/Brunico/Portofino. Document any inversion as 🔴.

Caveats: when websearch can't find a per-entity published value, fall back to the national aggregate or the typical published range for the indicator class (`unemployment rate in Italy 2023: 7–8% national, 4–6% north, 11–14% south`). Document the fallback.

---

## Phase 5 — Edge cases & known anti-patterns

Check these systematically — they're recurring bugs seen in past audits:

- **`* 100` rescale drift** — ratio expressed as 0-1 in code but column name says `_pct_*`. Confirm scale by sampling 5 rows and comparing to a published statistic.
- **Empty-pivot anti-pattern** — PySpark `.pivot(col)` with no values list on sparse silver yields only group-by keys. If KPI sits behind a pivot, confirm explicit values list.
- **`_delta_timestamp` references in Gold** — Gold has no `_delta_timestamp` per Constitution Article I; it's delivery-only.
- **Orphan ingestion sources** — a bronze/silver table exists but isn't referenced by the Gold model. Flag for cleanup but don't block.
- **Granularity downgrade** — Gold is at comune level but the only source for the canonical formula tops out at NUTS3. The implementation chose a different source (e.g. census permanente) — confirm the substitution is documented.

---

## Phase 5b — Visualization readiness (consumer viz apps)

Goal: a metric that is statistically correct can still be unusable in a viz product if its scale, distribution, or polarity makes choropleths illegible or filters non-discriminating. Always evaluate against the consumer viz app's indicator metadata card.

Pull the card from the consumer repo's indicator metadata path (e.g. `<consumer-repo>/assets/metadata/indicators/<kpi-column>.yaml`, or the user-supplied path) and reconcile each field against the actual Gold data:

1. **Unit + format alignment.**
   - Card declares `unit: '%'` / `'index'` / `'€'` / `'kmq'` / etc., `unit_position: prefix|suffix`, `format: percentage|number|currency`, `decimals: <int>`.
   - Verify Gold values match: a `format: percentage` column should sit in [0, 100] (not [0, 1]); a `format: currency` column should be euros (not thousands); decimals should match the precision actually meaningful in the data.
   - 🔴 if scale mismatches card (the classic `× 100` rescale bug).

2. **Polarity check.**
   - Card declares `polarity: higher_better | lower_better | neutral`. This drives the color ramp direction in the app's choropleths.
   - Verify polarity is consistent with the indicator's domain meaning. NEET = lower_better; employment rate = higher_better; Gini = lower_better; broadband coverage = higher_better.
   - 🔴 if card says `higher_better` for an inequality/unemployment-style indicator (would paint deprivation as positive).

3. **Distribution shape.**
   - Run `percentile_approx(<col>, array(0.01, 0.05, 0.25, 0.5, 0.75, 0.95, 0.99))` on the most recent year.
   - **Skewness** — if p99/p50 > 5 (or p1/p50 < 0.2), the choropleth will be dominated by outliers. Recommend either a log scale, a winsorized version, or a quantile-binned color ramp in the app config.
   - **Compression** — if p95 − p5 covers less than 10% of the nominal range (e.g. an indicator declared 0–100 but values cluster 60–70), the choropleth will look uniform. Flag for product team to consider z-score normalization or rescaling.
   - **Bimodality** — if histogram shows two peaks, a sequential color ramp will hide structure. Recommend diverging ramp around the antimode.

4. **Outliers + ceiling/floor artefacts.**
   - Count rows hitting exact 0, exact 100 (for percent), exact denominator-of-1 micro-comuni.
   - If >5% of entities sit at a single value, the indicator is non-discriminating at that grain.
   - For percent indicators, micro-entities (N=1, N=2) can hit 0 or 100 by accident → consider a min-N filter in the delivery view.

5. **Geographic coverage in the active year.**
   - Count distinct entities with non-null KPI values vs total entities in the comune dimension. If <90% coverage, viz will show blank polygons.
   - Flag missing-geography clusters (e.g. all Trentino-Alto Adige missing for fiscal indicators — known MEF carve-out).

6. **Temporal continuity.**
   - For each year in scope, count non-null rows. If a year is 100% NULL (common for `t-1` cold-starts on annual sources), confirm the app's time-slider hides that year by default; otherwise users see an empty map for that year.

7. **Card-vs-reality gaps.**
   - `description` field on the card should mention the source substitution, time coverage, and any proxy gap surfaced in Phase 3/4.
   - `temi` / `subtema_map` should match how the app groups the indicator in its navigation — flag misclassifications.

Output a small `Visualization readiness` block (see report template below) with one line per check (✅ / ⚠️ / 🔴) and concrete recommendations (e.g. "switch to quantile bins", "winsorize at p99", "add min-population filter", "fix `polarity` in metadata card").

---

## Phase 6 — Assessment report (markdown)

**Default output location:** `<repo-root>/evals/<kpi-column>/assessment_<N>.md`, where `<N>` is the next available integer (1 if the folder is empty, otherwise `max(existing) + 1`). One folder per KPI; iterations accumulate as numbered files so prior assessments stay readable for comparison.

The `evals/` folder is git-ignored (see the data repo's `.gitignore`) — assessments are workspace artifacts, not source. If the user explicitly wants the report tracked in git, save instead to `.specify/specs/<active-feature>/assessment-<kpi-column>.md` (inside an active Speckit feature) or `docs/assessments/<kpi-column>.md`. Confirm with the user before deviating from the default.

**How to use the template:**

1. Copy `templates/assessment_report.md` (relative to this skill folder) to the output path.
2. Fill in placeholders as each phase completes — don't rewrite the section structure, just substitute content into each `<…>` slot.
3. Keep the section order and headings intact; downstream tooling and teammates rely on it.

The template lives outside this file so its structure can evolve without requiring SKILL.md edits, and so the assessment report and the SKILL never drift apart.

---

## Phase 7 — JIRA ticket draft (only on bug detection)

If verdict is 🔴 or there's a concrete cleanup action, draft a JIRA ticket as a markdown file alongside the assessment report. **Never auto-push to JIRA** — the user pushes manually or via Atlassian MCP after review.

Filename: `<repo-root>/evals/<kpi-column>/jira-draft_<N>.md` (same `<N>` as the assessment that produced it; same git-ignored folder).

Copy `templates/jira_ticket.md` (relative to this skill folder) as the starting point and fill in placeholders. Same rationale as the assessment template: keep structure stable, evolve content.

---

See `references/worked-example-neet.md` for a fully worked example (NEET rate, Eurostat-vs-ISTAT definition mismatch).

---

## Phase 8 — Improvement options (conditional)

Runs **only** when the assessment surfaces any of:
- ⚠️ or 🔴 in formula comparison (Phase 3)
- ⚠️ or 🔴 in coherence with common knowledge (Phase 4b)
- ⚠️ or 🔴 in visualization readiness (Phase 5b)
- Verdict severity ≥ low

A ✅-clean assessment skips this phase entirely. The goal here is: when something is sub-optimal, don't just document the gap — propose concrete ways to close it. This is the difference between an audit and a useful audit.

Research lanes (use WebSearch + WebFetch heavily; cite every URL):

1. **Alternative sources at the same granularity.** For each ⚠️/🔴 concern (proxy formula, scope substitution, coverage gap, viz limitation), ask: is there another public dataset that would resolve it? Look at:
   - Adjacent publishers (ISTAT BES indicators, INPS observatories, Banca d'Italia microdata, Agenzia Coesione Territoriale CPT, Agenzia Entrate releases, MEF additional tables, Catasto, regional open-data portals).
   - Whether the publisher exposes a richer dataset than the one currently ingested (e.g. MEF gross IRPEF income vs MEF net-of-tax tables; ISTAT census LFS vs census permanente).
   - For each candidate: record granularity, frequency, concept, accessibility (open / request-only), legal/licensing constraints.

2. **Methodological improvements on the existing source.** Same data, better math:
   - Better estimators for the current quantity (shape-preserving Lorenz interpolation, Pareto-tail correction, kernel-smoothed quantiles, small-area estimation, equivalisation proxies from auxiliary covariates).
   - Better dimension filtering / aggregation when SDMX dimensions are wildcarded.
   - Better NULL/NaN handling at the cell-suppression boundary.
   - Rank each by *expected impact* (large / moderate / small) and *implementation cost* (≤1 day / 1-3 days / >3 days).

3. **Source-side fixes.** Things the ingestion layer can do without changing the math:
   - Backfill missing years if upstream publishes them (and we just don't ingest them yet — see the NEET 2021 case → JIRA `<TICKET-ID>`).
   - Tighten dimension filters on SDMX wildcards to insulate from future breakdown publications.
   - Add canary tests that fail when the source schema drifts.

4. **Hybrid / small-area approaches.** When the granularity requirement forces a proxy (e.g. MEF IRPEF instead of EU-SILC at LAU), check whether published Small-Area Estimation (SAE) or model-based downscaling techniques exist for the canonical metric. Italy-specific references: ISTAT BES SAE notes, Eurostat regional SAE working papers, JRC working papers on subnational distributional indicators.

5. **Consumer-facing remediation.** When the indicator is structurally limited and won't change, what should change on the consumer app side? Card description enrichment, time-slider configuration, color-ramp choice, complementary indicators that contextualize this one.

**Output:** write a separate companion file `<repo-root>/evals/<kpi-column>/improvement_options_<N>.md` (same `<N>` as the assessment). Structure:

```markdown
# Improvement options — <KPI_COLUMN>
**Companion to:** `assessment_<N>.md`
**Triggered by:** <list of ⚠️/🔴 findings that fired this phase>

## Alternative sources at LAU
<table: source / granularity / frequency / concept / access / notes / URL>

## Methodological improvements on the existing source
<ranked list — each with: change, expected impact, effort, references>

## Source-side fixes
<bullets: backfill / filter tightening / canary tests, with concrete file paths>

## Hybrid / SAE approaches
<published references + applicability assessment>

## Consumer-facing remediation
<Consumer app card / time-slider / color-ramp / complementary indicators>

## Recommended next 2-3 actions
<numbered, with effort estimate and which downstream artefact each touches>

## References
<URL list>
```

Reference the companion file from the main assessment report's `## Recommendations` section so the chain is discoverable.

---

## When to stop and ask the user

- If lineage trace can't reach a Bronze/Silver source (Gold computed from a join with no obvious origin), stop and ask.
- If multiple Gold models compute slightly different versions of the same KPI, stop and ask which one is authoritative.
- If the canonical definition has multiple competing official sources (Eurostat vs ILO vs OECD), surface the divergence and let the user pick the reference.
- If you'd need to run a destructive or large-scope Databricks query (full-table scan on a multi-billion-row bronze), ask before executing.

Otherwise keep going — produce the report and JIRA draft, then hand off.
