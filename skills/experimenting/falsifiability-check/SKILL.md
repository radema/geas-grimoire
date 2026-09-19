---
name: falsifiability-check
description: Pre-report sanity check for ML / research experiments. Verifies (a) every ablation produces measurably distinct predictions, (b) every claim metric is gradient-bearing during training, (c) every gate threshold maps to a parsed ADR clause, (d) no silent no-op or asymmetric comparison. Invoke immediately before write-experiment-report or before any external claim. Returns PASS / FAIL-WITH-FINDINGS; FAIL routes back to phase-iterate.
---

# falsifiability-check

Pre-report sanity gate. Catches the class of bugs that the peer-reviewer finds after the report is written: ablations that are structurally no-op, comparisons that are asymmetric, parameters that look learnable but have no gradient, gates that don't match what the ADR claims.

## When to invoke

- An experiment sweep finished (full or partial).
- Before calling `write-experiment-report`.
- Before publishing any number to a wider audience.
- Whenever you'd say "the model wins on metric X" — verify X is what the architecture actually controls.

**Skip** only if the experiment is exploratory AND a PI has explicitly signed off tagging it "not for falsifiability" — the acting agent must not apply this tag unilaterally; if no PI sign-off is on record, run the check.

## Inputs

- `<experiment_dir>` — absolute path.
- `<driving_adr>` — wikilink to the ADR with the claim(s).
- `<leaderboard_path>` — usually `<experiment_dir>/results/leaderboard*.csv`.
- `<runs_dir>` — per-run JSON dir, usually `<experiment_dir>/results/runs/`.

## Checks

### Check 1 — Ablation distinctness

For every `(model, year, split, seed)` block in the leaderboard, compute pairwise differences across ablation labels.

- For numeric metric `mae_pc`: at least 1 ablation pair must differ by ≥ 1% of baseline mean.
- For prediction vectors (if stored in per-run JSON): max pairwise L1 ≥ 1e-3.
- If ALL ablations are byte-identical for ANY model → **FAIL**. Likely cause: ablation kwargs not reaching the model, OR loss decoupled from the ablated quantity.

### Check 2 — Gradient flow on all learnable parameters

For each model trained:
- Load the saved model state.
- Run one forward + backward pass on a held-out batch.
- For every `nn.Parameter` with `requires_grad=True`, assert `.grad is not None and .grad.abs().max() > 0`.
- Specifically flag parameters that **did not move from init** across ALL seeds — strong indicator of broken gradient path.

If any parameter is silent → **FAIL** with the parameter name + suspected cause.

### Check 3 — Gate ↔ ADR mapping

Parse the driving ADR for each claim (H1, H2, …). For each gate threshold in the experiment config:
- Does the threshold value match the ADR text?
- Does the gate metric match the H-claim subject?
- If MAE gate compares against baseline `X`, is `X` the same baseline the ADR named?

If a gate threshold has no ADR provenance → **FAIL**. (Defensible exception: the threshold is provisional, tagged `pending` in the config.)

### Check 4 — Symmetric comparison

When the report makes a claim like "model A beats model B on metric M":
- Did A and B receive the same training-loss surgery?
- Did A and B see the same features, scale parameters, regularization, val signal?
- If A got patches B didn't → the comparison attributes results to the wrong cause.

If asymmetric → **FAIL** unless the asymmetry is explicitly documented as intentional ("ablation tests effect of patch X").

### Check 5 — Coverage matrix sanity

For every `(model, ablation, split, year, seed)` cell:
- Is `status == "done"`?
- If any cell is missing or `error` → flag as DNF.
- Report % coverage. If < 80% → tag findings as PROVISIONAL in the report header.

### Check 6 — Bootstrap CI determinism + same-Δ consistency

For every pairwise comparison reported as a CI in the experiment write-up (or the leaderboard if no report exists yet):

- **Same-Δ inconsistency**: scan the report and any auxiliary tables (gate-check, headline, decomposition) for the SAME underlying paired comparison (`(family_a, model_a) − (family_b, model_b)` on the same split). If two CIs are printed for the same Δ and they disagree on stat-sig (one CI entirely below 0, the other crossing 0) → **FAIL** with the seed mismatch as the root cause. This catches the "bootstrap-seed artifact" failure mode where the analyst re-ran the bootstrap with different RNG state and got opposite stat-sig calls.
- **Seed reproducibility**: the report (or its aggregation script) must declare `bootstrap_seed: int` + `n_resamples: int`. If absent → **FAIL** with "no bootstrap reproducibility metadata".
- **Sample-size sensitivity**: when the comparison has `n_observations < 20` paired diffs, the report must include a 20-seed sensitivity row (e.g. via `research.common.bootstrap.seed_sensitivity`). The row must show `% of CIs that cross zero` across the seed range. If the comparison is presented as stat-sig but `>25%` of seeds cross zero → **FAIL** with "stat-sig call not robust to bootstrap-seed choice"; downgrade verdict to borderline.

