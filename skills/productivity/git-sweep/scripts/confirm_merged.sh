#!/usr/bin/env bash
# confirm_merged.sh -- git-sweep phase 2: resolve the true merge state of a
# local branch, including the two cases `git merge-base --is-ancestor` alone
# gets wrong.
#
# CRITICAL: every git command here is READ-ONLY. No fetch, no checkout, no
# delete. Run stale_refs.sh first (it fetches) so origin refs are fresh.
#
# Usage:
#   confirm_merged.sh <repo-path> <branch>...
#   confirm_merged.sh <repo-path> --base origin/dev <branch>...
#
# Emits one TSV line per branch:
#   branch  verdict  base  ahead  remote  evidence
#
# Verdicts:
#   merged              ancestor of a base branch. Safe: `git branch -d`.
#   squash_merged       NOT an ancestor, but its tree is identical to a base.
#                       This is the false negative: the branch was squashed on
#                       merge so its commits never appear in the base history.
#                       Equally safe, but `git branch -d` will refuse it.
#   unmerged_local_only real commits, nothing on the remote. Deleting loses
#                       work. Report only.
#   unmerged_pushed     real commits that exist on the remote, OR ls-remote
#                       could not be reached. HARD STOP: propose a PR, never
#                       a delete. The unreachable case lands here by design --
#                       "I could not check" must never render as "safe".
#
# The `remote` column is the pushed-state evidence: origin/<b>@<sha> (live),
# `absent` (no remote branch, no tracking ref), `gone-stale-tracking-ref`
# (remote branch deleted, local refs/remotes copy not yet pruned -- any
# ahead/behind count against it is meaningless), or `unknown` (ls-remote
# failed).
set -uo pipefail

REPO="${1:-}"
if [ -z "$REPO" ] || [ ! -d "$REPO" ]; then
  echo "confirm_merged.sh: usage: confirm_merged.sh <repo-path> [--base <ref>] <branch>..." >&2
  exit 2
fi
shift

BASES=()
BRANCHES=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --base)
      shift
      BASES+=("${1:-}")
      ;;
    --base=*) BASES+=("${1#*=}") ;;
    -*)
      echo "confirm_merged.sh: unknown flag $1" >&2
      exit 2
      ;;
    *) BRANCHES+=("$1") ;;
  esac
  shift
done

g() { git -C "$REPO" --no-optional-locks "$@"; }

if [ "${#BASES[@]}" -eq 0 ]; then
  # promotion bases differ per repo (e.g. one repo promotes through dev,
  # another through stage), so checking only the default branch mislabels a
  # merged branch as unmerged.
  for cand in origin/dev origin/stage origin/main origin/master; do
    g rev-parse --verify -q "$cand" >/dev/null 2>&1 && BASES+=("$cand")
  done
fi

if [ "${#BASES[@]}" -eq 0 ]; then
  echo "confirm_merged.sh: no base branch found in $REPO" >&2
  exit 2
fi

printf 'branch\tverdict\tbase\tahead\tremote\tevidence\n'

for b in "${BRANCHES[@]}"; do
  [ -z "$b" ] && continue
  if ! g rev-parse --verify -q "refs/heads/$b" >/dev/null 2>&1; then
    printf '%s\tno_such_branch\t-\t-\t-\tno refs/heads/%s in %s\n' "$b" "$b" "$REPO"
    continue
  fi

  verdict=""
  matched=""
  for base in "${BASES[@]}"; do
    if g merge-base --is-ancestor "$b" "$base" 2>/dev/null; then
      verdict="merged"
      matched="$base"
      break
    fi
  done

  if [ -z "$verdict" ]; then
    for base in "${BASES[@]}"; do
      if g diff --quiet "$base" "$b" 2>/dev/null; then
        verdict="squash_merged"
        matched="$base"
        break
      fi
    done
  fi

  primary="${BASES[0]}"
  ahead=$(g rev-list --count "${matched:-$primary}..$b" 2>/dev/null)
  ahead="${ahead:-0}"

  # ls-remote is the only authority on whether the remote branch still
  # exists: refs/remotes/origin/<b> survives a remote-side delete until
  # someone prunes, so a local tracking ref proves nothing. Its exit status
  # matters as much as its output -- offline or unauthenticated, it prints
  # nothing and that must NOT read as "branch absent, safe to delete".
  ls_out=$(g ls-remote --heads origin "$b" 2>/dev/null)
  ls_rc=$?
  remote_sha=$(printf '%s\n' "$ls_out" | awk 'NF {print $1; exit}')

  has_tracking=0
  g rev-parse --verify -q "refs/remotes/origin/$b" >/dev/null 2>&1 && has_tracking=1

  if [ "$ls_rc" -ne 0 ]; then
    remote="unknown"
  elif [ -n "$remote_sha" ]; then
    remote="origin/$b@${remote_sha:0:8}"
  elif [ "$has_tracking" = "1" ]; then
    remote="gone-stale-tracking-ref"
  else
    remote="absent"
  fi

  if [ -z "$verdict" ]; then
    if [ "$ls_rc" -ne 0 ]; then
      # Cannot reach the remote. Assume the riskier class on purpose.
      verdict="unmerged_pushed"
    elif [ -n "$remote_sha" ]; then
      verdict="unmerged_pushed"
    else
      verdict="unmerged_local_only"
    fi
    matched="$primary"
  fi

  case "$verdict" in
    merged)
      evidence="ancestor of $matched"
      ;;
    squash_merged)
      evidence="tree identical to $matched, $ahead commit(s) absent from its history"
      ;;
    unmerged_pushed|unmerged_local_only)
      divergence=""
      if [ "$has_tracking" = "1" ]; then
        lr=$(g rev-list --left-right --count "origin/$b...$b" 2>/dev/null)
        if [ -n "$lr" ]; then
          divergence="; origin/local behind/ahead = $(echo "$lr" | tr '\t' '/')"
          [ "$remote" = "gone-stale-tracking-ref" ] && divergence="$divergence (against a STALE tracking ref, remote branch is gone)"
          [ "$remote" = "unknown" ] && divergence="$divergence (remote unreachable, tracking ref may be stale)"
        fi
      fi
      [ "$remote" = "unknown" ] && divergence="$divergence; ls-remote FAILED, treated as pushed on purpose"
      sample=$(g log --oneline "$matched..$b" 2>/dev/null | head -3 | tr '\n' ';' | sed 's/;$//')
      evidence="$ahead commit(s) not in $matched$divergence; $sample"
      ;;
  esac

  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$b" "$verdict" "$matched" "$ahead" "$remote" "$evidence"
done
