---
name: start-experiment
description: Scaffold a new experiment under research/experiments/<NN_name>/ from templates, given a user idea or the next item in a roadmap ADR. Supports two kinds — hypothesis-ablation (default) and staged-build/pipeline. Phase 5/7 of the research-loop (post-ADR, pre-run). Stops at HALT for PI review before any implementation.
---

# Start Experiment Protocol

Use this skill when the user wants to spin up a new experiment folder inside a Speckit-style research lab (`research/experiments/`). The skill is **scaffold-only**: it creates files, wires them to the driving ADR, appends one STATE line, then HALTs. It never runs code, never queries Databricks, never edits the ADR.

> `<research-repo>` below means the repo the user is working in — the research monorepo that holds
> `research/`. Resolve it from the current working directory; never assume a fixed absolute path.

This is phase **5 / 7** of the research-loop in [[research/METHODOLOGY]] (after ADR, before snapshot + run). Reference layouts: `research/experiments/01_baseline/`, `research/experiments/02_gnn/`. **Templates lookup**: prefer per-project `<project>/research/templates/` (project may have customized them); fallback to bundled `~/.claude/skills/start-research/templates/` when missing. If neither exists, HALT.

---

## Step 0: Determine experiment kind

Decide which of two kinds you are scaffolding (ask the user if not obvious; default to A):

- **Kind A — hypothesis-ablation** *(default)*. Tests one falsifiable claim with a headline
  metric + threshold and an A1/A2/… ablation menu. This is the canonical case (the 01–04
  pattern); the README MUST carry claim / metric / ablations. Steps 1–6 below apply as written.
- **Kind B — staged-build / pipeline**. A multi-stage build (e.g. ingest → graph → train → eval →
  operator) that is NOT a single hypothesis. There is no single headline-claim/ablation menu;
  instead the README carries a **stage DAG** with a per-stage acceptance check. Use Kind B when
  the ADR describes a system/pipeline rather than a comparison. Deltas vs Kind A are flagged
  **(Kind B)** inline below.

## Shared-code & data-layer rules (both kinds)

- **Thin consumer of shared code.** If a shared kernel package exists for this track under
  `research/common/<kernel>/` (e.g. `common/samlau/`), the experiment `src/` imports from it
  (`from common.<kernel>... import ...`) and scaffolds ONLY experiment-specific glue. NEVER
  re-stub or copy shared functions into the experiment. If a piece of logic will be needed by ≥2
  experiments, note it as a `lift-to-common` candidate in the README rather than duplicating it.
- **Data layer is a choice, not hardwired.** Two admissible sources — pick per the ADR / project
  policy and record it in the README + `data/README.md`:
  - *connect-and-cache* — a `storage.py` module + `conf/data.yaml` reads Unity Catalog directly
    and caches locally. Preferred where the project policy says so (e.g. SAM-downscaling track).
    No `data/queries.sql` snapshot manifest in this mode; document the UC sources in
    `data/README.md` instead.
  - *dbx-snapshot* — static Parquet under `data/` + `data/queries.sql`, produced by the
    `dbx-snapshot` agent. The default for hypothesis-ablation experiments unless project policy
    says otherwise.

---

## Step 1: Determine inputs

Accept one of:

1. **Free-form idea / problem statement** — user describes what they want to test.
2. **ADR reference** — e.g. `decisions/0003-roadmap.md` §"Session N+1", `decisions/0005-multi-indicator.md`.
3. **Both** — user refines an ADR session block.

