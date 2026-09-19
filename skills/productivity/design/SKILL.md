---
name: design
description: >-
  Puts the session into design mode -- batched clarifying questions and a
  tracked decision map, zero code edits, until the user types BUILD or
  /design off. Use when the user runs /design, says "design mode", or "let's
  design X before coding".
allowed-tools: Read, Grep, Glob, Bash, AskUserQuestion, Write, Edit
---

# design

Design mode separates deciding from building. While it's on, every question
is asked in a batch, every ruling is written to one decision map, and no code
gets edited -- hooks enforce that last part, not this prompt.

Arguments: `/design <topic>` starts it. `/design off` (or typing `BUILD`)
stops it.

## Start

**Step 1 -- pick the map path.**

- If the repo uses `.specify/specs/`, use `.specify/specs/<topic-slug>/design.md`.
- Otherwise `<repo-root>/docs/design/<topic-slug>.md`.

Create it if missing, with these sections:

```markdown
# <topic>

## Context

## Open questions

## Decisions
<!-- dated entries, one per ruling -->

## Build handoff
```

**Step 2 -- turn the flag on:**

```bash
bash <skill-dir>/scripts/design_flag.sh on "<absolute-map-path>"
```

Run it with `cwd` = the repo you're designing in (the skill process's own
working directory covers this; you don't need to pass a session id -- see
`scripts/design_flag.sh` header for how the flag is keyed).

## While it's on

- Every code edit and every bash write is denied by hook -- if one gets
  blocked, that's working as intended, not a bug to route around.
- Ground every question in the actual code: cite `file:line`.
- Batch clarifying questions into **one** `AskUserQuestion` call (up to 4
  questions), and always let a custom answer through.
- After each answer set, append the ruling(s) to the map's Decisions section
  with a date. Write nothing else outside the map (`docs/` and `.specify/`
  paths are also allowed by the hook, for supporting notes).
- End every round with: "continue, or BUILD?"

## Exit

`BUILD` or `/design off` clears the flag (a `UserPromptSubmit` hook does
this automatically and confirms it). At that point:

1. Summarize the map's Decisions and Build handoff sections.
2. Propose a next step -- `ticket-loop` or an `implementer` dispatch, or ask
   the user which. Do not start implementing inline unless asked directly.

## Notes

- The flag is keyed by repo root, not session id -- see
  `scripts/design_flag.sh` for why and the limitation that follows (two
  sessions in the same repo share the mode).
- Reachable via a symlink outside this repo:
  `ln -s /root/geas-grimoire/skills/productivity/design ~/.claude/skills/design`.
