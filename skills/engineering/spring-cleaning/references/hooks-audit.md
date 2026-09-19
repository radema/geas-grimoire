# Hooks audit

Audit every configured hook. **Do not change or delete anything** — audit only; changes happen
in the execute phase after approval, per SKILL.md.

Why this matters: hooks are the config the user can't see running. They fire silently, cost a
subprocess (and sometimes a denial round-trip) on every match, and outlive the reason they were
added. A forgotten hook is a standing tax.

## Sources — read all of them

- `~/.claude/settings.json` and `~/.claude/settings.local.json` (user scope)
- the repo's `.claude/settings.json` and `.claude/settings.local.json` (repo scope)
- **the hook scripts themselves** (e.g. in `~/.claude/hooks/`): read each script a hook invokes
  and describe what the code actually does — not what its filename suggests. Inline `command`
  hooks: read the inline command.

## Procedure

### 1. List them all

For every hook entry: the event (SessionStart, PreToolUse, PostToolUse, Notification, Stop, …),
the matcher, when it fires in practice, and what it does — **in plain English**, one entry each.
"Blocks `find`/`cat` with file operands and tells you to use Read/Glob instead" — not "enforces
builtin tool usage policy".

### 2. Which ones fire on every message

Identify the hooks that run on (nearly) every turn or every tool call — SessionStart,
UserPromptSubmit, a PreToolUse matcher on `Bash` or `*`, PostToolUse on `Edit|Write`. These are
the expensive ones: each fires a subprocess per match. Estimate frequency in plain terms
("every Bash call", "once per session", "every Python file edit").

### 3. Any trigger too common

Flag matchers broad enough to fire when the user didn't mean them: `*` matchers, single common
words in prompt-matching hooks, `Bash` matchers whose script only cares about one subcommand but
runs on all of them. Say what unintended case would trip each.

### 4. Any two that could fire at once

Find event+matcher overlaps (e.g. two PreToolUse:Bash hooks). For each pair, say what actually
happens: both run (in listed order); a deny from either blocks; combined latency doubles; and
whether their effects can contradict (one rewrites what the other then checks).

### 5. Any pointing at a file or folder that no longer exists

Stat every path a hook references — the script itself, and every path *inside* the script or
inline command (state files, log files, skill dirs, binaries invoked). A hook whose script is
missing fails on every fire; a hook reading a nonexistent state file may be silently always-on or
always-off — say which. Also flag fragile couplings (a hook calling into another component's
directory, e.g. a skill's `scripts/`): not broken today, but breaks when that component is cleaned.

### 6. Which ones the user has probably forgotten

Heuristic, stated as such: script mtime old, AND not mentioned in any CLAUDE.md, AND no recent
transcript evidence of it firing (use `scripts/usage_evidence.sh` with the script name — hooks
leave traces mainly as denial/output messages in transcripts, so absence is weak evidence; label
confidence accordingly).

## Output format

1. Plain-English inventory (step 1), then the findings from steps 2–6, each section present even
   if empty ("none found") or **NOT RUN** with reason.
2. **The table** — one row per hook:

   | Hook | Fires on | Verdict (keep / fix / remove) | One-line reasoning |
   |---|---|---|---|

3. Counts: N hooks, N every-message, N broken paths, N overlapping pairs, N probably-forgotten.

Then HALT — do not touch anything until the user says so.
