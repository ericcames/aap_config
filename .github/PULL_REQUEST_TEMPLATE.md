## Summary

<!-- What does this PR add or change, and why? -->

## Test plan

<!-- How was this validated? e.g. yamllint + ansible-lint pass, export run,
     validate.yml (check mode) against dev, config.yml applied to dev. -->

## Risk / rollback

<!-- Blast radius and how to undo if it goes wrong. Which environments does it
     touch? -->

## Checklist

- [ ] No tokens, passwords, vault passwords, or secrets committed
- [ ] No customer/RHDP data — used generic placeholders
- [ ] Exported credential fields remain `{{ vaulted_* }}` placeholders
- [ ] Object vars load from `inventory/group_vars/` — no new `vars_files:` / `include_vars:`
- [ ] `yamllint .` and `ansible-lint` pass locally
- [ ] `CHANGELOG.md` updated under `[Unreleased]`
- [ ] `AGENTS.md` updated if the layout or a convention changed

## Related issues

<!-- Closes #<issue number> -->
