# AGENTS.md - Guide for Agentic Coding

## Project Overview
Python 3.13.1 knowledge repository using `uv` package manager. Platform-agnostic collection of agentic prompts, skills, and workflows.

## Essential Commands

### Testing
```bash
# Run all tests
uv run pytest

# Run with coverage
uv run pytest --cov=ras_balancer --cov-report=html

# Run single test file (unittest)
uv run python skills/<skill-name>/scripts/test_<module>.py
```

### Code Quality
```bash
# Run all quality checks
uv run quality  # Runs: black . && flake8 . && mypy .

# Individual tools
uv run black .        # Format code
uv run flake8 .       # Style linting
uv run mypy .         # Type checking
uv run ruff .         # Fast linting (alternative)
```

## Core Engineering Standards

### 1. Test-Driven Development (TDD)
- **Never** implement features or fix bugs without a failing test first
- Follow Red-Green-Refactor cycle
- Run existing tests before every commit
- Test naming: `test_<module_name>.py` using unittest

### 2. SOLID & Clean Code
- Prefer small, single-responsibility modules over large files
- Use descriptive naming; document the "Why", not the "How"
- Break complex tasks into sub-skills or sub-workflows

### 3. Data Integrity
- Workflows must be **idempotent** (safe to run multiple times)
- Use strict validation (schemas, types, assertions) to fail early
- Graceful degradation for optional dependencies

### 4. Contract-First Development
- Interface definitions finalized before implementation
- SKILL.md frontmatter must be complete

## Code Style Guidelines

### Naming Conventions
- **Variables/Functions**: `snake_case` (`search_notes`, `storage_folder`)
- **Classes**: `PascalCase` (`KnowledgeGraphTool`, `DocxRenderer`)
- **Constants**: `UPPER_SNAKE_CASE` (`SUPPORTED_CHART_TYPES`)
- **Private methods**: `_snake_case` (`_safe_path`, `_expand_synonyms`)
- **Directories**: `kebab-case` (`build-knowledge/`, `word-doc/`)

### Type Hints
- Use type hints for public APIs and complex signatures
- Return types recommended for clarity
- Conditional imports for optional dependencies:
  ```python
  try:
      from nltk.corpus import wordnet
  except ImportError:
      wordnet = None
  ```

### Imports
- Order: standard library → third-party
- Group with blank lines between sections
- Conditional imports for optional deps

### Error Handling
- Try-except with meaningful error messages
- Graceful fallback for optional functionality
- Validation with early returns for clear error paths
  ```python
  if not pattern:
      return "Error: No keywords provided."
  if os.path.exists(path):
      return f"Error: '{filename}' already exists."
  ```

### Formatting
- 4-space indentation (PEP 8)
- Blank lines between functions and classes
- Google-style docstrings for public functions
- Line length: ~88-100 characters

## Bolt Lifecycle (Development Workflow)

1. **Bolt-Intent**: Requirements → Spec → ADR → Implementation Plan
2. **Bolt-Implementation**: TDD Loop → Documentation → Status Update
3. **Bolt-Verify**: Requirement Coherence → Edge Case Hunt → Performance Audit

## File Organization

### Skills Structure
```
skills/
└── <skill-name>/
    ├── SKILL.md          # Required: Definition with YAML frontmatter
    ├── scripts/          # Optional: Python/Bash automation
    ├── templates/        # Optional: Document templates
    ├── references/       # Optional: Syntax guides, lookup tables
    └── resources/        # Optional: Examples, static assets
```

### SKILL.md Format
```yaml
---
name: skill-identifier
description: One-sentence description
---
```

## Documentation Standards

- **Token efficiency**: Be concise, avoid fluff. Use imperative verbs ("Run", "Create")
- **Modularity**: Split into smaller files; avoid monolithic documents
- **Internal linking**: Use `[[wikilinks]]` for cross-references

## Agent Permissions (opencode.jsonc)
- `git *`: allow
- `grep *`, `ls`: allow
- `uv run pytest/ruff/black/flake8/mypy *`: allow
- `rm *`: ask
- `*`: ask (default)

## License
Apache License 2.0
