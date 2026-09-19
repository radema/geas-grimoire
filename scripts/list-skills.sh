#!/usr/bin/env bash
# Regenerate the README skill catalogue from what is on disk.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
README="$REPO/README.md"
BEGIN='<!-- BEGIN SKILLS -->'
END='<!-- END SKILLS -->'

usage() {
  cat <<'EOF'
Usage: list-skills.sh [--check | --stdout]

  (no args)  rewrite the catalogue between the markers in README.md
  --check    exit 1 with a diff if README.md is out of date
  --stdout   print the generated catalogue and touch nothing
EOF
}

# Reads name/description from the YAML frontmatter of every SKILL.md and
# prints "category<TAB>name<TAB>description".
# Categories kept out of the README catalogue. README.md is published to the
# public mirror, so listing a category that never publishes would leak exactly
# what publish-public.sh withholds: the brand skill descriptions name the
# company and its clients. They are catalogued in skills/brand/README.md, which
# is inside the withheld directory.
SKIP_CATEGORIES="brand"

collect() {
  for f in "$REPO"/skills/*/*/SKILL.md; do
    [ -e "$f" ] || continue
    category="$(basename "$(dirname "$(dirname "$f")")")"
    for skip in $SKIP_CATEGORIES; do
      [ "$category" = "$skip" ] && continue 2
    done
    awk -v cat="$category" '
      function flush() {
        if (done) return
        done = 1
        if (name != "") {
          gsub(/[ \t]+$/, "", desc)
          print cat "\t" name "\t" desc
        }
      }
      NR == 1 && $0 != "---" { exit }
      NR == 1 { next }
      $0 == "---" { flush(); exit }
      /^name:[ \t]*/ { sub(/^name:[ \t]*/, ""); name = $0; next }
      /^description:[ \t]*/ {
        sub(/^description:[ \t]*/, "")
        if ($0 == ">" || $0 == ">-" || $0 == "|" || $0 == "|-") { folded = 1; desc = "" }
        else { desc = $0 }
        next
      }
      folded && /^[ \t]+/ {
        line = $0
        sub(/^[ \t]+/, "", line)
        desc = (desc == "" ? line : desc " " line)
        next
      }
      { folded = 0 }
      END { flush() }
    ' "$f"
  done
}

# First sentence, or 160 chars, whichever comes first.
shorten() {
  awk '{
    s = $0
    gsub(/^["'"'"']|["'"'"']$/, "", s)
    if (match(s, /\. /)) s = substr(s, 1, RSTART)
    sub(/\.$/, ".", s)
    if (length(s) > 160) { s = substr(s, 1, 157); sub(/[ ,;]+$/, "", s); s = s "..." }
    print s
  }'
}

title_case() {
  echo "$1" | tr '-' ' ' | awk '{ for (i = 1; i <= NF; i++) $i = toupper(substr($i,1,1)) substr($i,2); print }'
}

generate() {
  local last=""
  collect | sort | while IFS=$'\t' read -r cat name desc; do
    if [ "$cat" != "$last" ]; then
      [ -n "$last" ] && echo
      echo "## $(title_case "$cat")"
      echo
      last="$cat"
    fi
    echo "- **$name** — $(printf '%s' "$desc" | shorten)"
  done
}

require_markers() {
  grep -qF "$BEGIN" "$README" && grep -qF "$END" "$README" && return 0
  echo "error: README.md has no '$BEGIN' / '$END' markers." >&2
  echo "Add both marker lines to README.md, then run this script again." >&2
  exit 1
}

current() {
  awk -v b="$BEGIN" -v e="$END" '
    $0 == b { inside = 1; next }
    $0 == e { inside = 0; next }
    inside { print }
  ' "$README"
}

mode="write"
case "${1:-}" in
  --help | -h) usage; exit 0 ;;
  --check) mode="check" ;;
  --stdout) mode="stdout" ;;
  "") ;;
  *) usage >&2; exit 2 ;;
esac

if [ "$mode" = "stdout" ]; then
  generate
  exit 0
fi

require_markers
new="$(mktemp)"
old="$(mktemp)"
trap 'rm -f "$new" "$old"' EXIT
generate > "$new"
# Strip the blank padding lines we add around the block before comparing.
current | sed '1{/^$/d}; ${/^$/d}' > "$old"

if [ "$mode" = "check" ]; then
  if diff -u "$old" "$new" > /dev/null; then
    echo "README.md skill catalogue is up to date."
    exit 0
  fi
  echo "README.md skill catalogue is out of date:"
  diff -u --label README.md --label generated "$old" "$new" || true
  exit 1
fi

out="$(mktemp)"
awk -v b="$BEGIN" -v e="$END" -v f="$new" '
  $0 == b { print; print ""; while ((getline line < f) > 0) print line; print ""; inside = 1; next }
  $0 == e { inside = 0 }
  !inside { print }
' "$README" > "$out"
mv "$out" "$README"
echo "README.md catalogue updated ($(grep -c '^- \*\*' "$new") skills)."
