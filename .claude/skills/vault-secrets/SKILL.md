---
name: vault-secrets
description: Generate and encrypt a per-environment secrets.yml for the vaulted_* variables referenced by curated objects. Use when the user needs to fill in AAP credential secrets and ansible-vault encrypt them. Mirrors docs/runbooks/04-secrets.md.
---

# Manage vaulted secrets

Follow the standards in `AGENTS.md`. This mirrors `docs/runbooks/04-secrets.md`.

## Steps

1. List the placeholders the curated objects reference:
   ```
   bash utilities/list-vaulted-vars.sh
   ```
   (It writes nothing to disk.)

2. Create the env's secrets file from the skeleton:
   ```
   bash utilities/list-vaulted-vars.sh > inventory/group_vars/<env>/secrets.yml
   ```
   Tell the user to replace each `CHANGEME` with the real value in their editor.
   **Do not ask the user to paste secret values to you, and do not write real
   secret values yourself.**

3. Encrypt (one vault password per environment):
   ```
   ansible-vault encrypt inventory/group_vars/<env>/secrets.yml --vault-id <env>@prompt
   ```

4. Verify the guard passes:
   ```
   bash utilities/check-vault-encrypted.sh
   ```

5. Remind the user the same vault password becomes the GitHub `<env>` environment's
   `VAULT_PASSWORD` secret (runbook 07 / docs/github-setup.md).

## Do not

- Do not commit a plaintext `secrets.yml` (the pre-commit hook and CI block it).
- Do not echo secret values into the terminal or into any tracked file.
