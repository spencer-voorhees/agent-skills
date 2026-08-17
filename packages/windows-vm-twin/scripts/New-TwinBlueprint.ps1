<#
.SYNOPSIS
    Synthesizes source VM manifests into a target deployment blueprint and parameter template.
.DESCRIPTION
    Reads exported JSON manifests, generates twin-parameters.json with pre-populated
    overrides for paths, service accounts, and IP bindings, and creates a tailored
    Target-Replay-Runbook.md.
.PARAMETER ManifestDir
    Path to directory containing exported JSON manifests from Export-SourceVmTwin.ps1.
.PARAMETER OutputDir
    Directory where blueprint artifacts and parameters will be written.
.EXAMPLE
    .\New-TwinBlueprint.ps1 -ManifestDir "C:\VM-Twin-Export" -OutputDir "C:\VM-Twin-Blueprint"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ManifestDir = ".\VM-Twin-Export",

    [Parameter(Mandatory = $false)]
    [string]$OutputDir = ".\VM-Twin-Blueprint"
)

$ErrorActionPreference = "Stop"

$resolvedManifestDir = [System.IO.Path]::GetFullPath($ManifestDir)
$resolvedOutputDir = [System.IO.Path]::GetFullPath($OutputDir)

if (-not (Test-Path -LiteralPath $resolvedOutputDir)) {
    $null = New-Item -ItemType Directory -Path $resolvedOutputDir -Force
}

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host " Windows VM Configuration Twin - Blueprint Synthesizer" -ForegroundColor Cyan
Write-Host " Source Manifests: $resolvedManifestDir" -ForegroundColor Yellow
Write-Host " Blueprint Target: $resolvedOutputDir" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Cyan

# Load manifests
function Load-ManifestJson([string]$name) {
    $p = Join-Path -Path $resolvedManifestDir -ChildPath $name
    if (Test-Path -LiteralPath $p) {
        return (Get-Content -LiteralPath $p -Raw | ConvertFrom-Json)
    }
    return $null
}

$metadata       = Load-ManifestJson "system-metadata.json"
$features       = Load-ManifestJson "windows-features.json"
$apppools       = Load-ManifestJson "iis-apppools.json"
$sites          = Load-ManifestJson "iis-sites.json"
$shares         = Load-ManifestJson "smb-shares.json"
$acls           = Load-ManifestJson "ntfs-acls.json"
$smtpConfig     = Load-ManifestJson "smtp-config.json"
$smtpService    = Load-ManifestJson "smtp-service.json"
$certs          = Load-ManifestJson "ssl-certificates.json"
$localAccounts  = Load-ManifestJson "local-accounts.json"

# Build twin-parameters.json template
$pathMappings = [ordered]@{}
$accountMappings = [ordered]@{}
$bindingOverrides = [ordered]@{}
$smtpOverrides = [ordered]@{}

# Extract all paths
if ($acls) {
    foreach ($a in $acls) {
        if ($a.Path) {
            $pathMappings[$a.Path] = $a.Path # Default to identical target path
        }
    }
}

# Extract custom service accounts in AppPools
if ($apppools) {
    foreach ($p in $apppools) {
        if ($p.ProcessModel -and $p.ProcessModel.IdentityType -eq "SpecificUser" -and $p.ProcessModel.UserName) {
            $u = $p.ProcessModel.UserName
            if (-not $accountMappings.Contains($u)) {
                $accountMappings[$u] = [ordered]@{
                    TargetUserName = $u
                    TargetPassword = "REPLACE_WITH_TARGET_PASSWORD_OR_LEAVE_EMPTY"
                }
            }
        }
    }
}

# Extract custom accounts in shares
if ($shares) {
    foreach ($sh in $shares) {
        foreach ($acc in $sh.AccessPermissions) {
            if ($acc.AccountName -and $acc.AccountName -notmatch "BUILTIN|NT AUTHORITY|Everyone") {
                if (-not $accountMappings.Contains($acc.AccountName)) {
                    $accountMappings[$acc.AccountName] = [ordered]@{
                        TargetUserName = $acc.AccountName
                        TargetPassword = ""
                    }
                }
            }
        }
    }
}

# Seed captured custom local users so target passwords can be supplied for
# re-creation (source password hashes are never captured and cannot migrate)
if ($localAccounts -and $localAccounts.Users) {
    foreach ($u in @($localAccounts.Users)) {
        if ($u.Name -and -not $accountMappings.Contains($u.Name)) {
            $accountMappings[$u.Name] = [ordered]@{
                TargetUserName = $u.Name
                TargetPassword = "REPLACE_WITH_TARGET_PASSWORD_OR_LEAVE_EMPTY"
            }
        }
    }
}

