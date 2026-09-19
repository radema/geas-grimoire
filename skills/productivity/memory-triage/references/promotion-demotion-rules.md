# Memory promotion / demotion rules

The memory system is tiered by audience. Each surface has one owner-scope, one write
path, one audience. Anything appearing in two surfaces is either a pointer (allowed) or
a promotion in progress (must resolve within one cycle).

## Tiers

| Scope | Surface | Memory class | Write path |
|---|---|---|---|
| User | `~/.claude/CLAUDE.md` | Procedural contract (≤120 lines) | Manual/debrief |
| User | `~/.claude/projects/*/memory/` | Personal semantic facts (`user_*`) + corrections (`feedback_*`); `project_*` = staging only | Auto-memory |
| Repo | `<repo>/CLAUDE.md` | Procedural contract + pointers, never state | PR |
| Repo | `.specify/memory/constitution.md` | Normative governance, versioned | Constitution amendment |
| Repo | `docs/memory/` vault (INDEX routing map + one `entries/<ID>.md` file per entry + ARCHITECTURE narrative + BUGS registry + WORKLOG) | Team semantic + condensed episodic | Capture skills, PR-reviewed |
| Repo | `docs/adr/` | Authoritative decision rationale (MADR); vault entries point, never restate | PR |
| Feature | `.specify/specs/<f>/memory.md` | Episodic working memory; archived at feature close | Plan/capture skills |

## Entry ontology fields (vault entries and single-note files)

`id` (prefix = kind: D decision · A constraint · B bug-pattern · V deviation · W worklog ·
F feedback · R reference) · `kind` · `scope` (user | repo:<name> | feature:<slug>) ·
`status` (active | superseded | stale | archived) · `valid_from` · `review_by`
(TTL defaults: decisions/constraints +180d, bug-patterns/worklog +90d, feedback none) ·
`provenance` · `supersedes` · `links` (`[[ID]]`, typed by target prefix) · `tags`.

## Promotion rules

| ID | Edge | Test | Gate |
|---|---|---|---|
| P-1 | personal `project_*` → repo vault | cited in ≥2 distinct sessions, OR names an artifact a teammate touches; hard deadline: any `project_*` older than 30 days must promote or archive | PR review |
| P-2 | feature memory → vault | at feature close, an item survives only if it states a "future mistake prevented" — else archived with the feature | capture-skill approval prompt |
| P-3 | vault entry → constitution | cited in ≥3 merged PRs referencing the entry ID (behaving as law → codify) | constitution amendment (versioned, human) |
| P-4 | anything → CLAUDE.md | behavioral + violated ≥2× despite existing memory + not expressible as a hook; 120-line ceiling: one line in, one line out | human edit |

## Demotion rules

| ID | Edge | Test | Gate |
|---|---|---|---|
| D-1 | memory → hook/config | a captured rule violated again after capture is not a memory, it is a pending config fix — write the hook, demote the note to a pointer | human picks hook design |
| D-2 | active → stale | `today > review_by` and not re-confirmed → `status: stale`; stale entries excluded from planning synthesis | auto-flag; human confirms extend-or-archive |
| D-3 | soft conflict → supersession | overlapping non-contradictory entries: newer wins, gets `supersedes:`, elder gets `status: superseded` | mechanical, logged in PR |
| D-4 | hard conflict → HALT | two active entries assert contradictory constraints: block synthesis output, surface both with provenance, stop | human resolves — never auto-merge |
| D-5 | orphan hygiene | auto-memory slug dir whose working directory no longer exists (dead worktree) → merge into parent project's dir or delete | human skim |
