# docs-wiki — method reference

The durable "how and why" behind the skill. SKILL.md points here; read it before a `full`
run, or when you need the page template / conventions / known gotchas.

## Table of contents
1. The method (Bootstrapping Your Reality + Karpathy wikilinks)
2. Two audiences, one artifact
3. Output structure
4. Page template
5. Wikilink convention
6. Orchestration principles (model routing, concurrency, one branch)
7. Known gotchas (learned the hard way)
8. Review checklist

---

## 1. The method

Two ideas combined:

- **Bootstrapping Your Reality** (recursive-README summarization): document a codebase
  *bottom-up*. Write a `README.md` at each leaf directory ("purpose of this dir + one line
  per file"), then roll up one level at a time ("read the child READMEs + this dir's own
  code, summarize"). Cheap, hierarchical, and an agent can understand a system by reading
  the README tree instead of parsing all the source. Assume ~50% first-draft accuracy —
  verification is a required step, not an afterthought.
- **Karpathy-style LLM-wiki**: a curated set of concept + how-to pages connected by
  `[[wikilinks]]`, written for humans to navigate. This is the entry point layer on top of
  the leaf READMEs.

The skill produces both: leaf/rollup READMEs (code-adjacent, for agents) **and** a
`docs/wiki/` hub (navigable, for humans). The hub links *out* to the repo's existing docs
rather than duplicating them — find and reuse what's already written.

## 2. Two audiences, one artifact

Every wiki page opens with a plain-language **Overview** a non-technical teammate can read,
then goes technical. This dual-audience rule is the whole point — docs that only serve
engineers fail the people who most need orientation, and docs that only serve
non-technical readers are useless for actual work. Serve both, in that order, on each page.

## 3. Output structure

```
<repo>/
  <dir>/README.md            leaf: purpose + file-by-file enumeration + links
  <parent>/README.md         rollup: summarizes child READMEs + own code
  docs/wiki/
    Home.md                  what the repo is + wikilinked index of everything
    Architecture.md          how the pieces fit; request/data lifecycle
    <Domain>.md              one concept page per bounded context/domain
    How-to-<task>.md         one per routine operation (add entity, run tests, deploy…)
    Glossary.md              domain + tech terms
    README.md                the wiki's own conventions (explains the wikilink rule)
```

Language: match the repo's dominant doc language unless told otherwise; if the user picks a
language, apply it to **everything** including pre-existing READMEs you touch (translate
them, don't leave a mixed-language wiki).

## 4. Page template

Every concept/how-to page:

```markdown
# <Title>
## Overview
Plain language, no jargon — what this is and why it exists. 3–6 sentences.
## How it works    (concept)   |   ## Steps   (how-to)
Technical detail; cite `path:line` for non-obvious claims; fenced commands for how-tos.
## Related
[[Wikilinks]] to sibling pages + relative links to code READMEs and existing docs/.
## Source
The files/dirs this page documents.
```

Leaf README: `# <dir>` + plain-language purpose + file-by-file list + a `## Related` block
with `[[wikilinks]]` and relative links to sibling/child READMEs.

**Progressive disclosure**: open every major section with a one-line TL;DR before detail,
and cap heading depth at ~4 levels (e.g. Architecture → Subsystem → Component → Method).
Readers should get the gist from the top of each section without scrolling.

## 5. Wikilink convention

- `[[Page-Name]]` = an Obsidian-style link to `docs/wiki/Page-Name.md` (no extension).
- For code/existing-docs targets, ALSO add a normal relative markdown link so GitHub
  navigation works, e.g. `see the [Geo module](../../apps/api/src/modules/geo/README.md)
  ([[Geo]])`.
- No dangling links: a `[[Target]]` must have a matching `docs/wiki/Target.md`.
- Document this rule in `docs/wiki/README.md` so future editors follow it.
- `scripts/check-wiki-links.sh` enforces both halves — run it in the review pass.

## 6. Orchestration principles

- **Structure-first (two-pass).** Before writing page bodies, emit the *plan*: the list of
  wiki pages to create (a TOC) and the README coverage map. Show it to the user for a quick
  edit if they're around, then write content against it. Deciding structure and writing
  prose are different jobs; separating them prevents a wasted swarm producing the wrong
  page set. (This is what every serious tool in this space does — deepwiki's `toc.yaml`
  first pass, microsoft deep-wiki's "always TOC before pages".)
- **Model routing**: Explore agents + doc-writers = Sonnet (they synthesize unfamiliar
  code into accurate plain prose — Haiku is too shallow and Opus is wasteful at this
  volume). Reserve Opus for a single review pass, if any; often the main thread reviews.
- **Concurrency cap**: default 5 concurrent subagents. Higher risks rate limits and makes
  the orchestrator's synthesis unwieldy.
- **One branch, no worktree isolation for writers.** All work lands on a single `docs-*`
  branch. Doc-writers edit the shared working tree directly — worktree isolation would
  fragment the branch. Collision-safety comes from giving each writer a **disjoint** set of
  files/dirs to own, plus the concurrency cap. Explore agents are read-only, so they never
  collide.
- **Bottom-up, in waves**: explore → leaf READMEs → rollup READMEs → wiki hub → review.
  Commit after each wave to checkpoint.
- **Scratch discipline**: Explore agents write structured reports (not file dumps) that the
  orchestrator feeds to writers. If you stage them on disk (e.g. `.claude/scratch-wiki/`),
  they are *scratch* — never git-add them, and delete them at the end. If you cite them as
  "Source" in a page, that citation dies when the scratch is deleted (a real bug seen in
  the field) — cite the real code/doc files instead.
  **Scratch means what this run created and will delete — nothing else.** A file git already tracked
  at the base commit is not scratch, whatever folder it sits in, including one named `scratch`: it is
  a citable source. Test it, don't guess: `git ls-files --error-unmatch <path>` at the base. You may
  translate such a file if the run's language rule requires it, but never relocate or delete one — if
  a tracked file looks like junk, say so in the report and leave it.

## 7. Known gotchas

- **Deleted-scratch citations**: writers love to cite their research notes in a page's
  `## Source`. When scratch is cleaned up, those become dead references. Tell writers to
  cite real files only.
- **Dead paths from stale research**: a writer relying on an early Explore snapshot may
  cite a file that a later wave changed or that never existed. The review pass must
  spot-check cited `path:line` against the current tree.
- **Mixed language**: writers "match existing convention" and leave some READMEs in the old
  language. If the user asked for one language, translate the stragglers.
- **Repo-specific clobber traps**: many repos have codegen/scaffold scripts that overwrite
  curated files. Before a run, scan the repo's own CLAUDE.md/AGENTS.md/README for "do not
  run X" warnings and pass them into the orchestration prompt as hard constraints.
- **Idle orchestrator is normal**: a background orchestrator goes idle while its
  subagents run; that is expected, not a stall. Check disk (commits/files) to judge
  progress, don't spam it.
- **Stale-parent rollups (the maintenance killer)**: rollup READMEs summarize their
  children. When a child dir changes, its ancestor rollups silently go stale — a folder
  edit invalidates every README above it. So in `maintenance` and `scoped` runs, after
  updating a leaf README you MUST walk up and refresh every ancestor rollup to the repo
  root, and any wiki page that cites the changed area. Never update a leaf in isolation.
- **Citation rot**: `path:line` citations and remote blob links break when files move or
  lines shift. Re-run the review pass (link check + spot-check) on every maintenance run,
  not just the initial build.

## 8. Review checklist

1. `bash scripts/check-wiki-links.sh <wiki-dir> <scan-root>` → zero dangling/broken
   (minus intentional syntax examples).
2. Diff is docs-only: `git diff --name-only <base>..HEAD | grep -v '\.md$'` is empty.
3. Fact spot-check: pick ~10 cited `path:line` claims and verify against real code.
4. Readability: every page's Overview is genuinely non-technical.
5. Coverage: every zone/module has a README; every routine op has a how-to.
6. No scratch **this run created** was committed; no page cites a path this run deletes. Files
   tracked before the run are sources, not scratch.

---

## 9. Optional enhancements (not core — adopt when a team asks)

These are validated ideas from prior art (deepwiki-skill, microsoft deep-wiki,
karpathy-llm-wiki, fiberplane/drift) that add value but also weight/deps. Keep the core
skill dependency-free; reach for these on request:

- **Drift anchoring for CI gating**: store, per page, an anchor to the code it documents so
  a CI job can flag stale docs. Cheapest = git blob SHA of each cited file; better =
  AST-hash (survives reformatting) via a tool like `fiberplane/drift` (`drift check
  --changed <path>`, merge-blocking). Our `maintenance` mode approximates this
  dependency-free via `git diff` since the last `docs(wiki)` commit — good enough for most
  repos; only reach for real drift tooling when a team wants a hard CI gate.
- **`llms.txt` navigation export**: a `/llms.txt` (index) + `/llms-full.txt` (single
  high-signal concatenation of the wiki) helps external integrator agents. Generate from
  the wiki if the repo serves docs publicly.
- **Mermaid diagrams**: architecture pages benefit from a diagram; if you add Mermaid,
  validate it (fenced ```mermaid renders on GitHub; a bad diagram is worse than none).
- **Remote citation links**: `[file:line](<repo-url>/blob/<branch>/file#Lline)` gives
  clickable GitHub navigation in addition to the local relative link.
