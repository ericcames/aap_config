# Runbook 04 — Secrets and the vault

## You will need

Curated objects in `inventory/group_vars/` (runbook 03). Some will reference
`{{ vaulted_* }}` placeholders (credential passwords, tokens, keys).

## You will learn

Why secrets never go into Git in plain text, and how ansible-vault encrypts a
per-environment `secrets.yml`.

## Steps

1. **List the secret variables your objects need:**
   ```bash
   bash utilities/list-vaulted-vars.sh
   ```
   This prints a skeleton (`vaulted_x: CHANGEME`) — it writes nothing to disk.

2. **Create the env's secrets file from that skeleton:**
   ```bash
   bash utilities/list-vaulted-vars.sh > inventory/group_vars/dev/secrets.yml
   ```
   Edit it and replace each `CHANGEME` with the real value.
   > **AI Assist:** [PROMPTS.md → rb04](../ai/PROMPTS.md#rb04).

3. **Encrypt it** (one vault password per environment):
   ```bash
   ansible-vault encrypt inventory/group_vars/dev/secrets.yml --vault-id dev@prompt
   ```
   Store that password safely — you'll add it to GitHub as the `dev` environment's
   `VAULT_PASSWORD` secret later (runbook 07).

4. **Verify the guard is happy:**
   ```bash
   bash utilities/check-vault-encrypted.sh      # "check-vault-encrypted: OK"
   ```

## How you know it worked

`head -1 inventory/group_vars/dev/secrets.yml` shows `$ANSIBLE_VAULT;...`. The
pre-commit hook will now let you commit it; it would have blocked a plaintext file.

## If it went wrong

- **`check-vault-encrypted.sh` FAILED** → the file isn't encrypted; run the
  `ansible-vault encrypt` step.
- **Committed a plaintext secret by accident** → the pre-commit hook should have
  blocked it. If it reached a remote, **rotate that credential immediately** and
  open a security issue (see SECURITY.md).
- **Lost the vault password** → you can't decrypt; regenerate the secrets file and
  re-encrypt with a new password.

Next: [05-branch-pr.md](05-branch-pr.md).
