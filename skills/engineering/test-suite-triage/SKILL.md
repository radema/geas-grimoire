---
name: test-suite-triage
description: >-
  Review the whole test suite (or a named subpart) to find trivial, redundant,
  and mergeable tests without losing real coverage. Fans out a capped number of
  parallel reviewer subagents that classify every test against a shared
  anti-pattern taxonomy and a KEEP / TRIM-trivial / TRIM-redundant / MERGE
  rubric, then consolidates a ranked report and HALTS for human sign-off before
  any deletion. Use when asked to "review / trim / audit / clean up the test
  suite", "find trivial or redundant tests", "classify these tests", "reduce
  test-suite bloat", or to check tests against the anti-pattern taxonomy.
user-invocable: true
disable-model-invocation: true
---

# Test-suite triage

Classify tests as **KEEP / TRIM-trivial / TRIM-redundant / MERGE** and produce a
ranked, sign-off-gated removal plan. You coordinate; the reviewer subagents
classify. **Nothing is deleted before a human approves a specific subset.**

This skill is self-contained: the taxonomy, rubric, worker prompt, and
verification gate all live under `references/` in this same skill directory.
Do not depend on external docs to run it.

- `references/taxonomy-and-rubric.md` — the 7-class anti-pattern taxonomy, the
  four verdicts, the KEEP guarantees, and the mechanical-edit verification gate.
- `references/worker-prompt.md` — the parametrizable prompt handed to each
  reviewer subagent.

## When to use

- A request to review, trim, audit, or de-bloat the test suite (all of it or a
  named area: one layer, one source, one workflow).
- A periodic hygiene pass after a large feature lands.
- Before a refactor, to retire tests that pin the code you are about to change.

Do **not** use it to _write_ tests (that is a coverage task) or to chase a
failing test (that is debugging).

## Workflow

### 1. Inventory

Enumerate the target tests. Emit the grouped inventory **before** fanning out.

- pytest: every `def test_*` under the target path. Use a recursive glob —
  `tests/**/*.py` with globstar **on** (a non-recursive glob silently misses
  nested source folders; that has burned this repo before).
- dbt data tests: generic + singular tests under your dbt project's model directories.
- dbt unit tests: `unit_tests:` blocks.
  Record per file: test-function count. Group by area (ingestion module, ingestion
  source, gold workflow, delivery product, dbt, shared util).

### 2. Scope & partition (capped fan-out)

Split the inventory into **N review batches**, one per area, each disjoint.

- **`max_workers` (default 8, hard cap 12).** If areas exceed the cap, pack
  several small areas into one batch rather than exceeding it — protects usage.
- Keep a batch focused: one coherent area, ≤ ~120 test functions. Split a giant
  area (e.g. a 100-test cluster) into its own batch.
- A batch that is mostly one function exercised many ways is a MERGE-heavy
  batch — flag it so in the prompt.

### 3. Fan out (parallel, read-only)

Dispatch one **Sonnet** reviewer subagent per batch, **in a single message** so
they run concurrently. Build each prompt from `references/worker-prompt.md`,
filling the file list and the area name. Every worker is **read-only**: it
classifies and reports, it never edits.

Reviewers report back via `SendMessage`, not plain text. Tell them so
explicitly — a plain-text final message is invisible to the coordinator.
When each report lands, dismiss that worker (shutdown request) to save usage;
do not leave idle workers running.

### 4. Synthesize & score

Merge worker tables into one ranked report, most-confident TRIM/MERGE first.
Rank order: TRIM-trivial (high) → TRIM-redundant (high) → the same at
med/low → MERGE groups. Add a summary: N tests total, N per verdict, est.
functions removed / merged, est. LOC, and any area where confidence was low or
workers hedged. List **GAPs** (a module/branch with no logic test) separately —
report only, never auto-fix. Split proposals into **Tier-1 (high-confidence)**
and **Tier-2 (med/low, individual review)**.

### 5. HALT for sign-off

Present the report and **stop**. Do not delete or edit any test until a human
approves a specific subset. An unanswered or ambiguous reply means keep
waiting — never infer approval. This gate is a hard stop, not a self-checkpoint.

### 6. Apply (post-approval only)

For the approved subset:

- Route **pure deletions** to **Haiku** implementers (exact function names,
  small disjoint batches). Route **MERGE/parametrize** and any judgment case
  (dead-helper cleanup, whole-file removal, shadow-fn tests) to **Sonnet** or
  handle in the coordinator — not Haiku.
- Work on a dedicated branch; never commit or push unless the human asks.
- After edits, run the **verification gate** in
  `references/taxonomy-and-rubric.md` (ruff + `py_compile` + post-count check),
  then report pass/fail. The full suite runs in CI (local run is skipped here —
  a local environment/runtime conflict, if your repo has one).

## Guardrails

- Read-only until the HALT gate clears.
- Never propose removing a test whose name/docstring cites a ticket, incident,
  or regression — flag it KEEP and say why.
- Prefer fewer high-confidence proposals over many shaky ones.
- Whole-file deletion and dead-helper cleanup need human/coordinator judgment,
  not a Haiku batch — a name-list deletion agent will not decide them safely.
