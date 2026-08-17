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

# Apply the same path remapping used during provisioning, so remapped targets
# are audited at their actual location instead of the source path.
$parameters = $null
if (-not [string]::IsNullOrWhiteSpace($ParametersFile) -and (Test-Path -LiteralPath $ParametersFile)) {
    $parameters = Get-Content -LiteralPath $ParametersFile -Raw | ConvertFrom-Json
}

function Resolve-TargetPath([string]$sourcePath) {
    if ($parameters -and $parameters.PathMappings) {
        foreach ($prop in $parameters.PathMappings.PSObject.Properties) {
            if ($prop.Name -eq $sourcePath -and -not [string]::IsNullOrWhiteSpace($prop.Value)) {
                return $prop.Value
            }
        }
    }
    return $sourcePath
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

# Create ServerManager once, independent of which manifests exist, so the site
# audit still runs when the app pool manifest is empty or missing.
$sm = $null
try {
    [System.Reflection.Assembly]::LoadFrom("$env:SystemRoot\System32\inetsrv\Microsoft.Web.Administration.dll") | Out-Null
    $sm = New-Object Microsoft.Web.Administration.ServerManager
}
catch {
    # Only a failure if the source actually had IIS configuration to audit;
    # the sections below record it against whichever manifests are non-empty.
}

$apppools = Load-Manifest "iis-apppools.json"
if ($apppools -and -not $sm) {
    Record-TestResult "IIS AppPool" "ServerManager" "FAIL" "Source has IIS app pools but Microsoft.Web.Administration is unavailable on target (is IIS installed?)."
}
if ($apppools -and $sm) {
    try {
        foreach ($p in $apppools) {
            $targetPool = $sm.ApplicationPools[$p.Name]
            if ($targetPool) {
                $state = $targetPool.State.ToString()
                $clr = $targetPool.ManagedRuntimeVersion

                # Compare the config that most often breaks apps when it drifts
                $drift = @()
                if ($p.ManagedRuntimeVersion -and $clr -ne $p.ManagedRuntimeVersion) {
                    $drift += "CLR '$clr' vs source '$($p.ManagedRuntimeVersion)'"
                }
                if ($p.ManagedPipelineMode -and $targetPool.ManagedPipelineMode.ToString() -ne $p.ManagedPipelineMode) {
                    $drift += "pipeline '$($targetPool.ManagedPipelineMode)' vs source '$($p.ManagedPipelineMode)'"
                }
                if ($p.ProcessModel -and $p.ProcessModel.IdentityType -and $targetPool.ProcessModel.IdentityType.ToString() -ne $p.ProcessModel.IdentityType) {
                    $drift += "identity '$($targetPool.ProcessModel.IdentityType)' vs source '$($p.ProcessModel.IdentityType)'"
                }
                if ($null -ne $p.Enable32BitAppOnWin64 -and $targetPool.Enable32BitAppOnWin64 -ne $p.Enable32BitAppOnWin64) {
                    $drift += "32-bit '$($targetPool.Enable32BitAppOnWin64)' vs source '$($p.Enable32BitAppOnWin64)'"
                }

                if ($drift.Count -gt 0) {
                    Record-TestResult "IIS AppPool" $p.Name "WARN" "Pool exists (State: $state) but config drifted: $($drift -join '; ')."
                }
                elseif ($state -eq "Started" -or $state -eq "Starting") {
                    Record-TestResult "IIS AppPool" $p.Name "PASS" "Pool running and matches source config (CLR: $clr, Mode: $($targetPool.ManagedPipelineMode))."
                } else {
                    Record-TestResult "IIS AppPool" $p.Name "WARN" "Pool matches source config but state is $state."
                }
            } else {
                Record-TestResult "IIS AppPool" $p.Name "FAIL" "Application pool is missing from target IIS."
            }
        }
    }
    catch {
        Record-TestResult "IIS AppPool" "Enumeration" "FAIL" "Could not audit application pools: $_"
    }
}

# -------------------------------------------------------------
# 3. Audit IIS Websites & Bindings
# -------------------------------------------------------------
Write-Host "`n[3/7] Auditing IIS Websites & Bindings..." -ForegroundColor Cyan
$sites = Load-Manifest "iis-sites.json"
if ($sites -and -not $sm) {
    Record-TestResult "IIS Site" "ServerManager" "FAIL" "Source has IIS sites but Microsoft.Web.Administration is unavailable on target (is IIS installed?)."
}
if ($sites -and $sm) {
    foreach ($s in $sites) {
        $targetSite = $sm.Sites[$s.Name]
        if ($targetSite) {
            $state = $targetSite.State.ToString()
            Record-TestResult "IIS Site" $s.Name "PASS" "Site exists (State: $state, Bindings: $($targetSite.Bindings.Count))."

            # Binding parity: every source binding should exist on the target
            $targetBindingSet = @($targetSite.Bindings | ForEach-Object { "$($_.Protocol)|$($_.BindingInformation)" })
            foreach ($sb in @($s.Bindings)) {
                $bindingKey = "$($sb.Protocol)|$($sb.BindingInformation)"
                if ($targetBindingSet -notcontains $bindingKey) {
                    Record-TestResult "Site Binding" "$($s.Name) [$bindingKey]" "WARN" "Source binding is not present on the target site."
                }
            }

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
                            Record-TestResult "Site Binding" "$($s.Name) ($($b.Protocol):$port)" "WARN" "Could not test TCP port ${port}: $_"
                        }

                        # HTTP response probe (http only; https via 127.0.0.1 would fail
                        # hostname validation). Any HTTP status counts as a live endpoint.
                        if ($b.Protocol -eq "http") {
                            try {
                                $resp = Invoke-WebRequest -Uri "http://127.0.0.1:$port/" -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
                                Record-TestResult "HTTP Probe" "$($s.Name) (port $port)" "PASS" "Endpoint returned HTTP $($resp.StatusCode)."
                            }
                            catch {
                                if ($_.Exception.Response) {
                                    $code = [int]$_.Exception.Response.StatusCode
                                    Record-TestResult "HTTP Probe" "$($s.Name) (port $port)" "PASS" "Endpoint responded with HTTP $code (server is up; status may reflect host-header or app config)."
                                } else {
                                    Record-TestResult "HTTP Probe" "$($s.Name) (port $port)" "WARN" "No HTTP response on 127.0.0.1:$port."
                                }
                            }
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
            $expectedPath = Resolve-TargetPath $sh.Path
            if ($targetShare.Path -eq $expectedPath) {
                Record-TestResult "SMB Share" $sh.Name "PASS" "Share exists (Path: $($targetShare.Path))."
            } else {
                Record-TestResult "SMB Share" $sh.Name "WARN" "Share exists but path is $($targetShare.Path); expected $expectedPath."
            }
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
            $targetPath = Resolve-TargetPath $entry.Path
            if (Test-Path -LiteralPath $targetPath) {
                Record-TestResult "NTFS Path" $targetPath "PASS" "Directory exists on target disk."

                # Compare the applied security descriptor against the captured SDDL
                if ($entry.Sddl) {
                    try {
                        $currentSddl = (Get-Acl -LiteralPath $targetPath).Sddl
                        if ($currentSddl -eq $entry.Sddl) {
                            Record-TestResult "NTFS ACL" $targetPath "PASS" "SDDL security descriptor matches source exactly."
                        } else {
                            Record-TestResult "NTFS ACL" $targetPath "WARN" "SDDL differs from source; review with Get-Acl (owner or inherited ACEs may legitimately differ)."
                        }
                    }
                    catch {
                        Record-TestResult "NTFS ACL" $targetPath "WARN" "Could not read target ACL: $_"
                    }
                }
            } else {
                Record-TestResult "NTFS Path" $targetPath "WARN" "Directory path does not exist on target disk."
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

        # Expected values honor twin-parameters overrides, then the source capture
        $smtpOverrides = if ($parameters) { $parameters.SmtpOverrides } else { $null }
        $expectedPort = 25
        if ($smtpOverrides -and $smtpOverrides.Port) { $expectedPort = [int]$smtpOverrides.Port }
        elseif ($smtpConfig.Properties -and $smtpConfig.Properties.Port) { $expectedPort = [int]$smtpConfig.Properties.Port }

        $expectedSmartHost = $null
        if ($smtpOverrides -and $smtpOverrides.SmartHost) { $expectedSmartHost = "$($smtpOverrides.SmartHost)" }
        elseif ($smtpConfig.Properties -and $smtpConfig.Properties.SmartHost) { $expectedSmartHost = "$($smtpConfig.Properties.SmartHost)" }

        if ($expectedSmartHost) {
            $actualSmartHost = "$($adsi.Properties['SmartHost'].Value)"
            if ($actualSmartHost -eq $expectedSmartHost) {
                Record-TestResult "SMTP Server" "SmartHost" "PASS" "SmartHost matches expected value ('$actualSmartHost')."
            } else {
                Record-TestResult "SMTP Server" "SmartHost" "WARN" "SmartHost is '$actualSmartHost'; expected '$expectedSmartHost'."
            }
        }

        # Check the expected SMTP port listener
        $portTest = Test-NetConnection -ComputerName "127.0.0.1" -Port $expectedPort -WarningAction SilentlyContinue
        if ($portTest.TcpTestSucceeded) {
            Record-TestResult "SMTP Server" "Port $expectedPort Listener" "PASS" "Port $expectedPort is actively listening on target."
        } else {
            Record-TestResult "SMTP Server" "Port $expectedPort Listener" "WARN" "Port $expectedPort TCP connection test failed."
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
        # Compare against what the SOURCE actually had, not a hardcoded expectation
        $expectedStart = if ($smtpService.StartType) { "$($smtpService.StartType)" } else { "Automatic" }
        $expectRunning = $expectedStart -ne "Disabled"
        if ("$($svc.StartType)" -eq $expectedStart -and ((-not $expectRunning) -or $svc.Status -eq "Running")) {
            Record-TestResult "SMTPSVC Service" "Service Status" "PASS" "StartType matches source ($expectedStart); status is $($svc.Status)."
        } else {
            Record-TestResult "SMTPSVC Service" "Service Status" "WARN" "Status $($svc.Status), StartType $($svc.StartType); source was $expectedStart."
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
