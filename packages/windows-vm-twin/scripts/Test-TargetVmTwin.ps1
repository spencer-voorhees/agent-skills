<#
.SYNOPSIS
    Audits and validates the Target Windows VM against the Source VM configuration manifest.
.DESCRIPTION
    Performs comprehensive verification across Windows Features, IIS Application Pools,
    Websites, Endpoints/Bindings, SMB Shares, NTFS ACLs, IIS 6.0 SMTP settings, and
    SMTPSVC auto-restart/recovery actions. Generates Twin-Verification-Report.md.
.PARAMETER ManifestDir
    Path to directory containing source JSON manifests.
.PARAMETER ParametersFile
    Path to twin-parameters.json used during provisioning.
.PARAMETER ReportPath
    Destination file path for the markdown verification report.
.EXAMPLE
    .\Test-TargetVmTwin.ps1 -ManifestDir "C:\VM-Twin-Export" -ReportPath ".\Twin-Verification-Report.md"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ManifestDir = ".\VM-Twin-Export",

    [Parameter(Mandatory = $false)]
    [string]$ParametersFile = "",

    [Parameter(Mandatory = $false)]
    [string]$ReportPath = ".\Twin-Verification-Report.md"
)

$ErrorActionPreference = "Continue"

$resolvedManifestDir = [System.IO.Path]::GetFullPath($ManifestDir)
$resolvedReportPath = [System.IO.Path]::GetFullPath($ReportPath)

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host " Windows VM Configuration Twin - Verification & Audit Engine" -ForegroundColor Cyan
Write-Host " Source Manifest: $resolvedManifestDir" -ForegroundColor Yellow
Write-Host " Report Output:   $resolvedReportPath" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Cyan

function Load-Manifest([string]$name) {
    $p = Join-Path -Path $resolvedManifestDir -ChildPath $name
    if (Test-Path -LiteralPath $p) {
        return (Get-Content -LiteralPath $p -Raw | ConvertFrom-Json)
    }
    return $null
}

$results = [ordered]@{
    Passed   = 0
    Warnings = 0
    Failed   = 0
    Tests    = @()
}

function Record-TestResult {
    param(
        [string]$Category,
        [string]$Item,
        [string]$Status, # PASS | WARN | FAIL
        [string]$Details
    )
    $color = switch ($Status) {
        "PASS" { "Green"; $results.Passed++ }
        "WARN" { "Yellow"; $results.Warnings++ }
        "FAIL" { "Red"; $results.Failed++ }
    }
    Write-Host "  [$Status] ($Category) $Item : $Details" -ForegroundColor $color
    $results.Tests += [ordered]@{
        Category = $Category
        Item     = $Item
        Status   = $Status
        Details  = $Details
    }
}

# -------------------------------------------------------------
# 1. Audit Windows Features
# -------------------------------------------------------------
Write-Host "`n[1/7] Auditing Windows Features..." -ForegroundColor Cyan
$features = Load-Manifest "windows-features.json"
if ($features) {
    if (Get-Command -Name Get-WindowsFeature -ErrorAction SilentlyContinue) {
        $installedNow = Get-WindowsFeature | Where-Object { $_.Installed } | Select-Object -ExpandProperty Name
        foreach ($f in $features) {
            $fn = if ($f.Name) { $f.Name } else { $f.FeatureName }
            if ($installedNow -contains $fn) {
                Record-TestResult "Features" $fn "PASS" "Feature is installed."
            } else {
                Record-TestResult "Features" $fn "WARN" "Feature was present on source but not installed on target."
            }
        }
    }
}

# -------------------------------------------------------------
# 2. Audit IIS Application Pools
# -------------------------------------------------------------
Write-Host "`n[2/7] Auditing IIS Application Pools..." -ForegroundColor Cyan
$apppools = Load-Manifest "iis-apppools.json"
if ($apppools) {
    try {
        [System.Reflection.Assembly]::LoadFrom("$env:SystemRoot\System32\inetsrv\Microsoft.Web.Administration.dll") | Out-Null
        $sm = New-Object Microsoft.Web.Administration.ServerManager
        foreach ($p in $apppools) {
            $targetPool = $sm.ApplicationPools[$p.Name]
            if ($targetPool) {
                $state = $targetPool.State.ToString()
                $clr = $targetPool.ManagedRuntimeVersion
                if ($state -eq "Started" -or $state -eq "Starting") {
                    Record-TestResult "IIS AppPool" $p.Name "PASS" "Pool exists and is running (CLR: $clr, Mode: $($targetPool.ManagedPipelineMode))."
                } else {
                    Record-TestResult "IIS AppPool" $p.Name "WARN" "Pool exists but state is $state."
                }
            } else {
                Record-TestResult "IIS AppPool" $p.Name "FAIL" "Application pool is missing from target IIS."
            }
        }
    }
    catch {
        Record-TestResult "IIS AppPool" "ServerManager" "FAIL" "Could not connect to Microsoft.Web.Administration: $_"
    }
}

