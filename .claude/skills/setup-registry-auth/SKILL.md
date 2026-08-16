---
name: setup-registry-auth
description: Authenticate with registry.redhat.io to pull the Ansible Dev Tools container image. Use when the dev container build fails with "unauthorized" errors, or before opening the dev container for the first time. Mirrors docs/runbooks/01-devcontainer.md.
---

# Set up registry.redhat.io authentication

Follow the standards in `AGENTS.md`. This mirrors
`docs/runbooks/01-devcontainer.md` — specifically the registry authentication
steps needed before the dev container can build.

## What this does

The Ansible Dev Tools base image (`registry.redhat.io/ansible-automation-platform-27/ansible-dev-tools-rhel9`)
requires authentication. This skill walks you through a one-time setup so
your container engine can pull the image.

## Steps

1. **Check your Red Hat credentials.** You need:
   - A Red Hat customer account (email + password)
   - An Automation Hub API token (not the password)
   
   Get the token: https://console.redhat.com → Automation Hub → API token

2. **Run the login script.** On your **host machine** (not inside a container):
   ```bash
   bash .devcontainer/registry-login.sh
   ```
   
   You will be prompted for your Red Hat email (or username) and password. It's
   safe to enter credentials at this prompt — they are sent directly to
   registry.redhat.io, not logged or stored in plain text.

3. **Verify the auth file was created.** After login, check:
   ```bash
   ls -l ~/.config/containers/auth.json    # podman
   # or
   ls -l ~/.docker/config.json             # docker
   ```
   
   The file should exist with mode `600` (readable/writable by you only).

4. **Test the image pull.** Run:
   ```bash
   bash .devcontainer/pull-with-auth.sh
   ```
   
   If it prints `✓ Image pulled successfully`, your auth is working.

5. **Open the dev container.** You can now safely open the repo in VS Code's
   dev container:
   - From VS Code: `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
   - Type: `Dev Containers: Reopen in Container`
   - Wait for the build to complete

6. **Verify inside the container:**
   ```bash
   ansible --version
   ansible-galaxy collection list | grep infra.aap_configuration
   ```

## Troubleshooting

**"unauthorized: Please login to the Red Hat Registry"**

Your credentials are missing or invalid.

**Fix:** Re-run the login script:
```bash
bash .devcontainer/registry-login.sh
```

**"unable to retrieve auth token"**

Your email/password is wrong, or your Red Hat account doesn't have Automation
Hub access.

**Fix:**
- Verify your credentials at https://console.redhat.com
- If you don't have an Automation Hub API token, create one:
  https://console.redhat.com → Automation Hub → API token
- Try the login script again

**"No auth found. Run this first: bash .devcontainer/registry-login.sh"**

The `pull-with-auth.sh` helper didn't find credentials.

**Fix:** Make sure you ran `registry-login.sh` and it printed success messages.

## Do not

- Do not commit `~/.config/containers/auth.json` or `~/.docker/config.json` to
  git — they contain credentials and belong only on your local machine.
- Do not share the base64-encoded auth string with anyone — it is your plaintext
  credentials in disguise.
- Do not type your password into a terminal history file or script — the login
  script handles input safely and never logs it.
- Do not use an Automation Hub API token as your password — the script accepts
  either, but an API token is more secure for programmatic access.
