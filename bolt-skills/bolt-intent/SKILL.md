---
name: bolt-intent
description: Define requirements, specifications, architecture, and step-by-step task plans for a new feature or modification. Orchestrates the creation of the Elephant (spec.md) and Goldfish Checklist (plan.md).
---

# Bolt-Intent Workflow: The Elephant & The Goldfish

## 0. Prerequisites
Before starting, verify:
- `docs/design/constitution.md` exists and has `status: approved`. If not, invoke `bolt-constitution` first.
- If this is a modification to a pre-existing feature, ensure you read its consolidated design doc in `docs/design/<feature>.md` first.

## 1. Setup & Context Gathering
1. **Understand Intent**: Analyze the user's request. Ask if this is a new feature or a bugfix/modification.
2. **Create Workspace**: 
   - For new features: Create `docs/design/<feature-name>/`.
   - For modifications: Create `docs/design/<feature-update>/` (a transient folder for the current branch/PR).
3. **Draft Proposal (Critical)**: Based on your understanding of the codebase and the user's initial description, provide a first draft proposal of the technical implementation. 
   - **Form**: Use clearly written prose and Mermaid block diagrams.
   - **Content**: Demonstrate your understanding of the system's architecture. Use short blocks of pseudocode only if necessary.
   - **Continuous Drafting**: Immediately write this into a draft `spec.md` using `bolt-intent/templates/spec.md`. Do NOT wait until the end of the conversation. The file system is your memory.

---

## Phase 1: Spec & Architecture (The Elephant)

### 1.1 Evolve `spec.md`
Continuously update `docs/design/<workspace>/spec.md` (`status: draft`).

The `spec.md` is the long-term memory (The Elephant). It describes WHAT, WHY, and architectural HOW, as well as strict constraints.
- **Requirements**: Capture the **Business Problem** (3–5 sentences in plain English for a casual reader), User Stories/Hypothesis, Functional Requirements (FR-001), Edge Cases, and Success Criteria (SC-001).
- **Architecture & Decisions (ADR)**: Document technical choices. 
    - Provide a **jargon-light Technical Plan** describing how components fit together. Include a Mermaid block diagram.
    - **Alternatives**: Explicitly document ideas considered but ruled out, providing guardrails against future hallucinations.
    - If extensive research is needed, invoke `bolt-research` and link to `[[docs/research/topic.md]]`.
- **Interfaces & Constraints (HALT ZONE)**: Define rigid rules (API signatures, performance SLAs, backward compatibility, etc.). These are the boundaries the executing agent (Goldfish) cannot cross without human permission.

### 1.2 Clarification Loop (Mandatory)
1. Mark any unclear item immediately in the markdown: `[NEEDS CLARIFICATION: <specific question>]`. Do not guess or assume.
2. Present all open questions to the user.
3. Incorporate answers directly into `spec.md` (patching the file as you go).
4. Repeat until zero `[NEEDS CLARIFICATION]` markers remain.

---

## Phase 2: Implementation Checklist (The Goldfish)

### 2.1 Draft `plan.md`
Write `docs/design/<workspace>/plan.md`. Initialize from `bolt-intent/templates/plan.md`.

This is the transient checklist for the `bolt-implement` agent (The Goldfish).
- Give each task a clear Definition of Done traceable to an FR-NNN or SC-NNN from `spec.md`.
- Annotate each task with a complexity label (e.g., `## TASK-01 [medium] — Title`).
- **Detailed Implementation Plan**: Provide highly detailed step-by-step instructions. **Enumerate every single file that will be created or changed**, and provide the rationale for why. This is critical for keeping the executor on the rails.
- Do not use YAML arrays for tasks; write highly detailed markdown steps.

**Complexity annotation** — add the label in the task heading: `## TASK-01 [P][medium] — Title`

| Label | Default model | When to apply |
|-------|--------------|---------------|
| `[trivial]` | haiku | Config changes, renames, single-line edits |
| `[low]` | haiku | Well-specified edits to a single file, straightforward test writing |
| `[medium]` | sonnet | Multi-file changes, new logic, function signature changes |
| `[high]` | opus | Architectural refactors, novel algorithms, ambiguous or underspecified scope |

### 2.2 Validate
Present `spec.md` and `plan.md` to the user for final review. Once approved, the Bolt is ready for implementation.

---
**Next Steps**: The Bolt is ready for implementation. Invoke `bolt-implementation`. For complex Bolts with `[P]`-marked tasks, consider `dispatching-parallel-agents`.
