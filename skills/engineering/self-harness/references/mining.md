# Weakness mining

Turn past sessions into a ranked list of recurring failure signatures. Output of this step is a set of
clusters, each with: a signature label, a support count, the sessions/days it spans, and 1–2 verbatim
excerpts as evidence.

## Where the data lives

- **Transcripts**: `~/.claude/projects/<project-slug>/*.jsonl`. Each working directory maps to one
  `<project-slug>` dir (the path with slashes turned to dashes). One `.jsonl` per session; each line is
  a JSON event. Honor the user's `--time-range` by filtering on file mtime first, then on event
  timestamps inside.
- **Distilled feedback**: `~/.claude/projects/<project-slug>/memory/feedback_*.md` and the
  `MEMORY.md` index. These are weaknesses a human already named. Treat each as a pre-clustered signature
  with support ≥1 — and note that a documented feedback memory whose failure *still appears in recent
  transcripts* is the strongest possible signal (the written fix didn't hold).

Scan a representative sample of sessions if the range is large; you do not need every line of every
transcript. You need enough to estimate which signatures recur.

## What a failure signature is

Borrowed from the paper's "verifier-grounded failure signatures": group failures by their *mechanism*,
not their surface text, so that ten instances of the same underlying problem count as one signature with
support 10 — not ten unrelated issues. Two failures share a signature when fixing the same harness
surface would address both.

## Signal taxonomy (what to grep the JSONL for)

Mine these, strongest first. The first three are the high-value ones.

1. **Explicit user correction** — a user turn that countermands what just happened: "no", "stop",
   "don't", "that's wrong", "I said", "why did you", "revert that", "not what I asked". The single
   clearest weakness label. Capture the assistant action immediately prior — that's the mechanism.
2. **Documented-but-violated rule** — an assistant action that contradicts a known `CLAUDE.md` /
   memory rule (e.g. ran a bare `python` when the rule mandates `uv run`; read many files inline when
   the rule mandates an Explore subagent). Cross-reference candidate violations against the project's
   `CLAUDE.md` and `feedback_*.md`. These are prime escalation candidates in Step 2.
3. **Repeated tool failure** — the same tool erroring ≥2 times in a session on the same target
   (failed Edits from stale `old_string`, command-not-found, repeated permission denials). Look at
   `tool_use` / `tool_result` pairs where the result is an error.
4. **Rework loops** — the same file edited 3+ times in quick succession, or a plan/approach abandoned
   mid-session. Signals an instruction gap that sent Claude down a wrong path.
5. **Permission-denied** — a denied tool call followed by a workaround. Recurring denials for the same
   command class often mean a missing allowlist entry (a settings edit) rather than a behavior fix.
6. **Hook rejections** — a hook blocked an action repeatedly. The behavior the hook guards against is
   recurring despite the guard; may need the guard tightened or the upstream instruction fixed.
7. **Premature verification claim** — assistant text matching `verified|all clean|complete|passes`
   where no test/lint/run Bash command executed in that same turn, AND within the next 2 user turns
   the user corrects it ("wrong", "not", "actually", "that's not", "still"). Mechanical part: regex
   the claim phrase and check the turn's tool-call list for an absent Bash/test invocation. LLM-read
   part: confirming the later user turn is actually a correction of that specific claim, not an
   unrelated request — needs reading the text pair, not just error strings.
8. **User redirect** — a user turn starting with or containing "stop", "don't", "I did not ask", "I
   asked for", "you keep", "too complicated", immediately following an assistant action turn.
   Mechanical part: string match on the user turn's opening/body. LLM-read part: confirming the
   assistant turn just before it was actually an action (not a question or a plan) the user is
   pushing back on — the match alone doesn't establish that.
9. **Dismiss request** — a user turn asking to dismiss, stop, or shut down teammates or subagents.
   Evidence the orchestrator left agents idle after their work landed. Mechanical part: keyword match
   ("dismiss", "shut down", "stop the agent/teammate"). LLM-read part: confirming the target was
   actually idle (finished, not mid-task) — reading the surrounding turns, not just the keyword.

Same minimum-support threshold applies to all three: keep only signatures with support ≥3 across
sessions, or spanning ≥2 distinct days.

## Clustering procedure

1. Extract candidate failure events using the taxonomy above.
2. Label each with its mechanism (the harness surface that would fix it), not its wording.
3. Merge events with the same mechanism into one signature; accumulate support count and the set of
   distinct sessions and days.
4. Apply the **minimum-support threshold** from SKILL.md: keep only signatures with support ≥3 across
   sessions, or spanning ≥2 distinct days. Drop the rest as noise (but you may list dropped near-misses
   separately so the human can override).
5. Rank surviving signatures by support × recency. Hand the ranked list to Step 2.

## Ephemerality

Hold clusters in working context. If you must write them down, write a single transient findings file
inside the run workspace and treat it as disposable. Do not copy raw transcript text into memory files,
committed docs, or anything that could become a training/fine-tuning corpus (see the ToS note in
SKILL.md). Excerpts in the final report should be the minimum needed to justify a proposal.
