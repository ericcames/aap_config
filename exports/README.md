# exports/ — raw export landing zone

`playbooks/export.yml` writes the output of `filetree_create` here, one
subdirectory per source (e.g. `exports/azure/`), organized by organization with
one YAML file per object.

## What is safe here

Exports run with `secrets_as_variables: true`, so secret fields (passwords,
tokens, keys) are written as `{{ vaulted_* }}` **placeholders**, not real values.
That is why this tree is safe to **commit** — it gives you review history of what
the production instance looked like at export time.

Two guards keep it honest, in the pre-commit hook and in CI:

- `utilities/scan-exports.sh` — fails if a secret-shaped field holds anything
  other than a `{{ vaulted_* }}` placeholder.
- `*_settings` exports are **gitignored** — settings objects can embed SSO/client
  secrets that are not templated out. Review those in `exports/` locally and
  curate the values by hand (runbook 03); they never reach Git.

## What happens next

The raw export is **not** what gets deployed. You **curate** the objects you want
into `inventory/group_vars/` (runbook 03), renaming their top-level variables to
the `*_all` / `*_<env>` suffix convention. That curated content is what
`playbooks/config.yml` applies to dev/qa/prod.
