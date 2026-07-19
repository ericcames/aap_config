# aap_config — AAP Config-as-Code Starter Kit

A hands-on kit that teaches sysadmins to manage **Ansible Automation Platform
2.7** as code:

1. **Export** your controller + gateway objects from a production **Azure managed
   AAP** into this Git repo, then
2. **Load** them into on-prem **AAP 2.7 containerized** — dev → qa → prod — using
   **GitHub Actions**.

It is built for people with **little Git or software-development experience**,
working on **Windows desktops** in a **VS Code Dev Container**, with an **AI
assistant** (GitHub Copilot or Claude Code) helping at every step.

## The 5-minute picture

```
  Azure managed AAP 2.7 (production)
            │  export.yml  (filetree_create, read-only)
            ▼
        exports/            ← raw objects, committed for review
            │  you curate the ones you want
            ▼
   inventory/group_vars/    ← the config that gets deployed
            │  git push → Pull Request → merge
            ▼
      GitHub Actions
       ├── dev   (auto on merge)
       ├── qa    (manual + approval)
       └── prod  (manual + approval)   on-prem AAP 2.7 containerized
            ├── prod-active   (aap_site_role: active)
            └── prod-passive  (aap_site_role: passive)
```

## Start here

**No local install?** Launch the dev container in the cloud — no Docker/Podman,
no WSL, no admin rights:

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/ericcames/aap_config)

Set `AH_TOKEN` once as a Codespaces secret and every codespace comes up ready.
See [Running in GitHub Codespaces](docs/codespaces.md). Otherwise, set up locally
with runbooks 00–01 below.

Work through the numbered runbooks in [`docs/runbooks/`](docs/runbooks/):

| # | Runbook | You will learn |
|---|---------|----------------|
| 00 | Prerequisites | accounts, Docker/Podman Desktop, VS Code, Copilot seat check |
| 01 | Dev container | clone, "Reopen in Container" |
| 02 | Export | run `export.yml`, the working tree, `.gitignore` |
| 03 | Curate into group_vars | `git status`/`diff`/`add`/`commit` |
| 04 | Secrets & vault | why secrets never go in Git |
| 05 | Branch → PR → merge | branches, pull requests, review |
| 06 | Evolve the kit | research → plan → implement → PR for design changes |
| 07+ | CI, deploy, approvals, drift | GitHub Actions end-to-end |

Standing this kit up on a customer's or internal GitHub Enterprise instance? See
[Duplicating into enterprise GitHub](docs/duplicating-into-enterprise-github.md).

## For AI assistants and contributors

- **[`AGENTS.md`](AGENTS.md)** is the canonical guidance — the repo layout, the
  Ansible standards this kit demonstrates, and how to run everything. Copilot
  reads it automatically; `CLAUDE.md` and `.github/copilot-instructions.md` point
  to it.
- Ready-to-paste AI prompts for each runbook are in
  [`docs/ai/PROMPTS.md`](docs/ai/PROMPTS.md).
- Contributing: [`CONTRIBUTING.md`](CONTRIBUTING.md). Roadmap:
  [`ROADMAP.md`](ROADMAP.md).

## Key design choices

- **Objects load implicitly from `inventory/group_vars/`** — no
  `vars_files`/`include_vars`. Environment is chosen with `--limit`. This is the
  Red Hat Services standard the kit exists to demonstrate.
- **No project-local `ansible.cfg`** (it would shadow your real one). The dev
  container writes one in the container home.
- **All secrets vault-encrypted** in `inventory/group_vars/<env>/secrets.yml` —
  connection credentials AND CaC object secrets. One vault password per env
  unlocks everything (COP `aap_configuration_template` pattern).
- **Newest collections, pinned once** in
  [`collections/requirements.yml`](collections/requirements.yml).

## Where the subscription fits

Setting `AH_TOKEN` in runbook 00 is not a packaging detail — it is the moment
this kit reaches into your **Ansible Automation Platform subscription**. The
content it pulls is the subscription:

| What the kit installs | Source | What you get |
|---|---|---|
| `ansible.platform`, `ansible.controller` | Red Hat **certified** content (Automation Hub) | Built and supported by Red Hat, with a support lifecycle and a path to open a case |
| `infra.aap_configuration`, `infra.aap_configuration_extended` | Red Hat **validated** content (Automation Hub) | Red Hat–tested opinionated patterns — the config-as-code roles this kit is built on |
| Anything from galaxy.ansible.com | Community | No Red Hat support commitment; you own the risk |

The modules that create every object in `inventory/group_vars/` — job templates,
projects, credentials, gateway settings — come from the certified collections. A
community collection can do similar work, but when it breaks against a new AAP
release, there is no case to open and no committed fix. That difference, plus
support for the platform itself, is what an AAP subscription buys.

Without a token the dev container still builds, and the runbooks still read
correctly — you just cannot install the certified content, so nothing deploys.
That is the honest shape of the dependency, and it is worth understanding early
rather than at go-live.
