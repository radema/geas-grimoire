#!/usr/bin/env bash
# PreToolUse Agent — enforce ticket-loop's max_parallel cap mechanically.
#
# The ticket-loop skill says "dispatch while running < max_parallel". This hook makes that hold
# when the prose is skipped: it finds the active story state file (.claude/ticket-loop/<story>.json
# with at least one trail in building|reviewing|merging), and denies an Agent dispatch whose prompt
# names that story or one of its tickets while running >= max_parallel.
#
# Unrelated dispatches (no story/ticket key in the prompt) always pass. No active story: pass.

INPUT=$(cat)
PROMPT=$(printf '%s' "$INPUT" | jq -r '.tool_input.prompt // empty' 2>/dev/null)
[ -z "$PROMPT" ] && exit 0
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$CWD" ] && exit 0
ROOT=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null) || exit 0
DIR="$ROOT/.claude/ticket-loop"
[ -d "$DIR" ] || exit 0

for f in $(ls -t "$DIR"/*.json 2>/dev/null); do
  running=$(jq -r '[.trails[]? | select(.status=="building" or .status=="reviewing" or .status=="merging")] | length' "$f" 2>/dev/null) || continue
  [ "${running:-0}" -gt 0 ] || continue
  cap=$(jq -r '.max_parallel // 3' "$f")
  [ "$running" -ge "$cap" ] || exit 0
  story=$(jq -r '.story' "$f")
  keys=$(jq -r '[.story] + [.tickets[].key] | join("|")' "$f")
  if printf '%s' "$PROMPT" | grep -qE "\\b($keys)\\b"; then
    jq -cn --arg r "ticket-loop cap reached for $story: $running/$cap agents running (~/.claude/hooks/ticket_loop_cap.sh). Do not dispatch another trail; end the turn and wait for a completion notification, then re-run state.sh can-dispatch." \
      '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  fi
  exit 0
done
exit 0
