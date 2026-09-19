# JIRA Ticket Draft

**Epic:** <user confirms — e.g. ABC-123 data-quality epic, ABC-456 tech-debt epic>
**Type:** Bug / Task
**Title:** <one-line, mentions KPI column + bug class>
**Priority:** <Low / Medium / High>

## Summary
<2-3 sentences: what's wrong, blast radius, downstream consumer impact>

## Current behavior
<implemented formula + filters + scale, file:line reference>

## Expected behavior
<canonical formula + source citation>

## Reproduction
```sql
-- minimal query that demonstrates the deviation
```

## Proposed fix
<concrete diff sketch — file path + the SQL/Python change>

## Acceptance criteria
- [ ] <verifiable check 1>
- [ ] <verifiable check 2>
- [ ] dbt build passes with contract enforcement
- [ ] downstream delivery view re-validates

## Related
- Assessment report: `<path to assessment_<N>.md>`
- Source methodology: `<URL>`
- Prior BOLT findings: `<if any>`
