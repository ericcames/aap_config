# Runbook 05 — Branch, pull request, merge

> **Skill:** `/branch-pr` runs this whole runbook for you, in Claude Code or GitHub
> Copilot CLI. Read the steps first, then let it drive.

## You will need

Committed curated objects and an encrypted `secrets.yml` (runbooks 03–04).

## You will learn

Branches, pushing, and opening a pull request — the normal way changes reach
`main`.

## Steps

1. **Make a branch** for your change (never work directly on `main`):
   ```bash
   git switch -c add-controller-projects
   ```

2. **Push it** to GitHub:
   ```bash
   git push -u origin add-controller-projects
   ```

3. **Open a pull request:**
   ```bash
   gh pr create --fill
   ```
   The PR template asks for a summary, test plan, and the secret/standards
   checklist — fill it in.
   > **AI Assist:** [PROMPTS.md → rb05](../ai/PROMPTS.md#rb05).

4. **Review your own diff** in the PR's "Files changed" tab. Confirm: no real
   secrets, no customer identifiers, group_vars only.

5. **Wait for the Lint checks** (green), then **merge**.

## How you know it worked

The PR shows the **Lint** checks passing, and after merge your change is on
`main`. Merging to `main` is what later triggers the dev deploy (runbook 07).

## If it went wrong

- **Lint check failed** → click it to read why; usually yamllint indentation or an
  unencrypted secrets file. Fix, commit, push — the PR re-checks automatically.
- **"I committed to main by accident"** → use the git-rescue prompt in
  [PROMPTS.md → rb05](../ai/PROMPTS.md#rb05); your AI assistant will walk you
  through moving the commit to a branch.

Next: continue with the deploy runbooks (06–08), added in Phase 2.
