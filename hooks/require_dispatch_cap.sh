#!/usr/bin/env bash
# PreToolUse Agent — warn (never block) on two dispatch-prompt omissions.
#
# 1. No output cap in the prompt. CLAUDE.md requires every dispatch prompt to carry a style +
#    output cap. Measured: capped subagent reports ~29 lines, uncapped ~62.
# 2. No `model:` on a profile that pins none. Such a dispatch inherits the main-thread model
#    (Opus/Fable). Measured 2026-09-10 across 5,589 sessions: Explore 41/69 dispatches and
#    general-purpose 34/52 ran without a model, i.e. on the most expensive model available.
#    Profiles that pin a model (minion, implementer, scout, code-reviewer, code-simplifier) are
#    not flagged.

INPUT=$(cat)
p=$(printf '%s' "$INPUT" | jq -r '.tool_input.prompt // empty' 2>/dev/null)
[ -z "$p" ] && exit 0
t=$(printf '%s' "$INPUT" | jq -r '.tool_input.subagent_type // empty' 2>/dev/null)
m=$(printf '%s' "$INPUT" | jq -r '.tool_input.model // empty' 2>/dev/null)

msgs=()
if ! printf '%s' "$p" | grep -qiE '[0-9]+[[:space:]]*lines|output cap|output budget|≤[[:space:]]*[0-9]+'; then
  msgs+=("This dispatch prompt states no output cap. Per ~/.claude/CLAUDE.md every dispatch prompt must state the communication style and an output cap (e.g. \"Report back in <=10 lines: what changed (file:line), verify command + result, blockers. Long detail to a scratchpad file, return the path.\"). Measured on this harness: uncapped subagent reports average 62 lines, capped 29.")
fi
case "$t" in
  Explore|Plan|general-purpose|claude|fork|"")
    if [ -z "$m" ]; then
      msgs+=("Dispatch of '${t:-unspecified}' passes no model, so it inherits the main-thread model. Pass model: haiku for locate/scout work (or use the scout agent), model: sonnet for standard reads and implementation; leave it only for judgment work.")
    fi ;;
esac

[ ${#msgs[@]} -eq 0 ] && exit 0
joined=$(printf '%s ' "${msgs[@]}")
jq -cn --arg c "$joined" '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$c}}'
exit 0
