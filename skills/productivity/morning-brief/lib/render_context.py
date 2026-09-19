"""Render bundle + signals + diff + commitments into context.md, deterministically.

CLI:
    uv run python lib/render_context.py --state-dir DIR --out PATH
"""

from __future__ import annotations

import argparse
import json
import re
from datetime import UTC, date, datetime
from pathlib import Path

from statefiles import prior_state_file

SECRETS_PATH = Path("/root/.config/morning-brief/secrets.env")


# Simple env-file secret loader duplicated here (rather than importing
# collectors/jira.py) to keep lib/ independent of collectors/ ordering during
# build. Parses KEY=VALUE lines, ignores blanks/comments, strips quotes.
def load_secrets(path: Path = SECRETS_PATH) -> dict[str, str]:
    if not path.exists():
        return {}
    secrets: dict[str, str] = {}
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        secrets[key.strip()] = value.strip().strip('"').strip("'")
    return secrets


_BEARER_RE = re.compile(r"Bearer\s+\S+")
_AUTH_HEADER_RE = re.compile(r"Authorization:\s*\S+")

# Spec's original ~4KB target assumed bare ticket keys with no summary text;
# richer per-item detail (ticket summaries, commit subjects, handoff
# excerpts) legitimately needs more room, and the line-count target was
# explicitly not a hard requirement. 16KB still comfortably bounds token
# cost for the Stage-2 model call.
MAX_BYTES = 16384


def redact(text: str, secret_values: list[str]) -> str:
    for value in secret_values:
        if value:
            text = text.replace(value, "[REDACTED]")
    text = _BEARER_RE.sub("Bearer [REDACTED]", text)
    return _AUTH_HEADER_RE.sub("Authorization: [REDACTED]", text)


def _signals_for(signals: list[dict], subject_ref: str) -> list[str]:
    return [s["code"] for s in signals if s.get("subject_ref") == subject_ref]


# An unassigned ticket younger than this is still an open question about
# who takes it; older than this it is backlog.
UNOWNED_FRESH_DAYS = 3


def _parse_ymd(value: str | None) -> date | None:
    """Parse a bare YYYY-MM-DD, or the leading date of an ISO timestamp."""
    if not value:
        return None
    try:
        return datetime.strptime(value[:10], "%Y-%m-%d").date()
    except ValueError:
        return None


def _jira_owner_bucket(item: dict) -> str:
    """Classify a Jira item by who actually owns it.

    Derived from the collector's JQL semantics, not from a name match, so it
    needs no knowledge of the user's own display name:

    - `team_unowned` selects `assignee IS EMPTY`, so a null assignee is
      unowned.
    - `mine_created_assigned_other` selects `reporter = currentUser() AND
      assignee != currentUser()`, so membership means someone else owns it.
    - anything else with an assignee was selected by an `assignee =
      currentUser()` clause, so it is the user's own.

    An item can match several queries, and the collector comma-joins the
    names -- split before testing membership.
    """
    if not item.get("assignee"):
        return "unowned"
    queries = (item.get("query") or "").split(",")
    if "mine_created_assigned_other" in queries:
        return "other"
    return "mine"


def _jira_age_note(item: dict, today: date | None) -> str:
    """`[123d, due 2026-03-22 overdue]` -- staleness and deadline, or ''.

    Both facts come straight from the collector's `updated` and `duedate`
    fields. Without them Stage 2 cannot tell a ticket that moved yesterday
    from one untouched for six months, and has no basis for the "going
    cold" and due-date judgements the brief format asks it to make.
    """
    if today is None:
        return ""
    parts = []
    updated = _parse_ymd(item.get("updated"))
    if updated is not None:
        parts.append(f"{(today - updated).days}d")
    duedate = _parse_ymd(item.get("duedate"))
    if duedate is not None:
        overdue = " overdue" if duedate < today else ""
        parts.append(f"due {duedate.isoformat()}{overdue}")
    return f"  [{', '.join(parts)}]" if parts else ""


