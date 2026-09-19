# Evalset — frozen cases for project-scope validation (Path A)

This folder holds the held-out task split that gives project-scope validation its teeth. Each case is a
**frozen** prompt whose correct outcome is checkable by a deterministic verifier (`pytest`, a check
script, `ruff`, `dbt`). A candidate harness edit is accepted only if replaying these cases under it
doesn't regress any and improves at least one (see `../references/validation.md`).

## Two case modes

A coding prompt has no fixed "correct" output in the abstract — the outcome depends on the starting
state. The starting state is frozen one of two ways:

- **self-contained (preferred)** — the case ships a starter directory under `fixtures/<id>/` holding the
  oracle test plus any starter code. The harness copies it into a sandbox and replays there. Portable,
  not tied to any repo or git history. Use this for generic tasks.
- **pinned-repo** — the task runs against a real repo at a frozen commit. The case pins `work_commit`
  (task start state) and `oracle_from` (the child commit the verifier test is checked out from), so the
  test that grades the work is an independent artifact, not something the agent wrote. Use only when a
  task is genuinely repo-specific.

## The oracle must be independent of the agent

The agent implements or fixes code; it must never write or edit the test that grades it, or the gate is
circular — the agent would be marking its own homework. Each case lists `protect:` — the oracle (and any
other off-limits files); the validation harness reverts those to their frozen state before running the
verifier. A case earns `discriminates: yes` only if its oracle **fails** on the untouched fixture and
**passes** after correct work. Confirm that before trusting a case (run the verifier on the fixture as
shipped — it should fail).

## Held-out from the proposer

Cases here must **not** be shown to the proposal step. If the proposer sees the evalset, edits overfit
to it and the gate becomes theater — the same held-out discipline the paper relies on.

## Adding a case

1. Pick a small task with an unambiguous deterministic check (a unit test, or a script that asserts the
   condition). Behavior cases — "was the edit surgical?" — are fair game if a script can judge them.
2. Build its frozen start state: a `fixtures/<id>/` dir (self-contained), or a `work_commit` +
   `oracle_from` pair (pinned-repo).
3. Write the prompt as a user would phrase it.
4. Give the verifier command, the pass condition (`exit_zero`, `tests_pass:N`, `no_findings`), and the
   `protect:` paths.
5. Confirm `discriminates`: run the verifier on the untouched fixture — it must fail.
6. Add the entry to `manifest.yml` (copy `manifest.example.yml`). Keep the set at 5–10 cases — validation
   cost is `K candidates × N cases × M repeats` subagent runs.

`manifest.yml` is gitignored-by-intent for personal setups; `manifest.example.yml` is the template.
