---
name: research-loop
description: Bootstrap a daily continuation of an ongoing research-loop session in a Speckit-style research lab (research/ folder with METHODOLOGY.md, STATE.md, decisions/, experiments/<NN_name>/LOG.md + results/). Use this skill at the START of a session when the user says things like "continue the research loop", "where were we", "resume the experiment", "what's the state of the research", "pick up where we left off", "kick off today's research session", or any phrasing that implies recovering prior context for an ongoing research project. Reads STATE.md tail + active experiment LOG.md BLOCKERS + driving ADR + latest results/report.md + results/peer_review.md + recently-added notes, then emits a dependency-ordered task list and proposes skill routing (phase-iterate / falsifiability-check / write-experiment-report / peer-reviewer) while respecting HALT gates and ADR-scope discipline. Phase 8/8 (continuation) of the research-loop, complementary to start-research (Phase 0) and start-experiment (Phase 5).
---

# Research-Loop Continuation Protocol

Use this skill when the user wants to **resume an in-flight research project** under `research/` rather than start a new one. The aim is to recover full session context fast and to surface a concrete, dependency-ordered task list before any work touches code.

This is the "continuation" phase of the loop defined in [[research/METHODOLOGY]]. Companion skills:

- `start-research` — bootstrap a brand-new research project.
- `start-experiment` — scaffold a new experiment under an existing project.
- `phase-iterate` — iterate inside one experiment when smoke fails.
- `falsifiability-check` — pre-report gate (ablation distinctness, gradient flow, gate↔ADR mapping).
- `write-experiment-report` — produce `results/report.md` from a leaderboard.
- `debrief` — wrap up at session end.

Note: `peer-reviewer` (agent, not a skill) exists only in the research monorepo. In repos without it, skip the peer-review dispatch step and note in the report that peer review was unavailable.

This skill is **read-only context recovery + task framing**. It never edits code, never runs experiments, never amends an ADR. It HALTs to PI before any downstream work.

---

## Step 1: Locate the research root

Default: `research/` from the project working directory. If a monorepo with multiple research roots (e.g. `<project>/research/`), ask the user which root.

Verify it has the expected scaffold:

- `METHODOLOGY.md` + `CLAUDE.md` (governance)
- `STATE.md` (append-only session log)
- `decisions/` (ADRs)
- `experiments/<NN_name>/` (one folder per experiment)
- optional: `notes/`, `papers_md/`, `templates/`, `future_data_sources.md`

If the scaffold is missing, this isn't a continuation case — HALT and suggest `start-research` instead.

---

## Step 2: Read the canonical context surface (in order)

Read each of these. Do **not** summarize from memory — re-read each session because state shifts daily.

1. **`research/CLAUDE.md`** — folder-scoped rules (ADR-scope discipline, HALT gates, subagent routing).
2. **`research/METHODOLOGY.md`** §"Phases" + §"HALT conditions" — only re-read if rules have changed since last session; otherwise rely on CLAUDE.md.
3. **`research/STATE.md` tail** — last ~40 entries (or last 200 lines if shorter). This is the highest-signal source: it tells you what happened yesterday, what BLOCKERs were opened, what the last HALT was waiting on. Always UTC-timestamped.
4. **Latest ADR** — find `decisions/` and pick the highest-numbered ADR whose status is `accepted` or `proposed`. Read its current version in full (ADRs are versioned in place, so version footer = current state). Pay attention to §"Halt conditions", §"Roadmap", §"Scope this session".
5. **Active experiment** — identify the most recently touched `experiments/<NN_name>/` (by `git log -1 --format=%cI -- experiments/<NN>/` or by STATE entry). Read:
   - `LOG.md` §BLOCKERS (open bugs) + last few iteration entries
   - `results/report.md` if it exists (current outcome snapshot)
   - `results/peer_review.md` if it exists (last verdict + open findings)
6. **Recent notes** — list `notes/*.md` modified in the last ~7 days (`git log --since='7 days ago' --name-only -- notes/`). Read any whose subject is referenced by the open BLOCKERs or by the latest ADR's roadmap.
7. **Continuation prompt, if any** — many projects keep a `decisions/research-loop.md` or `decisions/N+X-continuation.md` carrying the next-session task list. If present, read it; treat as draft tasks (PI may have revised since).

Delegate the bulk-read to an `Explore` subagent if the surface is large (>10 files or >2k lines), so the main thread stays clean. The subagent should return: STATE tail summary, list of open BLOCKERs with acceptance criteria, latest ADR's halt conditions, last peer-review verdict, recent-notes titles.

---

## Step 3: Build the session snapshot

Synthesize what you read into a compact snapshot. Surface it to the user before any task proposal. Template:

```markdown
## Session snapshot — <UTC timestamp>

**Project**: <claim from STATE / ADR 0001>
**Branch**: <current git branch>
**Last session**: <date of last STATE entry> — <one-line summary>

**Active experiment**: `experiments/<NN_name>/`
- Last outcome: <verdict from latest report.md / peer_review.md>
- Coverage: <X% of planned sweep, if known>

**Open BLOCKERs** (from LOG.md):
- BUG-NNN — <one-line description> — acceptance: <criterion>
- ...

**Latest ADR**: `decisions/<NNNN-name>.md` v<X> (<status>)
- Halt condition: <quoted from ADR>
- Next-session scope: <quoted from ADR §roadmap>

**Recent notes** (last 7d): <list>
```

