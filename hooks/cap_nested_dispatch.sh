#!/usr/bin/env bash
# Deny Agent dispatch from inside a leaf subagent. Leaves never sub-delegate.
#
# Detection (2026-09-10): the hook input carries `agent_type` when running inside a subagent
# (documented PreToolUse field). Fallback for older runtimes: the subagent transcript carries a
# {"type":"agent-setting","agentSetting":"<type>"} event; main-thread sessions carry none
# (verified 2026-07-30 across 264 session files).
#
# Blast radius is narrow by construction: every custom profile holds no `Agent` grant, so this
# can only bite `general-purpose`, `claude` and `fork` (which inherit `tools: *`). Measured: 9 of
# 12 observed nesting violations were `general-purpose`. The `orchestrator` profile that used to
# be licensed here was retired 2026-09-10; orchestration is the main thread's job.

INPUT=$(cat)
SETTING=$(printf '%s' "$INPUT" | jq -r '.agent_type // empty' 2>/dev/null)

if [ -z "$SETTING" ]; then
  TP=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
  { [ -z "$TP" ] || [ ! -f "$TP" ]; } && exit 0
  SETTING=$(grep -o '"agentSetting":"[^"]*"' "$TP" 2>/dev/null | head -1 | cut -d'"' -f4)
fi
[ -z "$SETTING" ] && exit 0                 # main thread — unrestricted

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Leaf agents never sub-delegate (~/.claude/CLAUDE.md). This session is a `%s` subagent. Do the work yourself, or report back to the main thread that the task needs splitting."}}\n' "$SETTING"
exit 0
