# CLAUDE.md audit

Audit one CLAUDE.md against Anthropic's *current* guidance and say what to delete. The point:
old rules were written for older, weaker models; each obsolete rule costs context tokens on every
single session and can actively fight the current model's defaults. But deletion needs evidence,
so the burden of proof sits on DELETE, never on KEEP.

## Procedure

### 1. Fetch the live rules first

Before reading a single line of the target file, fetch Anthropic's current guidance with
WebFetch/WebSearch, **for the exact model powering this session** (the model ID is in the system
prompt). Useful sources, in order:

- Claude Code memory/CLAUDE.md best practices: https://code.claude.com/docs/en/memory
  and https://www.anthropic.com/engineering/claude-code-best-practices
- Prompting guidance for the current model family (search: "<model name> prompting best practices
  site:anthropic.com" / platform docs release notes)

If fetching fails or returns nothing usable: say so plainly, and mark every verdict that depends
on a source as **NOT RUN**. Do not substitute guidance from memory — memory is exactly what goes
stale.

### 2. Go line by line

Work through the file instruction by instruction (a multi-line rule = one row; headings and blank
lines are skipped, not counted). Every instruction gets exactly one verdict:

- **DELETE** — the current model does this by default, or current guidance says the opposite.
- **KEEP** — still earning its place, or no source evidence against it (see rule 3).
- **REWRITE** — the intent is valid but the wording is stale/overbroad; propose the shorter form.

One-line reason for each.

### 3. Quote your source

A DELETE or REWRITE verdict requires a **verbatim quote from the fetched Anthropic guidance** in
its row. No quote → the verdict is KEEP, regardless of how confident the reasoning feels. This is
the anti-hallucination gate: "I think the model does this now" is not a source.

### 4. Flag every verify-twice rule

Independently of verdict, flag any rule that forces re-verifying what the model already
self-corrects: re-read the file after editing, double-check your own diff, run the check twice,
confirm before every step. These make the user pay twice — once in tokens, once in latency.
Mark the row with ⚠ verify-twice. (Rules requiring verification of *other agents'* claims or of
external state are not verify-twice — those catch things self-correction can't.)

### 5. Never touch a truth rule

Any rule of the shape "only claim what you verified", "report failures honestly", "don't say done
unless it ran" is **KEEP, unconditionally** — even if a fetched source argued against it, even if
the user says "apply everything" later. Truth rules are the last line of defense; they are cheap
and their failure mode is catastrophic. Mark them 🔒 truth-rule.

### 6. Tell the user what is missing

Compare the file against the fetched guidance and list rules the guidance recommends that the
file lacks (e.g. build/test commands, code style pointers, repo etiquette). Suggestions only —
adding is a separate decision from deleting.

## Output format

ALWAYS end with:

1. **The table** — one row per instruction:

   | # | Instruction (excerpt) | Verdict | Reason | Source quote |
   |---|---|---|---|---|

   Flags (⚠ verify-twice, 🔒 truth-rule) go in the Verdict cell. Rows whose check couldn't run
   say **NOT RUN** in the Verdict cell with the reason.

2. **The honest count**: `N instructions audited: X DELETE, Y KEEP, Z REWRITE, W NOT RUN` —
   the numbers must add up to the row count.

3. **Missing rules** list (from step 6), or "none found".

Then HALT per SKILL.md — no edits until the user says which verdicts to apply.
