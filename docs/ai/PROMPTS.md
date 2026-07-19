# AI prompt library

Copy-paste prompts for each step of the teaching path. They work in **any** AI
assistant — GitHub Copilot CLI (`copilot -p "..."`), Copilot Chat in VS Code, or
Claude Code (paste into the chat). The runbooks link to the anchors here.

**Prompts explain; skills do.** Use a prompt here when you want to *understand* a
step — paste it, read the answer, then run the command yourself. When you want the
assistant to *carry out* the step with this repo's standards already baked in,
invoke the matching skill instead: `/setup-workstation`, `/export-aap`,
`/curate-config`, `/vault-secrets`, `/branch-pr`, `/evolve-kit`, `/apply-config`.
The skills ship in `.claude/skills/` and load in **both** Claude Code and GitHub
Copilot CLI — see
[`AGENTS.md` → Repo-shipped skills](../../AGENTS.md#repo-shipped-skills).

**How to write a good prompt (the rules the runbooks follow):**
1. State your context ("I'm in an Ansible config-as-code repo…").
2. Ask one thing per prompt.
3. Early on, ask it to **explain**; later, ask it to **write** or **fix**.

---

## Runbook 00 — prerequisites {#rb00}

> Skill: `/setup-workstation` — runs the step instead of just explaining it.

```
Explain what a VS Code Dev Container is and why a Windows user would run one
instead of installing Ansible directly on Windows. Keep it to a short paragraph.
```

```
I ran `gh api /user/copilot_billing` and got a 404. What does that mean about my
GitHub Copilot access, and who do I ask to fix it?
```

## Runbook 01 — dev container {#rb01}

> Skill: `/setup-workstation` — runs the step instead of just explaining it.

```
I'm in VS Code on Windows. Explain, step by step, how to clone a GitHub repo over
HTTPS using `gh auth login` (device flow) and then "Reopen in Container".
```

## Runbook 02 — export {#rb02}

> Skill: `/export-aap` — runs the step instead of just explaining it.

```
I'm in an Ansible config-as-code repo. Explain what this command does before I run
it: `ansible-playbook playbooks/export.yml -i inventory --limit azure`. What does
`--limit azure` change?
```

```
The export failed with an assertion about aap_hostname not being set. Explain
what I forgot to do — I need connection.yml and vault-encrypted secrets.yml in
the right group_vars directory. Walk me through setting them up.
```

## Runbook 03 — curate into group_vars {#rb03}

> Skill: `/curate-config` — runs the step instead of just explaining it.

```
I'm looking at an exported AAP object file under exports/. Explain what each field
in this controller project definition does: <paste the file>.
```

```
Explain the difference between `git status`, `git diff`, and `git add`, as if I've
never used Git. Then tell me the exact commands to stage one file.
```

```
In this repo, shared objects use a variable name ending in `_all` and per-env ones
end in `_dev`/`_qa`/`_prod`. I have an exported `controller_projects:` list I want
to share across all environments. What should I rename the top-level key to, and
which directory under inventory/group_vars/ does it belong in?
```

## Runbook 04 — secrets & vault {#rb04}

> Skill: `/vault-secrets` — runs the step instead of just explaining it.

```
Explain what `ansible-vault encrypt inventory/group_vars/dev/secrets.yml
--vault-id dev@prompt` does, and what happens if I lose the password.
```

```
Why should a password never be committed to Git in plain text, even in a private
repo? Explain the risk simply.
```

## Runbook 05 — branch → PR → merge {#rb05}

> Skill: `/branch-pr` — runs the step instead of just explaining it.

```
Explain, step by step and simply: create a branch, commit my changes, push it, and
open a pull request with the GitHub CLI (`gh`).
```

```
I accidentally committed directly to `main` instead of a branch. Walk me through
fixing this safely, one command at a time, explaining each before I run it.
```

## Runbook 06 — evolve the kit {#rb06}

> Skill: `/evolve-kit` — runs the step instead of just explaining it.

```
I want to change how this kit handles <topic>. Walk me through the full cycle:
research the COP-recommended approach, plan the changes, implement, update
CHANGELOG/AGENTS.md, lint, commit, push, and open a PR.
```

```
I've made changes across inventory, CI workflows, and docs. Walk me through
staging specific files, writing a good commit message, pushing to a branch, and
opening a pull request with `gh pr create`.
```

```
Explain what the Red Hat Communities of Practice (COP) is and where to find
their recommended patterns for AAP config-as-code.
```

## Runbook 07+ — CI, deploy, approvals {#rb07}

> Skill: `/apply-config` — runs the step instead of just explaining it.

```
Explain what a GitHub Actions "status check" is and why a pull request can be
blocked from merging until the Lint check passes.
```

```
Explain what a GitHub "Environment" with "required reviewers" does when the
Deploy qa workflow runs.
```
