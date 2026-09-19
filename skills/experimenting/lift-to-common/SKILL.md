---
name: lift-to-common
description: Mechanical refactor — lift a function (plus its transitive private helpers) from `experiments/<NN>/src/<file>.py` to `research/common/<module>.py`; rewrite imports in all consumer experiments; verify via parity + smoke + ruff. Use when ≥ 2 experiments need the same code (PI shared-code policy). Dispatchable to a Sonnet subagent — no architectural judgment required.
---

# lift-to-common

Progressive code-structure cleanup for research-loop monorepos. When two or more experiments need the same module (data loader, split impl, bootstrap helper, etc.), lift it once to `research/common/` instead of letting copies drift.

## When to invoke

- A second experiment is about to consume the same function as a first experiment.
- A peer-review finding flags duplicated logic with subtle drift between experiments (e.g. split protocols mismatched).
- A consumer-count audit reveals a function imported from `experiments/<NN>/src/...` by another experiment via `sys.path` hack — formalize the lift.

**Skip** if the function is genuinely per-experiment (uses experiment-specific config keys, named after the experiment, only one experiment will ever need it).

## Anti-patterns this skill prevents

- Copy-paste between experiments → silent divergence (e.g. 01_baseline NUTS3-stratified spatial vs 03_gnn_enriched pure-random spatial — caught in peer review B1 only).
- Reaching into another experiment's `src/` via `sys.path.insert(..., experiments/01/src)` from inside experiment 03 — creates a hidden cross-experiment dependency without formalization.
- Half-lifts where helper is moved but consumers still duplicate the function body locally.

## Inputs

- `<source_path>` — absolute path to the function's current home (e.g. `research/experiments/03_gnn_enriched/src/data_loader.py`).
- `<symbols>` — list of public symbols to lift (e.g. `["load_enriched_covariates"]`). Transitive private helpers will be lifted automatically.
- `<target_module>` — destination filename in `research/common/` (e.g. `research/common/enriched_covariates.py`).
- `<consumers>` — list of experiment dirs that should import from common after the lift (e.g. `["01_baseline", "03_gnn_enriched"]`).

## Steps

### Step 1 — Survey & identify transitive deps

1. Read `<source_path>` end-to-end. For each symbol in `<symbols>`, walk the call graph: which private helpers (`_foo`, `_bar`) does it call? Which of those helpers are also called by OTHER public functions in the same file?
2. Classify each helper:
   - **Exclusive to lifted symbols** → moves to common.
   - **Shared with other in-source-file public functions** → moves to common, then re-imported back into source file so there is one source of truth.
   - **Unrelated to lifted symbols** → stays in source file untouched.
3. Surface findings as a 3-column table: `symbol | used_by_lifted_only | used_by_other_in_source`.

### Step 2 — Create `research/common/<target_module>.py`

- File header: 2-line module docstring noting `Lifted YYYY-MM-DD from <source_path>. Consumed by: <consumers>.`
- Move lifted function(s) + helpers verbatim (preserve type hints, docstrings, warnings, behavior).
- If `research/common/` is empty, create `research/common/__init__.py` (empty or with `__all__`).
- If `research/__init__.py` doesn't exist, create it (empty) — needed for `from research.common...` imports to resolve as a package.

### Step 3 — Rewrite source file

- DELETE the lifted symbols from `<source_path>`.
- For helpers that were ALSO used by other in-source-file functions: add `from research.common.<target_module> import _helper_name` at the top of `<source_path>` (private import is OK — single source of truth).
- Insert sys.path hack at top:
  ```python
  import sys
  from pathlib import Path
  _REPO_ROOT = Path(__file__).resolve().parents[N]  # N = depth to the research repo root
  if str(_REPO_ROOT) not in sys.path:
      sys.path.insert(0, str(_REPO_ROOT))
  ```
  Computing `N`: count the number of directories between `__file__` and the repo root. For `research/experiments/<NN>/src/<file>.py`, N=4.
- Add `# noqa: E402` to the `from research.common...` import line (sys.path manipulation comes before it).

