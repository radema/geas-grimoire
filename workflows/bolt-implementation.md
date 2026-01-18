---
description: Execute the implementation plan using TDD and domain-specific best practices.
---

# Bolt-Implementation Workflow: The Build Loop

This workflow covers the active development phase. It requires an approved plan in `.bolts/<bolt-id>/plan.md`.

## 1. The Execution Loop
1. Invoke the `executing-plans` skill for the current task in the bolt folder.
2. **The TDD Loop**:
   - **Red**: Failing test.
   - **Green**: Minimal implementation.
   - **Refactor**: Clean code.
3. **Status Sync**: Update `.bolts/<bolt-id>/plan.md` after every task.

## 2. Incremental Verification
1. For long plans, trigger an **Intermediate Bolt-Verify** after every "Macro-Milestone".
2. If verification fails or reveals new requirements:
   - Mark the current task as "Blocked/Refined".
   - Pivot back to `bolt-intent` or adjust the `plan.md` accordingly.

**Checkpoint**: Continue the loop until all tasks for the current milestone or the entire plan are complete.
