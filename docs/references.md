# References

External resources that shaped this kit's design. Grouped by topic.

## Active/passive CaC (the pattern this kit follows)

| Resource | Description |
|----------|-------------|
| [Active/passive CaC architecture (Part 2)](https://www.redhat.com/en/blog/automation-controller-active-passive-architecture-cac) | The COP blog post that defines the `Controller_Location` / site-role pattern. Covers webhooks, load-balancer headers, and how failover works without a Git commit. |
| [CaC with GitOps (Part 1)](https://www.redhat.com/en/blog/ansible-automation-controller-cac-gitops) | Foundations: directory structure, per-environment promotion via Git branches/tags, webhook-driven deployment. |
| [AAP 2.1 Reference Architecture (HA)](https://www.ansible.com/blog/new-reference-architecture-deploying-red-hat-ansible-automation-platform-2.1) | The original HA reference architecture. Two-site active/passive with CaC replacing database replication. |

## Red Hat Communities of Practice (COP) — Config as Code

| Resource | Description |
|----------|-------------|
| [AAP CaC Docs](https://redhat-cop.github.io/aap_config_as_code_docs/) | Umbrella docs site for all COP CaC collections. Role references, getting-started guides, variable naming. |
| [`infra.aap_configuration`](https://github.com/redhat-cop/infra.aap_configuration) | The collection this kit uses. Roles for controller, gateway, hub, and EDA objects. Includes `dispatch`, `filetree_read`, `filetree_create`. |
| [`aap_configuration_template`](https://github.com/redhat-cop/aap_configuration_template) | COP starter template for multi-environment CaC repos. Uses `config/all/` + `config/<env>/` layout (this kit uses the inventory `group_vars` variant of the same pattern). |
| [Automation Good Practices](https://github.com/redhat-cop/automation-good-practices) | COP-wide good practices covering naming, AAP CaC, Git workflow, testing, CI/CD, and security. |

## Creating a CaC pipeline

| Resource | Description |
|----------|-------------|
| [Creating an Ansible controller CaC pipeline](https://www.redhat.com/en/blog/creating-ansible-controller-config-code-pipeline) | End-to-end walkthrough: Git repo structure, CI/CD, promotion gates, multi-environment deployment. |
| [Organization-level CI/CD with CaC](https://www.redhat.com/en/blog/self-service-config-code-ansible) | Self-service model: each AAP organization owns its own CaC branch, with CI/CD gates per org. |
