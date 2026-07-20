# Runbook 04 — Secrets and the vault

> **Skill:** `/vault-secrets` runs this whole runbook for you, in Claude Code or GitHub
> Copilot CLI. Read the steps first, then let it drive.

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

   > **Password files instead of typing.** `@prompt` is the default and the right
   > choice for a person at a keyboard. For an unattended run — or a live demo,
   > where a mistyped password stalls everything — put the password in a file
   > **outside the repo** and point `--vault-id` at it:
   >
   > ```bash
   > # Prompts for the password; noclobber refuses to overwrite an existing file.
   > ( set -o noclobber
   >   read -rsp 'dev vault password: ' PW && printf '%s' "$PW" > ~/secrets/.vault_pass_dev
   >   unset PW; echo )
   > chmod 600 ~/secrets/.vault_pass_dev
   > ansible-playbook playbooks/config.yml -i inventory --limit dev \
   >   --vault-id dev@~/secrets/.vault_pass_dev
   > ```
   >
   > One file per environment, mode `600`, kept in `~/secrets/` so it is never
   > near the working tree. `.gitignore` also covers `*.vault_pass` /
   > `.vault-password` patterns as a second line of defense, but the real
   > protection is that the file lives outside the repo. This is the same secret
   > you store as the environment's `VAULT_PASSWORD` in GitHub.
   >
   > **Never write a literal password into a command in these docs.** Anyone
   > running the block verbatim would overwrite a working key with a published
   > placeholder — which both destroys access to the vaulted file and, worse,
   > re-encrypts it under a password printed in this repo.

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

## Alternative: an external secrets manager

If your environment keeps secrets in **BeyondTrust Password Safe**, `secrets.yml`
shrinks to the BeyondTrust OAuth credentials (still vault-encrypted) and the
`vaulted_*` values resolve from Password Safe at run time. The design is in
[`docs/secrets-beyondtrust.md`](../secrets-beyondtrust.md) — captured, not yet
implemented. The steps above remain the default, and environments can mix.

Next: [05-branch-pr.md](05-branch-pr.md).
