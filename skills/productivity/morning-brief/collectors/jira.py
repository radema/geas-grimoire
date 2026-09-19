#!/usr/bin/env python3
"""Jira Stage-1 collector.

Prints exactly one JSON object to stdout. Logs/errors go to stderr.
Exits 0 on success and on expected failures (missing secrets, auth/network
errors) -- those produce a degraded `ok: false` JSON object rather than a
crash. Never prints or logs the API token.
"""

import json
import sys
from pathlib import Path

import requests

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "lib"))
from skillconfig import load_list  # noqa: E402

SECRETS_PATH = "/root/.config/morning-brief/secrets.env"
REQUEST_TIMEOUT = 10
MAX_RESULTS = 15
FIELDS = ["key", "summary", "status", "assignee", "reporter", "created", "updated", "duedate"]

# Boards this collector watches. A tenant can have dozens of projects, most
# irrelevant to one person; restricting to a few keeps queries fast and results
# relevant instead of scanning every board. Configure them in
# `config/projects.txt` or MORNING_BRIEF_PROJECTS; with neither, every project
# the account can see is queried.
PROJECTS = load_list("projects.txt", "MORNING_BRIEF_PROJECTS")

# Colleagues whose unowned tickets the brief should surface, beyond the user's
# own. Configure in `config/team.txt` or MORNING_BRIEF_TEAM; with neither, only
# the user's own reported tickets are looked at.
TEAM = load_list("team.txt", "MORNING_BRIEF_TEAM")

SCOPE = f"project in ({', '.join(PROJECTS)}) AND " if PROJECTS else ""
REPORTERS = ", ".join(["currentUser()"] + [f'"{member}"' for member in TEAM])

QUERIES = {
    "mine_active": f"{SCOPE}(assignee = currentUser() OR reporter = currentUser()) AND statusCategory != Done ORDER BY duedate ASC, updated DESC",
    "mine_created_assigned_other": f"{SCOPE}reporter = currentUser() AND assignee != currentUser() AND assignee is not EMPTY AND statusCategory != Done ORDER BY updated DESC",
    "mine_stale": f'{SCOPE}assignee = currentUser() AND statusCategory = "In Progress" AND issuetype != Epic AND updated <= -3d',
    "team_unowned": f"{SCOPE}assignee IS EMPTY AND statusCategory != Done AND created >= -14d AND reporter in ({REPORTERS})",
    "closed_yesterday": f"{SCOPE}assignee = currentUser() AND status CHANGED TO Done AFTER -1d",
}


def load_secrets(path: str) -> dict:
    """Load flat KEY=value lines from a secrets file, skipping comments/blanks."""
    secrets = {}
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            secrets[key.strip()] = value.strip()
    return secrets


def sanitize(message: str, secrets: dict) -> str:
    """Strip any secret value that may have leaked into an error message."""
    for value in secrets.values():
        if value:
            message = message.replace(value, "<redacted>")
    return message


def resolve_api_base(tenant_base_url: str) -> str:
    """Resolve the Atlassian API gateway base URL for this tenant.

    Scoped API tokens (Atlassian's "API token with scopes") are only
    authorized when requests go through the API gateway
    (api.atlassian.com/ex/jira/{cloudId}/...) -- calling the tenant's own
    domain (yoursite.atlassian.net/...) directly authenticates fine but
    silently returns empty results for every query, with no error. The
    cloudId lookup itself is unauthenticated.
    """
    resp = requests.get(f"{tenant_base_url}/_edge/tenant_info", timeout=REQUEST_TIMEOUT)
    resp.raise_for_status()
    cloud_id = resp.json()["cloudId"]
    return f"https://api.atlassian.com/ex/jira/{cloud_id}"