def _render_jira(items: list[dict], signals: list[dict], today: date | None) -> list[str]:
    """Render the Jira items grouped by owner, with staleness per line.

    Grouping is the point: a flat list gives Stage 2 no way to tell a ticket
    the user must act on from one they merely filed for a colleague, and it
    will describe the whole list as the user's board.
    """
    buckets: dict[str, list[dict]] = {"mine": [], "other": [], "unowned": []}
    for item in items:
        buckets[_jira_owner_bucket(item)].append(item)

    def line(item: dict) -> str:
        codes = _signals_for(signals, f"jira:{item.get('key')}")
        suffix = f"  {', '.join(codes)}" if codes else ""
        summary = item.get("summary") or ""
        note = _jira_age_note(item, today)
        return f"- {item.get('key')}  {item.get('status')}  {summary}{note}{suffix}"

    out: list[str] = []
    if buckets["mine"]:
        out.append(f"### Assigned to you ({len(buckets['mine'])})")
        out.extend(line(i) for i in buckets["mine"])
    if buckets["other"]:
        out.append(f"### You reported, owned by someone else ({len(buckets['other'])})")
        by_owner: dict[str, list[dict]] = {}
        for item in buckets["other"]:
            by_owner.setdefault(item.get("assignee") or "unknown", []).append(item)
        for owner in sorted(by_owner):
            out.append(f"- {owner}:")
            out.extend(f"  {line(i)}" for i in by_owner[owner])
    if buckets["unowned"]:
        # An unowned ticket filed days ago is a backlog fact, not news; one
        # filed in the last few days is a live decision about who picks it
        # up. Give the fresh ones the full line and compress the rest, so
        # the group stays scannable without hiding anything.
        fresh, older = [], []
        for item in buckets["unowned"]:
            created = _parse_ymd(item.get("created"))
            age = (today - created).days if (today and created) else None
            (fresh if age is not None and age <= UNOWNED_FRESH_DAYS else older).append(item)
        if fresh:
            out.append(
                f"### Unassigned, filed in the last {UNOWNED_FRESH_DAYS} days ({len(fresh)}) — need an assignee"
            )
            out.extend(line(i) for i in fresh)
        if older:
            out.append(f"### Unassigned, older ({len(older)})")
            out.extend(f"- {i.get('key')}  {i.get('summary') or ''}" for i in older)
    return out


def _render_diff_line(entry: dict) -> str:
    kind = entry["kind"]
    ref = entry["subject_ref"]
    if kind == "new":
        return f"new: {ref}"
    if kind == "resolved":
        return f"resolved: {ref}"
    if kind == "changed":
        return f"changed: {ref}"
    return f"unchanged: {ref}"


def _stale_branch_proposal(branch: dict) -> str:
    reason = branch.get("reason")
    name = branch.get("name")
    if reason == "gone":
        return f"git branch -D {name}"
    if reason == "old_no_upstream":
        return f"review — local-only work, git branch -D {name} only after user checks"
    return f"git branch -d {name}"


def _stale_worktree_proposal(worktree: dict) -> str:
    if worktree.get("blocked"):
        return "inspect first, do not remove"
    return f"git worktree remove {worktree.get('path')}"


BOT_MARKER = "[bot]"
COMMIT_SUBJECTS_PER_REPO = 5
MERGED_PRS_SHOWN = 8


