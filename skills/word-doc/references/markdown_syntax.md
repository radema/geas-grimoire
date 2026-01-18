# Supported Markdown Syntax

The `md_to_docx.py` converter supports the following markdown elements.

## Document Structure

```markdown
---
template: report.docx
placeholders:
  client_name: "Acme Corp"
  date: "2026-01-18"
---

# Your content starts here
```

## Headings

```markdown
# Heading 1 → Word "Heading 1" style
## Heading 2 → Word "Heading 2" style
### Heading 3 → Word "Heading 3" style
```

## Text Formatting

```markdown
**bold text** → Bold
*italic text* → Italic
`code` → Courier New font
```

## Lists

```markdown
- Bullet item → "List Bullet" style
- Another item

1. Numbered item
2. Another numbered
```

## Tables

```markdown
| Header 1 | Header 2 |
|----------|----------|
| Cell 1   | Cell 2   |
| Cell 3   | Cell 4   |
```

Tables use Word's "Table Grid" style with bold headers.

## Images

```markdown
![Caption](path/to/image.png)
```

Images are centered and scaled to 5.5" width. Caption appears below in italic.

## Placeholders

Use `{{variable}}` anywhere in text. Values come from YAML frontmatter:

```markdown
---
placeholders:
  client: "Acme"
---

Report for {{client}}.
```

## Chart Types

Use `chart_generator.py` to create:
- `line` - Time series, trends
- `bar` - Comparisons
- `scatter` - Correlations
- `area` - Cumulative data
- `pie` - Proportions
- `heatmap` - Matrix data
- `box` - Distributions
