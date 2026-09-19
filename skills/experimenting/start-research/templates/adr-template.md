<!--
  Purpose   : Architecture Decision Record — captures a committed project-level decision with context,
              alternatives, and consequences.
  When      : Write one whenever a non-trivial design choice must be locked before proceeding.
              Mandatory for: claim + eval protocol (ADR 0001), central architecture (ADR 0002),
              roadmap choices. Optional for smaller decisions that STATE.md can absorb.
  Where     : research/decisions/<NNNN>-<slug>.md
  Links to  : [[notes/_positioning]], [[notes/<relevant-paper>]], [[STATE.md]]
  Linked from: STATE.md entry at time of HALT, subsequent ADRs
-->

# <NNNN> — <Short title>

- **Status:** <Draft | Accepted (vN) | Superseded by [[decisions/NNNN-slug]]>
- **Date:** <YYYY-MM-DD>
- **Deciders:** <PI name> (PI), <Implementer> (implementer)
- **Context refs:** <[[notes/_positioning]], [[notes/paper-note]], ...>

## vN changes vs v(N-1) <(remove if first version)>

- <Change bullet 1>
- <Change bullet 2>

## Context

<1–3 paragraphs: what problem are we solving, what prior art anchors the decision, what
differentiators matter for our prototype. Reference [[notes/_positioning]] for the gap and claim.>

## Decision drivers

- <Driver 1 — e.g. Falsifiability>
- <Driver 2 — e.g. Generality / reusability>
- <Driver 3 — e.g. Honest positioning vs prior art>
- <Driver 4 — e.g. Roadmap compatibility>

## <Optional reframing section if the mental model shifted significantly>

<Explain the new framing and why it is superior. Keep to 1–2 paragraphs.>

## Target indicator (if applicable)

<Indicator name, source table, granularity, years, row count.>

## Data sources

| Role | Table | Notes |
|---|---|---|
| <role> | `<catalog.schema.table>` | <granularity, years, notes> |

**Materialization**: <snapshot policy — local parquet, pin date, no re-ingestion mid-experiment.>

**Missingness expectations**: <which tables / columns have partial coverage; how pipeline handles it.>

## Falsifiable claim

**H1 — <accuracy or primary claim>.**
<Exact quantitative threshold: model X must beat model Y by ≥ N% on metric M.>

**H2 — <constraint / coherence claim>.**
<Exact threshold, condition, acceptance criterion.>

**H3 — <architectural or qualitative claim>.**
<What code artefact confirms this; how it is verified.>

**If H1 fails AND H3 holds:** <fallback decision>. **If H3 fails:** <restart trigger>.

**Tonight non-claims:**
- <Non-claim 1>
- <Non-claim 2>

## Evaluation protocol

### Splits

1. **<Split name>** — <description, size, stratification, what signal is hidden>.
2. **<Split name>** — <description, size, stratification, what signal is hidden>.
3. ~~<Split name>~~ — **dropped** (<reason>). <Deferred to roadmap if applicable.>

<N> seeds per (model, split). CIs reported.

### Ablation runs

- **<A1 — name>**: <description, acceptance criterion>.

### Models compared

| Tag | Model | Hard constraint | Tier | Tonight? |
|---|---|---|---|---|
| `<tag>` | <Model name> | <yes/no/post-hoc> | <classical/NN/NN-graph> | <✓/next session> |

### Metrics

1. **<Primary metric>** (<unit>, primary).
2. **<Secondary metric>** (<unit>).
3. **Coherence error**: `<formula>`. Reported on <conditions>.
4. <Additional metric>.

### Reporting

`results.json`, `leaderboard.csv`, `report.md` per run. Aggregated leaderboard: one row per (<dimensions>).

## Considered alternatives

- **<Alternative 1>**: rejected — <reason>.
- **<Alternative 2>**: rejected — <reason>.
- **<Alternative 3>**: included as ablation / deferred.

## Consequences

- <Consequence 1 — runtime / compute estimates>.
- <Consequence 2 — what this locks in>.
- <Consequence 3 — what downstream ADRs can extend without revisiting>.

## Open questions for reviewer

1. <Question 1>?
2. <Question 2>?
3. <Question 3>?

---

**Halt here.** Approve / amend → <next action>.
