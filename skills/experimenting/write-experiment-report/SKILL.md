---
name: write-experiment-report
description: Generate a robust results/report.md for a research experiment from leaderboard.csv + driving ADR + per-run JSONs. Produces the canonical sectioning used in research/experiments/01_baseline (TL;DR, coherence check, headline accuracy with 95% CIs, skill ratios, optional Theil decomposition, per-year breakdown, ADR threshold check, failure analysis, limitations, bars for next experiment). HALTs for PI review — never auto-commits or auto-bumps ADRs. Use when an experiment driver has finished and the operator asks for a report, or when a previous report needs to be regenerated.
---

# write-experiment-report

Generate a robust `results/report.md` for one experiment, given:

- `<experiment_dir>/results/leaderboard.csv` — one row per run (year × split × seed × model + metrics)
- `<driving_adr_path>` — the ADR with the falsifiable claim(s) and thresholds
- `<experiment_dir>/results/runs/*.json` — optional per-run detail
- `<experiment_dir>/config.yaml` — optional, for data/feature provenance

Canonical exemplar: [[<research-repo>/research/experiments/01_baseline/results/report]] (v5).
`<research-repo>` means the repo the user is working in — the research monorepo that holds
`research/`; resolve it from the current working directory, never a fixed absolute path.
Template skeleton lookup: prefer `<project>/research/templates/experiment-report-template.md` (per-project, may have drift); fallback to bundled `~/.claude/skills/start-research/templates/experiment-report-template.md`.
Methodology rules: [[<research-repo>/research/METHODOLOGY]] §Reports.

This skill **prescribes structure and computations** — the implementer (main thread or an
`experiment-module` subagent) executes pandas / numpy via the project venv
(`research/.venv/bin/python`). Do **not** inline code into this skill; do not compute by hand.

---

## Step 0 — Confirm inputs

1. Resolve `<experiment_dir>` (absolute). Verify `results/leaderboard.csv` exists.
2. Resolve `<driving_adr_path>`. Read it once. Extract:
   - The accepted version (e.g. `v5`).
   - Each falsifiable claim (H1, H2, H3, …) with thresholds (e.g. "`gnn-proj ≤ 75% of prop_pc MAE`").
   - The hard-constraint threshold (e.g. coherence `≤ 1e-6`).
   - The expected metrics list (primary first).
3. List `results/runs/*.json` (best-effort — may be absent).
4. Report which thresholds you could parse and which are flagged **N/A** because the ADR
   text was ambiguous. **HALT if no claim could be parsed.**

---

## Step 1 — Load leaderboard, validate schema

Via `research/.venv/bin/python`, load `leaderboard.csv` with pandas. Required columns:

- Index axes: `year`, `split`, `seed`, `model`
- Core metrics (at least one of each family): `mae*`, `rmse*`, `r2_levels*`, `r2_log*`, `mape*`
- Constraint: `max_coherence_err*`
- Rank: `spearman_mean`
- Cost: `fit_seconds`
- Optional / experiment-specific: `theil_true_between`, `theil_true_within`,
  `theil_pred_between`, `theil_pred_within`, plus any user metrics.

Operations to perform:

1. Detect the **primary metric family** by suffix. If any model name ends in `_pc` or any metric
   ends in `_pc`, treat per-capita as primary; the structural null is `prop_pc`. Else use `prop`.
2. Detect models with zero successful rows → record as **DNF** for the headline table.
3. Detect Spearman columns that are constant-within-group (returns `NaN`) → keep `NaN`,
   surface a footnote, never silently drop.

---

## Step 2 — Compute statistics

For each `(split, model)` group across `seed × year` combinations, compute:

- `mean`, `std`, `n` for every metric column.
- **95% CI via Student-t**: `mean ± t_{0.975, n−1} · std / sqrt(n)`. Use `scipy.stats.t.ppf`.
- If `n == 1` collapse CI to the point estimate and tag the row with a flag (`single-rep`).
- For coherence: take the **global max** across all runs and all models (single scalar).

Skill ratios:

