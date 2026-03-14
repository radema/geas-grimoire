---
name: bolt-verify
description: Run comprehensive evaluations (deterministic tests and critic reviews) against the completed Bolt before marking it ready for a Merge Request.
---

# Bolt-Verify Workflow: Quality Assurance & Evaluation

This workflow validates the code and prepares the final outputs for a Merge Request or production handover. It acts as the "Critic Agent" gate, running evaluations against the completed implementation to ensure it meets the initial `spec.md` constraints.

## 1. Context & Setup
1. **Locate Workspace**: Ask the user for the active Bolt directory (e.g., `.bolts/BOLT-XXX-<shortname>/`) if it wasn't provided in the prompt.
2. **State Verification**: Open the `plan.md` file in the Bolt directory. Verify its frontmatter is set to `status: complete`. If it is not, inform the user that verification typically requires a completed plan.
3. **Load Constraints**: Read `spec.md`, `architecture.md`, and the codebase to gather the Acceptance Criteria, data models, and interface contracts.

## 2. Deterministic Evaluations (The Fast Checks)
Before performing deep analysis, check the structural integrity of the code.
1. Run the project's test suite, linters, and type checkers against the touched files. 
2. Ensure all tests pass.
3. *(Optional)* Check test coverage metrics if configured for the project.

## 3. Critic Evaluation (The Judgment Checks)
Perform a detailed review of the implementation. Use targeted skills to assist.
1. **Review Against Specs**: Read the implementation and compare it strictly against the Acceptance Criteria in `spec.md`.
2. **Review Against Architecture**: Did the code deviate from the architecture patterns, design decisions, or tools defined in `architecture.md`?
3. **Deep Analysis**: Look for edge cases, security vulnerabilities, or performance bottlenecks.
4. *(Optional)* **Skill Delegation**: Invoke specialized skills for specific domains, for example:
   - Use `webapp-testing` if validating a UI or frontend workflow.
   - Use `verification-before-completion` for a standardized code audit checklist.

## 4. The Merge Request Package (MRP)
Prepare the final artifacts for human review.
1. **Create `mrp.md`**: Generate a `.bolts/BOLT-XXX-<shortname>/mrp.md` document.
   - For highly complex Bolts, you may create a `mrp/` folder to store screenshots, logs, or extensive evidence.
2. **Structure the MRP**: Include the following sections:
   - **Summary**: High-level overview of what was built and how it matched the `spec.md`.
   - **Evidence**: Test execution results, coverage stats, and browser verification artifacts.
   - **Residual Risks**: Any known technical debt, skipped optional tasks, or minor follow-up items.
3. **Set State**: Include frontmatter `status: in-review` in the MRP file.

## 5. Final Decision Loop
1. Present the completed `mrp.md` to the user and request a formal Code Review.
2. **PASS (Approved)**: If the user approves, change the MRP frontmatter to `status: approved` and ensure all other active documents in the Bolt are set to `status: complete`.
3. **FAIL/REVISE**: If the user rejects the work or requests changes, document those findings in the "Residual Risks" or a new ADR. The user can then pivot back to `bolt-implementation` to address the feedback.

---
**Next Steps**: A successful verification means the Bolt is complete and ready to be merged.
