# design

User-invoked skill: puts a session into "design mode" -- batched clarifying
questions, a tracked decision map, zero code edits -- until the user types
`BUILD` or `/design off`. Enforced by hooks, not prose.

## Install

```bash
ln -s /root/geas-grimoire/skills/productivity/design ~/.claude/skills/design
```

Then add the three hook entries below to `~/.claude/settings.json` (see
report for the exact JSON; not duplicated here to avoid a second source of
truth going stale).

## Limitation

The design-mode flag is keyed by git repo root (sha1 of `git rev-parse
--show-toplevel`), not by Claude Code session id -- the skill process and
the hook process are different invocations with no shared session id
available to both. This means two concurrent sessions working in the same
repo share one design-mode flag: turning it off in one turns it off in both.