- Pick the null baseline (Step 1.1): `prop_pc` or `prop`.
- For each non-null model and each split, compute
  `skill_ratio = mean_MAE_model / mean_MAE_null`. <1.0 means improvement.

Per-year breakdown:

- For each `(year, split)`, identify the best model by primary metric (lowest MAE family).
- Record best MAE + max coherence error for that year.

Theil decomposition (only if all four `theil_*` columns present):

- Per `(split, model)`: mean of `theil_true_between`, `theil_true_within`,
  `theil_pred_between`, `theil_pred_within`.

ADR threshold check:

- For each parsed claim like "`X ≤ p% of Y`", compute `required_X = p/100 · mean_MAE_Y`
  per split. Flag claims whose `Y` is DNF / broken as **n/a**.

---

## Step 3 — Cross-reference data + features

If `<experiment_dir>/config.yaml` exists, lift:

- Years, target column, aggregation constraint, feature list per year, known caveats.

Else inspect a few `results/runs/*.json` (pick one per year): pull `features_used`,
`target`, `caveats` if present. Otherwise mark the data section as "see ADR §Data sources"
and leave a flag in the report.

---

## Step 4 — Assemble `report.md`

Write `<experiment_dir>/results/report.md` with the following canonical sections, in order.
**Replicate the tone and table shape of [[<research-repo>/research/experiments/01_baseline/results/report]] v5.**

### 4.1 Header

```
# <NN_name> — Results Report (v<N>, <target-flavor>)

- **Generated**: <UTC timestamp>
- **Spec**: [[../../../decisions/<NNNN-slug>]] v<N>
- **Reproducibility**: data SQL → `data/queries.sql`; driver → `src/run.py`
- **Total runs**: <N> = <years> × <splits> × <seeds> × <models>
- **v<N-1> results**: archived at `results/report_v<N-1>_<flavor>.md` (if any)
```

### 4.2 TL;DR — 5 numbered bullets

Each bullet must be fact-grounded (cite the actual scalar from the leaderboard). Required slots:
(1) coherence verdict (max err vs threshold), (2) best model per split, (3) what the structural
null reveals, (4) one positive surprise or fix, (5) one negative result or limitation.

### 4.3 Data + features used

Bullet list (Step 3). Mark coarse covariates and fallbacks explicitly with a blockquote.

### 4.4 Coherence — hard constraint check

Table: global max coherence error vs ADR threshold, runs satisfying / total. One sentence on
how coherence is enforced (post-hoc rescaling vs projection layer).

### 4.5 Headline accuracy per (split, model) with 95% CIs

One subtable per split, sorted by primary metric ascending. Columns: model, MAE mean, MAE std,
MAE 95% CI, R² levels, R² log, MAPE, max coherence err, Spearman, fit (s). Include any custom
metric columns the user has surfaced (same CI treatment).

Show the structural null at the top of each split table even if not best — it is the bar.

### 4.6 Skill ratio table

One row per split, one column per non-null model. Highlight ratios < 1.0 as improvements.

### 4.7 Theil-L inequality decomposition *(if columns present)*

Per `(split, model)`: `true_between`, `true_within`, `pred_between`, `pred_within`. Add a
1-sentence reading: a model captures genuine sub-NUTS3 variation iff `pred_within` rises
toward `true_within`.

### 4.8 Per-year breakdown

Year × split → best model, best MAE, coherence max. 1-sentence note on year-to-year drift.

### 4.9 ADR threshold check (forward-looking)

Table mapping each H-claim from the driving ADR to:
- ADR target (verbatim phrasing)
- Required next-model MAE per split (computed in Step 2)
- Status: strict / minimum / pending / **n/a (broken baseline)**

Every row must wikilink to the ADR via `[[../../../decisions/<NNNN-slug>]]`.

### 4.10 Failure analysis *(only if any model has R²_levels < 0, all-NaN metrics, or anomaly)*

For each failing model:
- Name the runs: `(year, split, seed, model)` tuples.
- Root-cause sketch (2-3 sentences).
- Fix path as a numbered list — should map to a follow-up ADR scope.

