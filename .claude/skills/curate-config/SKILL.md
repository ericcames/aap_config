---
name: curate-config
description: Promote exported AAP objects from exports/ into inventory/group_vars/, renaming top-level vars to the _all / _<env> suffix convention. Use when the user wants to turn a raw export into deployable config-as-code. Mirrors docs/runbooks/03-curate.md.
---

# Curate exports into group_vars

Follow the standards in `AGENTS.md`. This mirrors `docs/runbooks/03-curate.md`.

## The rule that matters

Object variables load **implicitly** from `inventory/group_vars/`. **Never** add
`vars_files:` or `include_vars:` to load them. Environment is selected with
`--limit`.

## Steps

1. Read the object(s) the user wants from `exports/<name>/…`. Explain fields if
   asked.

2. Decide placement:
   - Shared by every environment → `inventory/group_vars/aap/<type>.yml`, top-level
     key suffixed **`_all`** (e.g. `controller_projects_all`).
   - One environment only → `inventory/group_vars/<env>/<type>.yml`, key suffixed
     **`_<env>`** (e.g. `controller_projects_dev`).

3. Copy the object into the target file and rename the top-level key accordingly.
   Keep any `{{ vaulted_* }}` placeholders exactly as-is.

4. Verify:
   ```
   ansible-lint
   git status && git diff
   ```

5. Remind the user which `vaulted_*` variables now need values (`/vault-secrets`
   or runbook 04) before this env can deploy.

## Do not

- Do not introduce `vars_files:`/`include_vars:`.
- Do not resolve `{{ vaulted_* }}` placeholders to real values here.
- Do not commit customer identifiers or real secrets.