If any Check 6 element FAILs → STOP. The headline claim is bootstrap-seed-dependent and the report cannot be defended. Root cause is usually a non-deterministic `random.seed(...)` call inside the aggregation script — fix by lifting to `research.common.bootstrap` with explicit `random.Random(seed)` and re-running aggregation.

### Check 7 — Rank vs scale (Pearson is affine-invariant)

Whenever a claim of **distinctness** ("model differs from baseline X") or **collapse** ("model ≈ baseline X")
rests on a **Pearson correlation** (e.g. `corr_vs_prop`), Pearson alone is insufficient — it is invariant to
affine rescaling and dominated by a few large cells. The same Pearson value can hide two opposite stories:

- High Pearson but the model **reorders** units (a monotone-but-nonlinear reshape) → "collapse" is overstated.
- Low Pearson but **rank is preserved** (Spearman ≈ 1, only magnitudes/curvature change) → "distinct" is overstated
  (it is a magnitude rescale of the baseline, not a genuine reallocation).

So: for every Pearson-based distinctness/collapse claim, the report MUST also carry **Spearman correlation**
**and** a **% reallocated** metric (e.g. `pct_lau_reallocated` — fraction of units whose within-group rank vs
the baseline changed). Cross-check:

- **Collapse claim** (corr ≈ 1): require Spearman ≈ 1 AND pct-reallocated ≈ 0. If Spearman < 1 or pct-reallocated
  is non-trivial while Pearson ≈ 1 → the "collapse" is rank-incomplete; downgrade to "magnitude-aligned, rank-distinct".
- **Distinctness claim** (corr well below 1): require Spearman to corroborate genuine reordering. If Spearman ≈ 1
  while Pearson is low → the model only rescaled magnitudes, did not reorder; state that explicitly, do not claim
  "reallocates / reorders".

If a Pearson-only distinctness/collapse claim is made with no Spearman + reallocation corroboration → **FAIL**
with "rank-vs-scale unverified". (This recurred in 04b and 04c peer reviews — it belongs in the gate, not after.)

### Check 8 — Comparability gate

Every model or configuration appearing in a comparison table or bar chart must be solving the **identical problem** — not merely sharing a metric name.

Concretely, verify that all compared entries share:
- **Same margins**: identical row totals and column totals (or the same absence of marginal constraint).
- **Same masking**: the loss and the evaluation metric must be computed over the exact same set of cells (e.g. off-diagonal only vs. full matrix).
- **Same diagonal / self-arc handling**: either all entries include the diagonal in prediction + evaluation, or none do. Mixed handling — diagonal carved out for one entry, competing in another — inflates one entry's metric denominator relative to the other's.
- **Same candidate set**: if softmax denominator or normalisation pool differs, probabilities are not on the same scale.

If any structural mismatch exists across the entries being compared → **FAIL** with the specific mismatch (e.g. "classical baseline evaluated on full matrix including diagonal; GNN evaluated on cross-only; numbers not comparable"). This is a silent failure mode: the metric label looks identical, so the mismatch is easy to miss for many iterations. (This session: classical bars ran full-margin while the GNN ran cross-only; the inflated bar went unnoticed across multiple comparison rounds.)

### Check 9 — Noise-floor gate

Before any delta between configurations is interpreted as a meaningful result, the **run-to-run noise floor** must be established.

Requirements:
- At minimum, **one config must be repeated at a fixed seed** (determinism check); alternatively, ≥ 2 independent repeats of the same config at the same fixed seed to measure non-determinism from GPU/CUDA sources.
- The observed noise floor (max absolute variation across repeats) must be documented explicitly (e.g. in the run JSON or leaderboard header).
- Any reported delta smaller than the noise floor is **not a claim** — tag it `< noise-floor` and do not interpret it directionally.

If no noise-floor measurement exists → **FAIL** with "noise floor not established; deltas not interpretable". If a reported delta is below the documented noise floor → **FAIL** with the specific comparison and the noise floor value. (This session: single-seed runs showed ± ~0.05–0.08 non-determinism at fixed seed; two full hyperparameter ladders were built and then retracted because their deltas were below noise — the waste was avoidable had the floor been established first.)

