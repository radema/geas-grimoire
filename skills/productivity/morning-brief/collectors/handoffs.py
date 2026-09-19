#!/usr/bin/env python3
"""Handoffs Stage-1 collector.

Scans /root/.claude/handoffs/*.md (skipping any archive/ subdirectory) and
extracts a short summary of each. Prints exactly one JSON object to stdout,
logs/errors to stderr. A malformed file never crashes the whole run.
"""

import glob
import json
import os
import re
import sys

HANDOFFS_DIR = "/root/.claude/handoffs"
TICKET_RE = re.compile(r"\b([A-Za-z]{2,10}-\d+)\b")
FILENAME_RE = re.compile(r"^(?P<repo>.+)-(?P<ts>\d{8}-\d{6})-(?P<slug>.+)\.md$")
TIMESTAMP_RE = re.compile(r"(\d{8}-\d{6})")


def extract_title(lines: list) -> str:
    first = lines[0].strip() if lines else ""
    match = re.match(r"^#\s*Handoff\s*—\s*(.+)$", first)
    if match:
        return match.group(1).strip()
    return first.lstrip("#").strip()


def extract_field(text: str, label: str) -> str:
    match = re.search(rf"\*\*{label}\*\*:\s*(.+)", text)
    if not match:
        return None
    return match.group(1).strip()


def _strip_trailing_parens(value: str) -> str:
    return re.sub(r"\s*\(.*\)\s*$", "", value).strip()


def clean_repo(value: str) -> str:
    if value is None:
        return None
    value = _strip_trailing_parens(value)
    return value.strip("`").strip()


def clean_branch(value: str) -> str:
    if value is None:
        return None
    value = _strip_trailing_parens(value)
    return value.strip("`").strip()


def extract_ticket(branch: str, text: str) -> str:
    if branch:
        match = TICKET_RE.search(branch)
        if match:
            return match.group(1).upper()
    first_lines = "\n".join(text.splitlines()[:15])
    match = TICKET_RE.search(first_lines)
    if match:
        return match.group(1).upper()
    return None


def extract_first_paragraph(text: str) -> str:
    lines = text.splitlines()
    heading_idx = None
    for i, line in enumerate(lines):
        if re.match(r"^##\s+", line):
            heading_idx = i
            break
    if heading_idx is None:
        return None

    para_lines = []
    for line in lines[heading_idx + 1 :]:
        stripped = line.strip()
        if not stripped:
            if para_lines:
                break
            continue
        if stripped.startswith("#"):
            break
        para_lines.append(stripped)

    if not para_lines:
        return None

    paragraph = " ".join(para_lines)
    paragraph = re.sub(r"\s+", " ", paragraph).strip()
    if len(paragraph) > 200:
        paragraph = paragraph[:200].rstrip() + "..."
    return paragraph


NEXT_STEPS_RE = re.compile(r"^##\s*\d*\.?\s*Next steps", re.IGNORECASE)
BOLD_LEAD_RE = re.compile(r"^\*\*(.+?)\*\*")


def extract_next_step(text: str) -> str:
    """Return the first item under the handoff's "Next steps" heading.

    The brief needs what is left to do, not what the session was about --
    the scope paragraph the first heading yields is background. Handoffs
    written by the handoff skill put an ordered list under "## N. Next
    steps, in order", each item leading with a bold imperative; prefer that
    bold lead, which is already a one-line summary of the item, and fall
    back to the item's first sentence.
    """
    lines = text.splitlines()
    start = None
    for i, line in enumerate(lines):
        if NEXT_STEPS_RE.match(line.strip()):
            start = i
            break
    if start is None:
        return None

    item_lines = []
    for line in lines[start + 1 :]:
        stripped = line.strip()
        if stripped.startswith("#"):
            break
        if not stripped:
            if item_lines:
                break
            continue
        if item_lines and re.match(r"^(\d+\.|[-*])\s", stripped):
            break  # the second item -- we only want the first
        item_lines.append(re.sub(r"^(\d+\.|[-*])\s*", "", stripped))

    if not item_lines:
        return None

    item = re.sub(r"\s+", " ", " ".join(item_lines)).strip()
    bold = BOLD_LEAD_RE.match(item)
    step = bold.group(1).strip() if bold else item.split(". ")[0].strip()
    step = step.replace("**", "").rstrip(".")
    if len(step) > 160:
        step = step[:160].rstrip() + "..."
    return step or None


def extract_mtime(filename: str, filepath: str):
    match = TIMESTAMP_RE.search(filename)
    if match:
        try:
            from datetime import datetime

            dt = datetime.strptime(match.group(1), "%Y%m%d-%H%M%S")
            return dt.isoformat()
        except ValueError:
            pass
    try:
        from datetime import datetime

        return datetime.fromtimestamp(os.path.getmtime(filepath)).isoformat()
    except OSError:
        return None


def extract_slug(filename: str, title: str) -> str:
    match = FILENAME_RE.match(filename)
    if match:
        return match.group("slug")
    return title


def parse_file(filepath: str) -> dict:
    filename = os.path.basename(filepath)
    with open(filepath) as f:
        text = f.read()
    lines = text.splitlines()

    title = extract_title(lines)
    repo = clean_repo(extract_field(text, "Repo"))
    branch = clean_branch(extract_field(text, "Branch"))
    ticket = extract_ticket(branch, text)
    first_paragraph = extract_first_paragraph(text)
    next_step = extract_next_step(text)
    mtime = extract_mtime(filename, filepath)
    slug = extract_slug(filename, title)

    return {
        "file": filename,
        "slug": slug,
        "title": title,
        "repo": repo,
        "branch": branch,
        "ticket": ticket,
        "mtime": mtime,
        "first_paragraph": first_paragraph,
        "next_step": next_step,
    }


def main():
    handoffs = []
    pattern = os.path.join(HANDOFFS_DIR, "*.md")
    for filepath in sorted(glob.glob(pattern)):
        filename = os.path.basename(filepath)
        try:
            handoffs.append(parse_file(filepath))
        except Exception as e:
            print(f"{filename}: failed to parse ({e})", file=sys.stderr)
            handoffs.append({"file": filename, "error": str(e)})

    tmp_handoffs_found = []
    for filepath in sorted(glob.glob("/tmp/handoff-*.md")):
        tmp_handoffs_found.append(os.path.basename(filepath))

    result = {"handoffs": handoffs, "tmp_handoffs_found": tmp_handoffs_found}
    print(json.dumps(result))
    return 0


if __name__ == "__main__":
    sys.exit(main())
