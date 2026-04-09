---
bolt: BOLT-XXX
shortname: <shortname>
status: in-review
date: YYYY-MM-DD
---
# Merge Request Package — BOLT-XXX: <Title>

## Summary
<2–4 sentences: what was delivered, scope, and outcome.>

## Requirement Coverage
| Requirement | Description | Evidence |
|-------------|-------------|----------|
| FR-001 | <Description> | <File:line or test name> |
| SC-001 | <Description> | <Test output or manual check> |

## Evidence

### Linting
```bash
<ruff / mypy output>
```

### Tests
```bash
<pytest output>
```

### Code Inspection
<Key logic verified manually — describe what was checked>

## Deviations
| ID | Summary | Impact |
|----|---------|--------|
| ID-001 | <What deviated from architecture.md> | None / <FR affected> |

## Breaking Changes
<None. / Describe schema or interface changes.>

## Residual Risks
| Risk | Severity | Mitigation |
|------|----------|------------|
| <Risk> | Low/Medium/High | <Mitigation> |
