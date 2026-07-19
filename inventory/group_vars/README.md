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
| `prod/` | prod_active + prod_passive (both are children of prod) | shared prod objects + `aap_site_role` variable + `secrets.yml` |
| `prod_active/` | prod_active only | active-side overrides (if any beyond the env var) |
| `prod_passive/` | prod_passive only | passive-side overrides (if any beyond the env var) |

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

## Active/passive production topology

Production runs as an **active/passive pair** — two AAP instances that receive
the **same config simultaneously**. The only difference is a single variable,
`aap_site_role`, which controls whether work-triggers and outbound signals are
enabled.

`aap_site_role` is set from the `AAP_SITE_ROLE` environment variable (in
`group_vars/prod/aap_site_role.yml`). Each CI GitHub Environment
(`prod_active`, `prod_passive`) sets it to `active` or `passive`. Locally, set
it in `docs/dev-environment.sh`.

Curated objects use it to gate three categories:

| Category | Pattern | Example |
|----------|---------|---------|
| Schedules | `enabled: "{{ aap_site_role == 'active' }}"` | Job schedules, inventory syncs, project update schedules |
| Notifications | `state: "{{ 'present' if aap_site_role == 'active' else 'absent' }}"` | Slack, email, webhook callbacks |
| Webhook receivers | `enabled: "{{ aap_site_role == 'active' }}"` | Incoming webhook-triggered job templates |

**Failover:** change the `AAP_SITE_ROLE` env var (or the load-balancer header
that injects it) — no Git commit, no PR, no wait. The passive side already has
the full config; enabling its schedules makes it production.

See `group_vars/prod/schedule_overrides.yml` for commented examples.

This is the [Red Hat COP-recommended pattern for active/passive CaC](https://www.redhat.com/en/blog/automation-controller-active-passive-architecture-cac).
More references in [`docs/references.md`](../../docs/references.md).

## Secrets

Each env's `secrets.yml` is **ansible-vault encrypted** and holds the
`vaulted_*` values referenced by exported credentials. Generate a skeleton with
`utilities/list-vaulted-vars.sh`, fill it, then
`ansible-vault encrypt inventory/group_vars/<env>/secrets.yml --vault-id <env>@prompt`.
The pre-commit hook and CI refuse an unencrypted `secrets.yml`.
