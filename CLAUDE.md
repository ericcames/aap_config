# CLAUDE.md — aap_config

**Read [`AGENTS.md`](AGENTS.md) first — it is the canonical guidance for this
repo** (purpose, directory map, the Ansible standards you must follow, how to run
export/config/validate/lint, collection pins). This file only adds Claude-Code-
specific notes. Eric's global rules in `~/.claude/CLAUDE.md` also apply.

## Claude-specific notes

- **Repo-shipped skills** live in `.claude/skills/` and mirror the runbooks:
  `/export-aap`, `/curate-config`, `/vault-secrets`. Prefer following a skill over
  improvising — it keeps you aligned with what a trainee is taught to do. Skills
  reference `docs/runbooks/` rather than duplicating steps.
- **The standards in AGENTS.md are hard rules**, not preferences. The most common
  way to get this repo wrong is to reach for `vars_files:`/`include_vars:` to load
  object definitions — don't. Variables come from `inventory/group_vars/` by group
  membership. If you catch yourself writing an `include_vars: dir:`, stop.
- This kit doubles as a **standards-demo vehicle for Eric's team**. Keep AGENTS.md,
  the skills, and the runbooks consistent — a future goal (see ROADMAP) is to
  extract them into a shareable team plugin like `aap-skills`.
- When you change the directory layout or a convention, update `AGENTS.md` in the
  same change — CI checks that every top-level directory is named there.
