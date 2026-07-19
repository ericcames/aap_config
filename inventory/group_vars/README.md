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
| `prod/` | prod_active + prod_passive (both are children of prod) | shared prod objects + `secrets.yml` |
| `prod_active/` | prod_active only | `connection.yml` with `aap_site_role: active` |
| `prod_passive/` | prod_passive only | `connection.yml` with `aap_site_role: passive` |

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

`aap_site_role` is set as a plain value in each side's committed `connection.yml`:
`group_vars/prod_active/connection.yml` has `aap_site_role: active` and
`group_vars/prod_passive/connection.yml` has `aap_site_role: passive`.

Curated objects use it to gate three categories:

| Category | Pattern | Example |
|----------|---------|---------|
| Schedules | `enabled: "{{ aap_site_role == 'active' }}"` | Job schedules, inventory syncs, project update schedules |
| Notifications | `state: "{{ 'present' if aap_site_role == 'active' else 'absent' }}"` | Slack, email, webhook callbacks |
| Webhook receivers | `enabled: "{{ aap_site_role == 'active' }}"` | Incoming webhook-triggered job templates |

**Failover:** swap the `aap_site_role` values in the two `connection.yml` files
(or flip the load-balancer header). The passive side already has the full config;
enabling its schedules makes it production.

See `group_vars/prod/schedule_overrides.yml` for commented examples.

This is the [Red Hat COP-recommended pattern for active/passive CaC](https://www.redhat.com/en/blog/automation-controller-active-passive-architecture-cac).
More references in [`docs/references.md`](../../docs/references.md).

## Secrets

**All secrets live in one place:** each env's `secrets.yml`, **ansible-vault
encrypted**. This includes connection credentials (`aap_username`,
`aap_password`) AND CaC object secrets (`vaulted_*`). Non-secret connection
settings (hostname, cert validation, site role) live in the committed
`connection.yml` in the same directory.

Each env has `.example` templates showing the format:

```bash
# Set up a new env's secrets:
cp inventory/group_vars/<env>/connection.yml.example inventory/group_vars/<env>/connection.yml
cp inventory/group_vars/<env>/secrets.yml.example   inventory/group_vars/<env>/secrets.yml
# Fill in real values, then encrypt:
ansible-vault encrypt inventory/group_vars/<env>/secrets.yml --vault-id <env>@prompt
```

The pre-commit hook and CI refuse an unencrypted `secrets.yml`. Use
`utilities/list-vaulted-vars.sh` to see which `vaulted_*` variables your
curated objects need.

This follows the [COP `aap_configuration_template`](https://github.com/redhat-cop/aap_configuration_template)
pattern. See [`docs/references.md`](../../docs/references.md) for more.
