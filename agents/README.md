# Agents

Reusable Claude Code subagent definitions. Drop a file into `~/.claude/agents/` (user scope) or a repo's `.claude/agents/` (project scope) to use it.

Precedence note: for **agents**, project scope overrides user scope (a repo's copy wins inside that repo). For **skills** it's the opposite (personal/user overrides project).

| Agent | Role | Edits files? | Model | maxTurns |
|---|---|---|---|---|
| `scout` | Cheap read-only locator for known symbols/patterns; returns a `path:line` table, no code, ≤20 lines. | no | haiku | 15 |
| `minion` | Trivial mechanical executor (moves, renames, one-liners, doc updates); anonymous subagent, no git. | yes | haiku | 15 |
| `implementer` | Executes an already-decided change in any repo (Databricks/dbt, frontend, general); domain hints point at the repo's own docs. `model: opus` only for hard debugging. Commits to a branch in an isolated worktree. | yes | sonnet, effort high | 60 |
| `code-reviewer` | Read-only three-axis review: Correctness (runs tests, PASS/FAIL), Simplify (absorbed code-simplifier: overengineering, duplication, missed reuse, inefficiency), Spec (diff vs brief/spec, pass `SPEC: <path>`). Axes reported separately, ≤25 lines. Edit/Write removed; `hooks/deny_bash_writes.sh` denies writing Bash. | no (enforced) | opus | 25 |
| `speckit-cleanup-runner` | Thin dispatcher for `/speckit-cleanup-run` in any `.specify/`-initialized repo. | via skill | haiku | — |
| `speckit-reconcile-runner` | Thin dispatcher for `/speckit-reconcile-run`. | via skill | haiku | — |
| `speckit-verify-runner` | Thin dispatcher for `/speckit-verify-run` (read-only gate). | via skill | haiku | — |

Retired 2026-09-10 (kept under `retired/` for reference, not installed): `orchestrator` (1 dispatch in 5,589 sessions; the main thread + ticket-loop orchestrate), `impl-dbx` and `impl-fe` (merged into `implementer`; their domain briefings duplicated the repos' own CLAUDE.md / docs/memory), `code-simplifier` (its axis moved into `code-reviewer`).

Hooks these agents rely on live in `../hooks/`: `deny_bash_writes.sh` (referenced from reviewer frontmatter), `guard_push.sh` (force-push / protected-branch / prod-stg bundle guard, wired in settings.json), `require_dispatch_cap.sh` (warns on missing output cap or missing `model:`), `cap_nested_dispatch.sh` (denies `Agent` inside any subagent), `ticket_loop_cap.sh` (denies a ticket-loop dispatch past `max_parallel`). Install by copying to `~/.claude/hooks/`; settings.json wiring is documented in each script header and is not versioned here.

The three `speckit-*-runner` agents are repo-agnostic generalizations of project-scoped runners; they stop if the current repo has no `.specify/`.
