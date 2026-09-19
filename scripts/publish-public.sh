#!/usr/bin/env bash
# Decide what may reach the PUBLIC mirror of this repo.
# Allowlist first, then a report of everything it skipped, then a content scan.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"

# Only these paths are ever published. The company brand category is
# deliberately missing and must stay missing.
#
# pyproject.toml and .python-version stay out on purpose: there are no
# dependencies to install, and pyproject.toml carries the author's real name,
# which the denylist scan is built to stop.
ALLOW="
skills/data-engineering
skills/engineering
skills/experimenting
skills/productivity
skills/archive
agents
hooks
scripts
docs
LICENSES
archive
README.md
AGENTS.md
LICENSE
.gitignore
"

# Patterns that must never appear in published content. Written in pieces so
# this script does not trip its own scan.
PAT_BRAND="skills""/brand"
PAT_JIRA='\b(IT|CIV)-[0-9]+\b'
PAT_MAIL='@openeconomics''\.eu'
# Private repository and people names. These were missing on 2026-09-19 and the
# scan reported "clean" over a payload that carried them in 17 files — an empty
# result only means the patterns did not match, never that the payload is safe.
#
# They live in their own file, which is itself excluded from the payload: a list
# of private names is not something to publish, and inlining it here made the
# script trip its own scan. A missing file is a hard error, never an empty
# pattern that would quietly match nothing.
NAMES_FILE="$REPO/scripts/denylist-names.txt"
if [ ! -f "$NAMES_FILE" ]; then
  echo "error: $NAMES_FILE is missing. Refusing to scan with no names." >&2
  exit 2
fi
PAT_NAMES="$(grep -vE '^\s*(#|$)' "$NAMES_FILE" | sed 's/[[:space:]]\+/ ?/g' | paste -sd'|' -)"
if [ -z "$PAT_NAMES" ]; then
  echo "error: $NAMES_FILE lists no names. Refusing to scan with no names." >&2
  exit 2
fi
PAT_NAMES="\\b($PAT_NAMES)\\b"

TO_DIR=""
ASSUME_YES=0

usage() {
  cat <<'EOF'
Usage: publish-public.sh [--yes] [--to <dir>]

  (no args)  dry run: print the payload, the skipped paths and the scan result
  --to <dir> copy the payload into an existing checkout of the public repo
             (no clone, no commit, no push — you do those)
  --yes      accept the skipped-paths report and keep going
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --help | -h) usage; exit 0 ;;
    --yes) ASSUME_YES=1 ;;
    --to) TO_DIR="${2:-}"; [ -n "$TO_DIR" ] || { echo "error: --to needs a directory" >&2; exit 2; }; shift ;;
    *) usage >&2; exit 2 ;;
  esac
  shift
done

cd "$REPO"

# Paths that are inside an allowed directory but must still never publish.
# docs/design holds the decision map: an internal record that quotes real Jira
# keys and names company material, which is exactly what the denylist catches.
DENY_PATHS="
docs/design
scripts/denylist-names.txt
"

