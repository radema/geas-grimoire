---
name: jules-cli
description: Interface with the Google Jules CLI to delegate asynchronous coding tasks. Use this tool to execute a specific plan, start a background session, or retrieve results from a remote Jules agent.
---

# Jules CLI Skill

## Goal
To execute the `jules` command-line tool for delegating long-running or complex coding tasks to a remote agent session. This skill handles session creation, status monitoring, and result retrieval.

## Usage Rules

### 1. Starting a Task
* **Command:** `jules remote new`
* **Required Flags:**
    * `--session "<prompt>"`: The detailed instruction or plan you want Jules to execute.
    * `--repo .`: Specifies the current directory as the target repository.
* **Constraints:** Always quote the session prompt. If the prompt is complex (multi-step), ensure it is passed as a single string.

### 2. Non-Interactive Mode
* **NEVER** run `jules` without arguments (this opens a TUI).
* **ALWAYS** use the subcommand syntax `jules remote <action>`.

### 3. Monitoring & Retrieval
* Use `jules remote list --session` to check the status of running tasks.
* Use `jules remote pull --session <ID>` to apply the changes (PR/Branch) locally once the task is complete.

## Command Reference

| Action | Command Pattern |
| :--- | :--- |
| **Start New Session** | `jules remote new --repo . --session "<Your Plan>"` |
| **List Sessions** | `jules remote list --session` |
| **Pull Results** | `jules remote pull --session <Session_ID>` |
| **Check Version** | `jules version` |

## Examples

### Example 1: Execute a Specific Plan
**User:** "Here is the refactoring plan for the auth module. Run it with Jules."
**Agent Execution:**
```bash
jules remote new --repo . --session "Refactor src/auth.ts to use the Singleton pattern. Update all import references in src/routes/ to match the new class structure. Run tests to verify."