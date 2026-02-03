---
name: skill-manager
description: "Manage and synchronize agentic skills from public GitHub repositories using the `skm` CLI utility. Use this skill when you need to: (1) Find and fetch new skills from external repositories, (2) Keep existing skills updated, (3) List available skills in the marketplace, or (4) Bootstrap a new environment with a specific skill set."
---

# Skill Manager (skm)

## Overview
The `skill-manager` skill enables the agent to discover, fetch, and synchronize specialized agentic skills from public GitHub repositories. It uses the `skm` CLI utility to maintain a local repository of skills, which can then be selectively integrated into the active project.

## Workflow

### 1. Installation & Setup
If `skm` is not installed, it must be bootstrapped from the source repository. Use `uv` if available (preferred):
```bash
uv tool install git+https://github.com/radema/skill-manager.git
```
Otherwise, use `pip`:
```bash
pip install git+https://github.com/radema/skill-manager.git
```

### 2. Marketplace Management
The marketplace is the local staging area for fetched skills, typically stored in `.skills-marketplace/` (or `.skill-manager/`).

**Stewardship Note**: After first use, ensure this staging folder is added to your `.gitignore` (e.g., `echo ".skills-marketplace/" >> .gitignore`).

- **Add a Repository**: Add a public GitHub repository to your inventory.
  ```bash
  skm add <repo-url>
  ```
- **Sync Skills**: Download or updates added repositories.
  ```bash
  skm sync           # Sync all items
  skm sync <name>    # Sync a specific item
  ```
- **List Inventory**: View managed repositories.
  ```bash
  skm list
  ```

### 3. Integration (Manual Move)
`skm` fetches skills into the staging folder. Once fetched, relevant skills should be manually integrated into the active `.agent/skills/` folder to make them active for the current workspace.

**Example**:
1. `skm add https://github.com/user/my-skills`
2. `skm sync`
3. Identify a useful skill in `.skills-marketplace/my-skills/skills/target-skill`
4. Copy `target-skill/` to `.agent/skills/`

## Interaction Patterns

### Fetching a New Capability
**User**: "I need to work with Kubernetes, do we have any skills for that?"
**Agent**: "I don't have a Kubernetes skill active. I'll search for one using the skill-manager."
1. Run `skm add <kubernetes-skill-repo>`
2. Run `skm sync`
3. Inspect the fetched content and move relevant skill folders to `.agent/skills/`.

### Inventory Check
**User**: "Show me what's in our skills marketplace."
**Agent**: Run `skm list` and provide a summary of the repositories and available skills.

## Best Practices
- **Prune Regularly**: Remove repositories that are no longer needed using `skm remove <name>`.
- **Commit Active Skills**: When moving a skill to `.agent/skills/`, ensure it is committed to the main repository if it's intended to be a permanent part of the project's capability.
- **Verify Content**: Before activating a fetched skill, inspect its `SKILL.md` to ensure it aligns with the project's core standards.
