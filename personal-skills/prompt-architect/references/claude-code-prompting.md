# Claude Code Prompting Reference

Sources:
- FlorianBruniaux/claude-code-ultimate-guide (github.com)
- Anthropic official Claude Code docs
Last verified: April 2026

---

## Overview: Why Claude Code is Different

Claude Code prompts run inside an **agentic loop** — not a single conversation turn. Claude reads files,
executes bash commands, makes tool calls, and iterates. This changes how prompts should be written:

- Instructions must survive **multi-turn context** — Claude re-reads CLAUDE.md on every new context window
- Prompts must handle **tool orchestration** — Claude decides when to grep, read files, run commands
- Tone matters differently — aggressive coercion language causes overtriggering on Claude 4.6+

---

## CLAUDE.md — Project Memory

CLAUDE.md is always injected at the start of every session. It is the single most important file.

### Recommended Structure

```markdown
# [Project Name]

## Role and Mission
[What Claude's job is in this codebase. One paragraph max.]

## Stack
[Languages, frameworks, key libraries, runtime versions]

## Codebase Map
[Brief orientation — one line per major folder/module]

## Workflow
[How tasks should proceed. Example:]
1. Read relevant files before making changes
2. Write tests before implementing
3. Implement, run tests, fix failures
4. Commit with conventional commit messages

## Key Constraints
- Always [constraint with reason]
- Never [constraint with reason]
- Before [risky action], [checkpoint behavior]

## File Conventions
[Naming, structure, formatting rules specific to this project]

## Commands
[Key bash commands: how to run tests, lint, build]
```

### CLAUDE.md Best Practices
- Keep under **500 lines** — longer files get skimmed, not read
- Use `references/` folder for deep detail; point to it from CLAUDE.md
- Put the most critical constraints at the **top** (context pressure degrades recall at 70%+)
- State constraints with reasons: "Never rm -rf without confirmation (irreversible)" beats "Never rm -rf"
- Update CLAUDE.md when you discover something Claude keeps getting wrong

### Context Window Pressure (Golden Rules)
From the Claude Code ultimate guide:
- **0–50%**: work freely
- **50–70%**: start paying attention
- **70–90%**: run `/compact` to compress context
- **90%+**: run `/clear` — behavior becomes erratic

---

## Slash Commands (`.claude/commands/name.md`)

Slash commands are user-invocable workflows. They live in `.claude/commands/` (project-level) or
`~/.claude/commands/` (global).

### Template

```markdown
---
description: One-line description of what this command does and when to trigger it
---

# /[command-name]: [Title]

[Imperative task statement. What Claude should do when this command runs.]

## Context
[What Claude should read or check first]

## Steps
1. [Step one — specific action]
2. [Step two]
3. [Step three]

## Output
[What to produce, where to put it, what format]

## Quality Gate
Before finishing, verify:
- [ ] [Check 1]
- [ ] [Check 2]
```

### Good Slash Command Examples

**`/pr` — Pull Request Description**
```markdown
---
description: Generate a pull request description from git diff and recent commits
---
Read the git diff and last 5 commit messages. Write a PR description with:
- Summary (2-3 sentences on what changed and why)
- Key changes (bulleted, specific)
- Testing notes
Output as markdown, ready to paste into GitHub.
```

**`/commit` — Conventional Commit**
```markdown
---
description: Stage all changes and create a conventional commit message
---
Review the staged changes. Write a conventional commit message following:
`type(scope): subject` where type is feat/fix/docs/refactor/test/chore.
Subject: imperative, under 72 chars. Ask for confirmation before committing.
```

---

## Agent Definitions (`.claude/agents/name.md`)

Agents are sub-Claude instances that can be delegated specialized tasks.

### Template

```markdown
---
name: [agent-name]
description: >
  [When to delegate to this agent. Be specific about trigger conditions.
  Include example phrases that should route here.]
---

You are a [specific role] specialist.

## Your Task
[What this agent does. Imperative, specific.]

## Constraints
- Always [constraint]
- Never [constraint]
- Your scope is limited to: [scope]

## Output
[What format, where to put results, how to signal completion]
```

### Agent Trigger Language (Claude 4.6+)
**Do NOT use:**
- "CRITICAL: ALWAYS delegate to this agent"
- "You MUST use this agent when..."
- "NEVER handle X without this agent"

**Use instead:**
- "Delegate to this agent when the task involves [specific condition]"
- "Use for [domain] tasks, especially when [trigger phrase]"
- "This agent handles [scope] — route here for [examples]"

