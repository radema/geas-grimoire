# geas-grimoire 📜

The personal Claude Code harness: the skills, subagents and hooks I actually run. Each skill is a
"spell" — the prompt and logic that drives an agent through one kind of work. The name nods to my
other project, **[geas-ai](https://github.com/radema/geas-ai)**: `geas-ai` is about *binding and
sealing* agentic artifacts (governance), `geas-grimoire` is about the *invocation*. This repo is
private; a curated subset is published to the public mirror `radema/geas-grimoire` by
`scripts/publish-public.sh`.

## Layout

| Path | What it holds |
|---|---|
| `skills/<category>/<name>/` | The skills. Categories: `data-engineering`, `engineering`, `experimenting`, `productivity`, `brand`, `archive`. |
| `agents/` | Claude Code subagent definitions (`scout`, `minion`, `implementer`, `code-reviewer`, the speckit runners). |
| `hooks/` | Hook scripts, plus `settings.reference.json` showing how they are wired. |
| `scripts/` | `link-skills.sh`, `list-skills.sh`, `publish-public.sh`. |
| `archive/` | Retired top-level material kept for reference, not installed. |
| `docs/` | Design notes, technical notes, future ideas. |
| `LICENSES/` | Licence texts of third-party work this repo derives from. |

## Install

Skills are installed by symlinking a skill directory into `~/.claude/skills/<name>`. A device can
install any subset — there is no all-or-nothing step.

```bash
ln -s "$PWD/skills/productivity/debrief"  ~/.claude/skills/debrief
ln -s "$PWD/skills/engineering/triage"    ~/.claude/skills/triage
```

`scripts/link-skills.sh` does the same for a chosen list:

```bash
./scripts/link-skills.sh --list                    # what exists, and what is linked
./scripts/link-skills.sh debrief triage wayfinder  # link these
./scripts/link-skills.sh --category productivity   # link a whole category
./scripts/link-skills.sh --dry-run handoff         # show, change nothing
```

It never deletes: a real directory already sitting at the target is reported and skipped.

`scripts/list-skills.sh` prints the catalogue (`--stdout`) or refreshes it in this README.

`agents/` and `hooks/` are **copied**, not symlinked:

```bash
cp agents/*.md    ~/.claude/agents/
cp hooks/*.sh     ~/.claude/hooks/
```

`hooks/settings.reference.json` shows how the hooks are wired into `~/.claude/settings.json`.
`settings.json` itself is not versioned here.

## Skill catalogue

<!-- BEGIN SKILLS -->

## Data Engineering

- **assess-indicator** — Audit a single Gold-layer KPI/indicator column against its official statistical definition (Eurostat / ISTAT / ILO / Worldbank / OECD / SDMX) and trace it ba...
- **quality-analysis** — Structured Gold-table quality investigation for Delta Lake / Databricks Lakehouse pipelines.
- **read-data-contract** — Programmatically extract metadata from YML-based data contracts (dbt schema.yml, metadata.yml, *_contract.yml, *_schema.yml, etc.) to infer column names, dat...

## Engineering

- **docs-wiki** — Generate or maintain a Karpathy-style LLM-wiki for a codebase — bottom-up per-directory README rollups PLUS a curated docs/wiki/ hub of concept + how-to page...
- **self-harness** — Mine past Claude Code sessions for recurring failure patterns, then propose and validate targeted fixes to the harness — CLAUDE.md, skills, agents, hooks, se...
- **spring-cleaning** — Audit and clean up stale Claude Code configuration — outdated CLAUDE.md rules, dead or overlapping skills, and stale hooks — at user scope (~/.claude) or rep...
- **technical-doc-writer** — Guide for creating effective, structured, and token-efficient technical documentation.
- **test-suite-triage** — Review the whole test suite (or a named subpart) to find trivial, redundant, and mergeable tests without losing real coverage.
- **ticket-loop** — Autonomously implement a triaged Jira story's ready-for-agent subtask queue as parallel trails (dependency chains) in per-trail worktrees on one story branch...
- **triage** — Move issues and external PRs through a state machine of triage roles — categorise, verify, grill if needed, and write agent-ready briefs.
- **wayfinder** — Plan a huge chunk of work — more than one agent session can hold — as a shared map of decision tickets on your issue tracker, and resolve them one at a time...
- **writing-great-skills** — Reference for writing and editing skills well — the vocabulary and principles that make a skill predictable.

## Experimenting

- **falsifiability-check** — Pre-report sanity check for ML / research experiments.
- **lift-to-common** — Mechanical refactor — lift a function (plus its transitive private helpers) from `experiments/<NN>/src/<file>.py` to `research/common/<module>.py`; rewrite i...
- **phase-iterate** — Standardize the smoke-fail → diagnose → minimal-patch → re-smoke loop for ML / research experiments where a single design pass rarely passes the acceptance g...
- **research-loop** — Bootstrap a daily continuation of an ongoing research-loop session in a Speckit-style research lab (research/ folder with METHODOLOGY.md, STATE.md, decisions...
- **start-experiment** — Scaffold a new experiment under research/experiments/<NN_name>/ from templates, given a user idea or the next item in a roadmap ADR.
- **start-research** — Bootstrap a new research project around a measurable claim — branch, scaffold research/, seed METHODOLOGY/CLAUDE.md/STATE, stub positioning + future_data_sou...
- **tdd-implementation** — Enforces Test-Driven Development methodology
- **write-experiment-report** — Generate a robust results/report.md for a research experiment from leaderboard.csv + driving ADR + per-run JSONs.

## Productivity

- **debrief** — Systematically wrap up a session by summarizing progress, scouting for reusable skills, and cleaning up context.
- **design** — Puts the session into design mode -- batched clarifying questions and a tracked decision map, zero code edits, until the user types BUILD or /design off.
- **git-sweep** — Sweep a repo's git residue — stale local worktrees and stale local branches — deciding which are safe to delete and then deleting the ones the user names.
- **handoff** — Compact the current conversation into a handoff document in ~/.claude/handoffs/ so a fresh agent or a later session can pick the work up without re-deriving it.
- **llm-council** — Run any question, idea, or decision through a council of 5 AI advisors who independently analyze it, peer-review each other anonymously, and synthesize a fin...
- **memory-triage** — Periodic memory-system triage sweep — promote/expire/clean personal auto-memory and repo memory vaults per the tiered promotion/demotion rules bundled in ref...
- **morning-brief** — Write today's morning brief from an already-built context file.
- **prompt-architect** — Build, critique, or optimize prompts for Claude — Claude.ai chat, API system prompts, or Claude Code CLAUDE.md / slash command / agent definitions.
- **research** — Investigate a question against high-trust primary sources and capture the findings as a Markdown file in the repo.

<!-- END SKILLS -->

## Derived from

Five skills here are forks of [Matt Pocock's skills](https://github.com/mattpocock/skills)
(MIT, "Copyright (c) 2026 Matt Pocock"). The licence text is kept at
`LICENSES/mattpocock-skills-MIT.txt`.

| Skill here | Upstream |
|---|---|
| `skills/engineering/triage` | `skills/engineering/triage` |
| `skills/engineering/wayfinder` | `skills/engineering/wayfinder` |
| `skills/engineering/writing-great-skills` | `skills/productivity/writing-for-agents` |
| `skills/productivity/handoff` | `skills/productivity/handoff` |
| `skills/productivity/research` | `skills/engineering/research` |

Each carries a `FORK.md` recording the local changes. Do not refresh them blindly from upstream.

The rest of his set is installed at user scope unmodified and is deliberately **not** vendored
here — there is nothing to keep in sync, so keeping a copy would only create drift.

## Credits

Skills that used to live in this repo and were removed on 2026-09-19, because they were unmodified
imports. Credit stays here; the code is upstream where it belongs.

| Upstream | Skills removed |
|---|---|
| [superpowers](https://github.com/obra/superpowers) by obra | `brainstorming`, `using-git-worktrees`, `using-superpowers`, `writing-plans`, `writing-skills`, `executing-plans` |
| [Anthropic](https://github.com/anthropics/skills) | `skill-creator`, `doc-coauthoring` |
| [GitHub Spec Kit](https://github.com/github/spec-kit) | 14 skills (`speckit-memory-md-*`, `speckit-onboard-*`) |
| no recorded upstream | `algorithm-translator`, `build-knowledge`, `code-reviewer`, `jules-cli`, `opencode-cli`, `opencode-config-advisor`, `skill-scout`, `word-doc` |

The `speckit-*` set installed at user scope also includes contributions by `dsrednicki` and
`ismaelJimenez`.

`skills/productivity/llm-council` stays: it is my own implementation using Claude sub-agents, but
the method is Andrej Karpathy's LLM Council.

## Licence

This repo is Apache-2.0 — see `LICENSE`. The five Pocock-derived skills listed above are MIT.
