# BOLT System Core (v2.0) - The Elephant & Goldfish Architecture

## 1. Philosophy
This architecture implements "Spec-Driven Development" (SDD) by modeling the system into two distinct entities:
*   **The Elephant (Long-Term Memory)**: The persistent specification. It remembers Intent, Architecture, Constraints, and the "Why" (Architecture Decision Records).
*   **The Goldfish (Short-Term Memory)**: The agentic session (`bolt-implement`). It is transient, executes detailed plans, and relies on strict contextual feeding to avoid context-window decay and hallucination.

## 2. File Structure & Delivery Model (Gitflow)
The temporary `.bolts/` directory paradigm is eliminated. Features are developed directly as deliverables in the `docs/design/` directory.

### The Blueprint Directory
When a new feature is initiated, a dedicated folder is created: `docs/design/[feature-name]/`.
It contains exactly two files:

1.  **`spec.md` (The Elephant)**: 
    *   **YAML Frontmatter**: Tracks state (e.g., `status: in-progress`).
    *   **Intent**: Brief description of the feature.
    *   **Interfaces & Constraints (HALT ZONE)**: Strict API signatures and hard rules. If the Goldfish needs to violate these, it must stop and ask the user.
    *   **Architecture & ADRs**: Explains the "Why". Uses `[[wikilinks]]` to reference deep context in `docs/research/` without bloating the file.
2.  **`plan.md` (The Goldfish Checklist)**: 
    *   A highly detailed, mutable markdown checklist with specific steps, file paths, and instructions tailored for the agent executing the code.

### Modifying Pre-existing Features
When modifying an existing feature, `bolt-intent` does **not** directly mutate the consolidated design doc (`docs/design/<feature>.md`) in real-time. 
1.  It reads the existing `docs/design/<feature>.md` for context.
2.  It creates a *new* dedicated folder for the current modification branch (e.g., `docs/design/<feature-update>/`) with its own transient `spec.md` and `plan.md`.
3.  Upon completion and promotion (`bolt-synthesis` phase), the architectural changes are consolidated back into the master `docs/design/<feature>.md` file.

### Delivery & CI Integration
The entire `docs/design/[feature-name]/` folder is part of the Git deliverable. Merge requests to `dev` or `main` can utilize CI checks to ensure no `spec.md` in the diff has a `status: in-progress` or `status: draft`.

## 3. The Skills Ecosystem

*   **`bolt-intent` (The Specifier)**
    *   Operates in an interactive session. It does *not* write one-shot. It continuously drafts and refines `spec.md` and `plan.md` in the new feature folder based on human feedback.
*   **`bolt-implement` (The Executor)**
    *   The Goldfish. It executes `plan.md`. TDD is supported but driven by human request rather than enforced automatically. Uses programmatic tools to extract context safely.
*   **`bolt-audit` (The Warden)**
    *   A unified two-phase check:
        *   *Phase 1 (Verify)*: Deterministic. Runs `pytest`, `mypy`, `ruff`, etc. Fast failure.
        *   *Phase 2 (Audit)*: Semantic. Analyzes the `git diff` against the `Interfaces & Constraints` of `spec.md` to flag architectural drift.
*   **`bolt-synthesis` (The Consolidator)**
    *   Post-audit cleanup. Deletes or archives the transient `plan.md`, changes the `spec.md` status to `audited`, and handles the updating of old design docs if the branch was a modification of an existing feature.
*   **`bolt-roadmap` (The Orchestrator)**
    *   Acts as the Epic planner. Rather than creating a persistent epic file, it orchestrates the sequential creation of multiple separate `bolt-intent` feature specs.
*   **`bolt-research` (The Scout)**
    *   Pre-intent investigation. Outputs detailed findings to `docs/research/[topic].md` which are then cleanly referenced via wikilinks in the main specs.

## 4. Managing Architectural Drift (The Pivot)
If the Goldfish (`bolt-implement`) encounters a blocker that requires violating the `Interfaces & Constraints` (The Halt Zone) of the `spec.md`, it must not proceed. The code must never outpace the spec.
1.  **The Trigger (Halt)**: The agent stops execution and alerts the human architect.
2.  **The Pivot**: The human invokes `bolt-intent` (in an update capacity) to re-evaluate the architecture.
3.  **Spec Update**: The intent agent updates the `spec.md` with the new constraint/interface and logs the decision in the `Architecture & ADRs` section (e.g., "Attempted X, blocked by Y. Drifting to Z."). It then regenerates the affected tasks in `plan.md`.
4.  **Resumption**: A new `bolt-implement` session is started against the updated plan.

## 5. Technical Enablers

### Context Extraction Utility (`bolt_parser.py`)
To prevent the Goldfish from breaking markdown formatting or choking on massive documents, a Python utility script (e.g., `scripts/bolt_parser.py`) is introduced. 
*   Coding agents will use this script via CLI to extract specific sections (e.g., just the `## Interfaces & Constraints`) enforcing a "Skeleton-First" reading strategy. 
*   Python is chosen over basic command-line tools (`sed`/`awk`) to provide robust Markdown AST parsing and regex error handling, ensuring the agent's context window is never corrupted by stray markdown syntax.
