#!/usr/bin/env bash
# check-wiki-links.sh — link-integrity gate for a docs-wiki.
#
# Verifies two things the swarm gets wrong most often:
#   1. [[wikilinks]] whose target page does not exist in the wiki dir.
#   2. relative markdown links ( ](../x.md) ) whose target file is missing.
#
# Usage:  check-wiki-links.sh [WIKI_DIR] [SCAN_ROOT]
#   WIKI_DIR   dir holding the [[wikilink]] pages   (default: docs/wiki)
#   SCAN_ROOT  root to scan for relative .md links  (default: .)
#
# Exit 0 = PASS, 1 = broken links found, 2 = bad invocation.
# Run it from the repo root during the review pass of any docs-wiki run.
set -uo pipefail

WIKI_DIR="${1:-docs/wiki}"
SCAN_ROOT="${2:-.}"
fail=0

[ -d "$WIKI_DIR" ] || { echo "ERROR: wiki dir not found: $WIKI_DIR"; exit 2; }

# --- collect existing wiki page slugs (filename without .md) ---
declare -A page_exists
for f in "$WIKI_DIR"/*.md; do
  [ -e "$f" ] || continue
  b="${f##*/}"; b="${b%.md}"
  page_exists["$b"]=1
done

echo "== [[wikilink]] integrity (targets must be a page in $WIKI_DIR) =="
dangling=0
# extract [[Target]] / [[Target#anchor]] / [[Target|alias]] -> Target
while IFS= read -r tgt; do
  [ -n "$tgt" ] || continue
  if [ -z "${page_exists[$tgt]:-}" ]; then
    echo "  DANGLING [[${tgt}]]"
    dangling=$((dangling+1))
  fi
done < <(grep -rhoP '(?<=\[\[)[^]]+' "$WIKI_DIR" 2>/dev/null | grep -oP '^[^#|]+' | sort -u)
if [ "$dangling" -eq 0 ]; then echo "  OK: no dangling wikilinks"; else fail=1; fi
echo "  (a conventions/glossary page may show intentionally-fake example targets — eyeball those)"
echo

echo "== relative .md link integrity (scan: $SCAN_ROOT) =="
broken=0
shopt -s globstar nullglob
for f in "$SCAN_ROOT"/**/*.md; do
  case "$f" in *"/node_modules/"*|*"/_legacy/"*|*"/.git/"*) continue;; esac
  dir="${f%/*}"
  while IFS= read -r link; do
    [ -n "$link" ] || continue
    case "$link" in http*|/*) continue;; esac   # skip absolute / external
    if [ ! -f "$dir/$link" ]; then
      echo "  BROKEN $f -> $link"
      broken=$((broken+1))
    fi
  done < <(grep -oP '\]\(\K\.\.?/[^)#]+\.md' "$f" 2>/dev/null | sort -u)
done
if [ "$broken" -eq 0 ]; then echo "  OK: no broken relative .md links"; else fail=1; fi
echo

if [ "$fail" -eq 0 ]; then
  echo "RESULT: PASS"
else
  echo "RESULT: FAIL ($dangling dangling wikilinks, $broken broken relative links)"
fi
exit $fail
