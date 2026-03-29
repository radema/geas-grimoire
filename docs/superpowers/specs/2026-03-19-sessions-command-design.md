# Design: /sessions Slash Command

**Date:** 2026-03-19
**Status:** approved

## Summary

A global Claude Code slash command (`/sessions`) that lists all past sessions with metadata and pre-formatted resume commands, so the user can quickly find and resume any previous conversation.

## Acceptance Criteria

- Running `/sessions` displays a markdown table of all sessions found in `~/.claude/projects/`
- Each row shows: `#`, Session ID, Created, Last Active, Name, First Message, Last Message
- Timestamps displayed as `YYYY-MM-DD HH:MM` in local timezone
- First/Last Message truncated to ≤80 chars; shows `—` if no qualifying message exists
- Sessions sorted by last activity descending (most recent first)
- Below the table, each session has a ready-to-copy `claude --resume <id>` command
- Handles missing/malformed JSONL entries gracefully (skips corrupt lines silently)
- If `~/.claude/projects/` does not exist, prints a friendly "No sessions found" message
- Subagent session files (under `subagents/` subdirectories) are excluded

## Implementation

**File:** `~/.claude/commands/sessions.md`
**Type:** Global Claude Code slash command (markdown prompt file)

**Approach:** The command instructs Claude to run an inline Python script via the Bash tool. The script:

1. Scans `~/.claude/projects/*/*.jsonl` — one level deep only, excluding `subagents/` subdirectories
2. Per file, extracts:
   - **Session ID**: filename without `.jsonl`
   - **Created**: `snapshot.timestamp` from the first `file-history-snapshot` entry; if absent, timestamp from the first entry that has one
   - **Last Active**: timestamp of the last entry of any type that has a timestamp field (reflects overall session activity, not just user turns)
   - **Session Name**: `slug` field from the first `progress` type entry; `N/A` if absent
   - **First/Last Message**: first and last entry where `type == "user"`, `isMeta` is not `true`, `message.content` is a non-empty string or contains at least one `type: text` block with non-empty text, and the extracted text does not start with `<` (filters XML/tag injections) and does not start with `/` (filters slash commands)
3. Sorts rows by last activity descending
4. Outputs a markdown table + resume commands block

## Data Sources

| Field | Source | Fallback |
|---|---|---|
| Session ID | JSONL filename (without `.jsonl`) | — |
| Created | `snapshot.timestamp` in first `file-history-snapshot` entry | First entry timestamp |
| Last Active | Timestamp of last entry with any timestamp field | `—` |
| Session Name | `slug` from first `progress` entry | `N/A` |
| First Message | First qualifying user entry (see filtering rules above) | `—` |
| Last Message | Last qualifying user entry (see filtering rules above) | `—` |

## Qualifying User Message Filtering Rules

A user entry qualifies as a human-authored message if ALL of the following hold:
1. `type == "user"`
2. `isMeta` is absent or `false`
3. `message.content` is either:
   - A non-empty string, OR
   - A list containing at least one `{"type": "text", "text": "<non-empty>"}` block
4. The extracted text does not start with `<` (excludes XML injections)
5. The extracted text does not start with `/` (excludes slash commands)

## Out of Scope

- Interactive session picker (decided against — adds complexity for no gain)
- Auto-resume within the same session (not possible with `claude --resume` as a startup flag)
- Session renaming
- Cross-project session aggregation (only scans the current `~/.claude/projects/` root)
