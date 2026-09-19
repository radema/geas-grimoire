# Dispatch prompt template — fill every {placeholder} before dispatching

GOAL: implement trail {TRAIL_ID} of story {STORY_KEY}: tickets {TICKET_KEYS_IN_ORDER}, one commit per ticket, in that order.

## Spec
Trail file: {TRAIL_FILE_PATH} (order, story constraints). One brief per ticket in the same directory:
{BRIEF_FILE_PATHS}. Read the trail file first, then the brief of the ticket you are on. The brief is
the contract — acceptance criteria and out-of-scope are binding. You have no Jira access; everything
you need is in those files. If a brief is insufficient, STOP after the tickets you completed and
report the gap instead of guessing.

## Worktree and git rules (violations void the whole run)
- First action: `cd {WORKTREE_PATH}` then `git rev-parse --show-toplevel` and
  `git rev-parse --abbrev-ref HEAD`. Toplevel must be {WORKTREE_PATH} and branch {TRAIL_BRANCH}.
  If not, STOP and report — do not fix it.
- Stay in that worktree for every command. Never touch {STORY_BRANCH}, {BASE_BRANCH}, or any other
  worktree. Never `git checkout`, `git switch`, `git merge`, `git push`, `git rebase`.
- Commit on {TRAIL_BRANCH} only: exactly one commit per ticket, message starting with the ticket key
  (`{TICKET_KEYS_IN_ORDER%% *}: <what>`), after that ticket's checks pass. No squash, no amend of an
  earlier ticket's commit.
- Do not run destructive git commands (reset, clean, stash) for any reason.

## Environment rules
- Databricks operations target the dev catalog/workspace only. Never stg or prod (hook-enforced).
- Follow the target repo's CLAUDE.md commands (`uv run` prefixes, scoped pre-commit, dbt compile).

## Verification
Per ticket, before its commit: run the checks its acceptance criteria imply (scoped tests, lint,
dbt compile). Record command + exit code. Do not report a check you did not run.

## Communication
- Style: {COMM_STYLE}
- Final report, ≤10 lines: per ticket `KEY sha — checks: <cmd> exit N`, then gaps/blockers.
  Longer detail goes to {SCRATCHPAD_PATH}; reference the path. Never paste diffs.
- You are a leaf: never dispatch subagents. If a ticket is bigger than its brief says, finish the
  tickets before it, commit them, and report "needs-split" for that ticket.
