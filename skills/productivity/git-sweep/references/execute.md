# Execute phase — ordered recipe

Read this only after the user has approved specific refs. Run the steps in
this order: a branch cannot be deleted while a worktree still has it checked
out, and `worktree prune` must follow the removals.

Delete **one ref per command**, so a failure names the ref that failed. A
compound command over several refs that half-fails leaves an unclear state, and
in practice got re-run wholesale.

## 1. Worktrees

```bash
git -C <repo> worktree remove <path>
```

- `fatal: '<path>' is a locked working tree` → the tree was locked
  deliberately. Show the reason and stop:
  ```bash
  cat <repo>/.git/worktrees/<name>/locked 2>/dev/null || echo "(no reason recorded)"
  ```
  Only `git -C <repo> worktree unlock <path>` after the user says so.
- `contains modified or untracked files` → stop on that worktree and show what
  is in it, so the user decides whether any of it is work:
  ```bash
  git -C <path> --no-optional-locks status --porcelain | head -20
  ```
- `is not a working tree` → the directory is already gone; the registration is
  stale. Skip to prune.

## 2. Prune

Once, after all approved removals:

```bash
git -C <repo> worktree prune && git -C <repo> worktree list
```

## 3. Branches

```bash
git -C <repo> branch -d <branch>
```

- `error: the branch '<branch>' is not fully merged` → stop on that branch,
  report it, move to the next one. Two legitimate reasons to see this, and they
  need opposite responses:
  - verdict was `squash_merged`: the work *is* in the base, git just cannot
    see it through the squash. Say so, quote the `confirm_merged.sh` evidence
    line, and ask for `-D` explicitly.
  - verdict was wrong: the branch has real unmerged commits. Re-run
    `scripts/confirm_merged.sh` before doing anything else.
The one class that takes `-D` unasked: an `agent_scratch` throwaway
(`*/.claude/worktrees/agent-*`, or a `worktree-agent-*` branch) whose verdict is
`merged`.

## 4. Fast-forward the base branches

Only if the user asked for it. From the main worktree:

```bash
git -C <repo> merge --ff-only origin/<base>          # when <base> is checked out
git -C <repo> fetch origin dev:dev main:main         # when it is not
```

`fetch origin <remote>:<local>` fails if the local branch is not a
fast-forward. That is the intended guard — report it, do not force.

## After

Re-run phase 1 and show the new counts, so the user can see what is left:

```bash
bash $SW/stale_refs.sh --no-fetch --worktree-stale-days 0 | python3 $SW/apply_ignore.py
```
