# Runbook 01 — Open the dev container

> **Skill:** `/setup-workstation` runs this whole runbook (it covers runbooks 00–01) for you, in Claude Code or GitHub
> Copilot CLI. Read the steps first, then let it drive.

> **Status:** the "Reopen in Container" path below is a work in progress — it has needed
> several recent fixes (`remoteUser`, registry auth) and isn't fully validated end-to-end
> yet. The **[WSL-native alternative](#alternative-wsl-native-no-container)** below (no
> container, work directly in the WSL2 distro) is confirmed working and is what's actually
> used day-to-day right now.

## You will need

Runbook 00 complete (GitHub login, container runtime, VS Code). If you prefer a
plain terminal without VS Code, see the **devcontainer CLI** alternative at the
end of [runbook 00](00-prerequisites.md#alternative-no-vs-code-devcontainer-cli).

## You will learn

What "clone" means, and how the dev container gives you Ansible + all tools with
nothing installed on Windows directly.

The container is built on **Red Hat's Ansible Dev Tools image** for AAP 2.7, so
you get the same toolchain Red Hat ships to customers — `ansible-core`,
`ansible-lint`, `yamllint`, `ansible-navigator`, `ansible-creator`, `molecule`,
`ansible-builder` — plus the `gh` CLI and Node, which this repo layers on top.

## Steps

1. **Clone the repo** (get your own copy on your machine):
   ```bash
   gh repo clone <your-org>/aap_config
   cd aap_config
   code .
   ```
   > **AI Assist:** [PROMPTS.md → rb01](../ai/PROMPTS.md#rb01).

2. **Reopen in Container.** VS Code will detect `.devcontainer/` and pop up
   "Reopen in Container" — click it. (Or Command Palette → *Dev Containers:
   Reopen in Container*.) First time takes a few minutes to build.

3. **Answer the post-create prompt.** It asks for your **Automation Hub token**
   (from console.redhat.com → Automation Hub → API token). Paste it. This writes
   `~/.ansible.cfg` and installs the pinned collections — inside the container's
   home directory on the devcontainer path, or your WSL home directory on the
   [WSL-native path](#alternative-wsl-native-no-container). *(You can skip and
   re-run `bash .devcontainer/post-create.sh` later, from either path.)*

   > No prompt appeared? That is the good case — it only asks when `AH_TOKEN` is
   > unset. In [Codespaces](../codespaces.md) with the secret configured, or
   > locally if you exported the variable before launching VS Code, the
   > collections install unattended.

   The simple, single-token case (no customer Private Automation Hub — see
   [runbook 00](00-prerequisites.md#collections-from-a-customers-private-automation-hub)
   if you need that) writes this:

   ```ini
   [galaxy]
   server_list = rh_certified, rh_validated, community

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

   Never commit this file or paste a real token into any doc/PR — see
   [AGENTS.md](../../AGENTS.md).

4. When it finishes, it prints **"Next step: open docs/runbooks/02"**.

## How you know it worked

Inside the container terminal:
```bash
ansible --version                       # shows ansible-core 2.16.x
ansible-navigator --version             # proves you are on the Dev Tools image
gh --version                            # the layered GitHub CLI, used by runbook 05
ansible-galaxy collection list | grep infra.aap_configuration   # shows 4.7.0
```

## If it went wrong

- **Collections didn't install** → your Hub token was blank or wrong. Re-run
  `bash .devcontainer/post-create.sh` and paste a fresh token.
- **Line-ending weirdness / scripts fail** → the repo enforces LF via
  `.gitattributes`; make sure you cloned fresh (don't copy files from a Windows
  editor that rewrote them to CRLF).
- **Copilot CLI missing** → optional; use Copilot Chat in VS Code or install the
  `gh copilot` extension. AI Assist prompts work anywhere.

## Alternative: WSL-native (no container)

**Currently the working path** — skip "Reopen in Container" entirely and work directly in
the WSL2 distro through VS Code's **WSL Remote** connection (title bar reads
`[WSL: <distro>]`, not `[Dev Container: ...]`). This is what's actually validated working
right now, while the devcontainer path above is still being hardened.

1. Open the repo in VS Code via WSL Remote instead of reopening in a container:
   ```bash
   # from inside your WSL2 distro
   cd ~/git-repos/aap_config   # wherever you cloned it inside the WSL filesystem
   code .
   ```
   VS Code attaches to the WSL distro directly — do **not** accept a "Reopen in Container"
   prompt if VS Code offers one. Confirm the connection via the remote indicator in the
   bottom-left status bar:

   ![VS Code bottom-left status bar showing the "WSL: podman-AAP" remote indicator](../images/vscode-wsl-remote-indicator.png)

2. Install tooling directly in the WSL distro instead of relying on
   `.devcontainer/post-create.sh` (which only runs on container build):
   - Ansible tooling: on the container path, `ansible-core`/`ansible-lint`/
     `ansible-navigator`/etc. come pre-installed from the Containerfile's base image
     (`registry.redhat.io/.../ansible-dev-tools-rhel9`). A bare WSL distro has none of
     that, so install `pip` first, then the same
     [`ansible-dev-tools`](https://github.com/ansible/ansible-dev-tools) package the
     base image ships (`pip install ansible-dev-tools`, or `pipx install
     ansible-dev-tools`). Only *after* that does `bash .devcontainer/post-create.sh`
     make sense to run — it just installs collections per
     [collections/requirements.yml](../../collections/requirements.yml), it doesn't
     install Ansible itself.

     ```text
     $ adt --version
     ansible-builder                  3.1.1
     ansible-core                     2.21.3
     ansible-creator                  26.8.0
     ansible-dev-environment          26.8.0
     ansible-dev-tools                26.8.0
     ansible-lint                     26.8.0
     ansible-navigator                26.8.0
     ansible-sign                     0.1.6
     molecule                         26.8.0
     pytest-ansible                   26.8.0
     tox-ansible                      26.8.0
     ```
   - GitHub Copilot CLI: `npm install -g @github/copilot`, or `gh extension install
     github/gh-copilot`.
   - Claude Code CLI: install directly in WSL following Anthropic's standard install
     steps.
   - **VS Code extensions**: `.devcontainer/devcontainer.json` normally installs these
     automatically on container build (`redhat.ansible`, `redhat.vscode-yaml`,
     `GitHub.copilot`, `GitHub.copilot-chat`) — on the WSL-native path there's no
     container build step to do that, so install them by hand from the Extensions
     panel once VS Code is connected via WSL Remote:

     ![VS Code Extensions Marketplace showing the Red Hat "Ansible" extension installed and enabled on "WSL: podman-AAP"](../images/vscode-ansible-extension-wsl.png)

3. Set up `~/.ansible.cfg`, your vault password file(s), and `~/.config/containers`
   (registry auth) directly under your **WSL home directory** — not inside the repo, and
   not inside a container. This is a deliberate choice: WSL2 runs local to the Windows
   host only, so secrets placed there don't risk being baked into a container image,
   build context, or anything that could leave the machine. See
   [04-secrets.md](04-secrets.md) for the vault/`connection.yml` setup itself.

   ![GitHub Copilot CLI running in a VS Code terminal tab, connected via WSL Remote (title bar shows "aap_config [WSL: podman-AAP]")](../images/copilot-cli-wsl-vscode.png)

### How you know it worked (WSL-native)

Same checks as the container path, run directly in the WSL terminal — no "enter
container" step needed:
```bash
ansible --version
ansible-galaxy collection list | grep infra.aap_configuration
gh copilot --version   # or: copilot --version, depending on which Copilot CLI you installed
```

```text
$ ansible-galaxy collection list | grep infra.aap_configuration
[WARNING]: Collection at '/usr/local/lib/python3.14/site-packages/ansible/_internal/ansible_collections/ansible/_protomatter' does not have a
MANIFEST.json file, nor has it galaxy.yml: cannot detect version.
infra.aap_configuration               4.7.0
infra.aap_configuration_extended      4.9.1
```

The `[WARNING]` about `ansible/_protomatter` is harmless — an internal ansible-core
bundled pseudo-collection with no version metadata, unrelated to this repo. As long
as both `infra.aap_configuration` lines show up with the versions pinned in
[collections/requirements.yml](../../collections/requirements.yml), you're good.

Next: [02-export.md](02-export.md).
