<!--
  Purpose   : Formal results report for one experiment. Covers: data/features summary,
              coherence check, headline accuracy with CIs, ADR threshold comparison,
              failure analysis for any broken baselines, compute profile, limitations,
              and bars set for the next experiment.
  When      : Write after the driver script completes a full end-to-end sweep. This document
              triggers the HALT condition. Do not modify after HALT.
  Where     : research/experiments/<NN_name>/results/report.md
  Links to  : [[../../../decisions/<NNNN-slug>]] (spec), data/queries.sql, src/run.py
  Linked from: [[STATE.md]] (HALT entry), [[decisions/<NNNN+1>-slug]] (bars for next ADR)
-->

# <NN_name> — Results Report

- **Generated**: <YYYY-MM-DD>
- **Spec**: [[../../../decisions/<NNNN-slug>]] v<N>
- **Reproducibility**: data SQL → `data/queries.sql`; driver → `src/run.py`
- **Total runs**: <N> = <breakdown: e.g. M years × K splits × S seeds × P models>
- **Wall-clock**: ~<T> s (<hardware: CPU/GPU note>)

## TL;DR

1. **<Key finding 1 — coherence>.** <Exact max error + threshold>.
2. **<Key finding 2 — best model on split 1>**: <model> — <metric value, % vs baseline>.
3. **<Key finding 3 — best model on split 2>**: <model> — <metric value>. <GNN bar implication>.
4. **<Key finding 4 — broken baseline if any>**: <model> is broken as implemented (<root cause>). <Fix path>. Treat as placeholder.
5. **<Key finding 5 — negative result>**: <model> worse than <baseline>. <Explanation>.

## Data + features used

- **Years**: <year range>.
- **<Primary unit> after filtering**: ~<N> of <M> (<reason for discrepancy>).
- **Target**: `<column_name>` (<description, unit>).
- **Features**: <feature list>. Plus binary missingness masks for each.
- **Caveats** (logged per run):
  - `<feature>` <year> missing in source — <fallback applied>.
  - `<feature>` is <granularity>-level broadcast to all <units> in <parent>. Coarse signal.
  - ≤ <N> <unit> <field> values imputed per year (<method>).

## Coherence — hard constraint check (ADR §<clause>)

| Statistic | Value | Threshold |
|---|---|---|
| Global max coherence error (all <N> runs, all models) | **<value>** | ≤ <threshold> |
| Models satisfying coherence | <n> / <total> | <all / partial> |

<1–2 sentences: how coherence is achieved (post-hoc rescaling vs projection), what the trivial vs
non-trivial regime distinction means for the next experiment.>

## Headline accuracy — per (split, model) with 95% CIs

CIs are Student-t over <N> <seed/year/fold> combinations (<breakdown>).

### Split: `<split_1>` (<description>)

| Model | MAE mean | MAE std | MAE 95% CI | R² levels | R² log | MAPE | Spearman | Fit (s) |
|---|---|---|---|---|---|---|---|---|
| **<best_model>** | **<value>** | <std> | [<lo>, <hi>] | <value> | <value> | <value> | <value> | <t> |
| <model_2> | <value> | <std> | [<lo>, <hi>] | <value> | <value> | <value> | <value> | <t> |
| <model_3> | <value> | <std> | [<lo>, <hi>] | <value> | <value> | <value> | <value> | <t> |
| <broken_model> | <value> | <std> | [<lo>, <hi>] | <value> | <value> | <value> | <value> | <t> |

### Split: `<split_2>` (<description>)

| Model | MAE mean | MAE std | MAE 95% CI | R² levels | R² log | MAPE | Spearman | Fit (s) |
|---|---|---|---|---|---|---|---|---|
| **<best_model>** | **<value>** | <std> | [<lo>, <hi>] | <value> | <value> | <value> | <value> | <t> |
| <model_2> | <value> | <std> | [<lo>, <hi>] | <value> | <value> | <value> | <value> | <t> |

### Skill ratio — MAE relative to `<reference_model>`

| Split | <model_2> | <model_3> | <broken_model> |
|---|---|---|---|
| <split_1> | **<ratio>** (<better/worse>) | <ratio> (<worse>) | <ratio> (<broken>) |
| <split_2> | <ratio> (<tied/worse>) | <ratio> (<worse>) | <ratio> (<broken>) |

## Per-year breakdown

| Year | Split | Best model | Best MAE | Coherence max |
|---|---|---|---|---|
| <year> | <split_1> | <model> | <value> | <value> |
| <year> | <split_2> | <model> | <value> | <value> |

<1-sentence note on year-to-year drift.>

## ADR <NNNN> v<N> threshold check (forward-looking)

ADR sets explicit thresholds for **<next model>** once implemented in `experiments/<NN_next>/`.
The classical numbers tonight define the absolute bar.

| Comparison | ADR target | Required `<next_model>` MAE (<split_1>) | Required `<next_model>` MAE (<split_2>) |
|---|---|---|---|
| `<next_model>` ≤ <N>% of `<baseline>` MAE | strict | ≤ **<value>** | ≤ **<value>** |
| `<next_model>` ≤ <N>% of `<model>` MAE | strict | ≤ <value> | ≤ <value> |
| `<next_model>` ≤ <N>% of `<broken_model>` MAE | strict | n/a (<broken_model> broken) | n/a |
| `<next_model>` ≤ 100% of `<competitor>` MAE | head-to-head | TBD | TBD |
| Coherence ≤ <threshold> at every layer | strict | implementation contract | implementation contract |
| <Other metric> ≥ <threshold> | minimum | already met / TBD | already met |

**Update to ADR <NNNN> required if**: <condition under which a threshold becomes meaningless>.

## Failure analysis — <broken model>

<2–3 sentences: root cause of the degenerate behaviour. What degenerates, why, under what conditions.>

**Fix path (ADR <NNNN+1> scope):**
1. <Step 1 to fix the implementation>.
2. <Step 2>.
3. <Step 3>.

Until fixed, <broken model> numbers in this report should be <ignored / treated as placeholder>.

## Compute baseline numbers (<hardware>)

| Stage | Wall (s) |
|---|---|
| Single <model_1> fit (<description>) | <t> |
| Single <model_2> fit (<description>) | <t> |
| Single <reference_model> pass | <t> |
| Total <N>-run sweep | <T> |

<1 sentence on next-experiment compute implications.>

## Limitations of this report

1. **<Limitation 1>** — <description and mitigation for next session>.
2. **<Limitation 2>** — <description>.
3. **<Limitation 3>** — <description>.
4. **<Limitation 4>** — <description>.

## Conclusions and bars for the next experiment (ADR <NNNN+1>)

1. **<Conclusion 1>**: <what the coherence result implies for the next experiment>.
2. **<Conclusion 2 — the bar is high/low>**: <why, and what the GNN / next model must do differently>.
3. **<Conclusion 3 — which split is the meaningful structural test>**: <why>.
4. **<Conclusion 4 — training signal quality>**: <what the weak-baseline results imply for the next model's signal>.
5. **<Conclusion 5 — what is doing most of the work>**: <feature ablation recommendation>.

## Artifacts

- `data/*.parquet` — frozen snapshot (see `data/README.md`, `data/queries.sql`)
- `data/<graph_artifact_1>.parquet`, `data/<graph_artifact_2>.parquet` — <description>
- `src/models.py`, `src/data_loader.py`, `src/splits.py`, `src/metrics.py`, `src/run.py`
- `results/runs/*.json` — <N> per-run metric dumps
- `results/leaderboard.csv` — <N> rows × <M> columns
- `results/report.md` — this file
