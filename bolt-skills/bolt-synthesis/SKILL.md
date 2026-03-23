---
name: bolt-synthesis
description: Manage the project's knowledge base by documenting decisions, resolving assumptions, and updating global architecture or conventions. Targets project knowledge — not process improvement (see bolt-retrospective for that).
---

# Bolt-Synthesis Workflow: Knowledge Management

This workflow manages the project's **enduring knowledge base**. Use it after a Bolt is merged, or when architectural decisions, new technical patterns, or resolved assumptions need to become permanent, portable assets for the whole project.

> **Distinction from bolt-retrospective**: `bolt-synthesis` updates what the project knows (architecture, conventions, tech decisions). `bolt-retrospective` updates how the team works (process, constitution, bolt skills). If during synthesis you identify process improvements, flag them for a future `bolt-retrospective` — do not mix them here.

## When to Run
- Immediately after a Bolt's `mrp.md` reaches `status: approved`.
- After a batch of related Bolts to consolidate overlapping learnings.
- When a resolved assumption or new constraint should be inherited by all future Bolts.

## 1. Intelligence Ingestion
Identify what new information was generated during the recent development cycle.
1. Review `mrp.md` and `architecture.md` from recently completed Bolts.
2. Review `implementation_decisions.md` for runtime deviations that reflect permanent decisions (not one-off workarounds).
3. Review `research.md` (if present) — `RD-NNN` recommendations that were adopted become project conventions.
4. Extract: core thesis, key insights, ADRs, and any resolved `[NEEDS CLARIFICATION]` items that have broad applicability.

## 2. Axiom & Constraint Extraction
Analyse the ingested data to extract:
- **Axioms**: Core principles, tools selected (e.g., "PostgreSQL is the data store"), or patterns adopted project-wide.
- **Constraints**: Physical, technical, or systemic limits discovered during the Bolt that apply beyond this feature.
- **Resolved Assumptions**: Items that were ambiguous at the start of the Bolt but are now authoritatively answered.

## 3. Global Documentation Update
Update the primary project documentation (e.g., `REQUIREMENTS.md`, `ARCHITECTURE.md`, `CONVENTIONS.md` in the repository root or `.sdlc/` folder).
1. Use `technical-doc-writer` or `doc-coauthoring` (if available) to ensure tone is clear and concise.
2. **Do not just append**: Rewrite sections to gracefully incorporate new intelligence so future Bolts inherit it coherently.
3. Every new concept SHOULD link to at least one internal concept or external reference.
4. If a `RD-NNN` recommendation from `research.md` was adopted, add the decision to `ARCHITECTURE.md` with its rationale — future Bolts should not re-research resolved questions.

## 4. Resolving Assumptions
If a Bolt generated assumptions because project documentation was lacking:
1. Review those logged assumptions.
2. If validated by the user or code review, explicitly add the answers to the project's global conventions so future agents do not guess.
3. If the assumption revealed a gap in `constitution.md`, flag it as a proposed amendment for `bolt-retrospective`.

## 5. Consolidation & Cleanup
Perform a formal documentation audit:
1. Resolve naming conflicts or redundant definitions in global docs.
2. Ensure the state of tracked Bolts in `strategy-map.md` matches the actual codebase.
3. Report the "State of the Knowledge Graph" to the user for final review.

---
**Next Steps**: If process improvements were identified during synthesis, queue a `bolt-retrospective`. Otherwise, the knowledge base is updated and the next Bolt can begin with `bolt-intent`.
