> Worked example referenced from the start-experiment skill. Historical example, not the general pattern.

# Specific behavior: continuing ADR 0003 §"Session N+1"

This is the canonical use case the skill is built for. When the user says "start the next experiment" / "continue ADR 0003" / "run start-experiment on the roadmap", do the following without re-asking for confirmation on each item — surface them all together at Step 6:

1. **Read** `<research-repo>/research/decisions/0003-roadmap.md` fully. Target section: `### Session N+1 — Honest GNN benchmark (v2)`. Sub-items 1, 1b, 1c, 4, 5, 6.
2. **Slug**: default `gnn_enriched` (offer override). Folder: `research/experiments/03_gnn_enriched/`.
3. **README.md** must encode:
   - Driving ADR: `[[../../decisions/0003-roadmap]]` §"Session N+1 — Honest GNN benchmark (v2)".
   - Headline claim: "**Theil-L `pred_within` ≥ 0.006**" (vs true 0.0083; baseline `fh_pc` = 0.0039).
   - Secondary: **MAE_pc ≤ 1,317 €/person on spatial split / ≤ 1,280 €/person on provincia_block**.
   - Splits: spatial-random (frac 0.2) + provincia_block (k=20). Seeds: 0–4. Years: 2022/2023/2024.
   - Model variants: `gnn-soft`, `gnn-wb`, `gnn-proj` (per ADR 0002 v3).
   - Ablations:
     - **A1** — 10% NUTS3 aggregates blanked; verify projection coherence.
     - **A2** — drop `log_pop`; confirm no pop-leakage.
     - **A3** — backbone swap GCNII / GraphSAGE / plain GCN, same projection + heads.
     - **A4** — multi-level constraint {NUTS3 ∪ NUTS2 ∪ NAT} via SVD-threshold.
     - **A5** — temporal smoothness on/off.
   - Halt conditions (verbatim from ADR §"Halt-if"): (a) `gnn-proj` does not beat `fh_pc` on Theil-L within after covariate enrichment → reopen ADR 0002; (b) A4 shows no advantage over NUTS3-only → H1 effectively unfalsifiable.
4. **config.yaml** placeholders:
   ```yaml
   years: [2022, 2023, 2024]
   splits: { spatial: { frac: 0.2 }, provincia_block: { k: 20 } }
   seeds: [0, 1, 2, 3, 4]
   models: [gnn-soft, gnn-wb, gnn-proj]
   ablations:
     A1: { blank_nuts3_frac: 0.10 }
     A2: { drop_features: [log_pop] }
     A3: { backbones: [gcnii, graphsage, gcn] }
     A4: { constraint_levels: [NUTS3, NUTS2, NAT], svd_threshold: 1.0e-8 }
     A5: { temporal_smoothness: [true, false] }
   target: taxable_income_per_capita
   exposure: population
   projection: { dtype: float64 }   # ADR 0003 v2 §1c — cast PopWeightedProjection matmul to float64
   tracking: { backend: mlflow }    # ADR 0003 v2 Phase 1 — MLflow logging
   features:
     # TODO(ADR-0003 §1b): pick 4–8 LAU-granular covariates from the enriched set
     - n_firms_total          # from gold.com_opencomuni_business_y
     - employment_rate_lau    # from silver.fact_istat_census_occupazione
     - education_share_high   # from silver.fact_istat_census_istruzione
     # household / housing / unemployment LAU-level — TODO finalize
   ```
5. **data/queries.sql** stub must include placeholder blocks for the **NUTS crosswalk** (`pro_com` ⨝ `gisco_id` ⨝ `nuts3_eurostat`) and for each enriched covariate table:
   - `gold.com_opencomuni_business_y`
   - `silver.fact_istat_census_occupazione`
   - `silver.fact_istat_census_istruzione`
   - `silver.fact_istat_famiglie`
   - `silver.fact_istat_abitazioni`
   - `silver.fact_istat_disoccupazione`
   - `silver.dim_istat_territorio_comuni`, `silver.dim_eurostat_gisco_lau`, `silver.dim_eurostat_gisco_nuts` (crosswalk inputs)
   Plus `DESCRIBE TABLE` lines for each. Bodies are `-- TODO(dbx-snapshot)` — the agent fills in the SELECT.
6. **src/models.py** stub: `MODELS = {"gnn-soft": ..., "gnn-wb": ..., "gnn-proj": ...}` with `TODO(ADR-0002 §<arch>):` markers. Projection module must `TODO(ADR-0003 §1c): cast matmul to float64`.
7. **src/run.py** stub: load `config.yaml`, init MLflow (`mlflow.start_run()` + `log_param/log_metric/log_artifact`), iterate `(year, split, seed, model, ablation)`, write per-run JSON to `results/runs/`. `TODO` markers for actual training calls.
8. **Dependencies** in README: add `mlflow` to the install list (ADR 0003 Phase 1, ~5 lines of tracking calls per ADR).
9. **STATE.md** entry, in addition to the standard one, must mention the float64 projection cast and MLflow-tracking deps as the two implementation-fix deltas vs 02_gnn.
10. **Recommended dispatch order**:
    1. `dbx-snapshot` agent → produce `data/nuts_crosswalk.parquet` + the 6 covariate parquets + populated `queries.sql`.
    2. `experiment-module` agent — module 1: `data_loader.py` (load + merge crosswalk + cov tables).
    3. `experiment-module` agent — module 2: `models.py` with float64 projection cast + GraphSAGE / GCN backbones.
    4. `experiment-module` agent — module 3: `run.py` + MLflow + ablation loop.
    5. Smoke run on 1 year × 1 seed × 1 model — then HALT for PI before full sweep (90 runs, GPU-cost-gated per ADR 0003).

---
