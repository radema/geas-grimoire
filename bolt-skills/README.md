# Bolt Skills Directory

## Purpose
This directory contains a collection of specialized "skills" designed to guide and automate the agentic development lifecycle (the "Bolt" lifecycle). These skills establish structured workflows for project governance, feature specification, implementation, testing, knowledge synthesis, and continuous process improvement. By using these skills, the development process remains modular, test-driven, and aligned with core engineering standards.

## Skills Overview

Each subdirectory here represents a distinct skill and contains a `SKILL.md` file that defines its behavior, instructions, and required workflows. Below is an enumeration of each skill and a short description of its function:

*   **`bolt-constitution`**
    Establish a project governance document (`constitution.md`) with immutable architectural articles that all Bolts inherit. Run once per project before `bolt-roadmap`.

*   **`bolt-implementation`**
    Execute the technical plan for a feature using bounded, task-by-task execution and evaluation checks.

*   **`bolt-intent`**
    Define requirements, specifications, architecture, and step-by-step task plans for a new feature. Includes a mandatory clarification loop and optional research gate before architecture is authored.

*   **`bolt-research`**
    Investigate and document technology choices before architecture is locked. Invoked from `bolt-intent` Phase 2 when new technology decisions are required. Produces `research.md`. Optional — skip with a documented reason when a Bolt extends an established pattern.

*   **`bolt-retrospective`**
    A structured post-Bolt retrospective that captures process improvements, proposes constitution amendments, and updates `bolt-*` skills. Targets the development process — not the project. Distinct from `bolt-synthesis`.

*   **`bolt-roadmap`**
    Create a comprehensive strategic roadmap and diagram for the project by decomposing high-level goals into atomic, sequential/parallel bolts.

*   **`bolt-synthesis`**
    Manage the project's knowledge base by documenting decisions, resolving assumptions, and updating global architecture or conventions. Targets project knowledge — not process improvement.

*   **`bolt-verify`**
    Run comprehensive evaluations (deterministic tests and critic reviews) against the completed Bolt before marking it ready for a Merge Request.

*   **`debrief`**
    Systematically wrap up a session by summarizing progress, scouting for reusable skills, and cleaning up context.
