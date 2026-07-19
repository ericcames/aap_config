# Runbook 01 — Open the dev container

## You will need

Runbook 00 complete (GitHub login, container runtime, VS Code). If you prefer a
plain terminal without VS Code, see the **devcontainer CLI** alternative at the
end of [runbook 00](00-prerequisites.md#alternative-no-vs-code-devcontainer-cli).

## You will learn

What "clone" means, and how the dev container gives you Ansible + all tools with
nothing installed on Windows directly.

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
   (from console.redhat.com → Automation Hub → API token). Paste it. This writes a
   container-local `~/.ansible.cfg` and installs the pinned collections. *(You can
   skip and re-run `bash .devcontainer/post-create.sh` later.)*

   > No prompt appeared? That is the good case — it only asks when `AH_TOKEN` is
   > unset. In [Codespaces](../codespaces.md) with the secret configured, or
   > locally if you exported the variable before launching VS Code, the
   > collections install unattended.

4. When it finishes, it prints **"Next step: open docs/runbooks/02"**.

## How you know it worked

Inside the container terminal:
```bash
ansible --version                       # shows ansible-core 2.16.x
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

Next: [02-export.md](02-export.md).
