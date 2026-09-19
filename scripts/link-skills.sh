#!/usr/bin/env bash
# Symlink chosen skills from this repo into ~/.claude/skills.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
DRY_RUN=0
FORCE=0

usage() {
  cat <<'EOF'
Usage: link-skills.sh [--dry-run] [--force] <name> [<name>...]
       link-skills.sh [--dry-run] [--force] --category <category>
       link-skills.sh --list

Links <repo>/skills/<category>/<name> to ~/.claude/skills/<name>.
Never deletes anything: an existing real directory is reported and skipped.

  --list       show every skill and whether it is linked
  --dry-run    print what would happen, change nothing
  --force      replace a symlink that points somewhere else
EOF
}

# Prints "category<TAB>name" for every skill in the repo.
all_skills() {
  for d in "$REPO"/skills/*/*/; do
    [ -f "$d/SKILL.md" ] || continue
    d="${d%/}"
    printf '%s\t%s\n' "$(basename "$(dirname "$d")")" "$(basename "$d")"
  done
}

status_of() {
  local name="$1" src="$2" link="$TARGET_DIR/$name"
  if [ -L "$link" ]; then
    if [ "$(readlink "$link")" = "$src" ]; then echo "linked"; else echo "linked elsewhere -> $(readlink "$link")"; fi
  elif [ -e "$link" ]; then
    echo "real directory in the way"
  else
    echo "not linked"
  fi
}

do_list() {
  all_skills | sort | while IFS=$'\t' read -r cat name; do
    printf '%-24s %-18s %s\n' "$name" "$cat" "$(status_of "$name" "$REPO/skills/$cat/$name")"
  done
}

link_one() {
  local name="$1" category src link
  category="$(all_skills | awk -F'\t' -v n="$name" '$2 == n { print $1; exit }')"
  if [ -z "$category" ]; then
    echo "not found: $name (no skills/*/$name in this repo)" >&2
    return 1
  fi
  src="$REPO/skills/$category/$name"
  link="$TARGET_DIR/$name"

  if [ -L "$link" ]; then
    if [ "$(readlink "$link")" = "$src" ]; then
      echo "already linked: $name"
      return 0
    fi
    if [ "$FORCE" -eq 0 ]; then
      echo "skipped: $name is a symlink to $(readlink "$link") — pass --force to repoint it"
      return 0
    fi
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "would repoint: $link -> $src"
      return 0
    fi
    rm "$link"
  elif [ -e "$link" ]; then
    echo "skipped: $link is a real directory — move it aside yourself, then rerun"
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    echo "would link: $link -> $src"
    return 0
  fi
  mkdir -p "$TARGET_DIR"
  ln -s "$src" "$link"
  echo "linked: $name ($category)"
}

names=()
category=""
while [ $# -gt 0 ]; do
  case "$1" in
    --help | -h) usage; exit 0 ;;
    --list) do_list; exit 0 ;;
    --dry-run) DRY_RUN=1 ;;
    --force) FORCE=1 ;;
    --category) category="${2:-}"; [ -n "$category" ] || { echo "error: --category needs a value" >&2; exit 2; }; shift ;;
    -*) usage >&2; exit 2 ;;
    *) names+=("$1") ;;
  esac
  shift
done

if [ -n "$category" ]; then
  if [ ! -d "$REPO/skills/$category" ]; then
    echo "error: no such category: $category" >&2
    exit 2
  fi
  while IFS=$'\t' read -r _ name; do names+=("$name"); done < <(all_skills | awk -F'\t' -v c="$category" '$1 == c')
fi

if [ "${#names[@]}" -eq 0 ]; then
  usage >&2
  exit 2
fi

failed=0
for n in "${names[@]}"; do
  link_one "$n" || failed=1
done
exit "$failed"
