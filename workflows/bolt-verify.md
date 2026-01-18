---
description: Assess coherence, review tests, edge cases, and finalize documentation.
---

# Bolt-Verify Workflow: Quality Assurance & Handover

This workflow validates the code and prepares it for review. It can be triggered at milestones or completion.

## 1. Deep Verification
1. Invoke `verification-before-completion` and `webapp-testing` (for UI).
2. Compare implementation against `.bolts/<bolt-id>/spec.md`.

## 2. The "Merge Request Package" (MRP)
Create artifacts in `.bolts/<bolt-id>/mrp/` including:
- `summary.md`: High-level overview of what was implemented.
- **Evidence**: Test results, coverage stats, and browser screenshots.
- **Audit**: Checklist of boundary conditions tested (nulls, speed, responsive).
- **Residual Risks**: Any known technical debt or follow-up items.

## 3. The Feedback Loop
- **PASS**: If all AC are met, use `requesting-code-review` and attach the "Merge Request Package".
- **FAIL/REVISE**: If gaps are found or UX feels "off":
  1. Document the findings in the "Residual Risks" or a new ADR.
  2. **Return to Bolt-Implementation** or `Bolt-Intent` to fix the identified issues.

**Checkpoint**: The workflow is complete when the "Merge Request Package" is approved by the USER or the loop restarts.
