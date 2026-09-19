---
bolt: BOLT-XXX
shortname: <shortname>
status: draft
jira: ~
date: YYYY-MM-DD
---
# Spec: <Title>

## Background
<Root cause summary and affected pipelines>

## Hypothesis
<Working theory before investigation>

## Investigation Notes
<Findings from codebase exploration — populated during Phase 1>

## Affected Pipelines
| Pipeline | Type | Symptom |
|----------|------|---------|
| `path/to/file.py` | Bronze/Silver/Gold | <Observed error or data quality issue> |

## Functional Requirements

### FR-001 — <Title>
<Fix to apply. Implementation-agnostic.>

## Edge Cases & Error Scenarios
- <Boundary condition>: expected behaviour.

## Success Criteria

### SC-001: <Measurable criterion>
<e.g., "All affected pipelines produce correct municipality joins for 2023 vintage data.">
