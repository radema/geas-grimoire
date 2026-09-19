---
name: start-research
description: Bootstrap a new research project around a measurable claim — branch, scaffold research/, seed METHODOLOGY/CLAUDE.md/STATE, stub positioning + future_data_sources. Phase 0 of the research-loop (before any ADR or experiment).
---

# Start a Research Project

Phase 0 of the **research-loop methodology** (see reference at
`<research-repo>/research/METHODOLOGY.md`). This skill stands up the scaffolding that every
later phase assumes: a feature branch, the `research/` folder, the constitution (METHODOLOGY +
CLAUDE.md), an open STATE log, an empty positioning, and a stubbed data-source inventory.

> `<research-repo>` throughout this skill means the repo the user is working in — the research
> monorepo that holds `research/`. Resolve it from the current working directory; never assume a
> fixed absolute path.

**Out of scope for this skill** (handled later):
- Writing any ADR (first ADR is drafted *after* seed-paper ingestion).
- Scaffolding any `experiments/<NN_name>/` subfolder (that is the `start-experiment` skill).
- Creating persistent agents (deferred until ≥ 2× pattern reuse, per ADR 0001 v1 precedent).

---

## Step 1 — Intake & scope confirmation

Pose a short structured intake to the user. Do **NOT** invent answers; collect them all before
proceeding. Present as a numbered list:

1. **One-sentence measurable claim or research question** (must be falsifiable).
2. **Domain context** (e.g. "Italian socioeconomic disaggregation", "EU climate transition risk").
3. **Primary data sources expected** — catalog tables (`<catalog>.<schema>.<table>`) and/or
   external open-data candidates.
4. **First experiment shape** — synthetic vs real, scale (rows / units / years), expected runtime budget.
5. **Persistent-agent cap** — default **5** (per ADR 0001 v1 precedent). Confirm or override.
6. **HALT gates** to enforce — defaults from METHODOLOGY: after every ADR, after every experiment
   run, before any DB write, when two reasonable paths exist. Confirm or extend.
7. **Project folder name** — default `research/`, overridable.

**WAIT for user answers.** Echo back a compact summary and ask "Proceed with scaffold?" before any
file or branch action.

---

## Step 2 — Branch from the correct base

1. Run `git remote show origin` and `git status` to identify the active project and its base
   branch. **Most projects** use `origin/stage` or `origin/dev`, **NOT** `origin/main`.
2. If the base branch is ambiguous, **HALT** and ask the user explicitly: "Cut from `stage`,
   `dev`, or another base?"
3. Cut a feature branch named `feat/<slug>` (slug derived from the claim) from the confirmed base:
   ```bash
   git fetch origin
   git checkout -b feat/<slug> origin/<base>
   ```
4. Do **not** push yet. Do **not** open a PR.

---

## Step 3 — Scaffold the folder

Create the canonical layout under the project folder name from Step 1 (default `research/`). All
paths absolute:

```
<repo-root>/<project-folder>/
├── papers/
├── papers_md/
├── notes/
├── decisions/
├── experiments/
├── templates/
├── STATE.md
├── METHODOLOGY.md
├── CLAUDE.md
├── future_data_sources.md
└── .gitignore
```

Use `mkdir -p` for directories. Touch empty files only where the next step does not seed content.

---

## Step 4 — Seed methodology, CLAUDE.md, templates

**Source of truth (in order of preference)**:

1. **Bundled with this skill** (canonical, always available): `~/.claude/skills/start-research/templates/`. 9 templates: `adr-template.md`, `paper-note-template.md`, `positioning-template.md`, `state-log-template.md`, `data-sources-template.md`, `snapshot-readme-template.md`, `queries-sql-template.sql`, `experiment-report-template.md`, `pdr-srs-template.md` (per-module PDR+SRS design+requirements doc — used by `start-experiment` Kind-B docs-first scaffolding). **Always copy these** to `<project-folder>/templates/` as the per-project working copies (may diverge later per project needs).
2. **Reference repo**: if `<research-repo>/research/METHODOLOGY.md` exists, copy `METHODOLOGY.md` + `CLAUDE.md` from it (adjust scope + branch name). Otherwise prompt the user for the reference repo path, or write fresh from the bundled templates' meta-rules.

Adjust the seeded `CLAUDE.md`:
- Replace the project-specific scope paragraph with the user's domain context from Step 1.
- Replace branch name with the new `feat/<slug>`.
- Strip the "Persistent agents" section (no agents exist yet); leave a one-line placeholder:
  `> Persistent agents — none yet; promote to this section once a pattern reuses ≥ 2×.`
