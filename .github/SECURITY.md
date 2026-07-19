# Security Policy

## Scope

This repository is a **configuration-as-code starter kit** for Ansible Automation
Platform 2.7. It exports controller + gateway objects from a production AAP into
Git and loads them into on-prem dev/qa/prod environments via GitHub Actions. It
contains **patterns, playbooks, inventory, CaC object definitions, and docs
only** — no live credentials, tokens, or environment-specific values.

## What should never be committed

- AAP tokens, passwords, OAuth tokens, or vault passwords
- Customer or company names, RHDP deployment URLs, cluster/instance IDs, or other
  identifying details — committed files use generic placeholders
- Exported credential secrets: `filetree_create` runs with
  `secrets_as_variables: true`, so secret fields export as `{{ vaulted_* }}`
  placeholders. Keep them that way — never fill a real value into an exported file.
- `*_settings` exports (they can embed SSO/client secrets) — these are gitignored
  and curated by hand.

Secrets live only in two gitignored places: connection secrets in
`docs/dev-environment.sh` (template: `docs/dev-environment.sh.example`), and
committed CaC secrets in ansible-vault-encrypted
`inventory/group_vars/<env>/secrets.yml`. The `utilities/check-vault-encrypted.sh`
and `utilities/scan-exports.sh` guards run in a pre-commit hook and in CI.

If a secret is committed by mistake, **rotate the affected credential immediately**
and open an issue so it can be removed from history.

## Supported versions

Only the latest commit on `main` is maintained.

## Reporting a vulnerability

Open a GitHub issue for general security concerns. If you believe disclosure would
cause active harm, contact the maintainer directly.
