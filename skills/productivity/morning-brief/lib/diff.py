"""Diff today's bundle against yesterday's.

CLI:
    uv run python lib/diff.py --state-dir DIR
Reads today's + yesterday's bundle-{date}.json, writes diff-{date}.json.
"""

from __future__ import annotations

import argparse
import json
from datetime import UTC, datetime
from pathlib import Path

from signals import _handoff_picked_up, _parse_date, handoff_age_bucket
from statefiles import prior_state_file


def _key_jira(item: dict) -> str:
    return item["key"]


def _key_pr(item: dict) -> str:
    return f"{item['repo']}#{item['number']}"


def _key_branch(item: dict) -> str:
    return f"{item['repo']}:{item['branch']}"


def _key_handoff(item: dict) -> str:
    return item["slug"]


def _key_stale_ref(item: dict) -> str:
    return f"{item['repo']}:{item['name']}"


def _flatten_stale_refs(stale_refs_repos: list[dict]) -> list[dict]:
    """Flatten stale_refs' per-repo branch/worktree candidates into one list,
    each tagged with its repo and a "name" (branch name or worktree path) so
    _diff_collection can key on repo+name across both kinds."""
    flat: list[dict] = []
    for repo in stale_refs_repos:
        repo_name = repo.get("repo")
        for branch in repo.get("stale_branches", []) or []:
            flat.append({**branch, "repo": repo_name, "name": branch.get("name")})
        for worktree in repo.get("stale_worktrees", []) or []:
            flat.append({**worktree, "repo": repo_name, "name": worktree.get("path")})
    return flat


def _diff_collection(
    today_items: list[dict], yesterday_items: list[dict], key_fn, ignore_keys: tuple[str, ...] = ()
) -> list[dict]:
    today_by_key = {key_fn(i): i for i in today_items}
    yesterday_by_key = {key_fn(i): i for i in yesterday_items}
    entries = []
    for key, after in today_by_key.items():
        before = yesterday_by_key.get(key)
        if before is None:
            entries.append({"kind": "new", "subject_ref": key, "before": None, "after": after})
        else:
            before_cmp = {k: v for k, v in before.items() if k not in ignore_keys}
            after_cmp = {k: v for k, v in after.items() if k not in ignore_keys}
            kind = "changed" if before_cmp != after_cmp else "unchanged"
            entries.append({"kind": kind, "subject_ref": key, "before": before, "after": after})
    for key, before in yesterday_by_key.items():
        if key not in today_by_key:
            entries.append(
                {"kind": "resolved", "subject_ref": key, "before": before, "after": None}
            )
    return entries


def compute_diff(today: dict, yesterday: dict | None) -> list[dict]:
    if yesterday is None:
        return []

    entries: list[dict] = []
    entries += _diff_collection(today.get("jira", []), yesterday.get("jira", []), _key_jira)
    entries += _diff_collection(
        today.get("github", {}).get("review_requested", []),
        yesterday.get("github", {}).get("review_requested", []),
        _key_pr,
    )
    entries += _diff_collection(
        today.get("github", {}).get("my_open_branches", []),
        yesterday.get("github", {}).get("my_open_branches", []),
        _key_branch,
        ignore_keys=("author",),
    )
    entries += _diff_collection(
        today.get("handoffs", []), yesterday.get("handoffs", []), _key_handoff
    )
    entries += _diff_collection(
        _flatten_stale_refs(today.get("stale_refs", [])),
        _flatten_stale_refs(yesterday.get("stale_refs", [])),
        _key_stale_ref,
    )
    return entries


def infer_handoff_state(handoff: dict, git_state_entry: dict | None, now: datetime) -> str:
    """Return one of: Picked up, Waiting, Open loop, Cold, Dangling, Untracked.

    Dangling/Untracked take priority as they are structural, not age-based;
    otherwise falls back to the shared age bucketing in signals.py.
    """
    branch = handoff.get("branch")
    if git_state_entry is not None and branch:
        branch_names = {b.get("name") for b in git_state_entry.get("branches", [])}
        if branch not in branch_names:
            return "Dangling"

    if not handoff.get("ticket"):
        return "Untracked"

    mtime = _parse_date(handoff.get("mtime"))
    if mtime is None:
        return "Waiting"
    age_days = (now.date() - mtime).days
    picked_up = _handoff_picked_up(handoff, git_state_entry, now)
    return handoff_age_bucket(age_days, picked_up)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--state-dir", required=True)
    args = parser.parse_args()

    state_dir = Path(args.state_dir)
    now = datetime.now(UTC).astimezone()
    today_str = now.strftime("%Y-%m-%d")

    today_bundle = json.loads((state_dir / f"bundle-{today_str}.json").read_text())
    # Not strictly yesterday: the last day the pipeline actually ran, so a
    # weekend or a day off does not empty the diff.
    prior = prior_state_file(state_dir, "bundle", now.date())
    prior_bundle = json.loads(prior[0].read_text()) if prior else None

    diff_entries = compute_diff(today_bundle, prior_bundle)

    out_path = state_dir / f"diff-{today_str}.json"
    out_path.write_text(json.dumps(diff_entries, indent=2))
    print(f"wrote {out_path}")


if __name__ == "__main__":
    main()