# SSL / IP Binding overrides
if ($sites) {
    foreach ($s in $sites) {
        foreach ($b in $s.Bindings) {
            if ($b.CertificateThumbprint) {
                $bindingOverrides[$b.BindingInformation] = [ordered]@{
                    Protocol                = $b.Protocol
                    Host                    = $b.Host
                    OriginalThumbprint      = $b.CertificateThumbprint
                    TargetThumbprint        = $b.CertificateThumbprint
                    CertificateStore        = if ($b.CertificateStoreName) { $b.CertificateStoreName } else { "My" }
                }
            }
        }
    }
}

# SMTP overrides
if ($smtpConfig -and $smtpConfig.Installed) {
    $smtpOverrides = [ordered]@{
        SmartHost            = $smtpConfig.Properties.SmartHost
        DropDir              = $smtpConfig.Properties.DropDir
        Port                 = $smtpConfig.Properties.Port
        ApplyRelayList       = $true
        AllowTargetIpRelay   = $true
    }
}

$twinParams = [ordered]@{
    TargetEnvironment = [ordered]@{
        TargetHostName        = ""
        TargetDomainOrWorkgroup = ""
        ExecutionMode         = "Automated" # Automated | Manual
    }
    PathMappings             = $pathMappings
    AccountMappings          = $accountMappings
    BindingOverrides         = $bindingOverrides
    SmtpOverrides            = $smtpOverrides
    ServiceRecoveryOverrides = [ordered]@{
        ConfigureSmtpAutoRestart = $true
        ResetPeriodSeconds       = if ($smtpService.RecoverySettings.ResetPeriodSeconds) { $smtpService.RecoverySettings.ResetPeriodSeconds } else { 86400 }
        RestartDelayMilliseconds = 60000
    }
}

$paramsFilePath = Join-Path -Path $resolvedOutputDir -ChildPath "twin-parameters.json"
$paramsJson = $twinParams | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($paramsFilePath, $paramsJson, [System.Text.Encoding]::UTF8)
Write-Host "  [+] Generated: twin-parameters.json" -ForegroundColor Green

# Generate Tailored Runbook
$runbookPath = Join-Path -Path $resolvedOutputDir -ChildPath "Target-Replay-Runbook.md"
$rb = [System.Text.StringBuilder]::new()

