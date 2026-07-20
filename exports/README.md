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

## Naming: "AMZL" is Amazon Linux

Objects named `AMZL Daily Demo - *` and inventories named `amzl-dailydemo*` refer
to **Amazon Linux, the operating system**. They are demo-org content — an OS
lifecycle story (provision an EC2 instance, patch to release, harden, add a
devops user, deploy a Docker webserver, tear it down nightly).

Noted here because `AMZL` is also the common abbreviation for Amazon Logistics,
so a reviewer auditing this public repo for customer data will reasonably stop on
it. It is not a customer name. Real customer names must never appear in tracked
files — see [`CONTRIBUTING.md`](../CONTRIBUTING.md).

## Re-exporting: wipe first

`filetree_create` only **writes** files — it never removes them. An object
deleted upstream leaves a stale file here that survives every future export and
silently misrepresents the source. So when you re-export a source that has
changed, clear the tree first:

```bash
rm -rf exports/azure/
ansible-playbook playbooks/export.yml -i inventory --limit azure --vault-id azure@prompt
git status exports/          # deletions now show as deletions, and get reviewed
```

Object types with no instances come back as `key: []` files (e.g.
`gateway_teams.yaml`). Those are correct output, not leftovers — they record
that the type was exported and was empty. Leave them.

## What happens next

The raw export is **not** what gets deployed. You **curate** the objects you want
into `inventory/group_vars/` (runbook 03), renaming their top-level variables to
the `*_all` / `*_<env>` suffix convention. That curated content is what
`playbooks/config.yml` applies to dev/qa/prod.
