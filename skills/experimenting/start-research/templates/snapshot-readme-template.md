<!--
  Purpose   : Documents every Parquet file in an experiment data snapshot — source table,
              row/column counts, join keys, caveats. The human-readable companion to queries.sql.
  When      : Write immediately after snapshot subagent completes. Never modify after the snapshot
              date — add a new README if re-snapshotting.
  Where     : research/experiments/<NN_name>/data/README.md
  Links to  : queries.sql (same directory), [[decisions/0001-...]], [[STATE.md]]
  Linked from: [[experiments/<NN_name>/results/report.md]] (Artifacts section), [[STATE.md]]
-->

# experiments/<NN_name>/data — snapshot manifest

> **Reproducibility**: See [`queries.sql`](queries.sql) for the exact SQL that produced every parquet file in this directory.

Snapshot date: <YYYY-MM-DD>
Source: <catalog-name> (<catalog system>), <access mode, e.g. read-only via Databricks MCP>.

| file | source table | rows | columns | notes |
|---|---|---|---|---|
| <filename.parquet> | <schema.table> | <N> | <M> | <one-line: granularity, filter, years> |
| <filename.parquet> | <schema.table> | <N> | <M> | <one-line: granularity, filter, years> |
| <filename.parquet> | <schema.table> | <N> | <M> | <geometry note if applicable> |

## <Special topic note 1 — e.g. Geometry note>

<Explain any non-standard encoding, format choice, or known limitation for the geometry/spatial columns.>

## <Special topic note 2 — e.g. Distance matrix>

<Explain structure: symmetric or directed, self-pairs, units, completeness.>

## <Table-specific note — repeat per table that needs it>

- <Notable filter applied and why>.
- <Year availability issue, fallback applied>.
- <Granularity mismatch note, e.g. NUTS2 broadcast to LAU>.

## <Join key note>

`<column>` in `<file>` is <type / encoding>. Cross-reference with `<other-file>` on `<column>`
(<cast note if needed, e.g. leading zeros>).

## Reproducibility

Exact SQL for every file is in [`queries.sql`](queries.sql). The file documents:
- The final `SELECT` statement (copy-pasteable) for each parquet file.
- For chunked queries: the parameterized template, the full list of chunk-key pairs, and the concatenation strategy.
- Any column renames and type casts applied between source and parquet.
- The schema discovery `DESCRIBE TABLE` statements used during the initial exploration session.

All queries target `<catalog-name>` and were executed <access mode> on <YYYY-MM-DD>.

## Known caveats

- <Caveat 1 — row-count mismatch between tables and cause>.
- <Caveat 2 — pagination / row-limit workaround applied>.
- <Caveat 3 — year not yet available in source>.
- <Caveat 4 — granularity coarser than desired; note what exists in catalog for future>.
