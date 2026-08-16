#!/usr/bin/env bash
# ============================================================================
# .devcontainer/pull-with-auth.sh
# ============================================================================
# Helper to pull the Ansible Dev Tools image using registry.redhat.io auth.
#
# Usage:
#   bash .devcontainer/pull-with-auth.sh
#
# This script uses the auth stored by `registry-login.sh` in the standard
# location. It is primarily useful for CI/CD or for pulling via a separate
# authfile if you prefer that approach.
# ============================================================================
set -euo pipefail

IMAGE="registry.redhat.io/ansible-automation-platform-27/ansible-dev-tools-rhel9:latest"

# Detect if standard auth locations exist
PODMAN_AUTH="${HOME}/.config/containers/auth.json"
DOCKER_AUTH="${HOME}/.docker/config.json"

if [[ -n "${AUTHFILE:-}" && -f "${AUTHFILE}" ]]; then
  # Option 1: Use an explicit AUTHFILE env var (for CI/custom workflows)
  echo "Pulling ${IMAGE} using AUTHFILE=${AUTHFILE}..."
  podman pull --authfile "${AUTHFILE}" "${IMAGE}"
elif [[ -f "${PODMAN_AUTH}" ]]; then
  # Option 2: Use standard podman auth location (set by registry-login.sh)
  echo "Pulling ${IMAGE} using ${PODMAN_AUTH}..."
  podman pull --authfile "${PODMAN_AUTH}" "${IMAGE}"
elif [[ -f "${DOCKER_AUTH}" ]]; then
  # Option 3: Use standard docker auth location
  echo "Pulling ${IMAGE} using ${DOCKER_AUTH}..."
  podman pull --authfile "${DOCKER_AUTH}" "${IMAGE}"
else
  echo "ERROR: No auth found. Run this first:" >&2
  echo "  bash .devcontainer/registry-login.sh" >&2
  exit 1
fi

echo "✓ Image pulled successfully."

