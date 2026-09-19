#!/usr/bin/env bash
# stale_refs.sh -- git-sweep phase 1: diagnose stale local branches and
# worktrees, and record the evidence + a proposed cleanup command for each.
#
# Twin copy: ~/.claude/skills/morning-brief/collectors/stale_refs.sh
# The classification ladder (protected set, reasons, worktree candidacy, JSON
# shape) is deliberately identical in both. Change one, change the other, or
# the daily brief and this skill will disagree about the same repo.
#
# CRITICAL: every git command in this script is READ-ONLY except the
# `git fetch --prune` in fetch_repo (suppressed by --no-fetch). No checkout,
# no pull, no merge, no stash pop/apply, no reset, no clean, no `branch -d`/
# `-D`, no `worktree remove`, ever. `--no-optional-locks` is passed on every
# other git invocation so this script cannot interfere with another Claude
# Code session's git operations in the same repo. Any `git branch -d`/`-D` or
# `git worktree remove` text that appears below is a proposal string emitted
# as JSON output, never executed. Do not add any other write/mutating git
# command here.
#
# Usage:
#   stale_refs.sh [--all | <repo-path>...] [--no-fetch] [--stale-days N]
#                 [--worktree-stale-days N]
#
# With no repo argument, sweeps the toplevel of the repo containing $PWD.
# --all sweeps the four watched repos. --no-fetch skips the fetch, at the cost
# of stale [gone] tracking.
set -uo pipefail

# --all's repo list, in priority order:
#   1. $GIT_SWEEP_REPOS, colon-separated absolute paths
#   2. config/repos.txt next to this script, one path per line (# comments ok)
#   3. fallback: every git repo directly under this skill's own repo's parent
#      directory (e.g. /root, if this skill lives in /root/geas-grimoire)
REPOS_CONFIG="$(dirname "${BASH_SOURCE[0]}")/../config/repos.txt"
if [ -n "${GIT_SWEEP_REPOS:-}" ]; then
  IFS=':' read -ra ALL_REPOS <<< "$GIT_SWEEP_REPOS"
elif [ -f "$REPOS_CONFIG" ]; then
  mapfile -t ALL_REPOS < <(grep -vE '^\s*(#|$)' "$REPOS_CONFIG")
else
  SKILL_REPO_ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null || echo /root)"
  PARENT_DIR="$(dirname "$SKILL_REPO_ROOT")"
  mapfile -t ALL_REPOS < <(find "$PARENT_DIR" -mindepth 1 -maxdepth 1 -type d -exec test -e "{}/.git" \; -print)
fi

STALE_DAYS=14
WT_STALE_DAYS=""
DO_FETCH=1
WANT_ALL=0
REPOS=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --all) WANT_ALL=1 ;;
    --no-fetch) DO_FETCH=0 ;;
    --stale-days)
      shift
      STALE_DAYS="${1:-14}"
      ;;
    --stale-days=*) STALE_DAYS="${1#*=}" ;;
    --worktree-stale-days)
      shift
      WT_STALE_DAYS="${1:-0}"
      ;;
    --worktree-stale-days=*) WT_STALE_DAYS="${1#*=}" ;;
    -*)
      echo "stale_refs.sh: unknown flag $1" >&2
      exit 2
      ;;
    *) REPOS+=("$1") ;;
  esac
  shift
done

if [ "$WANT_ALL" = "1" ]; then
  REPOS=("${ALL_REPOS[@]}")
