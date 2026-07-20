# Changelog

All notable changes to this project are documented here. Format based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- **Phase 0 scaffold.** New greenfield config-as-code starter kit for AAP 2.7.
  - `AGENTS.md` canonical AI/standards guidance, with thin `CLAUDE.md` and
    `.github/copilot-instructions.md` shims.
  - Dev container (`.devcontainer/`): UBI9 + Python 3.12, ansible-core 2.16
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

- **`DEMO.md` — a 10-minute demo fast path** for technical audiences. Runs the
  loop as four acts (export → curate → review → apply) with the payoff being the
  object appearing in AAP, rather than walking through runbooks 00–07. Includes a
  pre-flight checklist (the demo degrades cleanly to Acts 2–3 when no AAP is
  reachable), a deliberate secret-commit that the pre-commit hook rejects, and
  answers to the questions the room actually asks. Linked from `README.md` →
  Start here.
- **`qa` environment config.** `inventory/group_vars/qa/connection.yml` (gateway
  URL) and a vault-encrypted `qa/secrets.yml`, so `qa` is a working apply target
  for `validate.yml`/`config.yml` — matching what `azure/` already commits.
- **Vault password files as an alternative to `@prompt`.**
  `docs/runbooks/04-secrets.md` documents `~/secrets/.vault_pass_<env>` (mode
  600, outside the repo) for unattended and demo runs. `@prompt` remains the
  taught default.
- **`exports/README.md` — re-export procedure.** `filetree_create` only writes,
  so a re-export must be preceded by `rm -rf exports/<source>/` for upstream
  deletions to appear in the diff.

### Changed

