# format-variants.md
# Reference: Contract Format Detection, Variants & Edge Cases

Load this file only when:
- The extraction script fails or produces unexpected output
- You encounter a contract format not covered by dbt or generic detection
- You need to understand inference rules before deciding what to extract

---

## Table of Contents
1. [Format Detection Logic](#1-format-detection-logic)
2. [dbt schema.yml — Full Anatomy](#2-dbt-schemayml--full-anatomy)
3. [Generic metadata.yml — Variants](#3-generic-metadatayml--variants)
4. [Edge Cases & Inference Rules](#4-edge-cases--inference-rules)
5. [Custom / Unknown Formats](#5-custom--unknown-formats)

---

## 1. Format Detection Logic

Inspect top-level keys after `yaml.safe_load()`:

| Top-level keys present | Detected format |
|---|---|
| `models` and/or `sources` | **dbt** |
| `version: 2` + `models` | **dbt v2** (same extractor) |
| `tables` | **generic — tables variant** |
| `entities` | **generic — entities variant** |
| `datasets` | **generic — datasets variant** (map like `tables`) |
| None of the above | **unknown** → attempt generic, warn |

```python
import yaml

with open(path) as f:
    raw = yaml.safe_load(f)

keys = set(raw.keys())
# dbt
if "models" in keys or "sources" in keys:
    fmt = "dbt"
# generic
elif keys & {"tables", "entities", "datasets"}:
    fmt = "generic"
else:
    fmt = "unknown"
```

---

## 2. dbt schema.yml — Full Anatomy

### Minimal valid contract
```yaml
version: 2
models:
  - name: orders
    columns:
      - name: order_id
        tests:
          - unique
          - not_null
```

### Full-featured contract
```yaml
version: 2
models:
  - name: users
    description: "Core user data"
    config:
      tags: ["core", "pii_table"]
    meta:
      owner: data-platform
      freshness: daily
      domain: identity
    columns:
      - name: id
        data_type: int
        description: "Unique user identifier"
        meta:
          nullable: false
        tags: [pii]
        tests:
          - unique
          - not_null

      - name: status
        data_type: varchar
        tests:
          - accepted_values:
              values: ["active", "inactive", "pending"]
              severity: warn

      - name: account_id
        data_type: int
        tests:
          - relationships:
              to: ref('accounts')
              field: id
```

### Key mapping — dbt → extracted field

| dbt key path | Extracted field | Fallback |
|---|---|---|
| `models[].name` | `table_name` | required |
| `models[].description` | `table_description` | `""` |
| `models[].meta.owner` | `owner` | `"unknown"` |
| `models[].meta.freshness` | `freshness` | see freshness section |
| `columns[].name` | `column.name` | required |
| `columns[].data_type` | `column.type` | `columns[].type` → `"unknown"` |
| `columns[].description` | `column.description` | infer from name |
| `columns[].meta.nullable` | `column.nullable` | derive from tests |
| `columns[].tags` | `column.tags` | `[]` |
| `columns[].tests` | `column.tests` | `[]` |

### Freshness resolution order (dbt)
1. `model.meta.freshness`
2. `model.config.meta.freshness`
3. `model.freshness.warn_after.count` (native dbt source freshness)
4. `"unknown"`

### Test normalisation
Tests can appear as strings or dicts:
```yaml
tests:
  - unique                          # string form
  - not_null                        # string form
  - accepted_values:                # dict form
      values: ["a", "b"]
  - dbt_utils.not_empty_string: {}  # package test, dict form
```

Normalised output:
```json
[
  { "test_name": "unique",           "test_type": "unique",           "config": {} },
  { "test_name": "not_null",         "test_type": "not_null",         "config": {} },
  { "test_name": "accepted_values",  "test_type": "accepted_values",  "config": { "values": ["a","b"] } },
  { "test_name": "dbt_utils.not_empty_string", "test_type": "dbt_utils.not_empty_string", "config": {} }
]
```

---

## 3. Generic metadata.yml — Variants

### Variant A: `tables → columns`
```yaml
tables:
  - name: orders
    description: "Order transactions"
    owner: commerce-team
    freshness: hourly
    columns:
      - name: order_id
        type: bigint
        nullable: false
        description: "Surrogate order key"
      - name: customer_id
        type: int
        nullable: false
        tags: [fk]
```

### Variant B: `entities → attributes`
```yaml
entities:
  - entity: Customer
    description: "Represents a registered customer"
    attributes:
      - attribute: customer_id
        data_type: integer
        pii: false
        nullable: false
      - attribute: email
        data_type: varchar
        pii: true
```
Map `entity` → `table_name`, `attribute` → `column.name`.

### Variant C: `datasets → fields`
```yaml
datasets:
  - name: payments
    owner: finance
    fields:
      - name: payment_id
        type: string
      - name: amount
        type: decimal
        nullable: false
```
Map `fields` → columns array.

### Column key detection priority
```python
for row in rows:
    col_key = next(
        (k for k in ("columns", "attributes", "fields") if k in row),
        None
    )
    if col_key is None:
        # No column list — emit table-level metadata only, warn
        pass
```

### Name key detection priority
```python
name = row.get("name") or row.get("entity") or row.get("dataset") or "unknown"
```

---

## 4. Edge Cases & Inference Rules

### Nullable inference (when `meta.nullable` is absent)
1. If a `not_null` test exists for the column → `nullable: false`
2. If the column name is `id`, `*_id`, `created_at`, `updated_at` → `nullable: false` (heuristic, flag as inferred)
3. Otherwise → `nullable: true`

### Description inference (when description is blank or absent)
```python
def infer_description(name: str, dtype: str = "") -> str:
    label = name.replace("_", " ").capitalize()
    suffix = f" ({dtype})" if dtype and dtype != "unknown" else ""
    return f"{label}{suffix} [inferred]"
```
Always mark inferred descriptions with `[inferred]` so downstream consumers can distinguish them.

### Type inference (when `data_type` / `type` is absent)
- Check sibling `.sql` model file for `cast(... as TYPE)` on the same column
- Check warehouse `INFORMATION_SCHEMA.COLUMNS` if accessible
- Fall back to `"unknown"` and flag it

### PII tag absorption
Some contracts use a boolean `pii: true` instead of a tag. Absorb into tags:
```python
tags = col.get("tags", [])
if col.get("pii") is True and "pii" not in tags:
    tags = tags + ["pii"]
```

### Empty models list
```yaml
version: 2
models: []
```
Emit an empty array `[]` with a stderr warning. Do not error out.

### Deeply nested meta blocks
Some teams put owner inside `config.meta` instead of `meta`:
```yaml
models:
  - name: events
    config:
      meta:
        owner: analytics-eng
```
Always try both paths:
```python
owner = (
    model.get("meta", {}).get("owner")
    or model.get("config", {}).get("meta", {}).get("owner")
    or "unknown"
)
```

---

## 5. Custom / Unknown Formats

If top-level keys don't match any known pattern:

1. Print keys to stderr: `Warning: unknown format — keys: [...]`
2. Look for any key that contains a list of dicts
3. Within each dict, look for a `name` field and a nested list (potential columns)
4. Apply generic extraction heuristically
5. Always include `"format": "unknown"` in the output so the agent can flag it

```python
def extract_unknown(raw: dict, source_file: str) -> list:
    """Last-resort heuristic for unrecognised contract shapes."""
    results = []
    for key, value in raw.items():
        if not isinstance(value, list):
            continue
        for item in value:
            if not isinstance(item, dict) or "name" not in item:
                continue
            # Find first nested list as column proxy
            col_key = next(
                (k for k, v in item.items() if isinstance(v, list) and k != "tests"),
                None
            )
            columns = []
            if col_key:
                for col in item[col_key]:
                    if isinstance(col, dict):
                        col_name = col.get("name") or col.get("attribute") or col.get("field", "")
                        columns.append({
                            "name": col_name,
                            "type": col.get("type") or col.get("data_type", "unknown"),
                            "description": col.get("description") or _infer_description(col_name),
                            "nullable": col.get("nullable", True),
                            "tags": [],
                            "tests": [],
                        })
            results.append({
                "table_name": item["name"],
                "table_description": item.get("description", ""),
                "owner": item.get("owner", "unknown"),
                "freshness": item.get("freshness", "unknown"),
                "source_file": source_file,
                "format": "unknown",
                "columns": columns,
            })
    return results
```
