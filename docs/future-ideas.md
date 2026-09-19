# Future Ideas

Non-committed ideas surfaced during work, kept for later triage — not a roadmap.

## Personal-skills packaging & docs (from mattpocock/skills audit, 2026-08-24)

- **Ship `personal-skills/` as an installable Claude Code plugin** (`.claude-plugin/marketplace.json` + `plugin.json`), mirroring mattpocock/skills — would let this skill set be installed/updated as a unit instead of relying on manual symlinks.
- **`scripts/link-skills.sh` / `list-skills.sh` equivalents** — automate the symlinking currently done by hand and regenerate the README index, cutting drift between the skills on disk and what the README documents.
- **A `CONTEXT.md`-style shared glossary** for this skill set — gives cross-skill terms one canonical definition, the same idea the repo's own `domain-modeling` skill applies to other domains, applied here to itself.
- **Per-skill human-facing doc pages under `docs/`**, fixed template (`## What it does` / `## When to reach for it` / `## Where it fits`) — makes the subset of skills worth surfacing outside agent context legible to humans browsing docs, not just to the model.
- **Explicit `disable-model-invocation`-style labeling audit across all skills** — this repo already sets the field per-skill; documenting it as a first-class categorization axis (as mattpocock/skills does) would make user-invocation-only skills easier to spot at a glance.

## Keeping the third-party skills fresh (2026-09-19)

The skills this repo deliberately does *not* hold — Matt Pocock's set, installed as real
directories under `~/.claude/skills/` — go stale silently. Nothing tracks the gap.

- **Give `spring-cleaning` a "stale upstream" check.** It already audits dead skills, stale hooks
  and outdated `CLAUDE.md` rules. The missing axis is *third-party drift*: for each real (not
  symlinked) skill directory under `~/.claude/skills/`, find its upstream, compare, and report how
  far behind it is. That turns a manual re-diff into part of the existing sweep.
- Measured on 2026-09-19: 9 of 12 Pocock skills at user scope were behind upstream — all predating
  the 2026-08-19 upstream commit, and `prototype` predating 2026-07-17, so it was missing the
  HTML-demo feature entirely. `to-tickets` and `diagnosing-bugs` were current. `triage` is a real
  local fork and must never be refreshed blindly (see its `FORK.md`).
- Another repo on this machine holds, in its `.claude/skills/`, a **second** full copy of the same
  14 Pocock skills. Any refresh story has to cover repo-scope copies too, or they drift apart from
  the user-scope ones.
- Already settled, kept here as the precedent: `to-prd` was a near-verbatim fork of upstream
  `to-spec` with "spec" renamed to "PRD". Upstream `to-spec` now says "(you may know this document
  as a PRD)" itself, so the fork no longer earned its keep and was dropped (`e32cf3e`). A stale
  fork of an upstream skill is the same drift problem seen from the other side.
