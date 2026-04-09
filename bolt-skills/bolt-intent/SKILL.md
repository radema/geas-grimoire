---
name: bolt-intent
description: Define requirements, specifications, architecture, and step-by-step task plans for a new feature. Includes mandatory clarification loop and optional research gate before architecture is authored.
---

# Bolt-Intent Workflow: Specification & Design

## 0. Prerequisites
Before starting, verify:
- `.bolts/constitution.md` exists and has `status: approved`. If not, invoke `bolt-constitution` first.
- A `strategy-map.md` exists (from `bolt-roadmap`) or the user has a clear, scoped objective for this Bolt.

## 0.5 Spec Pre-flight
Before executing Phase 1, detect whether the spec work is already done:

1. **Approved spec on disk** — If `.bolts/BOLT-XXX-<shortname>/spec.md` already exists with `status: approved`: skip Phase 1 entirely. Proceed directly to Phase 2.
2. **Pre-written requirements document supplied** — If the user provides any `.md` document that already contains numbered FR-NNN / SC-NNN entries with zero `[NEEDS CLARIFICATION]` markers: adopt it as `spec.md` (`status: approved`), adapting formatting if needed. Skip Phase 1. Proceed directly to Phase 2.
   - If the supplied document contains unresolved markers, use it as the draft basis for Phase 1.1 (do not start from scratch).
3. **Draft spec with no open markers** — If `spec.md` exists with `status: draft` and a full scan finds zero `[NEEDS CLARIFICATION]` markers: promote to `status: approved` and skip to Phase 2.

If none of these conditions apply, proceed with Phase 1 as normal.

## 1. Setup & Context Gathering
1. **Understand Intent**: Analyze the user's request. Use the `brainstorming` skill if the goal, scope, or constraints are ambiguous. Do not proceed until you have a clear, scoped objective.
2. **Create Workspace**: Create `.bolts/BOLT-XXX-<shortname>/`.
3. *(Optional)* **Requirements Doc**: If the user provides extensive business requirements, generate `requirements.md` (`status: draft`) in the Bolt folder. Otherwise, rely on chat context.

---

## Phase 1: Spec & Clarification

### 1.1 Draft `spec.md`
Write `.bolts/BOLT-XXX-<shortname>/spec.md` (`status: draft`). Initialize from `bolt-intent/templates/spec-feature.md` (feature Bolt) or `spec-bugfix.md` (bug-fix/root-cause Bolt).

**The spec describes WHAT and WHY — never HOW.**
Do not include technology names, library choices, API structures, or implementation patterns. Those belong in `architecture.md`.

The spec must contain:
- **User Stories**: Prioritized (P1, P2, P3). Each story must be independently testable and viable as a standalone MVP slice.
  - Format: *"As a [role], I want [goal] so that [value]."*
  - Each story includes Given/When/Then acceptance scenarios.
- **Functional Requirements**: Numbered `FR-001`, `FR-002`, etc. Each must be testable and unambiguous.
  - Mark any unclear item immediately: `[NEEDS CLARIFICATION: <specific question>]`. Do not guess or assume.
- **Edge Cases & Error Scenarios**: Boundary conditions, failure modes, and degraded-state behaviors.
- **Success Criteria**: Numbered `SC-001`, `SC-002`, etc. Each criterion must be measurable and technology-agnostic.
  - Example: *"SC-001: 95th-percentile response time under 200ms at 100 concurrent users"* — not *"SC-001: API is fast"*.

### 1.2 Clarification Loop (Mandatory)
Before Phase 2 can begin, `spec.md` must have zero `[NEEDS CLARIFICATION]` markers.

1. Scan the draft spec for every `[NEEDS CLARIFICATION]` marker.
2. Present all open questions to the user in a single consolidated list.
3. Incorporate the answers into the spec — rewrite affected FR-NNN entries to be concrete and unambiguous.
4. Repeat until zero markers remain.
5. Update `spec.md` frontmatter to `status: approved`.

> **Gate**: Do not proceed to Phase 2 until `spec.md` has `status: approved`.

---

## Phase 2: Research Gate → Architecture → Plan

### 2.1 Research Gate
Read `constitution.md` and the approved `spec.md`. Determine whether new technology decisions are required.

**Invoke `bolt-research` if the Bolt**:
- Requires a new library or framework choice not covered by `constitution.md`.
- Introduces an external service integration not yet used in the project.
- Has performance SLAs (SC-NNN) that need validated evidence.
- Introduces a security-sensitive pattern not covered by the constitution.

**Skip `bolt-research` if** the Bolt purely extends an established pattern in the codebase. Document the skip in one line in `plan.md`: *"Research skipped — Bolt extends existing [pattern]. Constitution and architecture.md govern all choices."*

### 2.2 Draft `architecture.md`
Write `.bolts/BOLT-XXX-<shortname>/architecture.md` (`status: draft`). Initialize from `bolt-intent/templates/architecture.md`.

**The architecture describes HOW — every choice must be justified.**
- Reference `RD-NNN` entries from `research.md` for every technology choice (if research was run).
- Reference `constitution.md` article numbers for every constraint applied.
- Define: interface contracts, data models, component interactions, tools/libraries selected, and architectural patterns.

### 2.3 Draft `plan.md`
Write `.bolts/BOLT-XXX-<shortname>/plan.md` (`status: draft`). Initialize from `bolt-intent/templates/plan.md`.

- Give each task a clear Definition of Done traceable to at least one FR-NNN or SC-NNN.
- Mark tasks that have no dependencies on other tasks as `[P]` (parallelizable).
- Recommend TDD where applicable to verify Acceptance Criteria; allow flexibility if it is overkill for the specific task.
- **If the Bolt is Simple**: Write atomic steps directly inside `plan.md`.
- **If the Bolt is Complex**:
  - Create a Mermaid flow diagram inside `plan.md` mapping execution dependencies (`TASK-1 --> TASK-2`).
  - Create a `tasks/` subfolder with one `.md` file per task (e.g., `tasks/task-01-database.md`).

### 2.4 Validate Phase 2
Present `architecture.md` and `plan.md` to the user for review. Once approved, update both to `status: approved`.

---
**Next Steps**: The Bolt is ready for implementation. Invoke `bolt-implementation`. For complex Bolts with `[P]`-marked tasks, consider `dispatching-parallel-agents`.