def _render_since_last_brief(bundle: dict) -> list[str]:
    """What actually happened between the last brief and this one.

    Commits (bot commits excluded - dependabot is not work the reader did),
    PRs merged, and handoff threads that moved. Without this section the
    brief can only describe what is still open, never what was finished.
    """
    since = bundle.get("since")
    if not since:
        return []

    lines: list[str] = []

    for repo in bundle.get("git_state", []) or []:
        commits = [
            c
            for c in (repo.get("recent_commits") or [])
            if BOT_MARKER not in (c.get("author") or "")
        ]
        if not commits:
            continue
        head = f"- {repo.get('repo')}  {len(commits)} commit(s)"
        lines.append(head)
        for commit in commits[:COMMIT_SUBJECTS_PER_REPO]:
            lines.append(f"  - {commit.get('date')}  {commit.get('subject')}")
        remaining = len(commits) - COMMIT_SUBJECTS_PER_REPO
        if remaining > 0:
            lines.append(f"  - and {remaining} more")

    for pr in bundle.get("github", {}).get("merged_since", []) or []:
        merged_at = (pr.get("merged_at") or "")[:10]
        lines.append(
            f"- merged {pr.get('repo')} #{pr.get('number')}  {pr.get('title')}  {merged_at}"
        )

    for handoff in bundle.get("handoffs", []) or []:
        mtime = (handoff.get("mtime") or "")[:10]
        if mtime and mtime >= since:
            lines.append(f'- handoff "{handoff.get("title")}" updated {mtime}')

    if not lines:
        return [f"- nothing recorded since {since}"]
    return lines


def render(
    bundle: dict,
    signals: list[dict],
    diffs: list[dict],
    handoff_states: dict[str, str],
    checked_commitments: list[dict],
    degraded_sources: list[str],
) -> str:
    md = _render_raw(bundle, signals, diffs, handoff_states, checked_commitments, degraded_sources)
    if len(md.encode("utf-8")) > MAX_BYTES:
        md = _truncate(
            bundle, signals, diffs, handoff_states, checked_commitments, degraded_sources
        )
    return md


def _render_raw(
    bundle: dict,
    signals: list[dict],
    diffs: list[dict],
    handoff_states: dict[str, str],
    checked_commitments: list[dict],
    _degraded_sources: list[str],
    include_stale_refs: bool = True,
) -> str:
    """Build the markdown with no size check -- callers that need the
    truncation fallback call this directly to avoid recursing back into
    render()'s own size check."""
    date_str = bundle.get("date", "")
    today = _parse_ymd(date_str)
    lines: list[str] = [f"# Morning Brief — {date_str}", ""]

    # `outcome` is a more specific, already-settled fact than the generic
    # recomputed `status` (e.g. "already merged 2026-09-08 ... nothing to
    # do" vs. a stale-handoff-mtime fallback) — prefer it when present.
    commitment_lines = [
        f"- {c.get('text')} → {c.get('outcome') or c.get('status')}" for c in checked_commitments
    ]
    if commitment_lines:
        # Named by date, because the last brief is not always yesterday's.
        from_brief = next(
            (c.get("from_brief") for c in checked_commitments if c.get("from_brief")), None
        )
        heading = "## Commitments from the last brief"
        if from_brief:
            heading += f" ({from_brief})"
        lines.append(heading)
        lines.extend(commitment_lines)
        lines.append("")

    since_lines = _render_since_last_brief(bundle)
    if since_lines:
        lines.append(f"## Since last brief ({bundle.get('since')})")
        lines.extend(since_lines)
        lines.append("")

    jira_items = bundle.get("jira", [])
    if jira_items:
        lines.append(f"## Jira ({len(jira_items)})")
        lines.extend(_render_jira(jira_items, signals, today))
        lines.append("")

    prs = bundle.get("github", {}).get("review_requested", [])
    pr_lines = [
        f"- {pr.get('repo')} #{pr.get('number')}  {pr.get('title')}  author {pr.get('author')}"
        for pr in prs
    ]
    if pr_lines:
        lines.append(f"## PRs needing you ({len(prs)})")
        lines.extend(pr_lines)
        lines.append("")

    repos = bundle.get("git_state", [])
    if repos:
        lines.append("## Repositories")
        for repo in repos:
            repo_name = repo.get("repo")
            branch = repo.get("branch")
            codes = _signals_for(signals, f"repo:{repo_name}")
            suffix = f"  {', '.join(codes)}" if codes else ""
            recent = repo.get("recent_commits") or []
            last_subject = f"  last: {recent[0].get('subject')}" if recent else ""
            lines.append(f"- {repo_name}  {branch}{suffix}{last_subject}")
        lines.append("")

    if include_stale_refs:
        stale_lines = []
        for repo in bundle.get("stale_refs", []):
            repo_name = repo.get("repo")
            for b in repo.get("stale_branches", []) or []:
                stale_lines.append(
                    f"- {repo_name}  branch {b.get('name')}  {b.get('reason')}  "
                    f"{b.get('age_days')}d  [ahead {b.get('ahead', 0)}]  → {_stale_branch_proposal(b)}"
                )
            for w in repo.get("stale_worktrees", []) or []:
                blocked = w.get("blocked")
                tag = ""
                if blocked == "locked":
                    tag = "  [locked]"
                elif blocked == "dirty":
                    tag = f"  [dirty:{w.get('dirty_count', 0)}]"
                stale_lines.append(
                    f"- {repo_name}  worktree {w.get('path')}  {w.get('reason')}  "
                    f"{w.get('age_days')}d{tag}  → {_stale_worktree_proposal(w)}"
                )
        if stale_lines:
            lines.append("## Stale refs")
            lines.extend(stale_lines)
            lines.append("")

    handoffs = bundle.get("handoffs", [])
    handoff_lines = []
    for handoff in handoffs:
        slug = handoff.get("slug")
        state = handoff_states.get(slug, "Waiting")
        ticket = handoff.get("ticket") or "untracked"
        line = f'- "{handoff.get("title")}"  {state}  {ticket}'
        mtime = _parse_ymd(handoff.get("mtime"))
        if today is not None and mtime is not None:
            line += f"  {(today - mtime).days}d"
        # The next step, not the scope paragraph: the brief's reader needs
        # what is still owed on the thread, and the opening paragraph says
        # what the session was about instead. Fall back to the paragraph
        # only when a handoff has no "Next steps" section to read.
        if handoff.get("next_step"):
            line += f"  — next: {handoff['next_step']}"
        elif handoff.get("first_paragraph"):
            line += f"  — {handoff['first_paragraph']}"
        handoff_lines.append(line)
    if handoff_lines:
        lines.append("## Handoffs")
        lines.extend(handoff_lines)
        lines.append("")

    diff_lines = [f"- {_render_diff_line(entry)}" for entry in diffs]
    if diff_lines:
        lines.append("## Changed since yesterday")
        lines.extend(diff_lines)
        lines.append("")

    lines.append("## Sources")
    source_bits = []
    for name, status in bundle.get("sources", {}).items():
        if status.get("ok"):
            source_bits.append(f"{name}: ok ({status.get('count')})")
        else:
            source_bits.append(f"{name}: FAILED ({status.get('error')})")
    lines.append(" | ".join(source_bits))

    return "\n".join(lines).rstrip() + "\n"


