---
name: prompt-architect
description: >
  Build, critique, or optimize prompts for Claude — whether for Claude.ai chat, API system prompts,
  or Claude Code CLAUDE.md / slash command / agent definitions. Use this skill whenever the user
  wants to write a new prompt from scratch, improve an existing one, reverse-engineer a reference
  output into prompt rules, or diagnose why a prompt isn't working. Trigger on: "write me a prompt",
  "improve my prompt", "help me prompt Claude", "my Claude prompt isn't working", "create a system
  prompt", "write a CLAUDE.md", "optimize this instruction", "turn this into a prompt", or any
  request to craft instructions for Claude in any context. Always use this skill before writing any
  substantial prompt — even if the user hasn't explicitly asked for "a skill".
---

# Prompt Architect

A skill for building, reviewing, and optimizing prompts for Claude — covering chat, API, and Claude Code contexts.

---

## Step 1 — Identify Context and Mode

Before writing a single line, determine:

**A. Deployment context** (ask if unclear):
- `chat` — Claude.ai conversation, one-off task
- `api-system` — System prompt for a product or pipeline built on the API
- `claude-code` — CLAUDE.md, slash command (`.claude/commands/`), or agent definition

**B. Mode**:
- `build` — Writing a prompt from scratch
- `optimize` — Improving an existing prompt the user provides
- `reverse-engineer` — User gives a reference output; derive the prompt rules from it
- `diagnose` — User says the prompt isn't working; find and fix the issue

If the user hasn't made the context clear, ask **one** question covering both: "Is this for a chat conversation, an API system prompt, or Claude Code (CLAUDE.md / commands)?"

---

## Step 2 — Gather Intent (Build Mode)

For `build` mode, collect the following. Extract anything already stated; ask only for what's missing. Ask in a **single grouped message**, not one question at a time.

```
INTENT CHECKLIST
[ ] Task — What should Claude do? (verb + object: "summarize", "generate", "review")
[ ] Success criteria — What does a great output look like?
[ ] Output format — Length, structure, file type, tone
[ ] Audience — Who reads the output? (affects register and detail level)
[ ] Context files — What background should Claude always read first?
[ ] Reference example — Any existing output to mimic or anti-pattern to avoid?
[ ] Constraints — What should Claude never do?
[ ] Deployment context — chat / api-system / claude-code
```

For `optimize` / `diagnose`, ask the user to paste the current prompt and describe the problem.

---

## Step 3 — Select the Right Anatomy

The anatomy of an effective prompt differs by deployment context. Use the correct template.

### 3A. Chat / One-off Prompt Anatomy

Based on the Ruben Hassid framework + Anthropic best practices:

```
[ROLE] — optional but powerful for complex tasks
You are a [specific role] with expertise in [domain].

[TASK]
I want to [VERB + OBJECT] so that [SUCCESS CRITERIA].

[CONTEXT FILES] — list files or paste content Claude should read first
First, read these completely before responding:
<context>
[filename.md] — [what it contains]
[paste inline content or reference]
</context>

[REFERENCE] — optional; include when style/format matters
Here is a reference for what I want to achieve:
<reference>
[Upload or paste reference output]
</reference>

Here's what makes this reference work:
<reverse_engineered_rules>
- Always [pattern from reference]
- Never [anti-pattern]
</reverse_engineered_rules>

[SUCCESS BRIEF]
Type of output: [contract / memo / report / post / code / analysis]
Recipient's reaction: [what they should think/feel/do]
Does NOT sound like: [what to avoid — generic AI, jargon-heavy, too casual]
Success means: [they sign / they approve / they reply / they act]

[RULES]
My constraints and standards — read fully before starting:
- Always [rule 1]
- Never [rule 2]
- If you're about to break a rule, stop and tell me.

[CONVERSATION / ALIGNMENT]
Before you write anything:
1. List the 3 rules most relevant to this task.
2. Give me your execution plan (5 steps maximum).
Only begin work once we've aligned.
```

**When to include each section:**

| Section | Always | When style matters | When output is complex |
|---|---|---|---|
| Task | ✅ | ✅ | ✅ |
| Context files | If files exist | ✅ | ✅ |
| Reference | ❌ | ✅ | Optional |
| Success Brief | For deliverables | ✅ | ✅ |
| Rules | For recurring use | ✅ | ✅ |
| Alignment | For complex/risky tasks | ✅ | ✅ |

---

### 3B. API System Prompt Anatomy

For prompts embedded in products or pipelines. Structure for cacheability (stable content first).

```xml
<role>
You are [specific role]. [One sentence on expertise and purpose.]
</role>

<instructions>
[Numbered steps for the core task. Use sequential steps when order matters.]
1. [Step one]
2. [Step two]
</instructions>

<context>
[Background the model always needs. Stable content goes here for prompt caching.]
</context>

<output_format>
[Explicit format: length, structure, markdown usage, tone.]
[Tell Claude what TO do, not what NOT to do.]
Example: "Write responses as flowing prose paragraphs."
</output_format>

<rules>
- Always [rule]
- Never [rule]
- If [edge case]: [behavior]
</rules>

<examples>
<example>
<input>[Sample input]</input>
<output>[Ideal output]</output>
</example>
</examples>
```

