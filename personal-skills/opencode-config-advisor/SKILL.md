---
name: opencode-config-advisor
description: Detects, analyzes, and suggests changes to the Opencode CLI configuration file (config.json). Use this when the user complains about Opencode performance, asks to change the default model, or wants to modify CLI behavior.
---

# Opencode Config Advisor

## Goal
To locate the active Opencode configuration file, read its current state, and propose valid JSON modifications to satisfy user requirements (e.g., switching models, increasing context limits, changing output format).

## Usage Rules

### 1. Config Discovery
Always check for the configuration file in the following order of precedence:
1.  **Project Local:** `./opencode.json` (or `.opencode/config.json`)
2.  **Global (User):** `~/.config/opencode/opencode.json`
3.  **Legacy:** `~/.opencode.json`

*Command to use:* `ls -F ~/.config/opencode/opencode.json ./opencode.json 2>/dev/null`

### 2. Analysis & Safety
* **Read First:** Always run `cat <path_to_found_config>` before suggesting changes.
* **Validate JSON:** Ensure any proposed changes result in valid JSON. Do not use trailing commas.
* **Backup:** If executing a write operation, suggest backing up the original file first (`cp config.json config.json.bak`).

### 3. Common Modifications
* **Model Switching:** Look for `"model"` or `"default_model"`. Common values are `gpt-4o`, `claude-3-5-sonnet`, `gemini-pro`.
* **Context Window:** Look for `"max_tokens"` or `"context_limit"`.
* **API Keys:** **NEVER** output full API keys in the chat. Use placeholders like `"sk-..."` when displaying file content.

## Examples

### Example 1: Switch Model
**User:** "Opencode is being too expensive, switch it to a cheaper model."
**Agent Execution:**
1.  Locates `~/.config/opencode/opencode.json`.
2.  Reads content.
3.  Proposes changing `"model": "gpt-4"` to `"model": "gpt-4o-mini"`.

### Example 2: Debugging
**User:** "Why is Opencode ignoring my ignores?"
**Agent Execution:**
1.  Reads config to check the `"ignore_patterns"` or `"gitignore"` setting.
2.  Checks if `.gitignore` exists in the current directory.
3.  Suggests adding specific patterns to the config if the global setting is missing.