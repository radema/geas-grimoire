"""Compute derived signals from a bundle. All date arithmetic lives here.

CLI:
    uv run python lib/signals.py --state-dir DIR
Reads today's bundle-{date}.json, writes signals-{date}.json (list of signal dicts)
alongside it.
"""

from __future__ import annotations

import argparse
import json
from datetime import UTC, date, datetime
from pathlib import Path

SEV_INFO = 0
SEV_WARN = 1
SEV_URGENT = 2


def _parse_date(value: str | None) -> date | None:
    """Best-effort parse of an ISO date/datetime string into a date."""
    if not value:
        return None
    try:
        return datetime.fromisoformat(value).date()
    except ValueError:
        try:
            return date.fromisoformat(value[:10])
        except ValueError:
            return None


def _ahead_count(track: str | None) -> int:
    """Commits a branch is ahead of its upstream, from git's %(upstream:track).

    Accepts the forms git emits: "[ahead 6]", "[ahead 2, behind 1]", "[behind
    19]", "[gone]", and "" (no upstream). Anything without an ahead count is 0.
    """
    if not track or "ahead " not in track:
        return 0
    tail = track.split("ahead ", 1)[1]
    digits = ""
    for ch in tail:
        if not ch.isdigit():
            break
        digits += ch
    return int(digits) if digits else 0


def handoff_age_bucket(age_days: int, picked_up: bool) -> str:
    """Shared age-bucketing for a handoff, reused by diff.infer_handoff_state.

    picked_up means a git_state recent_commit newer than the handoff's mtime
    was found on its repo (best-effort: recent_commits only covers ~1 day, so
    a handoff older than that window can't be verified as picked up from this
    data alone and is treated as not-picked-up).
    """
    if picked_up:
        return "Picked up"
    if age_days > 14:
        return "Cold"
    if 2 <= age_days <= 7:
        return "Open loop"
    return "Waiting"


def _handoff_picked_up(handoff: dict, git_state_entry: dict | None, _now: datetime) -> bool:
    if not git_state_entry:
        return False
    mtime = _parse_date(handoff.get("mtime"))
    if mtime is None:
        return False
    for commit in git_state_entry.get("recent_commits", []) or []:
        # recent_commits entries have no explicit date field in the contract
        # beyond being "recent" (collector's ~1 day window); presence of any
        # recent commit on the handoff's repo after its mtime date counts as
        # picked up.
        commit_date = _parse_date(commit.get("date")) if isinstance(commit, dict) else None
        if commit_date is not None and commit_date > mtime:
            return True
    return False


