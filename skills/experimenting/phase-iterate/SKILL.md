---
name: phase-iterate
description: Standardize the smoke-fail → diagnose → minimal-patch → re-smoke loop for ML / research experiments where a single design pass rarely passes the acceptance gate. Use when an experiment driver is in place but smoke fails on a measurable acceptance criterion, OR when a series of similar smoke-fail-diagnose-patch cycles is anticipated. Caps the loop at N attempts before HALT-to-PI, captures every iteration in the experiment's LOG.md, and routes patch dispatch by complexity (Haiku trivial / Sonnet mechanical / Opus architectural).
---

# phase-iterate

Standardize the iteration loop that recurs when a research experiment can't pass its acceptance gate on the first design pass. Common in ML training-loop work where loss formulation, scale parameters, val signals, or regularization terms interact in non-obvious ways.

## When to invoke

- Experiment driver exists and runs end-to-end.
- Acceptance criterion is **measurable** (a number, a comparison, a verdict).
- First smoke FAILED.
- You expect ≥2 more attempts before pass, OR the failure cause is unclear.

**Skip** if a single targeted fix is obvious AND likely to pass on first retry.

## Loop structure

```
for iter in 1..N_MAX:
  1. Run smoke (driver --smoke).
  2. Check acceptance criterion.
  3. If PASS → exit loop, route to falsifiability-check, then HALT for PI approval before dispatching the full sweep.
  4. If FAIL:
     a. Diagnose (probe / inspect / print / unit test).
     b. Propose minimal patch (1-3 lines OR 1 kwarg change OR 1 loss term).
     c. Dispatch patch subagent (Haiku for trivial / Sonnet for mechanical / Opus for architectural).
     d. Log iteration to <experiment>/LOG.md.
     e. continue.
  5. If iter == N_MAX → HALT to PI. Report all attempts + recommendation.
```

## Inputs

- `<experiment_dir>` — absolute path to the experiment folder.
- `<smoke_cmd>` — exact shell command to run the smoke (e.g. `research/.venv/bin/python research/experiments/03_gnn_enriched/src/run.py --phase 3 --smoke`).
- `<acceptance>` — measurable criterion as either:
  - A list of metric thresholds: `theil_within > 0.001`, `coherence_nuts3 <= 1e-6`, `mae_pc < 2500`.
  - A column-distinctness rule: `predictions across ablations differ by >1e-3`.
- `<N_MAX>` — max iterations before HALT (default 4).
- `<driving_adr>` — wikilink to the relevant ADR for context.

## Steps

### Step 1 — Read

1. The acceptance criterion (parse to machine-checkable form).
2. The latest `<experiment_dir>/LOG.md` to know prior iterations (don't repeat).
3. The ADR halt-conditions (they bound what's defensible).

### Step 2 — Run smoke

Execute `<smoke_cmd>`. Capture stdout + stderr + exit code. Read the resulting per-run JSON / leaderboard.

### Step 3 — Check acceptance

For each criterion, compute PASS/FAIL on the smoke output. If ALL pass → return success.

### Step 4 — Diagnose

Per the failure mode:
- **All-error**: read traceback. Most common cause: empty partition, NaN, missing key. Find the failing function + line.
- **Metric below threshold**: print intermediates (gradients, activations, intermediate tensors). The probe script pattern: load model, forward one batch, compare pre-vs-post each transformation.
- **Ablations identical**: byte-compare per-run JSON. Locate where kwargs flow OR where loss touches the ablated quantity.

Surface the **single most likely root cause** with a 1-sentence hypothesis. If 2+ hypotheses are equally likely → HALT, ask PI.

### Step 5 — Propose minimal patch

Patch must be:
- ≤ 5 lines of code change in the smallest scope (1 file ideally).
- Single concept (don't bundle "fix bug AND change loss AND add feature").
- Reversible if it doesn't work.
- Documented in the LOG entry.

If proposed patch needs > 5 lines / > 1 file → escalate to Opus + tag as "architectural iteration".

### Step 6 — Dispatch patch

Per `/root/.claude/CLAUDE.md` (user-scope) model routing:
- **Haiku** if patch is trivially mechanical (rename, single-line, type-cast).
- **Sonnet** if patch needs a port / multi-line edit from a clear contract.
- **Opus** if patch is architectural (loss design, gradient flow, new abstraction).

Subagent prompt must include:
- Iteration number (`iter K of N_MAX`).
- Patch diff (exact lines).
- Acceptance criterion to verify after patch.
- Constraint: don't go beyond the 5-line scope.

### Step 7 — Log

Append entry to `<experiment_dir>/LOG.md` under a Timeline section:

```markdown
### <UTC> — Iteration (<patch-id>): <one-line description>
- **Failure mode**: <symptom from smoke>
- **Hypothesis**: <single sentence>
- **Patch**: <file:line> — <1-line diff summary>
- **Acceptance**: <PASS / FAIL after re-smoke>
- **Numbers**: <metric values pre vs post>
```

Use stable patch IDs (`D`, `d`, `c`, `e3` are valid — any short token).

### Step 8 — HALT

After `<N_MAX>` iterations without pass:
- Stop the loop.
- Print all attempts table.
- Recommend ONE of: (a) reframe the acceptance criterion, (b) reopen the driving ADR, (c) declare blocker → switch to PI option (B-style reframe).
- Do NOT auto-commit. Do NOT amend the ADR.

## Constraints

- Acceptance criteria parsed from PI brief or ADR, never invented mid-loop.
- Patches reversible (git working-tree → easy revert if iter K+1 needs to undo iter K).
- One file scope per iteration unless explicitly architectural.
- LOG.md is the source of truth for iteration history — never edit prior entries.
- Don't commit between iterations (atomic commit pass after PASS / HALT).

## Anti-patterns

- **Compound patches** ("fix the bug AND tune the lr AND add a feature") — guarantees you can't attribute the result.
- **Skipping diagnosis** — going straight to a patch without printing the symptom. Wastes iterations.
- **No N_MAX cap** — silent infinite loops on unfalsifiable problems.
- **Committing per iteration** — pollutes git history with smoke-fail commits. Commit after PASS / HALT.

## Outcomes

- **PASS**: route to falsifiability-check next. Full sweep is NOT dispatchable yet — HALT and wait for explicit PI approval after falsifiability-check completes. Skill returns with PASS verdict + LOG entry.
- **HALT-to-PI**: N_MAX hit. Skill returns failure mode taxonomy + recommended reframe.
- **Blocker**: a patch surfaces a deeper issue (e.g. structural no-op of ablations) → escalate to peer-reviewer + ADR amendment.

## Example invocation

```
phase-iterate \
  experiment_dir=/abs/path/research/experiments/03_gnn_enriched \
  smoke_cmd="research/.venv/bin/python research/experiments/03_gnn_enriched/src/run.py --phase 3 --smoke" \
  acceptance="theil_within > 0.001 ; coherence_nuts3 <= 1e-6 ; mae_pc < 2500" \
  N_MAX=4 \
  driving_adr=[[../../decisions/0001-research-claim-and-evaluation]]
```

Returns: iteration log + PASS/HALT verdict + leaderboard if PASS.
