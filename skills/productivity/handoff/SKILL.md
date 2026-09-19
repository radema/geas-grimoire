---
name: handoff
description: Compact the current conversation into a handoff document in ~/.claude/handoffs/ so a fresh agent or a later session can pick the work up without re-deriving it. Use this whenever context is running low or compaction is near, when the user says "hand this off", "write a handoff", "summarise this for a new session", "I'll continue tomorrow", "pass this to another agent", or wraps up a session with work still unfinished — and also when a long investigation is about to change hands, even if the user never says the word "handoff". Handles naming, the document template, the credential scan, and pruning stale handoffs.
argument-hint: "What will the next session be used for?"
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work.

## 1. Create the file

Run the bundled script — it applies the naming convention, stamps repo/branch/date, and prints the path:

```bash
bash ~/.claude/skills/handoff/scripts/handoff.sh new "<short-subject-label>"
```

Then fill in `assets/TEMPLATE.md`'s sections in place. Do not hand-roll the filename.

**Naming convention** (what the script produces):

```
<repository-code>-<YYYYMMDD>-<HHMMSS>-<short-subject-label>.md
```

- `<repository-code>` — slug of the git toplevel's directory name (a worktree resolves to its own
  directory name, so parallel worktrees stay distinct).
- `<YYYYMMDD>-<HHMMSS>` — creation time; sorts chronologically within a repo and never clobbers.
- `<short-subject-label>` — 2–5 words, kebab-case, ≤48 chars. Name the *subject*, not the verb:
  `istat-sdmx-hardening`, not `fixing-the-ingestion`.

**Location**: always `~/.claude/handoffs/`. It persists across sessions, lives outside every repo and
worktree (worktree churn can't lose it, git can't track it), and is one predictable place to look.
Never the OS temp dir (lost at session end) or the working tree (risks being committed).

After writing, print the **absolute path** so the user can hand it to the next agent.

## 2. Content

Fill `assets/TEMPLATE.md`. Sections §1–§4, §7 and §8 are mandatory; drop any other section that would
be empty rather than writing a placeholder. Rules that matter more than completeness:

- **Evidence, not claims.** Every assertion about state gets its proof — command output, log line,
  row count, `file.py:120` anchor. Tag each one `[V]` (verified *this session*) or `[?]` (recalled,
  unverified). "I remember this clearly, no need to re-check" is exactly the reasoning that puts a
  wrong `[V]` in a handoff — if you did not run it or read it, it is `[?]`.
- **Record the dead ends** (§5). Hypotheses disproved and approaches abandoned, with why. This is the
  section that stops the next agent re-burning the tokens you already spent.
- **Fixed decisions are fixed** (§4). If the user ruled on something, say so and say it is not open.
- **Write the restart prompt for a cold reader** (§8). It is the section that actually gets used — a
  paste-ready block that resumes the work. It must stand alone: name the dispatch profile, the base
  branch, the file paths, the scope fence, and what "done" means. If it only parses for someone who
  read the whole doc, it will not survive the paste.
- **Do not duplicate other artifacts.** PRDs, plans, ADRs, issues, commits, diffs — reference by path
  or URL (§12). Restating them is how handoffs go stale.
- **Do not restate durable project rules.** The next agent loads `CLAUDE.md` / `AGENTS.md` /
  `.specify/memory/constitution.md` itself. Copying them in adds length and creates a second,
  diverging copy. Name the file to read instead.
- **Verification block** (§9) is literal, runnable commands, not prose.
- **Relative-to-repo paths inside the doc**, with the repo root stated once in the header.
- **Redact secrets** — API keys, tokens, PATs, passwords, connection strings, PII. Never paste a
  transcript region that contained a credential; describe it instead.
- **Include a "suggested skills" section** (§10) naming skills the next agent should invoke.
- If the user passed arguments, treat them as the description of the next session's focus and tailor
  the whole doc to it (header `Next-session focus`).

Keep it as short as it can be while remaining sufficient. A handoff nobody reads to the end is worse
than a short one.

## 3. Before declaring it done — credential scan

```bash
bash ~/.claude/skills/handoff/scripts/handoff.sh check <path-to-handoff>
```

Exits non-zero on anything credential-shaped (PATs, `dapi*`, AWS keys, JWTs, private keys, URLs with
inline passwords, `API_KEY: …`). If it fires, redact and re-run — do not hand the file over until it
passes. This exists because transcripts routinely contain tokens the summary then copies forward.

A `PreToolUse` hook in `~/.claude/settings.json` runs the same scanner (`handoff.sh hook`) on every
`Write`/`Edit` targeting `~/.claude/handoffs/` and **denies** the call before a credential reaches
disk, so the gate holds even if this step is skipped. The hook fails open — if it errors, the write
proceeds — so the manual `check` above is still the belt to its braces. Manage it via `/hooks`.

## 4. Maintain `~/.claude/handoffs/`

Run this as part of every handoff, after writing the new doc:

```bash
bash ~/.claude/skills/handoff/scripts/handoff.sh prune          # report stale (>30d) handoffs
bash ~/.claude/skills/handoff/scripts/handoff.sh prune --apply   # move them to handoffs/archive/
```

- Report first, then ask the user before `--apply`. Archival moves files; it is theirs to approve.
- Age is read from the `<YYYYMMDD>` in the filename, not mtime — appending an addendum to a handoff
  must not make it look fresh. Files without a conformant timestamp are reported as off-convention
  and never aged; rename them instead.
- **One live handoff per repo+subject.** If the new doc continues the same subject as an existing one
  for the same repo, name that file in the new doc's `Supersedes:` header and offer to archive the
  old one. Two live handoffs on one subject is the main way a next agent gets a stale picture.
- Only archive — never delete. `archive/` is cheap and keeps the supersession chain readable as an
  audit trail; a wrongly-deleted handoff is not recoverable.
- Non-`.md` strays in the directory (scratch scripts, dumps) are not handoffs: mention them to the
  user and leave them alone.
