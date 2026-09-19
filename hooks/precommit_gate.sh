#!/usr/bin/env bash
# PreToolUse Bash, wired with "if": "Bash(git commit *)" — run pre-commit on staged files
# before a commit lands, so a failing hook blocks the commit with the actual output instead
# of the commit going through and CI catching it later.
#
# Why: pre-commit hooks (ruff, formatters, etc.) can auto-fix files; if they do and the
# re-run then passes, we re-stage the fixed files and let the commit through rather than
# forcing a second manual attempt.
#
# Canary: repo with a failing pre-commit hook (e.g. bad ruff lint) staged, `git commit -m x`
# -> expect exit 2 with the pre-commit output on stderr. Same repo with only a fixable
# formatting issue -> expect exit 0 and "pre-commit reformatted N files, re-staged".
# Repo with no .pre-commit-config.yaml, or nothing staged -> exit 0, no output.

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$CMD" ] && exit 0
[ -n "$CWD" ] && cd "$CWD" 2>/dev/null

root=$(git rev-parse --show-toplevel 2>/dev/null)
[ -z "$root" ] && exit 0
[ -f "$root/.pre-commit-config.yaml" ] || exit 0

staged=$(git -C "$root" diff --cached --name-only --diff-filter=ACMR)
[ -z "$staged" ] && exit 0

if command -v pre-commit >/dev/null 2>&1; then
  runner="pre-commit"
elif command -v uv >/dev/null 2>&1 && [ -f "$root/pyproject.toml" ]; then
  runner="uv run pre-commit"
else
  exit 0
fi

cd "$root" || exit 0

# shellcheck disable=SC2086
out=$($runner run --files $staged 2>&1)
rc=$?
[ $rc -eq 0 ] && exit 0

changed=$(git diff --name-only -- $staged)
if [ -n "$changed" ]; then
  # shellcheck disable=SC2086
  out2=$($runner run --files $staged 2>&1)
  rc2=$?
  if [ $rc2 -eq 0 ]; then
    # shellcheck disable=SC2086
    git add -- $staged
    n=$(printf '%s\n' "$staged" | grep -c .)
    printf 'pre-commit reformatted %s files, re-staged\n' "$n"
    exit 0
  fi
  out=$out2
fi

>&2 printf 'pre-commit failed; fix before committing:\n%s\n' "$(printf '%s' "$out" | tail -40)"
exit 2
