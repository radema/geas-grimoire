"""Locate the most recent prior state file for a given prefix.

The pipeline used to look strictly at `today - 1 day`, so any skipped day
(a weekend, a day off) silently emptied both the commitments check and the
diff. Every lookback goes through here instead: the newest dated file
before today, whatever its age.
"""

from __future__ import annotations

import re
from datetime import date
from pathlib import Path


def _stamp(name: str, prefix: str) -> str | None:
    """The date part of `{prefix}-YYYY-MM-DD.json`, or None.

    Matched whole, so prefix "commitments" never picks up
    "commitments-checked-...".
    """
    match = re.fullmatch(rf"{re.escape(prefix)}-(\d{{4}}-\d{{2}}-\d{{2}})\.json", name)
    return match.group(1) if match else None


def prior_state_file(state_dir: Path, prefix: str, today: date) -> tuple[Path, date] | None:
    """Newest `{prefix}-YYYY-MM-DD.json` in state_dir dated before today.

    Returns (path, its date), or None when there is no prior file.
    """
    candidates: list[tuple[date, Path]] = []
    for path in state_dir.glob(f"{prefix}-*.json"):
        raw = _stamp(path.name, prefix)
        if raw is None:
            continue
        try:
            stamp = date.fromisoformat(raw)
        except ValueError:
            continue
        if stamp < today:
            candidates.append((stamp, path))
    if not candidates:
        return None
    stamp, path = max(candidates)
    return path, stamp
