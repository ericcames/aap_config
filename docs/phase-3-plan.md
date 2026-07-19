# Phase 3 — Advanced (design, not yet built)

> **Status: parked.** Phases 0–2 are done. This document captures the Phase 3
> design so we can pick it up later without re-deriving it. Nothing here is
> implemented yet.

Phase 3 adds the "operate it over time" capabilities: drift detection, an
optional execution-environment CI path, the last two runbooks, and extraction of
the standards into a shareable team plugin.

## 3a. Drift detection (`object_diff`)

**Goal:** detect when someone changes an object in a live AAP environment by hand,
diverging from what's in Git — and surface it (report; optionally prune).

**Role:** `infra.aap_configuration_extended.object_diff`. It compares the live API
state against the Git-defined object lists (via the `controller_object_diff`
lookup) and can list — or delete — objects that exist in AAP but not in code.

- Scope note: `object_diff` is **controller-focused** today (its variables are
  `controller_*` / `aap_*`). **Verify gateway-object drift coverage** before
  relying on it for gateway objects; if unsupported, drift detection is
  controller-only in v1 of this feature.
- Safety: default to **report-only** (never auto-delete). Deletion/pruning is an
  explicit, separately-gated action. Respect `protect_not_empty_orgs: true`.

**New file:** `playbooks/drift.yml` — same auth/inventory model as `config.yml`
(basic auth, `--limit <env>`, vars from `inventory/group_vars/`), calling
`object_diff` in report mode.

**New workflow:** `.github/workflows/drift-detect.yml`

```yaml
on:
  schedule:
    - cron: "0 13 * * 1-5"   # weekday mornings
  workflow_dispatch: {}
jobs:
  drift:
    runs-on: [self-hosted, linux, aap]
    strategy:
      matrix:
        env: [dev, qa, prod]
    environment: ${{ matrix.env }}
    steps:
      # checkout, install ansible-core + collections, write vault password
      # run playbooks/drift.yml -i inventory --limit ${{ matrix.env }} (report mode)
      # if drift found -> `gh issue create` with the diff as the body
```

**Open questions:**
- Report format: issue body vs. job summary vs. both. Start with `gh issue create`
  labeled `drift`.
- De-dupe: don't open a new issue every run — update an existing open `drift`
  issue per environment (search by title `Drift: <env>`).

## 3b. Execution-environment CI path (option)

Today the deploy/lint jobs use a plain `pip install ansible-core` venv on the
runner. Phase 3 offers an EE-based alternative for teams that want CI to run in the
same container image as AAP:

```yaml
jobs:
  deploy:
    runs-on: [self-hosted, linux, aap]
    container:
      image: registry.redhat.io/ansible-automation-platform-26/ee-supported-rhel9:latest
      credentials:
        username: ${{ secrets.REGISTRY_USERNAME }}
        password: ${{ secrets.REGISTRY_PASSWORD }}
```

**Tradeoffs to document:** every runner needs registry pull secrets; image is
~2.6 GB; but CI then matches the AAP runtime exactly. Keep the pip-venv path as the
default; EE path is opt-in. (At 2.7 cutover, swap the image tag to the 2.7 EE.)

## 3c. Runbook 09 — drift detection

Teach: what drift is, reading a drift issue, deciding "fix in code" vs "the manual
change was intentional, add it to code." Introduces **scheduled workflows** and the
idea that Git is the source of truth. AI Assist prompts already stubbed in
`docs/ai/PROMPTS.md` (rb06 covers status checks/environments; add an rb09 anchor).

## 3d. Runbook 10 — graduation: export as a scheduled AAP job template

The full-circle exercise. The trainee takes `playbooks/export.yml` (which already
uses the `CONTROLLER_*` env-var names that AAP credential injection provides) and
runs it **inside AAP** as a scheduled job template:

- Introduces **execution environments** for the first time (the export needs
  `infra.aap_configuration_extended` in an EE — either a custom EE built with
  `ansible-builder`, or the supported EE plus a runtime collection install).
- Introduces **AAP credentials** injecting `CONTROLLER_*`, and a **project** that
  syncs this Git repo.
- The token lifecycle the playbook already implements (mint read token → delete in
  `always:`) now runs unattended — a natural teaching capstone.
- Contrast with v1: this is the "graduation" version of the in-AAP export we
  deliberately did NOT start with (the laptop CLI taught the Git skills first).

**Open question:** custom EE vs. supported EE + runtime install. Eric has EE-build
patterns in `aap.dailydemo.F5` / `Execution-Environments` / `image.builder.pipeline`
to reuse. Decide at build time.

## 3e. Team plugin extraction

Extract the reusable standards assets so the whole team can demo/enforce them
across repos (dc1.azure, AMZL-dailydemo, …), the way `aap-skills` already packages
demo skills:

- The `.claude/skills/` (export-aap, curate-config, vault-secrets) → a shared
  plugin.
- The `AGENTS.md` "Ansible standards" section → a reusable rules doc other repos
  reference or vendor.
- Goal: one canonical statement of the Red Hat Services CaC standards that every
  repo and every AI assistant (Copilot + Claude) inherits.

**Open question:** plugin packaging mechanics — mirror how `aap-skills` is
structured and distributed. Coordinate with the team so the plugin name/namespace
is agreed before publishing.

## Phase 3 verification (when built)

- Hand-edit an object in the dev AAP UI → the scheduled `drift-detect` workflow
  opens/updates a `Drift: dev` issue with the diff.
- Run `export.yml` as a scheduled AAP job template against a test instance; confirm
  it commits/pushes (or writes to a project artifact) and cleans up its token.
- Fresh clone of another repo consuming the extracted plugin gets the same skills
  and standards.
