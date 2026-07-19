# Runbook 02 — Export from the production AAP

> **Skill:** `/export-aap` runs this whole runbook for you, in Claude Code or GitHub
> Copilot CLI. Read the steps first, then let it drive.

## You will need

The dev container open (runbook 01), and connection details for the **Azure
production AAP**: URL, service-account username, password.

### Windows workstation checklist

Before running the export, confirm these on your **Windows host** (not inside the
container):

1. **Container runtime is running.** Docker Desktop (WSL2 backend) or Podman
   Desktop — look for the whale/podman icon in the system tray.
2. **`AH_TOKEN` is set.** The Automation Hub token must be a Windows environment
   variable so it passes into the container automatically:
   ```powershell
   setx AH_TOKEN "your-token-from-console.redhat.com"
   ```
   Then **restart your terminal** (or VS Code) so the variable takes effect.
3. **Git line endings.** The repo's `.gitattributes` forces LF, but as a
   safety net:
   ```powershell
   git config --global core.autocrlf input
   ```
4. **Clone fresh.** Always `git clone` — never copy/paste files from a Windows
   editor (Notepad, WordPad), as they may inject CRLF line endings that break
   YAML parsing.

## You will learn

How to run a playbook, what the "working tree" is, and why `exports/` is safe to
commit but secrets are not.

## Steps

1. **Set up your connection and secrets files** (if not already done — see
   [runbook 04](04-secrets.md) for full details):
   ```bash
   cp inventory/group_vars/azure/connection.yml.example inventory/group_vars/azure/connection.yml
   cp inventory/group_vars/azure/secrets.yml.example   inventory/group_vars/azure/secrets.yml
   ```
   Fill in the real hostname in `connection.yml` and real username/password in
   `secrets.yml`. Then encrypt the secrets:
   ```bash
   ansible-vault encrypt inventory/group_vars/azure/secrets.yml --vault-id azure@prompt
   ```
   (During initial testing you may point at an AAP 2.6 instance — the export
   works identically on 2.6 and 2.7.)

2. **Optional: save your vault password to a file** so you don't retype it
   every run:
   ```bash
   mkdir -p ~/secrets && chmod 700 ~/secrets
   echo 'your-vault-password' > ~/secrets/.vault_pass_azure && chmod 600 ~/secrets/.vault_pass_azure
   ```
   Then use `@~/secrets/.vault_pass_azure` instead of `@prompt` below. CI does
   the same thing — the `VAULT_PASSWORD` GitHub secret is written to a temp file
   by each deploy workflow.

3. **Run the export:**
   ```bash
   ansible-playbook playbooks/export.yml -i inventory --limit azure --vault-id azure@prompt
   ```
   Or with a vault password file (step 2):
   ```bash
   ansible-playbook playbooks/export.yml -i inventory --limit azure \
     --vault-id azure@~/secrets/.vault_pass_azure
   ```
   > **AI Assist:** [PROMPTS.md → rb02](../ai/PROMPTS.md#rb02) — ask it to explain
   > the command before you run it.

4. **Scan for leaked secrets:**
   ```bash
   bash utilities/scan-exports.sh          # should print "scan-exports: OK"
   ```

## How you know it worked

`exports/azure/` now contains folders per organization with one YAML file per
object. Open a credential file — secret fields read `{{ vaulted_... }}`, never a
real password. `scan-exports.sh` prints OK.

## If it went wrong

- **Assertion: aap_hostname not set** → `connection.yml` is missing or empty.
  Re-run step 1.
- **Vault password error** → you didn't pass `--vault-id azure@prompt`, or the
  password doesn't match what you used to encrypt.
- **Auth/401** → wrong username/password in `secrets.yml`, or the URL has a
  trailing slash (remove it).
- **TLS certificate error** → the instance uses a private CA; set
  `aap_validate_certs: false` in `connection.yml`.
- **`scan-exports.sh` FAILED** → a real secret leaked (rare). Re-run the export;
  if it persists, remove the value by hand and report it.

Next: [03-curate.md](03-curate.md).
