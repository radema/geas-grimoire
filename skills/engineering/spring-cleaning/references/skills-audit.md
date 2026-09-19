# Skills audit

Audit a skills folder for overlap and dead weight. **This layer never deletes anything** —
audit only; deletion happens in the execute phase after approval, per SKILL.md.

Why this matters: every registered skill's name+description sits in context on every session, and
each on-disk skill is maintenance surface. Skills accumulate faster than they get retired; the
audit's job is to make the retirement decision cheap and evidence-based.

## Procedure

### 1. List every skill

For each directory in the skills folder: name + one line on what it does (from its SKILL.md
frontmatter `description`; if there's no SKILL.md, say so — that's a finding in itself).

Also note **registered vs on-disk-only**: compare the directory list against the skills actually
surfaced in the current session's available-skills listing. A skill on disk but not registered is
loaded by nothing — headline that delta.

### 2. Group them by the job they do, not by their name

Same job = same group, whatever the names say (e.g. "interrogate my plan", "write docs",
"OE branding", "spec workflow"). A skill can only be in one group; singletons form their own
group. Grouping by job is what exposes duplicates that naming hides — read descriptions, not
just names.

### 3. For each group of two or more

Say **which one to keep** and, for each of the others, **exactly what it has that the keeper
misses** (a section, a script, a stricter rule — concrete, not "some nuance"). "Nothing the
keeper misses" is a valid and useful answer: it means a free deletion.

### 4. Flag every skill never actually used

Run `scripts/usage_evidence.sh <name>...` with all skill names. It searches session transcripts
(`~/.claude/projects/*/*.jsonl`) and `~/.claude/history.jsonl` for *invocation-shaped* evidence
(Skill tool calls, typed slash commands — not bare mentions, which match every transcript because
the skill listing is embedded in each session) and prints hits + most recent evidence date.

- **1 hit dated today is self-contamination** — the current session's transcript contains the
  names you're auditing. Treat it as 0 independent hits.
- 0 hits → flag as **no evidence of use** — absence of evidence, not proof of death (transcripts
  rotate; the skill may be new). State the caveat once, then trust the flag.
- Hits only from long ago → note the last-seen date.
- If the evidence sources don't exist on this machine, mark this check **NOT RUN**.

### 5. Flag every skill that depends on a file that no longer exists

Grep each skill's SKILL.md (and its scripts) for paths it depends on: absolute paths, `~/` paths,
`scripts/...`, `references/...`, `assets/...`. Stat each. Any missing target = flag **broken
dependency**, with the exact missing path. These skills silently fail when invoked — high-value
finds.

## Output format

1. **Inventory table**: name | one-line job | registered? | used? (evidence) | broken deps?
2. **Groups**: each group with keep/lose verdicts per step 3.
3. **The merged skill**: take the *biggest* group (most members) and write ONE merged SKILL.md
   for it, in full — real frontmatter, real body, ready to save — combining the keeper with the
   concrete things the others had. Then an explicit **"what you lose by merging"** list: anything
   from the retired members that deliberately didn't make it in (a distinct trigger phrase, a mode,
   a stylistic stance), so the trade is visible before it's made.
4. Counts: N skills, N registered, N no-evidence-of-use, N broken, N groups ≥2.

Then HALT per SKILL.md.
