---
name: read-data-contract
description: >
  Programmatically extract metadata from YML-based data contracts (dbt schema.yml,
  metadata.yml, *_contract.yml, *_schema.yml, etc.) to infer column names, data types,
  semantic descriptions, nullability, tags, and test definitions — without reading entire
  files into context. Use this skill whenever you encounter a task involving data contracts,
  dbt models, table validation, schema documentation, or query generation from structured
  YML sources. Trigger autonomously when you discover relevant YML files during work, even
  if the user has not explicitly asked for contract extraction. Token-efficiency is a core
  goal: extract only what is needed for the task at hand.
---

# read-data-contract

## Overview

Data contracts (`schema.yml`, `metadata.yml`, `*_contract.yml`) encode authoritative
metadata about tables and columns: names, types, semantic meaning, ownership, freshness,
and data quality tests.

**Use this skill when you need to:**
- Generate SQL queries (column names, types)
- Validate data quality rules (test definitions)
- Produce documentation or data dictionaries (descriptions, tags)
- Understand ownership and freshness SLAs
- Infer semantic meaning before transforming or joining data

**Two modes:**

| Mode | Trigger | Action |
|---|---|---|
| **Explicit** | User provides a file path | Parse that path directly |
| **Autonomous** | Agent finds YML files during work | Detect contract, extract silently |

Always prefer running the extraction script over reading entire files into context.

---

## Step-by-Step Execution

### Step 1 — Locate the Contract

**Explicit path:** use exactly what the user provides.

**Autonomous discovery:**
```bash
find . -type f \( -name "schema.yml" -o -name "metadata.yml" \
  -o -name "*_contract.yml" -o -name "*_schema.yml" \) 2>/dev/null
```

If multiple contracts exist, prefer the one in the same directory as the model being
worked on. If still ambiguous, list candidates and ask once.

---

### Step 2 — Run the Extraction Script

Use the bundled script. It outputs clean JSON to stdout — no file content enters context.

```bash
# Extract a specific table
python .claude/skills/read-data-contract/scripts/extract_contract.py \
  <path/to/schema.yml> --table <table_name>

# Extract all tables
python .claude/skills/read-data-contract/scripts/extract_contract.py \
  <path/to/schema.yml>
```

The script auto-detects dbt vs generic contract format.

**When to read the reference instead of running the script:**
- The contract uses an unfamiliar or custom format not covered by the script
- You need to understand inference rules before deciding what to extract
- → Read `references/format-variants.md` for format detection and edge-case guidance

---

### Step 3 — Use the JSON Output for Your Task

| Task | How to use the output |
|---|---|
| **SQL query generation** | Use `column.name` + `column.type` to build `SELECT` / `WHERE` |
| **Data validation** | Translate `tests` into assertions or dbt test commands |
| **Documentation** | Use `description`, `tags`, `owner`, `freshness` for data dictionaries |
| **Schema comparison** | Diff extracted column list against actual warehouse schema |

Never save extracted metadata to a file unless explicitly asked. Use it in-memory.

---

### Step 4 — Handle Missing Details

| Missing field | Strategy |
|---|---|
| `description` | Humanise column name: `created_at` → "Created at" |
| `data_type` | Check sibling SQL file or warehouse schema; else `"unknown"` |
| `nullable` | Default `True` unless a `not_null` test exists for that column |
| `owner` | Check `dbt_project.yml` meta block; else `"unknown"` |
| `tests` | Note "no formal tests defined" — do not invent tests |
| `freshness` | Note "freshness not specified" — do not assume |

---

## What the Script Returns

Each extracted table is a dict with this shape:

```json
{
  "table_name": "users",
  "table_description": "Core user data",
  "owner": "data-platform",
  "freshness": "daily",
  "source_file": "models/schema.yml",
  "columns": [
    {
      "name": "id",
      "type": "int",
      "description": "Unique user identifier",
      "nullable": false,
      "tags": ["pii"],
      "tests": [
        { "test_name": "unique",   "test_type": "unique",   "config": {} },
        { "test_name": "not_null", "test_type": "not_null", "config": {} }
      ]
    }
  ]
}
```

---

## Output Format (when presenting to user)

```markdown
## Table: [name]
**Description:** [description]
**Owner:** [owner]
**Freshness:** [cadence]
**Source:** [file path]

### Columns
| Column | Type | Nullable | Tags | Description |
|---|---|---|---|---|
| id | int | No | pii | Unique user identifier |

### Data Quality Tests
- **id → unique**: Ensures no duplicate IDs
- **id → not_null**: Ensures every row has an ID

### Warnings
- ⚠️ [any missing owner / freshness / descriptions / tests]
- ✅ [confirmed present fields]
```

Mark auto-inferred descriptions as `[inferred]`. Always include a Warnings section.

---

## Implementation Rules

**Never:**
- Read entire YML files into context
- Use `grep`, `sed`, `awk`, or regex to parse YAML
- Ask the user to confirm every field
- Assume dbt format without checking

**Always:**
- Run the script first; fall back to `references/format-variants.md` for edge cases
- Include `source_file` in any extracted output for traceability
- Flag missing critical metadata rather than silently omitting it