If an ADR ref is given, **read the referenced section in full** via `Read` (don't summarize from memory). Extract:

- **Scope** — what's in / out for this experiment.
- **Goals** — falsifiable claim(s) this experiment tests.
- **Halt conditions** — when does the experiment end.
- **Ablations** — explicit A1/A2/... menu.
- **Metrics + thresholds** — headline + secondary, with numeric targets.
- **Splits / seeds / years** — eval protocol.
- **Model variants** — list of variants the run will produce.
- **Data sources** — catalog tables required (these go to `dbx-snapshot` later).

If anything in that list is missing or ambiguous in the ADR, **collect it as an Ambiguity** and surface in Step 6. Do not invent.

---

## Step 2: Numbering + name

1. `ls research/experiments/` → find max `NN`; new dir = `(NN+1)` zero-padded.
2. Ask user for a short slug (snake_case, ≤ 4 words). Offer a default derived from the ADR section heading if obvious.
3. Final folder: `research/experiments/<NN>_<slug>/` (absolute: `<research-repo>/research/experiments/<NN>_<slug>/`).

---

## Step 3: Scaffold from templates — docs-first, never pre-stub

Use `Write` once per file. Instantiate templates with ADR-derived content where known and
`TODO(ADR-<id>):` comments where unknown.

**No-pre-stub rule (mandatory).** The scaffold writes **specs + structure**, never empty-bodied
or TODO-stub `.py`. A pre-stubbed module with no consumer is the anti-pattern of record
(research `METHODOLOGY.md` §Anti-patterns + the track `CONVENTIONS.md` R11 — the deleted
`common/sam/` 2k-line `NotImplementedError` package). `src/` is created **empty** (`.gitkeep`); the intended
module tree is *documented* (in `docs/` for Kind B, in the README Structure field for Kind A), and
the `.py` files are written later by the `experiment-module` agent **from the spec**, post-HALT.

### Kind A — hypothesis-ablation (light)

```
research/experiments/<NN_name>/
├── README.md                # driving ADR, claim, metrics, splits, ablations, halt, intended src/ tree
├── config.yaml              # years, splits, seeds, models, features, ablations
├── docs/                    # OPTIONAL — one DESIGN.md (pdr-srs-template) only if the experiment is non-trivial
├── data/
│   ├── README.md            # snapshot-readme-template (empty inventory table)
│   └── queries.sql          # queries-sql-template (empty body + DESCRIBE block)
├── src/
│   └── .gitkeep             # EMPTY — modules written by experiment-module from README/config + (opt) DESIGN.md
└── results/
    └── runs/                # gitignored — created empty (touch .gitkeep)
```

The README Structure field names the intended modules (`data_loader.py`, `splits.py`, `models.py`,
`metrics.py`, `run.py`) and the model menu lives in the README ablation list + `config.yaml` — do
**not** pre-stub a `MODELS = {}` registry or empty signatures.

### Kind B — staged-build / pipeline (docs-first, default for pipelines)

```
research/experiments/<NN_name>/
├── README.md                # driving ADR pointer → docs/OVERVIEW; stage DAG; per-stage check; halt
├── config.yaml              # stage params + pipeline wiring (NOT an ablation menu)
├── conf/
│   └── data.yaml            # UC catalog/schema/source paths (connect-and-cache)
├── docs/                    # PDR+SRS doc set — THE design+requirements contract (pdr-srs-template)
│   ├── OVERVIEW.md          # system index: pipeline DAG, module map → INTENDED src/ tree, honesty boundary, YAGNI
│   └── <MODULE>.md          # one PDR+SRS per planned module/stage (ingest→graph→…→eval/operator)
├── notebooks/               # one thin .ipynb per stage — orchestration ONLY (read config, call modules, display)
├── data/
│   └── README.md            # UC sources (connect-and-cache); OMIT queries.sql
├── src/
│   └── .gitkeep             # EMPTY — each module written by experiment-module from its docs/<MODULE>.md spec
└── results/
    └── runs/                # gitignored (touch .gitkeep)
```

- `docs/OVERVIEW.md` is the authority: it carries the pipeline DAG, the **module map → intended
  `src/` tree** (each leaf links to its `docs/<MODULE>.md`), the honesty boundary (what may be
  claimed vs what rides the pipeline), and the YAGNI statement. Mirror the shape of the reference
  instance `experiments/100_samlau_gnn/docs/OVERVIEW.md`.
- Each `docs/<MODULE>.md` is instantiated from `templates/pdr-srs-template.md`: `Maps to`,
  requirements (mostly `[to-build]`), interface sketch, acceptance/gates, **Out-of-scope (YAGNI
  gate)**, traceability to the ADR. Shared code is imported from `common/<kernel>`, never re-stubbed.
- Notebooks are thin (no logic — see the track CONVENTIONS). They reference modules that don't
  exist yet; that is expected — they are wired but not runnable until `experiment-module` builds the
  `src/` files from the specs.

---

## Step 4: Wire to the driving ADR (README.md)

The new `README.md` must contain, in this order:

1. **H1**: `<NN_name> — <one-line goal>`
2. **Driving ADR**: wikilink `[[../../decisions/<NNNN-slug>]]` § exact section.
3. **Falsifiable claim** — quoted verbatim from the ADR.
4. **Headline metric + threshold** (e.g. `Theil-L within ≥ 0.006`).
5. **Secondary metrics + thresholds**.
6. **Splits** + **seeds** + **years**.
7. **Model variants** (table: name → backbone → projection → notes).
8. **Ablations** (A1, A2, ...) — bullet per ablation, mapping to a config switch.
9. **HALT condition** — when this experiment is "done" (verbatim from ADR halt-if).
10. **Run command** — placeholder: `research/.venv/bin/python research/experiments/<NN_name>/src/run.py`.
11. **Structure** — directory tree (copy from Step 3).
12. **Dependencies** — list new deps to install before run (e.g. `mlflow`, `torch-geometric`).

**(Kind B — staged-build variant.)** Fields 3–8 (falsifiable claim, headline/secondary metric,
ablations) do not apply. Replace them with:
- **2'. Design authority** — point the driving-ADR field at `[[docs/OVERVIEW]]` as the per-module
  design+requirements authority (ADR holds the decision; `docs/` holds the design). Keep the ADR wikilink too.
- **3'. Stage DAG** — ordered stages (ingest → graph → train → eval → operator) with the
  dependency arrows, mirrored by the `notebooks/`, the `docs/<MODULE>.md` per stage, and `databricks.yml` task wiring.
- **4'. Per-stage acceptance check** — what must hold for each stage to be "done" (e.g. graph
  builds with Ω mask valid; constraint fixture passes; aggregation re-projects within tol).