### 4.11 Limitations

Numbered list. Always include: missing per-sub-unit metric disaggregation,
no external validation, plus any data caveats logged in Step 3. If Check 6
(bootstrap CI) was skipped or failed in falsifiability-check, state that explicitly here instead.

### 4.12 Conclusions and bars for next experiment

Numbered list of operational implications. **Each bar must restate the threshold in absolute
units** derived from the current null (e.g. "GNN must hit MAE_pc ≤ 1.317e+03 on spatial").

### 4.13 Artifacts

Bulleted file inventory: `data/`, `src/`, `results/runs/`, `results/leaderboard.csv`,
`results/report.md`, plus any archived prior versions.

---

## Step 5 — Append to STATE

Append **one** timestamped line to `<repo_root>/research/STATE.md`:

```
- <UTC timestamp> — `experiments/<NN_name>/results/report.md` regenerated (v<N>, <total_runs> runs). HALT for PI review.
```

STATE is append-only. Never edit prior entries.

---

## Step 6 — HALT

Print to the operator:

1. Path to the new `report.md`.
2. Summary of any flags raised: DNF models, single-rep collapses, NaN Spearmans, unparsed
   thresholds.
3. **HALT.** Do not `git add`, do not commit, do not edit the ADR. Wait for PI review.

---

## Edge cases (must handle, do not crash)

| Case | Behavior |
|---|---|
| ADR thresholds unparseable | List the affected claims, mark required-MAE cells as **N/A** + footnote. |
| Single seed or single year | CIs collapse to point estimates; tag the row `single-rep`. |
| Model with zero successful runs | Insert **DNF** row with NaN-filled metrics; exclude from skill ratio + threshold cells. |
| Both `prop` and `prop_pc` present | Pick whichever family matches the primary metric suffix (Step 1.1). Document the choice in the TL;DR. |
| Custom user-supplied metric columns | Include in the headline table with the same mean / std / CI treatment. |
| `theil_*` columns absent | Skip §4.7 silently. |
| `results/runs/` absent | Continue; data-section pulled from ADR + config.yaml fallback. |
| `config.yaml` absent and no run JSONs | Mark §4.3 as "see [[../../../decisions/<NNNN-slug>]] §Data sources". |

---

## Wikilink discipline

All cross-references inside `research/` use wikilinks **without** file extensions:

- ADR: `[[../../../decisions/0001-research-claim-and-evaluation]]`
- Prior report: `[[../report_v4_total]]`
- Methodology: `[[../../../METHODOLOGY]]`
- Sibling experiments: `[[../../02_gnn/results/report]]`

No raw `.md` URLs; no relative `./` paths.

---

## Worked example — 01_baseline v5

Invocation:

```
write-experiment-report \
  experiment_dir=<research-repo>/research/experiments/01_baseline \
  driving_adr_path=<research-repo>/research/decisions/0001-research-claim-and-evaluation.md
```

Expected output: a `results/report.md` matching
[[<research-repo>/research/experiments/01_baseline/results/report]] structure —

- 120 runs (3 years × 2 splits × 5 seeds × 4 models).
- Coherence max `6.20e-16` vs threshold `1e-6` → §4.4 satisfied.
- Headline tables show `ridge_pc` best on spatial, `prop_pc` best on provincia_block.
- Skill ratios highlight ridge_pc < 1.0 on spatial only.
- Theil §4.7 present (all four columns in leaderboard).
- Per-year breakdown identical to canonical exemplar.
- ADR v5 threshold check produces six rows (3 ratios × 2 splits) + coherence + Spearman.
- No failure-analysis section — no model with R² < 0 in v5 (fh_pc was repaired).
- Conclusions restate `MAE_pc ≤ 1.317e+03` (spatial) and `≤ 1.280e+03` (provincia_block) as
  the GNN bar in absolute units.

The skill **stops** after Step 6. The PI reviews, then chooses to amend the ADR
or proceed to the next experiment. The skill never makes that choice.
