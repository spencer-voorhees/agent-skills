---
name: windows-vm-twin
description: Windows VM Configuration Cloning & Twin Generator. Performs 100% read-only discovery and deterministic extraction of Windows Server configurations (IIS sites, AppPools, SMB shares, NTFS ACLs, installed Windows features, SMTP IIS 6.0 metabase settings, and SMTPSVC service restart/recovery actions). Generates structured migration manifests, a human-readable inventory report, and automated PowerShell replay/validation runbooks to create an exact configuration twin on a blank VM.
---

# Windows VM Configuration Twin (`windows-vm-twin`)

## Overview & Purpose

The `windows-vm-twin` skill captures the entire configuration profile of a Windows Server virtual machine and produces a deterministic blueprint, inventory report, and automated replay runbook to reconstruct a **Configuration Twin** on a blank target VM.

```
┌────────────────────────────────────────┐
│           SOURCE WINDOWS VM            │
│   (IIS, AppPools, Sites, SMB, NTFS,    │
│    SMTP IIS 6.0, SMTPSVC Recovery)     │
└──────────────────┬─────────────────────┘
                   │
                   ▼  Phase 1: 100% Read-Only Discovery
┌────────────────────────────────────────┐
│        CONFIGURATION MANIFEST          │
│   - JSON Configs (Features, IIS, SMTP) │
│   - SDDL ACLs & Share Perms            │
│   - Content Archives & SHA256 Hashes   │
│   - Source-VM-Inventory-Report.md      │
└──────────────────┬─────────────────────┘
                   │
                   ▼  Phase 2: Blueprint & Synthesis
┌────────────────────────────────────────┐
│     TARGET BLUEPRINT & PARAMETERS      │
│   - twin-parameters.json (Overrides)   │
│   - Target-Replay-Runbook.md           │
└──────────────────┬─────────────────────┘
                   │
                   ▼  Phase 3: Automated Replay & Provisioning
┌────────────────────────────────────────┐
│            TARGET BLANK VM             │
│   (Features -> Accounts -> Content ->  │
│    ACLs -> Shares -> IIS -> SMTP ->    │
│    Service Recovery -> Firewall)       │
└──────────────────┬─────────────────────┘
                   │
                   ▼  Phase 4: Twin Verification & Audit
┌────────────────────────────────────────┐
│       TWIN VERIFICATION REPORT         │
│   (Pass/Fail/Drift Audit Report)       │
└────────────────────────────────────────┘
```

---

## The Read-Only Guarantee

> [!IMPORTANT]
> **Zero Source Mutation**:
> All actions executed on the source VM are strictly non-mutating.
> - Only read-only cmdlets (`Get-*`, WMI/CIM queries, ADSI property readers, `sc.exe qfailure`, read-only file streams) are used.
> - No temporary files are written to `C:\Windows`, `C:\inetpub`, registry keys, or system directories.
> - All extracted data is streamed directly to a designated export directory or zip bundle.
> - No services are stopped, restarted, or reconfigured during discovery.

---

## Production Guard Rails (Target Side)

`Apply-TargetVmTwin.ps1` is the only script that mutates a machine, and it is fenced for production use:

- **Dry-run first**: every stage honors `-WhatIf`, reporting what it would change without touching the machine.
- **Wrong-server protection**: the script refuses to run when the local hostname matches the source VM recorded in the manifest — i.e. it was accidentally launched on the production source instead of the target. Override with `-AllowSourceHostName` only when the target legitimately reuses the source hostname.
- **System-path protection**: content extraction, SDDL replay, and share creation refuse drive roots and anything under `C:\Windows`, so a bad `PathMappings` entry cannot rewrite the security descriptor of `C:\`.
- **Idempotent re-runs**: existing app pools and sites are updated in place, existing shares and firewall rules are skipped, and content extraction overwrites cleanly — a failed run can be resumed without cleanup.

**Handling the export bundle**: the manifests contain hostnames, machine environment variables, ACL SDDL strings, and SMTP relay lists. No passwords are ever captured, but treat the bundle — and `twin-parameters.json`, which may hold target credentials you add — as sensitive: restrict access and transfer over secure channels. Content archival reads every site/share file, so for large content sets schedule `Export-SiteContent.ps1` in a low-traffic window.

---

## 4-Phase Lifecycle

### Phase 1: Source Discovery & Extraction (Source VM)

Run the discovery script in an elevated PowerShell session on the Source VM:

```powershell
# 1. Export configuration manifests and inventory report (Read-Only)
.\scripts\Export-SourceVmTwin.ps1 -OutputDir "C:\VM-Twin-Export" -IncludeCertificates -IncludeFirewall

