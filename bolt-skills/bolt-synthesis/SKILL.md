---
name: bolt-synthesis
description: Manage the project's knowledge base. Run post-audit to clean up transient Goldfish checklists (plan.md), merge feature updates back into master design docs, and promote architectural decisions to global project knowledge.
---

# Bolt-Synthesis Workflow: The Archivist & Janitor

This workflow executes immediately after a Bolt passes `bolt-audit` and is marked `status: audited`. Its primary job is to clean up transient execution files (The Goldfish's memory) and durably record the final state of the architecture (The Elephant).

## 1. Context & Setup
1. **Locate Workspace**: Ask the user for the active feature directory (e.g., `docs/design/<feature-name>/` or `docs/design/<feature-update>/`).
2. **State Verification**: Verify that `spec.md` or `audit-report.md` has `status: audited`. If not, abort and tell the user to run `bolt-audit` first.

## 2. Archival & Cleanup (The Goldfish Memory Flush)
The execution checklist (`plan.md`) is transient. It is no longer needed once the code is audited.
1. **Delete `plan.md`**: Remove `plan.md` from the feature directory.
2. **Archive Audit Report**: Keep `audit-report.md` in the directory (or append its core findings to the `spec.md` if the user prefers keeping a single file per feature). Ensure its status is explicitly closed out.

## 3. Consolidation: Modifying Pre-existing Features
If the audited directory is a transient feature-update folder (e.g., `docs/design/<feature-update>/`):
1. **Read Master Doc**: Open the master design document for the feature (e.g., `docs/design/<feature>.md`).
2. **Merge Changes**: Intelligently merge the updated requirements, constraints, and ADRs from the transient `spec.md` into the master `<feature>.md`. Do not just append; rewrite sections for flow and coherence.
3. **Delete Transient Folder**: Once the master design document is successfully updated and saved, safely delete the transient `docs/design/<feature-update>/` directory.

## 4. Global Documentation Update
If the feature introduces a new architectural pattern, global constraint, or tool choice (logged in the `## Architecture & Decisions (ADR)` section):
1. **Promote to Global**: Update the project's global documentation (e.g., `REQUIREMENTS.md`, `ARCHITECTURE.md`, or `.sdlc/CONVENTIONS.md`).
2. **Link Context**: Ensure the global documentation links back to the feature's design document for context.

## 5. Final Review
1. Report the cleanup actions and any global documentation updates to the user.
2. The Bolt lifecycle is now complete.

---
**Next Steps**: If process improvements or constitution failures were identified during the lifecycle, queue a `bolt-retrospective`. Otherwise, the team is ready for the next Bolt (`bolt-intent`).
