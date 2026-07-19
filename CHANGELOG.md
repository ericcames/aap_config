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
  variable (in each side's `connection.yml`) controls whether schedules,
  notifications, and webhooks are enabled. Added `docs/references.md` with COP
  resource links. Updated `deploy-prod.yml` to run two parallel jobs (one per
  side, each with its own GitHub Environment).
- **Evolve-kit skill and runbook.** New `/evolve-kit` Claude Code skill and
  `docs/runbooks/06-evolve-kit.md` documenting the full design-change workflow:
  research COP recommendations → plan → implement → cross-reference updates →
  lint → commit → push → PR → merge. Added matching AI prompts (rb06) and
  Copilot instructions so both assistants follow the same cycle.
- **Windows workstation readiness.** Added preflight checks to `export.yml`
  (CRLF line-ending detection, collection-installed assertion) and a Windows
  workstation checklist to the export runbook. Added `devcontainer` CLI as a
  VS-Code-free alternative in the prerequisites runbook.
- **Azure managed AAP export.** Raw `filetree_create` snapshot of the Azure
  managed AAP 2.7 instance — controller and gateway objects across all orgs.
  Settings files excluded by `.gitignore`; `scan-exports.sh` confirms no
  leaked secrets.
- **Unified secrets under ansible-vault.** Consolidated the two-pattern secrets
  approach (env vars for connection + vault for CaC) into a single model: all
  secrets live in vault-encrypted `inventory/group_vars/<env>/secrets.yml`,
  following the COP `aap_configuration_template` pattern. Non-secret connection
  settings (hostname, cert validation, site role) live in committed
  `connection.yml` files. Each env has `.example` templates. CI now needs only
  one secret per environment (`VAULT_PASSWORD`). Deleted `docs/dev-environment.sh`
  (AH_TOKEN handled by dev container). Moved `aap_site_role` from env-var lookup
  to plain values in per-side `connection.yml`.
- **GitHub Codespaces entry path.** New `docs/codespaces.md` and an "Open in
  Codespaces" badge in the README, so a user can launch the same `.devcontainer`
  in the cloud with no local container engine, WSL, or admin rights. Documents
  setting `AH_TOKEN` (and optional `AH_URL`) as Codespaces secrets — names only,
  never values — plus prebuilds and when to prefer Codespaces over local.
- **"Where the subscription fits" README section.** Makes explicit what
  `AH_TOKEN` actually buys: which pinned collections are Red Hat certified
  versus validated versus community, and why the supported content — not the
  YAML in this repo — is the thing an AAP subscription pays for.
- **Windows dev-container preflight (runbook 00).** A go/no-go section placed
  before the container-engine setup: PowerShell checks for Windows build, WSL
  presence/version, virtualization, the required optional features, and a WSL
  group-policy block, plus how to read the result (enable WSL2 and work inside
  the WSL2 filesystem, or fall back to Codespaces / a shared Linux dev host).
  Includes a capturable PASS/FAIL summary block so a blocked desktop becomes a
  documented record rather than a verbal one.
- **"Running on Fedora with Podman" (runbook 00).** Host setup for Fedora
  workstations as a sibling to the Windows guidance: Podman CLI plus
  `dev.containers.dockerPath`, exporting `AH_TOKEN` before launching VS Code,
  SELinux bind-mount behaviour, and the rootless-Podman file-ownership caveat
  (the container runs as `USER 1001`). The `--userns=keep-id` workaround is
  documented as local, uncommitted guidance only — it errors under Docker, so it
  must not go into the shared `devcontainer.json`.
- **`docs/duplicating-into-enterprise-github.md`.** How to copy this kit into
  GitHub Enterprise Cloud or Enterprise Server: a clean-slate copy (recommended,
  single fresh commit) versus a full-history mirror, plus the repo settings a
  git copy does not bring — Actions secrets, environments and their approval
  rules, self-hosted runners for on-prem AAP reach, and branch protection.
  Linked from the README.
- **`docs/going-to-production.md`.** Scope-level outline of what an enterprise
  rollout involves beyond the runbooks — enterprise GitHub landing and
  governance, CI/CD runners, secrets and vault governance, environments and
  approvals, `prod-active`/`prod-passive` HA, and scale/adoption — and how to
  engage Red Hat Consulting or a TAM for that work. Deliberately describes
  what's involved rather than how to implement it. Linked from the README.
- **`docs/tam-adoption-plan.md`.** One-page fill-in template for the moment a
  team scales onto config-as-code: baseline, adoption goals, onboarding cohorts,
  best-practice checkpoints (standards, secrets, promotion gates, drift,
  collection currency), escalation paths, and success measures. Linked from the
  "Scale and adoption" workstream in `going-to-production.md`.

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
