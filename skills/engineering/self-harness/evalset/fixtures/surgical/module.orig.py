"""HTTP client configuration."""

DEFAULT_TIMEOUT = 30
MAX_RETRIES = 3


def make_client(timeout=DEFAULT_TIMEOUT, retries=MAX_RETRIES):
    return {"timeout": timeout, "retries": retries}
