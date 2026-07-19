# Duplicating this kit into enterprise GitHub

This kit lives on public GitHub as a starting point. When you stand it up for a
customer or on an internal instance, you copy it into **GitHub Enterprise**
(Enterprise Cloud or a self-hosted Enterprise Server) and build from there.

This page covers the recommended way to do that, plus the enterprise-side setup
that a plain copy does **not** bring along.

## Which method

Because this kit is a starting point, you almost always want a **clean first
commit** — not the authoring history from the public repo. Use the clean-slate
method below.

Use the full-history mirror only if you specifically need every original commit,
branch, and tag preserved (e.g. for provenance).

> This repo is a normal public repo, not a GitHub *template repository*, so the
> `gh repo create --template` shortcut does not apply. The steps below work
> regardless.

## Before you start

Authenticate `gh` to the destination host. For an Enterprise Server instance,
point `gh` at it explicitly:

```bash
gh auth login --hostname YOUR-ENTERPRISE-HOST   # e.g. octocorp.ghe.com
```

For Enterprise Cloud (github.com domain) the default login is fine. Make sure
your account/token can create repositories in the destination organization — org
policy can block repo creation even with a valid token.

## Recommended: clean-slate copy

Gives the new repo a single fresh commit and none of the public repo's history.

```bash
# 1. Grab the latest files only
git clone --depth 1 https://github.com/ericcames/aap_config.git new-repo
cd new-repo

# 2. Drop the old history and start fresh
rm -rf .git
git init -b main
git add .
git commit -m "Initial import of AAP config-as-code starter kit"

# 3. Create the enterprise repo and push in one step
gh repo create YOUR-ORG/aap_config --private --source=. --remote=origin --push
```

Change `--private` to `--internal` if you want it visible across the enterprise,
or `--public` if appropriate.

## Alternative: full-history mirror

Only if you need to preserve all commits, branches, and tags.

```bash
git clone --bare https://github.com/ericcames/aap_config.git
gh repo create YOUR-ORG/aap_config --private
cd aap_config.git
git push --mirror https://YOUR-ENTERPRISE-HOST/YOUR-ORG/aap_config.git
cd .. && rm -rf aap_config.git
```

`--mirror` does **not** move Git LFS objects; if `.gitattributes` tracks any,
follow up with `git lfs push --all` against the new remote. Issues and releases
do not travel with a git copy either — they live in the GitHub API.

## What the copy does NOT bring — do this next

A git copy moves files only. This kit's GitHub Actions pipeline depends on repo
**settings** that you must recreate on the enterprise repo:

- **Actions secrets** — the per-environment vault passwords and connection
  credentials the workflows expect. Recreate them under *Settings → Secrets and
  variables → Actions* (and per environment).
- **Environments** — `dev`, `qa`, `prod` (including `prod-active` /
  `prod-passive`), with their **required reviewers / approval** protection
  rules. These are what gate the manual qa/prod promotions.
- **Runners** — on **GitHub Enterprise Server** there are no GitHub-hosted
  runners by default. The workflows need **self-hosted runners** with network
  reach to the on-prem AAP 2.7 endpoints. Confirm this before anyone expects the
  pipelines to run.
- **Branch protection** on `main`, if your process relies on it (see
  [runbook 05](runbooks/05-branch-pr.md)).

[`docs/github-setup.md`](github-setup.md) is the admin checklist for these
settings — work through it against the new repo.

## Verify

```bash
# LFS check on the source before copying
grep -i lfs .gitattributes 2>/dev/null && echo "has LFS — handle separately"

# After push, confirm the repo and default branch on the enterprise host
gh repo view YOUR-ORG/aap_config --web
```

Then walk [runbook 00](runbooks/00-prerequisites.md) on the new instance to
confirm accounts, the container engine, VS Code, and Copilot seats are in place
for whoever will use the kit.