# 2. Package website and share contents with hash validation (Read-Only)
.\scripts\Export-SiteContent.ps1 -ManifestDir "C:\VM-Twin-Export" -OutputDir "C:\VM-Twin-Export\Content" -Compress
```

#### What is Extracted:
| Manifest File | Captured Subsystems & Settings |
|---|---|
| `manifest.json` | Master bundle metadata, source hostname, OS version, capture timestamp, component checksums. |
| `windows-features.json` | Installed Windows Server Roles and Features (IIS sub-features, ASP.NET, SMTP Server, Tools). |
| `iis-apppools.json` | Application Pools: .NET CLR version, 32-bit mode, Pipeline Mode, Identity (Service Accounts/Custom), Recycling limits, Idle timeouts, CPU throttles. |
| `iis-sites.json` | Websites, Applications, Virtual Directories: Physical paths, AppPool mappings, bindings (HTTP/HTTPS/IP/Ports/Hostheaders), SSL certificate thumbprints. |
| `applicationHost.config.bak` | Raw read-only snapshot of the full IIS `applicationHost.config` (global modules, handlers, request filtering) for reference and diffing. |
| `smb-shares.json` | SMB Network Shares: Share names, physical paths, descriptions, caching modes, Share-level permissions (Read, Change, FullControl). |
| `ntfs-acls.json` | NTFS Access Control Lists for all site directories and share roots: Preserved as structured ACEs and Security Descriptor Definition Language (SDDL). |
| `smtp-config.json` | IIS 6.0 SMTP Server (`SmtpSvc/1`): Port bindings, IP addresses, Relay IP restrictions (`RelayIpList`), Smart Host (`SmartHost`), Drop Directory (`DropDir`), Pickup/BadMail dirs, authentication, connection limits. |
| `smtp-service.json` | `SMTPSVC` Windows Service: Startup type (`Automatic`, `Manual`, `Delayed-Auto`) and Failure/Recovery Actions (Restart service delay, reset failure count interval, action sequence). |
| `ssl-certificates.json` | SSL Certificate metadata in `LocalMachine\My` and `WebHosting` stores (Subject, Thumbprint, Issuer, Expiration, FriendlyName). |
| `local-accounts.json` | Non-built-in local users and custom local groups, including group membership, so accounts referenced by AppPools or NTFS/SMB permissions can be recreated. |
| `firewall-rules.json` | Active Windows Firewall rules for HTTP (80), HTTPS (443), SMTP (25/587), and SMB (445). |
| `system-metadata.json` | Computer name, domain/workgroup, OS build, timezone, network adapters, environment variables. |
| `Source-VM-Inventory-Report.md` | Human-readable audit report summarizing the complete server inventory. |

---

### Phase 2: Blueprint & Synthesis (Workstation / AI Agent)

Synthesize the extracted bundle into a customized target blueprint:

```powershell
.\scripts\New-TwinBlueprint.ps1 `
    -ManifestDir "C:\VM-Twin-Export" `
    -OutputDir "C:\VM-Twin-Blueprint"
```

#### Blueprint Artifacts Generated:
1. `twin-parameters.json`: Configuration overrides file where you can customize:
   - Target drive letters / path mappings (e.g. `D:\Sites` → `E:\WebSites`).
   - Domain or service account remapping (e.g. `OLDDOM\svc_web` → `NEWDOM\svc_web` or local accounts).
   - IP address and SSL certificate thumbprint re-bindings.
   - SMTP Smart Host or Relay overrides for the new environment.
2. `Target-Replay-Runbook.md`: A markdown execution runbook detailing exact commands, dependencies, and validation checkpoints.

---

### Phase 3: Target VM Replay & Provisioning (Blank Target VM)

Transfer the blueprint and content archives to the blank target VM and run the replay engine. Every stage supports `-WhatIf` for a dry run that reports what would change without touching the machine:

```powershell
# Run the complete automated provisioning pipeline
.\scripts\Apply-TargetVmTwin.ps1 `
    -BlueprintDir "C:\VM-Twin-Blueprint" `
    -ContentDir "C:\VM-Twin-Export\Content" `
    -ParametersFile "C:\VM-Twin-Blueprint\twin-parameters.json"

# Or execute step-by-step for controlled staging:
.\scripts\Apply-TargetVmTwin.ps1 -BlueprintDir "C:\VM-Twin-Blueprint" -Step Features
.\scripts\Apply-TargetVmTwin.ps1 -BlueprintDir "C:\VM-Twin-Blueprint" -Step Accounts
.\scripts\Apply-TargetVmTwin.ps1 -BlueprintDir "C:\VM-Twin-Blueprint" -Step Content -ContentDir "C:\VM-Twin-Export\Content"
.\scripts\Apply-TargetVmTwin.ps1 -BlueprintDir "C:\VM-Twin-Blueprint" -Step Acls
.\scripts\Apply-TargetVmTwin.ps1 -BlueprintDir "C:\VM-Twin-Blueprint" -Step Shares
.\scripts\Apply-TargetVmTwin.ps1 -BlueprintDir "C:\VM-Twin-Blueprint" -Step Iis
.\scripts\Apply-TargetVmTwin.ps1 -BlueprintDir "C:\VM-Twin-Blueprint" -Step Smtp
.\scripts\Apply-TargetVmTwin.ps1 -BlueprintDir "C:\VM-Twin-Blueprint" -Step Service
.\scripts\Apply-TargetVmTwin.ps1 -BlueprintDir "C:\VM-Twin-Blueprint" -Step Firewall
```

