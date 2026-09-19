#!/usr/bin/env bash
# stale_refs.sh -- Stage-1 collector: diagnoses stale local branches and
# worktrees, and records the evidence + a proposed cleanup command for each.
#
# CRITICAL: every git command in this script is READ-ONLY.
# No checkout, no pull, no merge, no stash pop/apply, no reset, no clean, no
# `branch -d`/`-D`, no `worktree remove`, ever. `--no-optional-locks` is
# passed on every git invocation so this script cannot interfere with
# another Claude Code session's git operations in the same repo. Any
# `git branch -d`/`-D` or `git worktree remove` text that appears below is
# a proposal string emitted as JSON output, never executed. Do not add any
# write/mutating git command here.
#
# --no-fetch is accepted for CLI parity with git_state.sh but is a no-op:
# this script never fetches. git_state.sh already fetches with --prune in
# the same bundle run, so origin refs and [gone] tracking are fresh.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Repositories this collector watches -- absolute paths, one per line, from
# `config/repos.txt` or the MORNING_BRIEF_REPOS environment variable
# (comma-separated). With neither, every git repository directly under $HOME.
REPOS=()
if [ -n "${MORNING_BRIEF_REPOS:-}" ]; then
  IFS=',' read -r -a REPOS <<< "$MORNING_BRIEF_REPOS"
elif [ -f "$SCRIPT_DIR/../config/repos.txt" ]; then
  while IFS= read -r LINE || [ -n "$LINE" ]; do
    LINE="${LINE%%#*}"
    LINE="${LINE#"${LINE%%[![:space:]]*}"}"
    LINE="${LINE%"${LINE##*[![:space:]]}"}"
    [ -n "$LINE" ] && REPOS+=("$LINE")
  done < "$SCRIPT_DIR/../config/repos.txt"
else
  for D in "$HOME"/*/; do
    [ -d "$D/.git" ] && REPOS+=("${D%/}")
  done
fi

STALE_DAYS=14

for arg in "$@"; do
  if [ "$arg" = "--no-fetch" ]; then
    : # no-op, accepted for parity with git_state.sh
  fi
done

HAVE_JQ=0
if command -v jq >/dev/null 2>&1; then
  HAVE_JQ=1
fi

json_escape() {
  # Escape a string for embedding in a JSON string literal.
  uv run python -c 'import json,sys; print(json.dumps(sys.argv[1])[1:-1])' "$1"
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
    if [ -n "$branch_reason_val" ] && [ "$wt_age" -ge "$STALE_DAYS" ]; then
      is_candidate=1
    elif [ "$prunable" = "1" ]; then
      is_candidate=1
    elif [ "$agent_scratch" = "1" ] && [ "$wt_age" -ge "$STALE_DAYS" ]; then
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
