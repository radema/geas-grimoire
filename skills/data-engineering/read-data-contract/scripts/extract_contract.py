#!/usr/bin/env python3
"""
extract_contract.py — Extract metadata from YML-based data contracts.

Usage:
    python extract_contract.py <path/to/schema.yml> [--table TABLE_NAME] [--pretty]

Output:
    JSON array of table metadata dicts, printed to stdout.
    On error, exits with code 1 and prints error to stderr.
"""

import sys
import json
import argparse
from pathlib import Path

try:
    import yaml
except ImportError:
    print("Error: PyYAML not installed. Run: pip install pyyaml", file=sys.stderr)
    sys.exit(1)


# ---------------------------------------------------------------------------
# Format detection
# ---------------------------------------------------------------------------

def detect_format(raw: dict) -> str:
    """Return 'dbt', 'generic', or 'unknown'."""
    keys = set(raw.keys())
    if "models" in keys or "sources" in keys:
        return "dbt"
    if "tables" in keys or "entities" in keys:
        return "generic"
    return "unknown"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _infer_description(col_name: str, dtype: str = "") -> str:
    label = col_name.replace("_", " ").capitalize()
    return f"{label} ({dtype}) [inferred]" if dtype and dtype != "unknown" else f"{label} [inferred]"


def _extract_freshness(model: dict) -> str:
    return (
        model.get("config", {}).get("meta", {}).get("freshness")
        or model.get("meta", {}).get("freshness")
        or str(model.get("freshness", {}).get("warn_after", {}).get("count", ""))
        or "unknown"
    )


def _normalise_tests(raw_tests: list) -> list:
    """Accept both string tests ('unique') and dict tests ({'not_null': {...}})."""
    result = []
    for t in raw_tests:
        if isinstance(t, str):
            result.append({"test_name": t, "test_type": t, "config": {}})
        elif isinstance(t, dict):
            test_name = next(iter(t))
            cfg = t[test_name]
            result.append({
                "test_name": test_name,
                "test_type": test_name,
                "config": cfg if isinstance(cfg, dict) else {},
            })
    return result


def _has_not_null_test(tests: list) -> bool:
    return any(t["test_type"] == "not_null" for t in tests)


def _extract_tags(col: dict) -> list:
    tags = list(col.get("tags", []))
    if col.get("pii") is True and "pii" not in tags:
        tags.append("pii")
    return tags


# ---------------------------------------------------------------------------
# dbt extractor
# ---------------------------------------------------------------------------

def extract_dbt(raw: dict, source_file: str, target_table: str = None) -> list:
    entries = raw.get("models", []) + raw.get("sources", [])
    results = []

    for model in entries:
        name = model.get("name", "")
        if target_table and name != target_table:
            continue

        columns = []
        for col in model.get("columns", []):
            col_name = col.get("name", "")
            dtype = col.get("data_type") or col.get("type", "unknown")
            raw_tests = col.get("tests", [])
            tests = _normalise_tests(raw_tests)

            # Derive nullable: explicit meta wins; not_null test implies False
            nullable_meta = col.get("meta", {}).get("nullable")
            if nullable_meta is not None:
                nullable = bool(nullable_meta)
            else:
                nullable = not _has_not_null_test(tests)

            columns.append({
                "name": col_name,
                "type": dtype,
                "description": col.get("description") or _infer_description(col_name, dtype),
                "nullable": nullable,
                "tags": _extract_tags(col),
                "tests": tests,
            })

        results.append({
            "table_name": name,
            "table_description": model.get("description", ""),
            "owner": model.get("meta", {}).get("owner", "unknown"),
            "freshness": _extract_freshness(model),
            "source_file": source_file,
            "columns": columns,
        })

    return results


# ---------------------------------------------------------------------------
# Generic extractor
# ---------------------------------------------------------------------------

def extract_generic(raw: dict, source_file: str, target_table: str = None) -> list:
    rows = raw.get("tables") or raw.get("entities") or []
    results = []

    for row in rows:
        name = row.get("name") or row.get("entity", "unknown")
        if target_table and name != target_table:
            continue

        # Support both columns/attributes key
        col_key = "columns" if "columns" in row else "attributes"
        raw_cols = row.get(col_key, [])

        columns = []
        for col in raw_cols:
            col_name = col.get("name") or col.get("attribute", "")
            dtype = col.get("data_type") or col.get("type", "unknown")
            nullable = col.get("nullable", True)

            columns.append({
                "name": col_name,
                "type": dtype,
                "description": col.get("description") or _infer_description(col_name, dtype),
                "nullable": nullable,
                "tags": _extract_tags(col),
                "tests": [],  # Generic contracts rarely define tests
            })

        results.append({
            "table_name": name,
            "table_description": row.get("description", ""),
            "owner": row.get("owner", "unknown"),
            "freshness": row.get("freshness", "unknown"),
            "source_file": source_file,
            "columns": columns,
        })

    return results


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Extract metadata from a YML data contract and print JSON."
    )
    parser.add_argument("contract", help="Path to the YML contract file")
    parser.add_argument("--table", default=None, help="Extract only this table (optional)")
    parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON output")
    args = parser.parse_args()

    contract_path = Path(args.contract)
    if not contract_path.exists():
        print(f"Error: file not found: {contract_path}", file=sys.stderr)
        sys.exit(1)

    with open(contract_path, "r", encoding="utf-8") as f:
        try:
            raw = yaml.safe_load(f)
        except yaml.YAMLError as e:
            print(f"Error parsing YAML: {e}", file=sys.stderr)
            sys.exit(1)

    if not isinstance(raw, dict):
        print("Error: contract file did not parse to a YAML mapping.", file=sys.stderr)
        sys.exit(1)

    fmt = detect_format(raw)
    source = str(contract_path)

    if fmt == "dbt":
        results = extract_dbt(raw, source, args.table)
    elif fmt == "generic":
        results = extract_generic(raw, source, args.table)
    else:
        print(
            f"Warning: unknown contract format (keys: {list(raw.keys())}). "
            "Attempting generic extraction.",
            file=sys.stderr,
        )
        results = extract_generic(raw, source, args.table)

    if not results:
        msg = f"No tables found"
        if args.table:
            msg += f" matching '{args.table}'"
        print(f"Warning: {msg} in {contract_path}", file=sys.stderr)

    indent = 2 if args.pretty else None
    print(json.dumps(results, indent=indent))


if __name__ == "__main__":
    main()
