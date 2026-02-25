---
description: Manage the project's knowledge base by documenting decisions, resolving assumptions, and updating global architecture or conventions.
---

# Bolt-Synthesis Workflow: Knowledge Management

This workflow is designed to manage the project's enduring knowledge base. Use it after a Bolt is completed, or when architectural decisions, new technical patterns, or assumptions need to become permanent, portable assets for the whole project.

## 1. Intelligence Ingestion
Identify what new information was generated during the recent development cycle.
1. Review the `mrp.md` and `architecture.md` files from recently completed Bolts.
2. Extract the core thesis, key insights, architectural decisions (ADRs), or unresolved assumptions made during development.

## 2. Axiom & Constraint Extraction
Analyze the ingested data to extract:
- **Axioms**: Core principles, tools selected (e.g., "PostgreSQL is the data store"), or patterns adopted.
- **Constraints**: Physical, technical, or systemic limits discovered during the Bolt.
- Store these as structured notes if necessary.

## 3. Global Documentation Update
Update the primary project documentation or "Living Manifesto" (e.g., `REQUIREMENTS.md`, `ARCHITECTURE.md`, `CONVENTIONS.md` in the repository root or `.sdlc/` folder).
1. Use the `technical-doc-writer` or `doc-coauthoring` skill (if available) to ensure the tone is clear and concise.
2. **Do not just append information**: Rewrite sections to gracefully incorporate the new intelligence, tools, or decisions into the overarching project constraints so future Bolts inherit them.
3. Every new concept SHOULD link to at least one internal concept or external reference.

## 4. Resolving Assumptions
If a Bolt generated assumptions because the project documentation was lacking:
1. Review those logged assumptions.
2. If validated by the user or code review, explicitly add those answers to the project's global conventions so future agents do not have to guess.

## 5. Consolidation & Cleanup
Perform a formal memory or repository audit:
1. Resolve naming conflicts or redundant definitions in the global docs.
2. Ensure the state of tracked Bolts matches the actual codebase.
3. Report the "State of the Knowledge Graph" to the user for final review.
