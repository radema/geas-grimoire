#!/usr/bin/env bash
# Deny git operations that can destroy work owned by ANOTHER agent's checkout.
#
# Why: mining 30 days of sessions (2026-07-30) found the user having to say
# "do not touch the current branch since another claude agent is working on it"
# in 4 sessions across 3 days, while `git stash` ran 42x, `git branch -D` 53x and
# `git checkout` 97x across the four active repos. The rule lived in a feedback
# memory and in prose; neither is checked at the moment the command runs.
#
# Scope is deliberately narrow — the guard is silent unless the repo has MORE THAN
# ONE worktree, i.e. unless a second checkout actually exists to collide with:
#   - `git stash`             : hides another agent's uncommitted work. Always denied.
#   - checkout/switch/branch -D naming a branch some other worktree has checked out.
# Everything else passes. `git worktree list --porcelain` is the authority, so this
# never guesses about who owns what.
#
# Uses JSON permissionDecision output (exit 0 always) — the correct blocking path.

INPUT=$(cat)
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$COMMAND" ] && exit 0
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty')
[ -z "$CWD" ] && exit 0

case "$COMMAND" in
  *"git stash"*|*"git checkout"*|*"git switch"*|*"git branch -D"*|*"git branch -d"*) ;;
  *) exit 0 ;;
esac

WT=$(git -C "$CWD" worktree list --porcelain 2>/dev/null) || exit 0
# Single checkout: no other agent's tree to damage.
[ "$(printf '%s\n' "$WT" | grep -c '^worktree ')" -gt 1 ] || exit 0

deny() {
  jq -cn --arg r "$1" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",
      permissionDecisionReason:$r}}'
  exit 0
}

case "$COMMAND" in
  *"git stash"*)
    deny "This repo has $(printf '%s\n' "$WT" | grep -c '^worktree ') worktrees, so another agent may own uncommitted work here — stashing hides it. Commit your own files by explicit path, or take an isolated checkout with \`git worktree add\`." ;;
esac

# Branch checked out elsewhere: switching moves it, deleting fails or loses it.
SELF=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null)
while IFS=$'\t' read -r wtpath ref; do
  branch=${ref#refs/heads/}
  [ "$wtpath" = "$SELF" ] && continue          # our own branch is ours to move
  case "$COMMAND" in
    *"$branch"*)
      deny "Branch \`$branch\` is checked out in another worktree ($wtpath) — another agent is working on it. Do not switch to, move, or delete it; work in your own worktree." ;;
  esac
done < <(printf '%s\n' "$WT" | awk '
  /^worktree /  { wt = substr($0, 10) }
  /^branch /    { print wt "\t" substr($0, 8) }
')

exit 0
