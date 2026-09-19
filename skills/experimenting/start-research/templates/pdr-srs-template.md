<!--
  PDR+SRS template — one per Python module (or tightly-coupled module group).
  Combined Preliminary Design Review (how it's built) + Software Requirements
  Spec (what it must do). Lives in research/experiments/<NN>/docs/.
  Governs the SAM→LAU track; reusable for any staged-build experiment.

  Rules:
  - One doc = one module/script (OVERVIEW.md is the only exception — system index).
  - Keep it a CONTRACT a builder (or experiment-module agent) can execute against.
  - YAGNI/KISS is mandatory: the "Out of scope" section is not optional.
  - Reference ADRs; do NOT duplicate their decision rationale here.
  Delete this comment block in instances.
-->

# <DOC_NAME> — <one-line module title>

| Field | Value |
|---|---|
| **Maps to** | `src/<module>.py` (+ any tightly-coupled files) |
| **Phase** | Phase 1 (IO-LAU build+train) / Phase 2 / … |
| **Status** | as-built / spec-to-build / partial |
| **Governing ADRs** | [[../../../decisions/1000-gnn-sam]] §X, … |
| **Last updated** | YYYY-MM-DD |

## 1. Purpose & scope

One paragraph: what this module owns in the pipeline, where it sits in the
`ingest → graph → model → loss → train → balance → eval` flow, and its single
responsibility. State the phase boundary if behaviour differs across phases.

## 2. Requirements (SRS)

Numbered, each checkable. `FR-<DOC>-NNN` functional; `NFR-<DOC>-NNN` non-functional.

- **FR-<DOC>-001** — <verb + object + observable outcome>. (witness/gate if any)
- **FR-<DOC>-002** — …
- **NFR-<DOC>-001** — storage / determinism / off-cluster-import / performance bound.

Mark each requirement's state where useful: `[built]` / `[to-build]`.

## 3. Design (PDR)

- **Public interface** — function/class signatures (real, copy-pasteable):
  ```python
  def fn(arg: T, ...) -> R: ...
  class C: ...
  ```
- **Data structures** — key types, shapes, dtypes, invariants.
- **Algorithm / control flow** — the core math/logic in prose + the few equations
  that matter; cite the ADR section, don't re-derive.
- **Upstream / downstream wiring** — what it consumes (which doc's output) and what
  it feeds (which doc consumes it).

## 4. Dependencies

- Upstream docs/modules: [[<DOC>]], `src/<module>`
- Shared kernel: `common.samlau.<module>` (lifted, never pre-stubbed — CONVENTIONS §1)
- Libraries: …

## 5. Acceptance / verification

- Smoke contract: the `__main__` / `tests/test_<module>.py` assertions that must pass.
- Gates this module is responsible for (e.g. G-storage, G-coherence ≤1e-6) with exact thresholds.
- How to run: `research/.venv/bin/python -m pytest research/experiments/<NN>/tests/...`

## 6. Out of scope (YAGNI gate)

Explicit list of what this module deliberately does **not** do. Anything not driven
by a current-phase requirement above goes here, not into the code. No speculative
abstraction, no "for later" parameters, no pre-stubbed signatures.

- Does NOT …
- Does NOT …

## 7. Traceability

| Requirement | Home ADR clause |
|---|---|
| FR-<DOC>-001 | [[../../../decisions/1000-gnn-sam]] §X |
| … | … |