def _truncate(bundle, signals, diffs, handoff_states, checked_commitments, degraded_sources) -> str:
    """Re-render dropping optional sections in order: diff (mostly
    "unchanged" lines), then stale refs, then handoffs/PRs trimmed, until
    under MAX_BYTES.
    Must-know (jira due/urgent) and Sources footer are never dropped. Always
    calls _render_raw (never render()) so this can never recurse back into
    render()'s own size check."""
    for include_stale_refs, keep_diffs in ((True, diffs), (True, []), (False, [])):
        candidate = _render_raw(
            bundle,
            signals,
            keep_diffs,
            handoff_states,
            checked_commitments,
            degraded_sources,
            include_stale_refs=include_stale_refs,
        )
        if len(candidate.encode("utf-8")) <= MAX_BYTES:
            return candidate
    # Still too big: drop PRs section content as a last resort, keep must-know + sources.
    reduced_bundle = dict(bundle)
    reduced_bundle["github"] = {
        "review_requested": [],
        "my_open_branches": bundle.get("github", {}).get("my_open_branches", []),
    }
    candidate = _render_raw(
        reduced_bundle,
        signals,
        [],
        handoff_states,
        checked_commitments,
        degraded_sources,
        include_stale_refs=False,
    )
    if len(candidate.encode("utf-8")) <= MAX_BYTES:
        return candidate
    # Genuinely can't fit even the bare minimum (e.g. a huge number of real
    # Jira items with long summaries) -- return it anyway rather than loop or
    # crash. An oversized context.md is a smaller problem than no context.md.
    return candidate


