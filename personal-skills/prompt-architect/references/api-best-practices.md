# API Prompting Best Practices Reference

Source: Anthropic official docs (platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)
Last verified: April 2026

---

## General Principles

### Clarity and Direction
- Be specific about desired output format and constraints
- Provide instructions as numbered steps when order or completeness matters
- Think of Claude as a brilliant new employee: the more context you give, the better
- **Golden rule**: Show your prompt to a colleague with minimal context. If they'd be confused, Claude will be too.

### Context and Motivation
- Explain *why* behind instructions ("format as JSON because this feeds a downstream parser")
- Claude generalizes from explanations, not just rules

### Examples (Few-Shot / Multi-Shot)
- 3–5 examples is the sweet spot
- Wrap in `<example>` tags (multiple: `<examples>`)
- Make examples diverse (cover edge cases) and relevant (mirror actual use case)
- Examples can include `<thinking>` blocks to model reasoning patterns

### XML Tags
- Use for any prompt mixing instructions, context, examples, variables
- Consistent naming: `<instructions>`, `<context>`, `<input>`, `<output_format>`
- Nest tags naturally: `<documents>` containing `<document index="1">`

### Role Assignment
- Even one sentence makes a difference: "You are a helpful coding assistant specializing in Python"
- Put role in system prompt for API use

### Long Context (20k+ tokens)
- **Put documents above instructions and query** (up to 30% quality improvement)
- Wrap documents: `<document><source>...</source><document_content>...</document_content></document>`
- Ask Claude to quote relevant passages before answering (cuts noise)

---

## Output and Formatting

### Communication Style (Claude 4.6+)
- More concise and direct than previous models
- May skip post-tool-call summaries; add "After tool use, summarize what you did" if needed

### Format Control
- Tell Claude what TO do: "Write in flowing prose paragraphs"
- Use XML format indicators: "Write prose in `<smoothly_flowing_prose_paragraphs>` tags"
- Match prompt style to desired output style (markdown-heavy prompt → markdown-heavy output)
- For minimal markdown:

```
When writing reports or analyses, use flowing prose paragraphs.
Reserve markdown for inline code, code blocks, and simple headings (##, ###).
Do not use bullet points or numbered lists unless presenting truly discrete items.
```

### Deprecated (Claude 4.6+)
- **Prefilled assistant turns** (last assistant message) are deprecated
- Migrate: use `<output_format>` instruction in system prompt instead
- Example migration: instead of prefill `{`, use instruction "Respond with only a JSON object, no preamble"

---

## Tool Use

### Explicit Action Instructions
- "Implement changes" vs "suggest changes" — be explicit
- Proactive default: "Implement changes rather than suggesting them. Infer intent and use tools to discover missing details."
- Conservative default: "Do not edit files unless explicitly instructed. Default to providing information and recommendations."

### Parallel Tool Calls
- Claude 4.6 models excel at parallel execution
- Boost to ~100%: "When tool calls have no dependencies between them, make all independent calls in parallel"
- Reduce: "Execute operations sequentially with brief pauses for stability"

### Claude 4.6 Calibration
- These models are **more proactive** than previous versions
- Remove aggressive language like "CRITICAL: you MUST use X" — it causes overtriggering
- Replace "If in doubt, use [tool]" with "Use [tool] when it would enhance understanding"

---

## Thinking and Reasoning

### Adaptive Thinking (Claude 4.6+)
- `thinking: {type: "adaptive"}` — Claude decides when and how much to think
- Controlled via `effort` parameter: `low` / `medium` / `high` / `max`
- Better than manual `budget_tokens` in most cases
- Use for: multi-step tool use, complex coding, long-horizon agents

### Thinking Guidance
- Guide initial thinking: "After receiving tool results, reflect on quality and determine next steps before proceeding"
- Contain overuse: "Use extended thinking only when it meaningfully improves quality — typically multi-step reasoning"
- Commit prompt: "Choose an approach and commit. Avoid revisiting decisions unless new contradicting info appears."

### Manual CoT (when thinking is off)
- Use `<thinking>` and `<answer>` tags to separate reasoning from output
- Self-check: "Before finishing, verify your answer against [criterion]"

---

## Agentic Systems

### Long-Horizon Tasks
- Use structured state files (JSON for test results, freeform text for progress notes)
- Use git for state tracking across sessions
- First context window: set up framework, write tests, create init scripts
- Subsequent windows: iterate against todo list

### Context Window Management
- Claude 4.6 has context awareness (tracks token budget)
- If your harness compacts context automatically: "Your context will be compacted automatically. Do not stop tasks due to token concerns."
- Otherwise Claude may wrap up work prematurely near context limit

### Autonomy vs Safety
- Specify reversibility threshold:
  "Take local, reversible actions freely (edit files, run tests). For destructive or hard-to-reverse actions (git push --force, dropping tables, posting externally), ask before proceeding."

### Research Tasks
- Provide clear success criteria
- Encourage cross-source verification
- For complex research: "Develop competing hypotheses. Track confidence levels. Update a hypothesis file. Self-critique regularly."

### Subagent Orchestration (Claude 4.6)
- Models proactively delegate without explicit instruction
- Watch for overuse: Claude Opus 4.6 may spawn subagents for simple grep calls
- Calibrate: "Use subagents for parallel/isolated tasks. Work directly for single-file edits or tasks needing shared context."

### Minimizing Hallucinations
```
<investigate_before_answering>
Never speculate about code you have not opened. Read the file before answering questions about it.
Investigate relevant files BEFORE answering. Never make claims about code without investigating.
</investigate_before_answering>
```

### Avoiding Overengineering
```
Only make changes directly requested or clearly necessary.
Do not add features, refactor surrounding code, or add docstrings to unchanged code.
Implement the minimum complexity needed for the current task.
```

---

## Formatting Reference

### Avoid excessive markdown (system prompt snippet)
```
<avoid_excessive_markdown>
Write reports and analyses in flowing prose paragraphs. Use paragraph breaks for organization.
Reserve markdown for inline code, code blocks, and simple headings (##, ###).
Do not use bullet points or numbered lists unless presenting truly discrete items or the user asks.
Incorporate lists naturally into sentences instead.
</avoid_excessive_markdown>
```

### Proactive action (system prompt snippet)
```
<default_to_action>
Implement changes rather than only suggesting them. If the user's intent is unclear, infer the most
useful action and proceed, using tools to discover missing details rather than guessing.
</default_to_action>
```

### Parallel tools (system prompt snippet)
```
<use_parallel_tool_calls>
When multiple tool calls have no dependencies, make them all in parallel. Maximize parallel execution
for speed and efficiency. Never use placeholders or guess missing parameters.
</use_parallel_tool_calls>
```
