---
name: export-aap
description: Export controller + gateway objects from a live AAP 2.7 instance into exports/ using playbooks/export.yml. Use when the user wants to export/snapshot AAP objects from the Azure production instance (or any AAP) into this repo. Mirrors docs/runbooks/02-export.md.
---

# Export AAP objects

Follow the standards in `AGENTS.md`. This mirrors `docs/runbooks/02-export.md`.

## Steps

1. Confirm the env's vault-encrypted `secrets.yml` and committed `connection.yml`
   exist in `inventory/group_vars/<env>/`. If not, tell the user to set them up
   first (use the `/vault-secrets` skill or `docs/runbooks/04-secrets.md`).

2. Run the export (default target is the `azure` group; override with
   `-e export_group=<group>` and `-e export_name=<dir>` if needed):
   ```
   ansible-playbook playbooks/export.yml -i inventory --limit azure --vault-id azure@prompt
   ```
   Scope is controller + gateway only (`input_tag: [controller, gateway]`), with
   `secrets_as_variables: true` so secrets export as `{{ vaulted_* }}`. A read
   token is minted and deleted in the play's `always:` — don't add git steps.

3. Run the leak guard and report the result:
   ```
   bash utilities/scan-exports.sh
   ```

4. Tell the user the output is in `exports/<name>/` and the next step is curation
   (`/curate-config` or runbook 03). Do NOT commit or push for them — that's their
   learning exercise.

## Do not

- Do not add `git add/commit/push` to the playbook or run them automatically.
- Do not disable `secrets_as_variables` or fill real secret values.
- Do not create a project-local `ansible.cfg`.
