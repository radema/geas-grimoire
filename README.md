# geas-grimoire 📜

**A personal repository of Agentic prompts, skills, and workflows.**

[![Repo Type](https://img.shields.io/badge/Repo_Type-Knowledge_Base-0052CC?style=flat-square)](https://github.com/radema/geas-grimoire)
[![Resources](https://img.shields.io/badge/Resources-Prompts_&_Workflows-orange?style=flat-square)](https://github.com/radema/geas-grimoire)
[![Access](https://img.shields.io/badge/Access-Public-success?style=flat-square)](https://github.com/radema/geas-grimoire)

## 📖 The Concept

**geas-grimoire** is a collection of "spells"—the raw prompts, tool definitions, and logic chains used to drive AI Agents.

The name is a thematic nod to my experimental project, **[geas-ai](https://github.com/radema/geas-ai)**.
* While `geas-ai` focuses on the *binding and sealing* of agentic artifacts (governance),
* `geas-grimoire` focuses on the *invocation*—providing the text and logic needed to wake the agents up.

> **Note:** This repository is platform-agnostic. While it shares a naming convention with `geas-ai`, these resources are designed to be used freely with **OpenCode**, **ClaudeCode**, **Antigravity**, or your own custom Python scripts.

## 📂 Repository Structure

The repository is organized into three core pillars of agentic development:

### 1. Agents (`/agents`)
*The Personas.*
Contains system prompts and identity definitions. These files define *who* the agent is and its core behavioral instructions.
* **Format:** Markdown / Text / YAML
* **Usage:** Copy the content into your IDE's "System Prompt" field or agent configuration file.

### 2. Workflows (`/workflows`)
*The Rituals.*
Defines the step-by-step logic for complex tasks. These act as "Standard Operating Procedures" (SOPs) or chain-of-thought templates for multi-step reasoning.
* **Content:** Logic chains (e.g., *Research -> Outline -> Draft*).

### 3. Skills (`/skills`)
*The Capabilities.*
A library of tools that agents can use to interact with the world. Each skill has its own dedicated subfolder containing the implementation and the interface definition.

```text
skills/
├── web_search/
│   ├── source_code.py
│   └── interface_def.json
├── file_writer/
│   └── ...
