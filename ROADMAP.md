# Roadmap — aap_config

The kit ships in phases. Priority 1 is the export path (Azure → GitHub);
Priority 2 is the load path (GitHub → on-prem dev/qa/prod via Actions).

**Testing note:** initial testing is against **AAP 2.6** (ee-supported baseline
ansible-core 2.16.17), so the toolchain is pinned to the 2.16 stream for now. AAP
2.6 and 2.7 are both gateway-era (2.5+), so the export/import model is identical —
no format conversion. At the 2.7 cutover, bump ansible-core to the 2.18 stream (dev
container + deploy workflows) and re-verify.

## Phase 0 — Scaffold ✅

Repo skeleton, community-standards files, dev container, lint configs, pinned
`collections/requirements.yml`, inventory skeleton, `AGENTS.md`/`CLAUDE.md`/Copilot
shims, secret-hygiene utilities, README/CHANGELOG/ROADMAP.

## Phase 1 — MVP export path (Priority 1) 🔄

- `playbooks/export.yml` (filetree_create, controller+gateway) ✅
- `utilities/` secret guards + skeleton generator ✅
- `.github/workflows/lint.yml` PR gate ✅
- Runbooks 00–05 (prereqs → dev container → export → curate → secrets → PR)
- `.claude/skills/` for export / curate / vault
- **Verify:** run against an RHDP AAP instance, then the real Azure 2.7 instance;
  `scan-exports.sh` clean; dry-run the runbooks as a trainee.

## Phase 2 — Load via GitHub Actions (Priority 2) 🔄

- `playbooks/config.yml` + `validate.yml` ✅
- `deploy-dev.yml` / `deploy-qa.yml` / `deploy-prod.yml` ✅
- `docs/github-setup.md` admin checklist ✅
- Self-hosted runner setup doc
- Runbooks 06–08 (CI lint → deploy dev → promote qa/prod)
- **Verify:** containerized AAP 2.7 dev + runner; merge a PR adding one job
  template → appears in dev; approve → appears in qa.

## Phase 3 — Advanced ⬜ (parked — design captured)

Full design in **[`docs/phase-3-plan.md`](docs/phase-3-plan.md)**. Summary:

- `object_diff` drift-detection workflow (scheduled; opens/updates an issue on drift)
- Execution-environment-based CI jobs (option)
- Runbook 09 (drift) + runbook 10 (graduation: export as a scheduled AAP job
  template, EE intro)
- **Team plugin:** extract `.claude/skills/` + the `AGENTS.md` standards into a
  shareable plugin (like `aap-skills`) so the whole team can demo/enforce the
  same standards across the team's other demo repos.
- **BeyondTrust secrets pattern:** implement the design in
  [`docs/secrets-beyondtrust.md`](docs/secrets-beyondtrust.md) once a Password
  Safe instance is available to test against — pin `beyondtrust.secrets_safe`,
  confirm the lookup's option names and return shape, verify the credential-type
  injector rendering, and extend the `/vault-secrets` skill.

## Decisions log

- **Export = laptop CLI, not an in-AAP job template.** Teaches the Git skills the
  rest of the kit needs; avoids setup in the platform being retired. (A scheduled
  job-template export is the Phase 3 graduation exercise.)
- **Objects load from `inventory/group_vars/`, not `vars_files`.** Red Hat
  Services standard; the kit exists partly to demonstrate it.
- **config/validate use basic auth; only export mints a token.** `filetree_create`
  needs an OAuth token; dispatch supports basic auth directly, so the import path
  creates nothing to leak or clean up.
- **No 2.4→2.5 conversion.** Source and targets are all gateway-era (2.5+): initial
  testing on AAP 2.6, production on AAP 2.7. Same object model, no format transform.
- **Active/passive prod via `aap_site_role` in `connection.yml`.** The Red Hat
  COP recommends pushing identical config to both sides simultaneously; a single
  variable controls schedules/notifications/webhooks. Each side's committed
  `connection.yml` sets `aap_site_role: active` or `passive`. Two parallel CI
  jobs in `deploy-prod.yml`, two GitHub Environments (`prod_active`,
  `prod_passive`). See `docs/references.md`.
- **Unified secrets under ansible-vault.** All secrets — connection credentials
  AND CaC object values — live in vault-encrypted `group_vars/<env>/secrets.yml`,
  following the COP `aap_configuration_template` pattern. One vault password per
  env unlocks everything. CI needs only `VAULT_PASSWORD` per GitHub Environment.
  Eliminated `docs/dev-environment.sh` and env-var lookups in `aap_settings.yml`.
- **BeyondTrust is a documented alternative, not a replacement; ansible-vault
  stays the default.** AAP 2.6/2.7 ships no BeyondTrust credential plugin, so the
  `credential_input_sources` path is unavailable — the pattern instead uses the
  certified `beyondtrust.secrets_safe` lookup at two layers: deploy time (each
  env's `secrets.yml` shrinks to the vault-encrypted BeyondTrust OAuth bootstrap;
  `vaulted_*` object values become lazy lookups in a committed
  `secrets_lookup.yml`) and job runtime (a custom credential type injecting those
  credentials as env vars). Vault remains the bootstrap layer, so CI still needs
  only `VAULT_PASSWORD` per environment. Environments can mix — dev/qa on vault,
  prod on Password Safe. Design in
  [`docs/secrets-beyondtrust.md`](docs/secrets-beyondtrust.md); implementation
  (including the collection pin) deferred until a live Password Safe exists.
