---
name: bolt-retrospective
description: Structured post-Bolt retrospective that captures process improvements, proposes constitution amendments, and updates bolt-* skills. Targets the development process — not the project. Distinct from bolt-synthesis.
---

# Bolt-Retrospective Workflow: Process Improvement

This workflow improves the **development process** — not the project artifacts. Run it after one or more Bolts are merged, or at a regular cadence (every 3–5 Bolts). It is the closed feedback loop that prevents recurring friction from becoming permanent overhead.

> **Distinction from bolt-synthesis**: `bolt-synthesis` asks *"what did we learn about the project?"* and updates `ARCHITECTURE.md` / `CONVENTIONS.md`. `bolt-retrospective` asks *"what did we learn about the process?"* and proposes changes to `constitution.md` or the bolt-* skills themselves.

## When to Run
- After a Bolt that surfaced significant or recurring process friction.
- After every 3–5 Bolts as a regular cadence check.
- Before starting a new major initiative or phase.

## 1. Evidence Collection
For each Bolt under review, gather the following artifacts:
1. `plan.md` — compare planned task count and complexity against what actually occurred.
2. `implementation_decisions.md` — catalogue all runtime deviations and their root causes.
3. `audit-report.md` — note residual risks, known limitations, and rework items that originated in the process.
4. `research.md` (if present) — was research sufficient? Were architecture decisions later revised?
5. Chat / session context — identify recurring blockers, repeated clarifications, or steps that were skipped.

## 2. Pattern Analysis
Synthesize the evidence into process signals:
- **Plan accuracy**: Were tasks under- or over-scoped? Were dependencies missed during `bolt-intent`?
- **Recurring blockers**: Did the same type of ambiguity, missing research, or absent convention appear in multiple Bolts?
- **Skipped steps**: Which workflow steps were skipped, and was the reason documented or silent?
- **Constitution compliance**: Were any articles violated? Were violations justified and logged?
- **Skill effectiveness**: Did any bolt-* skill prompt cause confusion, ambiguity, or incorrect agent behavior?

## 3. Produce `retrospective.md`
Generate `docs/design/retrospective-YYYY-MM-DD.md` (for batch reviews) or `docs/design/<feature-name>/retrospective.md` (for single-Bolt reviews):

```
---
scope: [feature-name, other-feature, ...]   # Features reviewed
date: YYYY-MM-DD
status: draft
---

# Retrospective

## What Worked
- <Process steps that accelerated delivery or prevented rework, with evidence>

## What Didn't
- <Friction point> — **Root cause**: <cause>

## Proposed Changes

### Constitution Amendments
| Article | Proposed Change | Rationale |
|---------|----------------|-----------|

### Bolt Skill Improvements
| Skill | Section | Proposed Change | Rationale |
|-------|---------|----------------|-----------|

### New Conventions
- <Convention to add to CONVENTIONS.md via bolt-synthesis>
```

## 4. Action Gate
Present `retrospective.md` to the user. For each proposed change:

- **Constitution amendments**: If approved, invoke `bolt-constitution` amendment protocol. The amendment is logged in `constitution.md` and the version is incremented.
- **Bolt skill improvements**: If approved, update the relevant skill file(s) directly.
- **New conventions**: If approved, these are handed to `bolt-synthesis` for incorporation into global project documentation.

Update frontmatter to `status: approved` once all actions are resolved.

---
**Next Steps**: Resolved convention changes feed into `bolt-synthesis`. Approved constitution amendments trigger `bolt-constitution`. Approved skill changes are applied to the relevant `bolt-*/SKILL.md` files.
