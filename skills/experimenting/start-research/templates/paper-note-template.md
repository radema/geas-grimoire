<!--
  Purpose   : Structured synthesis note for an ingested research paper.
              Records problem framing, method, datasets, baselines, limitations,
              relevance score, and hooks for the current prototype.
  When      : Write one immediately after converting a PDF to Markdown.
              Cap at 6 total notes per session; prefer the richest prior-art anchor.
  Where     : research/notes/<slug>.md
  Links to  : [[papers_md/<slug>]] (source markdown), [[notes/_positioning]], [[STATE.md]]
  Linked from: [[notes/_positioning]], [[decisions/0001-...]], [[STATE.md]] entry
-->

---
source: "[[papers_md/<slug>]]"
title: "<Full paper title>"
authors: <Author 1>, <Author 2>, <et al.>
year: <YYYY>
venue: <Journal / Conference / Working Paper series and number>
tags: [<tag1>, <tag2>, <tag3>]
relevance: <1–5>
---

# <Full paper title>

## Problem framed

<2–4 sentences: what gap does this paper address, what is ill-posed or insufficient about
prior solutions, what inductive biases or framing does the paper introduce.>

<Bullet list of core challenges identified by the paper:>

1. **<Challenge 1>**: <one-line description>.
2. **<Challenge 2>**: <one-line description>.
3. **<Challenge 3>**: <one-line description>.

## Method

**Core approach**: <One sentence summary of the method.>

**Graph construction**:
- **Nodes**: <node types, what they represent>.
- **Edges**: <edge types and semantics>.
- **Edge semantics**: <how relations are handled>.

**GNN architecture**:
- <Architecture name>, <L> message-passing layers, hidden dim <D>.
- <Per-relation message functions / aggregation operator>.
- Output activation: <activation function> to produce <output quantity>.

**Aggregation and loss function**:
- <How fine-scale quantities aggregate to coarse constraints>.
- Primary loss: <formula and description>.
- Optional regularizers: <list>.
- Total loss: <composition>.

**Training**: <Optimizer, schedule, epochs, notable techniques>.

**Post-processing**: <Any post-hoc reconciliation step and its coherence guarantee>.

## Key assumptions

1. <Assumption 1>.
2. <Assumption 2>.
3. <Assumption 3>.
4. <Assumption 4>.

## Datasets used

**Training targets**:
- <Dataset name>: <source, granularity, years>.

**Fine-scale covariates**:
- <Covariate name>: <source, resolution, description>.

**Administrative boundaries**: <source>.

**External validation**: <dataset, studies, use>.

**Scope**: <geographic + temporal coverage>.

## Baselines & metrics reported

**Out-of-sample validation** (<holdout description>):

| Metric | Value |
|--------|-------|
| <Metric 1> | <value> |
| <Metric 2> | <value> |

Test set: <N observations, period, sample-size notes>.

**Comparison baseline**: <Baseline name> — <brief description>:
- <Baseline metric>: <value>.
- <GNN metric>: <value>.
- <Key finding>.

## Limitations

1. <Limitation 1>.
2. <Limitation 2>.
3. <Limitation 3>.
4. <Limitation 4>.

## Relevance to our goal (score: <N>/5)

<2–3 sentences: why this paper is relevant, what it confirms, what it leaves open for our work.>

## Direct overlap with our prototype

**What this paper does (and our work should closely follow)**:
1. <Overlap 1>.
2. <Overlap 2>.

**What this paper does NOT explicitly address (differentiators for our work)**:
- <Gap 1>.
- <Gap 2>.
- <Gap 3>.

**Honest assessment**: <1–2 sentences on degree of overlap and our differentiation angle.>

## Hooks for our work

1. **<Hook 1 label>**: <concrete action for our prototype>.
2. **<Hook 2 label>**: <concrete action>.
3. **<Hook 3 label>**: <concrete action>.
4. **<Hook 4 label>**: <concrete action>.

## Open questions for positioning

- **<Question category>**: <specific question for ADR or _positioning.md>?
- **<Question category>**: <specific question>?
- **<Question category>**: <specific question>?

---

**Summary**: <1–2 sentence synthesis: what this paper is for our research and the single most
important thing to borrow from it.>
