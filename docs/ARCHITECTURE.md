# Architecture

## The flow

```mermaid
flowchart TD
    A["Azure managed AAP 2.7<br/>(production)"] -->|"export.yml<br/>filetree_create (read)"| B["exports/<br/>raw objects, committed"]
    B -->|"curate by hand<br/>(runbook 03)"| C["inventory/group_vars/<br/>deployable config"]
    C -->|"git push → PR → merge"| D["GitHub repo (main)"]
    D -->|"push to main<br/>(auto)"| E["deploy-dev.yml"]
    D -->|"workflow_dispatch<br/>+ approval"| F["deploy-qa.yml"]
    D -->|"workflow_dispatch<br/>+ approval"| G["deploy-prod.yml"]
    E -->|"config.yml (dispatch)"| H["AAP 2.7 dev<br/>(standalone)"]
    F -->|"config.yml (dispatch)"| I["AAP 2.7 qa<br/>(standalone)"]
    G -->|"config.yml (dispatch)"| J["AAP 2.7 prod<br/>(active/passive)"]
```

## Two ways in, one way out

- **Export (Priority 1)** runs from the trainee's laptop dev container against the
  Azure production instance. It only reads. Output lands in `exports/` for review;
  Git operations are done by the trainee, not the playbook.
- **Load (Priority 2)** runs from **self-hosted GitHub Actions runners** that sit
  on-prem with network reach to the dev/qa/prod gateways. The runner applies the
  curated `inventory/group_vars/` config with `config.yml`.

## Why the pieces are where they are

| Choice | Reason |
|--------|--------|
| Objects in `inventory/group_vars/`, loaded implicitly | Red Hat Services standard; no `vars_files`/`include_vars` |
| One inventory, `--limit <env>` | Shared objects (`group_vars/aap/`) merge with per-env deltas |
| Self-hosted runners | GitHub's hosted runners can't reach on-prem AAP gateways |
| Per-environment GitHub Environments | Isolate dev/qa/prod secrets; add required reviewers to qa/prod |
| Basic auth for config/validate, token for export | Dispatch supports basic auth (nothing to clean up); `filetree_create` needs an OAuth token |
| Plain `ansible-playbook`, not ansible-navigator | Avoids EE-in-container on Windows Docker/Podman — the biggest support burden |

## What's deliberately not here

- No project-local `ansible.cfg` (would shadow the user's real one).
- No `galaxy.yml` (this is a project, not a collection — versions live only in
  `collections/requirements.yml`).
- No Automation Hub / EDA objects yet (scope is controller + gateway).
- No 2.4→2.5 conversion (source and target are both AAP 2.7).
