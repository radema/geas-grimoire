---
description: Manage the project's knowledge base by ingesting, extracting, and linking intelligence.
---

# Bolt-Synthesis Workflow: Knowledge Management

This workflow is designed for the **Lead / Orchestrator** to manage the project's knowledge base. Use it when ingesting new research, articles, or codebase patterns to ensure they become permanent, portable assets.

1. **Intelligence Ingestion**
// turbo
Use appropriate tools (`read_url_content`, `mcp_github_server`, `browser_subagent`) to ingest the target reference. Extract the core thesis, key insights, and any major shifts or patterns described.

2. **Axiom & Constraint Extraction**
Analyze the ingested data to extract:
- **Axioms**: Core principles or "Universal Truths" found in the source.
- **Constraints**: Physical, technical, or systemic limits.
Store these as structured notes in the project's memory system (e.g., `.agent_memory/` or `docs/knowledge/`).

3. **Strategic Cross-Linking**
Apply the **Golden Rule of Linking**:
- Every new concept SHOULD link to at least one internal concept (e.g., a protocol or workflow) and one external reference.
- Update relevant indexes to reflect the new nodes in the knowledge graph.

4. **Manifesto / Documentation Refactoring**
Update the primary project documentation or "Living Manifesto" (e.g., `docs/vision.md`). 
- Do not just append information. 
- Rewrite sections to incorporate the new intelligence into the overarching narrative.

5. **Consolidation & Sealing**
Perform a formal memory audit:
- Resolve naming conflicts or redundant definitions.
- Delete temporary files or outdated draft versions.
- Archive finalized "Bolts" or previous states.
- Report the "State of the Knowledge Graph" for final review.
