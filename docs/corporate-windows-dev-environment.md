# Corporate Windows Dev Environment — AAP Config-as-Code

Set up a containerized Ansible development environment on a corporate Windows
workstation so you can export objects from an internal AAP 2.7 instance into
Git — the first step toward managing AAP as code.

> This document was created with [Claude](https://claude.ai/claude-code). The
> upstream reference for the dev-tools container is
> [Install Ansible dev tools on a container inside VS Code](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.7/install-proc_devtools_install_container)
> (Red Hat AAP 2.7 docs).

## Overview

This guide builds a local Ansible development environment that can reach two
internal systems behind your corporate firewall:

1. Your **Private Automation Hub (PAH)** — to install Red Hat certified and
   validated Ansible collections.
2. Your **dev AAP 2.7 instance** — to export controller and gateway objects.

Because both systems are internal-only, **GitHub Codespaces will not work** —
the toolchain comes up fine, but `ansible-galaxy install` and the export
playbook cannot reach your endpoints. The environment must run locally where
it has network access.

This repo is based on the
[aap_config starter kit](https://github.com/ericcames/aap_config). Another
example of config-as-code patterns for AAP is
[sales.demos](https://github.com/ericcames/sales.demos). If you have not yet
copied the starter kit into your corporate GitHub instance, see
[Duplicating into enterprise GitHub](duplicating-into-enterprise-github.md)
first.

**Scope:** this guide covers environment setup and the first export. Curating
exported objects and importing them into other environments are covered in
[runbook 03](runbooks/03-curate.md) and beyond.

## Prerequisites

### WSL2 and virtualization

The dev container needs a Linux backend on Windows. Run the **preflight
checks** in [runbook 00 → Preflight](runbooks/00-prerequisites.md#preflight-can-this-windows-desktop-run-the-dev-container)
before continuing. If WSL2 or Hyper-V is blocked by policy or firmware, this
desktop cannot run a local dev container — talk to your IT team about enabling
WSL2, or use a RHEL box on the internal network via VS Code Remote-SSH.

### Container runtime

Install **Docker Desktop** (simplest) or **Podman Desktop** (license-free).
If you use Podman, set the VS Code setting `dev.containers.dockerPath` to
`podman`.

### VS Code and extensions

Install [VS Code](https://code.visualstudio.com/) and these extensions:

- [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- [Red Hat Ansible](https://marketplace.visualstudio.com/items?itemName=redhat.ansible)
- [GitHub Copilot](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot) +
  [GitHub Copilot Chat](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot-chat)

### GitHub CLI

Install the [GitHub CLI](https://cli.github.com/) and authenticate to your
corporate GitHub Enterprise instance:

```bash
gh auth login --hostname YOUR-ENTERPRISE-HOST
```

Verify your Copilot seat:

```bash
gh api /user/copilot_billing
```

Seat details = you're good. A `404` = no seat; ask your GitHub org admin.

### Red Hat registry login

The Red Hat downstream Ansible Dev Tools image is hosted on `registry.redhat.io`,
which requires authentication. Log in with your
[Red Hat account](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.7/install-con_devtools_requirements#devtools-setup-registry-redhat-io):

```bash
podman login registry.redhat.io
```

Or if using Docker:

```bash
docker login registry.redhat.io
```

> This is different from the upstream starter kit, which uses
> `registry.access.redhat.com` (unauthenticated). The ADT image requires a Red
> Hat login.

### Tokens to collect before starting

Gather these before you open the dev container — you will need all three:

| What | Where to get it |
|------|-----------------|
| **Red Hat Automation Hub API token** | [console.redhat.com](https://console.redhat.com/ansible/automation-hub) → Automation Hub → API token |
| **Customer PAH token** | Your Private Automation Hub UI → Settings → API Token |
| **AAP dev credentials** | URL, service-account username, and password for your dev AAP 2.7 |

## Clone from corporate GitHub

Clone **inside the WSL2 filesystem**, not on the Windows `C:` drive — this
gives faster file I/O, correct line endings, and a real Linux shell as a
fallback:

```bash
gh repo clone YOUR-ORG/aap_config
cd aap_config
code .
```

## Dev container with Red Hat Ansible Dev Tools

The upstream starter kit ships a custom UBI9 Containerfile with pip-installed
tooling. For a corporate environment, use the **Red Hat downstream Ansible Dev
Tools (ADT) image** from `registry.redhat.io` instead — it is pre-built,
supported, and includes ansible-core, ansible-lint, ansible-navigator, yamllint,
and other dev tools out of the box.

### Method 1 — scaffold via the Ansible extension (recommended)

Follow the
[Red Hat procedure](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.7/install-proc_devtools_install_container):

1. Open VS Code in your project directory.
2. Click the **Ansible** icon in the activity bar.
3. In **Ansible Development Tools**, scroll to **ADD** and select **Devcontainer**.
4. Select the **Downstream** container image.
5. Click **Reopen in Container** when prompted (or use the Remote icon →
   "Reopen in Container").
6. Select the Podman or Docker variant matching your container runtime.

### Method 2 — manual devcontainer.json

If you prefer to configure manually, create or replace
`.devcontainer/devcontainer.json`:

```json
{
  "name": "AAP Config-as-Code (ADT)",
  "image": "registry.redhat.io/ansible-automation-platform-2.7/ansible-dev-tools-rhel8:latest",
  "postCreateCommand": "bash .devcontainer/post-create.sh",
  "containerEnv": {
    "ANSIBLE_FORCE_COLOR": "1"
  },
  "remoteEnv": {
    "AH_TOKEN": "${localEnv:AH_TOKEN}",
    "PAH_TOKEN": "${localEnv:PAH_TOKEN}",
    "PAH_URL": "${localEnv:PAH_URL}"
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "redhat.ansible",
        "redhat.vscode-yaml",
        "GitHub.copilot",
        "GitHub.copilot-chat"
      ],
      "settings": {
        "files.eol": "\n"
      }
    }
  }
}
```

> **Confirm the image name.** The path above
> (`ansible-automation-platform-2.7/ansible-dev-tools-rhel8`) should be verified
> at the [Red Hat container catalog](https://catalog.redhat.com/software/containers/search).
> The image may be `rhel9` for newer builds.

### Things to know about the ADT image

- **UBI Minimal base** — the package manager is `microdnf`, not `dnf` or `yum`.
  If you need to install additional packages, use `microdnf install`.
- **`gh` CLI is not pre-installed.** Install it in your `post-create.sh` or
  add a layered Containerfile:
  ```dockerfile
  FROM registry.redhat.io/ansible-automation-platform-2.7/ansible-dev-tools-rhel8:latest
  USER 0
  RUN microdnf -y install tar && microdnf clean all
  # Install gh CLI from tarball (same approach as the upstream kit's Containerfile)
  ARG GH_VERSION=2.96.0
  RUN set -eux; \
      case "$(uname -m)" in \
        x86_64)  gh_arch=amd64 ;; \
        aarch64) gh_arch=arm64 ;; \
      esac; \
      curl -fsSL -o /tmp/gh.tar.gz \
        "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${gh_arch}.tar.gz"; \
      tar -xzf /tmp/gh.tar.gz -C /usr/local --strip-components=1; \
      rm -f /tmp/gh.tar.gz
  USER default
  ```
- **Node.js / Copilot CLI** — the
  `ghcr.io/devcontainers/features/node:1` dev container feature may not work on
  UBI Minimal (it uses apt-based install scripts). Either install Node via
  `microdnf` in a layered Containerfile, or skip the Copilot CLI and use
  Copilot Chat directly in VS Code — the AI-assisted prompts work the same way.
- **ansible-core version** — the ADT image for AAP 2.7 ships ansible-core
  2.18.x, which is the correct baseline for AAP 2.7 targets. This differs from
  the upstream starter kit's 2.16 pin (which targets AAP 2.6).

### Open the container

Once your `devcontainer.json` is ready:

1. In VS Code, open the Command Palette and select **Dev Containers: Reopen in
   Container**.
2. Wait for the container to build and the post-create script to run.
3. Verify the tooling:

```bash
ansible --version
ansible-lint --version
```

## ~/.ansible.cfg — dual hub configuration

This is the critical piece. The `~/.ansible.cfg` inside the container tells
`ansible-galaxy` where to find collections. For a corporate setup, you need
**two sources**: your internal PAH (preferred) and Red Hat's Automation Hub
(fallback).

> **Hard rule:** this config goes in `~/.ansible.cfg` **inside the container**.
> It is never committed to the repo, and there is **no project-local
> `ansible.cfg`** — that would shadow the real one and break collection
> installs. See [AGENTS.md](../AGENTS.md) for why.

### The example

```ini
[galaxy]
server_list = customer_certified, customer_validated, rh_certified, rh_validated, community

[galaxy_server.customer_certified]
url = https://pah.example.internal/api/galaxy/content/published/
token = <customer-pah-token>

[galaxy_server.customer_validated]
url = https://pah.example.internal/api/galaxy/content/validated/
token = <customer-pah-token>

[galaxy_server.rh_certified]
url = https://console.redhat.com/api/automation-hub/content/published/
auth_url = https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token
token = <rh-ah-token>

[galaxy_server.rh_validated]
url = https://console.redhat.com/api/automation-hub/content/validated/
auth_url = https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token
token = <rh-ah-token>

[galaxy_server.community]
url = https://galaxy.ansible.com/
```

### How it works

- **Customer PAH entries come first** in `server_list` so `ansible-galaxy`
  prefers content from your internal hub. If a collection is not found there,
  it falls back to Red Hat Automation Hub, then community Galaxy.
- **Customer PAH uses a simple token** (from your PAH UI → Settings → API
  Token) — no `auth_url` needed.
- **Red Hat Automation Hub uses SSO-based auth** — the `auth_url` handles the
  token exchange automatically.
- **One token per hub.** The same customer PAH token covers both the
  `content/published/` (certified) and `content/validated/` (validated)
  endpoints. Same for the Red Hat AH token.

### Setting this up in post-create.sh

The upstream kit's `post-create.sh` already writes `~/.ansible.cfg` at container
creation time. To support the dual-hub config, set these environment variables
on your Windows host **before** opening the dev container:

```powershell
setx AH_TOKEN  "your-red-hat-automation-hub-token"
setx PAH_TOKEN "your-private-automation-hub-token"
setx PAH_URL   "https://pah.example.internal/api/galaxy"
```

Restart your terminal (or VS Code) after `setx` so the values take effect. The
`devcontainer.json` above passes these into the container via `remoteEnv`.

Then modify `post-create.sh` to use them. Replace the `~/.ansible.cfg` heredoc
section with:

```bash
PAH_BASE_URL="${PAH_URL:-https://pah.example.internal/api/galaxy}"

cat > "${ANSIBLE_CFG}" <<EOF
[galaxy]
server_list = customer_certified, customer_validated, rh_certified, rh_validated, community

[galaxy_server.customer_certified]
url = ${PAH_BASE_URL}/content/published/
token = ${PAH_TOKEN}

[galaxy_server.customer_validated]
url = ${PAH_BASE_URL}/content/validated/
token = ${PAH_TOKEN}

[galaxy_server.rh_certified]
url = ${AH_CERTIFIED_URL}
auth_url = ${AH_AUTH_URL}
token = ${AH_TOKEN}

[galaxy_server.rh_validated]
url = ${AH_VALIDATED_URL}
auth_url = ${AH_AUTH_URL}
token = ${AH_TOKEN}

[galaxy_server.community]
url = https://galaxy.ansible.com/
EOF
chmod 600 "${ANSIBLE_CFG}"
```

> The upstream `post-create.sh` already defines `AH_CERTIFIED_URL`,
> `AH_VALIDATED_URL`, and `AH_AUTH_URL` with sensible defaults. You only add
> the `PAH_*` variables and the `customer_*` server blocks.

## Install collections

With `~/.ansible.cfg` pointing at both hubs, install the pinned collections:

```bash
ansible-galaxy collection install -r collections/requirements.yml
```

The four collections this kit uses, and where they come from:

| Collection | Version | Hub endpoint |
|------------|---------|--------------|
| `ansible.platform` | 2.7.20260604 | Certified (`content/published/`) |
| `ansible.controller` | 4.8.0 | Certified (`content/published/`) |
| `infra.aap_configuration` | 4.7.0 | Validated (`content/validated/`) |
| `infra.aap_configuration_extended` | 4.9.1 | Validated (`content/validated/`) |

Each will resolve from your customer PAH first (if synced there), then fall
back to Red Hat Automation Hub. If your PAH does not yet have these collections
synced, the Red Hat AH fallback will handle it — but we recommend syncing them
to your PAH so the environment works even without external connectivity.

Verify:

```bash
ansible-galaxy collection list | grep -E 'infra.aap_configuration|ansible.platform|ansible.controller'
```

You should see all four collections with the versions listed above.

## First use case — export from dev AAP 2.7

With the environment running and collections installed, you are ready to export.
See [runbook 02](runbooks/02-export.md) for full details and troubleshooting —
this section adapts those steps for the `dev` environment.

### 1. Set up connection credentials

```bash
cp inventory/group_vars/dev/connection.yml.example inventory/group_vars/dev/connection.yml
```

Edit `connection.yml` and replace the placeholder with your dev AAP gateway URL:

```yaml
---
aap_hostname: "https://aap-dev.example.internal"
aap_validate_certs: true
```

> If your AAP instance uses a private CA certificate, set
> `aap_validate_certs: false` to skip TLS verification. The proper fix is to
> add your CA cert to the container's trust store.

### 2. Set up and encrypt secrets

```bash
cp inventory/group_vars/dev/secrets.yml.example inventory/group_vars/dev/secrets.yml
```

Edit `secrets.yml` and fill in your AAP service-account credentials:

```yaml
---
aap_username: "CHANGEME"
aap_password: "CHANGEME"

vaulted_subscriptions_client_id: "CHANGEME"
vaulted_subscriptions_client_secret: "CHANGEME"
```

Then encrypt:

```bash
ansible-vault encrypt inventory/group_vars/dev/secrets.yml --vault-id dev@prompt
```

Optionally, save the vault password to a file so you don't retype it every run:

```bash
mkdir -p ~/secrets && chmod 700 ~/secrets
echo 'your-vault-password' > ~/secrets/.vault_pass_dev && chmod 600 ~/secrets/.vault_pass_dev
```

### 3. Run the export

```bash
ansible-playbook playbooks/export.yml -i inventory --limit dev \
  --vault-id dev@prompt
```

Or with a vault password file:

```bash
ansible-playbook playbooks/export.yml -i inventory --limit dev \
  --vault-id dev@~/secrets/.vault_pass_dev
```

### 4. Verify

Check that the export created files under `exports/`:

```bash
ls exports/dev/
```

You should see folders per organization with YAML files for each exported
object. Open a credential file — secret fields should read
`{{ vaulted_... }}`, never a real password.

Run the secret-hygiene scan:

```bash
bash utilities/scan-exports.sh
```

It should print `scan-exports: OK`. If it reports a failure, see
[runbook 02 → If it went wrong](runbooks/02-export.md#if-it-went-wrong).

## What's next

The exported objects are now in your Git repo under `exports/`. From here:

- **Curate objects into `inventory/group_vars/`** — pick the objects you want
  to manage as code, rename their variables to the `_all` / `_<env>` suffix
  convention. See [runbook 03](runbooks/03-curate.md). *(Not covered in this
  document.)*
- **Secrets and vault** — manage AAP credentials and CaC object secrets. See
  [runbook 04](runbooks/04-secrets.md).
- **Branch, PR, and merge** — the Git workflow for getting changes reviewed
  and merged. See [runbook 05](runbooks/05-branch-pr.md).

For additional config-as-code patterns — including PAH content sync and demo
automation — see the
[sales.demos](https://github.com/ericcames/sales.demos) repo.

For enterprise-scale considerations (CI/CD runners, environments, approvals,
active/passive topology), see
[Going to production](going-to-production.md).

## References

Docs and tools used in creating this guide:

- [Red Hat: Install Ansible dev tools on a container inside VS Code](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.7/install-proc_devtools_install_container) — the upstream ADT container procedure
- [Red Hat: Authenticating with registry.redhat.io](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.7/install-con_devtools_requirements#devtools-setup-registry-redhat-io) — Red Hat registry login
- [Red Hat container catalog](https://catalog.redhat.com/software/containers/search) — verify ADT image name and tags
- [Red Hat Automation Hub](https://console.redhat.com/ansible/automation-hub) — API token for certified/validated collections
- [VS Code Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- [Red Hat Ansible VS Code extension](https://marketplace.visualstudio.com/items?itemName=redhat.ansible)
- [GitHub CLI](https://cli.github.com/manual/) — authenticate to corporate GitHub Enterprise
- [aap_config starter kit](https://github.com/ericcames/aap_config) — the upstream kit this repo is based on
- [sales.demos](https://github.com/ericcames/sales.demos) — another config-as-code example with PAH content sync
