# Handoff — {{SUBJECT}}

**Repo**: `{{REPO_PATH}}`
**Branch**: `{{BRANCH}}`
**Date**: {{DATE}}
**Next-session focus**: <what the next agent is being asked to do — from the user's arguments if given>
**State**: <commits local/pushed? PR? tests green/red? deployed where?>
**Supersedes**: <prior handoff filename, or `—`>

---

## 1. Scope of this session

<2–5 lines. What was asked, what was in scope, what was explicitly out.>

## 2. What was done / verified — with evidence

Tag every claim: **`[V]`** = verified this session (command output, `git status`/`log`/`diff`, file
re-read, test re-run) · **`[?]`** = recalled or inferred, not re-checked.

<Facts with proof: command output, log lines, table counts, file:line anchors.
Quote errors verbatim in fenced blocks.>

## 3. Current state

<Where things stand right now: what runs, what is broken, what is half-done.
Include uncommitted work and its location (branch, worktree path, stash).
`[V]`/`[?]` tags apply here too — this is the section a next agent trusts most.>

## 4. Decisions FIXED — do not re-litigate

<Rulings from the user or from evidence. One line each, with who/what decided it.>

## 5. Dead ends — tried and failed

<Hypotheses disproved and approaches abandoned, with *why*. This section is what
stops the next agent burning the same tokens. Omit only if genuinely empty.>

## 6. Open questions / blockers

<Questions only the user (or an external party) can answer. Mark which ones block
work vs which can be assumed. State the assumption you'd default to.>

## 7. Next steps, in order

1. <smallest first actionable step>
2. …

## 8. Restart prompt — paste-ready

How the work actually resumes. Everything above is reference; this is the thing someone copies.

**Dispatch**: <agent profile (e.g. `impl-dbx`, `implementer`) · model + effort · `isolation: worktree`?
· base branch, named explicitly · any `git fetch && git pull --ff-only <base>` needed first>

> **Task**: <one sentence, and the scope fence — what to do and what NOT to touch.>
>
> **Context**: read <this handoff's path> §<n>, §<n> first. <One or two lines of the load-bearing
> facts.> Do not re-derive the diagnosis.
>
> **Work**:
> 1. <file:line or path> — <change, concretely>
> 2. …
>
> **STOP and report if**: <the assumptions that, if false, mean the plan is wrong.>
>
> **Done means**: <the passing check — a command, a test, a green pipeline.>

Write this so it survives being pasted alone into a fresh session with no other context. If the
prompt only makes sense to someone who already read §1–§7, it is not finished. Name the file paths
and the base branch — a next agent that has to guess either one guesses wrong.

Omit this section only for a pure findings/analysis handoff where nothing is queued to execute.

## 9. Verification commands

```bash
# exact commands the next agent runs to confirm the state described in §3
```

## 10. Suggested skills

<Skills the next agent should invoke, and when. Name them exactly as listed.>

## 11. Gotchas

<Hard-won, non-obvious traps. Short list.>

## 12. Pointers — read these, do not re-derive

<Paths / URLs / ticket IDs for specs, plans, ADRs, PRs, prior handoffs.
Reference, never restate.>
