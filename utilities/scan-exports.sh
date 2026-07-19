#!/usr/bin/env bash
# ============================================================================
# utilities/scan-exports.sh
# ============================================================================
# Guard: exported object files under exports/ should contain secret FIELDS only
# as {{ vaulted_* }} placeholders (filetree_create secrets_as_variables: true).
# This scans committed export files for secret-shaped keys whose value is NOT a
# vaulted placeholder and NOT already null/empty — i.e. a real secret that leaked.
# Runs in the pre-commit hook and in CI. Exits non-zero if a likely leak is found.
#
# *_settings exports are gitignored (they can embed SSO secrets), so they are not
# scanned here — they never reach git.
#
# No exports yet? Nothing to scan, exit 0.
# ============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPORTS="$ROOT/exports"

if [[ ! -d "$EXPORTS" ]]; then
  echo "scan-exports: OK (no exports/ dir)"
  exit 0
fi

# Secret-bearing keys emitted by filetree_create.
KEYS='password|token|secret|ssh_key_data|ssh_key_unlock|become_password|vault_password|client_secret|api_key|authorize_password'

# A value is SAFE if it is a vaulted placeholder, empty, null, or "", or an
# obvious template. Flag anything else on a secret key line.
hits="$(grep -rInE "^[[:space:]]*(${KEYS}):[[:space:]]*" "$EXPORTS" 2>/dev/null \
  | grep -vE ":[[:space:]]*(\"\{\{[[:space:]]*vaulted_|'\{\{[[:space:]]*vaulted_|\{\{[[:space:]]*vaulted_)" \
  | grep -vE ":[[:space:]]*(\"\"|''|~|null|true|false|)[[:space:]]*$" \
  | grep -vE ":[[:space:]]*\{\{" \
  || true)"

if [[ -n "$hits" ]]; then
  echo "scan-exports: FAILED — possible real secret(s) in exports/ (expected {{ vaulted_* }}):" >&2
  echo "$hits" | sed "s#$ROOT/##" >&2
  echo "Fix: re-export with secrets_as_variables: true, or remove the value by hand." >&2
  exit 1
fi

echo "scan-exports: OK"
