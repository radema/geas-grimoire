---
description: Systematically wrap up a session by summarizing progress, scouting for reusable skills, and cleaning up context.
---

# Session Debrief Protocol

This workflow serves as the "End of Session" checklist. It ensures that every conversation yields long-term value by capturing knowledge, updating context, and identifying new tools/skills before the session context is lost.

## Step 1: Session Summary

1.  **Analyze**: Review the recent conversation history (last ~20 turns or relevant context).
2.  **Summarize**: Output a bulleted list of:
    *   **Accomplishments**: What specific tasks were completed?
    *   **Decisions**: What architectural or strategic choices were made?
    *   **Open Items**: What was left unfinished?

## Step 2: Skill & Pattern Scouting

1.  **Detect Patterns**: Did we perform a repetitive sequence of actions that isn't yet a workflow?
2.  **Gap Analysis**: Did we struggle with a task because a specific instruction was missing?
3.  **Proposal**:
    *   *If a pattern is found*: Propose a new **Skill** or **Workflow** (Name + 1-sentence description).
    *   *If rules were unclear*: Propose an update to `global.md` or a persona rule file.
    *   *If no pattern found*: Explicitly state "No new skills detected."

## Step 3: Approval Gate

1.  **Present Proposals**: Show the user *exactly* what files you recommend creating or updating.
    *   "I recommend creating `.agent/skills/new-skill/SKILL.md`..."
    *   "I recommend adding 'Always use Factory Pattern' to `architect.md`..."
2.  **WAIT for Approval**: Do **NOT** write any files yet. Ask: "Do you want me to apply these changes?"

## Step 4: Execution

1.  **Apply Changes**:
    *   If approved, Write/Update the files using `write_to_file` or `multi_replace_file_content`.
    *   Use `skill-creator` for new skills if needed.
2.  **Final Confirmation**: Confirm the context is clean and ready for the next session.
