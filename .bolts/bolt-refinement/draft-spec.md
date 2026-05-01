---
target: BOLT System Core (v2.0)
status: In-Progress
owner: System Architect
dependencies: [git, tree-sitter, python-yaml]
last_audit_hash: "initial-design-001"
---

# 1. Intent (The Elephant)
The goal is to refactor and optimize the `bolt-skills` repository into a production-grade **Spec-Driven Development (SDD)** harness. We are moving away from "Vibe Coding" toward "Managed Agency," where the repository’s long-term memory (The Elephant) is stored in tracked Markdown/YAML, and the code (The Goldfish) is a verified byproduct of the specification.

**Core Objectives:**
*   **Eliminate Amnesia:** Move all `bolt` documents from untracked folders to `docs/design/`.
*   **Enforce Governance:** Implement the "Interface Boundary" to prevent architectural drift.
*   **Optimize Context:** Use "Skeleton-First" loading to maintain agent performance.
*   **Detect Drift:** Replace basic verification with semantic `bolt-audit`.

# 2. Interfaces & Constraints (The "Halt Zone")
**CRITICAL: Any agentic action that violates these constraints MUST trigger a "Halt & Proposal" session.**

### 2.1 File System Schema
*   **Elephant Path:** `docs/design/[feature-name].md` (Must contain YAML front matter).
*   **Map Path:** `docs/Roadmap.md` (Must be a Markdown table with YAML-status badges).
*   **Skill Path:** `bolt-skills/[skill-name]/` (Contains the prompt logic and execution scripts).

### 2.2 The "Halt" Protocol
*   **Manual Gate:** The agent **must stop** and request human approval if it detects a need to change:
    1.  The `## Interfaces & Constraints` section of any design doc.
    2.  The public signature of any function in the `bolt-skills` core.
    3.  The YAML schema defined in the front matter.
*   **Auto-Synthesis:** Internal logic changes (private methods, loop optimizations) may be auto-synthesized into the `# Implementation Tasks` list without halting.

### 2.3 Documentation Integrity
*   No code shall be considered "Done" until the `last_audit_hash` in the YAML front matter is updated to the current commit SHA.

# 3. Architectural Sketch
The BOLT system operates as a state-aware graph. 



### 3.1 Skill Refactoring
*   **`bolt-intent`:** Refactor to "Evolver" mode. It must be able to read an existing `Roadmap.md`, identify dependencies, and update a single-file Elephant without creating duplicates.
*   **`bolt-implement`:** Integrate the "Synthesis" step. It must update the `## Implementation Tasks` list of the design doc upon successful test completion.
*   **`bolt-audit`:** Integrate `git diff` analysis. It must compare the `git diff` against the `Interfaces & Constraints` section to detect "Stealth Drift."

### 3.2 Context Engine (The Roadmap)
The `Roadmap.md` acts as the **Context Injection Engine**. Before any work begins, the agent must parse the roadmap to identify "Active" vs. "Audited" features to avoid context decay.

# 4. Implementation Tasks (The Checklist)

## Phase 1: Repository Migration
- [ ] Move existing `bolt-skills` documents to `docs/design/`.
- [ ] Initialize `docs/Roadmap.md` with the current state of the repository.
- [ ] Create a `template.md` for the single-file Elephant structure.

## Phase 2: Skill Refactoring (Iterative)
- [ ] **Task 2.1:** Update `bolt-intent` to support YAML front matter and "Evolve" logic.
- [ ] **Task 2.2:** Update `bolt-implement` to include the **Halt Zone** logic.
    - [ ] *Sub-task:* Implement "Impact Assessment" reporting for Halt moments.
- [ ] **Task 2.3:** Develop `bolt-audit`.
    - [ ] *Sub-task:* Use `git diff` to flag changes that occur without a corresponding spec update.

## Phase 3: Semantic Enhancement
- [ ] Integrate lightweight AST checks (e.g., Tree-Sitter) into `bolt-audit` to detect signature changes.
- [ ] Implement the "Skeleton-First" reading strategy in all skills to save tokens.

## Phase 4: Verification & Synthesis
- [ ] Ensure `bolt-implement` auto-updates the `Roadmap.md` status upon completion.
- [ ] Final "Self-Audit": Use the new `bolt-audit` to verify the BOLT system's own refactoring.