#!/usr/bin/env bash
# Handoff file management for the `handoff` skill.
#
#   handoff.sh new <short-subject-label>   -> create a handoff from TEMPLATE.md, print its path
#   handoff.sh check <file>                -> scan a finished handoff for leaked credentials
#   handoff.sh hook                        -> PreToolUse hook: deny Write/Edit that leaks one
#   handoff.sh prune [--apply]             -> report (or perform) archival of stale handoffs
#
# Naming convention: <repository-code>-<YYYYMMDD>-<HHMMSS>-<short-subject-label>.md
set -euo pipefail

HANDOFF_DIR="${HANDOFF_DIR:-$HOME/.claude/handoffs}"
ARCHIVE_DIR="$HANDOFF_DIR/archive"
TEMPLATE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/assets/TEMPLATE.md"
ARCHIVE_AFTER_DAYS="${ARCHIVE_AFTER_DAYS:-30}"

slugify() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g' | cut -c1-48
}

repo_code() {
  # Worktrees resolve to their own directory name, so parallel worktrees stay distinct.
  local top
  top="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  slugify "$(basename "$top")"
}

cmd_new() {
  local label="${1:-}"
  [[ -n "$label" ]] || { echo "usage: handoff.sh new <short-subject-label>" >&2; exit 2; }
  [[ -f "$TEMPLATE" ]] || { echo "missing template: $TEMPLATE" >&2; exit 1; }

  mkdir -p "$HANDOFF_DIR"
  local dest="$HANDOFF_DIR/$(repo_code)-$(date +%Y%m%d)-$(date +%H%M%S)-$(slugify "$label").md"

  sed -e "s|{{SUBJECT}}|$label|g" \
      -e "s|{{REPO_PATH}}|$(git rev-parse --show-toplevel 2>/dev/null || pwd)|g" \
      -e "s|{{BRANCH}}|$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo n/a)|g" \
      -e "s|{{DATE}}|$(date +%Y-%m-%d)|g" \
      "$TEMPLATE" > "$dest"

  echo "$dest"
}

# Credential shapes worth blocking on. Deliberately narrow — a scanner that
# cries wolf gets ignored, which is worse than no scanner.
CREDENTIAL_PATTERNS=(
  'gh[pousr]_[A-Za-z0-9]{16,}'
  'github_pat_[A-Za-z0-9_]{20,}'
  'sk-(ant-)?[A-Za-z0-9_-]{20,}'
  'AKIA[0-9A-Z]{16}'
  'dapi[0-9a-f]{32}'
  'xox[baprs]-[A-Za-z0-9-]{10,}'
  'eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.'
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'
  '[a-z][a-z0-9+.-]*://[^/:@[:space:]]+:[^/@[:space:]]{6,}@'
  '(password|passwd|secret|api[_-]?key|access[_-]?token)[[:space:]]*[:=][[:space:]]*.?[A-Za-z0-9/+=_-]{12,}'
)

# Scans a file, printing one block per matching pattern. Returns 1 if anything hit.
scan_file() {
  local f="$1" hit=0
  for p in "${CREDENTIAL_PATTERNS[@]}"; do
    if grep -nEi "$p" "$f" >/dev/null 2>&1; then
      hit=1
      echo "POSSIBLE CREDENTIAL — pattern /$p/:"
      grep -nEi "$p" "$f" | cut -c1-160 | sed 's/^/  /'
    fi
  done
  return $hit
}

cmd_check() {
  local f="${1:-}"
  [[ -f "$f" ]] || { echo "usage: handoff.sh check <file>" >&2; exit 2; }

  if ! scan_file "$f"; then
    echo
    echo "Redact the above before handing this file to anyone. Do not finalise the handoff."
    return 1
  fi
  echo "no credential-shaped strings found in $(basename "$f")"
}

