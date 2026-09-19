<!--
  Purpose   : Running append-only log of every significant action and decision in a research session.
              Single source of truth for "what happened and when."
  When      : Create at session start (branch + scaffold). Append throughout. Never edit past entries.
  Where     : research/STATE.md  (root of the research/ folder)
  Links to  : [[notes/<slug>]], [[decisions/<slug>]], [[experiments/<NN_name>/...]], [[future_data_sources]]
  Linked from: All ADRs (Context refs), all paper notes (indirectly via session timeline)
-->

# STATE — research/<feature-name>

Append-only log. Timestamp + one line per significant action/decision.

- <YYYY-MM-DDTHH:MMZ> — Branch `<branch-name>` cut from `<base-branch>`. Working folder = `research/`.
- <YYYY-MM-DDTHH:MMZ> — Scaffolded `<subfolder-1>/`, `<subfolder-2>/`, `<subfolder-3>/`, `<subfolder-4>/`. <Tool or env note>.
- <YYYY-MM-DDTHH:MMZ> — <Tooling decision: PDF→MD lib choice, env setup, etc.>
- <YYYY-MM-DDTHH:MMZ> — Seed papers identified: [[papers/<id-1>]] (<short title>, <date>, <Np>) and [[papers/<id-2>]] (<short title>, <date>, <Np>).
- <YYYY-MM-DDTHH:MMZ> — Extraction complete → [[papers_md/<slug-1>]] (<size>), [[papers_md/<slug-2>]] (<size>).
- <YYYY-MM-DDTHH:MMZ> — <Data source / MCP access note>. <Scope restriction, e.g. synthetic only per spec>.
- <YYYY-MM-DDTHH:MMZ> — Notes complete. [[notes/<slug-1>]] relevance <N>/5 (<one-line reason>). [[notes/<slug-2>]] relevance <N>/5 — <one-line reason>.
- <YYYY-MM-DDTHH:MMZ> — Decision: <paper ingestion decision, e.g. SKIP additional ingestion>. <Rationale>. Frees budget for <next task>.
- <YYYY-MM-DDTHH:MMZ> — Differentiator candidates vs <anchor paper>: (1) <diff 1>; (2) <diff 2>; (3) <diff 3>. <Non-claim note>.
- <YYYY-MM-DDTHH:MMZ> — [[notes/_positioning]] drafted. Refined claim: <one-line claim>.
- <YYYY-MM-DDTHH:MMZ> — [[decisions/<NNNN-slug>]] v1 drafted. HALT for PI approval.
- <YYYY-MM-DDTHH:MMZ> — PI: <PI feedback summary>. <Infrastructure change if any>.
- <YYYY-MM-DDTHH:MMZ> — <Session restart or tool reload note if needed>. <What changed>.
- <YYYY-MM-DDTHH:MMZ> — <Schema discovery or data confirmation note>. ADR rewritten to v<N> (<one-line change summary>). HALT for approval.
- <YYYY-MM-DDTHH:MMZ> — PI: <PI confirmations>. ADR v<N> **Accepted**: <key decisions locked>.
- <YYYY-MM-DDTHH:MMZ> — [[future_data_sources]] <created/rewritten> as <description>. <Highest-value next-session adds identified>.
- <YYYY-MM-DDTHH:MMZ> — Task #<N> in progress: <task description>.
- <YYYY-MM-DDTHH:MMZ> — <N> subagents (<model>) launched in parallel: <subagent-1>, <subagent-2>, <subagent-3>, <subagent-4>.
- <YYYY-MM-DDTHH:MMZ> — <Subagent name> subagent done. <N> artifacts written to [[experiments/<NN_name>/<subdir>/]]. Issues logged: <issue-1>; <issue-2>.
- <YYYY-MM-DDTHH:MMZ> — <Subagent name> subagent done: <N> lines / artifacts + <description>. <Notable issues or crosswalk problems>.
- <YYYY-MM-DDTHH:MMZ> — <Subagent name> subagent done. <N> baselines pass smoke test, all coherence ≤ <threshold>. <Notable degenerate case and cause>.
- <YYYY-MM-DDTHH:MMZ> — <Subagent name> subagent done. <N>-run sweep executed in <T>s. All coherence ≤ <threshold>. Best on <split>: <model> (−<N>% MAE vs <baseline>). Best on <split>: <model>. <Broken model note>.
- <YYYY-MM-DDTHH:MMZ> — Robust report written: [[experiments/<NN_name>/results/report]] with CIs, ratio table, ADR threshold check, <broken-model> failure analysis, GNN bar set for ADR 0002.
- <YYYY-MM-DDTHH:MMZ> — Baseline HALT reached. Task #<N> complete. Next: ADR <NNNN> (<description>) — task #<N+1>.
