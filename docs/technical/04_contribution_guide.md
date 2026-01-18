# Contribution Guide

This guide details the process for adding new capabilities to the Geas Grimoire.

## 1. Adding a New Skill

Skills are the functional units of the agent. To add a new skill:

1.  **Create Directory**: Create a new folder in `skills/` with a kebab-case name (e.g., `my-new-skill`).
2.  **Create Definition**: Add a `SKILL.md` file in that folder.
3.  **Add Metadata**: Ensure the file starts with the required YAML frontmatter.
    ```yaml
    ---
    name: my-new-skill
    description: A one-sentence description of what this skill does.
    ---
    ```
4.  **Define Instructions**: Write clear, step-by-step instructions for the Agent.
5.  **Add Scripts (Optional)**: If the skill requires complex logic, place Python scripts in a `scripts/` subfolder.

## 2. Adding a New Workflow

Workflows define the process for achieving a goal.

1.  **Create File**: Create a new markdown file in `workflows/` (e.g., `deployment-flow.md`).
2.  **Add Metadata**:
    ```yaml
    ---
    description: Step-by-step guide to deploying the application.
    ---
    ```
3.  **Define Steps**: Use numbered lists for sequential steps.
4.  **Annotate**: Use `// turbo` above steps where you want to authorize auto-execution of commands.

## 3. Style Guidelines

*   **Token Efficiency**: Be concise. Avoid fluff. The Agent pays for every token it reads.
*   **Clarity**: Use imperative verbs ("Run", "Create", "Analyze") rather than passive voice.
*   **Modularity**: Do not create massive monolithic files. Break complex tasks into sub-skills or sub-workflows.