elif [ "${#REPOS[@]}" -eq 0 ]; then
  cwd_toplevel=$(git --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
  if [ -z "$cwd_toplevel" ]; then
    echo "stale_refs.sh: $PWD is not inside a git repo; pass a repo path or --all" >&2
    exit 2
  fi
  REPOS=("$cwd_toplevel")
fi

# Worktree candidacy has its own age floor. The morning-brief twin has no
# such flag and always uses STALE_DAYS, to keep the daily brief quiet; an
# interactive sweep wants --worktree-stale-days 0, because an agent scratch
# worktree on an already-merged branch is the single most common thing the
# user asks about and it is usually hours old, not weeks.
[ -z "$WT_STALE_DAYS" ] && WT_STALE_DAYS="$STALE_DAYS"

fetch_repo() {
  # The one non-read-only command in this script. Accurate [gone] tracking
  # needs it: without a fetch, a branch whose remote was deleted still looks
  # alive. The morning-brief twin omits this because git_state.sh fetches
  # first in the same bundle run.
  [ "$DO_FETCH" = "1" ] || return 0
  git -C "$1" fetch --prune --quiet 2>/dev/null || true
}

HAVE_JQ=0
if command -v jq >/dev/null 2>&1; then
  HAVE_JQ=1
fi

json_escape() {
  # Escape a string for embedding in a JSON string literal. Pure bash: a git
  # skill must not depend on uv/python being on PATH (the morning-brief twin
  # shells out to uv here because its whole pipeline already requires it).
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\n'/\\n}"
  printf '%s' "$s"
}

json_bool() {
  # $1: "1"/"0" -> "true"/"false"
  [ "$1" = "1" ] && echo "true" || echo "false"
}

now_epoch=$(date +%s)

age_days_from_iso() {
  # $1: ISO-8601 date string -> age in whole days from now, 0 if unparsable.
  local epoch
  epoch=$(date -d "$1" +%s 2>/dev/null) || { echo 0; return; }
  echo $(( (now_epoch - epoch) / 86400 ))
}

repo_entries=()

for R in "${REPOS[@]}"; do
  if [ ! -d "$R" ]; then
    if [ "$HAVE_JQ" = "1" ]; then
      entry=$(jq -n --arg repo "$R" --arg error "repo path does not exist" \
        '{repo: $repo, default_branch: "", stale_branches: [], stale_worktrees: [],
          counts: {branches_total: 0, worktrees_total: 0}, error: $error}')
    else
      entry="{\"repo\": \"$(json_escape "$R")\", \"default_branch\": \"\", \"stale_branches\": [], \"stale_worktrees\": [], \"counts\": {\"branches_total\": 0, \"worktrees_total\": 0}, \"error\": \"repo path does not exist\"}"
    fi
    repo_entries+=("$entry")
    continue
  fi

  err=""

  fetch_repo "$R"

  # --- default branch + protected set ---
  default_branch=$(git -C "$R" --no-optional-locks symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)
  default_branch="${default_branch#origin/}"
  if [ -z "$default_branch" ]; then
    # origin/HEAD is unset on many clones. Probing beats assuming "main":
    # assuming it in a master-based repo leaves merged_base pointing at a ref
    # that does not exist, every branch then looks unmerged, and the sweep
    # reports clean while merged branches sit there.
    for cand in main master dev stage; do
      if git -C "$R" --no-optional-locks rev-parse --verify -q "refs/remotes/origin/$cand" >/dev/null 2>&1 \
        || git -C "$R" --no-optional-locks rev-parse --verify -q "refs/heads/$cand" >/dev/null 2>&1; then
        default_branch="$cand"
        break
      fi
    done
  fi
  if [ -z "$default_branch" ]; then
    default_branch="main"
  fi

  protected_set=("$default_branch" "main" "master" "dev" "stage")
  is_protected() {
    local name="$1" p
    for p in "${protected_set[@]}"; do
      [ "$name" = "$p" ] && return 0
    done
    return 1
  }

  # --- merged set, relative to origin/<default> if it exists, else local <default> ---
  merged_base="origin/$default_branch"
  if ! git -C "$R" --no-optional-locks rev-parse --verify -q "$merged_base" >/dev/null 2>&1; then
    merged_base="$default_branch"
  fi
  merged_raw=$(git -C "$R" --no-optional-locks branch --format='%(refname:short)' --merged "$merged_base" 2>/dev/null)
  declare -A is_merged=()
  while IFS= read -r m; do
    [ -z "$m" ] && continue
    is_merged["$m"]=1
  done <<< "$merged_raw"

  # --- branches: gather, classify, build stale_branches ---
  branches_raw=$(git -C "$R" --no-optional-locks for-each-ref refs/heads \
    --format='%(refname:short)|%(committerdate:iso-strict)|%(upstream:short)|%(upstream:track)|%(worktreepath)' 2>/dev/null)

  declare -A branch_age=()
  declare -A branch_reason=()
  branches_total=0
  stale_branch_entries=()

  while IFS='|' read -r name last_commit upstream track wt_path; do
    [ -z "$name" ] && continue
    branches_total=$((branches_total + 1))

    age_days=$(age_days_from_iso "$last_commit")
    branch_age["$name"]="$age_days"

    if is_protected "$name"; then
      continue
    fi
    # current branch of the main worktree is excluded from deletion candidacy
    if [ "$wt_path" = "$R" ]; then
      continue
    fi

    reason=""
    if [ -n "${is_merged[$name]+x}" ]; then
      reason="merged"
    elif [ "$track" = "[gone]" ]; then
      reason="gone"
    elif [ -z "$upstream" ] && [ "$age_days" -ge "$STALE_DAYS" ]; then
      reason="old_no_upstream"
    fi

    [ -z "$reason" ] && continue
    branch_reason["$name"]="$reason"

    ahead=$(git -C "$R" --no-optional-locks rev-list --count "${merged_base}..${name}" 2>/dev/null)
    ahead="${ahead:-0}"

    if [ "$HAVE_JQ" = "1" ]; then
      be=$(jq -n \
        --arg name "$name" --arg reason "$reason" --argjson age_days "$age_days" \
        --arg last_commit "$last_commit" --arg upstream_track "$track" \
        --arg worktree_path "$wt_path" --argjson ahead "$ahead" \
        '{name: $name, reason: $reason, age_days: $age_days, last_commit: $last_commit,
          upstream_track: $upstream_track, worktree_path: $worktree_path, ahead: $ahead}')
    else
      be="{\"name\": \"$(json_escape "$name")\", \"reason\": \"$(json_escape "$reason")\", \"age_days\": $age_days, \"last_commit\": \"$(json_escape "$last_commit")\", \"upstream_track\": \"$(json_escape "$track")\", \"worktree_path\": \"$(json_escape "$wt_path")\", \"ahead\": $ahead}"
    fi
    stale_branch_entries+=("$be")
  done <<< "$branches_raw"

  # --- worktrees: parse porcelain, classify, build stale_worktrees ---
  worktrees_raw=$(git -C "$R" --no-optional-locks worktree list --porcelain 2>/dev/null)

  wt_paths=()
  wt_branches=()
  wt_locked=()
  wt_lockreason=()
  wt_prunable=()

  cur_path="" cur_branch="" cur_locked=0 cur_lockreason="" cur_prunable=0

  flush_wt() {
    [ -z "$cur_path" ] && return
    wt_paths+=("$cur_path")
    wt_branches+=("$cur_branch")
    wt_locked+=("$cur_locked")
    wt_lockreason+=("$cur_lockreason")
    wt_prunable+=("$cur_prunable")
  }

  while IFS= read -r line; do
    if [ -z "$line" ]; then
      flush_wt
      cur_path="" cur_branch="" cur_locked=0 cur_lockreason="" cur_prunable=0
      continue
    fi
    case "$line" in
      "worktree "*) cur_path="${line#worktree }" ;;
      "branch refs/heads/"*) cur_branch="${line#branch refs/heads/}" ;;
      "locked") cur_locked=1 ;;
      "locked "*) cur_locked=1; cur_lockreason="${line#locked }" ;;
      "prunable") cur_prunable=1 ;;
      "prunable "*) cur_prunable=1 ;;
    esac
  done <<< "$worktrees_raw"
  flush_wt

  worktrees_total=${#wt_paths[@]}
  stale_worktree_entries=()

  for i in "${!wt_paths[@]}"; do
    [ "$i" -eq 0 ] && continue  # main worktree, never a candidate

    path="${wt_paths[$i]}"
    branch="${wt_branches[$i]}"
    locked="${wt_locked[$i]}"
    prunable="${wt_prunable[$i]}"

    dirty_count=0
    if [ -d "$path" ]; then
      dirty_count=$(git -C "$path" --no-optional-locks status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    fi

    agent_scratch=0
    case "$path" in
      */.claude/worktrees/agent-*) agent_scratch=1 ;;
    esac

    wt_age=0
    if [ -n "$branch" ] && [ -n "${branch_age[$branch]+x}" ]; then
      wt_age="${branch_age[$branch]}"
    elif [ -d "$path" ]; then
      wt_commit_date=$(git -C "$path" --no-optional-locks log -1 --format=%cI 2>/dev/null)
      [ -n "$wt_commit_date" ] && wt_age=$(age_days_from_iso "$wt_commit_date")
    fi

    branch_reason_val="${branch_reason[$branch]:-}"

    # A worktree on a merged/gone branch is only a candidate once it is also
    # old: a fresh worktree whose branch just merged is usually still in use.
    is_candidate=0
    if [ -n "$branch_reason_val" ] && [ "$wt_age" -ge "$WT_STALE_DAYS" ]; then
      is_candidate=1
    elif [ "$prunable" = "1" ]; then
      is_candidate=1
    elif [ "$agent_scratch" = "1" ] && [ "$wt_age" -ge "$WT_STALE_DAYS" ]; then
      is_candidate=1
    fi

    [ "$is_candidate" = "0" ] && continue

    blocked=""
    if [ "$locked" = "1" ]; then
      blocked="locked"
    elif [ "$dirty_count" -gt 0 ]; then
      blocked="dirty"
    fi

    if [ "$HAVE_JQ" = "1" ]; then
      blocked_json="null"
      [ -n "$blocked" ] && blocked_json="\"$blocked\""
      we=$(jq -n \
        --arg path "$path" --arg branch "$branch" --arg reason "orphan_worktree" \
        --argjson age_days "$wt_age" --argjson locked "$(json_bool "$locked")" \
        --argjson dirty_count "$dirty_count" --argjson prunable "$(json_bool "$prunable")" \
        --argjson agent_scratch "$(json_bool "$agent_scratch")" --argjson blocked "$blocked_json" \
        '{path: $path, branch: $branch, reason: $reason, age_days: $age_days, locked: $locked,
          dirty_count: $dirty_count, prunable: $prunable, agent_scratch: $agent_scratch, blocked: $blocked}')
    else
      blocked_json="null"
      [ -n "$blocked" ] && blocked_json="\"$(json_escape "$blocked")\""
      we="{\"path\": \"$(json_escape "$path")\", \"branch\": \"$(json_escape "$branch")\", \"reason\": \"orphan_worktree\", \"age_days\": $wt_age, \"locked\": $(json_bool "$locked"), \"dirty_count\": $dirty_count, \"prunable\": $(json_bool "$prunable"), \"agent_scratch\": $(json_bool "$agent_scratch"), \"blocked\": $blocked_json}"
    fi
    stale_worktree_entries+=("$we")
  done

  # --- assemble repo entry ---
  if [ "$HAVE_JQ" = "1" ]; then
    stale_branches_json=$(printf '%s\n' "${stale_branch_entries[@]:-}" | jq -s 'map(select(. != null))')
    stale_worktrees_json=$(printf '%s\n' "${stale_worktree_entries[@]:-}" | jq -s 'map(select(. != null))')
    entry=$(jq -n \
      --arg repo "$R" --arg default_branch "$default_branch" \
      --argjson stale_branches "$stale_branches_json" \
      --argjson stale_worktrees "$stale_worktrees_json" \
      --argjson branches_total "$branches_total" --argjson worktrees_total "$worktrees_total" \
      --arg error "$err" \
      '{repo: $repo, default_branch: $default_branch, stale_branches: $stale_branches,
        stale_worktrees: $stale_worktrees,
        counts: {branches_total: $branches_total, worktrees_total: $worktrees_total}} +
       (if $error == "" then {} else {error: $error} end)'
    )
  else
    stale_branches_join=$(IFS=,; echo "${stale_branch_entries[*]:-}")
    stale_worktrees_join=$(IFS=,; echo "${stale_worktree_entries[*]:-}")
    error_field=""
    if [ -n "$err" ]; then
      error_field=", \"error\": \"$(json_escape "$err")\""
    fi
    entry="{\"repo\": \"$(json_escape "$R")\", \"default_branch\": \"$(json_escape "$default_branch")\", \"stale_branches\": [$stale_branches_join], \"stale_worktrees\": [$stale_worktrees_join], \"counts\": {\"branches_total\": $branches_total, \"worktrees_total\": $worktrees_total}${error_field}}"
  fi

  repo_entries+=("$entry")

  unset is_merged branch_age branch_reason is_protected flush_wt
done

if [ "$HAVE_JQ" = "1" ]; then
  printf '%s\n' "${repo_entries[@]}" | jq -s '{repos: .}'
else
  joined=$(IFS=,; echo "${repo_entries[*]}")
  echo "{\"repos\": [$joined]}"
fi
