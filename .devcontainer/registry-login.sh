#!/usr/bin/env bash
# ============================================================================
# .devcontainer/registry-login.sh
# ============================================================================
# Authenticates podman/docker with registry.redhat.io for the Ansible Dev Tools image.
#
# Usage:
#   bash .devcontainer/registry-login.sh
#
# This script prompts for your Red Hat Customer Portal credentials and stores
# them in the standard auth location:
#   - podman: ~/.config/containers/auth.json
#   - docker: ~/.docker/config.json
# ============================================================================
set -e

echo "=========================================="
echo "registry.redhat.io authentication setup"
echo "=========================================="
echo
echo "You need Red Hat Customer Portal credentials to pull the Ansible Dev Tools image."
echo "Get them at: https://console.redhat.com"
echo
echo "You will be prompted for:"
echo "  - Username: your Red Hat account email or username"
echo "  - Password: your Red Hat account password"
echo
echo "Credentials will be stored in:"
if command -v podman &>/dev/null; then
  echo "  ~/.config/containers/auth.json (podman)"
else
  echo "  ~/.docker/config.json (docker)"
fi
echo
read -r -s -p "Press Enter to begin login, or Ctrl+C to cancel: " _
echo

# Try podman first; fall back to docker if podman is not available
if command -v podman &>/dev/null; then
  echo "Logging in to registry.redhat.io with podman..."
  podman login registry.redhat.io
  echo
  echo "✓ podman authentication stored in ~/.config/containers/auth.json"
elif command -v docker &>/dev/null; then
  echo "Logging in to registry.redhat.io with docker..."
  docker login registry.redhat.io
  echo
  echo "✓ docker authentication stored in ~/.docker/config.json"
else
  echo "ERROR: neither podman nor docker found in PATH" >&2
  exit 1
fi

echo
echo "Testing image pull..."
if command -v podman &>/dev/null; then
  podman pull registry.redhat.io/ansible-automation-platform-27/ansible-dev-tools-rhel9:latest --quiet
else
  docker pull registry.redhat.io/ansible-automation-platform-27/ansible-dev-tools-rhel9:latest
fi

echo "✓ Image pulled successfully"
echo
echo "Next step: Open the repo in your Dev Container from VS Code."
echo "         (Reopen in Container from the command palette)"
