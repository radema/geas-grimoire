# Migration Plan: Evolving geas-grimoire

## Overview

This plan outlines a gradual evolution of geas-grimoire from a monolithic knowledge store to a more modular, platform-agnostic system while:
- Keeping all existing structure working (backward compatible)
- Supporting both OpenCode and Antigravity equally
- Tracking opencode.jsonc in git
- Avoiding forced migrations - everything is optional
- Building on existing directories, not creating unnecessary new ones

## Core Principles

✅ **Track opencode.jsonc** - Keep it in git at `opencode/opencode.jsonc`
✅ **Support Antigravity + OpenCode** - Both have equal first-class support
✅ **Skip Claude Code** - Not included anywhere
✅ **Start from existing files** - No forced restructure, gradual evolution
✅ **Backward compatible** - Old structure continues to work
✅ **Optional migration** - Projects can opt-in to new structure
✅ **Minimal disruption** - Each phase can be done independently
✅ **No `.geas/` folder** - Use existing directories

---

## Phase 0: Foundation (Immediate)

**Goal**: Minimal changes, use existing directories

### Directory Changes

```
geas-grimoire/
├── opencode/                           # KEEP: OpenCode config (STILL TRACKED)
│   ├── opencode.jsonc                 # KEEP (already tracked)
│   ├── agent/                         # KEEP: Agent definitions
│   └── command-registry.yaml          # NEW: Centralized commands
│
├── antigravity/                       # NEW: Antigravity config
│   ├── config/
│   └── adapters/
│
├── core/                              # NEW: Interfaces & schemas ONLY
│   ├── interfaces/
│   └── schemas/
│
├── skills/                            # KEEP: Existing skills (unchanged)
├── workflows/                         # KEEP: Existing workflows (unchanged)
├── rules/                             # KEEP: Existing rules (unchanged)
└── docs/                              # KEEP: Existing docs (unchanged)
```

### Tasks

- [ ] Create `core/interfaces/` for interface definitions
- [ ] Create `core/schemas/` for validation schemas
- [ ] Create `antigravity/` directory for Antigravity configuration
- [ ] Create `opencode/command-registry.yaml` to centralize commands (extracted from opencode.jsonc)
- [ ] Update opencode.jsonc to reference the command registry
- [ ] **No `.geas/` folder** - use existing directories

---

## Phase 1: Interface Contracts (Week 1-2)

**Goal**: Define interfaces (nothing moved, just added)

### Directory Changes

```
core/
├── interfaces/
│   ├── skill-interface.md          # NEW
│   ├── workflow-interface.md       # NEW
│   ├── agent-interface.md          # NEW
│   └── adapter-interface.md        # NEW
│
└── schemas/
    ├── skill-schema.json          # NEW
    └── workflow-schema.json       # NEW
```

### Tasks

- [ ] Create interface definitions based on existing patterns
- [ ] Create validation schemas
- [ ] Document in `docs/technical/05_interfaces.md` (add to existing docs)
- [ ] Use existing files as reference:
  - `skills/build-knowledge/SKILL.md`
  - `workflows/bolt-intent.md`
  - `opencode/agent/developer.md`

---

## Phase 2: Skill Validation (Week 2-3)

**Goal**: Validate existing skills (no structure changes)

### Tasks

- [ ] Create validation script: `scripts/validate-skills.py`
- [ ] Run against all skills in `skills/`
- [ ] Generate compliance reports
- [ ] **No changes to skill directories** - keep them as-is
- [ ] Document any gaps

---

## Phase 3: Platform Adapters (Week 3-4)

**Goal**: Create adapter layer using existing directories

### Directory Changes

```
opencode/
├── opencode.jsonc                 # KEEP
├── agent/                         # KEEP
├── command-registry.yaml          # ADD: Centralized commands
└── adapter.py                     # NEW: OpenCode adapter

antigravity/
├── config/                        # NEW: Antigravity config
├── adapter.py                     # NEW: Antigravity adapter
└── command-registry.yaml          # NEW: Antigravity commands
```

### Tasks

- [ ] Create `opencode/adapter.py` (implements core interface)
- [ ] Create `antigravity/adapter.py` (implements same interface)
- [ ] Create `opencode/command-registry.yaml` (extract commands from opencode.jsonc)
- [ ] Create `antigravity/command-registry.yaml` (document Antigravity commands)
- [ ] Keep opencode.jsonc tracked in git

---

## Phase 4: Workflow Abstraction (Week 4-5)

**Goal**: Add universal workflows alongside existing bolt

### Directory Changes

```
workflows/
├── bolt/                           # KEEP: Existing bolt workflows
│   ├── bolt-intent.md
│   ├── bolt-implementation.md
│   └── bolt-verify.md
│
└── universal/                      # NEW: Generic workflows
    ├── plan.md
    ├── implement.md
    └── verify.md
```

### Tasks

- [ ] Create `workflows/universal/` with generic phases
- [ ] Add frontmatter to universal workflows mapping to bolt
- [ ] **Keep bolt workflows unchanged**
- [ ] Document in `docs/technical/06_workflows.md`

---

## Phase 5: Configuration (Week 5-6)

**Goal**: Add configuration using existing directories

### Directory Changes

```
opencode/
├── opencode.jsonc                 # KEEP
├── config.yaml                     # NEW: Base configuration
├── agent/                         # KEEP
└── command-registry.yaml          # NEW
```

