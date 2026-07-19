# Runbook 03 — Curate objects into group_vars

> **Skill:** `/curate-config` runs this whole runbook for you, in Claude Code or GitHub
> Copilot CLI. Read the steps first, then let it drive.

## You will need

A completed export in `exports/azure/` (runbook 02).

## You will learn

The core Git commands (`status`, `diff`, `add`, `commit`), and how object
variables load implicitly from `inventory/group_vars/`.

## The idea

The raw export is a *snapshot for review*. You choose which objects to actually
manage as code and copy them into `inventory/group_vars/`, renaming their
top-level variable to the suffix convention so they load for the right
environments:

- Shared by every env → `inventory/group_vars/aap/`, key ends in **`_all`**.
- One env only → `inventory/group_vars/<env>/`, key ends in **`_dev`/`_qa`/`_prod`**.

## Steps

1. **Look at an exported object** in VS Code, e.g.
   `exports/azure/<Org>/controller_projects.d/…yaml`.
   > **AI Assist:** [PROMPTS.md → rb03](../ai/PROMPTS.md#rb03) — "explain what each
   > field does".

2. **Copy the objects you want to keep** into the right file, e.g.
   `inventory/group_vars/aap/controller_projects.yml`, and **rename the top key**
   from `controller_projects:` to `controller_projects_all:`.
   > **AI Assist:** [PROMPTS.md → rb03](../ai/PROMPTS.md#rb03) — the rename prompt
   > tells you the exact key and directory.

3. **See what you changed:**
   ```bash
   git status            # which files are new/modified
   git diff              # the exact line-by-line changes
   ```

4. **Stage and commit** the curated files (not the whole `exports/` tree yet):
   ```bash
   git add inventory/group_vars/
   git commit -m "Add controller projects shared across all environments"
   ```

## How you know it worked

`git status` shows your `inventory/group_vars/` files committed. `ansible-lint`
passes:
```bash
ansible-lint
```

## If it went wrong

- **`ansible-lint` complains about the file** → check indentation and that the top
  key uses the `_all`/`_<env>` suffix.
- **Tempted to add `vars_files:` or `include_vars:`** → don't. That's the
  anti-pattern this kit avoids; group_vars load on their own (see AGENTS.md).

Next: [04-secrets.md](04-secrets.md).
