#!/usr/bin/env bash
# design_flag.sh -- get/set the design-mode flag for a repo.
#
# Usage:
#   design_flag.sh on <map-path> [cwd]   write flag, print flag file path
#   design_flag.sh off [cwd]             remove flag
#   design_flag.sh path [cwd]            print map path; exit 1 if not on
#
# [cwd] defaults to $PWD. Hooks pass the `.cwd` field from their JSON stdin
# so they resolve the same flag file the skill wrote, even though hooks run
# as a separate process from a different tool call.
#
# LIMITATION: the flag is keyed by repo root, not session id. Two concurrent
# Claude Code sessions in the same repo share one design-mode flag.
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$DIR/lib.sh"

mkdir -p "$HOME/.claude/design"

CMD="${1:-}"
case "$CMD" in
  on)
    MAP="${2:-}"
    CWD="${3:-$PWD}"
    if [ -z "$MAP" ]; then
      echo "design_flag.sh: usage: design_flag.sh on <map-path> [cwd]" >&2
      exit 2
    fi
    FLAG=$(design_flag_path_for "$CWD")
    printf '%s' "$MAP" > "$FLAG"
    echo "$FLAG"
    ;;
  off)
    CWD="${2:-$PWD}"
    FLAG=$(design_flag_path_for "$CWD")
    rm -f "$FLAG"
    ;;
  path)
    CWD="${2:-$PWD}"
    FLAG=$(design_flag_path_for "$CWD")
    [ -f "$FLAG" ] || exit 1
    cat "$FLAG"
    ;;
  *)
    echo "design_flag.sh: usage: design_flag.sh on <map-path> [cwd] | off [cwd] | path [cwd]" >&2
    exit 2
    ;;
esac
