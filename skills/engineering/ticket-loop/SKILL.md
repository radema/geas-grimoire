---
name: ticket-loop
description: Autonomously implement a triaged Jira story's ready-for-agent subtask queue as parallel trails (dependency chains) in per-trail worktrees on one story branch — route each trail to minion/implementer by complexity, cap concurrent agents, review each trail with code-reviewer (correctness + simplify + spec), merge trails into the story branch, halt at ready-for-human gates. Use whenever the user says "/ticket-loop", "run the ticket loop", "implement the triaged story", "work through the ready-for-agent queue", or names a story whose subtasks carry agent briefs and asks to implement them autonomously or under /goal. NOT for untriaged stories (run /triage first) and NOT a scheduler (it pairs with the native /goal command, which the user types).
---

# Ticket Loop

Work through a triaged Jira story's `ready-for-agent` subtasks as **trails** — dependency chains of
tickets — each built by one implementer in its own git worktree and merged into ONE story branch.
The main session is the orchestrator: the user picked its model/effort via `/model`, so never
re-delegate orchestration to another agent. Designed to run unattended under a user-typed `/goal`
in auto mode.

Invocation: `/ticket-loop <STORY-KEY> [--review medium] [--base dev] [--branch <name>] [--parallel 3]`
Defaults: `--review medium`, `--base dev`, `--parallel 3`, branch `feat/<story-key-lowercase>-<short-slug>`.

## Why this shape

- **One story branch, one PR**: `<base>` → `feat/<story>` → `feat/<story>--<trail>`. Trail branches
  are merged back with `--no-ff` and deleted; only the story branch is ever pushed. Merging into
  the base branch is human-only.
- **Trail = unit of work**: tickets linked by `Dipendenze` in a chain go to one implementer, one
  worktree, one commit per ticket, one review. Independent trails run in parallel. A ticket with
  two or more deps starts a new trail that waits for the trails it depends on.
- **Cap**: at most `max_parallel` agents (implementers + reviewers) at once — checked by
  `scripts/state.sh can-dispatch` and enforced by the PreToolUse hook
  `~/.claude/hooks/ticket_loop_cap.sh`.
- **Main session orchestrates**: subagents have no Jira MCP access and cannot answer permission
  prompts. Subagents only implement or review.
- **State file over memory**: `/goal` runs span many turns and survive resume. The state file
  (`.claude/ticket-loop/<story>.json`, schema in `assets/state-schema.json`) is the single source
  of truth — re-read it at the start of every turn.

## Phase 1 — Setup (first invocation only)

