#!/usr/bin/env bash
# UserPromptSubmit -- injects the design-mode reminder every round while the
# flag is on, and clears the flag on "BUILD" or "/design off".
#
# Silent (exit 0, no output) when design mode isn't active for this cwd.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INPUT=$(cat)
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$CWD" ] && exit 0

PROMPT=$(printf '%s' "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
TRIMMED=$(printf '%s' "$PROMPT" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
LOWER=$(printf '%s' "$TRIMMED" | tr '[:upper:]' '[:lower:]')

OFF=0
[ "$LOWER" = "build" ] && OFF=1
case "$LOWER" in "/design off"*) OFF=1 ;; esac

if [ "$OFF" = "1" ]; then
  MAP=$(bash "$DIR/design_flag.sh" path "$CWD" 2>/dev/null)
  bash "$DIR/design_flag.sh" off "$CWD" >/dev/null 2>&1
  if [ -n "$MAP" ]; then
    jq -cn --arg ctx "Design mode OFF. Decision map: $MAP. Hand off to implementation now." \
      '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$ctx}}'
  fi
  exit 0
fi

MAP=$(bash "$DIR/design_flag.sh" path "$CWD" 2>/dev/null) || exit 0

CTX="DESIGN MODE ON (map: $MAP). 1) Batch clarifying questions into one AskUserQuestion call, custom answers allowed. 2) Append every ruling to the map's Decisions section. 3) No code, no edits outside the map; end the round asking: continue or BUILD?"
jq -cn --arg ctx "$CTX" '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$ctx}}'
