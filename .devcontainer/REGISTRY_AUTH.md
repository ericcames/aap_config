# Registry Authentication for Dev Container

The Ansible Dev Tools dev container image (`registry.redhat.io/ansible-automation-platform-27/ansible-dev-tools-rhel9`) requires authentication with Red Hat's registry.

## One-time setup

### 1. Log in to the registry

Run the interactive login script:

```bash
bash .devcontainer/registry-login.sh
```

You will be prompted for your Red Hat Customer Portal credentials (email and password). Get a token at: https://console.redhat.com → Automation Hub → API token.

This automatically stores your credentials in the standard location:
- **podman**: `~/.config/containers/auth.json` (mode 600)
- **docker**: `~/.docker/config.json` (mode 600)

### 2. Open the dev container

From VS Code:
- Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
- Type "Dev Containers: Reopen in Container"
- Wait for the container to build and start

The build process will:
1. Pull the base Ansible Dev Tools image
2. Layer additional tools (gh CLI, Node.js)
3. Run `post-create.sh` inside the container to install collections

## Troubleshooting

### "unauthorized: Please login to the Red Hat Registry"

Your credentials are missing or invalid.

**Fix:**
```bash
# Re-run the login script
bash .devcontainer/registry-login.sh

# Or manually log in with podman/docker
podman login registry.redhat.io
```

### Verify auth is working

```bash
bash .devcontainer/pull-with-auth.sh
```

This pulls the image using your stored credentials. If it succeeds, your auth is set up correctly.

## Advanced: Using a custom authfile (CI/CD)

If you're running this in CI/CD or prefer a separate authfile:

```bash
export AUTHFILE="/path/to/auth.json"
bash .devcontainer/pull-with-auth.sh
```

The `auth.json` format is standard Docker/podman:

```json
{
  "auths": {
    "registry.redhat.io": {
      "auth": "<BASE64_USERNAME_COLON_PASSWORD>"
    }
  }
}
```

To create the base64 value:

```bash
echo -n "YOUR_EMAIL:YOUR_PASSWORD" | base64
```

Then paste it into `auth.json` (without the newline).
