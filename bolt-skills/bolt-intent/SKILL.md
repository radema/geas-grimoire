---
name: bolt-intent
description: Define requirements, specifications, architecture, and step-by-step task plans for a new feature.
---

# Bolt-Intent Workflow: Specification & Design

This workflow bridges the gap between a vague idea or chat discussion and a deterministic, implementation-ready plan. It establishes the "Orchestration Layer" for the Bolt.

## 1. Setup & Context Gathering
1. **Understand Intent**: Analyze the user's request from the chat. Use the `brainstorming` skill if requirements or features are ambiguous.
2. **Create Workspace**: Create a dedicated folder for the feature: `.bolts/BOLT-XXX-<shortname>/`.
3. *(Optional)* **Requirements Doc**: If the user provides extensive business requirements, generate `.bolts/BOLT-XXX-<shortname>/requirements.md` (status: `draft`). Otherwise, rely on the chat context.

## 2. Specification & Design
Draft the core technical documents. Present each to the user for review before proceeding.
1. **Draft `spec.md`**: Define the technical specifications, User Stories, and explicit Acceptance Criteria (AC). Include frontmatter: `status: draft`.
2. **Draft `architecture.md` (or ADR)**: Define interface contracts, data models, necessary tools/libraries, and architectural patterns. Include frontmatter: `status: draft`.
3. **Validate**: Ask the user to review. Once approved, update frontmatter to `status: approved`.

## 3. Execution Planning (The Plan)
Determine how the executing agent will build the specification.
1. **Analyze Complexity**: Review the approved `spec.md` and `architecture.md`.
2. **Generate `plan.md`**:
   - Every Bolt gets a `plan.md` file (frontmatter `status: draft`).
   - Give each step or task a clear Definition of Done. Recommend TDD (Test-Driven Development) where applicable to verify Acceptance Criteria, but allow flexibility if it's overkill for the specific task.
   - **If the Bolt is Simple**: Write the atomic steps directly inside `plan.md`.
   - **If the Bolt is Complex**: 
     - Create a Mermaid state/flow diagram inside `plan.md` mapping the execution dependencies (e.g., `TASK-1 --> TASK-2`).
     - Create a `tasks/` subfolder.
     - Generate an atomic `.md` file for each task (e.g., `tasks/task-01-database.md`).
3. **Validate**: Present the plan to the user. Once approved, update frontmatter to `status: approved`. 

---
**Next Steps**: The Bolt is now ready for implementation. The user can invoke `bolt-implementation` or continue in a new chat.
