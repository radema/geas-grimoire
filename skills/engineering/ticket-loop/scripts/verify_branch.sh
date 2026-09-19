#!/usr/bin/env bash
# verify_branch.sh — deterministic git guards for the ticket-loop skill.
# Usage:
#   verify_branch.sh setup <base>            pre-branch-creation checks (fetch, clean tree)
#   verify_branch.sh guard <base> <branch>   pre-dispatch / pre-commit checks
#   verify_branch.sh guard-worktree <path> <trail-branch>   worktree is at <path>, on <trail-branch>, no merge/rebase in progress
# Exit 0 = safe to proceed; non-zero = STOP the loop and report the printed reason.
set -euo pipefail

mode="${1:?usage: verify_branch.sh setup <base> | guard <base> <branch>}"
base="${2:?missing base branch}"

die() { echo "GUARD FAIL: $*" >&2; exit 1; }

case "$mode" in
  setup)
    git fetch origin --quiet || die "git fetch origin failed"
    [ -z "$(git status --porcelain)" ] || die "working tree not clean; commit or stash before creating the story branch"
    git rev-parse --verify "origin/$base" >/dev/null 2>&1 || die "origin/$base does not exist"
    echo "OK: tree clean, origin/$base at $(git rev-parse --short "origin/$base")"
    ;;
  guard)
    git fetch origin --quiet || die "git fetch origin failed"
    branch="${3:?missing branch name}"
    current="$(git rev-parse --abbrev-ref HEAD)"
    [ "$current" = "$branch" ] || die "on '$current', expected '$branch' — a subagent may have moved HEAD"
    git merge-base --is-ancestor "origin/$base" HEAD \
      || die "origin/$base is not an ancestor of HEAD — branch was not based off fresh $base"
    # Uncommitted changes are expected before a commit; untracked+modified is fine.
    # What is NOT fine: an in-progress merge/rebase.
    for f in MERGE_HEAD REBASE_HEAD; do
      [ ! -f "$(git rev-parse --git-dir)/$f" ] || die "in-progress $f state detected"
    done
    echo "OK: on $branch, ancestry verified against origin/$base"
    ;;
  guard-worktree)
    path="$base"; tbranch="${3:?missing trail branch}"
    [ -d "$path" ] || die "worktree path missing: $path"
    top="$(git -C "$path" rev-parse --show-toplevel 2>/dev/null)" || die "not a git worktree: $path"
    [ "$top" = "$(cd "$path" && pwd -P)" ] || die "$path is not a worktree root (toplevel is $top)"
    current="$(git -C "$path" rev-parse --abbrev-ref HEAD)"
    [ "$current" = "$tbranch" ] || die "worktree on '$current', expected '$tbranch' — the implementer moved HEAD"
    for f in MERGE_HEAD REBASE_HEAD; do
      [ ! -f "$(git -C "$path" rev-parse --git-dir)/$f" ] || die "in-progress $f state in $path"
    done
    echo "OK: worktree $path on $tbranch"
    ;;
  *)
    die "unknown mode '$mode'"
    ;;
esac
