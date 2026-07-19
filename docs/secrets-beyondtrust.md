# BeyondTrust Password Safe — secrets-management pattern (design, not yet built)

> **Status: design captured, not implemented.** There is no live Password Safe to
> test against yet, so nothing here is wired up. `ansible-vault` (runbook 04)
> remains the kit default. The `.example` files this document describes ship as
> inert templates; the `beyondtrust.secrets_safe` collection is deliberately
> **not** pinned yet (see [What's deferred](#whats-deferred)).
>
> Treat every snippet as illustrative. **Verify plugin option names and return
> shape against the collection's own docs before implementing** — see
> [References](references.md).

Some environments this kit lands in manage secrets in **BeyondTrust Password Safe
/ Secrets Safe** rather than in `ansible-vault`. This page is the design for those
environments: what changes, what stays, and why.

Nothing here is mandatory. An environment without Password Safe uses the vault
flow unchanged, and the two can coexist — dev and qa can stay pure-vault while
prod is BeyondTrust-backed.

## Why not `credential_input_sources`

AAP's built-in answer to "my secrets live in an external vault" is
[External Secret Management](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/html/configuring_automation_execution/assembly-controller-secret-management):
a credential field is *linked* to an entry in an external system, and AAP fetches
it at job launch. In CaC terms that is a `credential_input_sources` object.

**That path is unavailable for BeyondTrust.** AAP 2.6/2.7 ships credential plugins
for CyberArk (CCP and Conjur), HashiCorp Vault, Microsoft Azure Key Vault, AWS
Secrets Manager, Centrify, Thycotic/Delinea, and GitHub App installations —
**there is no BeyondTrust plugin**. Writing one means building and shipping a
custom AAP credential plugin (a Python entry point installed into the platform),
which is a platform-engineering project, not a config-as-code change.

So this design uses the vendor's supported path instead: the certified
**`beyondtrust.secrets_safe`** collection and its **`secrets_safe_lookup`** lookup
plugin. It authenticates with an OAuth client ID/secret, runs wherever Ansible
runs, and retrieves either Password Safe managed-account passwords or Secrets Safe
secrets. It supports ansible-core 2.14+, comfortably inside this kit's 2.16 pin.

The consequence worth naming up front: a lookup plugin runs **in the Ansible
process**, not in the AAP platform. So BeyondTrust is reached from two different
places, and they need separate treatment. That is the two-layer split below.

| | Layer 1 — deploy time | Layer 2 — job runtime |
|---|---|---|
| **Who runs it** | this repo's `config.yml`, from a laptop or CI runner | an AAP job template's playbook, in an execution environment |
| **What it fetches** | the `vaulted_*` values that CaC objects are built from | secrets the automation itself needs at run time |
| **Where creds come from** | the env's vault-encrypted `secrets.yml` | a custom AAP credential injecting env vars |
| **Needs the collection in** | the dev container / runner | the job's execution environment |

---

## Layer 1 — deploy time (applying config as code)

Today every `vaulted_*` value is a literal inside the env's vault-encrypted
`secrets.yml`. Under this pattern, `secrets.yml` shrinks to a **bootstrap** file
and the object secrets become lazy lookups in a **committed** file.

### The files

| File | Committed? | Encrypted? | Holds |
|------|-----------|-----------|-------|
| `connection.yml` | yes | no | `aap_hostname`, `aap_validate_certs` (unchanged) |
| `beyondtrust.yml` | yes | no | `bt_api_url`, `bt_verify_ca` — non-secret BT settings |
| `secrets.yml` | yes | **yes** | `aap_username`, `aap_password`, `vaulted_bt_client_id`, `vaulted_bt_client_secret` — **bootstrap only** |
| `secrets_lookup.yml` | yes | no | every other `vaulted_*`, defined as a `secrets_safe_lookup` — **no secret values** |

The `beyondtrust.yml` / `secrets.yml` split is the same non-secret vs. secret
split the kit already makes between `connection.yml` and `secrets.yml`.

Vault does not go away — it becomes the **bootstrap layer**. Something has to hold
the credential that unlocks Password Safe, and one vault password per environment
still unlocks it. This preserves the kit's
[unified-secrets decision](../ROADMAP.md#decisions-log): CI still needs exactly
one `VAULT_PASSWORD` per GitHub Environment, and no secret is ever read from a
shell environment variable at deploy time.

### What it looks like

```yaml
# inventory/group_vars/dev/beyondtrust.yml — committed, no secrets
bt_api_url: "https://passwordsafe.example.com/BeyondTrust/api/public/v3"
bt_verify_ca: true
```

```yaml
# inventory/group_vars/dev/secrets.yml — vault-encrypted, bootstrap only
aap_username: "..."
aap_password: "..."
vaulted_bt_client_id: "..."
vaulted_bt_client_secret: "..."
```

```yaml
# inventory/group_vars/dev/secrets_lookup.yml — committed, NO secret values.
# Each value is a lazy lookup, resolved only when something references it.
vaulted_machine_password: >-
  {{ lookup('beyondtrust.secrets_safe.secrets_safe_lookup',
            api_url=bt_api_url,
            verify_ca=bt_verify_ca,
            client_id=vaulted_bt_client_id,
            client_secret=vaulted_bt_client_secret,
            retrieval_type='MANAGED_ACCOUNT',
            secret_list='generic-system/generic-account') | first }}
```

Curated objects are **untouched** — they still say `{{ vaulted_machine_password }}`.
Only the definition of that variable moves. That is what makes this additive: the
same curated `group_vars/aap/` objects work against a vault-backed dev and a
BeyondTrust-backed prod.

`retrieval_type` picks the path format: `MANAGED_ACCOUNT` takes
`system_name/account_name`, `SECRET` takes `folder/secret_title`. Both go in
`secret_list`, which accepts a comma-separated list and returns results in list
form — hence the `| first` for a single secret. **Confirm that return shape before
implementing**; if a version returns a bare string, the filter comes off.

### Gotchas to respect

- **One file per variable.** Ansible loads the files in a `group_vars/<env>/`
  directory alphabetically, so a `vaulted_*` defined in both `secrets.yml` and
  `secrets_lookup.yml` resolves to the `secrets.yml` value with **no warning**.
  Each variable lives in exactly one of the two. Migrating a secret means deleting
  it from `secrets.yml` in the same change that adds the lookup.
- **`secrets_lookup.yml` is committed in plaintext by design.** The vault guard
  (`utilities/check-vault-encrypted.sh`) matches the filenames `secrets.yml` and
  `secrets.yaml` exactly, so this file is correctly ignored by it. Keep it that
  way — never put a literal secret in this file, and never name it `secrets.yml`.
- **Placeholders only, forever.** Real system and account names are customer
  infrastructure detail. Committed examples use `generic-system/generic-account`.
- **Lookups are lazy and uncached.** Each *reference* to the variable can trigger
  an API call. A large curated config means many calls; check that against
  Password Safe rate limits, and expect the config run to fail with an API error
  rather than a vault error when credentials are wrong.
- **Deploy hosts need network reach.** Self-hosted runners must reach the Password
  Safe API, not just AAP. Worth listing alongside AAP endpoints in the runner
  network design (see [going to production](going-to-production.md)).
- **`list-vaulted-vars.sh` still earns its keep.** Its output stops being a
  `secrets.yml` skeleton and becomes the checklist of values to load into Password
  Safe and then define as lookups.

---

## Layer 2 — job runtime (playbooks running in AAP)

Layer 1 covers secrets that *build* AAP objects. Automation that needs a secret
*while it runs* is a separate problem, and this is where the missing credential
plugin actually bites: without one, AAP cannot inject a Password Safe value into
a job directly. The job has to fetch it itself.

The pattern is a **custom credential type** that carries the BeyondTrust OAuth
credentials into the job as environment variables, plus playbooks that call the
lookup. Defined as CaC:

```yaml
# group_vars/aap/controller_credential_types.yml — shared across environments
controller_credential_types_all:
  - name: "BeyondTrust Secrets Safe"
    kind: cloud
    inputs:
      fields:
        - id: bt_api_url
          type: string
          label: "Password Safe API URL"
        - id: bt_client_id
          type: string
          label: "OAuth client ID"
        - id: bt_client_secret
          type: string
          label: "OAuth client secret"
          secret: true
      required: [bt_api_url, bt_client_id, bt_client_secret]
    injectors:
      env:
        PASSWORD_SAFE_API_URL: "{{ '{{ bt_api_url }}' }}"
        PASSWORD_SAFE_CLIENT_ID: "{{ '{{ bt_client_id }}' }}"
        PASSWORD_SAFE_CLIENT_SECRET: "{{ '{{ bt_client_secret }}' }}"
```

> The doubled braces are not a typo. Injector templates are evaluated by AAP at
> job launch, so they must survive Ansible's own templating when this file is
> applied. Check the rendering with `validate.yml` before trusting it.

```yaml
# group_vars/<env>/controller_credentials.yml
controller_credentials_dev:
  - name: "BeyondTrust — dev"
    credential_type: "BeyondTrust Secrets Safe"
    organization: "Default"
    inputs:
      bt_api_url: "{{ bt_api_url }}"
      bt_client_id: "{{ vaulted_bt_client_id }}"
      bt_client_secret: "{{ vaulted_bt_client_secret }}"
```

Note what closes the loop: this credential's own secrets are `vaulted_*`
variables, so **Layer 1 resolves them** — from vault in a vault-backed env, from
Password Safe itself in a BeyondTrust-backed one.

A job template attaches that credential, and its playbook reads the injected
environment variables:

```yaml
- name: Fetch a managed-account password at run time
  ansible.builtin.set_fact:
    target_password: >-
      {{ lookup('beyondtrust.secrets_safe.secrets_safe_lookup',
                api_url=lookup('ansible.builtin.env', 'PASSWORD_SAFE_API_URL'),
                client_id=lookup('ansible.builtin.env', 'PASSWORD_SAFE_CLIENT_ID'),
                client_secret=lookup('ansible.builtin.env', 'PASSWORD_SAFE_CLIENT_SECRET'),
                retrieval_type='MANAGED_ACCOUNT',
                secret_list='generic-system/generic-account') | first }}
  no_log: true
```

Two constraints on this layer:

- **The execution environment must contain `beyondtrust.secrets_safe`.** That is a
  property of the EE image, which is built in the automation-content repos — not
  in this config repo. Adding the credential type here does not make the lookup
  work; the EE has to ship the collection.
- **`no_log: true` on anything touching the value.** `aap_settings.yml` already
  sets `aap_configuration_secure_logging: true` for the CaC side; job playbooks
  need their own discipline.

---

## What's deferred

Left undone deliberately, to be picked up when a Password Safe instance is
available to test against:

- [ ] **Pin `beyondtrust.secrets_safe`** in `collections/requirements.yml` — and
      nowhere else. Not pinned now because `AGENTS.md`'s bump procedure requires
      verifying a pin with `validate.yml` against a live environment, which is
      impossible today; pinning early would install an unreferenced collection
      into every dev container and CI runner.
- [ ] Confirm plugin option names, the `secret_list` return shape, and certificate
      auth (`certificate_path` / `certificate_password`) if the environment
      requires it over client-secret auth.
- [ ] Verify the injector double-brace rendering in Layer 2 with a real apply.
- [ ] Extend the `/vault-secrets` skill (or add a sibling) once there is a
      runnable workflow to mirror.
- [ ] Decide whether `aap_username` / `aap_password` also move to Password Safe,
      or stay in the vault bootstrap. Keeping them in vault is simpler; moving
      them means the connection itself depends on a reachable Password Safe.
- [ ] Fold the setup steps into runbook 04 (or a new runbook) once they are real
      steps a trainee can run rather than a design.

## See also

- [Runbook 04 — Secrets and the vault](runbooks/04-secrets.md) — the default flow
- [Going to production](going-to-production.md) — secrets governance at scale
- [References](references.md) — BeyondTrust and AAP secret-management links
- [`ROADMAP.md`](../ROADMAP.md) — the decisions log entry for this design
