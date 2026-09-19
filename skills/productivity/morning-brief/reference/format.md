# Morning brief output format

This format is the same whether the brief is a chat reply or a written
`brief-YYYY-MM-DD.md` file — only the delivery channel differs (see
SKILL.md step 3). Use real markdown: bold, code spans, and the emoji
group markers below. This is a personal daily-reading tool read in a
terminal, not a plain-text log.

## The shape

The brief is **grouped by continuity** — where the reader left off, then
what happened, then what is still in flight — and only after that by
where the work lives:

```
header line          — day, date, and the gap since the last brief
Load: HEAVY|NORMAL|OPEN — one-line day-load verdict, directly under the header
▶ START HERE         — exactly one thread: where you stopped, first move
🔁 SINCE LAST BRIEF  — commitments checked, what landed, which threads moved
🧵 IN PROGRESS       — every other open thread, most recent first
👤 WAITING ON YOU    — people blocked on the user
🎫 JIRA              — board shape and the tickets that need a decision
📦 REPOS             — dirty repos no thread above already explains
🧹 CLEANUP           — one line, counts only (optional)
✅ TODAY             — the three commitments; item 1 is START HERE
footer line
```

Each group is: an **opening sentence** that says what the situation is,
then bullets. Urgency is carried by a trailing ⚠️ on the item, not by a
separate section. Groups appear in the order above; a group with nothing
in it vanishes entirely — no heading with nothing under it.

The order is the point. A colleague's PR, a board triage or a cleanup
sweep is never the first thing the reader meets, whatever its urgency:
those live in 👤, 🎫 and 🧹, below the continuity groups.

## The thread — the unit of continuity