1. Fetch story + subtasks via Atlassian MCP (`searchJiraIssuesUsingJql`, include `comment`).
2. Build the queue: subtasks labeled `ready-for-agent` with `statusCategory != Done`. Each MUST
   have an `## Agent Brief` comment with `**Dipendenze:**` and `**Complessità:**` lines (see the
   triage skill's AGENT-BRIEF.md). A brief missing either line: infer deps from the text if
   explicit, else treat as none; infer complexity conservatively (S if one interface named, M
   otherwise) and say so in the report. A ready-for-agent ticket without a brief is skipped and
   flagged for `/triage`. `ready-for-human` subtasks are gates: record them; prepare artifacts
   for them later, never execute them.
3. Create the branch: `scripts/verify_branch.sh setup <base>`, then
   `git checkout -b <branch> origin/<base>`.
4. Initialize state: `scripts/state.sh init <story> <branch> <base> <review-effort> <parallel>`,
   then `scripts/state.sh add-ticket <story> <key> <deps|-> <XS|S|M|L>` per queue entry, then
   `scripts/state.sh build-trails <story>` — prints the trail table (`t1  M  deps=-  A > B > C`)
   and the `L` tickets marked `needs-split` (never dispatched; listed for `/triage`).
5. Write brief files now: `.claude/ticket-loop/briefs/<key>.md` per ticket (brief + story
   constraints) and `.claude/ticket-loop/briefs/<trail>.trail.md` per trail (ticket order, paths
   of its briefs, story constraints). Subagents cannot read Jira — these files are their spec.
6. **Print for the user and stop**: the trail table, the gates, the needs-split tickets, and a
   ready-to-paste goal line:

   ```
   /goal every trail of <STORY> is merged into <branch> with a code-reviewer verdict of ship or
   fix-then-ship recorded in .claude/ticket-loop/<STORY>.json, blocked trails and needs-split
   tickets are listed in .claude/ticket-loop/<STORY>-report.md, and that report exists — or stop
   after 40 turns
   ```

   Tell the user to switch to auto mode before pasting it — `/goal` does not change the permission
   mode. Suggest `CLAUDE_CODE_GOAL_CHECKIN_MINUTES=10` so a stuck background agent surfaces sooner.

## Phase 2 — Per-turn loop (each subsequent turn)

Read the state file first. Then, in this order:

### 2a. Collect finished agents

For each completion notification since last turn (the trail's `agent_id` is in state):

- **Implementer finished** → verify, don't trust: `scripts/verify_branch.sh guard-worktree
  <worktree> <trail-branch>` and `git log <story-branch>..<trail-branch> --oneline`. One commit per
  ticket present → `state.sh set-ticket <key> committed <sha>` each; trail `reviewing`; dispatch
  `code-reviewer` (background) with: `cd <worktree>`, diff `<story-branch>...HEAD`,
  `SPEC:` = the trail's brief paths, review effort, output cap, and the sentence "Re-run every check
  listed in the implementer's `checks:` lines yourself; do not trust the reported exit codes."
  Missing or extra commits, or a reported "needs-split" → treat as a verification failure (below).
  Also parse the final report for
  one `checks: <cmd> exit N` line per ticket: a missing line, a `checks: none run` without a stated
  reason, or a non-zero exit is a verification failure too, handled the same way (`attempts += 1`,
  same blocked rule).
- **Reviewer finished** → record `review` in state.
  - `ship` / `fix-then-ship` → `merging` → `scripts/worktree.sh merge <story> <trail>`. Exit 0 →
    trail `merged`, tickets `merged`, one short Jira comment per ticket starting with
    `> *This was generated by AI during autonomous implementation.*` (what landed, sha, checks),
    transition if applicable, `scripts/worktree.sh remove`, then dismiss the trail's implementer
    teammate now (`SendMessage` shutdown/stop) — do not leave it idle. Exit 2 (conflict) → trail `blocked`,
    reason `merge conflict`; leave the worktree for the human; no automatic resolution.
    `fix-then-ship` items: apply via `SendMessage` to the same implementer before merging when they
    are one-line; otherwise record a conscious skip in the report.
  - `needs-rework` → `attempts += 1`. Attempt 2: route the findings to the same implementer via
    `SendMessage` (context intact); if it is gone, re-dispatch; if the trail contains an `M`
    ticket, re-dispatch with `model: opus`. Attempt 3 → `blocked`, reason from the review.

**Failure rule**: two consecutive verification or review failures on the same trail → `blocked`,
stop dispatching it, write what failed into the report file. Never try a third variation.

### 2b. Fill the frontier

```
while next=$(scripts/state.sh can-dispatch <story>); do
  path=$(scripts/worktree.sh add <story> $next)          # branch feat/<story>--<next> off current story HEAD
  scripts/state.sh set-trail <story> $next worktree $path ; ... branch, agent, model, status building
  dispatch (background, anonymous) per routing table; store agent_id
done
```

Routing by trail complexity (max over its tickets):

| complexity | agent | model | note |
|---|---|---|---|
| XS | `minion` | haiku | only if every brief is an exact prescription; else treat as S |
| S, M | `implementer` | sonnet | profile default (effort high) |
| L | — | — | never dispatched: `needs-split`, listed for `/triage` |

Prompt: fill `assets/dispatch-brief-template.md` (trail file, brief paths, worktree path, trail
branch, story/base branch names, style, ≤10-line report). `can-dispatch` exits non-zero on cap
reached or empty frontier; the hook denies any dispatch that slips past the cap.

### 2c. End the turn

Print `scripts/state.sh summary <story>` (one `LOOP:` line the `/goal` evaluator reads) and stop.
`/goal` skips evaluation while background agents run and resumes when one completes — idling is
the wait; never poll. Do no git operations on the story branch while a merge is not in progress.

## Phase 3 — Finish

When the frontier is empty and `state.sh running` is 0:

1. Full-branch `code-reviewer` against `origin/<base>`, `SPEC:` = the story description.
2. Gate artifacts for each `ready-for-human` ticket into `.claude/ticket-loop/gates/<ticket>/`.
3. Write `.claude/ticket-loop/<STORY>-report.md`: per trail — tickets, shas, agent/model, attempts,
   verdict; blocked trails with reason and worktree path; needs-split tickets; gate artifacts;
   review findings applied/skipped.
4. **Stop.** Never push, merge to base, open the PR, or deploy stg/prod. Print:

   ```
   git push -u origin <branch>
   gh pr create --base <base> --title "<STORY>: <story summary>" --body-file .claude/ticket-loop/<STORY>-report.md
   ```

## Resume behavior

If `.claude/ticket-loop/<story>.json` exists, skip Phase 1: reconcile state against reality
(`git worktree list`, `git log` on trail branches, `scripts/worktree.sh list`) — a trail marked
`building` whose worktree has all its commits is `reviewing`; a trail whose worktree is gone and
whose merge commit exists is `merged`. Reality wins; fix the file, not the history. Then continue
with Phase 2. Pass `--rebuild` only to recompute trails after `/triage` changed briefs; it refuses
while any trail is `building|reviewing|merging`.
