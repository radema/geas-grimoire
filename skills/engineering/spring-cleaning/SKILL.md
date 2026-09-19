---
name: spring-cleaning
description: >-
  Audit and clean up stale Claude Code configuration — outdated CLAUDE.md rules, dead or
  overlapping skills, and stale hooks — at user scope (~/.claude) or repository scope. Use this
  whenever the user says "spring cleaning", asks to audit their CLAUDE.md / skills folder / hooks,
  asks what config is stale, dead, unused, duplicated, or safe to delete, or wants to slim down
  their rules, skills, or settings.json hooks — even if they only name one of the three layers.
  Audit-first: reports verdicts and HALTS; executes deletions/merges only on explicit approval.
  NOT for mining sessions for recurring failures (use self-harness for that) and NOT for speckit
  artifact cleanup (speckit-cleanup-run).
---

# Spring Cleaning — config audit & cleanup

Audit one or more layers of Claude Code configuration for dead weight, then (only after
explicit approval) execute the cleanup. Three layers:

| Layer | What it audits | Reference to read |
|---|---|---|
| `claude.md` | A CLAUDE.md file, line by line, against Anthropic's *current* published guidance | `references/claude-md-audit.md` |
| `skills` | A skills folder for overlap, dead weight, never-used and broken skills | `references/skills-audit.md` |
| `hooks` | Every configured hook: cost, trigger breadth, collisions, dead paths | `references/hooks-audit.md` |

## Parsing the request

- **Layers**: take them from the arguments/request (`claude.md`, `skills`, `hooks` — any subset).
  If none named, audit all three.
- **Scope**: `user` (default) = `~/.claude/CLAUDE.md`, `~/.claude/skills/`, `~/.claude/settings.json`
  + `settings.local.json` + `~/.claude/hooks/`. `repo` = the current repo's `CLAUDE.md`,
  `.claude/skills/`, `.claude/settings.json`. If the user pointed at a specific file or folder,
  that wins. Ask only if genuinely ambiguous, and ask once.

Read the reference file for each selected layer before auditing that layer — each contains the
exact checklist and output format. Do not audit from memory of this file alone.

## Rules that apply to every layer

**The audit phase is strictly read-only.** No edits, no deletions, no renames, no "quick fixes"
along the way — the user is deciding what to cut, and the inventory must describe the config as
it actually is right now.

**Honest accounting.** Every numbered check in a layer's spec either ran or appears in the report
marked **NOT RUN** with the reason (fetch failed, file unreadable, evidence source missing).
Never silently skip a check, and never present a guess as a checked result. An empty grep is
*absence of evidence*, not proof — label it that way.

**Report inline.** Verdicts go in tables in the chat reply, per the format each reference file
defines. Lead with the counts.

**Then HALT.** End the audit with the verdict table(s) and the question of which findings to act
on. Do not touch anything until the user says so — an unanswered question means stop at the
report, never "proceed with best judgment".

## Execute phase (only after explicit approval)

When the user approves specific findings (and only those):

1. Work one layer at a time, restating the approved items before starting.
2. **Back up before destroying**: copy any skill directory, hook script, or file to be deleted or
   merged into the session scratchpad first, and say where the backup is.
3. Show the change before each destructive step — the CLAUDE.md diff, the settings.json hook
   block being removed, the skill dirs being merged — as a diff or explicit list.
4. CLAUDE.md rewrites: apply the approved DELETE/REWRITE verdicts only; KEEP lines are untouched
   verbatim. Truth rules ("only claim what you verified") are never edited, even if approved by
   a blanket "apply everything" — call it out and skip.
5. After each layer, report exactly what changed, with paths.

Items the user did not name stay untouched. "Apply all" means all items *in the report*, nothing
discovered later.

## Helper script

`scripts/usage_evidence.sh <name>...` — read-only grep over `~/.claude/projects/*/*.jsonl` and
`~/.claude/history.jsonl`; prints per name: hit count and the most recent modification time among
files that matched. Used by the skills and hooks layers for "was this ever actually used?"
evidence. Run it rather than hand-rolling greps.

## Boundary with neighboring skills

- `self-harness`: mines sessions for recurring *failures* and proposes additive fixes. If the
  user's real question is "why does Claude keep doing X", route there.
- `memory-triage`: memory files, not config. Don't audit `memory/` here.
- `git-sweep`: stale local git worktrees and local branches. Repo working state, not config —
  never audit or delete those here.
