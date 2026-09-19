#!/usr/bin/env bash
# lib.sh -- shared key computation for design-mode flag files.
# Sourced by design_flag.sh and the hooks; not run directly.
#
# Key = sha1 of the git toplevel for the given dir (or the dir itself if it's
# not a git repo). This is what lets a skill invocation (bash cwd = skill
# working dir at call time) and a hook invocation (JSON `.cwd` from a
# different tool call) agree on the same flag file without sharing a
# session id.

design_key_for() {
  local dir="$1" root
  root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || root="$dir"
  printf '%s' "$root" | sha1sum | cut -d' ' -f1
}

design_flag_path_for() {
  echo "$HOME/.claude/design/$(design_key_for "$1").flag"
}
