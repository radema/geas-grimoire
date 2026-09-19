-- =============================================================
-- Purpose   : Reproducibility manifest — exact SQL that produced every Parquet
--             file in the experiment's data/ directory.
-- When      : Produced by the snapshot subagent alongside the Parquet files.
--             Never edited after snapshot date.
-- Where     : research/experiments/<NN_name>/data/queries.sql
-- Links to  : README.md (same directory) for human-readable row/column counts
--             and caveats
-- Linked from: experiments/<NN_name>/results/report.md (Artifacts section)
-- =============================================================
-- Notes on execution environment:
--   - All queries executed via <execution method, e.g. Databricks MCP server execute_sql_read_only>.
--   - <Row-return limit note, e.g. MCP enforces a hard row-return limit of ~N rows per call>.
--   - All single-query files: <completeness verification method, e.g. truncated=False confirmed>.
--   - Chunked files: each chunk confirmed <completeness check> before concatenation.
--   - Results were collected as <format, e.g. JSON arrays> and written to parquet via <method>.
-- =============================================================


-- ---- <filename_1.parquet> ----
-- Source: <catalog.schema.table>
-- Rows: <N>  |  Columns: <M>
-- Filters: <filter description>
-- Column mapping (source → parquet):
--   <source_col_1>   → <parquet_col_1> (<cast if any>)
--   <source_col_2>   → <parquet_col_2> (<cast if any>)
--   <source_col_3>   → <parquet_col_3> (unchanged)
-- Note: <any partition column notes, join-key encoding notes, etc.>

SELECT
    <CAST(source_col_1 AS STRING)>  AS <parquet_col_1>,
    <source_col_2>,
    <CAST(source_col_3 AS STRING)>  AS <parquet_col_3>
FROM <catalog.schema.table>
WHERE <filter_col> IN (<value_1>, <value_2>)
ORDER BY <order_col>;


-- ---- <filename_2.parquet> ----
-- Source: <catalog.schema.table>
-- Rows: <N>  |  Columns: <M>
-- Year resolution: <most-recent / specific year>. Source has partition column `<year_col>`.
--   Most-recent year selected via QUALIFY / ROW_NUMBER pattern to retain one row per <key_col>.
-- Column mapping (source → parquet):
--   <source_col>  → <parquet_col> (<cast if any>)

SELECT
    <CAST(key_col AS STRING)>    AS <key_col>,
    <col_1>,
    <col_2>,
    <CAST(col_3 AS STRING)>      AS <col_3>
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY <key_col> ORDER BY <year_col> DESC) AS rn
    FROM <catalog.schema.table>
)
WHERE rn = 1
ORDER BY <key_col>;


-- ---- <filename_chunked.parquet> ----
-- Source: <catalog.schema.table>
-- Rows: <N>  |  Columns: <M>
-- Note: required ~<N> chunked queries due to <row-return limit, e.g. MCP ~24k row limit>.
-- Filters applied:
--   <filter_col_1> = '<value>'
--   <filter_col_2> = '<value>'        (<reason>)
--   <date_col> IN (<year_1>, <year_2>) (<year_3> returned 0 rows — <reason>)
-- Each chunk = <dimension_1> × <dimension_2>, queried individually to stay under limit.
--
-- Column mapping (source → parquet):
--   <source_col>         → <parquet_col> (<cast if any>)
--
-- 1. Parameterized template (placeholders: {<param_1>}, {<param_2>}):

SELECT
    <col_1>,
    CAST(<col_2> AS STRING)    AS <col_2>,
    <col_3>,
    CAST(<col_4> AS STRING)    AS <col_4>
FROM <catalog.schema.table>
WHERE <filter_col_1> = '<value>'
  AND <chunk_col_1> = '{<param_1>}'
  AND <chunk_col_2> = {<param_2>}
ORDER BY <col_1>;

-- 2. Chunk-key values iterated (<param_1> × <param_2>):
--    <Dimension 1> (<N> codes): <code_1>, <code_2>, <code_3>, ...
--    <Dimension 2>: <value_1>, <value_2>
--    Total chunks = <N1> × <N2> = <N_total> queries
--
--    Full iteration order (<param_1>, <param_2>):
--      ('<code_1>', <year_1>), ('<code_1>', <year_2>),
--      ('<code_2>', <year_1>), ('<code_2>', <year_2>),
--      ...
--
-- 3. Concatenation: all <N> result DataFrames concatenated with <method>,
--    then written to <filename_chunked.parquet>. <Dedup note if applicable>.
--
-- Verification: <year_3> returned 0 rows for every <dimension_1> — confirmed absent:

SELECT COUNT(*) AS row_count
FROM <catalog.schema.table>
WHERE <filter_col_1> = '<value>'
  AND <filter_col_2> CONDITION
  AND <date_col> = <year_3>;
-- Returns: 0


-- =============================================================
-- Schema discovery queries (for reference, not used to produce data)
-- =============================================================
DESCRIBE TABLE <catalog.schema.table_1>;
DESCRIBE TABLE <catalog.schema.table_2>;
DESCRIBE TABLE <catalog.schema.table_3>;
