"""Print the date the last brief ran, for the collectors' `--since` window.

CLI:
    uv run python lib/last_run.py --state-dir DIR
Prints YYYY-MM-DD, or nothing at all when no earlier run exists.
"""

from __future__ import annotations

import argparse
from datetime import UTC, datetime
from pathlib import Path

from statefiles import prior_state_file


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--state-dir", required=True)
    args = parser.parse_args()

    prior = prior_state_file(Path(args.state_dir), "bundle", datetime.now(UTC).astimezone().date())
    if prior:
        print(prior[1].isoformat())


if __name__ == "__main__":
    main()
