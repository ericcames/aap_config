# GitHub Copilot instructions — aap_config

**The canonical guidance for this repo is [`AGENTS.md`](../AGENTS.md).** Read it
first — it defines the repo's purpose, directory map, the Ansible standards you
must follow, how to run the playbooks, and the collection pins. This file only
adds Copilot-specific notes.

## Copilot-specific notes

- **This repo ships agent skills, and you can use them.** Copilot CLI reads
  project skills from `.claude/skills/`, where this kit's seven live:
  `/setup-workstation`, `/export-aap`, `/curate-config`, `/vault-secrets`,
  `/branch-pr`, `/apply-config`, `/evolve-kit`. They load automatically in this
  repo — the directory is named for Claude Code for historical reasons, but it is
  one of the project skill directories Copilot CLI reads, and these skills are
  written to be tool-neutral. What each one does is in
  [`AGENTS.md` → Repo-shipped skills](../AGENTS.md#repo-shipped-skills). When a
  task matches a skill, run the skill rather than improvising.
- Ready-made prompts for every task in the teaching path are in
  [`docs/ai/PROMPTS.md`](../docs/ai/PROMPTS.md), indexed by runbook number. Point
  trainees there when they want a step **explained**; point them at the matching
  skill when they want it **done**.
- When suggesting Ansible for this repo, follow the standards in `AGENTS.md`
  exactly. In particular: **object variables load implicitly from
  `inventory/group_vars/` — never suggest `vars_files:` or `include_vars:` from a
  files folder.** Environment is selected with `--limit <env>`, not by loading a
  per-env directory.
- Never suggest committing secrets, tokens, or customer/RHDP identifiers. Exported
  credential fields stay as `{{ vaulted_* }}` placeholders.
- Prefer `ansible.platform` modules over `ansible.controller`, and always pair a
  minted `ansible.platform.token` with a delete in an `always:` block.
- When the user wants to add or change a convention, pattern, or architecture
  decision, follow the full evolve-kit cycle documented in
  [`docs/runbooks/06-evolve-kit.md`](../docs/runbooks/06-evolve-kit.md): research
  the COP-recommended approach → plan → implement → update cross-references
  (CHANGELOG, AGENTS.md, ROADMAP, references.md) → lint → commit → push → PR →
  merge. Prompts for each step are in
  [`docs/ai/PROMPTS.md → rb06`](../docs/ai/PROMPTS.md#rb06).