## Outputs

Write `<experiment_dir>/results/falsifiability_check.md` with:

```markdown
# Falsifiability check — <experiment> — <UTC>

## Verdict
- Overall: PASS / FAIL-WITH-FINDINGS
- Coverage: <pct>%

## Check results

| Check | Status | Finding |
|---|---|---|
| 1. Ablation distinctness | PASS / FAIL | <one-line> |
| 2. Gradient flow | PASS / FAIL | <one-line> |
| 3. Gate ↔ ADR mapping | PASS / FAIL | <one-line> |
| 4. Symmetric comparison | PASS / FAIL | <one-line> |
| 5. Coverage | PASS / PROVISIONAL / FAIL | <pct>% |
| 6. Bootstrap determinism | PASS / FAIL | <seed declared? same-Δ consistent? 20-seed sens row if n<20?> |
| 7. Rank vs scale | PASS / FAIL / N/A | <Pearson distinctness/collapse claims corroborated by Spearman + % reallocated? N/A if no Pearson-based claim> |
| 8. Comparability | PASS / FAIL | <same margins, masking, diagonal handling, candidate set across all compared entries?> |
| 9. Noise floor | PASS / FAIL | <noise floor documented? all reported deltas above floor?> |

## Findings detail

(per-check, with file:line where possible)

## Recommendations

- If any FAIL → return to phase-iterate with the failing check as new acceptance.
- If PROVISIONAL coverage → mark in report TL;DR bullet 1.
- If all PASS → proceed to write-experiment-report.
```

## HALT gates

- **Check 1 FAIL**: STOP. Do not write the report. Diagnose ablation hook code path.
- **Check 2 FAIL**: STOP. Verify the parameter is in optimizer's param_groups + has `requires_grad=True`.
- **Check 3 FAIL**: STOP. Either update the ADR (with PI approval) or update the gate.
- **Check 4 FAIL**: STOP. Add the missing symmetric ablation OR document the asymmetry as an intentional contrast.
- **Check 6 FAIL**: STOP. Lift aggregation to a deterministic helper (e.g. `research.common.bootstrap` with `random.Random(seed)`); re-run; if `>25%` of 20 seeds cross zero, downgrade the headline call to borderline OR drop the sub-claim entirely.
- **Check 7 FAIL**: STOP. Add Spearman + %-reallocated alongside every Pearson-based distinctness/collapse claim; restate the claim to match what rank + scale jointly show (magnitude-aligned vs genuinely reordered) before the report ships.
- **Check 8 FAIL**: STOP. Align all compared entries to the identical problem setup (margins, masking, diagonal handling, candidate set) and re-run the affected sweep before any comparative claim is made.
- **Check 9 FAIL**: STOP. Run ≥ 2 repeats of one config at a fixed seed to measure the noise floor; re-evaluate all reported deltas against it; drop or tag `< noise-floor` any delta that does not clear it.

## Constraints

- Read-only on experiment artifacts (don't mutate runs, leaderboards, configs).
- Write only to `results/falsifiability_check.md` + append one STATE.md line.
- No git commits.
- Wikilinks for `research/` cross-references.

## Anti-patterns this skill prevents

- "We claim H1 wins because architecture X" when X also got training-loss surgery that the comparison model didn't.
- "Ablation A2 lowers Theil-within by 12%" when A2 also lowers MAE proportionally — likely correlation collapsed.
- A learnable scale parameter that "stayed at init" — usually broken gradient, sometimes optimal but rarely both.
- A 2-seed result tagged "winner" when other models have 5.
- "Model collapses to baseline (corr ≈ 1)" reported from Pearson alone, when Spearman < 1 / units reallocated — or "model is distinct" when Spearman ≈ 1 and only magnitudes moved. Pearson hides rank vs scale.
- "Classical baseline outperforms GNN on MAE" when the classical baseline was evaluated on a full matrix (diagonal included) and the GNN on cross-only — the same metric name, a different denominator, incomparable numbers.
- "Config B beats config A by 0.03 MAE" when the same model at fixed seed varies by ±0.06 across runs — the delta is below noise and the claim is noise, not signal.

## Cross-references

- Pair with `phase-iterate` (precedes a sweep) and `write-experiment-report` (succeeds this check).
- Findings feed into `peer-reviewer` agent if dispatched.
