# Running in GitHub Codespaces

Codespaces runs this repo's dev container in the cloud — no local Docker/Podman,
no WSL, no admin rights. It's the fastest way to get a new user (or a prospect in
an eval) to a working environment, and it reuses the same
[`.devcontainer`](../.devcontainer/) as the local path, so everything behaves
identically.

## Launch

Click **Code → Codespaces → Create codespace on main** in the repo, or use the
"Open in Codespaces" badge in the [README](../README.md). The container builds,
`post-create.sh` runs, and you land in a ready environment.

## One-time setup for your org (do this once)

So users never paste a token, set the Automation Hub credentials as **Codespaces
secrets** instead of relying on each user's shell:

1. Go to the repo (or organization) **Settings → Secrets and variables →
   Codespaces**.
2. Add a secret named `AH_TOKEN` (your Automation Hub API token from
   console.redhat.com → Automation Hub → API token).
3. If you use a customer's private hub, also add `AH_CERTIFIED_URL` and/or
   `AH_VALIDATED_URL` (the same overrides `post-create.sh` accepts). The kit
   needs **both** Automation Hub endpoints: certified content
   (`content/published/`) supplies `ansible.platform` and `ansible.controller`,
   validated content (`content/validated/`) supplies the
   `infra.aap_configuration*` roles.
4. Scope the secret to this repository.

Codespaces injects these into every codespace's environment, so `post-create.sh`
picks up `AH_TOKEN` automatically and installs the certified collections with no
prompt.

> Set the secret **before** you create a codespace. Codespaces reads secrets at
> creation time, so a codespace started earlier will not see one you add later —
> create a fresh one, or re-run `bash .devcontainer/post-create.sh` inside the
> existing codespace after exporting the token yourself.

## Faster starts with prebuilds

Enable **prebuilds** so users don't wait for the image to build each time:

1. Repo **Settings → Codespaces → Set up prebuild**.
2. Target the `main` branch and the region(s) your users are in.

Prebuilds cache the heavy work — the `Containerfile` build and the dev container
features. Note that the token-dependent collection install stays per-codespace,
because Codespaces secrets are intentionally not available during prebuild; that
step is quick compared to the image build.

## When to use Codespaces vs local

- **Evals, demos, mixed-skill teams, locked-down desktops** → Codespaces. Zero
  setup, consistent for everyone.
- **A maintainer's own Linux workstation** → local dev container is fine (see the
  Podman guidance in [runbook 00](runbooks/00-prerequisites.md)).
- **GitHub Enterprise Server (self-hosted)** → Codespaces is a GitHub Enterprise
  Cloud capability; on GHES, use a shared Linux dev host instead. Confirm
  availability with your GitHub admin.

## How you know it worked

In the codespace terminal:

```bash
ansible --version
ansible-galaxy collection list | grep infra.aap_configuration
```

You should see `ansible-core` and the pinned collections from
[`collections/requirements.yml`](../collections/requirements.yml). Then continue
from [runbook 02](runbooks/02-export.md).

## If it went wrong

- **`post-create.sh` prompted for a token** → the `AH_TOKEN` secret was not
  visible to this codespace. Confirm it exists under Settings → Secrets and
  variables → Codespaces, that it is scoped to this repository, and that the
  codespace was created *after* you added it.
- **Collections failed to install** → check that the token has not expired (Red
  Hat SSO offline tokens expire after 30 days of no use). Re-run
  `bash .devcontainer/post-create.sh` after updating the secret and rebuilding.
