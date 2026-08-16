---
name: setup-workstation
description: Get a person's laptop ready to use this kit — run the Windows WSL2 and virtualization preflight, sign in with gh, confirm a Copilot seat, set AH_TOKEN, and get either the WSL-native environment (recommended, currently working) or the VS Code dev container (work in progress) running. Use when someone is brand new to this repo, cannot get their environment to build or open, or is missing the accounts and tools the runbooks assume. Mirrors docs/runbooks/00-prerequisites.md and docs/runbooks/01-dev-environment.md.
---

# Set up a workstation for this kit

Follow the standards in `AGENTS.md`. This mirrors
`docs/runbooks/00-prerequisites.md` and `docs/runbooks/01-dev-environment.md`.

> **Status:** the devcontainer path (step 3, and "Reopen in Container" in step 6)
> is a work in progress — it has needed several recent fixes and isn't fully
> validated end-to-end. The **WSL-native path** (step 6, WSL-native branch) is
> confirmed working and is what's actually used day-to-day right now. Default to
> it unless the user specifically needs the container itself (e.g. testing
> devcontainer changes).

## Where you are running

Most of this happens on the user's **host machine** (Windows PowerShell) before
their environment exists, then inside their **WSL2 distro** once it does (WSL-native
path) or inside the **container** (devcontainer path). Guide them command by
command and ask them to paste the output back — do not assume you can run host
commands yourself, especially not from inside a different container or WSL distro
than your own.

## Steps

1. **Ask first:** local setup, or **GitHub Codespaces**? Codespaces skips most of
   this — see `docs/codespaces.md` — and `AH_TOKEN` becomes a Codespaces secret
   instead of a shell variable.

2. **Windows preflight — before installing anything.** The environment needs a
   Linux backend, and on a locked-down corporate desktop WSL2 or hardware
   virtualization is often disabled by policy or firmware. In PowerShell:
   ```
   winver
   wsl --status
   wsl --version
   systeminfo | findstr /i "Hyper-V"
   ```
   Then, in an **elevated** PowerShell (`-FeatureName` takes one name at a
   time — loop, don't pass a comma-separated list):
   ```
   foreach ($name in 'Microsoft-Windows-Subsystem-Linux', 'VirtualMachinePlatform') {
     Get-WindowsOptionalFeature -Online -FeatureName $name
   }
   Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WSL" -ErrorAction SilentlyContinue
   ```
   Reading it: WSL2 available or enableable → `wsl --install`, then clone
   **inside** the WSL2 filesystem. The `Microsoft-Windows-Subsystem-Linux`
   feature can show `Disabled` even when WSL2 works fine (`wsl --status` PASS,
   a distro you can actually use) — modern Store-distributed WSL doesn't always
   depend on that legacy feature. Virtualization off or WSL policy-blocked →
   stop and switch to Codespaces or a shared Linux host. Runbook 00 has a
   copy-paste block that prints a PASS/FAIL summary suitable for an IT ticket —
   offer it.

3. **(Devcontainer path only, WIP) Container engine.** Docker Desktop or Podman
   Desktop, plus VS Code's **Dev Containers** extension. With Podman, set VS
   Code's `dev.containers.dockerPath` to `podman`. Skip entirely if going
   WSL-native — it needs neither.

4. **GitHub sign-in and Copilot seat:**
   ```
   gh auth login          # HTTPS, device flow
   gh api /user/copilot_billing
   ```
   Seat details = an org-assigned Copilot Business/Enterprise plan. A `404` is
   **normal for individual Copilot Free/Pro** — this endpoint only returns data
   for org-assigned seats, it isn't a "do you have Copilot at all" check.
   Confirm Copilot actually works (VS Code extension, Copilot CLI) before
   treating the 404 as a problem; if it genuinely doesn't work, that's when to
   ask the GitHub org admin (Settings → Copilot → Access). Either way, not a
   blocker — every AI Assist prompt is plain text and works in Copilot Chat or
   Claude Code.

5. **(If cloning over SSH instead of HTTPS) SSH key.** Generate it **inside
   WSL**, not on the Windows side — same secrets-locality reasoning as
   `~/.ansible.cfg` below: it stays local to this machine.
   ```
   ssh-keygen -t ed25519 -C "you@example.com"
   cat ~/.ssh/id_ed25519.pub
   ```
   Paste the printed key at github.com/settings/keys, or run
   `gh ssh-key add ~/.ssh/id_ed25519.pub --title "aap_config WSL"`.

6. **Automation Hub token**, then branch by path. Get one at console.redhat.com
   → Automation Hub → API token.

   **WSL-native (recommended):**
   ```
   # inside the WSL2 distro
   export AH_TOKEN='<token>'
   pip install ansible-dev-tools     # or: pipx install ansible-dev-tools
   gh repo clone <your-org>/aap_config && cd aap_config
   bash .devcontainer/post-create.sh # installs collections only — ansible-dev-tools
                                      # above is what installs ansible-core/-lint/etc.
   code .                            # connects via WSL Remote, not a container
   ```
   Confirm the bottom-left VS Code status bar shows `WSL: <distro>`, not
   `Dev Container: ...`. Install the VS Code extensions by hand too — no
   container build step does it for you: `redhat.ansible`, `redhat.vscode-yaml`,
   `GitHub.copilot`, `GitHub.copilot-chat`. Copilot CLI:
   `npm install -g @github/copilot` (or `gh extension install github/gh-copilot`).

   **Devcontainer path (WIP):** export it in the shell that launches VS Code so
   the container inherits it:
   ```
   export AH_TOKEN='<token>'
   code .
   ```
   Then "Reopen in Container" (Command Palette → *Dev Containers: Reopen in
   Container*). First build takes a few minutes; if `AH_TOKEN` was set,
   post-create runs unattended, otherwise it prompts for the token.

   Either path: one token covers certified and validated content; a private hub
   can override `AH_CERTIFIED_URL` / `AH_VALIDATED_URL`. Without a token,
   collections don't install and nothing can deploy.

7. **Verify:**
   ```
   ansible --version                                              # or: adt --version (WSL-native)
   ansible-galaxy collection list | grep infra.aap_configuration  # 4.7.0 / 4.9.1
   ```
   Ignore a `[WARNING]` about `ansible/_protomatter` having no MANIFEST.json —
   harmless internal ansible-core noise. If collections are missing, the token
   was blank or wrong — re-run `bash .devcontainer/post-create.sh` with a fresh
   one (from WSL directly, or inside the container, matching whichever path).

8. **Hand off** to `docs/runbooks/02-export.md` or the `/export-aap` skill.

## Do not

- Do not suggest installing Ansible directly on the bare Windows host — WSL2 or
  the dev container are the supported paths, never Windows PowerShell itself.
- Do not install a container engine before the WSL2/virtualization preflight
  passes — or at all, if the user is going WSL-native.
- Do not echo, log, or commit `AH_TOKEN`. Putting it in a shell profile is the
  user's own decision on their own machine — say so, don't do it for them.
- Do not create a project-local `ansible.cfg`; post-create writes
  `~/.ansible.cfg` to the **home directory** — inside the container's home on
  the devcontainer path, or the user's WSL home on the WSL-native path. Never
  the repo.
- Do not commit Podman-specific `devcontainer.json` tweaks such as
  `runArgs: ["--userns=keep-id"]` — they break the Windows/Docker users this kit
  targets. Keep them local and uncommitted.
- Do not use this skill to configure an AAP instance's hostname or credentials —
  that is `/vault-secrets`.
