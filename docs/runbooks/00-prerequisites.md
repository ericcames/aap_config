# Runbook 00 — Install WSL2

> **Skill:** `/setup-workstation` runs this whole runbook (it covers runbooks 00–01) for you, in Claude Code or GitHub
> Copilot CLI. Read the steps first, then let it drive.

> **Decide this first, before anything else:** if **WSL2 and Hyper-V are
> blocked by policy or firmware** on this Windows desktop, the local
> dev-container path will not work here at all — see
> [Reading the result](#reading-the-result) below for what to do instead. Run
> the [Preflight checks](#preflight-can-this-desktop-run-wsl2) first; it
> takes two minutes and catches this at the start instead of midway through
> the runbook.

## You will need

A Windows 10/11 desktop, with the ability to run PowerShell as administrator.

## You will learn

Whether this desktop can run WSL2, and how to install it if so.

## Preflight: can this desktop run WSL2?

WSL2 needs virtualization enabled. On a locked-down corporate desktop,
WSL2 or hardware virtualization is sometimes disabled by IT policy or
firmware — and if it is, nothing built on WSL2 (including the dev container)
will start at all.

Run this check **first**, before installing anything. It takes two minutes
and tells you whether this desktop can use the local path or needs the
fallback further down.

### Run the checks

Open **PowerShell** and run:

```powershell
winver                              # Windows 10 2004+ or Windows 11 required
wsl --status                        # is WSL present? what is the default version?
wsl --version                       # WSL app version — blank means not installed
systeminfo | findstr /i "Hyper-V"   # virtualization / Hyper-V requirements
```

![The Windows "About" dialog opened by winver, showing Windows 11 Pro Version 25H2](../images/winver-windows11.png)

Then the two checks that decide it in a managed environment (the second needs an
elevated / admin PowerShell):

```powershell
# Are the required Windows features available and enabled?
# -FeatureName takes one name at a time — a comma-separated list becomes an
# array and Get-WindowsOptionalFeature rejects it, so loop instead.
foreach ($name in 'Microsoft-Windows-Subsystem-Linux', 'VirtualMachinePlatform') {
  Get-WindowsOptionalFeature -Online -FeatureName $name
}

# Is WSL disabled by group policy? (no output / not-found = not policy-blocked)
Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WSL" -ErrorAction SilentlyContinue
```

Example output — `State` is what to check; `Enabled` is good, `Disabled` needs
`wsl --install` (elevated) plus a reboot:

```text
FeatureName      : Microsoft-Windows-Subsystem-Linux
DisplayName      : Windows Subsystem for Linux
State            : Disabled

FeatureName      : VirtualMachinePlatform
DisplayName      : Virtual Machine Platform
State            : Enabled
```

Also confirm you can run commands as **administrator** (or that IT can enable
the features for you via Intune/GPO) — `wsl --install` requires elevation.

### Reading the result

**WSL2 is available or can be enabled** → you are good. Install it if needed:

```powershell
wsl --install     # installs WSL2 + a default Linux distro (reboot after)
```

Continue to [runbook 01](01-dev-environment.md).

**WSL2 and Hyper-V are blocked by policy or firmware** → the local dev-container
path will not work on this desktop. Do not invest in the local setup; switch to
a **shared Linux dev host** instead — a jump host or VM (for example RHEL) where
users run the dev container, or the tooling directly, over SSH.

Decide this **before** building out the local runbook flow, so a desktop that
can never run the container is caught at the start rather than midway through.

### Capture the result

If the desktop fails, the answer is worth recording rather than repeating from
memory. Paste this block into PowerShell (elevated, so the feature check
returns) and it prints a short PASS/FAIL summary you can drop into a ticket or
send to whoever is helping you with the rollout:

```powershell
$os   = Get-CimInstance Win32_OperatingSystem
$cs   = Get-CimInstance Win32_ComputerSystem
$wsl  = (Get-Command wsl.exe -ErrorAction SilentlyContinue) -ne $null
$feat = 'Microsoft-Windows-Subsystem-Linux', 'VirtualMachinePlatform' | ForEach-Object { Get-WindowsOptionalFeature -Online -FeatureName $_ -ErrorAction SilentlyContinue }
$pol  = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WSL" -ErrorAction SilentlyContinue
$adm  = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

"aap_config WSL2 preflight — $(Get-Date -Format s)"
"  OS                : $($os.Caption) build $($os.BuildNumber)"
"  Virtualization    : $(if ($cs.HypervisorPresent) { 'PASS (hypervisor present)' } else { 'FAIL (not enabled in firmware/BIOS)' })"
"  WSL command       : $(if ($wsl) { 'PASS' } else { 'FAIL (not installed)' })"
foreach ($f in $feat) { "  Feature $($f.FeatureName) : $($f.State)" }
"  WSL group policy  : $(if ($pol) { 'FAIL (policy key present — ask IT)' } else { 'PASS (no policy block)' })"
"  Admin rights      : $(if ($adm) { 'PASS' } else { 'NOT ELEVATED (re-run as admin to be sure)' })"
```

Example output from a passing desktop:

```text
aap_config WSL2 preflight — 2026-08-16T07:38:20
  OS                : Microsoft Windows 11 Pro build 26200
  Virtualization    : PASS (hypervisor present)
  WSL command       : PASS
  Feature Microsoft-Windows-Subsystem-Linux : Disabled
  Feature VirtualMachinePlatform : Enabled
  WSL group policy  : PASS (no policy block)
  Admin rights      : PASS
```

Note the `Microsoft-Windows-Subsystem-Linux` optional feature can show
`Disabled` even on a desktop where WSL2 is installed and working fine (`WSL
command: PASS`, and you can be actively running a distro) — modern
Store-distributed WSL doesn't always depend on that legacy optional feature the
way older in-box WSL did. Treat `WSL command: PASS` plus a distro you can
actually `wsl` into as the real signal; don't chase this specific `Disabled` if
everything else already works.

Any `FAIL` on virtualization or the WSL policy key means this desktop needs a
shared Linux host, not a local container engine. Send the block as-is — it says
exactly which control is blocking, which is what IT needs to act on.

Next: [01-dev-environment.md](01-dev-environment.md).
