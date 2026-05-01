---
name: bolt-constitution
description: Establish a project governance document (constitution.md) with immutable architectural articles that all Bolts inherit. Run once per project before bolt-roadmap.
---

# Bolt-Constitution Workflow: Project Governance

This workflow establishes the "architectural DNA" of the project — a `constitution.md` file containing immutable principles that every Bolt inherits. It prevents drift across Bolts by making standards explicit, auditable, and amendable only through a formal process.

## When to Run
Run **once per project**, before the first `bolt-roadmap` invocation. Re-invoke only to formally amend an existing article.

## 1. Context Discovery
Use the `brainstorming` skill to surface project-level standards. Cover the following dimensions:
1. **Testing philosophy**: Is TDD mandatory? What coverage targets apply? Are integration tests required to hit real services?
2. **Tech stack constraints**: Languages, frameworks, cloud provider, package managers.
3. **Abstraction rules**: Are framework features used directly? Are wrapper layers forbidden?
4. **Complexity budget**: Maximum number of services/projects? Is speculative engineering prohibited?
5. **Integration testing**: Real databases required? Contract tests written before implementation code?
6. **Security baseline**: Auth patterns, secrets management, dependency scanning requirements.
7. **Data contracts**: Schema registry? Backward compatibility rules? Breaking change policy?
8. **Performance targets**: SLAs, latency budgets, throughput floors.

Continue the discovery loop until there are **no ambiguities** about the project's non-negotiables.

## 2. Draft the Constitution
Generate `docs/design/constitution.md` with the following structure:

```
---
project: <project name>
version: 1.0
status: approved
authors: [<author(s)>]
amended: []
---

# Project Constitution

## Preamble
<One paragraph: project name, purpose, and what this constitution governs.>

## Article I — Test-First Imperative
<Principle statement. e.g.: All implementation code is preceded by failing tests. The Red phase must be confirmed before writing source code. No exceptions.>
**Rationale**: <why>

## Article II — Simplicity Budget
<Principle statement. e.g.: Maximum N services for initial implementation. No future-proofing. Additional components require documented justification.>
**Rationale**: <why>

## Article III — Anti-Abstraction
<Principle statement. e.g.: Use framework features directly. Wrapper layers require explicit justification in the Bolt's architecture.md.>
**Rationale**: <why>

## Article IV — Integration-First Testing
<Principle statement. e.g.: Tests hit real services. Contract tests are written before implementation code. Mocks require documented justification.>
**Rationale**: <why>

## Article V — Library-First
<Principle statement. e.g.: Prefer established libraries over custom implementations. Custom code requires a research.md entry justifying the gap.>
**Rationale**: <why>

## Article VI — Security Baseline
<Project-specific security requirements.>
**Rationale**: <why>

## Article VII — Data Contracts
<Schema standards, backward compatibility rules, breaking change policy.>
**Rationale**: <why>

<Additional project-specific articles as needed.>

## Amendment Process
Amendments require:
1. A proposed change with written rationale.
2. Impact assessment: which existing Bolts are affected.
3. User approval.
4. Version increment and entry in the `amended` frontmatter list.
5. A corresponding note in the active `bolt-retrospective` report.

## Amendments
<!-- Populated over time: [date] vX.Y — Article N — <summary> -->
```

## 3. User Validation
Present the draft constitution to the user. Refine until all articles are agreed upon.
Update frontmatter to `status: approved`.

## 4. Amendment Protocol (Re-invocation)
If `bolt-constitution` is re-invoked on an existing project:
1. Identify the article(s) to amend and document the proposed change and rationale.
2. Run an impact assessment: list all `docs/design/*/` feature directories that may be affected.
3. Update the article, increment the version number, and append to the `amended` list.
4. Notify the user which in-flight Bolts need to be reviewed for compliance.

---
**Next Steps**: Invoke `bolt-roadmap` to decompose the project into Bolts. All subsequent Bolt skills read `constitution.md` to inherit these constraints automatically.