Key API-specific practices (see `references/api-best-practices.md` for full detail):
- Put long documents **above** the query (improves performance up to 30%)
- Use XML tags consistently — `<instructions>`, `<context>`, `<input>`, `<examples>`
- 3–5 diverse examples in `<examples>` tags for format/tone control
- State desired format positively ("write in prose") vs negatively ("don't use bullets")
- For tool-use prompts, be explicit: "implement changes, don't just suggest them"

---

### 3C. Claude Code Anatomy

Claude Code prompts (CLAUDE.md, slash commands, agents) follow different conventions because they're parsed by an agentic loop, not a single conversation turn.

**Read `references/claude-code-prompting.md` for full guidance.** Quick reference:

**CLAUDE.md** (project memory, always in context):
```markdown
# Project: [Name]

## Role and Mission
[What Claude's job is in this repo]

## Key Constraints
- Always [constraint]
- Never [constraint]

## Codebase Map
[Brief orientation: what's in each folder]

## Workflow
[How tasks should proceed: plan → test → implement → commit]

## Stack
[Languages, frameworks, tools]
```

**Slash Command** (`.claude/commands/name.md`):
```markdown
---
description: [One line: what this command does and when to use it]
---

# /name

[Task statement in imperative form]

## Steps
1. [Step]
2. [Step]

## Output
[What to produce and where to put it]
```

**Agent** (`.claude/agents/name.md`):
```markdown
---
name: [agent-name]
description: [When to delegate to this agent — be specific about trigger conditions]
---

You are a [role] specialist.

[Task, constraints, output format for this agent's domain]
```

Claude Code-specific rules (see also `references/claude-code-prompting.md`):
- Avoid "CRITICAL: you MUST use X" language — Claude 4.6 overtriggers on aggressive phrasing
- Prefer "Use X when..." over "Always use X"
- For parallel tool use: "Make independent tool calls in parallel"
- For agentic autonomy: specify reversibility threshold ("ask before force-push, proceed freely for local file edits")
- CLAUDE.md should be under 500 lines; use `references/` for depth

---

## Step 4 — Write the Prompt

Apply the selected anatomy. Follow these universal rules regardless of context:

### Universal Principles (from Anthropic best practices)

1. **Be direct, not vague.** "Summarize in 3 bullet points" beats "give a summary."
2. **Explain the why.** "Format as JSON because this feeds a downstream parser" helps Claude generalize.
3. **Examples over instructions.** 3–5 well-chosen examples outperform long rule lists.
4. **XML tags for complex prompts.** Wrap distinct content types in named tags.
5. **Positive instructions.** "Write in prose paragraphs" > "Don't use bullet points."
6. **Long content above the query.** Documents → instructions → query order.
7. **Ask Claude to plan before acting.** "List your approach in 3 steps, then execute."
8. **Self-check instruction.** "Before finishing, verify your output against [criterion]."

### Anti-patterns to avoid

| Anti-pattern | Better alternative |
|---|---|
| "Do not use markdown" | "Write in smooth prose paragraphs" |
| "Be concise" | "Keep the response under 200 words" |
| Vague role ("Be an expert") | Specific role ("You are a senior Python engineer at a fintech firm") |
| Rules as negatives only | Pair every "never" with a "instead, do X" |
| No examples | Add 1–3 examples; wrap in `<example>` tags |
| Prefilled assistant turn (deprecated in Claude 4.6+) | Use `<output_format>` instruction instead |
| Aggressive triggering language in Claude Code | Normal phrasing; Claude 4.6 follows instructions without coercion |

---

## Step 5 — Alignment Check

Before handing over the final prompt, run this internal checklist:

```
QUALITY GATE
[ ] Task is a clear verb + object
[ ] Success criteria are specific and testable
[ ] Format is stated positively ("write X" not "don't do Y")
[ ] At least one example included (for non-trivial outputs)
[ ] XML tags used for multi-section prompts
[ ] Long context placed before the query
[ ] Rules listed as Always/Never pairs where possible
[ ] Deployment context reflected in anatomy choice
[ ] Claude Code prompts: no aggressive override language
```

If any item is ❌, fix it before delivering.

---

## Step 6 — Deliver and Offer Iteration

Present the prompt in a code block (so it's copyable). Then:

1. **Explain the key choices** — why each major section is included
2. **Flag optional additions** — what could be added if the user wants more control
3. **Invite testing** — "Try this and tell me what the output looks like; I can tune it from there"

For `optimize` / `diagnose` mode, also show a before/after diff of the key changes and explain why each change helps.

---

## Reference Files

- `references/api-best-practices.md` — Full Anthropic API prompting reference (formatting, tool use, thinking, agentic patterns)
- `references/claude-code-prompting.md` — Claude Code-specific patterns (CLAUDE.md, agents, hooks, context management)
