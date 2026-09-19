---
name: self-harness
description: >-
  Mine past Claude Code sessions for recurring failure patterns, then propose and validate
  targeted fixes to the harness — CLAUDE.md, skills, agents, hooks, settings.json. Use for
  "improve my harness", "run a harness review", "mine my sessions", "what keeps going wrong",
  "why does Claude keep doing X", "audit my CLAUDE.md against what actually happens", or when a
  repeated correction needs a systemic fix rather than another reminder.
---

# Self-Harness

Adapt the three-step loop from *Self-Harness* (arXiv 2606.09498) to a single developer's Claude Code
setup. The paper improves an agent's **harness** — "the non-parametric scaffolding that governs how a
fixed language model is deployed": prompts, tools, memory, runtime policy — without touching model
weights. Here the harness is everything you can edit: `CLAUDE.md` (user + project), skills under
`~/.claude/skills/`, agents under `~/.claude/agents/`, hooks and permissions in `settings.json`.

The loop has three steps, and they run in order:

1. **Weakness mining** — cluster real failures from past sessions into recurring signatures.
2. **Harness proposal** — generate a few minimal, diverse edits, each targeting one signature.
3. **Proposal validation** — gate each edit before it touches anything live.

## The one idea that shapes everything: mining is retrospective, validation cannot be

You can read past transcripts and see exactly where things went wrong — that evidence is sitting on
disk. But you **cannot** re-run history with a changed harness: the intent, the codebase state, and the
conversation are gone. So the two halves of the loop draw on different data:

- **Mining** uses past sessions and existing `feedback_*.md` memories. Telemetry-style signals
  (corrections, reverts, permission denials, repeated tool failures) are excellent here.
- **Validation** needs something you can re-run or measure *forward*. Those same telemetry signals are
  useless as a gate — a proposal that "looks like it would have helped" on a past failure is exactly the
  overfitting the paper warns against.

Hold this distinction. Most ways this skill can go wrong come from blurring it.

## Two hard constraints (never relax these)

- **Never auto-apply an edit.** The output is always a diff or a draft PR that a human merges. This is
  doubly true for user-scope edits, whose blast radius is *every project on the machine*. In scheduled
  mode the output is a draft only — see "Scheduled mode".
- **Minimum support before a pattern is proposal-eligible.** A signature must recur across **≥3
  sessions or span ≥2 distinct days** before it earns a proposal. A one-off is noise, not a weakness.
  This threshold is the local analog of the paper's held-out gate: it stops you from hard-coding the
  setup around a single bad session.

## Step 0 — Recent-run guard (check before mining)

Before mining anything, check whether a self-harness run over the **same scope** already happened in
the last ~24h — re-mining the same window wastes the whole parallel-agent budget (on 2026-07-02
three near-duplicate mining runs fired within one minute). Evidence is cheap to find, in order:

- A prior findings/report artifact with mtime < 24h — the transient workspace findings file, a
  `harness-review-*.html`, or the durable report the last run saved.
- Recent session transcripts (`~/.claude/projects/*/*.jsonl`, ranked by mtime) that themselves
  invoked this skill over the same `--time-range`/scope. Filenames + mtimes suffice; no deep parse.

If a recent same-scope run is found, **do not silently re-mine.** Report when it ran and where its
findings live, then offer to either (a) **reuse/resume** those findings (default), or (b) re-mine —
appropriate only if the scope changed or the user passes `--force`. Skip this guard entirely when
the user explicitly asks for a fresh mine or passes `--force`.

In **scheduled mode** there is no one to prompt: note the overlap in the report and mine only the
window that postdates the last run (which the held-out split already requires) instead of blocking.

## Step 1 — Weakness mining

Goal: turn a pile of sessions into a short list of *recurring failure signatures*, each with its
support count and representative evidence.

