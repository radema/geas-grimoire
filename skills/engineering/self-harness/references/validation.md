# Proposal validation

The paper's contribution *is* the gate: a deterministic verifier plus a held-out split, with a
conservative non-regression acceptance rule. Without that gate you don't have a weaker self-harness —
you have a suggestion engine that can silently degrade the setup while believing it improved. So the
validation path is chosen by what verifier is actually available, which forks by scope.

## Path 0 — Propose-only (the default for every run)

Validation is **off unless the user explicitly asks** for it ("validate the proposals", "run the
evalset", `--validate`). A present `evalset/manifest.yml` does **not** trigger it — the manifest is read
only after validation is explicitly requested. So by default, regardless of whether a manifest exists,
run mining and proposal, then present each candidate diff with its target signature, support count, and
evidence, and stop at a human gate. **Do not fabricate a verifier.** This is the paper's loop minus the
verifier — the same posture user scope is always in. State explicitly in the report that no mechanical
validation was performed and that acceptance rests on human judgment. Paths A–C below run only when
validation was explicitly requested.

## The acceptance rule (all paths that have a verifier)

Evaluate the current harness `h` and each candidate `h(j)` on the same cases. Accept `h(j)` only if:

> it makes **no case worse** and makes **at least one case better**.

(The paper's `Δ_in ≥ 0 ∧ Δ_ho ≥ 0 ∧ max(Δ_in, Δ_ho) > 0`, with "in" = held-in and "ho" = held-out.)
A proposal that merely trades one case for another is **rejected** — that trade is how overfitting
sneaks in. Reject candidates are logged with their failing case, never merged.

Outcomes are stochastic. Run each case **M ≥ 3 times** and aggregate pass counts before comparing,
exactly as the paper repeats stochastic evaluation.

## Path A — Project scope (real verifier, paper-fidelity)

A project repo carries deterministic verifiers: `pytest`, `dbt compile`, `ruff`, `pre-commit`, CI. Use
them as the verifier and a frozen evalset as the task split.

Procedure per candidate edit:

1. **Replay in isolation.** Dispatch the change to an `implementer` subagent with
   `isolation: worktree`. The worktree is the paper's "execution protocol surrounding a fixed model" —
   the model is constant; only the harness (the worktree's `CLAUDE.md`/skill/hook/setting) differs.
2. For each evalset case: set up its frozen start state (copy the `fixtures/<id>/` dir for a
   self-contained case, or check out `work_commit` for a pinned-repo case), apply the candidate harness,
   run the case's prompt, revert the `protect:` paths to their frozen oracle state, then run the verifier
   command. Record pass/fail.
3. Repeat M times per case; aggregate.
4. Apply the acceptance rule against the baseline (current harness) run over the same cases.

See `evalset/README.md` for the two case modes and the oracle-independence rule. The properties that keep
this honest: a frozen start state (a coding prompt's correct outcome depends on it), an oracle the agent
can't edit (`protect:`), the evalset held out from the proposer (or edits overfit it), M repeats for
stochasticity, and a bounded budget.

Budget and worktrees: total `runs = K candidates × N cases × M repeats`, but runs are not all distinct
worktrees. A worktree is pinned to `(repo, commit)`, so the M repeats of a case reuse one worktree
(reset between runs, serial), and cases on the same `(repo, commit)` share a pool. Practical shape is
one worktree per `(candidate × case)` → `K × N` live worktrees; M only lengthens each. **N (cases) and
K (candidates) are the real drivers** — keep N at 5–10, K at 2–4.

## Path B — User scope (no verifier, human gate)

A user-scope edit (`~/.claude/CLAUDE.md`, a global skill, a global hook) affects every project on the
machine and has no mechanically checkable outcome. There is nothing to replay against. Validation here
is:

1. **Forward measurement only** — you cannot test the edit retroactively. State this plainly.
2. **Mandatory human gate** — present the diff, the signature it targets, its support count, and the
   representative evidence. The human decides. The report must label this mode "suggestion engine with
   approval", not autonomous acceptance.

Do not fabricate a verifier for user scope (e.g. an LLM judging whether the edit "would have helped" the
mined failure). That is the circular, overfit gate the paper explicitly warns is insufficient for
higher-stakes changes — and a global edit is the highest-stakes change here.

## Path C — Scheduled / temporal held-out

A recurring run manufactures a held-out split by time. Run N proposes against window N's sessions; run
N+1 measures the target signature's rate in sessions that accrued **after** the proposal. Genuinely
held-out because they postdate it.

- Signal: a generalizing edit lowers its target signature's rate next window without raising others.
- **Mandatory caveat**: if the edit was merged it is live in N+1, so there is no control group. A
  single-window drop is noise. Only a **persistent multi-window drop** is weak confirmation. The report
  must say so every time.
- Scheduled runs **propose only** — draft PR, then stop. A human merges. Never auto-merge, especially
  user scope.

## What to emit

Per candidate: the path used, the raw pass counts (Path A) or the window comparison (Path C) or
"awaiting human gate" (Path B), and the accept/reject decision with its justification. Carry this into
the Step-3 section of the final report. A green result in Path B or C is weaker than a green result in
Path A; never present one without its scope-appropriate caveat.
