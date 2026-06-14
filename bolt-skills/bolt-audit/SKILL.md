---
name: bolt-audit
description: The Warden. Run the two-phase Pre-Flight Check (Deterministic Verify + Semantic Audit) against the completed implementation to ensure no architectural drift occurred.
---

# Bolt-Audit Workflow: The Warden's Pre-Flight Check

This workflow is the final gate before code is considered complete. It validates operational correctness (Verify) and architectural alignment (Audit) to ensure the Goldfish did not violate the Elephant's constraints.

## 1. Context & Setup
1. **Locate Workspace**: Ask the user for the active feature directory (e.g., `docs/design/<feature-name>/`).
2. **State Verification**: Open `plan.md` and verify all tasks are complete. Use the parser utility to extract the critical validation parameters:
   `python bolt-skills/scripts/bolt_parser.py docs/design/<workspace>/spec.md --section "Interfaces & Constraints"`
   `python bolt-skills/scripts/bolt_parser.py docs/design/<workspace>/spec.md --section "Success Criteria"`

## Phase 1: Deterministic Verify (The Fast Checks)
Before performing deep analysis, ensure the code structurally works.
1. Run the project's test suite (`pytest`), linters (`ruff`), and type checkers (`mypy`) against all touched files.
2. Ensure all tests pass.
3. Validate that every Success Criterion (SC-NNN) from `spec.md` is demonstrably met by the tests or code.
4. **Gate**: If any tests or operational checks fail, abort the audit, report the errors, and throw the session back to `bolt-implement`.

## Phase 2: Semantic Audit (Anti-Drift)
If Phase 1 passes, perform a semantic review of the implementation against the intent.
1. **Git Diff Analysis**: Review the `git diff` of the current branch against its base (e.g., `git diff main...HEAD` or `git status/diff` if uncommitted).
2. **Constraint Validation**: Compare the diff against the `## Interfaces & Constraints` section of `spec.md`. 
   - *Did the agent modify a public API signature?*
   - *Did the agent introduce an unauthorized dependency?*
   - *Did the agent violate a performance SLA?*
3. **Architecture Validation**: Does the implemented code match the patterns defined in `## Architecture & Decisions (ADR)`?

## 3. The Audit Report
Prepare the final artifacts for human review.
1. **Create `audit-report.md`**: Generate `docs/design/<feature-name>/audit-report.md`. Initialize from `bolt-audit/templates/audit-report.md`.
2. **Structure the Report**:
   - **Requirement Coverage**: Table mapping each FR-NNN and SC-NNN to its test or evidence artifact.
   - **Deterministic Evidence**: Paste the outputs of the linters and test suites.
   - **Semantic Drift Analysis**: Explicitly list each constraint from the Halt Zone and verify if the `git diff` respected it.
   - **Residual Risks**: Document any technical debt or edge cases discovered.
3. **Set State**: Update the frontmatter of `audit-report.md` to `status: in-review`.

## 4. Final Decision Loop
1. Request a formal Code Review from the human Architect.
2. **PASS (Approved)**: If approved, update `spec.md` frontmatter to `status: audited`.
3. **FAIL/REVISE**: If rejected, pivot back to `bolt-implement` to fix the drift.

---
**Next Steps**: A successful audit means the Bolt is ready for promotion. Invoke `bolt-synthesis` to clean up the transient `plan.md` and consolidate the design docs.
