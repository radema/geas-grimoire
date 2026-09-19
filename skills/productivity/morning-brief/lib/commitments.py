"""Load, verify, and persist commitments made in previous briefs.

CLI:
    uv run python lib/commitments.py --state-dir DIR
Reads yesterday's commitments-{yesterday}.json (if present), verifies each,
writes commitments-checked-{today}.json. If no prior file exists, writes []
and exits 0.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
from datetime import UTC, datetime
from pathlib import Path

from skillconfig import load_repos
from statefiles import prior_state_file

COLLECTORS_DIR = Path(__file__).resolve().parent.parent / "collectors"

# Basename -> absolute path, over the same watch list the collectors use.
KNOWN_REPOS = {Path(path).name: path for path in load_repos()}

_PR_ID_RE = re.compile(r"^(?:(?P<owner>[^/]+)/)?(?P<repo>[^#]+)#(?P<number>\d+)$")
_TEXT_PR_RE = re.compile(r"PR\s*#(\d+)")


def load_commitments(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return json.loads(path.read_text())


def _default_jira_check(key: str) -> str:
    proc = subprocess.run(
        ["uv", "run", "python", str(COLLECTORS_DIR / "jira.py"), "--check-keys", key],
        capture_output=True,
        text=True,
        timeout=20,
    )
    if proc.returncode != 0:
        raise RuntimeError(f"jira check failed: {proc.stderr.strip()[:200]}")
    payload = json.loads(proc.stdout)
    items = payload.get("items", [])
    if not items:
        return "unverified"
    return items[0].get("status", "unverified")


def _default_gh_check(pr_id: str) -> str:
    match = _PR_ID_RE.match(pr_id)
    if not match:
        raise ValueError(f"unrecognized PR id: {pr_id}")
    owner = match.group("owner")
    repo = match.group("repo")
    number = match.group("number")
    api_path = f"repos/{owner}/{repo}/pulls/{number}" if owner else f"repos/{repo}/pulls/{number}"
    proc = subprocess.run(
        ["gh", "api", api_path],
        capture_output=True,
        text=True,
        timeout=20,
    )
    if proc.returncode != 0:
        raise RuntimeError(f"gh api failed: {proc.stderr.strip()[:200]}")
    payload = json.loads(proc.stdout)
    # `state` is "closed" for a merged PR too; the brief needs the difference.
    if payload.get("merged_at"):
        return "merged"
    return payload.get("state", "unverified")


def _repo_slug(repo_path: str) -> str | None:
    """owner/repo for a local repo, from its `origin` remote. None if unresolvable."""
    proc = subprocess.run(
        ["git", "-C", repo_path, "remote", "get-url", "origin"],
        capture_output=True,
        text=True,
        timeout=10,
    )
    if proc.returncode != 0:
        return None
    match = re.search(r"github\.com[:/]([^/]+/[^/]+?)(\.git)?$", proc.stdout.strip())
    return match.group(1) if match else None


def _default_git_check(repo_path: str, since: str | None) -> str:
    since = since or "1 day ago"
    if repo_path not in KNOWN_REPOS.values() and repo_path not in KNOWN_REPOS:
        repo_path = KNOWN_REPOS.get(repo_path, repo_path)
    proc = subprocess.run(
        ["git", "-C", repo_path, "log", f"--since={since}", "--oneline"],
        capture_output=True,
        text=True,
        timeout=20,
    )
    if proc.returncode != 0:
        raise RuntimeError(f"git log failed: {proc.stderr.strip()[:200]}")
    return "active" if proc.stdout.strip() else "stale"


_JIRA_KEY_RE = re.compile(r"^[A-Z][A-Z0-9]+-\d+$")


def _identifiers(commitment: dict) -> dict:
    """The commitment's identifying detail, however the brief wrote it.

    Stage 2 writes an `identifiers` object; older files put the same keys at
    the top level. Both are read here, so the schema the skill documents and
    the schema this script verifies cannot drift apart again.
    """
    merged = {}
    for key in (
        "jira",
        "ticket",
        "keys",
        "repo",
        "branch",
        "pr",
        "prs",
        "person",
        "handoff_ref",
    ):
        if key in commitment:
            merged[key] = commitment[key]
    merged.update(commitment.get("identifiers") or {})
    return merged


def _jira_keys(ids: dict) -> list[str]:
    """Every Jira key the commitment names, from `keys`, `jira` or `ticket`."""
    found = []
    values = list(ids.get("keys") or [])
    values += [ids.get("jira"), ids.get("ticket")]
    for value in values:
        if isinstance(value, str) and _JIRA_KEY_RE.match(value.strip()):
            key = value.strip()
            if key not in found:
                found.append(key)
    return found


def _pr_ids(ids: dict) -> list[str]:
    """PR identifiers as `[owner/]repo#number`.

    Accepts both shapes the brief writes: full `owner/repo#number` strings,
    or bare numbers alongside a `repo`.
    """
    entries = ids.get("prs")
    if entries is None and ids.get("pr") is not None:
        entries = [ids["pr"]]
    if not entries:
        return []
    if not isinstance(entries, list):
        entries = [entries]
    repo = ids.get("repo")
    out = []
    for entry in entries:
        if isinstance(entry, str) and "#" in entry:
            out.append(entry)
        elif isinstance(repo, str):
            out.append(f"{repo}#{entry}")
    return out


def _repo_path(ids: dict) -> str | None:
    repo = ids.get("repo")
    if not isinstance(repo, str):
        return None
    if repo in KNOWN_REPOS:
        return KNOWN_REPOS[repo]
    if repo in KNOWN_REPOS.values():
        return repo
    # "some-org/some-repo" and the like: match on the basename.
    return KNOWN_REPOS.get(repo.rsplit("/", 1)[-1])


def _default_handoff_check(ref: str, since: str | None) -> str:
    """Did the named handoff thread move since the last brief?

    `ref` is whatever the brief recorded - a ticket key (PIPELINES-20260730)
    or a slug. Matched against both.
    """
    proc = subprocess.run(
        ["bash", str(COLLECTORS_DIR / "handoffs.sh")],
        capture_output=True,
        text=True,
        timeout=20,
    )
    if proc.returncode != 0:
        raise RuntimeError(f"handoffs collector failed: {proc.stderr.strip()[:200]}")
    handoffs = json.loads(proc.stdout).get("handoffs", [])
    match = next(
        (h for h in handoffs if ref in (h.get("ticket"), h.get("slug"))),
        None,
    )
    if match is None:
        return "handoff gone"
    mtime = (match.get("mtime") or "")[:10]
    if since and mtime and mtime > since:
        return f"moved {mtime}"
    return f"untouched since {mtime}" if mtime else "unverified"


def verify(
    commitment: dict,
    *,
    jira_check=None,
    gh_check=None,
    git_check=None,
    handoff_check=None,
    since=None,
) -> dict:
    jira_check = jira_check or _default_jira_check
    gh_check = gh_check or _default_gh_check
    git_check = git_check or _default_git_check
    handoff_check = handoff_check or _default_handoff_check

    result = dict(commitment)
    ids = _identifiers(commitment)

    ctype = commitment.get("type")
    cid = commitment.get("id")
    if ctype == "jira" and cid:
        result["status"] = jira_check(cid)
        return result
    if ctype == "pr" and cid:
        result["status"] = gh_check(cid)
        return result
    if ctype == "repo" and cid:
        result["status"] = git_check(cid, commitment.get("created") or since)
        return result

    # No explicit type: infer one from the identifying detail. A PR review is
    # the most specific claim a commitment can make, then a ticket, then "I
    # will touch this repo".
    pr_ids = _pr_ids(ids)
    if not pr_ids:
        # The `prs` field wasn't filled in, but the text names a PR number
        # ("Merge PR #24 ...") and a repo is known some other way (`repo`,
        # or the same handle `_repo_path` already resolves) — resolve its
        # owner/repo slug and check that PR too, rather than falling through
        # to a handoff/repo check that can't see PR state at all.
        text_match = _TEXT_PR_RE.search(commitment.get("text") or "")
        repo_path = _repo_path(ids)
        if text_match and repo_path:
            slug = _repo_slug(repo_path)
            if slug:
                pr_ids = [f"{slug}#{text_match.group(1)}"]
    if pr_ids:
        states = []
        for pr_id in pr_ids:
            number = pr_id.split("#")[-1]
            states.append(f"#{number} {gh_check(pr_id)}")
        result["status"] = ", ".join(states)
        return result

    keys = _jira_keys(ids)
    if keys:
        result["status"] = ", ".join(f"{key} {jira_check(key)}" for key in keys)
        return result

    handoff_ref = commitment.get("handoff_ref") or ids.get("handoff_ref")
    if isinstance(handoff_ref, str) and handoff_ref:
        result["status"] = handoff_check(handoff_ref, since)
        return result

    repo_path = _repo_path(ids)
    if repo_path:
        result["status"] = git_check(repo_path, commitment.get("created") or since)
        return result

    result["status"] = "unverified"
    return result


def verify_all(commitments: list[dict], **checkers) -> list[dict]:
    results = []
    for commitment in commitments:
        try:
            results.append(verify(commitment, **checkers))
        except Exception:
            result = dict(commitment)
            result["status"] = "unverified"
            results.append(result)
    return results


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--state-dir", required=True)
    args = parser.parse_args()

    state_dir = Path(args.state_dir)
    now = datetime.now(UTC).astimezone()
    today_str = now.strftime("%Y-%m-%d")

    # The last brief that actually ran, not strictly yesterday.
    prior = prior_state_file(state_dir, "commitments", now.date())
    commitments = load_commitments(prior[0]) if prior else []
    since = prior[1].isoformat() if prior else None

    checked = verify_all(commitments, since=since) if commitments else []
    for entry in checked:
        entry.setdefault("from_brief", since)

    out_path = state_dir / f"commitments-checked-{today_str}.json"
    out_path.write_text(json.dumps(checked, indent=2))
    print(f"wrote {out_path}")


if __name__ == "__main__":
    main()
