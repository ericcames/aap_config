---
name: vault-secrets
description: Create and encrypt a per-environment secrets.yml containing connection credentials (aap_username, aap_password) and CaC object secrets (vaulted_*). Also set up the env's connection.yml. Use when the user needs to configure an environment's secrets or connection settings. Mirrors docs/runbooks/04-secrets.md.
---

# Manage vaulted secrets

Follow the standards in `AGENTS.md`. This mirrors `docs/runbooks/04-secrets.md`.

## The model

All secrets live in one vault-encrypted file per environment:
`inventory/group_vars/<env>/secrets.yml`. This includes connection credentials
(`aap_username`, `aap_password`) AND CaC object secrets (`vaulted_*`).

Non-secret connection settings (hostname, cert validation, site role) live in
the committed `connection.yml` in the same directory.

## Steps

1. **Set up the connection file** (if not already done):
   ```
   cp inventory/group_vars/<env>/connection.yml.example inventory/group_vars/<env>/connection.yml
   ```
   Fill in the real hostname and cert-validation setting. This file is committed
   (not encrypted) — hostnames are not secrets.

2. **Create the secrets file.** If the user provides their secrets, write them
   directly into `inventory/group_vars/<env>/secrets.yml`. If not, start from
   the example:
   ```
   cp inventory/group_vars/<env>/secrets.yml.example inventory/group_vars/<env>/secrets.yml
   ```
   The file must contain at minimum:
   ```yaml
   aap_username: "<real value>"
   aap_password: "<real value>"
   ```
   Plus any `vaulted_*` variables their curated objects need. Run
   `bash utilities/list-vaulted-vars.sh` to list them.

3. **Encrypt it** (one vault password per environment):
   ```
   ansible-vault encrypt inventory/group_vars/<env>/secrets.yml --vault-id <env>@prompt
   ```

4. **Verify the guard passes:**
   ```
   bash utilities/check-vault-encrypted.sh
   ```

5. **Remind the user** that the same vault password becomes the GitHub
   Environment's `VAULT_PASSWORD` secret (the only CI secret needed per env).

## Do not

- Do not commit a plaintext `secrets.yml` (the pre-commit hook and CI block it).
- Do not echo secret values into the terminal log or any tracked file other than
  the `secrets.yml` that will be immediately encrypted.
- Do not put secrets in `connection.yml` — that file is committed unencrypted.
