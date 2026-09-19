#!/usr/bin/env python3
"""Filter stale_refs.sh JSON through the git-sweep ignore rules.

Reads the JSON on stdin, writes the filtered JSON to stdout, and reports what
it dropped on stderr so a suppressed ref is visible in the transcript rather
than silently gone.

Rule format, one per line: ``<repo>:<glob>``
  ``<repo>``  repo directory basename, or ``*`` for every repo
  ``<glob>``  fnmatch pattern, tested against a branch name and against a
              worktree path
Blank lines and ``#`` comments are ignored.

Rule files, both read when present, later file does not override earlier —
the union applies:
  <skill>/config/ignore.txt
  ~/.claude/skills/morning-brief/config/ignore.txt
"""

from __future__ import annotations

import fnmatch
import json
import os
import sys

SKILL_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RULE_FILES = [
    os.path.join(SKILL_DIR, "config", "ignore.txt"),
    # Shared with the morning brief on purpose: a ref the user has already
    # told the daily brief to stop mentioning must not resurface here as a
    # deletion candidate.
    os.path.expanduser("~/.claude/skills/morning-brief/config/ignore.txt"),
]


def load_rules() -> list[tuple[str, str, str]]:
    rules = []
    for path in RULE_FILES:
        if not os.path.exists(path):
            continue
        with open(path, encoding="utf-8") as fh:
            for line in fh:
                line = line.strip()
                if not line or line.startswith("#") or ":" not in line:
                    continue
                repo, _, glob = line.partition(":")
                rules.append((repo.strip(), glob.strip(), path))
    return rules


def matches(rules, repo_basename: str, *candidates: str):
    for repo, glob, source in rules:
        if repo not in ("*", repo_basename):
            continue
        for cand in candidates:
            if cand and fnmatch.fnmatch(cand, glob):
                return f"{repo}:{glob} ({os.path.basename(os.path.dirname(source))})"
    return None


def main() -> int:
    rules = load_rules()
    data = json.load(sys.stdin)
    dropped = []

    for entry in data.get("repos", []):
        basename = os.path.basename(entry.get("repo", ""))

        kept_branches = []
        for br in entry.get("stale_branches", []):
            hit = matches(rules, basename, br.get("name"), br.get("worktree_path"))
            if hit:
                dropped.append(f"branch {basename}:{br.get('name')} <- {hit}")
            else:
                kept_branches.append(br)
        entry["stale_branches"] = kept_branches

        kept_worktrees = []
        for wt in entry.get("stale_worktrees", []):
            hit = matches(rules, basename, wt.get("branch"), wt.get("path"))
            if hit:
                dropped.append(f"worktree {basename}:{wt.get('path')} <- {hit}")
            else:
                kept_worktrees.append(wt)
        entry["stale_worktrees"] = kept_worktrees

    json.dump(data, sys.stdout, indent=2)
    sys.stdout.write("\n")

    if dropped:
        sys.stderr.write("ignored by rule:\n  " + "\n  ".join(dropped) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
