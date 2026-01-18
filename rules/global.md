---
trigger: always_on
---

# Project Global Standards & Context

This rule defines the universal standards and project context. It is always active and serves as the "Source of Truth" for shared knowledge.

## Project Vision: <PROJECT_NAME>
*Note to Agent: If the project name or vision below is not defined or seems outdated based on the codebase, ask the user to provide details and update this file.*

**<PROJECT_NAME>** is [DESCRIBE PROJECT PURPOSE].
- **Architecture**: [Describe high-level architecture, e.g., Static Web Application, Microservices, etc.]
- **Primary Tech Stack**: [List key languages/frameworks, e.g., React, Python, Node.js]
- **Tools**: [List specific tools used in the workflow, e.g., `uv`, `npx`, `docker`]

## The .bolts/ Workspace
All documentation for a specific task ("A Bolt") must be stored in a dedicated subdirectory: `.bolts/<bolt-id>/`.
- `<bolt-id>`: A descriptive name provided by the user or derived from the task (e.g., `feature-map-layers`).
- **Hierarchy**:
  - `.bolts/<bolt-id>/spec.md`: User stories and AC.
  - `.bolts/<bolt-id>/plan.md`: Implementation steps.
  - `.bolts/<bolt-id>/adr/`: Technical decision records.
  - `.bolts/<bolt-id>/mrp/`: The Merge Request Package (verification reports, screenshots).

## Core Engineering Standards

1. **Test-Driven Development (TDD)**: 
   - Never implement features or fix bugs without a failing test first.
   - Run existing tests before every commit.
   - Use the `test-driven-development` skill for all coding tasks.

2. **SOLID & Clean Code**:
   - Prefer small, single-responsibility modules over large files.
   - Use descriptive naming and document the "Why", not the "How".

3. **Data Integrity**:
   - Workflows involving data processing should be **Idempotent** (re-running produces the same result).
   - Use strict validation (schemas, types, or assertions) to fail early on mismatches.

4. **Contract-First Development**:
   - Interface definitions (JSON schemas, APIs, Types) must be finalized and documented in `docs/plans/` or a relevant subdirectory before implementation begins.

## The Bolt Lifecycle
All development must follow this sequence:
1. **Bolt-Intent**: (Product Owner / Architect) Requirements $\rightarrow$ Spec $\rightarrow$ ADR $\rightarrow$ Implementation Plan.
2. **Bolt-Implementation**: (Engineer) TDD Loop $\rightarrow$ Documentation $\rightarrow$ Status Update.
3. **Bolt-Verify**: (QA / Reviewer) Requirement Coherence $\rightarrow$ Edge Case Hunt $\rightarrow$ Performance Audit.

## Superpowers & Skills
The `using-superpowers` skill is the entry point for every task. If a skill exists in `.agent/skills/`, it is **Mandatory** to invoke it whenever the context matches.
