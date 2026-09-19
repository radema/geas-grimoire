# Harness proposal

For each eligible signature from Step 1, draft K ≈ 2–4 candidate edits. Two properties matter, straight
from the paper's "diverse yet minimal":

- **Minimal** — each edit touches only the surface needed to address the mechanism. Resist bundling
  unrelated cleanups; a narrow edit is easier to validate and easier to revert.
- **Diverse** — the K candidates explore *different* mechanisms, not paraphrases of one. If every
  candidate is "add a stronger sentence to CLAUDE.md", you have one idea, not K.

## Editable harness surfaces, weakest to strongest enforcement

| Surface | Where | Enforcement |
|---|---|---|
| `CLAUDE.md` prose (user/project) | `~/.claude/CLAUDE.md`, `<repo>/CLAUDE.md` | Advisory — Claude may skip it |
| Skill instructions | `~/.claude/skills/<name>/SKILL.md` | Advisory, but scoped + triggered |
| Agent definitions | `~/.claude/agents/<name>.md` | Advisory, routes work |
| Permissions allowlist | `settings.json` | Deterministic (fewer prompts) |
| Hooks | `settings.json` (`PreToolUse`, etc.) | **Deterministic — harness executes it, not Claude** |

## The key decision: prose vs. enforcement

The most valuable proposals this skill makes come from one observation: **if a rule is already
documented and still recurs, adding more prose will not fix it.** The harness executes hooks and
settings; it only *suggests* prose. So:

- Signature is a **documented-but-violated rule** (taxonomy #2) → propose escalation to a **hook or
  setting**, because prose has demonstrably already failed for this exact case. Example: "use `uv run`,
  not bare `python`" keeps getting violated → propose a `PreToolUse` hook that blocks bare `python`/
  `pytest`/`ruff` invocations with a message, instead of a third CLAUDE.md reminder.
- Signature is a **genuine knowledge/approach gap** (Claude didn't know a convention, took a clumsy
  route) → prose or a skill is the right surface; there's nothing to enforce, only to inform.
- Signature is **recurring permission friction** → propose a settings allowlist entry, not a behavior
  change.

When proposing a hook, keep it narrow and reversible, and remember the `update-config` skill is the
right tool to actually wire `settings.json` — reference it rather than hand-editing.

## Proposal record (per candidate)

Mirror the paper's audit record. For each candidate produce:

- **Targets signature**: the signature label + support count it addresses.
- **Surface**: which file/mechanism from the table above.
- **Scope**: user or project (drives which validation path in `references/validation.md`).
- **Edit**: the concrete diff. For prose, the exact lines. For a hook/setting, the config block.
- **Mechanism**: one sentence — *why* this addresses the failure, not just what it changes. (The paper
  and good skill-writing both lean on explaining the why; a candidate you can't justify in one sentence
  is probably not minimal.)
- **Escalation flag**: true if this moves a documented rule from prose → enforcement. Surface these
  first in the report — they're the highest-leverage edits.

Do not apply anything here. Proposals flow to Step 3 for gating, then to a human for merge.
