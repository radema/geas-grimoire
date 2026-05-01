---
name: bolt-implementation
description: Execute the technical plan for a feature using bounded, task-by-task execution. Acts as the "Goldfish", relying on strict constraints from the "Elephant" (spec.md).
---

# Bolt-Implementation Workflow: The Goldfish Execution

This workflow covers the active development phase. You are the "Goldfish"—your job is to execute the immediate checklist (`plan.md`) while strictly obeying the immutable constraints of the blueprint (`spec.md`). You do not make architectural decisions.

## 1. Context & Setup
1. **Locate Workspace**: Ask the user for the active feature directory (e.g., `docs/design/<feature-name>/` or `docs/design/<feature-update>/`).
2. **Skeleton-First Context Loading**: 
   - Read `plan.md` to understand your immediate tasks.
   - Run the parser script to extract the constraints without loading the entire `spec.md` into your context window:
     `python bolt-skills/scripts/bolt_parser.py docs/design/<workspace>/spec.md --section "Interfaces & Constraints"`
     Pay absolute attention to this output.
3. **Constitution Check**: Briefly review `docs/design/constitution.md` for global repository invariants.

## 2. The Execution Bounds (HALT & PIVOT)
- **THE HALT ZONE**: If a task requires you to violate an interface, signature, or rule defined in the `## Interfaces & Constraints` section of `spec.md`, **STOP IMMEDIATELY**.
- **The Pivot Protocol**: Do NOT "hack" around the constraint. Do NOT modify `spec.md` yourself (that is the domain of `bolt-intent`). Alert the user and request a "Pivot". The user will pause this session and use `bolt-intent` to formally update the architecture and constraints. You will resume only when the spec has been officially updated.

### 2.1 Model Routing & Parallelism
- **One Step at a Time**: Execute tasks in dependency order per `plan.md`.
- **Parallel Tasks `[P]`**: Tasks marked `[P]` have no dependencies and may be dispatched simultaneously if supported. Ensure no two `[P]` tasks modify the same file.
- **Model Routing**: Task headings may carry a complexity annotation (e.g., `[medium]`). Resolve it to a model tier:
  - `[trivial]` / `[low]` → haiku
  - `[medium]` → sonnet (default)
  - `[high]` → opus (Stop and ask for user confirmation before proceeding with expensive models).

## 3. The Execution Loop
For each task in `plan.md`:
1. **Understand DoD**: Verify you understand the Definition of Done (DoD) for the task and trace it to the required FR/SC.
2. **Test-Driven Development (Optional)**: TDD is supported but driven by human request. If the user explicitly requests TDD, write and verify tests against the SC criteria *before* source code. Otherwise, write the implementation directly.
3. **Write Implementation**: Write the code required to fulfill the task. 
4. **Fast Deterministic Evals**: Aggressively verify assumptions. Run linters (`ruff`), type checkers (`mypy`), and local unit tests (`pytest`) locally *before* presenting the work.
5. **Mark Complete**: Update `plan.md` (e.g., check off markdown checklist items) to durably record your progress.
6. **User Review**: Pause execution. Ask the user for a review of the completed task before moving to the next step.

## 4. Finalization
1. When all tasks in `plan.md` are marked complete, inform the user.
2. The Bolt is now ready for the combined Pre-Flight Check.
3. **Next Steps**: Instruct the user to invoke `bolt-audit` to run final operational verifications and semantic drift checks.
