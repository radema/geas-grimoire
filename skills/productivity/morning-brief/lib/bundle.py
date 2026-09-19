"""Run morning-brief collectors and merge their output into a single bundle file.

CLI:
    uv run python lib/bundle.py --state-dir DIR [--timeout N] [--no-fetch] [--only REPO] [--dry-run]
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from datetime import UTC, datetime
from fnmatch import fnmatch
from pathlib import Path

LIB_DIR = Path(__file__).resolve().parent
COLLECTORS_DIR = LIB_DIR.parent / "collectors"

# Empty placeholder shape for each source, used when a collector fails.
_EMPTY_PAYLOAD = {
    "jira": {"items": [], "queries_run": [], "ok": False, "error": None},
    "github": {
        "review_requested": [],
        "my_open_branches": [],
        "merged_since": [],
        "ok": False,
        "error": None,
    },
    "git_state": {"repos": []},
    "handoffs": {"handoffs": [], "tmp_handoffs_found": []},
    "stale_refs": {"repos": []},
}

# The main list/array whose length is reported as "count" for each source.
_COUNT_KEY = {
    "jira": "items",
    "github": "review_requested",
    "git_state": "repos",
    "handoffs": "handoffs",
    "stale_refs": "repos",
}


def _run_one(name: str, argv: list[str], timeout_s: int) -> tuple[dict, dict]:
    """Run a single collector. Returns (payload, source_status)."""
    start = time.monotonic()
    try:
        proc = subprocess.run(argv, capture_output=True, text=True, timeout=timeout_s)
        elapsed_ms = int((time.monotonic() - start) * 1000)
        if proc.returncode != 0:
            return (
                dict(_EMPTY_PAYLOAD[name]),
                {
                    "ok": False,
                    "error": f"exit {proc.returncode}: {proc.stderr.strip()[:200]}",
                    "ms": None,
                    "count": 0,
                },
            )
        try:
            payload = json.loads(proc.stdout)
        except json.JSONDecodeError as exc:
            return (
                dict(_EMPTY_PAYLOAD[name]),
                {"ok": False, "error": f"invalid JSON: {exc}", "ms": None, "count": 0},
            )
        count = len(payload.get(_COUNT_KEY[name], []))
        return (payload, {"ok": True, "ms": elapsed_ms, "error": None, "count": count})
    except subprocess.TimeoutExpired:
        return (
            dict(_EMPTY_PAYLOAD[name]),
            {"ok": False, "error": f"timeout after {timeout_s}s", "ms": None, "count": 0},
        )
    except OSError as exc:
        return (
            dict(_EMPTY_PAYLOAD[name]),
            {"ok": False, "error": str(exc), "ms": None, "count": 0},
        )


def run_collectors(specs: list[tuple[str, list[str]]], timeout_s: int = 20) -> dict:
    """Run each (name, argv) collector spec in parallel.

    Returns {"sources": {name: {...status...}}, "data": {name: payload}}.
    """
    sources: dict = {}
    data: dict = {}
    with ThreadPoolExecutor(max_workers=max(1, len(specs))) as pool:
        futures = {pool.submit(_run_one, name, argv, timeout_s): name for name, argv in specs}
        for fut in futures:
            name = futures[fut]
            payload, status = fut.result()
            data[name] = payload
            sources[name] = status
    return {"sources": sources, "data": data}


IGNORE_FILE = LIB_DIR.parent / "config" / "ignore.txt"


def load_ignore_rules(path: Path = IGNORE_FILE) -> list[tuple[str, str]]:
    """Parse config/ignore.txt into (repo, glob) rules. Missing file: no rules."""
    if not path.exists():
        return []
    rules = []
    for raw in path.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or ":" not in line:
            continue
        repo, _, pattern = line.partition(":")
        rules.append((repo.strip(), pattern.strip()))
    return rules


def _ignored(repo_path: str, name: str, rules: list[tuple[str, str]]) -> bool:
    basename = Path(repo_path or "").name
    return any(
        (repo in ("*", basename, repo_path)) and fnmatch(name or "", pattern)
        for repo, pattern in rules
    )


def apply_ignore(
    git_state: list[dict], stale_refs: list[dict], rules: list[tuple[str, str]]
) -> None:
    """Drop ignored branches and worktrees, in place.

    Done here rather than in the collectors so both bash collectors stay
    read-only and single-purpose, and so one file governs what the brief is
    allowed to mention.
    """
    if not rules:
        return
    for repo in git_state:
        path = repo.get("repo", "")
        repo["branches"] = [
            b for b in repo.get("branches", []) or [] if not _ignored(path, b.get("name"), rules)
        ]
    for repo in stale_refs:
        path = repo.get("repo", "")
        repo["stale_branches"] = [
            b
            for b in repo.get("stale_branches", []) or []
            if not _ignored(path, b.get("name"), rules)
        ]
        repo["stale_worktrees"] = [
            w
            for w in repo.get("stale_worktrees", []) or []
            if not _ignored(path, w.get("path"), rules)
        ]


def write_bundle(merged: dict, out_dir: Path, date_str: str) -> Path:
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f"bundle-{date_str}.json"
    out_path.write_text(json.dumps(merged, indent=2))
    return out_path


def _build_specs(no_fetch: bool) -> list[tuple[str, list[str]]]:
    git_state_argv = ["bash", str(COLLECTORS_DIR / "git_state.sh")]
    stale_refs_argv = ["bash", str(COLLECTORS_DIR / "stale_refs.sh")]
    if no_fetch:
        git_state_argv.append("--no-fetch")
        stale_refs_argv.append("--no-fetch")
    return [
        ("jira", ["uv", "run", "python", str(COLLECTORS_DIR / "jira.py")]),
        ("github", ["uv", "run", "python", str(COLLECTORS_DIR / "github.py")]),
        ("git_state", git_state_argv),
        ("handoffs", ["bash", str(COLLECTORS_DIR / "handoffs.sh")]),
        ("stale_refs", stale_refs_argv),
    ]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--state-dir", required=True)
    # github.py's sequential per-repo `gh api` calls (slug + review-requested +
    # branch list + author lookups) measured 26-30s worst case across 4 repos;
    # 45s gives margin without masking a genuinely hung collector.
    parser.add_argument("--timeout", type=int, default=45)
    parser.add_argument("--no-fetch", action="store_true")
    parser.add_argument(
        "--only", default=None, help="Filter git_state repos to a single repo path/name"
    )
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    state_dir = Path(args.state_dir)
    specs = _build_specs(args.no_fetch)
    result = run_collectors(specs, timeout_s=args.timeout)
    data = result["data"]
    sources = result["sources"]

    git_state_repos = data["git_state"].get("repos", [])
    if args.only:
        git_state_repos = [r for r in git_state_repos if args.only in r.get("repo", "")]

    stale_refs_repos = data["stale_refs"].get("repos", [])
    if args.only:
        stale_refs_repos = [r for r in stale_refs_repos if args.only in r.get("repo", "")]

    apply_ignore(git_state_repos, stale_refs_repos, load_ignore_rules())

    now = datetime.now(UTC).astimezone()
    date_str = now.strftime("%Y-%m-%d")
    bundle = {
        "generated_at": now.isoformat(),
        "date": date_str,
        "sources": sources,
        "jira": data["jira"].get("items", []),
        "since": os.environ.get("MORNING_BRIEF_SINCE"),
        "github": {
            "review_requested": data["github"].get("review_requested", []),
            "my_open_branches": data["github"].get("my_open_branches", []),
            "merged_since": data["github"].get("merged_since", []),
        },
        "git_state": git_state_repos,
        "handoffs": data["handoffs"].get("handoffs", []),
        "stale_refs": stale_refs_repos,
    }

    out_path = write_bundle(bundle, state_dir, date_str)

    if args.dry_run:
        print(f"[dry-run] wrote {out_path}", file=sys.stderr)
        for name, status in sources.items():
            print(
                f"  {name}: ok={status['ok']} count={status['count']} error={status['error']}",
                file=sys.stderr,
            )
    else:
        print(f"wrote {out_path}", file=sys.stderr)


if __name__ == "__main__":
    main()
