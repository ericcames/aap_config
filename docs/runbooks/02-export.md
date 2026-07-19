# Runbook 02 — Export from the production AAP

## You will need

The dev container open (runbook 01), and connection details for the **Azure
production AAP**: URL, service-account username, password.

## You will learn

How to run a playbook, what the "working tree" is, and why `exports/` is safe to
commit but secrets are not.

## Steps

1. **Create your local secrets file** from the template (it is gitignored):
   ```bash
   cp docs/dev-environment.sh.example docs/dev-environment.sh
   ```
   Edit `docs/dev-environment.sh` and fill in `CONTROLLER_HOST`,
   `CONTROLLER_USERNAME`, `CONTROLLER_PASSWORD`. Keep `AAP_VALIDATE_CERTS="true"`
   for the Azure instance.

2. **Load it into your shell:**
   ```bash
   source docs/dev-environment.sh
   ```

3. **Run the export:**
   ```bash
   ansible-playbook playbooks/export.yml -i inventory --limit azure
   ```
   > **AI Assist:** [PROMPTS.md → rb02](../ai/PROMPTS.md#rb02) — ask it to explain
   > the command before you run it.

4. **Scan for leaked secrets:**
   ```bash
   bash utilities/scan-exports.sh          # should print "scan-exports: OK"
   ```

## How you know it worked

`exports/azure/` now contains folders per organization with one YAML file per
object. Open a credential file — secret fields read `{{ vaulted_... }}`, never a
real password. `scan-exports.sh` prints OK.

## If it went wrong

- **Assertion: CONTROLLER_HOST not set** → you didn't `source
  docs/dev-environment.sh` in *this* terminal. Re-run step 2.
- **Auth/401** → wrong username/password, or the URL has a trailing slash (remove
  it).
- **TLS certificate error** → the instance uses a private CA; only then set
  `AAP_VALIDATE_CERTS="false"` and re-source.
- **`scan-exports.sh` FAILED** → a real secret leaked (rare). Re-run the export;
  if it persists, remove the value by hand and report it.

Next: [03-curate.md](03-curate.md).
