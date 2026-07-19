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

Next: [01-devcontainer.md](01-devcontainer.md).
