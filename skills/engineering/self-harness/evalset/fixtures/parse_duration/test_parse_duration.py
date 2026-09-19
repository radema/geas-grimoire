"""Oracle for the implement-from-spec case. Frozen — the agent must not edit this.

On the untouched fixture (solution.py raises NotImplementedError) every test fails,
so the case discriminates: it passes only once parse_duration is correctly implemented.
"""

from solution import parse_duration


def test_simple_seconds():
    assert parse_duration("45s") == 45


def test_simple_minutes():
    assert parse_duration("90m") == 5400


def test_simple_hours():
    assert parse_duration("2h") == 7200


def test_combined():
    assert parse_duration("1h30m") == 5400


def test_full_combo():
    assert parse_duration("1h30m15s") == 5415


def test_zero():
    assert parse_duration("0s") == 0
