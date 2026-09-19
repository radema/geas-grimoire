# System Architecture

`geas-grimoire` is not an application. It is a versioned store of Claude Code harness assets —
skills, subagents, hooks — installed into a device's `~/.claude/` directory.

## Layout

| Path | Role |
|---|---|
| `skills/<category>/<name>/` | One skill per directory. `SKILL.md` required; `scripts/`, `references/`, `templates/`, `assets/` optional. |
| `agents/` | Subagent definitions (one Markdown file each) plus `retired/`. |
| `hooks/` | Hook scripts and `settings.reference.json`. |
| `scripts/` | `link-skills.sh`, `list-skills.sh`, `publish-public.sh`. |
| `archive/`, `skills/archive/` | Retired material, kept for reference, never installed. |
| `docs/`, `LICENSES/` | Notes and third-party licence texts. |

Categories: `data-engineering`, `engineering`, `experimenting`, `productivity`, `brand`, `archive`.

## Install model

Skills are **symlinked**: `~/.claude/skills/<name>` → `skills/<category>/<name>/`. One link per
skill, so a device installs only the subset it needs. Editing through either path edits the same
file. A plain directory at the target instead of a symlink means two editable copies and drift —
`scripts/link-skills.sh` refuses to overwrite one.

Agents and hooks are **copied** into `~/.claude/agents/` and `~/.claude/hooks/`, because Claude
Code reads them at startup and they are small and rarely edited. `~/.claude/settings.json` wires
the hooks; it is not versioned here, but `hooks/settings.reference.json` shows the shape.

`morning-brief` is the one skill not symlinked — see `AGENTS.md`.

## Two tiers: private and public

This repo is private. It contains company brand skills and configuration referring to private
work.

`scripts/publish-public.sh` produces the payload for the public mirror `radema/geas-grimoire`:

1. **Allowlist** — only named top-level paths are copied. `skills/brand/` is deliberately absent.
   A short denylist removes paths that sit inside an allowed directory but must still stay private.
2. **Skipped report** — everything not allowlisted is printed, and the script stops unless `--yes`.
3. **Denylist scan** — the payload is grepped for brand paths, Jira keys and company email
   addresses. Any hit aborts the publish. An empty payload is treated as a failure, not a pass.

The script copies files into an existing checkout; cloning, committing and pushing stay manual.
