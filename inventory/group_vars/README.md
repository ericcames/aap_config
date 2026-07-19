# inventory/group_vars/ — where object definitions live

Ansible loads these files **implicitly** based on group membership in
`../hosts.yml`. There is no `include_vars`/`vars_files` anywhere in this repo —
that is the whole point (see [`AGENTS.md`](../../AGENTS.md) → Ansible standards).

## Layout

| Directory | Loaded for | Holds |
|-----------|-----------|-------|
| `aap/` | every env (azure, dev, qa, prod are children of `aap`) | objects shared by all environments; `aap_settings.yml` |
| `azure/` | the export source only | connection notes for the Azure production AAP (no objects) |
| `dev/` | dev only | dev-specific object deltas + `secrets.yml` (vault-encrypted) |
| `qa/` | qa only | qa deltas + `secrets.yml` |
| `prod/` | prod only | prod deltas + `secrets.yml` |

## The variable-suffix convention

Shared and per-env lists **merge** because `dispatch_include_wildcard_vars: true`
(set in `aap/aap_settings.yml`). Name shared lists `*_all` and per-env lists
`*_<env>`:

```yaml
# group_vars/aap/controller_projects.yml
controller_projects_all:
  - name: "Platform Baseline"
    ...

# group_vars/dev/controller_projects.yml
controller_projects_dev:
  - name: "Dev Sandbox"
    ...
```

At apply time against dev, dispatch sees both `controller_projects_all` and
`controller_projects_dev` and applies their union. Curation (runbook 03) is where
exported objects get copied here and renamed to these suffixes.

## Secrets

Each env's `secrets.yml` is **ansible-vault encrypted** and holds the
`vaulted_*` values referenced by exported credentials. Generate a skeleton with
`utilities/list-vaulted-vars.sh`, fill it, then
`ansible-vault encrypt inventory/group_vars/<env>/secrets.yml --vault-id <env>@prompt`.
The pre-commit hook and CI refuse an unencrypted `secrets.yml`.
