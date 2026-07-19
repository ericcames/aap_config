---
name: setup-workstation
description: Get a person's laptop ready to use this kit — run the Windows WSL2 and virtualization preflight, install a container engine and VS Code, sign in with gh, confirm a Copilot seat, set AH_TOKEN, clone the repo, and open the VS Code dev container. Use when someone is brand new to this repo, cannot get the dev container to build or open, or is missing the accounts and tools the runbooks assume. Mirrors docs/runbooks/00-prerequisites.md and docs/runbooks/01-devcontainer.md.
---

# Set up a workstation for this kit

Follow the standards in `AGENTS.md`. This mirrors
`docs/runbooks/00-prerequisites.md` and `docs/runbooks/01-devcontainer.md`.

## Where you are running

Most of this happens on the user's **host machine** (Windows PowerShell, or a
Fedora/macOS shell) *before* the container exists. Guide them command by command
and ask them to paste the output back — do not assume you can run host commands
yourself, especially not from inside the container.

## Steps

1. **Ask two questions first:** which platform (Windows, Fedora, macOS), and
   local container engine or **GitHub Codespaces**. Codespaces skips steps 2-3
   entirely — see `docs/codespaces.md` — and `AH_TOKEN` becomes a Codespaces
   secret instead of a shell variable.

2. **Windows preflight — before installing anything.** The dev container needs a
   Linux backend, and on a locked-down corporate desktop WSL2 or hardware
   virtualization is often disabled by policy or firmware. In PowerShell:
   ```
   winver
   wsl --status
   wsl --version
   systeminfo | findstr /i "Hyper-V"
   ```
   Then, in an **elevated** PowerShell:
   ```
   Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux, VirtualMachinePlatform
   Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WSL" -ErrorAction SilentlyContinue
   ```
   Reading it: WSL2 available or enableable → `wsl --install`, then clone
   **inside** the WSL2 filesystem. Virtualization off or WSL policy-blocked →
   stop and switch to Codespaces or a shared Linux host. Runbook 00 has a
   copy-paste block that prints a PASS/FAIL summary suitable for an IT ticket —
   offer it.

3. **Container engine and editor.** Docker Desktop or Podman Desktop, plus VS
   Code with the **Dev Containers** extension. With Podman, set VS Code's
   `dev.containers.dockerPath` to `podman`. On Fedora the Podman CLI alone is
   enough.

4. **GitHub sign-in and Copilot seat:**
   ```
   gh auth login          # HTTPS, device flow
   gh api /user/copilot_billing
   ```
   Seat details means it works. A `404` means no seat — ask the GitHub
   organization admin (Settings → Copilot → Access). **A 404 is not a blocker:**
   every AI Assist prompt is plain text and works in Copilot Chat or Claude Code.

5. **Automation Hub token.** console.redhat.com → Automation Hub → API token.
   Export it in the shell that launches VS Code, so the container inherits it:
   ```
   export AH_TOKEN='<token>'
   code .
   ```
   On Windows, `setx AH_TOKEN "<token>"` and restart the terminal. One token
   covers certified and validated content; a private hub can override
   `AH_CERTIFIED_URL` / `AH_VALIDATED_URL`. Without a token the container still
   builds — but no collections install, so nothing can deploy.

6. **Clone and open:**
   ```
   gh repo clone <your-org>/aap_config
   cd aap_config
   code .
   ```
   Then "Reopen in Container" (or Command Palette → *Dev Containers: Reopen in
   Container*). The first build takes a few minutes. If `AH_TOKEN` was set,
   post-create runs unattended; if not, it prompts for the token.

7. **Verify inside the container:**
   ```
   ansible --version                                              # ansible-core 2.16.x
   ansible-galaxy collection list | grep infra.aap_configuration  # 4.7.0
   ```
   If the collections are missing, the token was blank or wrong — re-run
   `bash .devcontainer/post-create.sh` with a fresh one.

8. **Hand off** to `docs/runbooks/02-export.md` or the `/export-aap` skill.

## Do not

- Do not suggest installing Ansible directly on Windows — the dev container is
  the supported path.
- Do not install a container engine before the WSL2/virtualization preflight
  passes.
- Do not echo, log, or commit `AH_TOKEN`. Putting it in a shell profile is the
  user's own decision on their own machine — say so, don't do it for them.
- Do not create a project-local `ansible.cfg`; post-create writes `~/.ansible.cfg`
  **inside** the container home for exactly this reason.
- Do not commit Podman-specific `devcontainer.json` tweaks such as
  `runArgs: ["--userns=keep-id"]` — they break the Windows/Docker users this kit
  targets. Keep them local and uncommitted.
- Do not use this skill to configure an AAP instance's hostname or credentials —
  that is `/vault-secrets`.