#### Execution Stages:
1. **Features**: Installs all required Server Roles (Web-Server, ASP.NET, SMTP-Server, IIS Management tools) and checks if a reboot is needed.
2. **Accounts**: Creates required local service users (passwords supplied via `twin-parameters.json`), recreates custom local groups, and replays group membership.
3. **Content**: Restores file trees for websites and shared folders to target physical locations.
4. **ACLs**: Replays exact NTFS security descriptors (SDDL), then re-grants ACEs for source-machine-local accounts by name — their source SIDs cannot resolve on a new machine.
5. **Shares**: Provisions SMB shares with matching names, descriptions, and share-level permissions (including deny entries), re-applied on every run.
6. **IIS**: Rebuilds Application Pools (identities, recycling, 32-bit), Sites, Virtual Directories, and Bindings (including SNI SSL flags and certificate re-binding).
7. **SMTP**: Configures IIS 6.0 SMTP Server via ADSI (Relay IP list, Smart Host, Drop directory, connection limits).
8. **Service**: Sets `SMTPSVC` startup type and failure recovery actions (`sc.exe failure` to restart automatically on crash).
9. **Firewall**: Recreates the inbound Windows Firewall rules captured from the source (falls back to standard HTTP/HTTPS/SMTP/SMB rules when no manifest is present).

---

### Phase 4: Twin Verification & Drift Audit

Validate the provisioned target VM against the source manifest:

```powershell
.\scripts\Test-TargetVmTwin.ps1 `
    -ManifestDir "C:\VM-Twin-Export" `
    -ParametersFile "C:\VM-Twin-Blueprint\twin-parameters.json" `
    -ReportPath "C:\VM-Twin-Blueprint\Twin-Verification-Report.md"
```

The script outputs a comprehensive verification report:
- **Feature Parity**: Validates all source Windows features are installed.
- **IIS State**: Verifies AppPools are running, configured with correct identities, and sites are listening on expected bindings.
- **HTTP / Endpoint Health**: TCP listener probes for every HTTP/HTTPS binding, plus HTTP response probes against HTTP endpoints.
- **SMB & NTFS Integrity**: Confirms network shares exist at the mapped target paths and directory ACLs match the source SDDL exactly.
- **SMTP Service & Configuration**: Verifies SMTP port 25 listener, relay restrictions, drop directory path, and `sc.exe qfailure` recovery settings.

---

## Detailed Subsystem Handling

### 1. IIS 6.0 SMTP & Service Recovery
The legacy IIS 6.0 SMTP stack is managed through the ADSI metabase (`IIS://localhost/SmtpSvc/1`) and the Windows Service Control Manager (`sc.exe`):
- **Relay Restrictions**: Exported from `RelayIpList` binary octet streams and ADSI properties, replayed deterministically.
- **Automatic Restart on Failure**: Extracted via `sc.exe qfailure SMTPSVC` and configured via `sc.exe failure SMTPSVC reset= 86400 actions= restart/60000/restart/60000/restart/60000`.

### 2. High-Fidelity NTFS Permissions (SDDL)
NTFS permissions are extracted and applied using **Security Descriptor Definition Language (SDDL)** strings alongside structured JSON rules. This eliminates locale-dependent translation issues (e.g. `NT AUTHORITY\SYSTEM` vs localized names) and ensures exact inheritance flags and ACE flags are preserved.

Because machine-local accounts get **new SIDs** on the target, SDDL alone would leave their ACEs orphaned. The replay engine therefore follows the SDDL pass with a by-name re-grant: every non-inherited ACE whose identity was `SOURCEHOST\account` is re-added for the mapped target account (via `AccountMappings`), after verifying the account resolves. Run the **Accounts** stage before **ACLs** so those accounts exist.

### 3. Application Pool Identities & Credentials
- Built-in identities (`ApplicationPoolIdentity`, `NetworkService`, `LocalSystem`, `LocalService`) are re-created automatically.
- Custom domain or local user identities are flagged in `twin-parameters.json` so secure credentials can be supplied at target replay without exposing plaintext passwords in export files.

---

## Script Reference Summary

| Script | Purpose | Machine | Mutation Risk |
|---|---|---|---|
| [`Export-SourceVmTwin.ps1`](scripts/Export-SourceVmTwin.ps1) | Extracts all configuration manifests into JSON & markdown | Source VM | **Strictly None (Read-Only)** |
| [`Export-SiteContent.ps1`](scripts/Export-SiteContent.ps1) | Packages web roots and share folders into zip archives | Source VM | **Strictly None (Read-Only)** |
| [`New-TwinBlueprint.ps1`](scripts/New-TwinBlueprint.ps1) | Generates parameter overrides & customized replay runbook | Workstation / Target | Local files only |
| [`Apply-TargetVmTwin.ps1`](scripts/Apply-TargetVmTwin.ps1) | Replays configuration onto blank Windows VM | Target VM | Configures target VM |
| [`Test-TargetVmTwin.ps1`](scripts/Test-TargetVmTwin.ps1) | Audits target VM against source manifest for drift | Target VM | **Strictly None (Read-Only)** |