- **`DEMO.md` retargeted to a real environment.** Act 4 applies to `qa` instead
  of `dev`; all runnable commands use `--vault-id <env>@~/secrets/.vault_pass_<env>`
  so a demo never stalls on a mistyped password. Claude Code is now the assumed
  assistant rather than a mid-setup choice, and a new "Where you run it" section
  recommends the local dev container over Codespaces (which keeps its role as the
  audience's on-ramp and as a cold backup). The Act 3 secret-guard demo stays on
  `dev` deliberately — now that `qa/secrets.yml` is real, `dev/` is the only env
  where the throwaway `>` cannot destroy anything. Adds a `hunter2` footnote and
  a screenshot capture list.
- **Per-environment sign-in badge — the repo's first `_<env>` variable.**
  `inventory/group_vars/qa/gateway_settings.yml` sets `gateway_settings_qa.custom_logo`
  to the official AAP lockup extended with a color-coded environment badge,
  generated reproducibly by `utilities/make-env-logo.py` (amber qa, green dev,
  red prod) from the committed `docs/images/aap-logo-white.svg`. It **merges**
  with `gateway_settings_all` rather than replacing it, making the `_all` /
  `_<env>` convention demonstrable instead of merely asserted. Verified
  idempotent on qa.
  **Scope, precisely:** `custom_logo` renders on the **sign-in page only**. It
  does not change the post-login masthead, which is a bundled UI asset rather
  than a setting — confirmed on qa with the setting stored and the masthead still
  stock. AAP 2.7 exposes **no** way to mark the environment after login; all 43
  gateway settings were enumerated. Recorded so nobody re-researches it.
- **Pre-login banner as code.** `inventory/group_vars/aap/gateway_settings.yml`
  manages `custom_login_info` for every environment — the AAP sign-in banner,
  and the most visible object in the repo: proving an apply landed needs a
  logout, not navigation. Verified idempotent on qa (two consecutive applies
  report the analytics change only).
- **Automation Analytics as code, for every environment.**
  `inventory/group_vars/aap/controller_settings.yml` sets
  `INSIGHTS_TRACKING_STATE`, `AUTOMATION_ANALYTICS_URL`, the gather interval, and
  the service-account credentials, which resolve from each environment's vault as
  `vaulted_subscriptions_client_id` / `_client_secret`. Both variables are now
  **required** entries in all four `secrets.yml.example` templates, because
  `group_vars/aap/` loads for every environment. Verified on qa: the Automation
  Calculator returns real job-template and savings data.
  **Known and expected:** this file makes every apply report `changed=1`. AAP
  returns `SUBSCRIPTIONS_CLIENT_SECRET` as `$encrypted$`, so the role cannot
  compare desired against actual and rewrites it each run. Proven by removing
  that single line — two consecutive runs then report `changed=0`. Documented in
  the file header and in DEMO.md's Act 4.
- **First curated object: `aap_organizations_all`.**
  `inventory/group_vars/aap/aap_organizations.yml` manages the
  `IT Service Automation` organization as code, curated from
  `exports/azure/gateway_organizations.yaml`. Note the rename: the export writes
  `gateway_organizations:`, but the dispatch role reads `aap_organizations`, so
  copy-plus-suffix would produce a file that loads and does nothing.
  The organization is committed rather than curated live because
  `validate.yml` runs in check mode, which cannot create it — and a project
  referencing a missing organization fails the dry run.
- **`DEMO.md` — Act 2 decided and rehearsed.** Documents the object to curate
  (`AMZL Daily Demo` project, the only exported project not already present on
  the target), the target-preparation steps, the check-mode dependency
  limitation, and two optional extras: the pre-login banner
  (`gateway_settings_all.custom_login_info`, visible on the sign-in page) and
  Automation Analytics, whose credentials cannot come from the export because
  AAP returns them as `$encrypted$` — the strongest case in the kit for the
  vaulted-secrets model.
- **`DEMO.md` troubleshooting.** Every playbook run now tees to `/tmp/demo-*.log`
  with `ANSIBLE_FORCE_COLOR=1` set in the pre-flight so color survives the pipe,
  plus an "If something breaks mid-demo" section covering how to grep the logs
  and the three failures worth recognizing on sight. Fixes the pre-flight's
  `ls -l ~/secrets/`, which listed nothing because the vault password files are
  dotfiles — it now uses `ls -la`, so a missing file is actually caught.

- **Cross-tool agent skills, and three new ones.** The repo's skills use the open
  `SKILL.md` format and already worked in **both** Claude Code and GitHub Copilot
  CLI (which reads project skills from `.claude/skills/`) — but nothing said so,
  and `.github/copilot-instructions.md` pointed Copilot users only at copy-paste
  prompts. Added `AGENTS.md` → **Repo-shipped skills**: the seven-skill table, the
  cross-tool mechanism, the skills-vs-prompts division of labor (prompts explain,
  skills do), and the frontmatter contract for adding one. `CLAUDE.md` and the
  Copilot shim now point there instead of carrying their own lists; `README.md`
  gains a Skill column; `docs/ai/PROMPTS.md` and each runbook gain skill pointers.
  New skills: **`/apply-config`** (dry-run `validate.yml` in check mode, then
  apply `config.yml` — the deploy path had no skill), **`/branch-pr`** (runbook
  05), and **`/setup-workstation`** (runbooks 00–01). New `skills-frontmatter` CI
  job: `yamllint` cannot see Markdown frontmatter, so a non-portable key — the one
  failure mode that silently breaks loading in a tool — previously shipped
  unnoticed. Skills stay in `.claude/skills/`; decision and the deferred
  `.agents/skills` option recorded in `ROADMAP.md`.

- **BeyondTrust secrets-management design** (`docs/secrets-beyondtrust.md`).
  Documented pattern for environments that manage secrets in BeyondTrust Password
  Safe: at deploy time each env's `secrets.yml` shrinks to the vault-encrypted
  OAuth bootstrap and `vaulted_*` values become lazy `secrets_safe_lookup` calls
  in a committed `secrets_lookup.yml`; at job runtime a custom credential type
  injects those credentials as environment variables. Explains why AAP's
  `credential_input_sources` path is unavailable (AAP 2.6/2.7 ships no BeyondTrust
  credential plugin). Adds `beyondtrust.yml.example` and
  `secrets_lookup.yml.example` for dev/qa/prod. **Design and inert templates
  only** — the `beyondtrust.secrets_safe` collection is deliberately not pinned
  until it can be verified against a live Password Safe. ansible-vault remains the
  default and environments can mix. Decision recorded in `ROADMAP.md`.

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

### Fixed

- **Dev container image would not build.** `devcontainer.json` requested the
  `ghcr.io/devcontainers/features/github-cli` feature, whose install script is
  apt-only and fails on this UBI9 base (`apt-get: command not found`, exit 127).
  Dropped the feature and installed `gh` from the official pinned release tarball
  (`ARG GH_VERSION`, arch-detected) in the `Containerfile` instead. Separately,
  the `node` feature failed with `usermod: user '1001' does not exist` because
  `USER 1001` gave it a numeric id where it needs a name — switched to
  `USER default`, UBI9's uid-1001 application user. Affected every clean build
  (Docker Desktop, Podman, devcontainer CLI, Codespaces), not just Codespaces.
- **Certified collections could not install.** `post-create.sh` configured a
  single Automation Hub server on the *validated* endpoint plus community
  Galaxy, but `ansible.platform` and `ansible.controller` are *certified*
  content (`content/published/`) and are not on public Galaxy — so neither
  server could supply them. Now writes three servers (`rh_certified`,
  `rh_validated`, `community`) with the same token on both hub entries, adds
  `AH_CERTIFIED_URL` / `AH_VALIDATED_URL` overrides for private hubs, and keeps
  honouring `AH_URL` as an alias for the validated endpoint.
- **Docs claimed the wrong ansible-core version.** Runbook 01's verification step
  said `2.18.x` and the Phase 0 entry above said "2.18 stream", but the container
  pins `>=2.16,<2.17` and builds `ansible-core 2.16.19` — a user following the
  runbook would think a working container was broken. Both corrected to match the
  `Containerfile` and the accurate Notes entry below. Runbook 01 also no longer
  presents the Automation Hub token prompt as unconditional; it only appears when
  `AH_TOKEN` is unset.

### Notes / decisions

- **`gh codespace ssh` does not work with this kit, by design of the base image.**
  UBI9 ships no SSH server and the `sshd` dev container feature is apt-only, so it
  cannot be added. The VS Code terminal is unaffected (it does not use SSH).
  Documented in `docs/codespaces.md`, including the useful inverse: if
  `gh codespace ssh` *succeeds* and drops you on Debian/Alpine, the dev container
  failed to build and you are in a recovery container.

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
