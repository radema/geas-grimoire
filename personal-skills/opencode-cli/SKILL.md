---
name: opencode-cli
description: Interface with the Opencode CLI to execute AI-driven coding tasks, generate code snippets, and manage agent sessions non-interactively. Use this when the user asks to "ask Opencode" or "use Opencode" to perform a task.
---

# Opencode CLI Skill

## Goal
This skill allows the agent to utilize the `opencode` command-line tool to perform coding tasks, query the Opencode agent, and manage configuration. It is specifically optimized for **non-interactive** usage to prevent the agent from getting stuck in Terminal UI (TUI) modes.

## Usage Rules

### 1. Non-Interactive Execution (CRITICAL)
* **NEVER** run the bare command `opencode` without arguments. This launches an interactive TUI that will hang the agent session.
* **ALWAYS** use `opencode run "<prompt>"` for generation, questions, or coding tasks.
* **ALWAYS** use the `-p` or `--prompt` flag if `run` is not applicable in your specific version, but `opencode run` is the standard for delegation.

### 2. Output Handling
* The output from Opencode is standard text. Read the output to confirm the task was completed or to retrieve the generated code.
* If the user asks for JSON output and the CLI supports it, append `--output-format json`.

### 3. Context & Directories
* If the user specifies a working directory, use the `-c` or `--cwd` flag:
    `opencode run "prompt" --cwd /path/to/dir`

## Command Reference

| Action | Command Pattern |
| :--- | :--- |
| **Run Prompt** | `opencode run "Your instruction here"` |
| **Check Version** | `opencode --version` |
| **List Models** | `opencode models` |
| **Auth Status** | `opencode auth list` |
| **Set Directory** | `opencode run "..." --cwd ./subdir` |

## Examples

### Example 1: Generative Task
**User:** "Use opencode to write a Python script that calculates Fibonacci numbers."
**Agent Execution:**
```bash
opencode run "Write a Python script that calculates Fibonacci numbers and prints the first 10."