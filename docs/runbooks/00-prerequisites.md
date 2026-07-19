# Runbook 00 — Prerequisites

## You will need

- A **GitHub account** with access to your enterprise organization, and **GitHub
  Copilot** (a seat — we check it below).
- **Docker Desktop** *or* **Podman Desktop** on your Windows machine.
- **VS Code** with the **Dev Containers** extension.
- A **Red Hat login** for Automation Hub (or your org's private hub URL + token).
- **AAP connection details** for the production (Azure) instance: URL, a service
  account username, and password.

## You will learn

What each account/tool is for, and how to confirm your Copilot seat works.

## Preflight: can this Windows desktop run the dev container?

The dev container needs a Linux backend on Windows. Both Docker Desktop and
Podman Desktop run their containers on **WSL2** (or Hyper-V). On a locked-down
corporate desktop, WSL2 or hardware virtualization is sometimes disabled by IT
policy or firmware — and if it is, the dev container will not start at all.

Run this check **first**, before installing a container engine. It takes two
minutes and tells you whether this desktop can use the local dev-container path
or needs the fallback further down.

> Not on Windows? Skip this section — see
> [Running on Fedora with Podman](#running-on-fedora-with-podman) (or your
> platform's container setup) instead.

### Run the checks

Open **PowerShell** and run:

```powershell
winver                              # Windows 10 2004+ or Windows 11 required
wsl --status                        # is WSL present? what is the default version?
wsl --version                       # WSL app version — blank means not installed
systeminfo | findstr /i "Hyper-V"   # virtualization / Hyper-V requirements
```

Then the two checks that decide it in a managed environment (the second needs an
elevated / admin PowerShell):

```powershell
# Are the required Windows features available and enabled?
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux, VirtualMachinePlatform

# Is WSL disabled by group policy? (no output / not-found = not policy-blocked)
Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WSL" -ErrorAction SilentlyContinue
```

Also confirm you can run commands as **administrator** (or that IT can enable
the features for you via Intune/GPO) — `wsl --install` requires elevation.

### Reading the result

**WSL2 is available or can be enabled** → you are good, and you should prefer
WSL2. Enable it if needed:

```powershell
wsl --install     # installs WSL2 + a default Linux distro (reboot after)
```

Then clone the repo **inside** the WSL2 filesystem (e.g. under your Linux home,
`\\wsl$\...`), not on the Windows `C:` drive, and open the dev container from
there. This gives much faster file I/O, correct line endings and permissions,
and a real Linux shell as a fallback. Continue with the container-engine setup
below.

**WSL2 and Hyper-V are blocked by policy or firmware** → the local dev-container
path will not work on this desktop. Do not invest in the local setup; switch to
one of these instead:

- **[GitHub Codespaces](../codespaces.md)** — the same `.devcontainer` runs in
  the cloud with no local engine, WSL, or admin rights required. This is the
  smoothest fallback because the kit's dev container config is reused as-is.
- **A shared Linux dev host** — a jump host or VM (for example RHEL or Fedora)
  where users run the dev container, or the tooling directly, over SSH.

Decide this **before** building out the local runbook flow, so a desktop that
can never run the container is caught at the start rather than midway through.

### Capture the result

If the desktop fails, the answer is worth recording rather than repeating from
memory. Paste this block into PowerShell (elevated, so the feature check
returns) and it prints a short PASS/FAIL summary you can drop into a ticket or
send to whoever is helping you with the rollout:

```powershell
$os   = Get-CimInstance Win32_OperatingSystem
$cs   = Get-CimInstance Win32_ComputerSystem
$wsl  = (Get-Command wsl.exe -ErrorAction SilentlyContinue) -ne $null
$feat = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux, VirtualMachinePlatform -ErrorAction SilentlyContinue
$pol  = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WSL" -ErrorAction SilentlyContinue
$adm  = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

"aap_config dev-container preflight — $(Get-Date -Format s)"
"  OS                : $($os.Caption) build $($os.BuildNumber)"
"  Virtualization    : $(if ($cs.HypervisorPresent) { 'PASS (hypervisor present)' } else { 'FAIL (not enabled in firmware/BIOS)' })"
"  WSL command       : $(if ($wsl) { 'PASS' } else { 'FAIL (not installed)' })"
foreach ($f in $feat) { "  Feature $($f.FeatureName) : $($f.State)" }
"  WSL group policy  : $(if ($pol) { 'FAIL (policy key present — ask IT)' } else { 'PASS (no policy block)' })"
"  Admin rights      : $(if ($adm) { 'PASS' } else { 'NOT ELEVATED (re-run as admin to be sure)' })"
```

Any `FAIL` on virtualization or the WSL policy key means this desktop needs
Codespaces or a shared Linux host, not a local container engine. Send the block
as-is — it says exactly which control is blocking, which is what IT needs to act
on.

## Steps

1. **Install a container runtime.** Docker Desktop is simplest; Podman Desktop is
   the license-free alternative. If you use Podman, set VS Code setting
   `dev.containers.dockerPath` to `podman`.

2. **Install VS Code + the Dev Containers extension** (and, when prompted later,
   the GitHub Copilot extensions).

3. **Sign in to GitHub from the terminal:**
   ```bash
   gh auth login       # choose HTTPS, authenticate in the browser (device flow)
   ```

4. **Check your Copilot seat:**
   ```bash
   gh api /user/copilot_billing
   ```
   Seat details = you're good. A `404` = no seat; ask your GitHub org admin
   (org Settings → Copilot → Access).

   > **AI Assist:** see [PROMPTS.md → rb00](../ai/PROMPTS.md#rb00) — paste the
   > 404 prompt if you hit that.

## How you know it worked

`gh auth status` shows you logged in, and `gh api /user/copilot_billing` returns
seat details (not 404). Docker/Podman Desktop is running.

## If it went wrong

- **404 on the Copilot check** → no seat; the runbooks still work with Copilot
  Chat in VS Code or Claude Code, since every AI Assist prompt is plain text.
- **Corporate proxy blocks Copilot** → try `curl -v https://api.githubcopilot.com`
  to see if TLS is being intercepted; report it to your admin. Fall back to
  Copilot Chat or Claude Code.
- **Podman "cannot connect"** → ensure the Podman machine is started
  (`podman machine start`) and `dev.containers.dockerPath` is set to `podman`.

## Running on Fedora with Podman

The dev container runs the same on Fedora as on Windows — the export tooling
lives inside the container, so the runbooks all apply unchanged. There are three
one-time host setup steps and one thing to be aware of.

### 1. Use Podman as the container engine

Fedora Workstation usually ships Podman already. Confirm with `podman --version`;
if it is missing, install it with `sudo dnf install -y podman`. You do not need
Podman Desktop — the CLI is enough.

Tell VS Code to use Podman instead of Docker. In *Settings* (JSON or UI), set:

```json
"dev.containers.dockerPath": "podman"
```

### 2. Export your Automation Hub token before opening the container

[`.devcontainer/devcontainer.json`](../../.devcontainer/devcontainer.json) passes
`AH_TOKEN` from your host shell into the container, and
[`post-create.sh`](../../.devcontainer/post-create.sh) uses it to install the
certified collections. If the token is not set, the setup script prompts for it —
and if you leave the prompt blank, it skips the collections and you cannot run
the export.

Set it in the shell you launch VS Code from, then start VS Code from that same
shell so it inherits the value:

```bash
export AH_TOKEN='paste-your-token-here'
code .
```

Get a token at console.redhat.com → Automation Hub → API token. To avoid doing
this every time, add the `export` line to your `~/.bashrc` (note: this stores the
token in a plaintext dotfile — only do it on a machine you trust).

### 3. SELinux and bind mounts

Fedora runs SELinux in enforcing mode. Podman relabels the mounted repo
automatically, so this normally just works. If the container cannot read the repo
files, an SELinux mount label is the usual cause — check `podman` mount flags
before anything else.

### File ownership note

Because the container runs as a non-root user (`USER default`, uid 1001, in
[`.devcontainer/Containerfile`](../../.devcontainer/Containerfile)), rootless
Podman maps it into a high subuid range, and files it writes into the
bind-mounted repo (for example under `exports/`) can end up owned by an
unexpected UID on the host. If you hit that, add this to your **local,
uncommitted** copy of `.devcontainer/devcontainer.json`:

```json
"runArgs": ["--userns=keep-id"]
```

Do not commit that line — it is Podman-specific and would break the Windows and
Docker users this kit targets.

## Alternative: no VS Code (devcontainer CLI)

If you prefer a plain terminal over VS Code, you can build and enter the dev
container using the **devcontainer CLI**. Everything works the same — you just
won't get VS Code extensions (Ansible language server, Copilot inline
completions). AI Assist prompts still work via Copilot Chat in the terminal
(`gh copilot`) or Claude Code.

1. **Install Node.js** (needed for the CLI):
   ```powershell
   winget install OpenJS.NodeJS
   ```
2. **Install the devcontainer CLI:**
   ```powershell
   npm install -g @devcontainers/cli
   ```
3. **Set your Automation Hub token** so it passes into the container:
   ```powershell
   setx AH_TOKEN "your-token-from-console.redhat.com"
   ```
   Restart your terminal after `setx`.
4. **Clone and launch:**
   ```powershell
   gh repo clone <your-org>/aap_config
   cd aap_config
   devcontainer up --workspace-folder .
   devcontainer exec --workspace-folder . bash
   ```
5. Inside the container, verify setup:
   ```bash
   ansible --version
   ansible-galaxy collection list | grep infra.aap_configuration
   ```
   Then continue from [runbook 02](02-export.md).

Next: [01-devcontainer.md](01-devcontainer.md).
