#!/usr/bin/env bash
# morning-brief orchestrator: runs stage-1 collectors, then stage-2 (claude -p)
# to render the final brief. See morning-brief/reference/ for the spec.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${MORNING_BRIEF_STATE_DIR:-/root/.local/state/morning-brief}"
mkdir -p "$STATE_DIR"

DATE="$(date +%F)"
DRY_RUN=0
FORCE=0
NO_FETCH=0
WEEKLY=0
SHOW=0
ONLY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --force) FORCE=1; shift ;;
    --no-fetch) NO_FETCH=1; shift ;;
    --weekly) WEEKLY=1; shift ;;
    --show) SHOW=1; shift ;;
    --only)
      [[ $# -ge 2 ]] || { echo "flag --only requires a value" >&2; exit 2; }
      ONLY="$2"; shift 2 ;;
    *) echo "unknown flag: $1" >&2; exit 1 ;;
  esac
done

CONTEXT_FILE="$STATE_DIR/context-$DATE.md"
BRIEF_FILE="$STATE_DIR/brief-$DATE.md"
COMMITMENTS_FILE="$STATE_DIR/commitments-$DATE.json"
USAGE_LOG="$STATE_DIR/usage.log"
LOCK_FILE="$STATE_DIR/.lock"
MARKER_FILE="$STATE_DIR/.ran-$DATE"

# Print today's brief if present, else context, else say nothing yet.
show_latest() {
  if [[ -f "$BRIEF_FILE" ]]; then
    cat "$BRIEF_FILE"
  elif [[ -f "$CONTEXT_FILE" ]]; then
    cat "$CONTEXT_FILE"
  else
    echo "nothing generated yet today"
  fi
}

if [[ "$SHOW" -eq 1 ]]; then
  show_latest
  exit 0
fi

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "another run in progress" >&2
  exit 1
fi

if [[ -f "$MARKER_FILE" && "$FORCE" -eq 0 && "$WEEKLY" -eq 0 ]]; then
  show_latest
  exit 0
fi

START_TIME=$(date +%s)

# --- Since when? ---
# The date the last brief actually ran, not "yesterday": collectors window
# their "what happened" queries on it, so a weekend or a day off does not
# erase the record of what was done.
SINCE=$(uv run python "$SCRIPT_DIR/lib/last_run.py" --state-dir "$STATE_DIR" 2>/dev/null || true)
if [[ -n "$SINCE" ]]; then
  export MORNING_BRIEF_SINCE="$SINCE"
fi

# --- Stage 1: collectors ---
BUNDLE_ARGS=(--state-dir "$STATE_DIR")
[[ "$NO_FETCH" -eq 1 ]] && BUNDLE_ARGS+=(--no-fetch)
[[ -n "$ONLY" ]] && BUNDLE_ARGS+=(--only "$ONLY")

if ! uv run python "$SCRIPT_DIR/lib/bundle.py" "${BUNDLE_ARGS[@]}"; then
  echo "bundle.py failed fully - no bundle to build on, aborting" >&2
  exit 1
fi

if ! uv run python "$SCRIPT_DIR/lib/signals.py" --state-dir "$STATE_DIR"; then
  echo "stage failed: signals.py" >&2
fi

if ! uv run python "$SCRIPT_DIR/lib/diff.py" --state-dir "$STATE_DIR"; then
  echo "stage failed: diff.py" >&2
fi

if ! uv run python "$SCRIPT_DIR/lib/commitments.py" --state-dir "$STATE_DIR"; then
  echo "stage failed: commitments.py" >&2
fi

if ! uv run python "$SCRIPT_DIR/lib/render_context.py" --state-dir "$STATE_DIR" --out "$CONTEXT_FILE"; then
  echo "stage failed: render_context.py" >&2
fi

if [[ ! -f "$CONTEXT_FILE" ]]; then
  echo "render_context.py did not produce $CONTEXT_FILE - no context to build on, aborting" >&2
  exit 1
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  cat "$CONTEXT_FILE"
  exit 0
fi

# TODO: placeholder pending real usage.log-based quota tracking. Always passes today.
check_quota() { return 0; }

if ! check_quota; then
  cp "$CONTEXT_FILE" "$BRIEF_FILE"
  touch "$MARKER_FILE"
  ELAPSED=$(( $(date +%s) - START_TIME ))
  echo "$DATE  model=none  weekly=$WEEKLY  secs=$ELAPSED  quota=exceeded" >>"$USAGE_LOG"
  cat "$BRIEF_FILE"
  exit 0
fi

# --- Stage 2: claude -p renders the final brief ---
MODEL="${MORNING_BRIEF_MODEL:-sonnet}"
PROMPT="/morning-brief --headless"
[[ "$WEEKLY" -eq 1 ]] && PROMPT="/morning-brief --weekly --headless"

RAW_FILE="$STATE_DIR/brief-$DATE.md.raw"
STDERR_FILE="$STATE_DIR/claude-stderr-$DATE.log"

# True if $1 exists and was (re)written at or after this run started -
# i.e. the model actually wrote it itself, rather than a stale file left
# over from an earlier run.
written_this_run() {
  [[ -f "$1" ]] && [[ "$(stat -c %Y "$1")" -ge "$START_TIME" ]]
}

CLAUDE_OK=1
if ! claude -p "$PROMPT" \
  --model "$MODEL" \
  --allowed-tools "Read,Write" \
  --output-format json \
  --add-dir "$STATE_DIR" \
  >"$RAW_FILE" 2>"$STDERR_FILE"; then
  CLAUDE_OK=0
  echo "claude -p call failed, falling back to context.md as brief" >&2
fi

USAGE_SUFFIX=""
if [[ "$CLAUDE_OK" -eq 1 ]] && written_this_run "$BRIEF_FILE"; then
  : # model already wrote brief-$DATE.md itself this run - leave it alone
elif [[ "$CLAUDE_OK" -eq 1 ]]; then
  if RESULT_TEXT=$(uv run python -c "
import json, sys
try:
    data = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(1)
result = data.get('result')
if not isinstance(result, str) or not result:
    sys.exit(1)
sys.stdout.write(result)
usage = data.get('usage') or {}
tok_in = usage.get('input_tokens')
tok_out = usage.get('output_tokens')
if tok_in is not None and tok_out is not None:
    sys.stderr.write(f'in={tok_in} out={tok_out}')
" -- "$RAW_FILE" 2>"$STATE_DIR/.usage-tokens.tmp"); then
    echo "$RESULT_TEXT" >"$BRIEF_FILE"
    if [[ -s "$STATE_DIR/.usage-tokens.tmp" ]]; then
      USAGE_SUFFIX="  $(cat "$STATE_DIR/.usage-tokens.tmp")"
    fi
    rm -f "$STATE_DIR/.usage-tokens.tmp"
  else
    echo "claude -p output was not valid JSON with a result field, falling back to context.md" >&2
    CLAUDE_OK=0
    rm -f "$STATE_DIR/.usage-tokens.tmp"
  fi
fi

if [[ "$CLAUDE_OK" -eq 0 ]] && ! written_this_run "$BRIEF_FILE"; then
  cp "$CONTEXT_FILE" "$BRIEF_FILE"
fi

# Stage 2 is expected to also write a commitments file itself; only trust
# it if it was actually written this run, then sanity-check it.
if written_this_run "$COMMITMENTS_FILE"; then
  if ! uv run python -c "import json, sys; json.load(open(sys.argv[1]))" -- "$COMMITMENTS_FILE" 2>/dev/null; then
    echo "warning: $COMMITMENTS_FILE is malformed JSON, ignoring it (brief still stands)" >&2
  fi
fi

ELAPSED=$(( $(date +%s) - START_TIME ))
echo "$DATE  model=$MODEL  weekly=$WEEKLY  secs=$ELAPSED${USAGE_SUFFIX}" >>"$USAGE_LOG"

if [[ "$WEEKLY" -eq 0 ]]; then
  touch "$MARKER_FILE"
fi

cat "$BRIEF_FILE"
