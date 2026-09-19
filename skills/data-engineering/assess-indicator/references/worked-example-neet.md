## Worked example — NEET case

The NEET assessment that motivated this skill is the canonical worked example:

- **KPI:** `com_pct_obsvalue_neet_index_15_24_y` on `com_opencomuni_socioeconomia_y`
- **Lineage:** `preparation/dbt_models/com_opencomuni_socioeconomia_y/00_prep/int_com_opencomuni_socioeconomia_y_metrics.sql:307-388` → `silver.fact_istat_census_occupazione` → bronze from ISTAT SDMX dataflow `IT1:DF_DCSS_ISTR_LAV_PEN_2_TV_3` (Censimento permanente, comune-level).
- **Canonical NEET (ILO):** youth 15-24 neither in employment nor in education or training, ÷ total population 15-24.
- **Implemented:** `cur_act_stat = 'other condition' AND age = 'Y15-24' AND gender = 'T'` ÷ `cur_act_stat = 'total' AND age = 'Y15-24' AND gender = 'T'`.
- **Verdict:** 🟡 proxy. The ISTAT census permanente dataflow at comune granularity does **not** publish an `education enrollment` dimension. `'other condition'` (codes 4+5+7+24 = housewife + student + other + pensioner) is the closest available bucket. True NEET requires also excluding the "student" subset, which is unobservable at this grain. Documented in the report; flagged for product-team review rather than auto-fixed.
- **Bug #1 (dimension double-counting):** initially flagged as risk because bronze wildcards all 10 dimensions. Inspection of 1.08M rows for year 2023 showed source publishes only TOTAL/ALL slice — false alarm. **Lesson:** always verify dimension cardinality on actual silver before claiming a multiplication bug.
