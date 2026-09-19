---
name: bolt-verify
description: Run comprehensive evaluations (deterministic tests and critic reviews) against the completed Bolt before marking it ready for a Merge Request.
---

# Bolt-Verify Workflow: Quality Assurance & Evaluation

This workflow validates the code and prepares the final outputs for a Merge Request or production handover. It acts as the "Critic Agent" gate, running evaluations against the completed implementation to ensure it meets the initial `spec.md` constraints.

## 1. Context & Setup
1. **Locate Workspace**: Ask the user for the active Bolt directory (e.g., `.bolts/BOLT-XXX-<shortname>/`) if it wasn't provided.
2. **State Verification**: Open `plan.md`. Verify frontmatter is `status: complete`. If not, inform the user that verification requires a completed plan.
3. **Load Constraints**: Read `spec.md`, `architecture.md`, `constitution.md`, and `implementation_decisions.md` (if present) to gather the full set of Acceptance Criteria, contracts, architectural decisions, and logged deviations.

## 2. Deterministic Evaluations (The Fast Checks)
Before performing deep analysis, check structural integrity.
1. Run the project's test suite, linters, and type checkers against all touched files.
2. Ensure all tests pass.
3. *(Optional)* Check test coverage metrics if configured for the project.

## 3. Critic Evaluation (The Judgment Checks)
Perform a detailed review of the implementation.

1. **Requirement Traceability**: Verify every FR-NNN from `spec.md` has at least one corresponding test or verifiable artifact. Flag any FR without coverage.
2. **Success Criteria Validation**: Verify every SC-NNN is demonstrably met. For quantitative criteria (e.g., latency, throughput), require evidence (test output, benchmark result).
3. **Review Against Architecture**: Did the code deviate from the architecture patterns, design decisions, or tools defined in `architecture.md`? Cross-reference `implementation_decisions.md` — deviations that were logged are expected; unlogged deviations are findings.
4. **Constitution Compliance**: Check each constitution article that was flagged as relevant during `bolt-implementation`. Flag any violation not documented in `implementation_decisions.md`.
5. **Deep Analysis**: Look for edge cases, security vulnerabilities, or performance bottlenecks beyond the spec.
6. *(Optional)* **Skill Delegation**: Invoke specialized skills for domain-specific checks:
   - Use `webapp-testing` for UI or frontend workflow validation.
   - Use `verification-before-completion` for a standardized code audit checklist.

## 4. The Merge Request Package (MRP)
Prepare the final artifacts for human review.
1. **Create `mrp.md`**: Generate `.bolts/BOLT-XXX-<shortname>/mrp.md`. Initialize from `bolt-verify/templates/mrp.md`.
   - For highly complex Bolts, create an `mrp/` folder to store screenshots, logs, or extensive evidence.
2. **Structure the MRP**:
   - **Summary**: High-level overview of what was built and how it matched `spec.md`.
   - **Requirement Coverage**: Table mapping each FR-NNN and SC-NNN to its test or evidence artifact.
   - **Evidence**: Test execution results, coverage stats, and verification artifacts.
   - **Deviations**: Summary of entries from `implementation_decisions.md` and their impact.
   - **Residual Risks**: Known technical debt, skipped optional tasks, or minor follow-up items.
3. **Set State**: Include frontmatter `status: in-review`.

## 5. Final Decision Loop
1. Present `mrp.md` to the user and request a formal Code Review.
2. **PASS (Approved)**: If approved, update MRP frontmatter to `status: approved` and all active Bolt documents to `status: complete`.
3. **FAIL/REVISE**: If rejected, document findings in "Residual Risks" or a new `implementation_decisions.md` entry. Pivot back to `bolt-implementation` to address feedback.

---
**Next Steps**: A successful verification means the Bolt is complete and ready to merge. Follow with `bolt-synthesis` to promote learnings to global documentation, and optionally `bolt-retrospective` if process improvements were identified.
