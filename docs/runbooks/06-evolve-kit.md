# Runbook 06 — Evolve the kit

## You will need

A working dev container (runbook 01) and familiarity with branches and PRs
(runbook 05). You should also be comfortable reading the repo's standards in
`AGENTS.md`.

## You will learn

How to make a design change to this kit end-to-end: research the recommended
approach, plan and implement changes across inventory/CI/docs, lint, commit,
push, open a PR, and merge.

## Steps

1. **Research the recommended approach.** Before changing anything, check what
   the Red Hat COP recommends. Good starting points:
   - `docs/references.md` in this repo — links to COP blogs, collections, and
     templates.
   - The [AAP CaC docs](https://redhat-cop.github.io/aap_config_as_code_docs/).
   - The [Automation Good Practices](https://github.com/redhat-cop/automation-good-practices)
     repo.
   > **AI Assist:** [PROMPTS.md → rb06](../ai/PROMPTS.md#rb06).

2. **Plan the changes.** Sketch which files need to change — inventory,
   group_vars, playbooks, CI workflows, docs. If there are multiple approaches,
   note the tradeoffs. Get a teammate's (or your AI assistant's) input before
   implementing.

3. **Create a branch:**
   ```bash
   git switch -c descriptive-branch-name
   ```

4. **Implement.** Follow the standards in `AGENTS.md`:
   - Object variables load from `inventory/group_vars/` — never add
     `vars_files:` or `include_vars:`.
   - No customer data, secrets, or identifiers in tracked files.
   - Prefer `ansible.platform` modules over `ansible.controller`.

5. **Update the cross-references.** Every design change touches more than the
   code itself:
   - `CHANGELOG.md` — add an entry under `[Unreleased]` (always).
   - `AGENTS.md` — update if the directory layout or a convention changed (CI
     checks this).
   - `ROADMAP.md` — add a decisions-log entry if this is an architectural
     choice.
   - `docs/references.md` — add any new external links you found during
     research.
   - `README.md` — update if the change is user-facing.

6. **Lint and verify:**
   ```bash
   yamllint .
   ansible-lint
   ```
   If you changed the inventory, also verify it parses:
   ```bash
   ansible-inventory -i inventory --list --limit <group>
   ```

7. **Commit.** Stage specific files — never `git add .`:
   ```bash
   git add inventory/hosts.yml inventory/group_vars/prod/ ...
   git commit -m "Short description of what changed and why"
   ```

8. **Push and open a PR:**
   ```bash
   git push -u origin descriptive-branch-name
   gh pr create --fill
   ```
   The PR template asks for a summary, test plan, risk/rollback, and the
   secrets/standards checklist. Fill it in.

9. **Review your own diff** in the PR's "Files changed" tab. Confirm: no real
   secrets, no customer identifiers, group_vars only, CHANGELOG updated.

10. **Wait for Lint checks** (green), then **merge.**

## How you know it worked

The PR shows the Lint checks passing. After merge, your design change is on
`main` and all cross-references (AGENTS.md, CHANGELOG, etc.) are consistent.

## If it went wrong

- **Lint check failed** → click it to read why; usually yamllint indentation,
  an unencrypted secrets file, or AGENTS.md missing a directory. Fix, commit,
  push — the PR re-checks automatically.
- **ansible-inventory parse error** → check `hosts.yml` YAML indentation and
  that group names match between the inventory and `group_vars/` directories.
- **"I forgot to update CHANGELOG/AGENTS.md"** → add a follow-up commit to the
  same branch and push. The PR updates automatically.
- **"I pushed to main by accident"** → use the git-rescue prompt in
  [PROMPTS.md → rb05](../ai/PROMPTS.md#rb05).

Next: deploy runbooks (07+), added in later phases.
