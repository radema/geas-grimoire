#!/usr/bin/env bash
# usage_evidence.sh — read-only usage-evidence grep for the spring-cleaning skill.
#
# Usage: usage_evidence.sh <name> [<name>...]
# For each name, searches Claude Code session transcripts and prompt history for
# INVOCATION-shaped evidence (not bare mentions) and prints:
#   <name>\t<hits>\t<latest_evidence_date | ->
#
# Why invocation-shaped: every session's transcript embeds the full skill listing, so a bare-name
# grep matches ~every transcript for ~every skill. We instead match:
#   - Skill tool calls:            "skill": "<name>"  /  "skill":"<name>"
#   - typed slash commands:        "/<name>" at a display-boundary (history.jsonl + transcripts)
#   - command expansion markers:   <command-name>/<name>
# Hook scripts: pass the script filename (e.g. my_hook.sh) — any transcript mention of a script
# filename is already invocation-shaped (denial/output messages).
#
# 0 hits = "no evidence of use", NOT proof of never-used (transcripts rotate).
# A single hit dated today may be the auditing session itself — treat as self-contamination.
set -u

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
PROJECTS_DIR="$CLAUDE_DIR/projects"
HISTORY_FILE="$CLAUDE_DIR/history.jsonl"

if [ "$#" -eq 0 ]; then
  echo "usage: $(basename "$0") <name> [<name>...]" >&2
  exit 2
fi

if [ ! -d "$PROJECTS_DIR" ] && [ ! -f "$HISTORY_FILE" ]; then
  echo "NOT RUN: neither $PROJECTS_DIR nor $HISTORY_FILE exists" >&2
  exit 3
fi

printf 'name\thits\tlatest_evidence\n'
for name in "$@"; do
  hits=0
  latest_epoch=0
  esc=$(printf '%s' "$name" | sed 's/[.[\*^$()+?{|]/\\&/g')
  if [[ "$name" == *.sh || "$name" == *.py ]]; then
    pattern="$esc"           # script filename: bare mention is fine
  else
    pattern="\"skill\":[[:space:]]*\"${esc}\"|<command-name>/?${esc}|\"/${esc}[\" ]"
  fi

  scan() { grep -rlE -- "$pattern" "$1" 2>/dev/null; }

  if [ -d "$PROJECTS_DIR" ]; then
    while IFS= read -r f; do
      hits=$((hits + 1))
      m=$(stat -c %Y "$f" 2>/dev/null || echo 0)
      [ "$m" -gt "$latest_epoch" ] && latest_epoch=$m
    done < <(scan "$PROJECTS_DIR")
  fi

  if [ -f "$HISTORY_FILE" ] && grep -qE -- "$pattern" "$HISTORY_FILE" 2>/dev/null; then
    hits=$((hits + 1))
    m=$(stat -c %Y "$HISTORY_FILE" 2>/dev/null || echo 0)
    [ "$m" -gt "$latest_epoch" ] && latest_epoch=$m
  fi

  if [ "$latest_epoch" -gt 0 ]; then
    latest=$(date -d "@$latest_epoch" +%F 2>/dev/null || date -r "$latest_epoch" +%F)
  else
    latest='-'
  fi
  printf '%s\t%s\t%s\n' "$name" "$hits" "$latest"
done
