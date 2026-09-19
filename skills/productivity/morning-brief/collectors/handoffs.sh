#!/usr/bin/env bash
# Thin wrapper: the real parsing logic lives in handoffs.py (testable in isolation).
exec uv run python "$(dirname "$0")/handoffs.py" "$@"
