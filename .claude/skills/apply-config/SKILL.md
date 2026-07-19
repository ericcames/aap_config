---
name: apply-config
description: Apply this repo's config-as-code to an AAP environment — dry-run playbooks/validate.yml in check mode first, review what would change, then run playbooks/config.yml to apply. Selects the environment with --limit and unlocks secrets with --vault-id. Use when the user wants to deploy, apply, push, or preview the inventory/group_vars config against a dev, qa, or prod AAP instance.
---

# Apply config to an AAP environment

Follow the standards in `AGENTS.md` → **How to run things**. This mirrors
`playbooks/config.yml` and `playbooks/validate.yml`. There is no runbook for the
deploy path yet (runbooks 07+ are Phase 2 and not written); until there is, this
skill and `AGENTS.md` are the guidance.

## The rule that matters

**Always validate before you apply.** `validate.yml` is `config.yml` with
`check_mode: true` — it reports what would change and changes nothing. Both
playbooks assert on `aap_hostname` / `aap_username` / `aap_password` and fail
early if the env isn't set up.

Variables arrive **implicitly** from `inventory/group_vars/` — never add
`vars_files:` or `include_vars:`. The environment is chosen with `--limit`, not
by loading a directory.

## Steps

1. **Pick the target and check preconditions.** Valid apply targets are `dev`,
   `qa`, `prod_active`, `prod_passive`. **`azure` is the export source — never an
   apply target.** Confirm the env has a committed `connection.yml` and a
   vault-encrypted `secrets.yml` in `inventory/group_vars/<env>/`:
   ```
   bash utilities/check-vault-encrypted.sh
   ```
   If they're missing, send the user to `/vault-secrets` or
   `docs/runbooks/04-secrets.md` first.

2. **Dry run in check mode first:**
   ```
   ansible-playbook playbooks/validate.yml -i inventory --limit dev --vault-id dev@prompt
   ```
   The vault label is the **environment's label, not the group name** —
   `prod_active` and `prod_passive` both use `--vault-id prod@…`, because the
   secrets live in `group_vars/prod/`. If the user keeps a password file, use
   `--vault-id dev@~/secrets/.vault_pass_dev` instead of `@prompt`.

3. **Summarize what would change and get explicit confirmation.** Report the
   intended creates/updates in plain language. Do not move on to the apply until
   the user says yes.

4. **Apply:**
   ```
   ansible-playbook playbooks/config.yml -i inventory --limit dev --vault-id dev@prompt
   ```

5. **Production is an active/passive pair.** Both sides receive the same config;
   `aap_site_role` in each side's `connection.yml` decides whether schedules and
   notifications are enabled. Run active, confirm it's clean, then passive:
   ```
   ansible-playbook playbooks/config.yml -i inventory --limit prod_active  --vault-id prod@prompt
   ansible-playbook playbooks/config.yml -i inventory --limit prod_passive --vault-id prod@prompt
   ```

6. **Confirm idempotence.** Re-run `config.yml`; the second run should report no
   changes. For long runs, capture the log so it can be searched:
   ```
   ansible-playbook playbooks/config.yml -i inventory --limit dev --vault-id dev@prompt 2>&1 | tee /tmp/config.log | tail -20
   grep -n 'FAILED\|fatal' /tmp/config.log
   ```

7. **Point back at the normal path.** Day to day, config reaches an environment
   by merging a PR — `.github/workflows/deploy-dev.yml` / `deploy-qa.yml` /
   `deploy-prod.yml` run exactly these two steps on a self-hosted runner using
   the environment's `VAULT_PASSWORD` secret. A local apply is for first-run and
   testing.

## Do not

- Do not run `config.yml` without a clean `validate.yml` in the same session.
- Do not apply against `azure` — it is the read-only export source.
- Do not use `--limit prod`; target `prod_active` and `prod_passive` explicitly.
- Do not hand-apply to qa or prod to "fix" something out of band. Changes belong
  in a PR (`/branch-pr`) and the deploy workflows, or the next deploy silently
  reverts them.
- Do not print, echo, or paste vault passwords or secret values into the chat,
  the terminal log, or any tracked file.
- Do not add `vars_files:` / `include_vars:` or a project-local `ansible.cfg`.
