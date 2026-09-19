#!/usr/bin/env bash
# PreToolUse Bash — for READ-ONLY agents (code-reviewer, code-simplifier, scout).
# Wired from each agent's frontmatter `hooks:` block, so it runs only while that agent runs.
#
# Why: those profiles say "you do not modify code" in prose, but Bash can still write files
# (sed -i, redirects, tee) and move history (git commit/add/stash/checkout/reset). Reviewers
# need Bash to run tests and `git diff`, so the tool stays; this denies the writing shapes.
#
# Allowed: anything else — test runners, git diff/log/show/status, grep, cat, ls.
# False-positive risk: a legitimate read that contains `>` (e.g. `2>&1`, `2>/dev/null`) —
# those two forms are whitelisted below. Redirects to a file are denied on purpose; write
# your findings in your final report or via the Write-less channel your dispatcher named.
# Redirects into /tmp are also whitelisted — scratch comparisons (`... > /tmp/a && diff /tmp/a /tmp/b`) are reads in effect, not a way to smuggle persistent output.

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$CMD" ] && exit 0

deny() {
  jq -cn --arg r "$1" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

# Strip harmless redirects before testing for file redirects.
STRIPPED=$(printf '%s' "$CMD" | sed -E 's/2>&1//g; s/[12]?>>?[[:space:]]*\/tmp\/[^[:space:];|&]*//g;  s/[12]?>[[:space:]]*\/dev\/null//g; s/<<[[:space:]]*['"'"'"]?EOF['"'"'"]?//g')

case "$STRIPPED" in
  *">"*)                      deny "Read-only agent: shell redirect to a file is not allowed. Report findings in your final message instead." ;;
esac
if printf '%s' "$CMD" | grep -qE '(^|[[:space:];&|])(sed[[:space:]]+(-[a-zA-Z]*i|--in-place)|tee[[:space:]]|rm[[:space:]]|mv[[:space:]]|cp[[:space:]]|chmod[[:space:]]|truncate[[:space:]]|python3?[[:space:]]+-c[[:space:]].*open\(.*["'"'"']w)'; then
  deny "Read-only agent: file-modifying command blocked. You review; you do not edit. If a fix is needed, describe it with file:line in your report."
fi
if printf '%s' "$CMD" | grep -qE '(^|[[:space:];&|])git[[:space:]]+(commit|add|stash|checkout|switch|reset|rebase|merge|push|cherry-pick|restore|clean|branch[[:space:]]+-[dDm])'; then
  deny "Read-only agent: git state-changing command blocked. Use git diff/log/show/status only."
fi
exit 0
