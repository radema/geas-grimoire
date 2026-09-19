"""Oracle for the fix-failing-test case. Frozen — the agent must not edit this.

summing.py ships with an off-by-one bug (`range(1, n)` excludes n), so these tests
fail as shipped. The case passes only once the source is fixed to be inclusive.
"""

from summing import sum_range


def test_sum_to_one():
    assert sum_range(1) == 1


def test_sum_to_five():
    assert sum_range(5) == 15


def test_sum_to_ten():
    assert sum_range(10) == 55
