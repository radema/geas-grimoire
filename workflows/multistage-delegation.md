---
description: Workflow for breaking down complex architectural plans into atomic, phased prompts for execution by specialized agents.
---

# Multistage Delegation Workflow

This workflow guides the **Coordinator Agent** in managing complex implementation plans by delegating execution to specialized **Code Agents**. This pattern ensures consistency, reduces context pollution, and enforces strict review gates.

## 1. Plan Decomposition

1.  **Review the Master Plan**: Analyze the implementation plan (e.g., `.bolts/<bolt-id>/plan.md`).
2.  **Identify Phases**: Break the plan into distinct, testable phases.
    *   *Phase 1*: Environment & Core Structures.
    *   *Phase 2*: Data Adapters & Logic.
    *   *Phase 3*: Loaders & Pipelines.
    *   *Phase 4*: Model Architecture.
    *   *Phase 5*: Training Loop & Refinement.

## 2. Prompt Engineering (The "Delegate Packet")

For **EMACH** phase, construct a prompt using this template:

```markdown
**Role**: Code Agent
**Phase**: [Phase Name] (e.g., Phase 2: Graph Adapter)
**Context**: Briefly summarize what has been built (Phase 1) and what the goal is now.

**Task**: [Action Verb] [Object].
*   "Implement the `GraphFactory` class..."
*   "Create the `TemporalBlock` module..."

**Specification**:
1.  **File**: `path/to/file.py`
2.  **Input/Output**: Explicitly define signatures.
    *   Input: `(Batch, Time, Feat)`
    *   Output: `(Batch, Horizon)`
3.  **Key Logic**:
    *   List 2-3 critical constraints (e.g., "Graph must correspond to lexical sort of stores").

**Validation**:
1.  Isolate verification step (e.g., "Create `tests/test_phase_2.py`").
2.  Define success condition (e.g., "Assert `num_nodes == 1782`").

**Constraints**:
*   Mention performance (MPS optimization).
*   Structure (No new files unless requested).

**Instruction**: STOP after implementation and ask for review.
```

## 3. Review & Gatekeeping

1.  **Verify**: When the Code Agent typically returns "DONE", the Coordinator MUST:
    *   Read the created file(s).
    *   Check `plan.md` off.
2.  **Iterate or Approve**:
    *   *If correct*: Mark Phase as complete. Generate prompt for Phase $(N+1)$.
    *   *If flawed*: Provide specific feedback to the SAME agent context to fix.

## 4. Final Integration

1.  Once all phases are complete, the Coordinator performs a final **Integration Test**.
2.  Run the full pipeline (e.g., 2 epochs of training).
3.  Report final metrics back to the User.