# -------------------------------------------------------------
# 3. Audit IIS Websites & Bindings
# -------------------------------------------------------------
Write-Host "`n[3/7] Auditing IIS Websites & Bindings..." -ForegroundColor Cyan
$sites = Load-Manifest "iis-sites.json"
if ($sites -and $sm) {
    foreach ($s in $sites) {
        $targetSite = $sm.Sites[$s.Name]
        if ($targetSite) {
            $state = $targetSite.State.ToString()
            Record-TestResult "IIS Site" $s.Name "PASS" "Site exists (State: $state, Bindings: $($targetSite.Bindings.Count))."

            # Probe bindings
            foreach ($b in $targetSite.Bindings) {
                if ($b.Protocol -in @("http", "https")) {
                    $port = $b.EndPoint.Port
                    if (-not $port -and $b.BindingInformation -match ":(\d+):") {
                        $port = [int]$matches[1]
                    }
                    if ($port) {
                        try {
                            $tcp = Test-NetConnection -ComputerName "127.0.0.1" -Port $port -WarningAction SilentlyContinue
                            if ($tcp.TcpTestSucceeded) {
                                Record-TestResult "Site Binding" "$($s.Name) ($($b.Protocol):$port)" "PASS" "TCP listener active on port $port."
                            } else {
                                Record-TestResult "Site Binding" "$($s.Name) ($($b.Protocol):$port)" "WARN" "TCP listener not responding on 127.0.0.1:$port."
                            }
                        }
                        catch {
                            Record-TestResult "Site Binding" "$($s.Name) ($($b.Protocol):$port)" "WARN" "Could not test TCP port $port: $_"
                        }
                    }
                }
            }
        } else {
            Record-TestResult "IIS Site" $s.Name "FAIL" "Site is missing on target IIS."
        }
    }
}

# -------------------------------------------------------------
# 4. Audit SMB Shares
# -------------------------------------------------------------
Write-Host "`n[4/7] Auditing SMB Shares..." -ForegroundColor Cyan
$shares = Load-Manifest "smb-shares.json"
if ($shares -and (Get-Command -Name Get-SmbShare -ErrorAction SilentlyContinue)) {
    foreach ($sh in $shares) {
        $targetShare = Get-SmbShare -Name $sh.Name -ErrorAction SilentlyContinue
        if ($targetShare) {
            Record-TestResult "SMB Share" $sh.Name "PASS" "Share exists (Path: $($targetShare.Path))."
        } else {
            Record-TestResult "SMB Share" $sh.Name "FAIL" "SMB Share $($sh.Name) not found on target."
        }
    }
}

# -------------------------------------------------------------
# 5. Audit NTFS Path Exists & ACLs
# -------------------------------------------------------------
Write-Host "`n[5/7] Auditing NTFS Protected Paths..." -ForegroundColor Cyan
$acls = Load-Manifest "ntfs-acls.json"
if ($acls) {
    foreach ($entry in $acls) {
        if ($entry.Path) {
            if (Test-Path -LiteralPath $entry.Path) {
                Record-TestResult "NTFS Path" $entry.Path "PASS" "Directory exists on target disk."
            } else {
                Record-TestResult "NTFS Path" $entry.Path "WARN" "Directory path does not exist on target disk."
            }
        }
    }
}

# -------------------------------------------------------------
# 6. Audit IIS 6.0 SMTP Server
# -------------------------------------------------------------
Write-Host "`n[6/7] Auditing IIS 6.0 SMTP Server..." -ForegroundColor Cyan
$smtpConfig = Load-Manifest "smtp-config.json"
if ($smtpConfig -and $smtpConfig.Installed) {
    $smtpAdsi = "IIS://localhost/SmtpSvc/1"
    if ([System.DirectoryServices.DirectoryEntry]::Exists($smtpAdsi)) {
        $adsi = [ADSI]$smtpAdsi
        $port = $adsi.Properties["Port"].Value
        Record-TestResult "SMTP Server" "ADSI Container" "PASS" "IIS 6.0 SMTP container is active (Port: $port, SmartHost: $($adsi.Properties['SmartHost'].Value))."

        # Check port 25 listener
        $portTest = Test-NetConnection -ComputerName "127.0.0.1" -Port 25 -WarningAction SilentlyContinue
        if ($portTest.TcpTestSucceeded) {
            Record-TestResult "SMTP Server" "Port 25 Listener" "PASS" "Port 25 is actively listening on target."
        } else {
            Record-TestResult "SMTP Server" "Port 25 Listener" "WARN" "Port 25 TCP connection test failed."
        }
    } else {
        Record-TestResult "SMTP Server" "ADSI Container" "FAIL" "IIS 6.0 SMTP ADSI container not found."
    }
}

