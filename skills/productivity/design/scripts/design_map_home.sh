#!/usr/bin/env bash
# design_map_home.sh -- find a repo's decision-map home for the design skill.
#
# Usage: design_map_home.sh [cwd]
#
# Prints the home directory and exits:
#   0 -- an existing design-doc home was found (first candidate that already
#        holds at least one .md file, so an empty dir is never mistaken);
#   1 -- none found; the printed value is the suggested default
#        (<root>/.design/), which the skill confirms with the user.
#
# The skill appends "<topic-slug>.md" to the printed home. Probing lives here
# instead of in the agent prompt so the agent spends no tokens discovering the
# repo's layout.

set -uo pipefail

DIR="${1:-$PWD}"
ROOT=$(git -C "$DIR" rev-parse --show-toplevel 2>/dev/null) || ROOT="$DIR"

for CAND in "$ROOT/.design" "$ROOT/.claude/design" "$ROOT/.opencode/design" "$ROOT/docs/design"; do
  if [ -d "$CAND" ] && [ -n "$(find "$CAND" -maxdepth 1 -name '*.md' -print -quit 2>/dev/null)" ]; then
    echo "$CAND"
    exit 0
  fi
done

echo "$ROOT/.design"
exit 1