### Tasks

- [ ] Add `opencode/config.yaml` with standards and settings
- [ ] Document configuration options
- [ ] Keep all existing opencode.jsonc functionality
- [ ] **No `.geas/` folder**

---

## Phase 6: Command Registry (Week 6-7)

**Goal**: Centralize commands in `opencode/`

### Directory Changes

```
opencode/
├── opencode.jsonc                 # KEEP
├── command-registry.yaml          # NEW
│   # Extract commands from opencode.jsonc
│   commands:
│     test:
│       template: "uv run pytest"
│     quality:
│       template: "uv run quality"
│     single-test:
│       template: "uv run python skills/{skill}/scripts/test_{module}.py"
│
antigravity/
└── command-registry.yaml          # NEW
```

### Tasks

- [ ] Extract commands from `opencode/opencode.jsonc` → `opencode/command-registry.yaml`
- [ ] Create `antigravity/command-registry.yaml`
- [ ] Update opencode.jsonc to reference command-registry.yaml
- [ ] Update AGENTS.md to reference new registry

---

## Phase 7: Documentation (Week 7-8)

**Goal**: Add to existing `docs/`

### Directory Changes

```
docs/
├── technical/
│   ├── 01_system_architecture.md  # KEEP
│   ├── 02_component_schemas.md    # KEEP
│   ├── 03_interfaces.md           # KEEP
│   ├── 04_contribution_guide.md   # KEEP
│   ├── 05_interfaces.md           # NEW: Interface definitions
│   ├── 06_workflows.md            # NEW: Workflow system
│   ├── 07_adapters.md             # NEW: Platform adapters
│   └── 08_configuration.md        # NEW: Configuration guide
│
└── guides/                         # NEW: Usage guides
    ├── opencode-guide.md
    ├── antigravity-guide.md
    └── multi-platform-guide.md
```

### Tasks

- [ ] Add new technical docs to existing `docs/technical/`
- [ ] Create `docs/guides/` for platform-specific guides
- [ ] Update README with new structure overview
- [ ] **Keep all existing docs unchanged**

---

## Phase 8: Testing (Week 8-9)

**Goal**: Add tests using existing structure

### Directory Changes

```
tests/                             # NEW (if needed) OR use skill test dirs
├── validation/
│   ├── test_skill_validation.py
│   └── test_workflow_validation.py
│
└── integration/
    ├── test_opencode_adapter.py
    └── test_antigravity_adapter.py
```

### Tasks

- [ ] Create validation tests
- [ ] Create adapter tests
- [ ] Ensure existing skill tests still work
- [ ] **No changes to existing test locations**

---

## Phase 9: Gradual Adoption (Ongoing)

**Goal**: Optional, no forced migration

### Strategy

- [ ] **Keep everything working**: No changes to existing paths
- [ ] **Add new capabilities**: Adapters, universal workflows, validation
- [ ] **Optional migration**: Projects can opt-in to new features
- [ ] **No deprecation**: Keep old structure indefinitely if it works

---

## Summary: Minimal Migration Plan

| Phase | What Changes | What Stays Same |
|-------|--------------|-----------------|
| 0 | Add `core/`, `antigravity/`, command registries | `skills/`, `workflows/`, `rules/`, `opencode/agent/` |
| 1 | Add `core/interfaces/` & `core/schemas/` | All skill/workflow files unchanged |
| 2 | Add validation script | Skill directories unchanged |
| 3 | Add adapter files | Existing configs unchanged |
| 4 | Add `workflows/universal/` | `workflows/bolt/` unchanged |
| 5 | Add `opencode/config.yaml` | opencode.jsonc unchanged |
| 6 | Add `command-registry.yaml` | All existing functionality |
| 7 | Add docs to `docs/` | All existing docs |
| 8 | Add tests | Existing tests unchanged |
| 9 | Optional features | Nothing forced |

---

## Key Changes from Original Idea

❌ **No `.geas/` folder** - use existing directories
❌ **No `integrations/` folder** - use existing `opencode/` and new `antigravity/`
❌ **No packaging** - stay as file-based repository
✅ **Add `core/` only for interfaces/schemas** - minimal new structure
✅ **Add `antigravity/`** - for Antigravity configuration
✅ **Add command registries** - in respective platform directories
✅ **Add `workflows/universal/`** - alongside existing bolt workflows
✅ **Keep opencode.jsonc tracked** - never move it from git tracking
✅ **Everything else unchanged** - skills, workflows, rules stay as-is

---

## Migration Checklist

- [ ] **Phase 0**: Create `core/` and `antigravity/`, add command registries
- [ ] **Phase 1**: Define core interfaces and schemas
- [ ] **Phase 2**: Validate existing skills against interfaces
- [ ] **Phase 3**: Create OpenCode and Antigravity adapters
- [ ] **Phase 4**: Add universal workflows alongside bolt
- [ ] **Phase 5**: Create configuration system
- [ ] **Phase 6**: Centralize command registry
- [ ] **Phase 7**: Update documentation
- [ ] **Phase 8**: Test and validate
- [ ] **Phase 9**: Gradual rollout with optional migration

---

## Next Steps

When ready to begin:
1. Start with Phase 0 - create the minimal new directories
2. Each phase can be done independently
3. Everything is optional - no forced migration
4. Existing structure continues to work throughout
