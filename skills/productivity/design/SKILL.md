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

Run the search script: `bash <skill-dir>/scripts/design_map_home.sh <repo>`. It
prints the decision-map home (an existing `.design/`, `.<harness>/design/` or
`docs/design/` that already holds maps) or, if none exists, the suggested
default `<repo-root>/.design/` with exit 1. The map is
`<home>/<topic-slug>.md`.

- On exit 0, use the printed home without asking.
- On exit 1, batch into your first question round a single confirmation of the
  default path, custom answer allowed.

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
  with a date. Write nothing else outside the map; supporting notes are only
  allowed in the map's own directory.
- End every round with: "continue, or BUILD?"

## Exit

`BUILD` or `/design off` clears the flag (a `UserPromptSubmit` hook does
this automatically and confirms it). At that point:

1. Summarize the map's Decisions and Build handoff sections.
2. Offer two options and let the user pick:
   - **Plan** -- write a plan from the locked map, inline in the reply or as
     `<map-dir>/plan.md`.
   - **Build** -- start implementing (enforcement is off). Dispatch per the
     repo's own conventions if any exist, otherwise inline.
   If the design session was long, also propose a handoff document (via the
   `handoff` skill when this harness has one) for whichever option they choose.
3. Do not start implementing inline unless the user picks Build and asks
   directly.

The skill is self-consistent: only the map and `design_map_home.sh` are
required for it to work. Other skills (`handoff`, ticket planners, dispatch or
implementer agents) are optional conveniences, never dependencies.

## Notes

- The flag is keyed by repo root, not session id -- see
  `scripts/design_flag.sh` for why and the limitation that follows (two
  sessions in the same repo share the mode).
- Reachable via a symlink outside this repo:
  `ln -s /root/geas-grimoire/skills/productivity/design ~/.claude/skills/design`.
