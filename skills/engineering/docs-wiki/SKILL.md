---
name: docs-wiki
description: >-
  Generate or maintain a Karpathy-style LLM-wiki for a codebase — bottom-up per-directory
  README rollups PLUS a curated docs/wiki/ hub of concept + how-to pages connected by
  [[wikilinks]], written for BOTH non-technical teammates and AI agents. Runs an orchestrated
  Sonnet subagent swarm (explore → write → review) on a single docs-* branch. Use this
  whenever the user wants to document a repo, bootstrap onboarding docs, build a repo wiki
  or knowledge base, "make the codebase understandable", generate READMEs across a project,
  refresh docs after code changes, or document a specific folder — even if they don't say
  the word "wiki". Three modes: full (initialize / brownfield), maintenance (update docs to
  match code changes / fix doc drift), and scoped (document one folder). Prefer this skill
  over ad-hoc doc writing for any multi-directory documentation job.
disable-model-invocation: true
---

# docs-wiki

Build and maintain an LLM-wiki: a set of per-directory `README.md` files (bottom-up rollup)
plus a navigable `docs/wiki/` hub of `[[wikilinked]]` concept and how-to pages. Every page
serves a non-technical reader first (plain-language Overview) and an engineer/agent second
(technical detail with `path:line` citations). The hub links out to the repo's existing
docs rather than duplicating them.

**Read `references/method.md`** for the why, the page template, conventions, and the
hard-won gotchas. **Use `references/orchestration-prompt.md`** as the swarm dispatch prompt.
**Run `scripts/check-wiki-links.sh`** in the review pass.

## Step 1 — Pick the mode

Ask the user if it's not obvious from their request:

| Mode | When | What it does |
|---|---|---|
| **full** | No wiki yet, or a brownfield repo needing full coverage | Explore the whole repo → leaf + rollup READMEs → `docs/wiki/` hub → review. |
| **maintenance** | A wiki exists; code changed and docs drifted | Diff since the last `docs(wiki)` commit → update only affected READMEs + pages → re-roll-up ancestors → review. |
| **scoped** | Document one folder/subtree | Explore just that path → its leaf READMEs → refresh ancestor rollups → its wiki page(s) → review. |

## Step 2 — Confirm the few decisions that change the output

Settle these before dispatching (offer recommendations, don't over-ask):

- **Branch**: a single `docs-*` branch (e.g. `docs-wiki`). All work lands there.
- **Language**: match the repo's dominant doc language unless the user picks one. Whatever
  is chosen applies to *everything*, including pre-existing READMEs you touch (translate
  stragglers — no mixed-language wiki).
- **Reviewer**: the main thread (you), a dedicated Opus review agent, or skip. The main
  thread is usually enough and cheapest.
- **Concurrency cap**: default 5 concurrent subagents.
- **Repo-specific traps**: skim the repo's `CLAUDE.md`/`AGENTS.md`/`README` for "do not run
  X" scaffold/codegen scripts and any conventions — pass them into the prompt as hard
  constraints. This is the single most repo-specific step; don't skip it.

## Step 3 — Run the swarm

For anything beyond a few directories, dispatch a background `orchestrator` agent (Sonnet)
with the filled-in `references/orchestration-prompt.md` — **from the main thread only.** If you
are already running as an orchestrator, run the wave plan yourself and dispatch leaf agents
directly; never spawn a second orchestrator. Keep the mode block you need, delete the others,
and fill every `<PLACEHOLDER>`. For a tiny repo, run the same wave plan inline yourself.

Core orchestration rules (full detail in `references/method.md` §6):

- **Structure-first**: in `full` mode, produce the wiki TOC + README coverage map *before*
  writing page bodies (Wave 1.5). Offer it to the user to edit if they're around.
- **Model routing**: Explore agents + doc-writers = Sonnet; reserve Opus for one review
  pass at most.
- **One branch, no worktree isolation for writers**; give each writer disjoint files so
  they can't collide. Explore agents are read-only.
- **Bottom-up in waves**, commit after each: explore → leaf READMEs → rollups → wiki hub.
- **Stale-parent rule** (maintenance & scoped): when a child dir changes, its ancestor
  rollup READMEs go stale — always walk up and refresh them to the repo root. Never update
  a leaf in isolation.

While a background orchestrator runs it will go **idle between dispatches** — that is normal,
not a stall. Judge progress by checking commits/files on disk, not by pinging it.

## Step 4 — Review (always)

Whoever reviews (default: you) runs this gate before calling it done:

```bash
bash <skill-dir>/scripts/check-wiki-links.sh docs/wiki .   # zero dangling/broken
git diff --name-only <base>..HEAD | grep -v '\.md$'         # must be empty (docs-only)
```

Then: spot-check ~10 cited `path:line` claims against the real tree (catches citation rot
and stale-research paths); confirm every page Overview is genuinely non-technical; confirm
none of **this run's own** scratch was committed and no page cites a path this run deletes. See
`references/method.md` §8.

## Step 5 — Wrap up

Commit on the `docs-*` branch. Open a PR only if the user asks. Report: branch, files
added/changed, the wiki page index, and any gaps that couldn't be filled — flag gaps
honestly rather than inventing facts to fill them.

## Optional enhancements

Drift-anchoring for CI gating, `llms.txt` export, Mermaid diagrams, remote blob citation
links — all validated but with added weight/deps. Keep the core dependency-free; reach for
these only when a team asks. See `references/method.md` §9.
