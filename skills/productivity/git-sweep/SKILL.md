---
name: git-sweep
description: >-
  Sweep a repo's git residue — stale local worktrees and stale local branches —
  deciding which are safe to delete and then deleting the ones the user names.
  Use when the user asks which local branches or worktrees are stale, merged, or
  safe to delete, asks to clean up / prune / remove them, or asks whether a
  branch is merged relative to dev, stage or main. Reports a verdict table and
  halts before touching anything. Not for ordinary git work (committing, PRs,
  rebasing, creating worktrees) or Claude Code config cleanup (spring-cleaning).
allowed-tools: Bash, Read, AskUserQuestion
---

# git-sweep

A repo accumulates **residue**: branches whose commits are already in the base,
worktrees whose agent finished weeks ago. Residue can go. Everything else is
**work** — commits that exist nowhere else — and work survives the sweep
untouched. Sorting one from the other is the whole job, and getting it wrong in
the direction of "delete" is unrecoverable.

The sort is in the scripts, not in your head. Hand-rolling a `for-each-ref`
classification loop is the habit this skill replaces: it was retyped from
scratch, slightly differently, in every session that led to this skill.

**Paths.** The cwd is the target repo, not the skill directory, so invoke the
scripts by absolute path — written `$SW` below:

```bash
SW=~/.claude/skills/git-sweep/scripts
```

## Phase 1 — Inventory

```bash
bash $SW/stale_refs.sh [--all | <repo-path>...] [--no-fetch] [--worktree-stale-days 0] \
  | python3 $SW/apply_ignore.py
```

- No repo argument = the repo containing the cwd. `--all` = the repos listed in
  `config/repos.txt` (or `$GIT_SWEEP_REPOS`, colon-separated), falling back to
  every git repo found next to this skill's own repo.
- Pass `--worktree-stale-days 0` for an interactive sweep. The 14-day default
  hides the most common case: an agent scratch worktree on an already-merged
  branch, hours old.
- It fetches `--prune` per repo. Use `--no-fetch` when the user is mid-deploy or
  offline, and then say in the report that `[gone]` tracking may be stale.
- `apply_ignore.py` drops deliberately-kept refs and names them on stderr. Show
  that line whenever it drops something, so a suppressed ref stays visible.

Output per repo: `stale_branches[]` with `reason` = `merged` / `gone` /
`old_no_upstream`, and `stale_worktrees[]` with `blocked` = `locked` / `dirty` /
null. Protected refs — `main`, `master`, `dev`, `stage`, the repo default, and
the branch checked out in the main worktree — never appear.

**Done when** every candidate is a named ref in hand. Candidates are proposals
at this point, not verdicts.

## Phase 2 — Confirm

```bash
bash $SW/confirm_merged.sh <repo-path> <branch>...
```

`git merge-base --is-ancestor` returns non-zero for a squash-merged branch, so
on its own it reports work that is already in the base as unmerged. This phase
exists to catch that, and two other states that look like each other:

| verdict | means | pushed-state column |
| --- | --- | --- |
| `merged` | ancestor of a base | any |
| `squash_merged` | tree identical to a base, commits absent from its history | any |
| `unmerged_local_only` | real commits, no remote copy | `absent` |
| `unmerged_pushed` | real commits on the remote, **or** the remote could not be reached | `origin/<b>@<sha>` or `unknown` |

The script checks `origin/dev`, `origin/stage`, `origin/main`, `origin/master`
in order, because promotion bases differ per repo (`repo-a` → `dev`,
`repo-b` → `stage`).

- `unmerged_pushed` and `unmerged_local_only` are work. Report them and offer to
  open a PR; a delete proposal for either is the failure this skill guards
  against.
- `remote: unknown` means `ls-remote` failed, so the branch sits in the riskier
  class deliberately — "could not check" is not "safe".
- `remote: gone-stale-tracking-ref` means the remote branch is deleted and the
  local `refs/remotes` copy is stale, which makes any ahead/behind count against
  it meaningless. Quote the state, not the count.

**Done when** every candidate branch from phase 1 has a verdict line. A
candidate with no verdict is unreviewed, not residue.

## Phase 3 — Report, then halt

Phases 1 and 2 are **read-only**, including for an obviously-dead agent
worktree: it costs one round trip to confirm and cannot be undone if the guess
was wrong.

Lead with the counts, then one table covering worktrees and branches together:

| ref | kind | verdict | evidence | proposed | blocked by |
| --- | ---- | ------- | -------- | -------- | ---------- |

Then ask which refs to act on and **stop**. An unanswered question ends the run
at the report. A clean sweep is one line and a stop.

Two cases belong in their own sentence rather than a table row, because both
read as residue and are not:

- work (`unmerged_pushed`, `unmerged_local_only`);
- a `merged` worktree only hours old — it may belong to a **running** agent.

## Phase 4 — Execute (after explicit approval)

Follow `~/.claude/skills/git-sweep/references/execute.md` in order: worktrees,
prune, branches, base fast-forward. It carries the recovery path for every git
error this hits in practice.

Approval covers the refs the user named and nothing else. "All of them" means
everything in the report, nothing discovered afterwards.

Two properties worth preserving deliberately, because each one already caught a
real mistake:

- `git branch -d` refuses to delete unmerged commits. Let it refuse: stop on
  that branch and report. `-D` is for one class only — an `agent_scratch`
  throwaway whose verdict is `merged`.
- A dirty or locked worktree stays where it is. Show what is inside it and ask;
  `--force` and `unlock` are the user's call, not yours.

Remote branches are outside a local sweep. `git push origin --delete` needs its
own confirmation, branch by named branch.

## Notes

- `$SW/stale_refs.sh` is a deliberate twin of
  `~/.claude/skills/morning-brief/collectors/stale_refs.sh` — same
  classification ladder, same JSON. Change one, change both, or the daily brief
  and this skill will disagree about the same repo.
- To silence a ref permanently, add a rule to
  `~/.claude/skills/git-sweep/config/ignore.txt`. `apply_ignore.py` also reads
  the morning brief's rule file, so a ref silenced there stays silent here.
- The skill is reachable through a symlink that lives outside this repo and is
  therefore not versioned with it. On a fresh box:
  `ln -s /root/geas-grimoire/skills/productivity/git-sweep ~/.claude/skills/git-sweep`.
