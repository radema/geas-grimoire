#!/usr/bin/env bash
# git_state.sh -- Stage-1 collector for local git repo state.
#
# CRITICAL: every git command in this script is READ-ONLY.
# No checkout, no pull, no merge, no stash pop/apply, no reset, no clean, ever.
# `--no-optional-locks` is passed on every git invocation so this script
# cannot interfere with another Claude Code session's git operations in the
# same repo. Do not add any write/mutating git command here.
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

# Window for `recent_commits`: the day the last brief ran, exported by run.sh.
# Without it the window was a fixed '1 day ago', so every skipped day lost the
# record of what was done.
SINCE="${MORNING_BRIEF_SINCE:-1 day ago}"

NO_FETCH=0
for arg in "$@"; do
  if [ "$arg" = "--no-fetch" ]; then
    NO_FETCH=1
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

entries=()

for R in "${REPOS[@]}"; do
  if [ ! -d "$R" ]; then
    if [ "$HAVE_JQ" = "1" ]; then
      entry=$(jq -n --arg repo "$R" --arg error "repo path does not exist" \
        '{repo: $repo, error: $error}')
    else
      entry="{\"repo\": \"$(json_escape "$R")\", \"error\": \"repo path does not exist\"}"
    fi
    entries+=("$entry")
    continue
  fi

  err=""

  if [ "$NO_FETCH" != "1" ]; then
    git -C "$R" --no-optional-locks fetch --prune --quiet 2>/dev/null || err="fetch failed"
  fi

  branch=$(git -C "$R" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -z "$branch" ]; then
    err="${err:+$err; }rev-parse failed"
  fi

  dirty_count=$(git -C "$R" --no-optional-locks status --porcelain=v1 2>/dev/null | wc -l | tr -d ' ')
  # Current branch only, against its own upstream. Using --branches --not
  # --remotes counted every local branch (worktrees included) and the brief
  # then printed that total next to the checked-out branch, which attributed
  # another branch's work to this one. An upstream that is missing or [gone]
  # (remote branch merged and deleted) yields 0, not a phantom count; other
  # branches with unpushed work are reported per-branch from `branches` below.
  unpushed_commits=$(git -C "$R" --no-optional-locks rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
  stash_count=$(git -C "$R" --no-optional-locks stash list 2>/dev/null | wc -l | tr -d ' ')

  recent_raw=$(git -C "$R" --no-optional-locks log --all --since="$SINCE" --pretty='%h|%s|%an|%ad' --date=short 2>/dev/null)
  branches_raw=$(git -C "$R" --no-optional-locks for-each-ref refs/heads --format='%(refname:short)|%(committerdate:relative)|%(upstream:track)' 2>/dev/null)

  recent_commits=()
  while IFS='|' read -r sha subject author cdate; do
    [ -z "$sha" ] && continue
    if [ "$HAVE_JQ" = "1" ]; then
      recent_commits+=("$(jq -n --arg sha "$sha" --arg subject "$subject" --arg author "$author" --arg date "$cdate" \
        '{sha: $sha, subject: $subject, author: $author, date: $date}')")
    else
      recent_commits+=("{\"sha\": \"$(json_escape "$sha")\", \"subject\": \"$(json_escape "$subject")\", \"author\": \"$(json_escape "$author")\", \"date\": \"$(json_escape "$cdate")\"}")
    fi
  done <<< "$recent_raw"

  branches_arr=()
  while IFS='|' read -r name reldate track; do
    [ -z "$name" ] && continue
    if [ "$HAVE_JQ" = "1" ]; then
      branches_arr+=("$(jq -n --arg name "$name" --arg reldate "$reldate" --arg track "$track" \
        '{name: $name, relative_date: $reldate, upstream_track: $track}')")
    else
      branches_arr+=("{\"name\": \"$(json_escape "$name")\", \"relative_date\": \"$(json_escape "$reldate")\", \"upstream_track\": \"$(json_escape "$track")\"}")
    fi
  done <<< "$branches_raw"

  if [ "$HAVE_JQ" = "1" ]; then
    recent_json=$(printf '%s\n' "${recent_commits[@]:-}" | jq -s 'map(select(. != null))')
    branches_json=$(printf '%s\n' "${branches_arr[@]:-}" | jq -s 'map(select(. != null))')
    entry=$(jq -n \
      --arg repo "$R" \
      --arg branch "$branch" \
      --argjson dirty_count "${dirty_count:-0}" \
      --argjson unpushed_commits "${unpushed_commits:-0}" \
      --argjson stash_count "${stash_count:-0}" \
      --argjson recent_commits "$recent_json" \
      --argjson branches "$branches_json" \
      --arg error "$err" \
      '{repo: $repo, branch: $branch, dirty_count: $dirty_count, unpushed_commits: $unpushed_commits,
        recent_commits: $recent_commits, branches: $branches, stash_count: $stash_count} +
       (if $error == "" then {} else {error: $error} end)'
    )
  else
    recent_join=$(IFS=,; echo "${recent_commits[*]:-}")
    branches_join=$(IFS=,; echo "${branches_arr[*]:-}")
    error_field=""
    if [ -n "$err" ]; then
      error_field=", \"error\": \"$(json_escape "$err")\""
    fi
    entry="{\"repo\": \"$(json_escape "$R")\", \"branch\": \"$(json_escape "$branch")\", \"dirty_count\": ${dirty_count:-0}, \"unpushed_commits\": ${unpushed_commits:-0}, \"recent_commits\": [$recent_join], \"branches\": [$branches_join], \"stash_count\": ${stash_count:-0}${error_field}}"
  fi

  entries+=("$entry")
done

if [ "$HAVE_JQ" = "1" ]; then
  printf '%s\n' "${entries[@]}" | jq -s '{repos: .}'
else
  joined=$(IFS=,; echo "${entries[*]}")
  echo "{\"repos\": [$joined]}"
fi
