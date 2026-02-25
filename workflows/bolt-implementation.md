---
description: Execute the technical plan for a feature using bounded, task-by-task execution and evaluation checks.
---

# Bolt-Implementation Workflow: The Build Loop

This workflow covers the active development phase of a single Bolt. It transitions the technical specifications and plans into working, evaluated code.

## 1. Context & Setup (The Execution Layer)
1. **Locate Workspace**: Ask the user for the active Bolt directory (e.g., `.bolts/BOLT-XXX-<shortname>/`) if it wasn't provided in the prompt.
2. **State Verification**: Open the `plan.md` file in the Bolt directory. Verify its frontmatter is set to `status: approved`. If it is not, inform the user and abort.
3. **Load Constraints**: Read the `spec.md`, `architecture.md`, and `plan.md` files to establish the precise technical constraints, Acceptance Criteria, and execution dependencies.

## 2. The Execution Bounds (Crucial Directives)
- **Stop on Blockers**: If you encounter an unexpected system constraint (e.g., a missing library), or an impossible requirement that contradicts the codebase, **STOP immediately**. Ask the user for clarification or suggest an architectural pivot before writing any code.
- **One Step at a Time**: Execute tasks sequentially based on `plan.md`. Do not start the next task until the current one is fully validated and the user has reviewed the progress.
- **State Updates**: Actively manage the frontmatter of your current task artifact (either the main `plan.md` list or an individual `tasks/task-0X.md` file). Update status appropriately (`todo` \u2192 `implementing` \u2192 `blocked/complete`).

## 3. The Execution Loop (Task by Task)
For each task in the plan:
1. Update the current task's frontmatter to `status: implementing`.
2. *(Optional)* **TDD Delegation**: If Test-Driven Development is requested or appropriate for establishing contracts, invoke the `test-driven-development` skill (or similar unit-testing workflow) to write and verify tests against the Acceptance Criteria.
3. **Write Implementation**: Write the code required to fulfill the task's Definition of Done and architecture contracts.
4. **Fast Deterministic Evals**: Aggressively verify assumptions. Run linters, syntax checks, compiler checks, or unit tests locally *before* presenting the work.
5. **Mark Complete**: Once the Definition of Done is met and evals pass, change the task frontmatter to `status: complete`.
6. **User Review**: Pause the execution. Ask the user for a review of the completed task before moving to the next logical step in the Mermaid diagram or sequence.

## 4. Finalization
1. When all tasks are marked as `status: complete`, inform the user.
2. Update the main `plan.md` frontmatter to `status: complete`.
3. The Bolt is ready for the `bolt-verify` stage or a Merge Request.
