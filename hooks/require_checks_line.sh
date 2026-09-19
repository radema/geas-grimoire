#!/usr/bin/env bash
# SubagentStop (implementer) — an implementer's final report must name what it ran to
# verify the change: a `checks: <cmd> exit N` line per ticket, or `checks: none run` with
# a reason. Guards against a report that just asserts "done" with no evidence.
#
# Canary: implementer ends its final message with no "checks:" line -> expect exit 2
# (stderr names the required format). Message with "checks: uv run pytest tests/ exit 0"
# or "checks: none run (no test suite in this repo)" -> exit 0.

INPUT=$(cat)
STOP_ACTIVE=$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)
[ "$STOP_ACTIVE" = "true" ] && exit 0

TP=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
if [ -z "$TP" ] || [ ! -f "$TP" ]; then
  exit 0
fi

TEXT=$(jq -c 'select(.type=="assistant")' "$TP" 2>/dev/null | tail -1 | jq -rs '
  [.[].message.content[]? | select(.type=="text") | .text] | join("\n")
' 2>/dev/null)

if printf '%s' "$TEXT" | grep -qiE 'checks: *none run'; then
  exit 0
fi
if printf '%s' "$TEXT" | grep -qE 'checks: .* exit [0-9]+'; then
  exit 0
fi

>&2 printf 'Final report must include one `checks: <cmd> exit N` line per ticket (or `checks: none run` with a reason).'
exit 2
