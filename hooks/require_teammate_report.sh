#!/usr/bin/env bash
# Block a teammate from going idle until it has sent a SendMessage report to
# its lead since the last incoming (lead/user) turn. Guards against the
# observed failure: a dispatched subagent finishes its task and goes idle —
# the lead only sees an idle_notification, no findings.
#
# Picked over a SubagentStop gate (wrong event scope for plain Agent-tool
# dispatches, which already return their report as the tool result) and over
# a non-blocking additionalContext nudge (same instruction that's already
# being ignored, just relocated). Advisor review: fable-advisor, 2026-08-25.
#
# Loop-safety: capped at 2 blocks per incoming-turn boundary (tracked in a
# state file keyed by session_id+teammate_name), then lets idle through so a
# stuck agent can't be blocked forever. Resets when a report is seen, or when
# a new incoming message advances the boundary.
#
# No tool-availability pre-check: SendMessage is often a deferred tool (not
# listed in the transcript's init entry until first fetched via ToolSearch),
# so "grep the transcript for the tool name" can't reliably tell "no tool"
# from "tool unused" — and "tool unused" is exactly the failure this hook
# exists to catch. The loop cap absorbs the cost for agents with no
# SendMessage tool at all: capped at 2 blocked idles, then through. The
# stderr message says to ignore the block if the tool doesn't exist.
# Advisor review: fable-advisor, 2026-08-25.

INPUT=$(cat)
TP=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
SESSION=$(printf '%s' "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)
TEAMMATE=$(printf '%s' "$INPUT" | jq -r '.teammate_name // "unknown"' 2>/dev/null)

{ [ -z "$TP" ] || [ ! -f "$TP" ]; } && exit 0

STATE_DIR="/tmp/claude-teammate-idle"
mkdir -p "$STATE_DIR" 2>/dev/null
STATE_FILE="$STATE_DIR/${SESSION}-${TEAMMATE}.json"

LINES=$(wc -l < "$TP" 2>/dev/null || echo 0)

# Last incoming (lead/user) turn — a plain "user" role entry that is not
# itself a tool_result wrapper, and not this hook's own injected block
# feedback (which would otherwise look like a fresh incoming turn and reset
# the loop-safety counter forever).
LAST_INCOMING=$(grep -n '"role":[[:space:]]*"user"' "$TP" 2>/dev/null | grep -v 'tool_result' | grep -v 'Send findings to team-lead' | tail -1 | cut -d: -f1)
[ -z "$LAST_INCOMING" ] && LAST_INCOMING=0

# Did a SendMessage tool_use happen after that line? Require both markers on
# the same line so a tool_result schema dump mentioning the string
# "SendMessage" (e.g. from ToolSearch) doesn't count as a report sent.
SENT_SINCE=0
if [ "$LAST_INCOMING" -lt "$LINES" ]; then
  if tail -n "+$((LAST_INCOMING + 1))" "$TP" 2>/dev/null | grep '"type":[[:space:]]*"tool_use"' | grep -q '"name":[[:space:]]*"SendMessage"'; then
    SENT_SINCE=1
  fi
fi

if [ "$SENT_SINCE" = "1" ]; then
  rm -f "$STATE_FILE" 2>/dev/null
  exit 0
fi

PREV_BOUNDARY=0
BLOCKS=0
if [ -f "$STATE_FILE" ]; then
  PREV_BOUNDARY=$(jq -r '.boundary // 0' "$STATE_FILE" 2>/dev/null)
  BLOCKS=$(jq -r '.blocks // 0' "$STATE_FILE" 2>/dev/null)
fi

# A new incoming turn since the last block resets the counter.
if [ "$LAST_INCOMING" != "$PREV_BOUNDARY" ]; then
  BLOCKS=0
fi

if [ "$BLOCKS" -ge 2 ]; then
  rm -f "$STATE_FILE" 2>/dev/null
  exit 0
fi

BLOCKS=$((BLOCKS + 1))
printf '{"boundary":%s,"blocks":%s}' "$LAST_INCOMING" "$BLOCKS" > "$STATE_FILE" 2>/dev/null

>&2 printf 'Send findings to team-lead via SendMessage, then idle. If you have no SendMessage tool, ignore.'
exit 2
