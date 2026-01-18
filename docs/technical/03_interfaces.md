# Interface Definitions

This document details the interfaces through which an Agent interacts with the capabilities defined in this repository.

## 1. Skill Interface

Skills are primarily invoked through **Context Activation** and **Script Execution**.

### Context Activation
When an Agent determines a skill is relevant (based on the `description`), it reads the `SKILL.md` file using `view_file`.
*   **Input**: The Agent's current objective and the Skill's instructions.
*   **Output**: The Agent adjusts its behavior or follows the step-by-step procedure defined in the markdown.

### Script Execution
Many skills package complex logic into Python scripts to ensure reliability and token efficiency.
*   **Method**: `run_command` tool.
*   **Standard Environment**: Python 3.x within the repository's virtual environment.
*   **Argument Pattern**: Scripts should generally accept target paths or configuration flags as command-line arguments.

**Examples:**
```bash
# Documentation scaffolding
python3 .agent/skills/technical-doc-writer/scripts/scaffold_docs.py <target_directory>

# Chart generation (word-doc skill)
uv run python skills/word-doc/scripts/chart_generator.py \
  --type line --data data.csv --x month --y revenue --output chart.png

# Markdown to Word conversion (word-doc skill)
uv run python skills/word-doc/scripts/md_to_docx.py \
  --input content.md --template templates/report.docx --output report.docx
```

## 2. Workflow Interface

Workflows are "Rituals" that the agent follows.

*   **invocation**: The user may request a workflow (e.g., "Run the deployment workflow"), or the Agent may select one based on the task type.
*   **Process**: The Agent reads the workflow file and executes steps sequentially.
*   **State Management**: Workflows may require the Agent to maintain state (e.g., "Step 1 complete, proceeding to Step 2").

## 3. MCP Integration

The `geas-grimoire` assumes the presence of standard Model Context Protocol (MCP) servers to bridge the gap between text generation and system action.

### Required Capabilities
To fully utilize the skills in this repository, the connected Agent must have access to:
*   **FileSystem Access**: `view_file`, `list_dir`, `write_to_file`, `run_command`.
*   **(Optional) MCP Servers**:
    *   `github-mcp-server`: For PR/Issue management skills.
    *   `memory`: For long-term knowledge retention skills.
    *   `sequential-thinking`: For complex reasoning workflows.
