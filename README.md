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
```

## Start here

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
- **Secrets in two gitignored places only:** `docs/dev-environment.sh` for
  connection secrets, vault-encrypted `inventory/group_vars/<env>/secrets.yml` for
  committed CaC secrets.
- **Newest collections, pinned once** in
  [`collections/requirements.yml`](collections/requirements.yml).