- Strip the project-specific Python package list; replace with `<TBD — populate at first
  experiment>`.

---

## Step 5 — Seed STATE.md

Append-only log. Write a single opening entry (UTC timestamp):

```markdown
# STATE — <project-folder>/<slug>

Append-only log. Timestamp + one line per significant action/decision.

- <UTC-NOW> — Branch `feat/<slug>` cut from `<base>`. Working folder = `<project-folder>/`.
- <UTC-NOW> — Scaffolded `papers/`, `papers_md/`, `notes/`, `decisions/`, `experiments/`, `templates/`. Seeded [[METHODOLOGY]] + [[CLAUDE]] + [[future_data_sources]].
- <UTC-NOW> — Claim (pre-ADR-0001): "<user's one-sentence claim>". Persistent-agent cap: <N>.
```

UTC format: `YYYY-MM-DDTHH:MMZ`. Use wikilinks `[[...]]` for all in-folder cross-references.

---

## Step 6 — Seed an empty positioning note

Copy `<project-folder>/templates/positioning-template.md` → `<project-folder>/notes/_positioning.md`. Leave the
template placeholders intact; the user fills them after seed-paper ingestion. Add a one-line header
note at the top:

```markdown
> Status: empty stub. Fill after seed-paper notes exist; before [[decisions/0001-...]].
```

---

## Step 7 — Seed `future_data_sources.md`

Copy `<project-folder>/templates/data-sources-template.md` → `<project-folder>/future_data_sources.md`. Then:

1. **Section A (in-catalog tables)**: if a Databricks MCP server is configured for this workspace
   (check for `databricks-mcp-server` in the available tools), offer to run `SHOW CATALOGS` and
   pre-populate the table from accessible catalogs. **HALT** and ask the user before issuing any
   SQL — even read-only. If declined or MCP unavailable, leave Section A with placeholder rows
   pulled from the user's "primary data sources expected" answer in Step 1.
2. **Section B (external open data)**: leave the table empty with just the header row. The user
   fills as candidates emerge during paper ingestion.
3. Pin `Snapshot date for inventory: <YYYY-MM-DD>` at the top.

---

## Step 8 — Seed `.gitignore`

Minimal scaffold:

```
.venv/
__pycache__/
*.pyc
.ipynb_checkpoints/
experiments/*/data/*.parquet
experiments/*/results/runs/
papers/*.pdf
!papers/.gitkeep

# Reproducibility artifacts — DO track
!experiments/*/data/queries.sql
!experiments/*/data/README.md
!experiments/*/src/
!experiments/*/results/leaderboard.csv
!experiments/*/results/report.md
```

Add empty `.gitkeep` files inside `papers/`, `papers_md/`, `notes/`, `decisions/`, `experiments/`
to keep the empty dirs tracked.

---

## Step 9 — HALT & present checklist

Do **NOT** commit, push, or proceed further. Print the following checklist for the user, then
**WAIT for explicit confirmation**:

```
Start-research scaffold complete. Confirm before any next phase:

- [ ] Branch correct? `feat/<slug>` from `origin/<base>`
- [ ] Scaffold complete? All folders + STATE + METHODOLOGY + CLAUDE.md + future_data_sources + .gitignore present
- [ ] Methodology + CLAUDE.md visible and scope-adjusted to this project?
- [ ] Persistent-agent cap acknowledged? (<N>, default 5)
- [ ] Ready to ingest seed papers / run `start-experiment` once ADR 0001 is accepted?
```

After confirmation, surface the natural next steps **without executing them**:

1. Drop seed PDFs into `<project-folder>/papers/`.
2. Convert to Markdown under `papers_md/`.
3. Write one structured note per paper in `notes/` using `[[templates/paper-note-template]]`.
4. Fill `[[notes/_positioning]]`.
5. Draft `[[decisions/0001-research-claim-and-evaluation]]` — **first HALT for PI approval**.

---

## Anti-patterns (do not do)

- **Do not** write any ADR in this phase — ADR 0001 belongs to the post-ingestion phase.
- **Do not** scaffold `experiments/<NN_name>/` — that is the `start-experiment` skill.
- **Do not** create persistent subagents — wait until a pattern reuses ≥ 2×.
- **Do not** push the branch or open a PR — research branches are long-lived and PR'd at experiment
  promotion time only.
- **Do not** issue catalog queries beyond `SHOW CATALOGS` without explicit user approval, and never
  issue any write SQL.
- **Do not** edit past STATE entries — append only.
- **Do not** cut the branch from `main` unless the user explicitly confirms — default is `stage`
  or `dev` depending on the repo.
