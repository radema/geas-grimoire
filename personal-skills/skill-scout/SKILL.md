---
name: skill-scout
description: Analyzes the recent conversation history or a completed task to detect reusable patterns. Generates a new SKILL.md file to automate that workflow in the future. Use this when the user asks to "create a skill from this," "save this workflow," or "suggest a new skill."
---

# Skill Scout

## Goal
To analyze the recently completed task (user prompts and agent actions), abstract it into a reusable workflow, and generate a valid `SKILL.md` file that adheres to Antigravity standards.

## Usage Rules

### 1. Analysis Phase
* **Scan History:** Look at the last 5-10 turns of the conversation. Identify the *Goal* (what the user wanted) and the *Execution* (what commands/actions were actually successful).
* **Generalize:** Identify specific values (filenames, URLs, project names) and replace them with general instructions (e.g., "Ask the user for the target file" or "Use the current working directory").

### 2. Output Format (The "Skill Blueprint")
You must generate a code block containing the full content of the suggested `SKILL.md` file. It must include:
* **Frontmatter:** `name` (kebab-case) and `description` (detailed triggers).
* **Body Sections:** `## Goal`, `## Usage Rules` (or Instructions), and `## Examples`.

### 3. File Creation
* Ask the user if they want to save this skill.
* If yes, create the directory `<project-root>/.agent/skills/<skill-name>/` and write the file.

## Examples

**User:** "That sequence of git commands worked perfectly. Save that as a skill."

**Agent Execution:**
1.  *Analyzes history:* Sees user ran `git checkout -b`, `git add`, `git commit`, `git push`.
2.  *Drafts Skill:* `git-feature-start`.
3.  *Output:*
    ```markdown
    ---
    name: git-feature-start
    description: Automates the creation of a new feature branch and initial commit sequence.
    ---
    
    # Git Feature Start
    
    ## Goal
    Streamline the start of a new feature workflow.
    ...
    ```