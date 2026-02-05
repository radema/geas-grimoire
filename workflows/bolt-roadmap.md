---
description: Create a comprehensive strategic roadmap and diagram for the project by decomposing high-level goals into atomic, sequential/parallel bolts.
---

# Bolt Roadmap Workflow

This workflow guides the user and agent from a high-level project objective to a fully decomposed execution plan (`strategy-map.md`). It ensures all dependencies are identified, architectural patterns are selected, and the path forward is visually clear.

## Step 1: Context & Objective Discovery (The Interview)

Start by understanding what the user wants to build. Do not proceed to planning until you have a crystal-clear understanding of the scope.

1.  **Iterative Interview Loop**:
    *   **Action**: Ask one targeted question at a time.
    *   **Topics**:
        *   **Goal**: What is the ultimate deliverable? (e.g., "A Forecasting System," "A React Dashboard")
        *   **Scope**: What is IN and what is OUT of scope?
        *   **Constraints**: Are there specific technologies, libraries, or patterns required?
        *   **Architectural Preference**: Monolith vs. Microservices? OOP vs. Functional?
    *   **Constraint**: CONTINUE this loop until there are **no shadow points or doubts**. If you cannot write the spec for Bolt #1 immediately, you do not have enough info.

## Step 2: Strategic Decomposition

Once the objective is clear, break it down using the **Bolt Architecture**:

1.  **Identify Foundations**: What needs to exist first? (e.g., config setup, data loaders, validation frameworks).
2.  **Define Streams**: Group tasks into logical streams (e.g., "Frontend Stream," "Backend Stream," "Data Science Stream").
3.  **Atomic Bolts**: Break streams into "Bolts" - units of work small enough to be completed in one session but large enough to add value.
    *   *Rule*: A Bolt must have a clear "Definition of Done."

## Step 3: Sequencing & Dependency Analysis

Determine the execution order.

1.  **Sequential Chains**: Identify tasks that strictly block others (e.g., "Database Schema" must happen before "API Endpoints").
2.  **Parallel Opportunities**: Identify bolts that can be worked on simultaneously if multiple agents were available (e.g., "Frontend Component X" and "Backend Service Y").
3.  **Critical Path**: What is the shortest path to a "Walking Skeleton" (MVP)?

## Step 4: Artifact Generation

Create the specific deliverables.

### 4.1 Create `strategy-map.md`
Generate a markdown file with the following structure:
*   **Project Goal**: Concise summary.
*   **Architectural Standards**: The agreed-upon technical constraints.
*   **The Roadmap**: A list of Bolts, grouped by Phase/Stream.
    *   **Tagging**: Mark each Bolt explicitly as `[SEQUENTIAL]` or `[PARALLELABLE]`.
    *   **Description**: Provide a 1-sentence description of the output.

### 4.2 Create Mermaid Diagram
Append a Mermaid chart to `strategy-map.md` to visualize the flow.
*   Use `graph TD` (Top-Down).
*   Use subgraphs for Phases/Streams.
*   Use explicit arrows `-->` to show dependencies.
*   Style parallel blocks to look distinct.

## Step 5: User Validation

1.  Present the `strategy-map.md` to the user.
2.  Ask: "Does this accurately reflect our strategy? Are the dependencies correct?"
3.  Refine the plan based on feedback.