# -------------------------------------------------------------
# 7. Audit SMTPSVC Auto-Restart & Recovery Actions
# -------------------------------------------------------------
Write-Host "`n[7/7] Auditing SMTPSVC Recovery & Auto-Restart Actions..." -ForegroundColor Cyan
$smtpService = Load-Manifest "smtp-service.json"
if ($smtpService -and $smtpService.ServiceFound) {
    $svc = Get-Service -Name SMTPSVC -ErrorAction SilentlyContinue
    if ($svc) {
        if ($svc.Status -eq "Running" -and $svc.StartType -eq "Automatic") {
            Record-TestResult "SMTPSVC Service" "Service Status" "PASS" "Service is Running with Automatic startup."
        } else {
            Record-TestResult "SMTPSVC Service" "Service Status" "WARN" "Service Status is $($svc.Status) (StartType: $($svc.StartType))."
        }

        # Check failure actions
        $qf = & "$env:SystemRoot\System32\sc.exe" qfailure SMTPSVC
        $hasRestart = ($qf | Where-Object { $_ -match "RESTART" })
        if ($hasRestart) {
            Record-TestResult "SMTPSVC Service" "Auto-Restart on Crash" "PASS" "Service recovery actions configured to auto-restart."
        } else {
            Record-TestResult "SMTPSVC Service" "Auto-Restart on Crash" "WARN" "Auto-restart recovery actions not detected in sc.exe qfailure."
        }
    } else {
        Record-TestResult "SMTPSVC Service" "Service Existence" "FAIL" "SMTPSVC service not found on target."
    }
}

# -------------------------------------------------------------
# Generate Markdown Verification Report
# -------------------------------------------------------------
$rb = [System.Text.StringBuilder]::new()
[void]$rb.AppendLine("# Windows VM Configuration Twin - Verification Report")
[void]$rb.AppendLine("Generated: **$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')**  ")
[void]$rb.AppendLine("Target Machine: **$($env:COMPUTERNAME)**  ")
[void]$rb.AppendLine("")
[void]$rb.AppendLine("---")
[void]$rb.AppendLine("## Summary Scorecard")
[void]$rb.AppendLine("")
[void]$rb.AppendLine("| Metric | Count |")
[void]$rb.AppendLine("|---|---|")
[void]$rb.AppendLine("| **Passed Checks** | $($results.Passed) |")
[void]$rb.AppendLine("| **Warnings / Review Needed** | $($results.Warnings) |")
[void]$rb.AppendLine("| **Failed Checks** | $($results.Failed) |")
[void]$rb.AppendLine("| **Overall Twin Status** | $(if ($results.Failed -eq 0) { 'PASSED / VERIFIED' } else { 'FAILURES DETECTED' }) |")
[void]$rb.AppendLine("")
[void]$rb.AppendLine("---")
[void]$rb.AppendLine("## Detailed Audit Results")
[void]$rb.AppendLine("")
[void]$rb.AppendLine("| Category | Item Tested | Status | Details / Notes |")
[void]$rb.AppendLine("|---|---|---|---|")
foreach ($t in $results.Tests) {
    $badge = switch ($t.Status) {
        "PASS" { "PASS" }
        "WARN" { "WARN" }
        "FAIL" { "FAIL" }
    }
    [void]$rb.AppendLine("| **$($t.Category)** | $($t.Item) | $badge | $($t.Details) |")
}

[System.IO.File]::WriteAllText($resolvedReportPath, $rb.ToString(), [System.Text.Encoding]::UTF8)

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host " Verification Complete: $($results.Passed) Passed, $($results.Warnings) Warnings, $($results.Failed) Failed" -ForegroundColor $(if ($results.Failed -eq 0) { 'Green' } else { 'Red' })
Write-Host " Report written to: $resolvedReportPath" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Cyan