# PreToolUse hook entry point. Reads the hook JSON on stdin; denies a Write/Edit
# that would put a credential into a handoff file. Fails open on any internal
# error — a broken scanner must never block ordinary work.
cmd_hook() {
  local payload path body findings
  payload="$(cat)" || exit 0

  path="$(jq -r '.tool_input.file_path // empty' <<<"$payload" 2>/dev/null)" || exit 0
  [[ -n "$path" ]] || exit 0
  case "$path" in
    "$HANDOFF_DIR"/*|"$HOME"/.claude/handoffs/*) ;;
    *) exit 0 ;;
  esac

  # Write sends .content; Edit sends .new_string; MultiEdit sends an edits array.
  body="$(jq -r '[.tool_input.content // empty,
                 .tool_input.new_string // empty,
                 (.tool_input.edits // [] | map(.new_string // empty) | join("\n"))]
                | join("\n")' <<<"$payload" 2>/dev/null)" || exit 0
  [[ -n "${body// /}" ]] || exit 0

  # Not `local`: the EXIT trap runs after function scope is gone, and reading an
  # out-of-scope name under `set -u` would abort with a non-zero exit — which the
  # harness reads as a hook error and discards the deny verdict below.
  tmp="$(mktemp)" || exit 0
  trap 'rm -f "$tmp"' EXIT
  printf '%s' "$body" > "$tmp"

  if findings="$(scan_file "$tmp")"; then
    exit 0   # clean
  fi

  # Must exit 0: the verdict travels in this JSON, not in the exit code.
  jq -n --arg r "Blocked: this handoff content contains credential-shaped strings.
Line numbers are relative to the content being written.

$findings

Redact these (describe the credential instead of pasting it), then retry." \
    '{hookSpecificOutput: {hookEventName: "PreToolUse",
                           permissionDecision: "deny",
                           permissionDecisionReason: $r}}'
  exit 0
}

cmd_prune() {
  local apply=0
  [[ "${1:-}" == "--apply" ]] && apply=1
  mkdir -p "$HANDOFF_DIR"

  # Age comes from the YYYYMMDD in the filename, not mtime: editing a handoff
  # (fixing a cross-reference, appending an addendum) resets mtime and would
  # silently make a stale doc look fresh.
  local cutoff
  cutoff="$(date -d "-${ARCHIVE_AFTER_DAYS} days" +%Y%m%d)"

  local stale=() unparsed=()
  for path in "$HANDOFF_DIR"/*.md; do
    [[ -f "$path" ]] || continue
    local f d
    f="$(basename "$path")"
    d="$(grep -oE '[0-9]{8}-[0-9]{6}' <<<"$f" | head -1 | cut -d- -f1)"
    if [[ -z "$d" ]]; then unparsed+=("$f"); continue; fi
    [[ "$d" < "$cutoff" ]] && stale+=("$f")
  done

  if [[ ${#unparsed[@]} -gt 0 ]]; then
    echo "off-convention (no <YYYYMMDD>-<HHMMSS> in name) — rename these, not aged:"
    printf '  %s\n' "${unparsed[@]}"
  fi

  if [[ ${#stale[@]} -eq 0 ]]; then
    echo "no handoffs older than ${ARCHIVE_AFTER_DAYS}d in $HANDOFF_DIR"
    return 0
  fi

  if [[ $apply -eq 1 ]]; then
    mkdir -p "$ARCHIVE_DIR"
    for f in "${stale[@]}"; do
      mv "$HANDOFF_DIR/$f" "$ARCHIVE_DIR/$f"
      echo "archived: $f"
    done
  else
    echo "stale (>${ARCHIVE_AFTER_DAYS}d) — would move to $ARCHIVE_DIR:"
    printf '  %s\n' "${stale[@]}"
    echo "re-run with --apply to archive."
  fi
}

case "${1:-}" in
  new)   shift; cmd_new "$@" ;;
  check) shift; cmd_check "$@" ;;
  hook)  shift; cmd_hook "$@" ;;
  prune) shift; cmd_prune "$@" ;;
  *)     echo "usage: handoff.sh {new <label>|check <file>|hook|prune [--apply]}" >&2; exit 2 ;;
esac
