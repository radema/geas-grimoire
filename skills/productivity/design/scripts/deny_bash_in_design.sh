#!/usr/bin/env bash
# PreToolUse Bash -- while design mode is on for this repo, Bash is restricted
# to the same read-only shape as a read-only agent (see
# ~/.claude/hooks/deny_bash_writes.sh): reads, test runs, git diff/log/status
# are fine; writes, redirects and git state changes are not. The
# design_flag.sh call the skill itself makes (to turn the flag on) is
# whitelisted so the skill can bootstrap design mode.
#
# No flag for this cwd -> exit 0.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INPUT=$(cat)
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$CWD" ] && exit 0

MAP=$(bash "$DIR/design_flag.sh" path "$CWD" 2>/dev/null) || exit 0

CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
case "$CMD" in
  *design_flag.sh*) exit 0 ;;
esac

printf '%s' "$INPUT" | bash ~/.claude/hooks/deny_bash_writes.sh
exit $?
