#!/usr/bin/env bash
# ============================================================================
# utilities/check-vault-encrypted.sh
# ============================================================================
# Guard: every inventory/group_vars/<env>/secrets.yml MUST be ansible-vault
# encrypted (first line starts with "$ANSIBLE_VAULT"). Runs in the pre-commit
# hook and in CI (lint.yml). Exits non-zero on the first plaintext secrets file.
#
# No secrets.yml files yet? That's fine — nothing to check, exit 0.
# ============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0

# Find every file named secrets.yml or secrets.yaml under inventory/group_vars.
while IFS= read -r -d '' f; do
  first_line="$(head -n1 "$f" 2>/dev/null || true)"
  if [[ "$first_line" != \$ANSIBLE_VAULT* ]]; then
    echo "ERROR: not vault-encrypted: ${f#"$ROOT"/}" >&2
    echo "       Encrypt it:  ansible-vault encrypt '${f#"$ROOT"/}' --vault-id <env>@prompt" >&2
    fail=1
  fi
done < <(find "$ROOT/inventory/group_vars" -type f \( -name 'secrets.yml' -o -name 'secrets.yaml' \) -print0 2>/dev/null)

if [[ "$fail" -ne 0 ]]; then
  echo "check-vault-encrypted: FAILED — plaintext secrets file(s) found." >&2
  exit 1
fi

echo "check-vault-encrypted: OK"