def run_search(api_base: str, auth, jql: str) -> list:
    # /rest/api/3/search was retired by Atlassian (returns 410 Gone);
    # /rest/api/3/search/jql is the replacement, same request/response shape
    # for our non-paginated use (single page, capped at MAX_RESULTS).
    resp = requests.post(
        f"{api_base}/rest/api/3/search/jql",
        auth=auth,
        json={"jql": jql, "maxResults": MAX_RESULTS, "fields": FIELDS},
        timeout=REQUEST_TIMEOUT,
    )
    resp.raise_for_status()
    return resp.json().get("issues", [])


def to_item(issue: dict, query_name: str) -> dict:
    fields = issue.get("fields", {})
    assignee = fields.get("assignee") or {}
    reporter = fields.get("reporter") or {}
    status = fields.get("status") or {}
    return {
        "key": issue.get("key"),
        "summary": fields.get("summary"),
        "status": status.get("name"),
        "assignee": assignee.get("displayName"),
        "reporter": reporter.get("displayName"),
        "created": fields.get("created"),
        "updated": fields.get("updated"),
        "duedate": fields.get("duedate"),
        "query": query_name,
    }


def empty_result(error: str) -> dict:
    return {"items": [], "queries_run": [], "ok": False, "error": error}


def main():
    check_keys_arg = None
    for i, arg in enumerate(sys.argv[1:]):
        if arg == "--check-keys" and i + 2 <= len(sys.argv[1:]):
            check_keys_arg = sys.argv[1:][i + 1]

    secrets = {}
    try:
        secrets = load_secrets(SECRETS_PATH)
    except OSError as e:
        print(sanitize(f"could not read secrets file: {e}", secrets), file=sys.stderr)
        print(json.dumps(empty_result("secrets.env missing or unreadable")))
        return 0

    base_url = secrets.get("JIRA_BASE_URL")
    email = secrets.get("JIRA_EMAIL")
    token = secrets.get("JIRA_API_TOKEN")
    if not base_url or not email or not token:
        print("secrets.env missing required keys", file=sys.stderr)
        print(json.dumps(empty_result("secrets.env missing or incomplete")))
        return 0

    auth = (email, token)
    base_url = base_url.rstrip("/")

    try:
        api_base = resolve_api_base(base_url)
    except Exception as e:
        msg = sanitize(str(e), secrets)
        print(f"could not resolve Atlassian cloud id: {msg}", file=sys.stderr)
        print(json.dumps(empty_result(f"cloud id lookup failed: {msg}")))
        return 0

    if check_keys_arg:
        keys = [k.strip() for k in check_keys_arg.split(",") if k.strip()]
        if not keys:
            print(json.dumps(empty_result("no keys provided to --check-keys")))
            return 0
        jql = "key in ({})".format(", ".join(keys))
        try:
            issues = run_search(api_base, auth, jql)
            items = [to_item(issue, "check_keys") for issue in issues]
            print(
                json.dumps(
                    {
                        "items": items,
                        "queries_run": ["check_keys"],
                        "ok": True,
                        "error": None,
                    }
                )
            )
            return 0
        except Exception as e:
            msg = sanitize(str(e), secrets)
            print(f"check-keys query failed: {msg}", file=sys.stderr)
            print(json.dumps(empty_result(f"request failed: {msg}")))
            return 0

    items = []
    items_by_key = {}
    queries_run = []
    try:
        for name, jql in QUERIES.items():
            issues = run_search(api_base, auth, jql)
            for issue in issues:
                item = to_item(issue, name)
                key = item["key"]
                existing = items_by_key.get(key)
                if existing is None:
                    items.append(item)
                    items_by_key[key] = item
                elif name not in existing["query"].split(","):
                    existing["query"] = f"{existing['query']},{name}"
            queries_run.append(name)
        print(
            json.dumps(
                {
                    "items": items,
                    "queries_run": queries_run,
                    "ok": True,
                    "error": None,
                }
            )
        )
        return 0
    except Exception as e:
        msg = sanitize(str(e), secrets)
        print(f"jira query failed: {msg}", file=sys.stderr)
        print(json.dumps(empty_result(f"request failed: {msg}")))
        return 0


if __name__ == "__main__":
    sys.exit(main())
