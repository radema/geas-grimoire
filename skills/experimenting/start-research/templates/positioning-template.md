<!--
  Purpose   : Documents the research positioning — gap analysis, honest overlap assessment,
              falsifiable claim, and design-space sketch — before the first ADR is written.
  When      : Write after all seed notes are complete, before ADR 0001. Update if PI redirects
              the claim. Do not amend after ADR 0001 is accepted; fork a new version instead.
  Where     : research/notes/_positioning.md  (leading underscore = meta-document, not a paper note)
  Links to  : [[notes/<paper-note-1>]], [[notes/<paper-note-2>]], [[decisions/0001-...]]
  Linked from: [[decisions/0001-...]], [[STATE.md]]
-->

---
title: Positioning — <Project name> vs Prior Art
date: <YYYY-MM-DD>
status: <draft (pre-ADR-0001) | final>
tags: [positioning, gap-analysis, <tag3>, <tag4>]
---

# Positioning

## Prior art anchors

- **[[notes/<primary-anchor-note>]]** — <Authors, venue, year>. <2-sentence description: what the
  paper does, what constraint mechanism it uses, what scale it validates on.>
- **[[notes/<secondary-anchor-note>]]** — <Authors, venue, year>. <2-sentence description:
  relevance to our work, key difference (e.g. no hierarchical constraints).>
- **<Method cited by reference, not ingested 1>** — <Authors (year)>. *(cited by reference, not ingested)*
  <1-sentence description; why relevant to our design space.>
- **<Method cited by reference, not ingested 2>** — <Authors (year)>. *(cited by reference)*
  <1-sentence description.>

## The gap

<Primary anchor> sets the state-of-the-art for **<core problem>**. What it does NOT formally tackle,
in priority order for our prototype:

1. **<Gap 1 — architectural primitive>**: <description of the gap and why it matters for our use case.>
2. **<Gap 2 — downstream task>**: <description. Acknowledged future work in §<N> of anchor paper.>
3. **<Gap 3 — data representation>**: <description. Trade-off noted.>

## The claim (refined for ADR 0001)

> <Exact falsifiable claim in one or two sentences. Format: "A <model type> whose <key architectural
> property> matches or exceeds <baseline> on <metric>, while additionally permitting <downstream
> capability>, enabling <end goal>.">

For tonight: prove the **<first half of the claim>**. The <second half> is roadmap.

## Honest overlap assessment

- **<Core technical element shared with prior art>**: shared with <anchor>. Not novel.
- **<Domain / geography / dataset swap>**: not a research contribution. <Measurement upside if any>.
- **<Specific combination we contribute>**: borrows from <Method A> + <Method B>. Novelty is the
  **specific combination** — <description>. To our knowledge not published; needs final-night search
  to confirm before any external claim.
- **<Most genuinely open angle>**: the most genuinely open angle. Roadmap, not tonight.

## What we will and won't claim tonight

| Claim | Tonight | Roadmap |
|---|---|---|
| <Claim 1> | <✓/✗> | <✓/—> |
| <Claim 2> | <✓/✗> | <✓/—> |
| <Claim 3> | <✓/✗> | <✓/—> |
| <Claim 4> | <✓/✗> | <✓/—> |
| <Claim 5> | <✓/✗> | <✓/—> |

## <Key design dimension> — design space

Decision deferred to **ADR 0002** (after baseline runs). Options on the table:

1. **<Option 1 — simplest>** — <brief description>. <Coherence guarantee or lack thereof.> Used as ablation.
2. **<Option 2 — prior-art approach>** — <description>. Two-stage, coherence guaranteed at output.
3. **<Option 3 — our proposed approach>** — <description>. Coherence at every forward pass.
   Compatible with autodiff.
4. **<Option 4 — reparameterization>** — <description>. Exact coherence by construction. Restriction noted.

ADR 0002 will compare options 2–4 on the baseline data.

## Open questions for ADR 0001

- <Question 1: data realism / scope>?
- <Question 2: evaluation — which metrics, which levels>?
- <Question 3: holdout strategy>?
- <Question 4: temporal holdout — keep or drop given axis thinness>?
