---
name: bolt-implementation
description: Execute the technical plan for a feature using bounded, task-by-task execution and evaluation checks.
---

# Bolt-Implementation Workflow: The Build Loop

This workflow covers the active development phase of a single Bolt. It transitions the approved specifications and plan into working, evaluated code.

## 1. Context & Setup (The Execution Layer)
1. **Locate Workspace**: Ask the user for the active Bolt directory (e.g., `.bolts/BOLT-XXX-<shortname>/`) if it wasn't provided in the prompt.
2. **State Verification**: Open `plan.md`. Verify its frontmatter is `status: approved`. If it is not, inform the user and abort.
3. **Load Constraints**: Read `spec.md`, `architecture.md`, and `plan.md` to establish the precise technical constraints, Acceptance Criteria (FR-NNN / SC-NNN), and execution dependencies.
4. **Constitution Check**: Read `constitution.md`. Note any articles directly relevant to implementation (testing requirements, abstraction rules, integration testing rules).

## 2. The Execution Bounds (Crucial Directives)
- **Stop on Blockers**: If you encounter an unexpected system constraint (e.g., a missing library, an impossible requirement that contradicts the codebase), **STOP immediately**. Log the blocker in `implementation_decisions.md` and ask the user for clarification or an architectural pivot before writing any code.
- **One Step at a Time (Sequential Tasks)**: Execute tasks in dependency order per `plan.md`. Do not start the next task until the current one is fully validated and the user has reviewed the progress.
- **Parallel Tasks `[P]`**: Tasks marked `[P]` in `plan.md` have no dependencies on each other and may be dispatched simultaneously as parallel sub-agents. Before dispatching, run this checklist:
  - [ ] No two `[P]` tasks modify the same file — if they do, consolidate into one agent and log as `ID-NNN | Decision: Merged TASK-XX and TASK-YY | Rationale: Both modify <file>`
  - [ ] Each agent prompt is self-contained: explicit scope, goal, constraints, and expected output format
  - [ ] Relevant file paths and context are pasted directly into each prompt — agents do not inherit session context
  - [ ] Output is specified concretely ("Return a summary of root cause and changes made" — not "fix it")

  Avoid: too-broad scope, missing file context, no constraints on what not to touch, vague output requests.
- **Model Routing**: Each task heading may carry a complexity annotation. Resolve it to a model tier before dispatching or executing the task:
  - `[trivial]` / `[low]` → haiku
  - `[medium]` → sonnet (default when no annotation is present)
  - `[high]` → opus — **stop and ask the user for confirmation before proceeding**; opus incurs significant cost and requires a MAX plan
- **Traceability**: Every piece of implementation must be traceable to at least one FR-NNN requirement or SC-NNN success criterion from `spec.md`. If code cannot be traced to either, question whether it belongs in this Bolt.

## 3. The Execution Loop (Task by Task)
For each task in the plan:
1. Update the current task's frontmatter to `status: implementing`.
2. *(Optional)* **TDD Delegation**: If TDD is required by `constitution.md` or appropriate for establishing contracts, invoke the `test-driven-development` skill to write and verify tests against the relevant FR-NNN / SC-NNN criteria before writing source code.
3. **Write Implementation**: Write the code required to fulfill the task's Definition of Done and architecture contracts.
4. **Fast Deterministic Evals**: Aggressively verify assumptions. Run linters, syntax checks, compiler checks, or unit tests locally *before* presenting the work.
5. **Log Deviations**: If you deviate from `architecture.md` or `plan.md`, log the decision immediately in `implementation_decisions.md` (initialize from `bolt-implementation/templates/implementation_decisions.md` if not yet created) using the format:
   - `ID-NNN | Phase: <phase> | Files: <files> | Decision: <what changed> | Rationale: <why>`
6. **Mark Complete**: Once the Definition of Done is met and evals pass, update the task frontmatter to `status: complete`.
7. **User Review**: Pause execution. Ask the user for a review of the completed task before moving to the next step in the dependency sequence.

## 4. Finalization
1. When all tasks are `status: complete`, inform the user.
2. Update the main `plan.md` frontmatter to `status: complete`.
3. The Bolt is ready for `bolt-verify`.
