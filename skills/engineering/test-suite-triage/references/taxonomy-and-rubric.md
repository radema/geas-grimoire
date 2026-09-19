# Test triage — taxonomy, rubric, and verification gate

Self-contained reference for `test-suite-triage`. Everything a reviewer needs to
classify a test lives here; do not rely on external docs.

## The four verdicts

| Verdict            | Meaning                                                                      | Action                                                          |
| ------------------ | ---------------------------------------------------------------------------- | --------------------------------------------------------------- |
| **KEEP**           | Guards a real branch, edge case, boundary, invariant, or a named regression. | Untouched.                                                      |
| **TRIM-trivial**   | Asserts nothing about our logic (see taxonomy).                              | Delete.                                                         |
| **TRIM-redundant** | The branch it covers is already covered elsewhere.                           | Delete.                                                         |
| **MERGE**          | Same function/branch as ≥1 sibling with only trivially different input.      | Fold into one `@pytest.mark.parametrize` — **no case dropped**. |

Assign one verdict per test function, plus a one-line rationale and a confidence
(`high` / `med` / `low`). Bias to KEEP when unsure — a test is cheap; lost
coverage is not.

## Anti-pattern taxonomy (TRIM-trivial classes)

1. **`pass`-stub / no-assert** — body is `pass` or has zero assertions.
2. **Fixture / CSV echo** — asserts only that a constant equals itself:
   `assert len(X) == N`, exact set/dict equality that re-lists the code's own
   table (a tag→family map, a config registry, a category list).
3. **Getter / passthrough** — asserts a property returns its literal, or a thin
   wrapper forwards to a helper, with no branch exercised.
4. **Framework-behavior** — tests the platform, not our code: that Spark `SUM`
   ignores nulls, that pandas casts a column, that a mocked `requests`/
   `subprocess` returns what you set, that a dataclass raises `TypeError` on a
   missing arg.
5. **Tautology** — reimplements the formula/exit-condition inline in the test
   and asserts the reimplementation, never invoking the real function/macro.
6. **Shadow-helper** — defines a _local copy_ of a module function and tests the
   copy, so production code is never exercised (worse: the copy's expected
   behavior can silently contradict the real function's contract).
7. **Schema/const invariant** — asserts a static module constant is unique / the
   right length / ASCII-safe, exercising no logic.

## TRIM-redundant classes

- **Cross-file duplicate** — same branch asserted in two files (sometimes a
  byte-identical function); keep the focused one, drop the copy.
- **Script-vs-module duplicate** — a per-source script test duplicates a
  module-level test of the shared component. Keep the module test.
- **Example subsumed by property** — an example-based test whose exact case a
  property/parametrized test already generates. (Inverse also: if a property
  never reaches a case, the example is **KEEP** — real unique coverage.)
- **Fixture-sibling** — several tests share one fixture and each asserts a facet
  the primary test already asserts.

## KEEP — never propose removing

- Any test whose name/docstring cites a ticket, incident, or regression.
- A real branch, edge case, or boundary (esp. NULL vs 0 vs NaN, if your project
  documents that distinction as an invariant).
- A mathematical / statistical invariant (property tests, determinism,
  sum-preservation, monotonicity).
- The one test that reaches a branch no property/parametrize covers.
- A documented prod-incident guard.

## MERGE — how to judge

Two+ tests are a MERGE group when they call the **same function** and differ only
in input that routes to the **same branch** (e.g. four synonym tags all hitting
one classifier family; a clamp tested on col A then col B; `None` vs `""` both
hitting one fallback). They are **NOT** a MERGE when each input exercises a
_distinct_ branch — those are all KEEP. When collapsing, the parametrized test
must keep one row per original input; never silently drop a case.

## Verification gate (mechanical edits, step 6)

Run after any approved deletion/merge, before reporting done:

1. `uv run python -m py_compile <each edited file>` — syntactic validity.
2. `uv run ruff check <edited files>` — catches unused imports **and** `F821`
   undefined-name (a real NameError when a deletion removed a helper/alias a
   _kept_ test still used). Fix only import-order / unused-import fallout your
   edits caused.
3. **Post-count check** — `grep -cE '^\s*def test_'` per edited file vs the
   expected remaining count. Catches a missed or over-eager deletion (a reviewer
   or an implementer dropping the wrong number of functions).
4. If every test in a file was removed, the file becomes a hollow shell — flag
   it for a **human decision** (delete file vs keep as scaffold). Do not
   `git rm` a whole pre-existing file on your own authority.

If a local full-suite run is impractical (e.g. a runtime/environment conflict),
skip it and rely on CI for real green; note whatever repo-specific local-smoke
recipe applies instead of the project's default virtual environment.