is_allowed() {
  local path="$1" a d
  for d in $DENY_PATHS; do
    [ "$path" = "$d" ] && return 1
    case "$path" in "$d"/*) return 1 ;; esac
  done
  for a in $ALLOW; do
    [ "$path" = "$a" ] && return 0
    case "$path" in "$a"/*) return 0 ;; esac
  done
  return 1
}

# Every file git knows about, ignored files excluded.
ALL_FILES="$(mktemp)"
PAYLOAD="$(mktemp)"
hits="$(mktemp)"
trap 'rm -f "$ALL_FILES" "$PAYLOAD" "$hits"' EXIT
git ls-files -z --cached --others --exclude-standard | tr '\0' '\n' > "$ALL_FILES"

while IFS= read -r f; do
  is_allowed "$f" && printf '%s\n' "$f"
done < "$ALL_FILES" > "$PAYLOAD"

count="$(wc -l < "$PAYLOAD" | tr -d ' ')"
echo "== payload =="
echo "$count files from:"
for a in $ALLOW; do
  n="$(grep -c -E "^$a(/|$)" "$PAYLOAD" || true)"
  if [ "$n" -gt 0 ]; then printf '  %-28s %s files\n' "$a" "$n"; fi
done

# Layer 2 — say out loud what is being left behind. `skills` is reported one
# level deeper because the allowlist works per category.
echo
echo "== not published =="
unlisted=0
while IFS= read -r top; do
  is_allowed "$top" && continue
  echo "not published: $top  (add to ALLOW in this script, or ignore)"
  unlisted=1
done < <(awk -F/ '{ print ($1 == "skills" && NF > 1) ? $1 "/" $2 : $1 }' "$ALL_FILES" | sort -u)
if [ "$unlisted" -eq 0 ]; then echo "(nothing — every top-level path is allowlisted)"; fi

# Layer 3 — scan the payload itself.
echo
echo "== denylist scan =="
if [ "$count" -eq 0 ]; then
  echo "ERROR: payload is empty — nothing was scanned, this is not a pass."
  exit 1
fi


# Content scan. Deliberately NOT the brand path — documenting the rule
# ("skills/brand never publishes") is not a leak, and matching the string in
# prose made every doc explaining the policy a hit. The brand guard that matters
# is the path check below: no brand FILE in the payload.
#
# No -I: a binary under an allowed directory must NOT be skipped silently. The
# thing this repo is cleaning up is a brand-manual PDF that went public, and -I
# would wave exactly that through. Binaries are reported separately instead.
while IFS= read -r f; do
  grep -inHE "$PAT_JIRA|$PAT_MAIL|$PAT_NAMES" -- "$f" 2>/dev/null >> "$hits" || true
done < "$PAYLOAD"
grep -E "^$PAT_BRAND(/|$)" "$PAYLOAD" | sed 's/$/:0: brand file inside the payload/' >> "$hits" || true

# Any non-text file in the payload is flagged for a human to look at: a scan
# cannot judge an image or a PDF, and silence about it is not evidence.
while IFS= read -r f; do
  # -s first: an empty file has nothing to leak, but `grep -qI .` cannot tell it
  # apart from a binary (both give no matching line), so it would report forever.
  if [ -f "$f" ] && [ -s "$f" ] && ! grep -qI . -- "$f" 2>/dev/null; then
    printf '%s:0: binary file in the payload — check it by hand\n' "$f" >> "$hits"
  fi
done < "$PAYLOAD"

echo "scanned $count files"
if [ -s "$hits" ]; then
  echo "REFUSING TO PUBLISH — forbidden content found:"
  sort -u "$hits"
  exit 1
fi
echo "clean: no brand paths, no Jira keys, no company addresses, no private repo"
echo "       or people names, no unchecked binaries"

if [ "$unlisted" -eq 1 ] && [ "$ASSUME_YES" -eq 0 ]; then
  echo
  echo "Stopping: some top-level paths are not in the allowlist (see above)."
  echo "Check the list, then rerun with --yes."
  exit 2
fi

echo
if [ -z "$TO_DIR" ]; then
  echo "Dry run — nothing was written. Rerun with --to <public-repo-checkout> to copy."
  exit 0
fi

if [ ! -d "$TO_DIR" ]; then
  echo "error: --to '$TO_DIR' is not an existing directory. Clone the public repo yourself first." >&2
  exit 2
fi

if [ ! -d "$TO_DIR/.git" ]; then
  echo "error: '$TO_DIR' is not a git checkout. Refusing to write into it." >&2
  exit 2
fi

# Mirror, do not merge. Copying on top would leave behind any file that has since
# been dropped from the allowlist — it would stay published forever, and a
# `git add -A` in the checkout would not notice because the file is still there.
# So clear the working tree first (never .git) and let the copy define the tree.
find "$TO_DIR" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +

while IFS= read -r f; do
  mkdir -p "$TO_DIR/$(dirname "$f")"
  cp -Pp "$f" "$TO_DIR/$f"
done < "$PAYLOAD"

echo "Copied $count files into $TO_DIR (working tree mirrored, not merged)."
echo "Next, do this yourself:"
echo "  cd $TO_DIR && git status        # look at what changed"
echo "  git add -A && git commit && git push"
