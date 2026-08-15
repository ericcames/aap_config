#!/usr/bin/env bash
set -euo pipefail

# Simple helper to start Podman services inside WSL so VS Code Dev Containers
# sees the Docker-compatible socket. Run this from the WSL distro used by VS Code.

if command -v systemctl >/dev/null 2>&1 && systemctl --version >/dev/null 2>&1; then
  echo "Starting podman.socket via systemd"
  sudo systemctl enable --now podman.socket
else
  echo "Starting podman system service in background (no systemd)"
  nohup podman system service --time=0 >/dev/null 2>&1 &
fi

echo "Podman service started. Verify with: docker ps  (podman-docker shim) or podman ps"
