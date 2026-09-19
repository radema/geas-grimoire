#!/usr/bin/env bash
# worktree.sh — one git worktree + branch per trail, merged back into the story branch.
# Branch layout: <base> -> feat/<story> (the only branch that becomes a PR) -> feat/<story>--<trail>.
# (git refs cannot nest under an existing branch name, so the trail suffix uses '--', not '/'.)
# Usage:
#   worktree.sh add    <story> <trail>   # create <worktree_root>/<trail> on new branch <story-branch>--<trail> off current story HEAD
#   worktree.sh merge  <story> <trail>   # from the main checkout on the story branch: merge --no-ff; conflict -> abort, exit 2
#   worktree.sh remove <story> <trail>   # remove the worktree and delete the (merged) trail branch
#   worktree.sh list   <story>
# Exit 0 ok; 1 usage/guard failure; 2 merge conflict (aborted, tree clean).
set -euo pipefail

cmd="${1:?usage: worktree.sh add|merge|remove|list <story> [trail]}"
story="${2:?missing story key}"
root="$(git rev-parse --show-toplevel)"
file="$root/.claude/ticket-loop/$story.json"
[ -f "$file" ] || { echo "no state file $file" >&2; exit 1; }
story_branch=$(jq -r '.branch' "$file")
wt_root=$(jq -r '.worktree_root // empty' "$file"); [ -n "$wt_root" ] || wt_root="$root/.claude/ticket-loop/wt"

die() { echo "WORKTREE FAIL: $*" >&2; exit 1; }
on_story() { [ "$(git -C "$root" rev-parse --abbrev-ref HEAD)" = "$story_branch" ] || die "main checkout is on '$(git -C "$root" rev-parse --abbrev-ref HEAD)', expected '$story_branch'"; }

case "$cmd" in
  add)
    trail="${3:?trail id}"; on_story
    path="$wt_root/$trail"; branch="$story_branch--$trail"
    [ ! -e "$path" ] || die "worktree path exists: $path"
    git -C "$root" rev-parse --verify --quiet "$branch" >/dev/null && die "branch exists: $branch"
    mkdir -p "$wt_root"
    git -C "$root" worktree add --quiet -b "$branch" "$path" "$story_branch"
    echo "$path"
    ;;
  merge)
    trail="${3:?trail id}"; on_story
    branch="$story_branch--$trail"
    [ -z "$(git -C "$root" status --porcelain --untracked-files=no)" ] || die "story checkout has uncommitted changes; merge refused"
    git -C "$root" rev-parse --verify --quiet "$branch" >/dev/null || die "no branch $branch"
    n=$(git -C "$root" rev-list --count "$story_branch..$branch")
    [ "$n" -gt 0 ] || die "trail $trail has no commits beyond $story_branch"
    if git -C "$root" merge --no-ff --no-edit -m "merge($story): trail $trail" "$branch" >/dev/null 2>&1; then
      echo "merged $branch ($n commits) -> $story_branch @ $(git -C "$root" rev-parse --short HEAD)"
    else
      git -C "$root" merge --abort 2>/dev/null || true
      echo "CONFLICT merging $branch into $story_branch; aborted, tree restored" >&2
      exit 2
    fi
    ;;
  remove)
    trail="${3:?trail id}"
    path="$wt_root/$trail"; branch="$story_branch--$trail"
    [ -d "$path" ] && git -C "$root" worktree remove --force "$path"
    git -C "$root" rev-parse --verify --quiet "$branch" >/dev/null && git -C "$root" branch -d "$branch" >/dev/null
    git -C "$root" worktree prune
    echo "removed $trail"
    ;;
  list)
    git -C "$root" worktree list | grep -F "$wt_root/" || echo "(no trail worktrees)"
    ;;
  *) die "unknown command '$cmd'" ;;
esac
