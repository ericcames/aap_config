---
name: branch-pr
description: Take a finished local change from working tree to merged main — create a branch, stage specific files, commit, push, open a pull request with gh, self-review the diff for secrets, watch the Lint checks, merge, and delete the branch. Use when the user has edits ready and wants help getting them reviewed and merged, or has committed to main by accident. Mirrors docs/runbooks/05-branch-pr.md.
---

# Branch, pull request, merge

Follow the standards in `AGENTS.md`. This mirrors `docs/runbooks/05-branch-pr.md`.

## The rule that matters

Nothing reaches `main` except through a pull request with green Lint checks.
Audit the diff for secrets and customer identifiers **before** committing, not
after pushing.

## Steps

1. **See what you have:**
   ```
   git status && git diff
   ```
   Read the diff for real secrets, customer or company names, RHDP URLs, and
   cluster/instance IDs. `{{ vaulted_* }}` placeholders must still be
   placeholders. If anything looks live, stop and tell the user.

2. **Make a branch** — uncommitted work comes with you:
   ```
   git switch -c descriptive-branch-name
   ```
   If they already committed to `main`, explain the rescue one command at a time
   and get confirmation before each: branch at the current commit, then move
   `main` back.

3. **Stage specific files** — never `git add .`:
   ```
   git add path/to/file.yml
   git commit -m "Explain what changed and why"
   ```

4. **Push:**
   ```
   git push -u origin <branch>
   ```

5. **Open the pull request:**
   ```
   gh pr create --fill
   ```
   Fill in the template — summary, test plan, risk/rollback, and the
   secrets/standards checklist.

6. **Self-review the diff** with `gh pr diff` or the "Files changed" tab. Confirm
   no secrets, no customer identifiers, object changes in
   `inventory/group_vars/` only, and `CHANGELOG.md` updated if the change is
   user-visible.

7. **Watch the checks:**
   ```
   gh pr checks --watch
   ```
   Red is usually yamllint indentation, an unencrypted `secrets.yml`, a
   `SKILL.md` frontmatter problem, or `AGENTS.md` missing a new top-level
   directory. Fix, commit, push — the PR re-checks itself.

8. **Merge, then clean up:**
   ```
   git switch main && git pull
   git branch -d <branch>
   git push origin --delete <branch>
   ```

## Do not

- Do not commit or push directly to `main`.
- Do not `git add .` or `git commit -a` — stage named files.
- Do not run `git reset --hard`, `git push --force`, or any history rewrite
  without explaining it first and getting explicit confirmation.
- Do not merge with red Lint checks, and do not bypass a required check.
- Do not commit a plaintext `secrets.yml`, customer identifiers, or RHDP URLs.
- Do not use this skill for a design or convention change — use `/evolve-kit`,
  which wraps this same flow with research, planning, and the cross-reference
  updates (`CHANGELOG.md`, `AGENTS.md`, `ROADMAP.md`, `docs/references.md`).
