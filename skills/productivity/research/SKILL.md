---
name: research
description: Investigate a question against high-trust primary sources and capture the findings as a Markdown file in the repo. Use when the user wants a topic researched, docs or API facts gathered, or reading legwork delegated to a background agent.
---

Spin up a **background agent** to do the research, so you keep working while it reads.

Its job:

1. Investigate the question against **primary sources** — official docs, source code, specs, first-party APIs — not a secondary write-up of them. Follow every claim back to the source that owns it.
2. Write the findings to a single Markdown file, citing each claim's source.
3. Save it **inside the repo** — never only `/tmp`, a scratchpad, or the reply — at the path the caller named, and report that path back. If no path was named, ask for one rather than choosing.
4. Match the filenames and the **language** of the folder you are saving into, not of your brief or of the material you read.
5. Do not switch branches. Commit only in a branch or worktree you were given; otherwise say the file is uncommitted so the caller commits it.