Inputs:
- Session transcripts: `~/.claude/projects/<project-slug>/*.jsonl` (one project dir per working
  directory; filter by file mtime to honor the user's `--time-range`).
- Distilled feedback already on hand: `~/.claude/projects/<project-slug>/memory/feedback_*.md`.
  These are pre-labeled weaknesses — consume them, don't re-derive them.

Read `references/mining.md` for the failure-signature taxonomy, the exact JSONL fields to scan, and the
clustering procedure. Mining data is **ephemeral**: hold clusters in working context, write at most a
transient findings file in the workspace, and never copy raw transcript text into anything durable
(see "Terms-of-Service note").

## Step 2 — Harness proposal

Goal: for each eligible signature, draft a small number (K ≈ 2–4) of **minimal, diverse** candidate
edits. Minimal: touch only the surface that addresses the mechanism. Diverse: the K candidates should
explore genuinely different mechanisms, not reword each other.

The highest-value move this skill makes over a plain reminder: when a signature is a **rule that is
already documented yet still recurs** (the memory index is full of these — e.g. a CLAUDE.md line that
"keeps getting violated in practice"), prose has already failed. Propose escalating to an *enforced*
mechanism — a hook or a setting that the harness executes deterministically — rather than another
sentence Claude can skip. Read `references/proposal.md` for the prose-vs-enforcement decision and the
proposal record format.

## Step 3 — Proposal validation

This step is **off by default and never runs unless the user explicitly asks for it** — e.g. "validate
the proposals", "run the evalset", or a `--validate` argument. The presence of `evalset/manifest.yml`
does **not** trigger it; a manifest is only consulted once validation is explicitly requested. This keeps
every ordinary run cheap (no worktrees, no subagent fan-out) and puts the decision to spend that budget
in the user's hands. Read `references/validation.md` for the full procedure; the short version:

- **Propose-only (the default for every run).** Mine → propose → present each diff with its signature
  and evidence for a **human gate**. No verifier is invented. You lose the non-regression guarantee but
  keep the mining and diverse-proposal value; this is the paper's loop minus the verifier, which is
  exactly what user scope already is. Say plainly that no mechanical validation was run.
- **Project scope, validation explicitly requested → Path A.** Only then, replay the frozen cases in
  `evalset/manifest.yml` in a git worktree under the candidate harness and score with the real verifiers
  (`pytest`, a check script, `ruff`, `dbt`). Accept only on the paper's non-regression rule: no case
  worse, at least one better. This is the paper-fidelity path. If validation is requested but no manifest
  exists, say so and fall back to propose-only — do not fabricate a verifier.
- **User scope always uses the human gate** — a global edit's outcome isn't mechanically checkable and
  its blast radius is every project, so there is nothing to replay. Present the diff and evidence; the
  human decides. This mode is "suggestion engine with approval", not the paper's autonomous loop.

## Scheduled mode (periodic / Claude Code web review)

A recurring run gives you a held-out split *for free, by time*: run N mines a window and proposes; run
N+1 validates those proposals against sessions that accumulated **since** the proposal — genuinely
held-out because they postdate it. A generalizing edit should lower its target signature's rate in the
next window without spiking others.

Caveat to state in any scheduled report: if the edit was merged it is live in N+1, so there is no clean
control. A single-window drop is noise; only a **persistent multi-window drop** is weak confirmation.
Scheduled runs **propose only** — they open a draft PR and stop. They never merge.

## Terms-of-Service note

This skill reads only the user's own session data and edits config files; it trains nothing, which keeps
it clear of Anthropic's AUP. The one line that matters: **never persist mined session inputs/outputs
into a training or fine-tuning corpus** (that would be "model distillation" under the AUP). Keep mined
data ephemeral and config-only.

## Output

End every run with a single report containing:

1. **Signatures** — each eligible failure cluster, its support count, and one representative excerpt.
2. **Proposals** — per signature, the candidate edit(s) as a diff, scope (user/project), and whether it
   escalates prose → enforcement.
3. **Validation result** — project scope: evalset pass deltas and accept/reject per the non-regression
   rule. User scope: "awaiting human gate". Scheduled: the held-out window comparison.
4. **Next action** — exactly what the human merges, or what the next scheduled window will check.

Never present a passing proposal without the caveat appropriate to its scope. A green check in user or
scheduled mode is weaker evidence than a green check in project mode, and the report must say so.
