---
name: bolt-roadmap
description: Create a comprehensive strategic roadmap and diagram for the project by decomposing high-level goals into atomic, sequential/parallel bolts.
---

# Bolt-Roadmap Workflow: Strategic Decomposition

This workflow guides the user and agent from a high-level project objective to a fully decomposed execution plan (`strategy-map.md`). It ensures all dependencies are identified, architectural patterns are selected, and the path forward is visually clear. Roadmaps can be created initially or incrementally over time.

## 0. Prerequisites
Check for `.bolts/constitution.md`:
- **If it exists** (status: approved): Read it before the interview. Use its articles to constrain architectural preference questions — do not re-ask what the constitution already answers.
- **If it does not exist**: Recommend that the user invoke `bolt-constitution` before the roadmap, especially for multi-Bolt initiatives. Proceed without it only if the user explicitly chooses to.

## 1. Context & Objective Discovery (The Interview)
Start by understanding what the user wants to build. Do not proceed to planning until you have a crystal-clear understanding of the scope.
1. **Iterative Interview Loop**: Use the `brainstorming` skill.
   - **Goal**: What is the ultimate deliverable?
   - **Scope**: What is IN and what is OUT of scope?
   - **Constraints**: Are there specific technologies, libraries, or patterns required? (Check `constitution.md` first — these may already be answered.)
   - **Architectural Preference**: Monolith vs. Microservices? (Defer to constitution if it specifies.)
2. **Constraint Check**: CONTINUE this loop until there are **no shadow points or doubts**. You must have enough information to write the spec for Bolt #1 immediately.

## 2. Strategic Decomposition
Break the objective down using the **Bolt Architecture**:
1. **Identify Foundations**: What needs to exist first? (e.g., config setup, data models, shared contracts).
2. **Define Streams**: Group tasks into logical streams (e.g., "Frontend Stream," "Data Pipeline").
3. **Atomic Bolts**: Break streams into "Bolts". A Bolt is a unit of work that completes a specific feature or logical slice, small enough to be tracked with a single `plan.md`.

## 3. Sequencing & Dependency Analysis
Determine the execution order of the Bolts.
1. **Sequential Chains**: Identify Bolts that strictly block others.
2. **Parallel Opportunities**: Identify Bolts that can be worked on simultaneously.
3. **Critical Path**: What is the shortest path to an MVP?

## 4. Artifact Generation
Create the specific deliverables.
### 4.1 Create `strategy-map.md`
Generate a markdown file (e.g., `.bolts/strategy-map.md` or a phase-specific roadmap like `.bolts/roadmap-phase2.md`):
- **Project Goal**: Concise summary.
- **Architectural Standards**: The agreed-upon technical constraints (reference `constitution.md` articles where applicable).
- **The Roadmap**: A list of Bolts (e.g., `BOLT-001-setup`, `BOLT-002-api`), grouped by Stream.
- **Tagging**: Mark each Bolt explicitly as `[SEQUENTIAL]` or `[PARALLELABLE]`.
- **Description**: Provide a 1-sentence description of the Bolt's output.

### 4.2 Create Mermaid Diagram
Append a Mermaid chart to the roadmap file.
- Use `graph TD`.
- Use subgraphs for Phases/Streams.
- Use explicit arrows `-->` to show dependencies between Bolts.

## 5. User Validation
1. Present the map to the user.
2. Refine the plan based on feedback.
3. **Next Steps**: Instruct the user to invoke `bolt-intent` for the first prioritized Bolt.
