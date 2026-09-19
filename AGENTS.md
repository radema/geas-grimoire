# AGENTS.md — contributor contract for this repo

This repo holds a personal Claude Code harness: skills, subagent definitions and hooks. There is no
application code, no test suite and no build — the deliverable is Markdown that agents read.

A curated subset is published to the public mirror `radema/geas-grimoire`; the rest stays private.

## Skill layout

```
skills/<category>/<name>/
├── SKILL.md       # required
├── scripts/       # optional
├── references/    # optional
├── templates/     # optional
└── assets/        # optional
```

Categories: `data-engineering`, `engineering`, `experimenting`, `productivity`, `brand`, `archive`.
`archive/` is repo-only and never symlinked live.

`SKILL.md` frontmatter needs exactly two keys:

```yaml
---
name: skill-identifier
description: One sentence saying when to use this skill.
---
```

## Conventions

- Directories: `kebab-case`.
- Python (inside `scripts/`): type hints on public APIs, Google-style docstrings, 4-space indent.
- YAML: 2-space indent.
- SQL: uppercase keywords.
- Prose: concise, imperative verbs ("Run", "Create"). Split long documents instead of growing one.

## The symlink rule

`~/.claude/skills/<name>` entries are **symlinks** into `skills/<category>/<name>/` in this repo.
Editing through either path is the same file, and both are fine.

Never replace a symlink with a plain directory. That forks the skill into two independently
editable copies. It has already happened twice — `ticket-loop` and `triage` — and reconciling them
cost real work.

`scripts/link-skills.sh` creates the links and refuses to overwrite a real directory.

## The `morning-brief` exception

`morning-brief` is the one skill deliberately not symlinked. The live version at
`~/.claude/skills/morning-brief` holds colleague email addresses, real Jira keys and private repo
names.

A sanitized copy lives here at `skills/productivity/morning-brief` and is what gets published.
Logic changes go in the repo copy; real config stays in the live one.

In the sanitized copy the team addresses, Jira project keys and repo list are read from config
files and environment variables that are deliberately **absent** here (`config/team.txt`,
`MORNING_BRIEF_TEAM`, and the equivalents in `collectors/github.py`), and `reference/format.md` is
rewritten with invented examples. The skill still runs without them.

Never copy the live `reference/format.md` or `collectors/jira.py` into this repo. They carry
colleague email addresses and 62 real Jira keys.

## Publishing

`scripts/publish-public.sh` decides what reaches the public mirror. It uses an allowlist of paths
plus a denylist content scan (brand paths, Jira keys, company email addresses) and refuses to
publish on any hit.

`skills/brand/` and the real `morning-brief` never reach the public repo. Run the script with no
arguments first — it is a dry run and prints the payload, what it skipped and the scan result.

## Forks of third-party skills

A skill forked from someone else's work carries a `FORK.md` next to its `SKILL.md`, stating:

- the upstream project and path,
- the upstream commit or date it was compared against,
- the exact local changes,
- and the line: "Do not refresh this skill blindly from upstream: re-apply these changes after any
  refresh."

Unmodified third-party skills are not vendored here. Install them at user scope from upstream and
credit them in `README.md`.

## Licence

Apache-2.0, except the Pocock-derived skills, which are MIT. See `README.md`.