### Step 4 — Rewrite consumers

For each consumer in `<consumers>` that is NOT the source file's own experiment:

- Locate its data_loader / splits / bootstrap usage points.
- Replace local impl OR cross-experiment `sys.path` reach-arounds with `from research.common.<target_module> import <symbols>`.
- Add the same sys.path hack (Step 3) at the consumer's entrypoint.
- Preserve all other consumer logic; the lift is pure code-relocation, not redesign.

### Step 5 — Parity test

Mandatory before declaring done. Run a Python block from the repo root:

```python
from research.experiments.<consumer_A>.src.<file> import <symbol> as fn_a
from research.experiments.<consumer_B>.src.<file> import <symbol> as fn_b
# Assert byte-identical output for the same inputs + same seed
out_a = fn_a(*test_args, seed=0)
out_b = fn_b(*test_args, seed=0)
assert (out_a == out_b).all()  # or appropriate equality check
print("parity: PASS")
```

If the consumers had previously divergent local impls → this assertion will fail. That IS the bug the lift exists to fix. Surface the divergence as a peer-review finding before committing the lift.

### Step 6 — Smoke test each consumer's driver

- For each consumer, run a one-line import check: `python -c "from <consumer>.src.<entrypoint> import ..."` to confirm imports still resolve.
- If a consumer has a fast `--smoke` mode: run it.
- If a consumer has a single representative cell that can be re-run end-to-end in < 1 minute: re-run + byte-compare a fresh per-run JSON against an archived one (machine-precision MAE check).

### Step 7 — Lint

```bash
cd <repo_root> && uv run ruff format research/common/<target_module>.py research/__init__.py research/common/__init__.py <each modified consumer file> && uv run ruff check --fix research/common/<target_module>.py <each modified consumer file>
```

Common ruff fixes after a lift:
- `F401 imported but unused` on the new `from .module import name` lines in `research/common/__init__.py` → add explicit `__all__` list re-exporting the names.
- `I001 unsorted imports` → ruff auto-fixes.

## Constraints

- **DO NOT** redesign the function's API during the lift. Pure relocation. API changes go in a separate PR.
- **DO NOT** lift functions that don't have ≥ 2 consumers yet — too early.
- **DO NOT** lift configuration constants without their accompanying functions (constants without context become orphaned magic numbers in `common/`).
- **DO NOT** commit until parity test + smoke test + lint all pass.
- When dispatching as a subagent: explicitly forbid touching ANY file outside the lift surface (other subagents may be editing in parallel).

## Deliverables

When done, the lift's deliverable summary should report:

- Files touched (1-line diff each).
- Transitive helpers identified + lift decisions (per Step 1 table).
- sys.path hack `parents[N]` depth + justification.
- Parity test output (verbatim).
- Smoke test exit status per consumer.
- Lint status.
- Any divergence between consumers' prior local impls (a peer-review finding).

## Edge cases

| Case | Behavior |
|---|---|
| `research/__init__.py` already exists | Leave alone. |
| Lifted function imports another lifted function from common | Use relative `from .other_module import foo` inside common files. |
| Helper has a global side effect (e.g. registers in a registry) | Move with care; verify the registry import order still works. |
| Consumer has a CLI flag that toggled the old vs new feature path | Preserve the flag, route both branches through the lifted function. |
| Function uses experiment-specific paths (e.g. `f"experiments/{name}/data/"`) | Refactor to take `data_root: Path` parameter BEFORE lifting; lift is not the right place to fix tight coupling. |
| Two consumers had divergent prior impls (e.g. one was buggy) | Pick the correct one as canonical; surface the choice in the deliverable; the lift IS the fix. |

## Cross-references

- Pair with `falsifiability-check` Check 6 (bootstrap determinism) — same shared-code discipline applies.
- Triggered by peer-review findings that name cross-experiment inconsistency (e.g. peer-review B1 split-protocol mismatch).
- Memory: search for `feedback_shared_code_refactor` in the project memory store for project-specific lift conventions and dispatch patterns.
