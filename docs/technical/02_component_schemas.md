# Component Schemas

This section defines the data structures and schemas used for the core components of the Geas Grimoire: **Skills** and **Workflows**.

## 1. Skill Schema

Skills are self-contained directories located in `skills/`. Each skill MUST contain a `SKILL.md` file which serves as the definition and entry point.

### Directory Structure
```text
skills/
└── <skill-name>/
    ├── SKILL.md          # Required: Definition and instructions
    ├── scripts/          # Optional: Python/Bash automation scripts
    └── resources/        # Optional: Templates, examples, or static assets
```

### Metadata (YAML Frontmatter)
The `SKILL.md` file must begin with a YAML frontmatter block:

```yaml
---
name: <skill-identifier>
description: <short-description>
---
```

| Field | Type | Description |
| :--- | :--- | :--- |
| `name` | String | A unique identifier for the skill (e.g., `technical-doc-writer`). Should match the directory name. |
| `description` | String | A concise summary of when and how to use this skill. Used by the Agent's router to select the skill. |

## 2. Workflow Schema

Workflows are Markdown files located in `workflows/` that define procedural logic.

### Metadata (YAML Frontmatter)

```yaml
---
description: <short-description>
---
```

| Field | Type | Description |
| :--- | :--- | :--- |
| `description` | String | Explains the goal of the workflow (e.g., "Deploy the application to production"). |

### Execution Annotations
Workflows support special annotations to control the Agent's execution autonomy.

| Annotation | Scope | Behavior |
| :--- | :--- | :--- |
| `// turbo` | Next Step | Grants permission to auto-run the specific `run_command` in the immediately following step. |
| `// turbo-all` | File | Grants permission to auto-run ALL `run_command` calls in the entire workflow. |

## 3. Rule Schema (Agent Persona)

Rules are defined in `rules/` or incorporated into the Agent's system prompt.

### Structure
Rules typically follow a markdown sectioning structure:
*   `<MEMORY>`: Durable instructions or context.
*   `<user_rules>`: Mandatory constraints.
*   `<workflows>`: References to available workflows.
*   `<skills>`: References to available skills.
