def sum_range(n):
    """Return the sum of the integers from 1 to n inclusive."""
    total = 0
    for i in range(1, n):
        total += i
    return total