def attach_signals(bundle: dict, now: datetime) -> list[dict]:
    signals: list[dict] = []
    today = now.date()

    # Jira signals
    for item in bundle.get("jira", []):
        key = item.get("key")
        duedate = _parse_date(item.get("duedate"))
        if duedate == today:
            signals.append(
                {
                    "code": "due_today",
                    "severity": SEV_URGENT,
                    "subject_ref": f"jira:{key}",
                    "detail": f"{key} due today",
                }
            )
        if item.get("query") == "mine_stale":
            updated = _parse_date(item.get("updated"))
            if updated is not None and (today - updated).days >= 5:
                signals.append(
                    {
                        "code": "stale_5d",
                        "severity": SEV_URGENT,
                        "subject_ref": f"jira:{key}",
                        "detail": f"{key} not updated in {(today - updated).days}d",
                    }
                )
            else:
                signals.append(
                    {
                        "code": "stale_3d",
                        "severity": SEV_WARN,
                        "subject_ref": f"jira:{key}",
                        "detail": f"{key} stale (mine_stale query)",
                    }
                )

    # git_state signals
    # Heuristic: dirty_count > 0 always flags "dirty". The collector's
    # recent_commits only covers the last ~1 day, so we can't compute a real
    # "days since last commit". As a proxy: if the repo is dirty AND
    # recent_commits is empty (no commit activity in that 1-day window),
    # upgrade to dirty_2d. This under-detects staleness beyond 1 day but never
    # false-positives on a repo that was actively committed to today.
    for repo in bundle.get("git_state", []):
        repo_name = repo.get("repo")
        dirty_count = repo.get("dirty_count", 0)
        if dirty_count and dirty_count > 0:
            signals.append(
                {
                    "code": "dirty",
                    "severity": SEV_WARN,
                    "subject_ref": f"repo:{repo_name}",
                    "detail": f"{dirty_count} dirty file(s)",
                }
            )
            if not repo.get("recent_commits"):
                signals.append(
                    {
                        "code": "dirty_2d",
                        "severity": SEV_URGENT,
                        "subject_ref": f"repo:{repo_name}",
                        "detail": "dirty with no recent commits",
                    }
                )
        # unpushed_commits is the checked-out branch only. Other local branches
        # (including ones checked out in worktrees) are reported separately from
        # their own upstream_track, so their work is never attributed to the
        # branch the brief happens to name.
        current_branch = repo.get("branch")
        unpushed = repo.get("unpushed_commits", 0)
        if unpushed and unpushed > 0:
            signals.append(
                {
                    "code": f"unpushed:{unpushed}",
                    "severity": SEV_WARN,
                    "subject_ref": f"repo:{repo_name}",
                    "detail": f"{unpushed} unpushed commit(s) on {current_branch}",
                }
            )
        for br in repo.get("branches", []):
            name = br.get("name")
            if name == current_branch:
                continue
            ahead = _ahead_count(br.get("upstream_track", ""))
            if ahead:
                signals.append(
                    {
                        "code": f"unpushed_other:{ahead}",
                        "severity": SEV_WARN,
                        "subject_ref": f"repo:{repo_name}",
                        "detail": f"{ahead} unpushed commit(s) on {name}",
                    }
                )

    # stale_refs signals: INFO, not WARN -- clutter, not risk. One signal per
    # repo when any candidate exists, so the brief mentions it without
    # treating it as something urgent.
    for repo in bundle.get("stale_refs", []):
        repo_name = repo.get("repo")
        n_branches = len(repo.get("stale_branches", []) or [])
        n_worktrees = len(repo.get("stale_worktrees", []) or [])
        if n_branches or n_worktrees:
            signals.append(
                {
                    "code": f"stale_refs:{n_branches}/{n_worktrees}",
                    "severity": SEV_INFO,
                    "subject_ref": f"repo:{repo_name}",
                    "detail": f"{n_branches} stale branch(es), {n_worktrees} orphan worktree(s)",
                }
            )

    # Handoff signals
    git_state_by_repo = {r.get("repo"): r for r in bundle.get("git_state", [])}
    for handoff in bundle.get("handoffs", []):
        slug = handoff.get("slug")
        repo_name = handoff.get("repo")
        git_entry = git_state_by_repo.get(repo_name)
        mtime = _parse_date(handoff.get("mtime"))
        picked_up = _handoff_picked_up(handoff, git_entry, now)

        if mtime is not None:
            age_days = (today - mtime).days
            bucket = handoff_age_bucket(age_days, picked_up)
            if bucket == "Waiting":
                signals.append(
                    {
                        "code": "waiting",
                        "severity": SEV_INFO,
                        "subject_ref": f"handoff:{slug}",
                        "detail": f"{age_days}d old, not yet picked up",
                    }
                )
            elif bucket == "Open loop":
                signals.append(
                    {
                        "code": "open_loop_5d",
                        "severity": SEV_URGENT,
                        "subject_ref": f"handoff:{slug}",
                        "detail": f"{age_days}d old, not picked up",
                    }
                )
            elif bucket == "Cold":
                signals.append(
                    {
                        "code": "handoff_cold_14d",
                        "severity": SEV_INFO,
                        "subject_ref": f"handoff:{slug}",
                        "detail": f"{age_days}d old, cold",
                    }
                )

        branch = handoff.get("branch")
        branch_names = {b.get("name") for b in (git_entry or {}).get("branches", [])}
        if git_entry is not None and branch and branch not in branch_names:
            signals.append(
                {
                    "code": "handoff_dangling",
                    "severity": SEV_INFO,
                    "subject_ref": f"handoff:{slug}",
                    "detail": f"branch {branch} no longer exists",
                }
            )

        if not handoff.get("ticket"):
            signals.append(
                {
                    "code": "handoff_untracked",
                    "severity": SEV_INFO,
                    "subject_ref": f"handoff:{slug}",
                    "detail": "no linked ticket",
                }
            )

    return signals


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--state-dir", required=True)
    args = parser.parse_args()

    state_dir = Path(args.state_dir)
    now = datetime.now(UTC).astimezone()
    date_str = now.strftime("%Y-%m-%d")
    bundle_path = state_dir / f"bundle-{date_str}.json"
    bundle = json.loads(bundle_path.read_text())

    signals = attach_signals(bundle, now)

    out_path = state_dir / f"signals-{date_str}.json"
    out_path.write_text(json.dumps(signals, indent=2))
    print(f"wrote {out_path}")


if __name__ == "__main__":
    main()
