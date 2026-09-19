# Reviewer subagent prompt template

Fill `{{AREA}}` and `{{FILE_LIST}}`, then dispatch as a **Sonnet**, read-only
subagent. Paste the taxonomy/rubric inline (from `taxonomy-and-rubric.md`) or
tell the worker to read that file — either keeps the skill self-contained.

---

READ-ONLY. Do NOT edit, delete, or move any file. Classify every test function
in your area for a test-suite triage of this repo (cwd is the repo root).

**IMPORTANT — reporting:** your plain-text output is NOT visible to the
coordinator. You MUST report by calling the `SendMessage` tool addressed to the
coordinator (or `main`), with the full markdown table in the `message` field.

## Your area: {{AREA}}

Classify EVERY test function in each file:
{{FILE_LIST}}

## Rules (binding)

- Verdicts: KEEP / TRIM-trivial / TRIM-redundant / MERGE. One per test function.
- **TRIM-trivial** = asserts nothing about our logic: `pass`-stub, fixture/CSV
  echo (`len==N`, set/dict equality re-listing the code's own table), getter/
  passthrough, framework-behavior (tests Spark/pandas/requests, not our code),
  tautology (reimplements the formula, never calls it), shadow-helper (tests a
  local copy of a module fn), static-constant invariant.
- **TRIM-redundant** = branch already covered: cross-file duplicate (incl.
  byte-identical), script-vs-module duplicate, example subsumed by a property/
  parametrized test, fixture-sibling re-asserting the primary test's facts.
- **MERGE** = same function/branch as a sibling, only trivially different input
  → one parametrized test. Name the merge group. NOT a merge if each input hits
  a distinct branch (those are KEEP).
- **KEEP (never propose removing):** any test citing a ticket/incident/regression
  in its name or docstring; a real branch/edge/boundary (esp. NULL vs 0 vs NaN);
  a math/statistical invariant; the sole test reaching an otherwise-uncovered
  branch; a documented prod-incident guard.
- dbt owns data-quality (not_null/unique/accepted_values/row-counts). A pytest
  that merely re-asserts a fact dbt already guards is TRIM-redundant. A dbt test
  guarding a real invariant is KEEP.

## Method

Read each test file. When a verdict depends on whether logic lives in a shared
module vs a thin wrapper, open the module under test to confirm. Be
conservative: prefer fewer high-confidence proposals over many shaky ones.

## Output contract — one markdown table row per test function:

`| file:line | test_name | verdict | rationale (one line) | confidence |`
End with a 3-line summary: counts per verdict + any GAP (a module/branch with no
logic test). Do NOT edit anything.