Claude 4.6 models follow normal instructions reliably. Aggressive language causes overtriggering.

---

## Hooks (`.claude/hooks/`)

Hooks run bash scripts at specific lifecycle points. They are **not prompts** — they're shell scripts
with a JSON trigger definition.

### Lifecycle Points
- `PreToolUse` — before Claude calls a tool (can block dangerous operations)
- `PostToolUse` — after a tool call
- `Stop` — when Claude finishes a task
- `SubagentStop` — when a subagent finishes

### Hook Use Cases
- Block `rm -rf`, `git push --force`, `DROP TABLE` — dangerous-actions-blocker
- Detect prompt injection in CLAUDE.md edits
- Auto-run linter after file edits
- Auto-commit after task completion

---

## Context and Memory Patterns

### Memory Hierarchy
1. **CLAUDE.md** — always in context, stable project memory
2. **Conversation history** — degrades with context pressure
3. **External files** — read on demand via Read tool
4. **Agent-specific context** — scoped to the subagent

### Scoped File Reading (reduce token waste)
Instead of grepping everything:
```markdown
## Finding Code
Before grepping broadly, first check:
1. [key_module.py] for [domain] logic
2. [config/] for configuration
3. [tests/] to understand expected behavior
Only grep if the above files don't contain what you need.
```

### State Across Sessions
- Use `progress.md` or `TODO.md` for task tracking (plain text, freeform)
- Use `tests.json` or structured files for test status
- Use git commit messages as a log of what's been done
- Start fresh context by: "Review progress.md and git log, then continue from where we left off"

---

## Calibration: Claude 4.6 vs Previous Models

| Behavior | Old models | Claude 4.6 |
|---|---|---|
| Tool triggering | Needed aggressive prompting | Triggers reliably on normal language |
| Parallel tool use | Sometimes needed coaxing | Default behavior |
| Context awareness | None | Tracks remaining token budget |
| Subagent use | Explicit only | Proactive; may over-delegate |
| Overengineering | Less common | May add unrequested abstractions |

**Migration checklist for existing CLAUDE.md / system prompts:**
- [ ] Remove "CRITICAL:", "ALWAYS", "NEVER" in all-caps unless genuinely necessary
- [ ] Replace "If in doubt, use X" with "Use X when [condition]"
- [ ] Add scope limits for subagents: "Work directly for single-file edits"
- [ ] Add overengineering guard: "Only make changes directly requested"

---

## Production Patterns

### Minimal Overengineering (system prompt)
```
Only make changes directly requested or clearly necessary. Do not add features,
refactor surrounding code, add docstrings to unchanged code, or design for
hypothetical future requirements. Minimum complexity for the current task.
```

### Safety for Destructive Actions
```
Take local, reversible actions freely (edit files, run tests, read logs).
For actions that are hard to reverse or affect shared systems — git push --force,
deleting branches, dropping database tables, posting to external services —
ask the user before proceeding.
```

### Grounded Answers (no hallucination)
```
<investigate_before_answering>
Never speculate about code you have not read. Read the file before answering.
Make no claims about code without first investigating. Give grounded answers only.
</investigate_before_answering>
```

### Long Tasks / Multi-Window
```
Save your current state and progress to progress.md before the context window
fills. Include: what's done, what's next, any blockers. On resume, read progress.md
and git log before continuing.
```

---

## Skills vs Agents vs Commands — When to Use Which

| Mechanism | Scope | Use when |
|---|---|---|
| CLAUDE.md | Always active, whole project | Persistent constraints, codebase orientation |
| Slash command | On-demand, user-invoked | Repeatable workflows (PR, commit, review) |
| Agent | Delegated subtask, isolated context | Specialized domain work that can run independently |
| Hook | Automated, triggered by lifecycle | Safety gates, auto-formatting, audit logging |
| Skill (`.claude/skills/`) | Shared across projects | Cross-repo best practices, templates |

---

## Common Mistakes

1. **CLAUDE.md over 500 lines** — Claude skims it. Move details to `references/`.
2. **Vague constraints** — "Be careful with databases" → "Never run DELETE without a WHERE clause. Never DROP without explicit confirmation."
3. **No workflow definition** — Claude invents its own. Define the loop explicitly.
4. **Aggressive tone on Claude 4.6** — Causes overtriggering. Use normal language.
5. **No quality gate** — Add a checklist Claude verifies before marking a task done.
6. **No file map** — Claude greps everything. A 5-line codebase map saves hundreds of tokens per session.
