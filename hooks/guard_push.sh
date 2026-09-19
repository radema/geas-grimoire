#!/usr/bin/env bash
# PreToolUse Bash, `if: Bash(git *)` and `if: Bash(databricks *)` — session-wide guard.
#
# Replaces two prose rules that lived in every builder profile and in CLAUDE.md:
#   - never force-push; never push to main / stage / dev without explicit instruction
#   - never `databricks bundle deploy` against prod / stg (CI does that)
# Denies only those shapes. Ordinary `git push -u origin feature/x` passes and still hits the
# existing `permissions.ask` rule for `Bash(git push:*)`.
#
# Output uses the JSON permissionDecision path (exit 0 always).

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$CMD" ] && exit 0

deny() {
  jq -cn --arg r "$1" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

# --- git push -------------------------------------------------------------
if printf '%s' "$CMD" | grep -qE '(^|[[:space:];&|])git[[:space:]]+push([[:space:]]|$)'; then
  PUSH=$(printf '%s' "$CMD" | grep -oE 'git[[:space:]]+push[^;&|]*' | head -1)
  if printf '%s' "$PUSH" | grep -qE '(^|[[:space:]])(--force|-f|--force-with-lease[^[:space:]]*|-[a-zA-Z]*f[a-zA-Z]*)([[:space:]]|$)|[[:space:]]\+[a-zA-Z]'; then
    deny "Force-push blocked by ~/.claude/hooks/guard_push.sh. Rewriting shared history needs the user to run it by hand."
  fi
  # refspec or bare branch naming a protected branch
  if printf '%s' "$PUSH" | grep -qE '(^|[[:space:]:])(main|master|stage|dev)([[:space:]]|$)|HEAD:(main|master|stage|dev)([[:space:]]|$)'; then
    deny "Push to a protected branch (main/master/stage/dev) blocked by guard_push.sh. Push a feature branch and open a PR; the user merges."
  fi
fi

# --- databricks bundle deploy ---------------------------------------------
if printf '%s' "$CMD" | grep -qE '(^|[[:space:];&|])databricks[[:space:]]+bundle[[:space:]]+(deploy|run|destroy)'; then
  if printf '%s' "$CMD" | grep -qE '(-t|--target)[[:space:]=]+(prod|production|stg|stage|staging)([[:space:]]|$)'; then
    deny "databricks bundle against prod/stg blocked by guard_push.sh. Those targets deploy via GitHub Actions only; use -t dev locally."
  fi
fi
exit 0