A **thread** is one handoff from `context.md`'s `## Handoffs` section. A
thread *consumes* every other line in `context.md` that names the same
ticket key or the same repo + branch: the Jira line, the `## Repositories`
line, its `## Since last brief` entries. Those facts are described **in
the thread bullet**. Elsewhere they may be counted ("twelve unowned, one
of them the START HERE branch") but never described a second time.

This is what stops the same piece of work appearing as a dirty repo, a
ticket and two handoffs in one brief.

## Naming items — handles, not codes

Every bullet opens with a **bold plain-English handle** naming the thing:
`**Alex's PR stack**`, `**ABC-101 refresh map**`, `**banner card**`. The
handle is what the reader points at ("do the refresh map", "drop the
leftovers"), and it is what makes the item recognisable a day later
without opening Jira.

Rules for handles:

- 2–4 words, plain English, describing the *thing*, not its status.
  `**model kernel branch**`, not `**Unpushed commits**`.
- Derive it from the data in `context.md` — the Jira summary, the branch
  name, the handoff title, the person's name. Never invent a project name
  that isn't there.
- A single ticket that *is* the item uses its key plus its state:
  `**ABC-102 blocked**`. A group of tickets gets a collective handle:
  `**Five In corso quiet 5d**`.
- Keep a handle stable day to day where the underlying thing is the same,
  so the reader recognises a recurring item — the same thread must carry
  the same handle in 🔁, 🧵, ▶ and ✅.

Only the TODAY items are numbered (`1.`, `2.`, `3.`). No `T1`/`T2`/`T3`
codes appear in the brief.

## Every item explains itself

After the handle, an em dash, then the facts *and* why they matter, in
one or two lines. A reader with no memory of yesterday must understand
the item from the line alone.

- Weak: `**ABC-123** is stale.`
- Good: `**ABC-123** — AI Workflows Automation Idea, no update in 5 days.`
- Weak: `**model kernel branch** — 6 commits unpushed.`
- Good: `**model kernel branch** — \`ml-pipelines\` dirty, 6 commits
  unpushed. The ABC-102 materialization fix is invisible to everyone
  until you push. ⚠️`

`context.md` carries the Jira summary text, a repo's last commit subject,
a handoff's opening paragraph and its next step — use them. Never surface
a bare `ABC-123` with no explanation of what it actually is.

Bold ticket keys and PR numbers. Use `code spans` for branch names, repo
paths, and file names.

Wrap bullets at roughly 78 characters and indent continuation lines by
two spaces, so the bullet marker stays the leftmost thing on the item.

## Header

Bold day and date, then the gap: which date the last brief was, and one
factual clause on what moved in between. No meeting count or calendar
info; calendar and mail are not part of this pipeline (the CISO ruled out
a Microsoft 365 connector for this use case, and no in-ToS, no-cost
alternative covers mail). A human checks their own calendar and inbox.

```
**Monday 7 September** — first brief since Friday 4th. Four of your PRs
landed in `data-platform` over the gap; one of Friday's three
commitments is done.
```

The clause is factual, never encouraging or disappointed. The last-brief
date comes from the `(DATE)` in `context.md`'s `## Since last brief` and
`## Commitments from the last brief` headings — never assume it was
yesterday.

### Load verdict

Directly under the header line, one line: `Load: HEAVY`, `Load: NORMAL`, or
`Load: OPEN`. The count is the number of ✅ TODAY items plus 👤 WAITING ON YOU
items plus `## PRs needing you` items (from `context.md`, before any group
cap trims the brief). `HEAVY` at count ≥8, `NORMAL` at 4–7, `OPEN` at ≤3.
No further clause — the verdict is the whole line.

```
**Monday 7 September** — first brief since Friday 4th. Four of your PRs
landed in `data-platform` over the gap; one of Friday's three
commitments is done.
Load: NORMAL
```

## Group caps

Hard caps, per group:

| Group | Cap |
|---|---|
| ▶ START HERE | exactly 1 bullet, at most 4 lines |
| 🔁 SINCE LAST BRIEF | 3 bullets, fixed: commitments / landed / threads moved |
| 🧵 IN PROGRESS | 4 bullets, plus one `Parked:` line for Cold threads |
| 👤 WAITING ON YOU | 2 bullets |
| 🎫 JIRA | 4 bullets; the older-unowned count lives in the heading |
| 📦 REPOS | one bullet per repo with orphan dirt |
| 🧹 CLEANUP | 1 line total |
| ✅ TODAY | exactly 3 numbered items, fewer if fewer qualify |
| whole brief | 72 lines at 78 characters, blanks and headings included |

If more things qualify than a cap allows, show the top ones and add a
plain `and N more` line at the end of that group — never expand the cap,
never silently drop the count. Never promote something to fill space: if
nobody is waiting on the user, 👤 WAITING ON YOU vanishes rather than
carrying filler.

## ⚠️ marks urgency

Score every candidate item on two axes, ITIL-style, and cross them into
one of four named cells. Only one cell earns ⚠️.

| | High urgency | Low urgency |
|---|---|---|
| **High impact** | **Critical** — blocks someone else or something breaks, and it's needed now, not later today. Gets ⚠️. E.g. **ABC-102 blocked** — gates the regional rollout; someone else is stuck until it moves. | **Important** — matters, but nothing forces action in the next day. No ⚠️. E.g. **Five In corso quiet 5d** — the board's health depends on them not going cold, but none has a deadline today. |
| **Low impact** | **Urgent, minor** — time-bound but low stakes if missed. No ⚠️. E.g. **PROJ-48** — missing clusterBars wanted for today's demo, but nothing breaks if it slips a day. | **Low priority** — nobody is blocked, no clock running. No ⚠️. E.g. **Leftovers** — 6 merged branches, safe to ignore for weeks. |

At most 3 per brief. If nothing lands in Critical, no bullet carries a
⚠️ — do not invent urgency to have a marker to show.

## ▶ START HERE

Exactly one thread: the one the reader opens their editor on. No opening
sentence — the bullet is the whole group.

The bullet states three things:

- **where the work stopped** — the handoff's state and last recorded
  position, plus the local evidence from `## Repositories` (dirty branch,
  unpushed commits, uncommitted files);
- **the first concrete move**, taken from the thread's `— next:` clause,
  shortened but never replaced with a vaguer paraphrase;
- **roughly how long** until the reader is back inside the thread.

Choosing it is deterministic, first match wins:

1. The most recently touched non-Cold thread that has a `— next:` clause
   **and** local evidence of unfinished work (its repo is dirty, or its
   branch has unpushed commits).
2. Else the most recently touched non-Cold thread with a `— next:` clause.
3. Else the oldest ⚠️ item in the brief.

A colleague's PR review, a Jira triage or a cleanup sweep is **never**
START HERE while any thread qualifies under 1 or 2. If
`## Commitments from the last brief` shows the previous START HERE was
not done and its thread still qualifies, it stays START HERE — a fresh
recommendation every morning defeats the point.

```
▶ START HERE
· **ABC-101 refresh map** — you stopped Thursday with G1 and the README
  row written but not committed, on `data-platform` branch
  `docs/ABC-101-quarterly-refresh-map` (dirty 2d). First move: one
  `docs(research):` commit, then the branch is PR-ready. About 15 minutes.
```

## 🔁 SINCE LAST BRIEF

What actually happened between the previous brief and this one. Three
bullets, in this fixed order, sourced from `context.md`'s
`## Commitments from the last brief` and `## Since last brief` sections
and from nothing else:

1. **the previous brief's commitments**, each with its outcome;
2. **what landed** — commits and merged PRs, per repo;
3. **which threads moved**, and the plain statement that the others did not.

The heading carries the previous brief's date: `🔁 SINCE LAST BRIEF (Fri 4 Sep)`.

Stage 1 writes a raw status after each commitment (`→ ABC-140 In corso`,
`→ #1428 merged`, `→ untouched since 2026-09-03`). Render it as one of
three words so the reader does not have to interpret a board status:

| Stage 1 status | Rendered |
|---|---|
| PR merged or closed; Jira status in a done category (`Done`, `Chiuso`, `Completato`); handoff moved after the commitment date | `done` |
| repo still dirty on the named branch; PR still open; Jira status unchanged since the commitment | `not done` (repo, handoff) or `still open` (PR, ticket) |
| anything else, including `unverified` | the status verbatim |

Quote each commitment as the previous brief wrote it, shortened. Never
reword it into a new claim, and never soften or sharpen the outcome — the
flat tone rule applies here more than anywhere: no "still hasn't", no
"unfortunately", no "good progress".

Commits by a bot are already excluded by Stage 1. A repo with nothing in
`## Since last brief` is named in the "landed" bullet as having nothing,
or omitted if no repo landed anything.

```
🔁 SINCE LAST BRIEF (Fri 4 Sep)
· **Friday's commitments** — confirm PR #1428 merged → done. Commit G1 on
  the ABC-101 branch → not done, branch still dirty. Review Alex's payments
  mappings #1423 → still open.
· **Landed** — `data-platform`: 4 PRs into `dev`, all yours: report year
  ceiling (#1428), tax-code padding (#1421), export folder suffix (#1424),
  PR templates per base branch (#1419). Nothing elsewhere.
· **Threads moved** — report year ceiling: its next step is done. The
  other five did not move.
```

## 🧵 IN PROGRESS

Every open thread except START HERE, **ordered by recency** (`Nd`
ascending), not by state. The state still appears on each line, so the
reader sees which threads are going nowhere without the brief reordering
their continuity for them.

Each bullet carries, in order:

- the **handle** — 2–4 plain-English words from the handoff title, not the
  title verbatim;
- its **state and age** — `Dangling, 3d` — read straight from
  `context.md`;
- **where it stopped**, in one clause, from the handoff's opening
  paragraph or its struck-through next step;
- **`Next:`** — the `— next:` clause, shortened, never replaced with a
  vaguer paraphrase.

A handoff with no `— next:` clause has no "Next steps" section to read;
say `No next step recorded` rather than inventing one. Where the next step
is struck through as done, say so, and give what follows only if
`context.md` actually names it (a ticket whose summary is that follow-up,
for instance).

Cold threads (older than 21d) do not get bullets. They collapse into one
trailing line naming each with its age:
`· Parked: **V1.1 roadmap draft** — Cold, 33d.`

```
🧵 IN PROGRESS · 5 more threads
Two dangling with uncommitted work behind them, one waiting on you.
· **report year ceiling** — Dangling, 3d. PR #1428 is merged; the follow-up
  already exists as ABC-110, a staging integration test, unowned. Next:
  take ABC-110 or give it an owner.
· **core-api identical responses** — Open loop, 4d. Next: it is waiting on
  your answer to question §6.1.
· **baseline plan** — Dangling, 6d. `ml-pipelines` dirty 2d on `stage`.
  Next: commit the doc edits.
· Parked: **V1.1 roadmap draft** — Cold, 33d.
```

## 👤 WAITING ON YOU

People, not systems. PRs awaiting the user's review, a question asked and
unanswered, a handoff explicitly waiting on them. Name the actual person
from `context.md`'s data (e.g. Alex Rivera, Dana Taylor) — never a generic
"someone" or "the team".

```
👤 WAITING ON YOU
Alex Rivera is the only person blocked on you.
· **Alex's two PRs** — `data-platform` #1429 waste-data ingestion refactor,
  #1423 payments mappings for billing. #1423 was on Friday's list. ⚠️
```

## 🎫 JIRA

`context.md` groups the Jira items under sub-headings, and that grouping
is not decoration — it is who owns the work:

| Sub-heading | Means |
|---|---|
| `### Assigned to you` | the user's own queue; the only tickets they are on the hook for |
| `### You reported, owned by someone else` | the user filed it, a named colleague owns it; listed under that person's name |
| `### Unassigned, filed in the last 3 days` | filed this week, nobody picked it up yet |
| `### Unassigned, older` | backlog; rendered as key + summary only |

**Never present a ticket from the second or third group as the user's own
work.** A ticket owned by a colleague belongs in 👤 WAITING ON YOU only
if they are actually blocked on the user, and otherwise is context, not a
task. An unassigned ticket's next step is "pick it up or leave it", never
"you're behind on it". A ✅ TODAY item drawn from the second group is
classified `(→ Name)`, using the assignee's name as `context.md` gives it.

The two unassigned groups get very different weight. **Name the recently
filed ones**, and where several share a subject, name the cluster and its
key range rather than every key — who takes them is still an open
question. The older group is backlog: give it a **count**, in the group
heading, never a list of keys.

Each line ends with `[<n>d]` — days since the ticket last moved — and
`due <date>`, marked `overdue` when the date has passed. Those two facts
are the *only* basis for calling something stale or late; there is no
other staleness input, so never assert an age or a deadline that is not
on the line.

A ticket already described by a thread bullet is **counted** here, never
described again.

Say nothing about a ticket that `context.md` does not carry. It has no
comments, no sprint, no priority and no history — if the answer is not in
the line, it is not available.

```
🎫 JIRA · 50 open — 10 yours, 15 with colleagues, 25 unowned (13 old backlog)
One of yours is blocked, four more are overdue, five went quiet. Twelve
filed this week have no owner.
· **ABC-102 blocked** — regional downscaling on the converged model vintage,
  gates the regional rollout. 7d untouched, due 28 Aug, overdue. ⚠️
· **Four overdue of yours** — asset refactor (ABC-201, 119d), impact-model
  chores (ABC-202, 63d), report region-level NULLs (ABC-203, 46d), ops
  handbook (ABC-204, 33d).
· **Five In corso quiet 5d** — Topic A gold (ABC-205) and Topic B gold
  (ABC-206), both due Thu 11 Sep; quarterly ingestion (PROJ-45), Report
  Research (PROJ-46), Report Sport (PROJ-47).
· **Twelve unowned, filed this week** — nine are one cluster on the report
  year ceiling and coverage policy (ABC-301–ABC-309); ABC-101 is the START
  HERE branch; ABC-310/ABC-311 are a new project's set-up pair.
```

## 📦 REPOS

**Orphan dirt only.** A dirty repo gets a bullet only when no thread above
already names its current branch. If every dirty repo is explained by a
thread, the group vanishes. Stale refs never produce a REPOS bullet —
they belong to 🧹 CLEANUP.

```
📦 REPOS
One repo is dirty outside any thread above.
· **banner card** — `web-app` dirty on `fix/hide-banner-card`; no handoff or
  ticket covers it, last commit is a dependabot bump.
```

## 🧹 CLEANUP (optional)

Only when `context.md` has a `## Stale refs` section — otherwise the
group vanishes, same no-filler rule as everywhere else. **One line, counts
only.** Say `all \`git branch -d\` safe` when every entry is `merged` with
no `[locked]` / `[dirty:N]` marker, otherwise `N need inspection first`.

Do **not** print git commands in the brief. The verbatim commands stay in
`context.md`; they are echoed after Phase 2, and only for the repos the
user actually picked. This skill has no Bash tool and cannot run anything
itself.

```
🧹 CLEANUP · 6 merged branches (data-platform 4, ml-pipelines 1,
core-mono 1), all `git branch -d` safe.
```

## ✅ TODAY

Exactly the three (or fewer) things the user will actually do, numbered
`1.`–`3.`.

**Item 1 is always the ▶ START HERE thread**, restated as a commitment.
Items 2 and 3 come from 👤, 🎫 and 🧵 by the ⚠️ rubric.

Each item must end in one of exactly four verbs, **written out** as the
last clause before the tags, and nothing else counts as a next step:

- `— do it.`
- `— hand it over.`
- `— park until <named date>.`
- `— drop it.`

If something doesn't fit one of those four, it belongs in one of the
groups above, or nowhere — never force it into TODAY.

Each item carries a short clause on why it's today's work (who's blocked,
what drifts otherwise, how long it takes) — the same self-explaining rule
as every other bullet.

### Delegation classification

**Every TODAY item carries a delegation classification** — one of three,
as a suffix on the item. Classify every item; there is no fourth option
and no "unclear".

| Suffix | Means | Use when |
|---|---|---|
| `(→ \`agent\`)` | an agent could do this | mechanical, bounded, in one of the 4 watched repos, spec is already clear |
| `(→ Name)` | a teammate owns it | the work sits with a person named in `context.md` (a PR author, a ticket assignee) |
| `(yours)` | only the user can do it | judgment calls, replies to people, decisions, anything unscoped |

Never classify a "reply to a person" item (Alex's question, an unread
thread) as delegable — that is always `(yours)`. Never name a teammate
who does not appear in `context.md`. This is a **proposal only**: this
skill has no Agent tool and cannot dispatch anything.

For the `→ \`agent\`` case, pick from this fixed catalog, matched to the
actual repo and task; never invent an agent name outside it:

| Agent | Fits |
|---|---|
| `minion` | One-line fixes, renames, mechanical formatting |
| `implementer` | A scoped code change with a clear spec, generalist |
| `impl-dbx` | Databricks work in `data-platform`, `ml-pipelines` |
| `impl-fe` | Frontend work in `web-app` |
| `code-reviewer` | Reviewing a specific PR before merge |
| `code-simplifier` | Auditing a file/module for overengineering |
| `Explore` | "Where is X" / broad investigation, no code change |
| `Plan` | Designing an approach before implementing |

### Effort tag

**Every TODAY item also carries an effort tag** — one word, `quick` or
`involved`, immediately before the delegation suffix. Two buckets only;
this is a personal 3-item list, not a backlog, so no story points, no
Fibonacci.

| Tag | Means | Use when |
|---|---|---|
| `quick` | under ~15 minutes, one clear action | a push, a reply, a decision already made |
| `involved` | real focus time, several steps or unknowns | a multi-PR review, drafting something, tracking down a cause |

```
✅ TODAY
1. Commit G1 + README row on `docs/ABC-101-quarterly-refresh-map` and
   open the PR — do it. quick (yours)
2. Alex's #1429 and #1423 — they are blocked; agent first pass, you merge —
   hand it over. involved (→ `code-reviewer`)
3. ABC-201, ABC-202, ABC-203, ABC-204, overdue 33–119 days — park until
   Mon 14 Sep. quick (yours)
```

The internal codes `T1`, `T2`, `T3` correspond to TODAY items 1, 2, 3.
They never appear in the brief itself — they exist only in
`commitments-YYYY-MM-DD.json` and in task-list text (SKILL.md steps 4
and 5).

## Standups

Standup content folds into the groups above rather than getting its own
blocks: what's in progress belongs in 🧵 IN PROGRESS, what's blocked
carries a ⚠️, and who is waiting belongs in 👤 WAITING ON YOU. Do not emit
separate `STANDUP ·` blocks.

## Footer

One line naming which sources were reached, plus the standing calendar
and mail note. When `context.md` ends with a `## Parked` section, add its
count as a second clause — a suppressed item is hidden, not lost.

```
All five sources reached. Calendar/mail not covered — check those yourself.
```

or, listing what was and wasn't:

```
Jira, git, handoffs, stale refs reached. GitHub not reached (rate limited).
2 items parked until 14 Sep. Calendar/mail not covered — check those yourself.
```

## Tone

- State commitments flatly. "Friday you said you would commit G1. The
  branch is still dirty." Never disappointed-sounding, never
  "unfortunately" or "still hasn't".
- No commentary, no congratulating, no explaining why something was
  chosen or left out.
- The opening sentences describe the situation; they do not editorialise
  about it.

## Worked example

```
**Monday 7 September** — first brief since Friday 4th. Four of your PRs
landed in `data-platform` over the gap; one of Friday's three
commitments is done.
Load: NORMAL

▶ START HERE
· **ABC-101 refresh map** — you stopped Thursday with G1 and the README
  row written but not committed, on `data-platform` branch
  `docs/ABC-101-quarterly-refresh-map` (dirty 2d). First move: one
  `docs(research):` commit, then the branch is PR-ready. About 15 minutes.

🔁 SINCE LAST BRIEF (Fri 4 Sep)
· **Friday's commitments** — confirm PR #1428 merged → done. Commit G1 on
  the ABC-101 branch → not done, branch still dirty. Review Alex's payments
  mappings #1423 → still open.
· **Landed** — `data-platform`: 4 PRs into `dev`, all yours: report year
  ceiling (#1428), tax-code padding (#1421), export folder suffix (#1424),
  PR templates per base branch (#1419). Nothing elsewhere.
· **Threads moved** — report year ceiling: its next step is done. The
  other five did not move.

🧵 IN PROGRESS · 5 more threads
Two dangling with uncommitted work behind them, one waiting on you.
· **report year ceiling** — Dangling, 3d. PR #1428 is merged; the follow-up
  already exists as ABC-110, a staging integration test, unowned. Next:
  take ABC-110 or give it an owner.
· **core-api identical responses** — Open loop, 4d. Next: it is waiting on
  your answer to question §6.1.
· **Staging-testing skill** — Open loop, 4d, from the ABC-206/ABC-207
  promotion run. No next step recorded. ABC-206 Topic B gold is due Thu
  11 Sep.
· **baseline plan** — Dangling, 6d. `ml-pipelines` dirty 2d on `stage`.
  Next: commit the doc edits.
· Parked: **V1.1 roadmap draft** — Cold, 33d.

👤 WAITING ON YOU
Alex Rivera is the only person blocked on you.
· **Alex's two PRs** — `data-platform` #1429 waste-data ingestion refactor,
  #1423 payments mappings for billing. #1423 was on Friday's list. ⚠️

🎫 JIRA · 50 open — 10 yours, 15 with colleagues, 25 unowned (13 old backlog)
One of yours is blocked, four more are overdue, five went quiet. Twelve
filed this week have no owner.
· **ABC-102 blocked** — regional downscaling on the converged model vintage,
  gates the regional rollout. 7d untouched, due 28 Aug, overdue. ⚠️
· **Four overdue of yours** — asset refactor (ABC-201, 119d), impact-model
  chores (ABC-202, 63d), report region-level NULLs (ABC-203, 46d), ops
  handbook (ABC-204, 33d).
· **Five In corso quiet 5d** — Topic A gold (ABC-205) and Topic B gold
  (ABC-206), both due Thu 11 Sep; quarterly ingestion (PROJ-45), Report
  Research (PROJ-46), Report Sport (PROJ-47).
· **Twelve unowned, filed this week** — nine are one cluster on the report
  year ceiling and coverage policy (ABC-301–ABC-309); ABC-101 is the START
  HERE branch; ABC-310/ABC-311 are a new project's set-up pair.

📦 REPOS
One repo is dirty outside any thread above.
· **banner card** — `web-app` dirty on `fix/hide-banner-card`; no handoff or
  ticket covers it, last commit is a dependabot bump.

🧹 CLEANUP · 6 merged branches (data-platform 4, ml-pipelines 1,
core-mono 1), all `git branch -d` safe.

✅ TODAY
1. Commit G1 + README row on `docs/ABC-101-quarterly-refresh-map` and
   open the PR — do it. quick (yours)
2. Alex's #1429 and #1423 — they are blocked; agent first pass, you merge —
   hand it over. involved (→ `code-reviewer`)
3. ABC-201, ABC-202, ABC-203, ABC-204, overdue 33–119 days — park until
   Mon 14 Sep. quick (yours)

Jira, GitHub, git, handoffs, stale refs reached. Calendar/mail not covered —
check those yourself.
```