- **5'. Shared-kernel imports** — which `common/<kernel>` modules each stage consumes, and any
  `lift-to-common` candidates the experiment will surface.
- **11'. Structure** — reproduce the **intended `src/` tree from `docs/OVERVIEW`** (modules are
  documented there, not pre-stubbed in `src/`).
Keep fields 1, 2 (+ 2'), 9 (HALT), 10 (orchestration command — notebooks DAG, not a `run.py` path), 12 (deps).

---

## Step 5: Append to STATE.md

Append **one** UTC-timestamped line to `<research-repo>/research/STATE.md` (append-only, never edit existing):

```
- <YYYY-MM-DDTHH:MMZ> — [[experiments/<NN_name>]] scaffolded (docs-first) from [[decisions/<NNNN-slug>]] §<section>. <N> PDR+SRS spec docs + empty src/ (no stubs). HALT for PI review before implementation.
```

Do not put the claim, thresholds, or decisions in STATE — those live in the ADR and the new README.

---

## Step 6: Surface + HALT

Report back to the user, terse, in this order:

1. **Created files** — absolute paths, one per line, with line counts.
2. **Wiring** — which ADR section drove which README field.
3. **Ambiguities** (if any) — list each piece of information missing from the ADR (Kind A) or
   from a `docs/<MODULE>.md` spec (Kind B) that blocks implementation. For each: where it's needed
   and the suggested resolution.
4. **Recommended dispatch order** — concrete next steps:
   - **Data first**, per the chosen data layer (Step 0 rules):
     - *dbx-snapshot mode*: `dbx-snapshot` agent (data/queries.sql + parquets) — list the exact tables.
     - *connect-and-cache mode*: `experiment-module` agent builds `storage.py` against
       `conf/data.yaml` (UC read + local cache) — list the exact UC tables; no snapshot.
   - `experiment-module` agent(s) next — **Kind B: one invocation per `docs/<MODULE>.md` spec**
     (the spec is the contract — requirements, interface, acceptance, out-of-scope); **Kind A: one
     per intended module** named in the README/config. Scope each to disjoint files; modules import
     shared code from `common/<kernel>`, never re-stub it. The agent writes the real `.py` into the
     empty `src/` — the scaffold left no stub to fill.
   - Smoke run, then full run, then `results/report.md`.
5. **HALT** — explicit. Do not start implementation. Wait for PI confirmation.

---

## Specific behavior: continuing an existing ADR

When the user says "continue ADR <NNNN>" / "start the next experiment", read the driving ADR fully, extract its thresholds, splits, model variants, and ablations directly from that document — do not invent or reuse values from prior experiments. See `references/worked-example-adr0003.md` for a fully worked example of this extraction.

## Constraints

- **Don't write the ADR** — assume it exists. If it doesn't, send the user to a different skill (e.g. `start-research` for full lab bootstrap, or ask them to draft `decisions/<NNNN>-...`).
- **Don't run anything** — no `python`, no `databricks`, no `git`. Scaffolding only.
- **Don't snapshot data** — that's `dbx-snapshot`'s job, dispatched in the next session.
- **Use wikilinks** `[[path/to/doc]]` (no extension) for every cross-reference inside `research/`.
- **HALT** after Step 6. Implementation begins in the next turn, only after PI confirms the scaffold + the ambiguity resolutions.
- **One STATE line.** Append-only. Never edit prior entries.
- **Templates are the source of truth** for `data/README.md` and `data/queries.sql` — read `snapshot-readme-template.md` + `queries-sql-template.sql` from the lookup path defined at top of file (per-project first, bundled fallback) and instantiate; do not freelance the structure.
- **No emojis** in any generated file.
