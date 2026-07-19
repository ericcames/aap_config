# AGENTS.md — aap_config

Canonical guidance for **any** AI assistant working in this repo — GitHub
Copilot (CLI/Chat) for trainees, Claude Code for maintainers, and any future
tool that reads the open [agents.md](https://agents.md) standard. `CLAUDE.md` and
`.github/copilot-instructions.md` are thin shims that point here; **this file is
the single source of truth.** When conventions change, update this file in the
same PR (CI greps that every top-level directory is mentioned here).

## What this repo is

A **configuration-as-code starter kit** that teaches sysadmins to:

1. **Export** controller + gateway objects from a production **Azure managed
   AAP 2.7** into this GitHub repo (Priority 1), then
2. **Load** them into on-prem **AAP 2.7 containerized** — dev → qa → prod — via
   **GitHub Actions** (Priority 2).

Source and targets are all **gateway-era (AAP 2.5+)** — initial testing runs
against **AAP 2.6**, production is **AAP 2.7** — so no 2.4→2.5 format conversion is
involved and the object model is identical across them. The toolchain is pinned to
ansible-core 2.16 (the AAP 2.6 EE baseline) for now; it bumps to 2.18 at the 2.7
cutover. Audience: sysadmins with little Git/software-dev experience, on Windows
desktops using a **VS Code Dev Container**. Every runbook step embeds an AI-assist
prompt.

## Directory map

| Path | What lives here |
|------|-----------------|
| `.devcontainer/` | Container definition + `post-create.sh` (tools, collections, galaxy auth, git hooks) |
| `.github/` | CI workflows, issue/PR templates, CODEOWNERS, SECURITY, this file's Copilot shim |
| `collections/` | `requirements.yml` — the ONLY place collection versions are pinned |
| `inventory/` | ONE inventory: `hosts.yml` + `group_vars/` (see standards below) |
| `exports/` | Raw `filetree_create` output, committed for review; `*_settings*` gitignored |
| `playbooks/` | `export.yml`, `config.yml`, `validate.yml` |
| `utilities/` | Secret-hygiene helper scripts run locally + in CI |
| `docs/` | `runbooks/` teaching path, `ai/PROMPTS.md`, architecture, github-setup, `references.md` (COP links), images |
| `.claude/` | Repo-shipped Claude Code skills mirroring the runbooks |

## Ansible standards — rules an AI MUST follow here

These are non-negotiable. Do not generate code that violates them, and flag it if
you see it.

1. **Variables load implicitly from inventory `group_vars` — never
   `vars_files:` or `include_vars:` from a `files/` (or `config/`) folder.**
   `group_vars/` lives **under the inventory directory** (`inventory/group_vars/`).
   This is the Red Hat Services standard for CaC repos; the v1 kit and some
   sibling repos use the `include_vars: dir:` / `vars_files:` anti-pattern —
   **do not copy it forward.**
2. **Environment selection is by inventory group + `--limit`**, not by loading a
   per-env vars directory. `group_vars/aap/` holds objects shared by every
   environment; `group_vars/<env>/` holds that env's deltas + encrypted secrets.
   Shared and per-env lists merge via `dispatch_include_wildcard_vars: true` and
   the `*_all` / `*_<env>` variable-suffix convention (e.g. `controller_projects_all`
   + `controller_projects_dev`). Production uses `--limit prod_active` /
   `--limit prod_passive`; the `aap_site_role` variable (from `AAP_SITE_ROLE`
   env var) controls whether schedules and notifications are enabled
   ([COP pattern](https://www.redhat.com/en/blog/automation-controller-active-passive-architecture-cac)).
3. **No project-local `ansible.cfg`.** It would shadow the user's `~/.ansible.cfg`
   (which holds their Automation Hub token). The dev container writes an
   `~/.ansible.cfg` **inside the container home** at post-create; set inventory
   and options via `-i` / env vars / CLI flags instead.
4. **`ansible.platform` over `ansible.controller`** wherever a module exists.
   Authenticate with `ansible.platform.token`; **always delete the token in an
   `always:` block** so stale tokens never accumulate.
5. **Playbooks target the inventory group, not `hosts: localhost`.** Each env's
   host is an inventory entry with `ansible_connection: local` — it is just the
   anchor that makes `group_vars` load; the work is local API calls.
6. **Secrets live in exactly two gitignored places:** connection secrets in
   `docs/dev-environment.sh` (sourced into the shell; template is the committed
   `.example`), and committed CaC secrets in `inventory/group_vars/<env>/secrets.yml`
   **ansible-vault encrypted**. Never write a secret value anywhere else.
7. **Never commit** customer/company names, RHDP URLs, cluster/instance IDs,
   tokens, passwords, or keys. Exported credential fields are templated to
   `{{ vaulted_* }}` placeholders by `secrets_as_variables: true` — keep them that
   way. Audit every diff before committing.

## How to run things

```bash
# One-time per shell: load connection secrets.
cp docs/dev-environment.sh.example docs/dev-environment.sh   # then fill it in
source docs/dev-environment.sh

# Export from the Azure production AAP into exports/azure-prod/.
ansible-playbook playbooks/export.yml -i inventory --limit azure

# Apply config to an on-prem env (dev/qa/prod). --limit picks the env's group_vars.
ansible-playbook playbooks/config.yml   -i inventory --limit dev --vault-id dev@prompt
ansible-playbook playbooks/validate.yml -i inventory --limit dev --vault-id dev@prompt  # check mode

# Production active/passive (COP-recommended pattern).
# Both sides get the same config; AAP_SITE_ROLE controls schedules/notifications.
AAP_SITE_ROLE=active  ansible-playbook playbooks/config.yml -i inventory --limit prod_active  --vault-id prod@prompt
AAP_SITE_ROLE=passive ansible-playbook playbooks/config.yml -i inventory --limit prod_passive --vault-id prod@prompt

# Lint exactly as CI does.
yamllint .
ansible-lint
```

## Collections

Pinned once in `collections/requirements.yml` (currently `infra.aap_configuration`
4.7.0, `infra.aap_configuration_extended` 4.9.1, `ansible.platform` 2.7.20260604,
`ansible.controller` 4.8.0). Bump procedure: edit the pin → rebuild the dev
container → run `validate.yml` against dev → open a PR. Never pin versions
anywhere else.

## Contributing hygiene

One concern per PR (would you revert these changes together?). Additive only.
Update `CHANGELOG.md` under `[Unreleased]` and `ROADMAP.md` phase status. Run
`yamllint .` and `ansible-lint` before pushing — both gate every PR. For design
changes (new conventions, architecture decisions), follow the full evolve-kit
cycle in [`docs/runbooks/06-evolve-kit.md`](docs/runbooks/06-evolve-kit.md):
research → plan → implement → cross-reference updates → lint → commit → PR →
merge.
