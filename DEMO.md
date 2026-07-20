# DEMO — the config-as-code loop in about 10 minutes

A demo script for a **technical audience** — sysadmins and platform engineers who
will actually run this. It shows the loop end to end without walking through
runbooks 00–07.

The runbooks teach. This shows. If someone in the room wants to *learn* it
afterwards, hand them [`README.md` → Start here](README.md#start-here).

---

## Before you stand up

Two questions decide which version of this demo you give. Answer them honestly —
the failure mode for this demo is discovering mid-session that a step needs
something you don't have.

**1. What can you reach?**

| What you have | What you can run |
|---|---|
| **A source AAP** (export from) | Act 1 live |
| **A target AAP** (apply to) | Act 4 live |
| **Neither** | Everything except Act 1 and Act 4 — see [No AAP handy](#no-aap-handy) |
| **GitHub Actions** — nothing to set up | Act 3 live. The five PR checks in `lint.yml` run on GitHub-hosted runners, so they work on this repo as-is. Only demoing a **deploy workflow actually firing** needs setup: a self-hosted runner labeled `self-hosted, linux, aap` plus the four GitHub Environments and their `VAULT_PASSWORD` secrets ([`docs/github-setup.md`](docs/github-setup.md)). Act 4 applies locally on purpose, so the demo never depends on that. |

> Demoing from a copy in a customer's **GitHub Enterprise Server**? GHES has no
> hosted runners by default, so even the lint checks need a self-hosted runner —
> a one-line `runs-on:` change, noted at the top of
> [`.github/workflows/lint.yml`](.github/workflows/lint.yml). Demo from your own
> GitHub repo and this does not come up.

**2. Has this repo been through the loop already?** If `inventory/group_vars/aap/`
holds nothing but `aap_settings.yml`, no objects have been curated yet, so Act 2
is a genuine first-time edit rather than a replay. That is fine — it is arguably
more honest — but you should have decided which object you are going to curate
*before* you start talking.

**Rehearse it once.** Run the whole thing start to finish the day before, against
the same environment, with the same terminal. This script assumes you have.

### Where you run it

**Your laptop's dev container.** It already holds the two things this demo
depends on: the vault password files in `~/secrets/` and the Automation Hub
token in `~/.ansible.cfg`. A codespace has neither, and putting them there means
a Codespaces secret written to a file at container start — which undoes the
reason for not typing passwords live. No image build to wait on, no idle
timeout, one less network hop.

Codespaces still earns its place in this demo twice: as the **audience's**
on-ramp (the badge in the README — they can try the repo without installing
anything), and as your **cold backup** if the laptop dies, accepting that you
will be typing vault passwords for that run.

### Setup checklist

```bash
# In the dev container, from the repo root:
ansible --version                                              # ansible-core 2.16.x
ansible-galaxy collection list | grep infra.aap_configuration  # 4.7.0
gh auth status                                                 # logged in
ls -l ~/secrets/                                               # .vault_pass_azure, .vault_pass_qa — both mode 600
git switch -c demo-$(date +%m%d) && git status                 # clean tree, demo branch
```

Missing a vault password file? Create it once, outside the repo:

```bash
install -m 600 /dev/null ~/secrets/.vault_pass_qa
# then put the qa vault password in it — one line, no trailing newline issues:
#   printf '%s' 'the-password' > ~/secrets/.vault_pass_qa
```

Have a second terminal open on the repo, and a browser tab on the repo's
**Actions** tab. This script assumes **Claude Code** as the assistant — the
skills also work in Copilot CLI, which is a point worth making in Act 2, but
pick one before you start rather than switching mid-demo.

---

## The one-sentence framing

> Your AAP configuration stops being something you click together in a UI and
> becomes something that lives in Git, gets reviewed like code, and is applied by
> a pipeline — with the same objects promoted through dev, qa, and prod.

Show [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) or the ASCII diagram in the
README for thirty seconds, then stop talking and start running things.

---

## Act 1 — Export: get what's already there into Git *(~2 min)*

*Needs a source AAP. Skip to Act 2 if you don't have one.*

The point to land: **nobody hand-writes this**. You start from what is already
running in production, and the export is read-only.

```bash
ansible-playbook playbooks/export.yml -i inventory --limit azure --vault-id azure@~/secrets/.vault_pass_azure
```

> `<env>@<file>` reads the vault password from disk instead of prompting. The
> runbooks teach `--vault-id azure@prompt`, and that is the right default for a
> person at a keyboard — but a demo should never stall on a mistyped password.
> If either playbook prompts you, the path is wrong.

While it runs, say what it is doing: `filetree_create` walks the controller and
gateway APIs and writes one file per object into `exports/`. It mints a
read-scoped OAuth token and deletes it in an `always:` block, so nothing is left
behind on the platform.

Then the part a security-minded audience cares about:

```bash
bash utilities/scan-exports.sh
```

Secret fields never come out in the clear — `secrets_as_variables: true` templates
them to `{{ vaulted_* }}` placeholders, and this guard fails the run if anything
secret-shaped slipped through. It runs in the pre-commit hook and in CI too.

```bash
ls exports/azure/
```

Real objects, one file each, committed for review.

---

## Act 2 — Curate: decide what is actually config *(~2 min)*

Export is a snapshot; **config-as-code is a decision about what you intend to
manage.** This is the step people underestimate.

Pick one object — a project or a job template reads well — and move it:

```bash
# Shared by every environment:
#   exports/azure/.../controller_projects.yaml
#     -> inventory/group_vars/aap/controller_projects.yml
#     and rename the top-level key to controller_projects_all
```

Two things to call out while you edit:

- **The `_all` / `_<env>` suffix.** `controller_projects_all` is shared;
  `controller_projects_dev` is a dev-only delta. They merge at apply time. That
  is how one repo serves four environments without four copies.
- **Variables load implicitly from `inventory/group_vars/`** — there is no
  `vars_files:` or `include_vars:` anywhere in this repo, by design. Environment
  is selected with `--limit`. This is the Red Hat Services standard, and it is
  the single most common thing people get wrong.

If the audience is AI-curious, this is the strongest place to show a skill —
`/curate-config` does exactly this move and knows the suffix rule:

```
/curate-config
```

Worth naming: these skills use the open `SKILL.md` format and work in **both**
Claude Code and GitHub Copilot CLI. Same files, either tool — nobody is locked in.

---

## Act 3 — Review: the guardrails are the product *(~3 min)*

This is the act that separates config-as-code from "we put some YAML in Git", so
give it the most time.

```bash
git add inventory/group_vars/aap/controller_projects.yml
git commit -m "Manage the platform baseline project as code"
git push -u origin demo-$(date +%m%d)
gh pr create --fill
```

Switch to the Actions tab and let five checks run in front of them:

| Check | What it stops |
|---|---|
| `yamllint` | Malformed YAML |
| `ansible-lint` | Playbook and syntax problems |
| `secret-guards` | A plaintext `secrets.yml` or a leaked secret in `exports/` |
| `agents-md-fresh` | Docs drifting from the directory layout |
| `skills-frontmatter` | An AI skill that would silently stop loading |

Then the line that usually lands hardest — **try to commit a secret in front of
them**:

```bash
echo 'aap_password: "hunter2"' > inventory/group_vars/dev/secrets.yml
git add inventory/group_vars/dev/secrets.yml && git commit -m "oops"
```

The commit is refused, because `secrets.yml` is not vault-encrypted:

```
ERROR: not vault-encrypted: inventory/group_vars/dev/secrets.yml
       Encrypt it:  ansible-vault encrypt '...' --vault-id <env>@prompt
check-vault-encrypted: FAILED — plaintext secrets file(s) found.
```

The same guard runs in CI, so it holds even for someone who skipped the hook.
Clean up:

```bash
git restore --staged inventory/group_vars/dev/secrets.yml
rm inventory/group_vars/dev/secrets.yml
```

> Practice this bit. **Use `dev/` on purpose** — `dev/secrets.yml` does not
> exist, so the `>` creates it and nothing real is at risk. Do **not** point this
> at `qa/`, which now holds a real vault-encrypted `secrets.yml` that `>` would
> destroy. Cleanup is `rm` and **not** `git checkout --`, which fails on an
> untracked file.
>
> Never type a real credential here. `hunter2` is [bash.org quote
> #244](https://bash-org-archive.com/?244) — a 2004 IRC log where a user whose
> client masks passwords as `*******` concludes that everyone's password displays
> that way, and helpfully types his real one. It has been the internet's
> universal obviously-fake password ever since, which is exactly why it belongs
> here: nobody in the room mistakes it for a live credential.

The secrets model in one breath: everything sensitive lives in one
vault-encrypted `secrets.yml` per environment — connection credentials *and*
object secrets — and CI needs exactly one `VAULT_PASSWORD` per GitHub
Environment. If they run BeyondTrust, CyberArk, or HashiCorp, point at
[`docs/secrets-beyondtrust.md`](docs/secrets-beyondtrust.md) as the worked
example of backing those values with an external manager.

Merge the PR.

---

## Act 4 — Apply: it shows up in AAP *(~3 min)*

*Needs a target AAP. If you don't have one, see [No AAP handy](#no-aap-handy).*

**Dry run first — always:**

```bash
ansible-playbook playbooks/validate.yml -i inventory --limit qa --vault-id qa@~/secrets/.vault_pass_qa
```

`validate.yml` is `config.yml` in check mode. It reports what *would* change and
changes nothing. Read the intended changes out loud — this is the "no surprises"
promise, and it is what makes the pipeline safe to hand to someone junior.

```bash
ansible-playbook playbooks/config.yml -i inventory --limit qa --vault-id qa@~/secrets/.vault_pass_qa
```

Now the payoff: **switch to the AAP UI and show the object**. Don't narrate it,
just show it.

Then run the apply a second time and show it reports no changes — idempotence is
what makes this safe to run on a schedule rather than a ceremony.

Close the loop: in the real flow, merging to `main` triggers `deploy-dev.yml`
automatically; qa and prod are `workflow_dispatch` with required reviewers on
their GitHub Environments. Production is an active/passive pair that receives
identical config, with one variable — `aap_site_role` — deciding which side's
schedules and notifications are live. Failover is swapping that value, not
re-running a migration.

---

## No AAP handy

Cut Acts 1 and 4 and run **Act 2 → Act 3** as the whole demo. You lose the "it
appeared in the UI" moment, but the guardrails act is the part technical audiences
argue about anyway, and every command still runs for real.

Substitute for the payoff: open `exports/azure/` to show what a real export looks
like, then walk [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for where the
pipeline goes. Be straightforward that you are showing the repo rather than a live
apply — a technical audience will respect that far more than a demo that stalls on
a connection error.

---

## Questions you will get

**"Why not just use the AAP UI, or a backup/restore?"** Backup restores an
instance; this promotes *intent* through environments. The same definitions build
dev, qa, and both prod sides, and every change is reviewable and revertable.

**"What happens if someone changes it by hand in the UI?"** Today, the next apply
puts it back. Scheduled drift detection using `object_diff` is designed in
[`docs/phase-3-plan.md`](docs/phase-3-plan.md) — report-first, never auto-delete.

**"Does this need Ansible expertise?"** No, and that is the point of the runbook
path — it is written for people with little Git or software-development
experience, on Windows, in a dev container, with an AI assistant at each step.

**"Where do the collections come from?"** Automation Hub, via `AH_TOKEN` — Red Hat
certified content (`ansible.platform`, `ansible.controller`) and validated content
(`infra.aap_configuration*`), pinned in
[`collections/requirements.yml`](collections/requirements.yml). That token is the
moment the kit reaches into their AAP subscription; see the README's
"Where the subscription fits".

**"Can we run this on our GitHub Enterprise?"** Yes — see
[`docs/duplicating-into-enterprise-github.md`](docs/duplicating-into-enterprise-github.md).
On GHES without hosted runners, the workflows need self-hosted runners with
network reach to the gateways; that is one line in each workflow.

**"What would it take to actually adopt this?"** That is a different conversation
from this demo:
[`docs/going-to-production.md`](docs/going-to-production.md) lists the
workstreams, and [`docs/tam-adoption-plan.md`](docs/tam-adoption-plan.md) is a
one-page plan to fill in with their TAM. Good leave-behinds.

---

## Screenshots to capture

Not yet captured — grab these during the next rehearsal. They go in
[`docs/images/`](docs/images/), committed so they render on GitHub, and they turn
this script into something that still lands when the environment is down.

| # | Act | The moment |
|---|-----|-----------|
| 1 | 4 | The object in the AAP UI, right after `config.yml` — the payoff, and the shot you cannot recreate later |
| 2 | 4 | The second apply reporting `changed=0` — idempotence in one frame |
| 3 | 3 | The five green checks on the PR in the Actions tab |
| 4 | 3 | The pre-commit hook refusing the `hunter2` commit |
| 5 | 2 | `/curate-config` running in Claude Code |

Shots 1 and 2 are the ones to prioritize: they are the only two that need a live
AAP, so they are the ones you lose if the environment is unreachable on the day.

---

## After the demo

```bash
git switch main && git pull
git branch -d demo-<date>
git push origin --delete demo-<date>
```

Point them at [`README.md`](README.md) to start the runbooks themselves, and at
the Codespaces badge if they want a working environment without installing
anything.
