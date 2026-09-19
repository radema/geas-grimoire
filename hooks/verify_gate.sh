#!/usr/bin/env bash
# Stop hook — catches a turn that claims "verified"/"complete"/"tests pass" but ran no
# check command this turn. Scoped to the current turn only (everything after the last
# real incoming user/teammate message in the transcript), so a claim about work done in
# an earlier turn (already checked then) doesn't re-trigger.
#
# Canary: edit a .py file, write "verified" in the final reply, end turn -> expect one
# block (exit 2, stderr explains). Stop again immediately after (stop_hook_active=true)
# -> passes through, exit 0. Same turn but the reply says "ran no tests, UNVERIFIED" or
# actually ran `uv run pytest` -> exit 0.
#
# Must stay fast and never hard-fail on a malformed transcript: any parse problem falls
# through to exit 0 rather than blocking the agent.

INPUT=$(cat)
STOP_ACTIVE=$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)
[ "$STOP_ACTIVE" = "true" ] && exit 0

TP=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
if [ -z "$TP" ] || [ ! -f "$TP" ]; then
  exit 0
fi

# Last line number of a "real" incoming user turn: type=="user" and the content is not a
# tool_result (a plain string, or an array with no tool_result block).
LAST_INCOMING=$(jq -c '
  select(.type=="user") |
  ((.message.content|type) as $t |
   if $t=="string" then true
   elif $t=="array" then ([.message.content[]?.type] | index("tool_result") | not)
   else true end) as $real |
  select($real) |
  input_line_number
' "$TP" 2>/dev/null | tail -1)
[ -z "$LAST_INCOMING" ] && LAST_INCOMING=0

SLICE=$(tail -n "+$((LAST_INCOMING + 1))" "$TP" 2>/dev/null)
[ -z "$SLICE" ] && exit 0

TEXT=$(printf '%s\n' "$SLICE" | jq -rs '
  [.[] | select(.type=="assistant") | .message.content[]? | select(.type=="text") | .text] | join("\n")
' 2>/dev/null)

CMDS=$(printf '%s\n' "$SLICE" | jq -rs '
  [.[] | select(.type=="assistant") | .message.content[]? | select(.type=="tool_use" and .name=="Bash") | .input.command] | join("\n")
' 2>/dev/null)

claim=0
printf '%s' "$TEXT" | grep -qiE '\b(verified|all clean|complete|completed|passes|passing|tests? pass)\b' && claim=1
[ "$claim" = 0 ] && exit 0

check=0
printf '%s' "$CMDS" | grep -qiE 'pytest|ruff|dbt (compile|test|run|build)|uv run|python3? |npm (test|run)|pnpm test|make |diff |verify_branch|git diff' && check=1
[ "$check" = 1 ] && exit 0

printf '%s' "$TEXT" | grep -q 'UNVERIFIED' && exit 0

>&2 printf 'You claimed verified/complete but ran no check this turn. Run the check and quote its output, or write UNVERIFIED.'
exit 2
