# Going to production

The runbooks get you to first value: exporting AAP objects and promoting them
through dev/qa/prod in a controlled environment. Running this **for real, at
enterprise scale** adds a set of decisions and hardening that go beyond the kit.
This page outlines those workstreams so you know what's ahead — and where expert
help pays off.

Each of these is something Red Hat Consulting and your Technical Account Manager
(TAM) do regularly; a short engagement usually moves faster and lands safer than
figuring it out from scratch.

## The production workstreams

**Enterprise GitHub landing.** Duplicating this starter into your enterprise
GitHub, with the right org and repo structure, ownership, and branch protection.
Straightforward to start; the governance decisions (who owns what, how teams
branch, how changes are reviewed) are what take thought. The mechanics are in
[Duplicating into enterprise GitHub](duplicating-into-enterprise-github.md).

**CI/CD runners.** The GitHub Actions pipeline needs runners that can reach your
on-prem AAP endpoints. On GitHub Enterprise Server there are no hosted runners by
default, so you'll design and secure self-hosted runners with the right network
reach and isolation.

**Secrets and vault governance.** The kit vault-encrypts every secret. In
production you decide how vault passwords and connection credentials are stored,
who holds them, and how they rotate — across dev, qa, and prod, and across teams.

**Environments and approvals.** Mapping the kit's dev/qa/prod flow onto GitHub
environments with the right protection rules and required reviewers, so
promotions to qa and prod are gated the way your change process requires.

**High availability.** The kit models an active/passive production
(`prod-active` / `prod-passive`). A real HA rollout means designing failover,
validating drift between sites, and rehearsing recovery.

**Scale and adoption.** Onboarding a team onto config-as-code — consistent
standards, a smooth path for less-technical users, and support as usage grows.
This is where a TAM's adoption planning and best-practice guidance is most
valuable. The [adoption plan template](tam-adoption-plan.md) is a one-page
starting point to fill in with your TAM.

## How to engage

Talk to your Red Hat account team or Solutions Architect about a services
engagement for the implementation work above, and about a TAM for ongoing
adoption and best-practice support as your team scales. They can scope an
engagement to exactly the workstreams you need help with.
