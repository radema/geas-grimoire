---
name: technical-doc-writer
description: Guide for creating effective, structured, and token-efficient technical documentation. Use when taking on documentation tasks, defining system architecture, writing technical specs, or whenever the user asks for "structured documentation".
---

# Technical Documentation Writer

This skill empowers you to produce technical documentation that is:

- **Effective**: Clear, actionable, and comprehensive.
- **Structured**: Organized logically into easy-to-navigate modular files.
- **Token-Efficient**: Optimized for consumption by both Humans and AI Agents.

## When to Use This Skill

- Initializing documentation for a new project.
- Refactoring existing "monolithic" documentation into a modular structure.
- Documenting specific system components (Architecture, API, Database, etc.) following a standard schema.

## The Standard Structure

We adopt a modular "folders and subfolders" approach to keep context focused and manageable. This is similar to the modular skill structure itself. This creates a "Knowledge/Documentation Graph" where each node (file) has a specific purpose.

### Core Sections

See the bundled script for the canonical list, but generally:

1.  **Architecture**: System review, tech stack, diagrams.
2.  **Database**: Schemas, relationships.
3.  **API**: Endpoints, contracts.
4.  **Security**: Auth, compliance.
5.  **Operations**: Deployment, monitoring, logging.
6.  **Quality**: Testing strategies.
7.  **Edge Cases**: Specific handling of non-happy paths.

## Workflow

### 0. Check Repo Type

First check the repo type. If a `.specify/` directory exists, this is a Speckit repo. Find the repo's doc tree before writing — it may be `docs/wiki/` (kebab-case slugs, `[[wikilinked]]`) or `docs/technical/` (flat `NN_` prefixes) depending on the repo. Add new deep-dives there via the governor's altitude rule (D-27, repo `docs/memory/entries/D-27.md`); scaffold nothing there. Feature-scoped writing stays in `.specify/specs/<feature>/`.

### 1. Scaffold the Structure

Don't worry about creating files manually. Use the bundled script to generate the standard folder and file structure.

**Command:**

```bash
python3 .claude/skills/technical-doc-writer/scripts/scaffold_docs.py <target_directory>
```

_Example: `python3 .claude/skills/technical-doc-writer/scripts/scaffold_docs.py docs/wiki`_

### 2. Populate the Content

Iterate through the generated files. You do not need to fill them all at once. Priorities usually are:

1.  System Architecture & Database Schema (The Foundation)
2.  API Specifications & Integration (The Interface)
3.  Others as implementation details solidify.

### 3. Writing Guidelines for Token Efficiency

- **Use Mermaid Diagrams**: Instead of long textual descriptions of flows, use `mermaid` diagrams.
- **Lists over Paragraphs**: Use bullet points for features, requirements, and steps.
- **Link, Don't Duplicate**: If a concept is defined in `01_system_architecture.md`, reference it in other files rather than redefining it.
- **Consistent Headers**: Stick to the provided headers in the templates.
- **Data over Prose**: For schemas and APIs, prefer table formats or code blocks (JSON/SQL) over descriptive text.

## Resources

- **Script**: `scripts/scaffold_docs.py` - Automates the creation of the documentation folder and markdown skeletons.
