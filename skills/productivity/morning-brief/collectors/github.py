#!/usr/bin/env python3
"""GitHub Stage-1 collector.

Uses the already-authenticated `gh` CLI via subprocess -- no token handling
here. Prints exactly one JSON object to stdout, logs/errors to stderr.
A single repo failing (no remote, gh error, timeout) never crashes the run.
"""

import json
import os
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from datetime import UTC, datetime, timedelta
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "lib"))
from skillconfig import load_repos  # noqa: E402

# Repositories this collector watches -- absolute paths, from
# `config/repos.txt` or MORNING_BRIEF_REPOS; with neither, every git
# repository directly under $HOME.
REPOS = load_repos()
SUBPROCESS_TIMEOUT = 10


def run(cmd: list) -> str:
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=SUBPROCESS_TIMEOUT)
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or f"command failed: {' '.join(cmd)}")
    return result.stdout


def get_slug(repo_path: str) -> str:
    """Derive owner/repo from `git remote get-url origin`."""
    url = run(["git", "-C", repo_path, "remote", "get-url", "origin"]).strip()
    # handles both git@github.com:owner/repo.git and https://github.com/owner/repo.git
    match = re.search(r"github\.com[:/]([^/]+/[^/]+?)(\.git)?$", url)
    if not match:
        raise ValueError(f"not a github remote: {url}")
    return match.group(1)


def get_review_requested(slug: str) -> list:
    # Using `gh api search/issues` (simpler single call vs paginating pulls + filtering).
    query = f"is:pr is:open review-requested:@me repo:{slug}"
    out = run(["gh", "api", "-X", "GET", "search/issues", "-f", f"q={query}"])
    data = json.loads(out)
    items = []
    for item in data.get("items", []):
        items.append(
            {
                "repo": slug,
                "number": item.get("number"),
                "title": item.get("title"),
                "url": item.get("html_url"),
                "author": (item.get("user") or {}).get("login"),
                "updated_at": item.get("updated_at"),
            }
        )
    return items


BRANCH_AUTHOR_LOOKUP_CAP = 20  # a repo can have 100+ branches; one `gh api`
# call per branch to fetch its head commit author is too slow and risks
# GitHub rate limits, so we only resolve authors for the first N branches
# returned by the API (per repo). The rest get "author": null.


def get_branch_author(slug: str, sha: str) -> str | None:
    out = run(["gh", "api", f"repos/{slug}/commits/{sha}"])
    data = json.loads(out)
    commit_author = (data.get("commit") or {}).get("author") or {}
    return (data.get("author") or {}).get("login") or commit_author.get("name")


def _lookup_author(slug: str, sha: str | None) -> str | None:
    if not sha:
        return None
    try:
        return get_branch_author(slug, sha)
    except Exception:
        return None


def get_merged_since(slug: str, since: str) -> list:
    """PRs authored by the user and merged on or after `since` (YYYY-MM-DD).

    This is the "what did I actually finish" input; without it the brief can
    only report what is still open.
    """
    query = f"is:pr is:merged author:@me repo:{slug} merged:>={since}"
    out = run(["gh", "api", "-X", "GET", "search/issues", "-f", f"q={query}"])
    data = json.loads(out)
    items = []
    for item in data.get("items", []):
        items.append(
            {
                "repo": slug,
                "number": item.get("number"),
                "title": item.get("title"),
                "url": item.get("html_url"),
                "merged_at": (item.get("pull_request") or {}).get("merged_at"),
            }
        )
    return items


def get_branches(slug: str) -> list:
    out = run(["gh", "api", f"repos/{slug}/branches?per_page=100"])
    data = json.loads(out)
    shas = [(b.get("commit") or {}).get("sha") for b in data]
    authors = [None] * len(data)
    lookup_idx = [i for i in range(len(data)) if i < BRANCH_AUTHOR_LOOKUP_CAP]
    with ThreadPoolExecutor(max_workers=10) as executor:
        results = executor.map(lambda i: _lookup_author(slug, shas[i]), lookup_idx)
        for i, author in zip(lookup_idx, results, strict=True):
            authors[i] = author

    branches = []
    for i, b in enumerate(data):
        branches.append(
            {
                "repo": slug,
                "branch": b.get("name"),
                "sha": shas[i],
                "author": authors[i],
            }
        )
    return branches


def main():
    review_requested = []
    my_open_branches = []
    merged_since = []
    errors = []
    # The day the last brief ran; run.sh exports it. Absent (a manual call),
    # fall back to yesterday rather than reporting nothing.
    since = (
        os.environ.get("MORNING_BRIEF_SINCE")
        or (datetime.now(UTC).date() - timedelta(days=1)).isoformat()
    )

    for repo_path in REPOS:
        try:
            slug = get_slug(repo_path)
        except Exception as e:
            msg = f"{repo_path}: no usable github remote ({e})"
            print(msg, file=sys.stderr)
            errors.append(msg)
            continue

        try:
            review_requested.extend(get_review_requested(slug))
        except Exception as e:
            msg = f"{slug}: review-requested lookup failed ({e})"
            print(msg, file=sys.stderr)
            errors.append(msg)

        try:
            merged_since.extend(get_merged_since(slug, since))
        except Exception as e:
            msg = f"{slug}: merged-PR lookup failed ({e})"
            print(msg, file=sys.stderr)
            errors.append(msg)

        try:
            my_open_branches.extend(get_branches(slug))
        except Exception as e:
            msg = f"{slug}: branch lookup failed ({e})"
            print(msg, file=sys.stderr)
            errors.append(msg)

    print(
        json.dumps(
            {
                "review_requested": review_requested,
                "my_open_branches": my_open_branches,
                "merged_since": merged_since,
                "since": since,
                "ok": True,
                "error": "; ".join(errors) if errors else None,
            }
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
