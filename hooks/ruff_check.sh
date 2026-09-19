#!/usr/bin/env bash
# PostToolUse Edit|Write: lint the edited Python file with ruff.
#
# Replaces the inline hook that did `cd "$(dirname "$f")" && uv run ruff check "$f"`
# with `2>/dev/null || true`. Two problems with that version:
#   - the file's own directory is not the uv project, so a nested file (e.g.
#     preparation/ingestion/foo.py) resolved a different env than the repo root, or none.
#   - stderr was discarded, so "ruff is not installed" / "no uv project here" looked
#     exactly like a clean lint.
#
# Now: walk up to the nearest pyproject.toml and run there, and print failures instead
# of hiding them. Always exits 0 — a lint finding is information, not a blocked edit.

f=$(jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -n "$f" ] || exit 0
case "$f" in *.py) ;; *) exit 0 ;; esac
[ -f "$f" ] || exit 0

dir=$(dirname -- "$f")
root=""
d="$dir"
while [ "$d" != "/" ] && [ -n "$d" ]; do
  if [ -f "$d/pyproject.toml" ]; then root="$d"; break; fi
  d=$(dirname -- "$d")
done
[ -n "$root" ] || root="$dir"

cd "$root" || exit 0

use_fix=0
[ -f "$root/ruff.toml" ] && use_fix=1
[ -f "$root/pyproject.toml" ] && grep -q '\[tool\.ruff' "$root/pyproject.toml" 2>/dev/null && use_fix=1

if [ "$use_fix" = 1 ]; then
  if ! out=$(uv run ruff format "$f" 2>&1 && uv run ruff check --fix "$f" 2>&1); then
    printf 'ruff format/check --fix (from %s):\n%s\n' "$root" "$out"
  fi
else
  if ! out=$(uv run ruff check "$f" 2>&1); then
    printf 'ruff check (from %s):\n%s\n' "$root" "$out"
  fi
fi
exit 0
