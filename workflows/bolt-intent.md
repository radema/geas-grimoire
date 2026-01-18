---
description: Define requirements, specifics, implementation plan and solution architecture.
---

# Bolt-Intent Workflow: Planning & Design

This workflow transitions from a vague idea to an implementation-ready design.

## 1. Requirement Gathering (Product Owner)
1. Invoke the `brainstorming` skill to explore user intent and constraints.
2. **Question Bundling**: Ask groups of related questions to refine the feature scope efficiently.
3. Identify success criteria and "Out of Scope" items.

## 2. Workspace Setup
1. Identify or create the dedicated task folder: `.bolts/<bolt-id>/`.
2. All subsequent documents for this bolt MUST stay within this folder.
3. This folder and its content has to be committed only if explicitly requested by the user. 

## 3. Specification & Documentation (Product Owner / Architect)
1. Use `doc-coauthoring` to draft the Specification in `.bolts/<bolt-id>/spec.md`.
2. Define user stories and acceptance criteria (AC).

## 4. Technical Architecture & Planning (Architect)
1. Define interface contracts and save ADRs to `.bolts/<bolt-id>/adr/`.
2. Invoke `writing-plans` to create the implementation plan in `.bolts/<bolt-id>/plan.md`.
3. **Incremental Strategy**: For large tasks, break the plan into "Macro-Milestones" that each end with a `bolt-verify` stage.

**Checkpoint**: The workflow is complete when the user approves the plan in the bolt folder.