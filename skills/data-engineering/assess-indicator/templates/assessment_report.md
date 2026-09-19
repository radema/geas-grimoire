# Assessment — <KPI_COLUMN>

**Gold table:** `<GOLD_TABLE>`
**Assessed by:** Claude (assess-indicator skill)
**Date:** <YYYY-MM-DD>
**Year range inspected:** <YEAR_RANGE>

## TL;DR
<one paragraph: is the KPI correct, partially correct, or wrong, and what to do about it>

## Lineage
| Layer | Object | File | Line |
|---|---|---|---|
| Gold | `<table>.<col>` | `preparation/.../<model>.sql` | L<n>-L<m> |
| Silver | `silver.fact_<x>` | `ingestion/<src>/silver_<x>.py` | — |
| Bronze | `bronze.fact_<x>` | `ingestion/<src>/bronze_<x>.py` | — |
| Source | `<SDMX dataflow ID>` | `<endpoint URL>` | — |

## Source brief
**Publisher & dataset:** <e.g. "ISTAT — Censimento permanente: Resident population 15+ by current activity status">
**Endpoint:** <SDMX REST / CSV / API> — `<URL pattern>`
**Dimensions** (with semantic hint):
- `<dim_1>` — <what it represents>
- `<dim_2>` — <what it represents>
- …

**Codelist values for KPI-relevant dimensions** (live-verified via MCP):
- `<dim>` ∈ {`<val_1>`, `<val_2>`, …}

**Time coverage:** <first year>–<last year>, <cadence>
**Geographic coverage / granularity:** <NUTS0/1/2/3 / LAU / world / …>
**Publication cadence:** <annual / quarterly / monthly / ad-hoc>
**What this source does NOT publish:** <gaps the implementation works around>
**Known idiosyncrasies:** <provisional values, revisions, total-vs-breakdown row coexistence, etc.>

## Canonical definition
**Source:** <Eurostat code / ISTAT dataflow / ILO indicator / metadata card>
**Formula:** <numerator / denominator>
**Scope:** <age, gender, geography, time>
**Caveats:** <any documented gotchas from the issuing body>

## Formula comparison
| Dimension | Implemented | Canonical | Match? |
|---|---|---|---|
| Numerator filter | … | … | ✅ / ⚠️ / 🔴 |
| Denominator | … | … | ✅ / ⚠️ / 🔴 |
| Age band | … | … | ✅ / ⚠️ / 🔴 |
| Gender | … | … | ✅ / ⚠️ / 🔴 |
| Geography | … | … | ✅ / ⚠️ / 🔴 |
| Multiplier | … | … | ✅ / ⚠️ / 🔴 |

## Data inspection findings
<bullet list of Phase 4 results: dimension cardinalities, codelist checks, row-count sanity, null/NaN distribution>

## Coherence with common knowledge
| Entity | Year | Gold value | Published value | Source URL | Δ abs | Δ rel | Verdict |
|---|---|---|---|---|---|---|---|
| <city A> | <Y> | … | … | <url> | … | … | ✅ / ⚠️ / 🔴 |
| <city B> | <Y> | … | … | <url> | … | … | ✅ / ⚠️ / 🔴 |
| <micro entity> | <Y> | … | … | <url> | … | … | ✅ / ⚠️ / 🔴 |
| <known extreme> | <Y> | … | … | <url> | … | … | ✅ / ⚠️ / 🔴 |
| National aggregate | <Y> | … | … | <url> | … | … | ✅ / ⚠️ / 🔴 |

**Polarity sanity:** <highest and lowest Gold entities match common-knowledge ranking? ✅ / 🔴>

## Edge-case checks
- ✅ / ⚠️ / 🔴 `* 100` rescale — <one line>
- ✅ / ⚠️ / 🔴 Empty-pivot anti-pattern — <one line>
- ✅ / ⚠️ / 🔴 `_delta_timestamp` references in Gold — <one line>
- ✅ / ⚠️ / 🔴 NaN ≠ NULL — <one line>
- ✅ / ⚠️ / 🔴 Codelist alignment — <one line>
- ✅ / ⚠️ / 🔴 Dimension double-counting — <one line>
- ✅ / ⚠️ / 🔴 Granularity substitution documented — <one line>
- ✅ / ⚠️ / 🔴 Orphan ingestion — <one line>

## Visualization readiness (consumer viz app)
- **Unit / scale / decimals vs card:** ✅ / ⚠️ / 🔴 <one line>
- **Polarity vs domain meaning:** ✅ / ⚠️ / 🔴 <one line>
- **Distribution shape (p1/p5/p25/p50/p75/p95/p99):** <values> — verdict <skew/compression/bimodality>
- **Outliers / ceiling-floor artefacts:** <count + verdict>
- **Geographic coverage:** <% of comuni non-null in most recent year>
- **Temporal continuity:** <years with full coverage vs cold-start years>
- **Card-vs-reality gaps:** <e.g. description doesn't mention source substitution>
- **Recommendations for consumer viz app config:** <quantile bins / winsorization / min-N filter / fix polarity / etc.>

## Verdict
- **Correctness:** ✅ correct / ⚠️ proxy / 🔴 wrong
- **Severity:** none / low / medium / high
- **Action required:** <none / cleanup ticket / hotfix / spec change>

## Recommendations
<numbered list, each with concrete file path + line and the change to make>

## References
<links to dataflow registry, methodology PDFs, related JIRA tickets, prior BOLT findings, websearch URLs cited in Coherence section>
