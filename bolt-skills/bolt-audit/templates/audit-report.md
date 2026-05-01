---
id: <feature-name>
status: in-review
date: YYYY-MM-DD
---
# Audit Report: <feature-name>

## 1. Summary
<2–4 sentences: what was delivered, scope, and outcome.>

## 2. Requirement Coverage
| Requirement | Description | Evidence |
|-------------|-------------|----------|
| FR-001 | <Description> | <File:line or test name> |
| SC-001 | <Description> | <Test output or manual check> |

## 3. Deterministic Evidence (Verify)
### Linting & Typing
```bash
<ruff / mypy output>
```

### Tests
```bash
<pytest output>
```

## 4. Semantic Drift Analysis (Audit)
| Constraint / Interface | Status | Notes / Drift Identified |
|------------------------|--------|--------------------------|
| <Constraint from spec.md> | Pass/Fail | <Details> |

## 5. Residual Risks & Technical Debt
| Risk | Severity | Mitigation |
|------|----------|------------|
| <Risk> | Low/Medium/High | <Mitigation> |
