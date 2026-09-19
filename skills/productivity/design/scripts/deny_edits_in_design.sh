#!/usr/bin/env bash
# PreToolUse Edit|Write -- while design mode is on for this repo, only the
# decision map (and files under docs/ or .specify/) may be written. Everything
# else is denied so a design conversation can't slip into code edits.
#
# No flag for this cwd -> exit 0 (design mode not active, nothing to check).

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INPUT=$(cat)
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$CWD" ] && exit 0

MAP=$(bash "$DIR/design_flag.sh" path "$CWD" 2>/dev/null) || exit 0

FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$FILE" ] && exit 0

ROOT=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null) || ROOT="$CWD"

case "$FILE" in
  "$MAP") exit 0 ;;
  "$ROOT/docs/"*|"$ROOT/.specify/"*) exit 0 ;;
esac

jq -cn --arg r "DESIGN mode: no code edits. Edit only the decision map ($MAP). Type BUILD or /design off to leave." \
  '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
exit 0
