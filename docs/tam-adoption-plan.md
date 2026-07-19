# Adoption plan template

A one-page plan for the moment config-as-code stops being one person's project
and becomes how a team works — usually somewhere between five and twenty users.

**This is a template.** Copy it somewhere your team can edit it, fill in the
placeholders, and review it with your Technical Account Manager (TAM). The
prompts matter more than the format; delete any row that does not apply to you.

---

## 1. Where we are today

| | |
|---|---|
| Date | `<YYYY-MM-DD>` |
| Environments live | `<dev / qa / prod-active / prod-passive>` |
| People using the kit today | `<names or count>` |
| Objects under config-as-code | `<e.g. 12 job templates, 4 projects, 6 credentials>` |
| Still managed by hand in the UI | `<what has not been exported yet>` |
| Biggest current pain | `<one sentence>` |

## 2. Adoption goals

What "adopted" means for this team, with dates. Two or three goals is plenty.

| Goal | Measure | Target date | Owner |
|---|---|---|---|
| `<e.g. all prod job templates managed as code>` | `<how you will know>` | `<YYYY-MM-DD>` | `<name>` |
| | | | |

## 3. Onboarding cohorts

Bring people on in small groups rather than all at once — each cohort's
questions improve the docs for the next.

| Cohort | Who | When | Runbooks they work through | Buddy / reviewer |
|---|---|---|---|---|
| 1 | `<names>` | `<date>` | 00–05 (export → PR) | `<name>` |
| 2 | `<names>` | `<date>` | 00–05, then 07+ (deploy) | `<name>` |
| 3 | `<names>` | `<date>` | `<...>` | `<name>` |

For each cohort, note who reviews their first pull request. The first PR review
is where the standards in [`AGENTS.md`](../AGENTS.md) actually get taught.

## 4. Best-practice checkpoints

Review these with your TAM as usage grows, rather than waiting for something to
break.

- [ ] **Standards holding?** Object vars still load from
      `inventory/group_vars/` — no `vars_files:` / `include_vars:` creeping in.
- [ ] **Secrets discipline.** Every `secrets.yml` vault-encrypted; vault
      passwords rotated on the schedule you set; no credentials in exports.
- [ ] **Promotion gates.** qa and prod still require the reviewers you intended;
      no one is bypassing the pipeline to click in the UI.
- [ ] **Drift.** You are checking whether the live platform still matches the
      repo, and someone owns acting on the answer.
- [ ] **Collection currency.** `collections/requirements.yml` pins reviewed
      against current certified/validated releases.
- [ ] **Docs match reality.** Runbooks updated when a convention changed.

## 5. Escalation and support

| Situation | Who to contact | How |
|---|---|---|
| Product defect or outage | Red Hat Support | `<case process, severity guidance>` |
| Certified collection behaviour | Red Hat Support | `<case>` |
| Best-practice / architecture question | TAM | `<cadence, e.g. monthly call>` |
| Implementation help | Red Hat Consulting | `<account team contact>` |
| Internal kit questions | `<your platform owner>` | `<channel>` |

## 6. How we will know it worked

Pick a small number and revisit them at each TAM checkpoint.

| Signal | Baseline | Now | Target |
|---|---|---|---|
| Time to first successful deploy for a new user | `<>` | `<>` | `<>` |
| Users who have merged at least one PR | `<>` | `<>` | `<>` |
| Share of AAP objects managed as code | `<>` | `<>` | `<>` |
| Manual UI changes per month | `<>` | `<>` | `<>` |
| Failed deploys per month | `<>` | `<>` | `<>` |

---

Related: [Going to production](going-to-production.md) for the wider set of
production workstreams.
