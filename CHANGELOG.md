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

### Notes / to confirm

- **ansible-core pin (Risk 4):** pinned to the `>=2.18,<2.19` stream to match the
  AAP 2.7 EE baseline. Confirm the exact minor against the 2.7 ee-supported image
  (`podman run --rm registry.redhat.io/ansible-automation-platform-27/ee-supported-rhel9 ansible --version`)
  when registry credentials are available, and tighten if it differs.
- **Collection versions verified** against console.redhat.com validated content on
  2026-07-18: `infra.aap_configuration` latest 4.7.0, `infra.aap_configuration_extended`
  latest 4.9.1.
