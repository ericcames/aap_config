---
name: evolve-kit
description: Drive a design change end-to-end — research the COP-recommended approach, plan changes across inventory/CI/docs, implement, lint, commit, push, open a PR, and merge. Use when the user wants to add or change a convention, pattern, or architecture decision in this kit. Mirrors docs/runbooks/06-evolve-kit.md.
---

# Evolve the kit

Follow the standards in `AGENTS.md`. This mirrors `docs/runbooks/06-evolve-kit.md`.

## Steps

1. **Research.** Before writing anything, find the Red Hat COP or upstream
   recommended approach. Check `docs/references.md` for prior art. Search the
   COP blogs, `infra.aap_configuration` docs, and `automation-good-practices`.
   Summarize what you found and link the sources.

2. **Plan.** Sketch which files change (inventory, group_vars, playbooks, CI
   workflows, docs). Present the plan to the user and get sign-off before
   implementing. If there are multiple valid approaches, explain the tradeoffs.

3. **Implement.** Make the changes following AGENTS.md standards. Remember:
   - Object variables load from `inventory/group_vars/` — no `vars_files:` /
     `include_vars:`.
   - No customer data, secrets, or identifiers in tracked files.
   - Prefer `ansible.platform` modules.

4. **Cross-reference updates.** Every design change touches more than code:
   - `CHANGELOG.md` — entry under `[Unreleased]` (always).
   - `AGENTS.md` — if the directory layout or a convention changed.
   - `ROADMAP.md` — decisions log entry if this is an architectural choice.
   - `docs/references.md` — if you found new external links during research.
   - `README.md` — if the change is user-facing.

5. **Lint and verify:**
   ```
   yamllint .
   ansible-lint
   ```
   If inventory changed, also:
   ```
   ansible-inventory -i inventory --list --limit <group>
   ```

6. **Commit.** Stage specific files (not `git add .`). Write a descriptive
   commit message that explains what changed and why.

7. **Push and PR:**
   ```
   git push -u origin <branch>
   gh pr create --fill
   ```
   Fill in the PR template: summary, test plan, risk/rollback, and the
   secrets/standards checklist.

8. **Review and merge.** Self-review the diff in the PR's "Files changed" tab.
   Confirm no secrets, no customer data, group_vars only. Wait for the Lint
   checks to pass, then merge.

9. **Clean up:**
   ```
   git switch main && git pull
   git branch -d <branch>
   git push origin --delete <branch>
   ```

## Do not

- Do not skip the research step — the COP may already have a recommended pattern.
- Do not commit without running `yamllint` and `ansible-lint` first.
- Do not push directly to `main` — always use a branch and PR.
- Do not skip `CHANGELOG.md` or `AGENTS.md` updates when they apply.
- Do not add `vars_files:` or `include_vars:` to load object definitions.
