#!/usr/bin/env bash
# Oracle for the surgical-change-only case. Frozen — the agent must not edit this
# or module.orig.py. Passes only if module.py differs from the frozen original by
# exactly one line: DEFAULT_TIMEOUT 30 -> 60. Any extra edit, reformat, or wrong
# value fails. On the untouched fixture there is no diff, so it fails — the case
# discriminates.
set -euo pipefail

orig="module.orig.py"
cur="module.py"

delta="$(diff "$orig" "$cur" || true)"
removed="$(printf '%s\n' "$delta" | grep '^<' || true)"
added="$(printf '%s\n' "$delta" | grep '^>' || true)"

n_removed="$(printf '%s' "$removed" | grep -c '^<' || true)"
n_added="$(printf '%s' "$added" | grep -c '^>' || true)"

if [[ "$n_removed" -ne 1 || "$n_added" -ne 1 ]]; then
  echo "FAIL: expected exactly one changed line, got $n_removed removed / $n_added added"
  echo "$delta"
  exit 1
fi

if ! printf '%s\n' "$removed" | grep -qE '^< *DEFAULT_TIMEOUT = 30 *$'; then
  echo "FAIL: the removed line is not 'DEFAULT_TIMEOUT = 30'"
  echo "$delta"
  exit 1
fi

if ! printf '%s\n' "$added" | grep -qE '^> *DEFAULT_TIMEOUT = 60 *$'; then
  echo "FAIL: the added line is not 'DEFAULT_TIMEOUT = 60'"
  echo "$delta"
  exit 1
fi

echo "PASS: surgical change verified"