Keep it tight — this is a reorientation, not a recap. Anything the user already knows from being in the conversation can be elided; anything they'd need to recall after a day off must be present.

---

## Step 4: Propose a dependency-ordered task list

Derive tasks from: open BLOCKERs (highest priority — they gate everything), the latest ADR's "next session scope", any peer-review findings tagged `blocker` or `should-fix`, and any continuation prompt left in `decisions/`.

Order by dependency:

1. **Mandatory blockers** — bugs that prevent the next sweep / report. Each goes through `phase-iterate` (smoke-fail → patch → re-smoke, capped at N_MAX=4).
2. **Symmetric / control experiments** — anything needed to make the headline comparison falsifiable (e.g. a missing ablation that isolates one factor).
3. **Gradient / sanity probes** — covered by `falsifiability-check`.
4. **Full sweep** — only after 1–3 land.
5. **Pre-report gate** — `falsifiability-check` again, on the sweep leaderboard.
6. **Report + peer review** — `write-experiment-report` → `peer-reviewer` agent.
7. **Optional ingest** — new papers / data sources that could enter scope.

For each task, name the routing:

- **Skill**: which skill drives it (`phase-iterate`, `falsifiability-check`, etc.).
- **Subagent model**: Haiku (trivial mechanical), Sonnet (mechanical with contract), Opus (architecture / judgment). Per `/root/.claude/CLAUDE.md`, delegate mechanical work — main thread orchestrates only.
- **HALT gate**: where the task pauses for PI review.
- **Acceptance criterion**: the falsifiable check that says "done".

Make HALT gates explicit. Standard gates from METHODOLOGY:

- After each bug fix → smoke + acceptance verification → HALT.
- After symmetric ablation lands → dry-run a few seeds → HALT.
- After `falsifiability-check` PASS → HALT for PI confirmation before any long sweep.
- After sweep → write report → peer review → HALT.

---

## Step 5: Flag ADR-scope risks

While reading, watch for cases where the next-session work would tempt an ADR amendment that doesn't belong in one. Per `research/CLAUDE.md`:

> ADR amendments contain cross-experiment decisions ONLY. Per-experiment iteration history → `LOG.md`. Aggregate outcomes → `results/report.md`.

If a task naturally produces per-experiment findings (patch logs, smoke diagnoses, loss-formulation tweaks), flag in the task list: "writes to `LOG.md`, NOT ADR." This pre-empts a common drift.

---

## Step 6: Out-of-scope reminder

End the snapshot with an explicit out-of-scope list, derived from the latest ADR's "out of scope this session" block (or from prior STATE entries if the ADR doesn't carry one). This stops scope creep before it starts. Typical items: deferred ablations, future indicators, production / monorepo promotion, MLflow integration, etc.

---

## Step 7: HALT for PI

Stop. Present the snapshot + task list + scope reminder. Ask one direct question:

> "Start with task 1 (<name>)? Or reorder / drop / add?"

Wait for the user. Do **not** dispatch subagents, do **not** open files for editing, do **not** read further. The user may redirect the priority — they have context this skill cannot see (calendar pressure, parallel work, fresh ideas).

Only after PI confirmation: dispatch the chosen task via its routing skill.

---

## Notes on parallelism

When two BLOCKERs touch independent files, dispatch their `phase-iterate` invocations in parallel via separate `Agent` calls in one message. When they share a file or a hypothesis (e.g. BUG-A's diagnosis says "symptom of BUG-B"), serialize and start with the root cause.

## Notes on continuation prompt files

If the project keeps a rolling `decisions/research-loop.md` (or similar) that's overwritten each session with the next set of tasks, you may use it as the seed task list — but always cross-check against STATE + LOG. Continuation prompts age fast: a fix that landed yesterday may still be listed as TODO.

## Anti-patterns

- Re-reading entire `METHODOLOGY.md` every session — it rarely changes; rely on `CLAUDE.md` summary.
- Reading all experiment LOGs — only the active one matters; archived experiments are frozen.
- Summarizing the snapshot from prior conversation memory instead of re-reading files — state drifts; re-read.
- Proposing tasks before reading the latest peer-review verdict — peer review often re-prioritizes.
- Amending an ADR to record a bug fix — that's a `LOG.md` entry. ADRs change only when cross-experiment policy changes.
- Launching a long sweep before `falsifiability-check` PASSES — wastes compute and ships unfalsifiable claims.

## Why this skill exists

Daily research work loses state fast: smoke failures, half-applied patches, half-written reports, peer-review findings still open. Without a disciplined re-entry pass, the next session either re-does work already done, or skips a HALT gate and ships a broken claim. This skill makes re-entry mechanical, so the human time goes to judgment, not bookkeeping.
