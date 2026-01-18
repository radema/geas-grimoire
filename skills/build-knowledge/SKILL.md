---
name: build-knowledge
description: "Build and manage a persistent knowledge base (second brain) using Markdown files. Use when you need to store, retrieve, or link complex concepts, project context, or 'remember' information across sessions. Triggers on: (1) 'Remember this', (2) 'Build a knowledge base', (3) 'Document this concept', (4) Summarizing findings into long-term memory."
---

# Build Knowledge

You are the curator of a persistent knowledge base stored in `.agent_memory`. Your goal is to create a densely linked "second brain" that avoids information silos.

## Core Principles

- **The Golden Rule of Linking**: NEVER create orphaned files. Every new note MUST be linked from at least one other note (usually `000_Index.md` or a related topic).
- **Search Before Write**: Always search for existing topics before creating a new node to prevent duplication.
- **Wikilinks**: Use `[[Note_Name]]` for internal links.

## Librarian Tool (Scripts)

Use the Librarian script via `uv` to manage the knowledge base.

### 1. Search for existing knowledge
Finds files containing specific keywords using case-insensitive grep and synonym expansion.
```bash
uv run python .agent/skills/build-knowledge/scripts/librarian.py search --keywords "keyword1" "keyword2"
```

### 2. Read a note
Retrieves the full content of a specific note.
```bash
uv run python .agent/skills/build-knowledge/scripts/librarian.py read --filename "Note_Name.md"
```

### 3. Create a new note
Stores new information. Fails if the file already exists.
```bash
uv run python .agent/skills/build-knowledge/scripts/librarian.py create --filename "Note_Name.md" --content "# Title\nContent here..."
```

### 4. Append to a note
Adds details to an existing topic.
```bash
uv run python .agent/skills/build-knowledge/scripts/librarian.py append --filename "Note_Name.md" --content "Additional info..."
```

## Standard Workflow

1. **Analyze**: User says "Remember X".
2. **Search**: `search --keywords "X"` to check for existing context.
3. **Branching Logic**:
   - **If exists**: `read` it, then `append` new info.
   - **If new**: `create` the node.
4. **Link**: `read` the parent/index note and `append` a link `[[X]]` to ensure discovery.
5. **Confirm**: Tell the user where the knowledge is stored.

## Troubleshooting & Setup

If using for the first time or if the script fails due to missing dependencies, see [references/setup.md](references/setup.md).
