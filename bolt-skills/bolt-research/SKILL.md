---
name: bolt-research
description: Investigate and document technology choices before architecture is locked. Invoked from bolt-intent Phase 2 when new technology decisions are required. Produces research.md. Optional — skip with documented reason when Bolt extends an established pattern.
---

# Bolt-Research Workflow: Evidence-Based Architecture

This workflow runs **between spec approval and architecture authoring** when a Bolt introduces new technology choices, external integrations, or performance-sensitive decisions not already covered by `constitution.md`. It ensures architecture decisions are made on evidence, not assumptions.

## When to Run
`bolt-intent` Phase 2 opens with a **research gate**. The decision is binary and must be documented:

- **Invoke bolt-research when**: the Bolt requires a new library or framework choice; integrates with an external service not yet used in the project; has performance SLAs that need validation; or introduces a security-sensitive pattern not covered by the constitution.
- **Skip when**: the Bolt purely extends an existing, well-established pattern in the codebase (e.g., adding a new Bronze ingestion table to an existing pipeline). Document the skip reason in one line inside `plan.md`: *"Research skipped — Bolt extends existing [pattern name]. Constitution and architecture.md govern all choices."*

## 1. Scope Definition
Read `spec.md` (status: approved) and `constitution.md`. Identify every open decision:
1. Technology decisions implied by the acceptance criteria.
2. External dependency and integration points.
3. Non-functional requirements (performance, scalability, security, compliance).
4. Areas where the constitution does not prescribe a specific approach.

Assign a `RD-NNN` identifier to each open decision before researching.

## 2. Research Execution
For each `RD-NNN`:
1. **Codebase Scan**: Search the existing codebase for reusable patterns, existing implementations, or prior decisions that resolve the question without new dependencies.
2. **Library Evaluation**: For new dependencies, compare candidates against: maintenance status and release cadence, license compatibility with the project, performance benchmarks relevant to the Bolt's SLAs, constitution constraints (Article V — Library-First, Article VI — Security Baseline).
3. **Security Assessment**: Check known vulnerability history of candidate libraries; verify alignment with constitution's security baseline.
4. **Benchmark Validation**: If performance SLAs apply, locate or produce evidence (published benchmarks, case studies, or quick spikes) that the recommended approach meets them.

## 3. Produce `research.md`
Generate `.bolts/BOLT-XXX-<shortname>/research.md`. Initialize from `bolt-research/templates/research.md`. The structure is:

```
---
bolt: BOLT-XXX-<shortname>
status: complete
---

# Research Report

## Open Decisions
| ID | Question | Recommendation | Confidence |
|----|----------|---------------|------------|
| RD-001 | ... | ... | High/Medium/Low |

## Decision Details

### RD-001 — <Question>
**Options considered**: ...
**Recommendation**: ...
**Rationale**: ...
**Constitution articles applied**: Article N — ...
**References**: ...

### RD-002 — ...

## Codebase Reuse
- <Module or pattern identified for reuse, with file path>

## Open Risks
- <Unresolved questions or low-confidence decisions flagged for architecture review>
```

## 4. Handoff to Architecture
Present `research.md` to the user for acknowledgement.
Once acknowledged, `bolt-intent` Phase 2 proceeds to authoring `architecture.md`.
Every technology choice in `architecture.md` **must reference a `RD-NNN` entry** from this document. Choices not traceable to a research decision are flagged as assumptions.

---
**Next Steps**: Return to `bolt-intent` Phase 2 to author `architecture.md` and `plan.md` using this document as technical input.
