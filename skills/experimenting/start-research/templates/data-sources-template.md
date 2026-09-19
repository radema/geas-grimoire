<!--
  Purpose   : Inventory of all data resources that could feed the model — both already in the
              catalog and external open data. Informs future experiment snapshots and prioritizes
              next-session ingestion work.
  When      : Write / update after catalog schema discovery (typically after ADR 0001 is accepted).
              Update after each session that adds new catalog tables.
  Where     : research/future_data_sources.md
  Links to  : [[decisions/0001-...]], [[STATE.md]], [[experiments/<NN>/data/README.md]]
  Linked from: [[STATE.md]], [[decisions/0001-...]] (Data sources section)
-->

# Future Data Sources

Inventory of data resources we could feed the <model description> in future iterations. Two sections:

- **A. Already in <catalog> catalog** — `<catalog-name>` (read-only via <access method>). Direct snapshot path. Zero ingestion cost.
- **B. External open data not yet in catalog** — needs ingestion work; tracked for future engineering effort.

Snapshot date for inventory: <YYYY-MM-DD>.

---

## A. Already in catalog (`<catalog-name>`)

Each row: dot-path + granularity + role in model + cost-to-add tonight/next-session.

### A.1 <Category 1 — e.g. Geometries & hierarchy (foundational)>

| Table | Granularity | Role | Notes |
|---|---|---|---|
| `<schema.table_1>` | <granularity> | <role> | <Notes — used tonight / next-session / etc.> |
| `<schema.table_2>` | <granularity> | <role> | <Notes.> |

### A.2 <Category 2 — e.g. Target / indicator candidates>

| Table | Granularity | Indicator(s) | Status |
|---|---|---|---|
| `<schema.table>` | <granularity> | <indicator list> | <**Target tonight.** / Candidate vN.> |

### A.3 <Category 3 — e.g. Covariates — unit-level>

<Prose intro + grouped list if many tables:>

- **<Group 1>**: `<table_1>`, `<table_2>` — <description>
- **<Group 2>**: `<table_1>` — <description>

### A.4 <Category 4>

| Table | Use |
|---|---|
| `<schema.table>` | <use> |

<Optional prose note if category has significance.>

### A.<N> <Additional categories as needed>

---

## B. External open data not yet in catalog

Candidates for future ingestion if specific modeling needs justify the effort.

| Source | URL | Granularity | License | Why useful | Effort |
|---|---|---|---|---|---|
| <Source name> | <https://...> | <granularity> | <license> | <1-line rationale> | <S/M/L> |

Effort key: S = <1 day, M = 1–3 days, L = >3 days.

---

## Implications

- **Catalog already covers <scope statement>.**
- **Highest-value next-session adds (all in catalog)**:
  1. `<table>` → <why valuable>.
  2. `<table>` → <why valuable>.
  3. `<table>` → <why valuable>.
  4. `<table>` → <why valuable>.
  5. `<table>` → <why valuable>.
- **External ingestion not needed unless** <condition — e.g. cross-country comparison, sub-unit granularity>.