def load_parked(state_dir: Path, today: date) -> dict[str, set[str]]:
    """Items the user parked to a future date, from the last brief's commitments.

    "Park it until a named date" is only a real choice if the parked item then
    stops appearing. Returns the keys / PR ids / handoff titles to suppress,
    plus the date they come back.
    """
    parked: dict[str, set[str]] = {"keys": set(), "prs": set(), "handoffs": set(), "until": set()}
    prior = prior_state_file(state_dir, "commitments", today)
    if not prior:
        return parked
    try:
        entries = json.loads(prior[0].read_text())
    except (OSError, json.JSONDecodeError):
        return parked
    for entry in entries:
        raw_until = entry.get("parked_until")
        if not isinstance(raw_until, str):
            continue
        until = _parse_ymd(raw_until)
        if until is None or until <= today:
            continue
        parked["until"].add(raw_until)
        parked["keys"].update(entry.get("keys") or [])
        parked["prs"].update(entry.get("prs") or [])
        if entry.get("handoff"):
            parked["handoffs"].add(entry["handoff"])
    return parked


def apply_parked(bundle: dict, parked: dict[str, set[str]]) -> int:
    """Drop parked tickets, PRs and handoffs from the bundle. Returns the count."""
    removed = 0

    jira = bundle.get("jira", [])
    kept_jira = [i for i in jira if i.get("key") not in parked["keys"]]
    removed += len(jira) - len(kept_jira)
    bundle["jira"] = kept_jira

    github = bundle.get("github", {})
    prs = github.get("review_requested", [])
    kept_prs = [p for p in prs if f"{p.get('repo')}#{p.get('number')}" not in parked["prs"]]
    removed += len(prs) - len(kept_prs)
    github["review_requested"] = kept_prs

    handoffs = bundle.get("handoffs", [])
    kept_handoffs = [h for h in handoffs if h.get("title") not in parked["handoffs"]]
    removed += len(handoffs) - len(kept_handoffs)
    bundle["handoffs"] = kept_handoffs

    return removed


def write_context(md: str, out_path: Path) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(md)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--state-dir", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    state_dir = Path(args.state_dir)
    from datetime import datetime

    now = datetime.now(UTC).astimezone()
    date_str = now.strftime("%Y-%m-%d")

    bundle = json.loads((state_dir / f"bundle-{date_str}.json").read_text())

    parked = load_parked(state_dir, now.date())
    parked_count = apply_parked(bundle, parked)

    signals_path = state_dir / f"signals-{date_str}.json"
    signals = json.loads(signals_path.read_text()) if signals_path.exists() else []

    diff_path = state_dir / f"diff-{date_str}.json"
    diffs = json.loads(diff_path.read_text()) if diff_path.exists() else []

    checked_path = state_dir / f"commitments-checked-{date_str}.json"
    checked_commitments = json.loads(checked_path.read_text()) if checked_path.exists() else []

    from diff import infer_handoff_state

    git_state_by_repo = {r.get("repo"): r for r in bundle.get("git_state", [])}
    handoff_states = {
        h.get("slug"): infer_handoff_state(h, git_state_by_repo.get(h.get("repo")), now)
        for h in bundle.get("handoffs", [])
    }

    degraded_sources = [
        name for name, status in bundle.get("sources", {}).items() if not status.get("ok")
    ]

    md = render(bundle, signals, diffs, handoff_states, checked_commitments, degraded_sources)
    if parked_count:
        # Said out loud, so a parked item is suppressed, not lost.
        until = ", ".join(sorted(parked["until"]))
        md += (
            f"\n## Parked\n- {parked_count} item(s) parked until {until}, hidden from this brief\n"
        )

    secrets = load_secrets()
    md = redact(md, list(secrets.values()))

    out_path = Path(args.out)
    write_context(md, out_path)
    print(f"wrote {out_path}")


if __name__ == "__main__":
    main()