[void]$rb.AppendLine("# Target VM Configuration Twin Replay Runbook")
[void]$rb.AppendLine("Source Host: **$($metadata.ComputerName)** | OS: **$($metadata.OperatingSystem)**")
[void]$rb.AppendLine("Generated: **$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')**")
[void]$rb.AppendLine("")
[void]$rb.AppendLine("---")
[void]$rb.AppendLine("## Pre-Flight Checklist")
[void]$rb.AppendLine("- [ ] Target Windows VM is online with Administrator access.")
[void]$rb.AppendLine("- [ ] Manifest directory and content archives transferred to target VM.")
[void]$rb.AppendLine("- [ ] Review and adjust ``twin-parameters.json`` (credentials, paths, IP bindings).")
[void]$rb.AppendLine("- [ ] Optional: dry-run any stage first with ``Apply-TargetVmTwin.ps1 ... -WhatIf``.")
if ($certs -and $certs.Count -gt 0) {
    [void]$rb.AppendLine("- [ ] Import required SSL certificates into ``LocalMachine\My`` or ``WebHosting`` store.")
}
[void]$rb.AppendLine("")
[void]$rb.AppendLine("---")
[void]$rb.AppendLine("## Automated Replay Command")
[void]$rb.AppendLine("Run the complete provisioning sequence on the target VM:")
[void]$rb.AppendLine('```powershell')
[void]$rb.AppendLine(".\Apply-TargetVmTwin.ps1 -BlueprintDir `"$resolvedOutputDir`" -ContentDir `"<PathToContentArchives>`" -ParametersFile `"$paramsFilePath`"")
[void]$rb.AppendLine('```')
[void]$rb.AppendLine("")
[void]$rb.AppendLine("---")
[void]$rb.AppendLine("## Modular Execution Stages")
[void]$rb.AppendLine("If deploying interactively or staging per change-window:")
[void]$rb.AppendLine("")
[void]$rb.AppendLine("### Stage 1: Install Windows Features & Roles")
[void]$rb.AppendLine('```powershell')
[void]$rb.AppendLine(".\Apply-TargetVmTwin.ps1 -BlueprintDir `"$resolvedOutputDir`" -Step Features")
[void]$rb.AppendLine('```')
[void]$rb.AppendLine("")
[void]$rb.AppendLine("### Stage 2: Create Service Accounts & Local Groups")
[void]$rb.AppendLine('```powershell')
[void]$rb.AppendLine(".\Apply-TargetVmTwin.ps1 -BlueprintDir `"$resolvedOutputDir`" -Step Accounts -ParametersFile `"$paramsFilePath`"")
[void]$rb.AppendLine('```')
[void]$rb.AppendLine("")
[void]$rb.AppendLine("### Stage 3: Restore Content & Apply NTFS ACLs")
[void]$rb.AppendLine('```powershell')
[void]$rb.AppendLine(".\Apply-TargetVmTwin.ps1 -BlueprintDir `"$resolvedOutputDir`" -Step Content -ContentDir `"<PathToContentArchives>`"")
[void]$rb.AppendLine(".\Apply-TargetVmTwin.ps1 -BlueprintDir `"$resolvedOutputDir`" -Step Acls")
[void]$rb.AppendLine('```')
[void]$rb.AppendLine("")
[void]$rb.AppendLine("### Stage 4: Create SMB Network Shares")
[void]$rb.AppendLine('```powershell')
[void]$rb.AppendLine(".\Apply-TargetVmTwin.ps1 -BlueprintDir `"$resolvedOutputDir`" -Step Shares")
[void]$rb.AppendLine('```')
[void]$rb.AppendLine("")
[void]$rb.AppendLine("### Stage 5: Rebuild IIS AppPools & Websites")
[void]$rb.AppendLine('```powershell')
[void]$rb.AppendLine(".\Apply-TargetVmTwin.ps1 -BlueprintDir `"$resolvedOutputDir`" -Step Iis -ParametersFile `"$paramsFilePath`"")
[void]$rb.AppendLine('```')
[void]$rb.AppendLine("")
[void]$rb.AppendLine("### Stage 6: Configure IIS 6.0 SMTP Server")
[void]$rb.AppendLine('```powershell')
[void]$rb.AppendLine(".\Apply-TargetVmTwin.ps1 -BlueprintDir `"$resolvedOutputDir`" -Step Smtp -ParametersFile `"$paramsFilePath`"")
[void]$rb.AppendLine('```')
[void]$rb.AppendLine("")
[void]$rb.AppendLine("### Stage 7: Configure SMTPSVC Service Auto-Restart & Recovery")
[void]$rb.AppendLine('```powershell')
[void]$rb.AppendLine(".\Apply-TargetVmTwin.ps1 -BlueprintDir `"$resolvedOutputDir`" -Step Service -ParametersFile `"$paramsFilePath`"")
[void]$rb.AppendLine('```')
[void]$rb.AppendLine("")
[void]$rb.AppendLine("### Stage 8: Configure Windows Firewall Rules")
[void]$rb.AppendLine('```powershell')
[void]$rb.AppendLine(".\Apply-TargetVmTwin.ps1 -BlueprintDir `"$resolvedOutputDir`" -Step Firewall")
[void]$rb.AppendLine('```')
[void]$rb.AppendLine("")
[void]$rb.AppendLine("### Stage 9: Verify Parity")
[void]$rb.AppendLine('```powershell')
[void]$rb.AppendLine(".\Test-TargetVmTwin.ps1 -ManifestDir `"$resolvedManifestDir`" -ParametersFile `"$paramsFilePath`"")
[void]$rb.AppendLine('```')

[System.IO.File]::WriteAllText($runbookPath, $rb.ToString(), [System.Text.Encoding]::UTF8)
Write-Host "  [+] Generated: Target-Replay-Runbook.md" -ForegroundColor Green

# Copy manifests to blueprint folder for portable handoff
$copiedManifestDir = Join-Path -Path $resolvedOutputDir -ChildPath "Manifests"
if (-not (Test-Path -LiteralPath $copiedManifestDir)) {
    $null = New-Item -ItemType Directory -Path $copiedManifestDir -Force
}

Get-ChildItem -Path $resolvedManifestDir -Filter "*.json" | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $copiedManifestDir -Force
}
if (Test-Path (Join-Path $resolvedManifestDir "applicationHost.config.bak")) {
    Copy-Item -LiteralPath (Join-Path $resolvedManifestDir "applicationHost.config.bak") -Destination $copiedManifestDir -Force
}

Write-Host "`n[+] Blueprint generated successfully at: $resolvedOutputDir" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
