"""Site-specific lists (Jira projects, teammates, watched repos) as config.

Nothing here is baked into the source: each list comes from an environment
variable, else from a file in `config/`, else from a generic fallback. The
config files are deliberately absent from this repository -- create them
locally (one entry per line, `#` starts a comment).
"""

from __future__ import annotations

import os
from pathlib import Path

CONFIG_DIR = Path(__file__).resolve().parent.parent / "config"


def load_list(filename: str, env_var: str) -> list[str]:
    """Read a configured list from `env_var` (comma-separated) or `config/<filename>`.

    Args:
        filename: File under `config/`, one entry per line, `#` comments allowed.
        env_var: Environment variable checked first; wins over the file.

    Returns:
        The configured entries, or an empty list when neither source exists.
    """
    raw = os.environ.get(env_var)
    if raw:
        return [v.strip() for v in raw.split(",") if v.strip()]

    path = CONFIG_DIR / filename
    if not path.exists():
        return []

    entries = []
    for line in path.read_text().splitlines():
        line = line.split("#", 1)[0].strip()
        if line:
            entries.append(line)
    return entries


def discover_repos() -> list[str]:
    """Git repositories directly under $HOME -- the fallback watch list."""
    home = Path(os.environ.get("HOME", "~")).expanduser()
    if not home.is_dir():
        return []
    return sorted(str(p) for p in home.iterdir() if (p / ".git").exists())


def load_repos() -> list[str]:
    """Absolute paths of the repositories the brief watches."""
    return load_list("repos.txt", "MORNING_BRIEF_REPOS") or discover_repos()
