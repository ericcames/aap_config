# GitHub setup (one-time, admin)

Some settings can't live in the repo's files — they're configured in GitHub itself.
An org owner / repo admin does this once. Below is a checklist plus an optional
`gh` script so a customer fork can reproduce it.

> The kit is portable to **GitHub Enterprise Cloud** and **GitHub Enterprise
> Server**. On GHES without hosted runners, change `runs-on: ubuntu-latest` to
> `runs-on: [self-hosted, linux]` in `lint.yml` (deploy workflows already use
> self-hosted).

## 1. Branch protection on `main`

- Require a pull request before merging.
- Require the **Lint** status checks to pass (`yamllint`, `ansible-lint`,
  `secret-guards`, `agents-md-fresh`).
- (Recommended) Require a review.

## 2. Self-hosted runner (on-prem)

One RHEL 9 VM with HTTPS reach to the dev/qa/prod gateways. Register it at the
**org or repo** level with labels `self-hosted, linux, aap`, and install it as a
service under a dedicated non-sudo user. (Settings → Actions → Runners → New
self-hosted runner gives the exact `./config.sh` command with a token.)

## 3. Environments + secrets

Create three environments — **dev**, **qa**, **prod** — each with:

| Kind | Name | Value |
|------|------|-------|
| Variable | `AAP_HOSTNAME` | that env's gateway URL (prod = active/passive VIP) |
| Secret | `AAP_USERNAME` | service account username |
| Secret | `AAP_PASSWORD` | service account password |
| Secret | `VAULT_PASSWORD` | the ansible-vault password for that env's `secrets.yml` |

On **qa** and **prod**, add **required reviewers** so a deploy pauses for human
approval. `dev` needs no reviewer (it deploys automatically on merge to `main`).

## Optional: reproduce with `gh`

```bash
ORG_REPO="your-org/aap_config"

# Branch protection (adjust to your plan; required checks by job name).
gh api -X PUT "repos/$ORG_REPO/branches/main/protection" \
  -H "Accept: application/vnd.github+json" \
  -f 'required_status_checks[strict]=true' \
  -f 'required_status_checks[checks][][context]=yamllint' \
  -f 'required_status_checks[checks][][context]=ansible-lint' \
  -f 'required_status_checks[checks][][context]=secret-guards' \
  -F 'enforce_admins=true' \
  -F 'required_pull_request_reviews[required_approving_review_count]=1' \
  -F 'restrictions=null'

# Environments (add reviewers to qa/prod in the UI or via the API).
for env in dev qa prod; do
  gh api -X PUT "repos/$ORG_REPO/environments/$env" >/dev/null
done

# Per-environment values (repeat per env; example for dev).
gh variable set AAP_HOSTNAME  --env dev  --repo "$ORG_REPO" --body "https://aap-dev.example.internal"
gh secret   set AAP_USERNAME  --env dev  --repo "$ORG_REPO"
gh secret   set AAP_PASSWORD  --env dev  --repo "$ORG_REPO"
gh secret   set VAULT_PASSWORD --env dev --repo "$ORG_REPO"
```

## Discovery checklist (before you build Phase 2)

Some enterprises restrict Actions. Confirm with an org owner:

- Org at `github.com/<org>` (GHEC) or a custom domain (GHES)?
- `gh api /orgs/<org>/actions/permissions` — Actions enabled? `allowed_actions`?
  If `selected`, ensure `actions/checkout` and `actions/setup-python` are allowed.
- May we register an on-prem self-hosted runner?
- Are environments with required reviewers available on private repos? (GHEC:
  Enterprise plan; GHES: version-dependent.)
