---
name: word-doc
description: >
  Create professional Word documents (.docx) from company templates.
  Use when: (1) Creating reports, proposals, or contracts,
  (2) Generating documents with charts and data analysis,
  (3) Drafting content that needs company styling.
  Agent writes narrative content based on user-provided data/context.
---

# Word Document Generator

Create professional Word documents using company templates. Write content
in Markdown, convert to styled `.docx` via bundled scripts.

## Workflow

1. **Gather Context:** Clarify scope, data sources, template choice
2. **Generate Charts:** If needed, create images using `chart_generator.py`
3. **Write Markdown:** Create content file with YAML frontmatter
4. **Convert:** Run `md_to_docx.py` to produce final document

## Templates

Store templates in `templates/` directory. Each template can have:
- `template_name.docx` — The styled Word template
- `template_name.palette.json` — Optional color palette for charts

The template provides fonts, margins, header/footer, and named styles.
Content is generated and appended by the converter.

## Creating a Document

### Step 1: Prepare Charts (if needed)

```bash
uv run python scripts/chart_generator.py \
  --type line \
  --data /path/to/data.csv \
  --x "month" --y "revenue" \
  --palette "#1a73e8,#34a853" \
  --output charts/revenue.png
```

Supported types: `line`, `bar`, `scatter`, `area`, `pie`, `heatmap`, `box`

### Step 2: Write Content Markdown

Create a `.md` file with YAML frontmatter:

```markdown
---
template: templates/report.docx
placeholders:
  client_name: "Acme Corp"
  date: "2026-01-18"
  project_code: "PRJ-001"
---

# Executive Summary

This report analyzes {{client_name}}'s Q1 performance...

## Revenue Analysis

| Quarter | Revenue | Growth |
|---------|---------|--------|
| Q1      | €1.2M   | +12%   |

![Revenue Trend](charts/revenue.png)

## Recommendations

1. **Expand** northern operations
2. **Monitor** supply chain costs
```

### Step 3: Convert to Word

```bash
uv run python scripts/md_to_docx.py \
  --input content.md \
  --template templates/report.docx \
  --output final_report.docx
```

## Supported Markdown

See `references/markdown_syntax.md` for full syntax reference.

Quick reference:
- `# H1` through `###### H6` → Heading styles
- `**bold**`, `*italic*`, `` `code` ``
- `- bullet` and `1. numbered` lists
- `| tables |` with headers
- `![caption](image.png)` → Centered images
- `{{placeholder}}` → YAML value substitution

## Error Handling

| Issue | Behavior |
|-------|----------|
| Template not found | Create blank document, warn |
| Missing placeholder | Leave `{{var}}` visible, warn |
| Image not found | Insert `[Image not found: path]` |
| Invalid markdown | Skip block, continue |

## Adding New Templates

1. Create styled `.docx` with heading styles, fonts, margins
2. Drop into `templates/` folder
3. (Optional) Add `template_name.palette.json`:
   ```json
   {"colors": ["#1a73e8", "#34a853", "#ea4335", "#fbbc04"]}
   ```
