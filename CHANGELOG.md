# Changelog

All notable changes to this project are documented here. Format based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- **Phase 0 scaffold.** New greenfield config-as-code starter kit for AAP 2.7.
  - `AGENTS.md` canonical AI/standards guidance, with thin `CLAUDE.md` and
    `.github/copilot-instructions.md` shims.
  - Dev container (`.devcontainer/`): UBI9 + Python 3.12, ansible-core 2.18
    stream, `post-create.sh` (container-local `~/.ansible.cfg`, collection
    install, Copilot CLI, secret-hygiene pre-commit hook).
  - `collections/requirements.yml` — single source of truth, pinned to
    `infra.aap_configuration` 4.7.0, `infra.aap_configuration_extended` 4.9.1,
    `ansible.platform` 2.7.20260604, `ansible.controller` 4.8.0.
  - Inventory-native layout: `inventory/hosts.yml` (group `aap` → azure/dev/qa/
    prod) + `inventory/group_vars/` — objects load implicitly, no
    `vars_files`/`include_vars` (Red Hat Services standard).
  - Community standards: CONTRIBUTING, CODE_OF_CONDUCT, LICENSE, CODEOWNERS,
    SECURITY, PR/issue templates, `.yamllint`, `.ansible-lint`, `.gitattributes`
    (LF for Windows), `.gitignore`.
- **Phase 1 export path.** `playbooks/export.yml` (`filetree_create`, controller +
  gateway scope, read-scoped token deleted in `always:`), `exports/` landing zone,
  and `utilities/` guards (`check-vault-encrypted.sh`, `scan-exports.sh`,
  `list-vaulted-vars.sh`). `.github/workflows/lint.yml` PR gate.
- **Phase 2 load path.** `playbooks/config.yml` + `validate.yml` (dispatch via
  implicit group_vars, basic auth), and `deploy-dev/qa/prod.yml` workflows
  (self-hosted runner, per-environment secrets, required-reviewer gates on
  qa/prod). `docs/github-setup.md` admin checklist.

- **Active/passive production topology.** Restructured `prod` inventory group
  into `prod_active` and `prod_passive` child groups following the Red Hat COP
  pattern. Config is pushed to both sides simultaneously; the `aap_site_role`
  variable (from `AAP_SITE_ROLE` env var) controls whether schedules,
  notifications, and webhooks are enabled. Failover is an env-var change. Added
  `docs/references.md` with COP resource links. Updated `deploy-prod.yml` to
  run two parallel jobs (one per side, each with its own GitHub Environment).
- **Evolve-kit skill and runbook.** New `/evolve-kit` Claude Code skill and
  `docs/runbooks/06-evolve-kit.md` documenting the full design-change workflow:
  research COP recommendations → plan → implement → cross-reference updates →
  lint → commit → push → PR → merge. Added matching AI prompts (rb06) and
  Copilot instructions so both assistants follow the same cycle.

### Notes / decisions

- **ansible-core pin (Risk 4 — CLOSED, measured).** Initial testing targets
  **AAP 2.6**, whose `ee-supported-rhel9` image ships **ansible-core 2.16.17**
  (measured 2026-07-18). All pinned collections require only `>=2.16.0`, so the
  dev container and deploy runners are pinned to the `>=2.16,<2.17` stream.
  **Cutover:** bump to `>=2.18,<2.19` (the AAP 2.7 EE baseline) when the on-prem
  environments move to 2.7.
- **Collection versions verified** against console.redhat.com validated content on
  2026-07-18: `infra.aap_configuration` latest 4.7.0, `infra.aap_configuration_extended`
  latest 4.9.1. These track the newest content and support AAP 2.5+, so they work
  against the 2.6 test gateway. (Known-good 2.6-EE fallbacks if a 2.6-specific
  issue appears: `ansible.platform` 2.6.20251106, `ansible.controller` 4.7.9.)
