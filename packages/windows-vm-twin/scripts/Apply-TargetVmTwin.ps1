<#
.SYNOPSIS
    Provisions and configures a blank Windows VM as an exact Configuration Twin.
.DESCRIPTION
    Replays Windows Server features, service accounts, file content, NTFS ACLs,
    SMB network shares, IIS Application Pools, IIS Websites/Bindings, IIS 6.0 SMTP,
    SMTPSVC auto-restart/recovery actions, and Firewall rules.
.PARAMETER BlueprintDir
    Directory containing generated blueprint and manifests.
.PARAMETER ContentDir
    Directory containing packaged content ZIP files.
.PARAMETER ParametersFile
    Path to twin-parameters.json with custom overrides.
.PARAMETER Step
    Which stage to execute: All, Features, Accounts, Content, Acls, Shares, Iis, Smtp, Service, Firewall.
.EXAMPLE
    .\Apply-TargetVmTwin.ps1 -BlueprintDir "C:\VM-Twin-Blueprint" -ContentDir "C:\VM-Twin-Export\Content"
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [string]$BlueprintDir = ".\VM-Twin-Blueprint",

    [Parameter(Mandatory = $false)]
    [string]$ContentDir = ".\VM-Twin-Export\Content",

    [Parameter(Mandatory = $false)]
    [string]$ParametersFile = "",

    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "Features", "Accounts", "Content", "Acls", "Shares", "Iis", "Smtp", "Service", "Firewall")]
    [string]$Step = "All"
)

$ErrorActionPreference = "Continue"

$resolvedBlueprintDir = [System.IO.Path]::GetFullPath($BlueprintDir)
$manifestsDir = Join-Path -Path $resolvedBlueprintDir -ChildPath "Manifests"
if (-not (Test-Path -LiteralPath $manifestsDir)) {
    $manifestsDir = $resolvedBlueprintDir
}

if ([string]::IsNullOrWhiteSpace($ParametersFile)) {
    $ParametersFile = Join-Path -Path $resolvedBlueprintDir -ChildPath "twin-parameters.json"
}

$parameters = $null
if (Test-Path -LiteralPath $ParametersFile) {
    $parameters = Get-Content -LiteralPath $ParametersFile -Raw | ConvertFrom-Json
}

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host " Windows VM Configuration Twin - Provisioning Engine" -ForegroundColor Cyan
Write-Host " Blueprint:   $resolvedBlueprintDir" -ForegroundColor Yellow
Write-Host " Step Target: $Step" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Cyan

function Load-Manifest([string]$fileName) {
    $p = Join-Path -Path $manifestsDir -ChildPath $fileName
    if (Test-Path -LiteralPath $p) {
        return (Get-Content -LiteralPath $p -Raw | ConvertFrom-Json)
    }
    return $null
}

# Helper to remap paths based on twin-parameters.json
function Resolve-TargetPath([string]$sourcePath) {
    if ($parameters -and $parameters.PathMappings) {
        $pProps = $parameters.PathMappings.PSObject.Properties
        foreach ($prop in $pProps) {
            if ($prop.Name -eq $sourcePath -and -not [string]::IsNullOrWhiteSpace($prop.Value)) {
                return $prop.Value
            }
        }
    }
    return $sourcePath
}

# -------------------------------------------------------------
# STEP: Features
# -------------------------------------------------------------
if ($Step -in @("All", "Features")) {
    Write-Host "`n[Stage: Features] Installing Windows Features and Server Roles..." -ForegroundColor Cyan
    $features = Load-Manifest "windows-features.json"
    if ($features) {
        $featureNames = @()
        foreach ($f in $features) {
            if ($f.Name) { $featureNames += $f.Name }
            elseif ($f.FeatureName) { $featureNames += $f.FeatureName }
        }

        # Filter out features that might not be directly installable root tokens
        if (Get-Command -Name Install-WindowsFeature -ErrorAction SilentlyContinue) {
            foreach ($fn in $featureNames) {
                Write-Host "  Checking/Installing: $fn" -ForegroundColor Gray
                try {
                    $res = Install-WindowsFeature -Name $fn -IncludeManagementTools -ErrorAction SilentlyContinue
                    if ($res.Success) {
                        Write-Host "  [+] Feature installed: $fn (RestartNeeded: $($res.RestartNeeded))" -ForegroundColor Green
                    }
                }
                catch {
                    Write-Warning "Could not install feature $fn: $_"
                }
            }
        }
        elseif (Get-Command -Name Enable-WindowsOptionalFeature -ErrorAction SilentlyContinue) {
            foreach ($fn in $featureNames) {
                try {
                    Enable-WindowsOptionalFeature -Online -FeatureName $fn -All -NoRestart -ErrorAction SilentlyContinue | Out-Null
                    Write-Host "  [+] Optional Feature enabled: $fn" -ForegroundColor Green
                }
                catch {}
            }
        }
    }
}

# -------------------------------------------------------------
# STEP: Accounts
# -------------------------------------------------------------
if ($Step -in @("All", "Accounts")) {
    Write-Host "`n[Stage: Accounts] Configuring Local Service Accounts..." -ForegroundColor Cyan
    if ($parameters -and $parameters.AccountMappings) {
        foreach ($accProp in $parameters.AccountMappings.PSObject.Properties) {
            $srcUser = $accProp.Name
            $targetInfo = $accProp.Value
            $targetUser = $targetInfo.TargetUserName
            $targetPwd = $targetInfo.TargetPassword

            if ($targetUser -notmatch '\\' -and (Get-Command -Name New-LocalUser -ErrorAction SilentlyContinue)) {
                $existing = Get-LocalUser -Name $targetUser -ErrorAction SilentlyContinue
                if (-not $existing -and $targetPwd -and $targetPwd -ne "REPLACE_WITH_TARGET_PASSWORD_OR_LEAVE_EMPTY") {
                    $secPwd = ConvertTo-SecureString $targetPwd -AsPlainText -Force
                    New-LocalUser -Name $targetUser -Password $secPwd -Description "Twin Service Account for $srcUser" -PasswordNeverExpires -ErrorAction SilentlyContinue | Out-Null
                    Write-Host "  [+] Created local user: $targetUser" -ForegroundColor Green
                }
            }
        }
    }
}

# -------------------------------------------------------------
# STEP: Content
# -------------------------------------------------------------
if ($Step -in @("All", "Content")) {
    Write-Host "`n[Stage: Content] Restoring Website & Share Content Archives..." -ForegroundColor Cyan
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $resolvedContentDir = [System.IO.Path]::GetFullPath($ContentDir)
    $contentManifestPath = Join-Path -Path $resolvedContentDir -ChildPath "content-manifest.json"

    if (Test-Path -LiteralPath $contentManifestPath) {
        $cManifest = Get-Content -LiteralPath $contentManifestPath -Raw | ConvertFrom-Json
        foreach ($arch in $cManifest.Archives) {
            $archiveFile = Join-Path -Path $resolvedContentDir -ChildPath $arch.ArchiveFile
            $targetDest = Resolve-TargetPath $arch.OriginalPath

            if (Test-Path -LiteralPath $archiveFile) {
                Write-Host "  Extracting $($arch.ArchiveFile) to $targetDest..." -ForegroundColor Gray
                if (-not (Test-Path -LiteralPath $targetDest)) {
                    $null = New-Item -ItemType Directory -Path $targetDest -Force
                }
                [System.IO.Compression.ZipFile]::ExtractToDirectory($archiveFile, $targetDest)
                Write-Host "  [+] Restored content: $targetDest" -ForegroundColor Green
            }
        }
    }
}

# -------------------------------------------------------------
# STEP: Acls
# -------------------------------------------------------------
if ($Step -in @("All", "Acls")) {
    Write-Host "`n[Stage: Acls] Replaying NTFS Access Control Lists (SDDL)..." -ForegroundColor Cyan
    $acls = Load-Manifest "ntfs-acls.json"
    if ($acls) {
        foreach ($entry in $acls) {
            $targetPath = Resolve-TargetPath $entry.Path
            if (Test-Path -LiteralPath $targetPath) {
                Write-Host "  Applying ACL to $targetPath..." -ForegroundColor Gray
                try {
                    if ($entry.Sddl) {
                        $targetAcl = Get-Acl -LiteralPath $targetPath
                        $targetAcl.SetSecurityDescriptorSddlForm($entry.Sddl)
                        Set-Acl -LiteralPath $targetPath -AclObject $targetAcl
                        Write-Host "  [+] Set SDDL ACL on $targetPath" -ForegroundColor Green
                    }
                }
                catch {
                    Write-Warning "Could not apply SDDL to $targetPath: $_"
                }
            }
        }
    }
}

# -------------------------------------------------------------
# STEP: Shares
# -------------------------------------------------------------
if ($Step -in @("All", "Shares")) {
    Write-Host "`n[Stage: Shares] Provisioning SMB Network Shares..." -ForegroundColor Cyan
    $shares = Load-Manifest "smb-shares.json"
    if ($shares -and (Get-Command -Name New-SmbShare -ErrorAction SilentlyContinue)) {
        foreach ($sh in $shares) {
            $targetPath = Resolve-TargetPath $sh.Path
            if (-not (Test-Path -LiteralPath $targetPath)) {
                $null = New-Item -ItemType Directory -Path $targetPath -Force
            }

            $existingShare = Get-SmbShare -Name $sh.Name -ErrorAction SilentlyContinue
            if (-not $existingShare) {
                Write-Host "  Creating SMB Share: $($sh.Name) ($targetPath)..." -ForegroundColor Gray
                $caching = if ($sh.CachingMode) { $sh.CachingMode } else { "Manual" }
                New-SmbShare -Name $sh.Name -Path $targetPath -Description $sh.Description -CachingMode $caching -FullAccess "Administrators" -ErrorAction SilentlyContinue | Out-Null
                Write-Host "  [+] Created Share: $($sh.Name)" -ForegroundColor Green

                # Grant permissions
                foreach ($acc in $sh.AccessPermissions) {
                    try {
                        if ($acc.AccessRight -eq "Full") {
                            Grant-SmbShareAccess -Name $sh.Name -AccountName $acc.AccountName -AccessRight Full -Force -ErrorAction SilentlyContinue | Out-Null
                        }
                        elseif ($acc.AccessRight -eq "Change") {
                            Grant-SmbShareAccess -Name $sh.Name -AccountName $acc.AccountName -AccessRight Change -Force -ErrorAction SilentlyContinue | Out-Null
                        }
                        elseif ($acc.AccessRight -eq "Read") {
                            Grant-SmbShareAccess -Name $sh.Name -AccountName $acc.AccountName -AccessRight Read -Force -ErrorAction SilentlyContinue | Out-Null
                        }
                    }
                    catch {
                        Write-Warning "Could not grant $($acc.AccessRight) to $($acc.AccountName) on $($sh.Name): $_"
                    }
                }
            }
            else {
                Write-Host "  [=] Share already exists: $($sh.Name)" -ForegroundColor Gray
            }
        }
    }
}

# -------------------------------------------------------------
# STEP: IIS
# -------------------------------------------------------------
if ($Step -in @("All", "Iis")) {
    Write-Host "`n[Stage: IIS] Rebuilding Application Pools, Sites, and Bindings..." -ForegroundColor Cyan
    try {
        [System.Reflection.Assembly]::LoadFrom("$env:SystemRoot\System32\inetsrv\Microsoft.Web.Administration.dll") | Out-Null
        $sm = New-Object Microsoft.Web.Administration.ServerManager

        $apppools = Load-Manifest "iis-apppools.json"
        if ($apppools) {
            foreach ($p in $apppools) {
                $pool = $sm.ApplicationPools[$p.Name]
                if (-not $pool) {
                    Write-Host "  Creating AppPool: $($p.Name)..." -ForegroundColor Gray
                    $pool = $sm.ApplicationPools.Add($p.Name)
                }

                $pool.AutoStart = $p.AutoStart
                $pool.ManagedRuntimeVersion = $p.ManagedRuntimeVersion
                if ($p.ManagedPipelineMode -eq "Classic") {
                    $pool.ManagedPipelineMode = [Microsoft.Web.Administration.ManagedPipelineMode]::Classic
                } else {
                    $pool.ManagedPipelineMode = [Microsoft.Web.Administration.ManagedPipelineMode]::Integrated
                }
                $pool.Enable32BitAppOnWin64 = $p.Enable32BitAppOnWin64
                if ($p.QueueLength) { $pool.QueueLength = $p.QueueLength }

                # Identity
                if ($p.ProcessModel) {
                    if ($p.ProcessModel.IdentityType -eq "SpecificUser" -and $parameters -and $parameters.AccountMappings) {
                        $mapped = $parameters.AccountMappings.PSObject.Properties[$p.ProcessModel.UserName]
                        if ($mapped -and $mapped.Value.TargetPassword -and $mapped.Value.TargetPassword -ne "REPLACE_WITH_TARGET_PASSWORD_OR_LEAVE_EMPTY") {
                            $pool.ProcessModel.IdentityType = [Microsoft.Web.Administration.ProcessModelIdentityType]::SpecificUser
                            $pool.ProcessModel.UserName = $mapped.Value.TargetUserName
                            $pool.ProcessModel.Password = $mapped.Value.TargetPassword
                        }
                    }
                    elseif ($p.ProcessModel.IdentityType -in @("ApplicationPoolIdentity", "NetworkService", "LocalSystem", "LocalService")) {
                        $pool.ProcessModel.IdentityType = [System.Enum]::Parse([Microsoft.Web.Administration.ProcessModelIdentityType], $p.ProcessModel.IdentityType)
                    }
                }

                # Recycling
                if ($p.Recycling -and $p.Recycling.PeriodicRestartTime) {
                    $pool.Recycling.PeriodicRestart.Time = [System.TimeSpan]::Parse($p.Recycling.PeriodicRestartTime)
                }
                if ($p.Recycling -and $p.Recycling.PrivateMemoryLimit) {
                    $pool.Recycling.PeriodicRestart.PrivateMemory = [long]$p.Recycling.PrivateMemoryLimit
                }

                Write-Host "  [+] Configured AppPool: $($p.Name)" -ForegroundColor Green
            }
            $sm.CommitChanges()
        }

        # Websites
        $sites = Load-Manifest "iis-sites.json"
        if ($sites) {
            foreach ($s in $sites) {
                # Determine primary root path
                $rootPath = "C:\inetpub\wwwroot"
                if ($s.Applications -and $s.Applications[0].VirtualDirectories) {
                    $rootPath = Resolve-TargetPath $s.Applications[0].VirtualDirectories[0].PhysicalPath
                }

                if (-not (Test-Path -LiteralPath $rootPath)) {
                    $null = New-Item -ItemType Directory -Path $rootPath -Force
                }

                $site = $sm.Sites[$s.Name]
                if (-not $site) {
                    Write-Host "  Creating IIS Site: $($s.Name)..." -ForegroundColor Gray
                    # Initial dummy binding
                    $firstBinding = $s.Bindings[0]
                    $site = $sm.Sites.Add($s.Name, $firstBinding.Protocol, $firstBinding.BindingInformation, $rootPath)
                }

                $site.ServerAutoStart = $s.ServerAutoStart

                # Clear and re-apply bindings
                $site.Bindings.Clear()
                foreach ($b in $s.Bindings) {
                    $binding = $site.Bindings.CreateElement()
                    $binding.Protocol = $b.Protocol
                    $binding.BindingInformation = $b.BindingInformation

                    # SSL Certificate lookup
                    if ($b.Protocol -eq "https" -and $b.CertificateThumbprint) {
                        $targetThumbprint = $b.CertificateThumbprint
                        if ($parameters -and $parameters.BindingOverrides) {
                            $override = $parameters.BindingOverrides.PSObject.Properties[$b.BindingInformation]
                            if ($override -and $override.Value.TargetThumbprint) {
                                $targetThumbprint = $override.Value.TargetThumbprint
                            }
                        }

                        $cert = Get-Item "Cert:\LocalMachine\My\$targetThumbprint" -ErrorAction SilentlyContinue
                        if (-not $cert) {
                            $cert = Get-Item "Cert:\LocalMachine\WebHosting\$targetThumbprint" -ErrorAction SilentlyContinue
                        }
                        if ($cert) {
                            $binding.CertificateHash = $cert.GetCertHash()
                            $binding.CertificateStoreName = if ($b.CertificateStoreName) { $b.CertificateStoreName } else { "My" }
                        } else {
                            Write-Warning "SSL Certificate $targetThumbprint not found in Certificate Store for binding $($b.BindingInformation)"
                        }
                    }
                    $site.Bindings.Add($binding)
                }

                # Configure Applications & Virtual Directories
                foreach ($app in $s.Applications) {
                    $siteApp = $site.Applications[$app.Path]
                    if (-not $siteApp) {
                        $siteApp = $site.Applications.Add($app.Path, (Resolve-TargetPath $app.VirtualDirectories[0].PhysicalPath))
                    }
                    if ($app.ApplicationPoolName) {
                        $siteApp.ApplicationPoolName = $app.ApplicationPoolName
                    }

                    foreach ($vd in $app.VirtualDirectories) {
                        $vPath = Resolve-TargetPath $vd.PhysicalPath
                        if (-not (Test-Path -LiteralPath $vPath)) {
                            $null = New-Item -ItemType Directory -Path $vPath -Force
                        }
                        $siteVDir = $siteApp.VirtualDirectories[$vd.Path]
                        if (-not $siteVDir) {
                            $siteVDir = $siteApp.VirtualDirectories.Add($vd.Path, $vPath)
                        } else {
                            $siteVDir.PhysicalPath = $vPath
                        }
                    }
                }

                Write-Host "  [+] Configured Site: $($s.Name)" -ForegroundColor Green
            }
            $sm.CommitChanges()
        }
    }
    catch {
        Write-Error "IIS Configuration Replay failed: $_"
    }
}

# -------------------------------------------------------------
# STEP: SMTP (IIS 6.0)
# -------------------------------------------------------------
if ($Step -in @("All", "Smtp")) {
    Write-Host "`n[Stage: SMTP] Configuring IIS 6.0 SMTP Server..." -ForegroundColor Cyan
    $smtpConfig = Load-Manifest "smtp-config.json"
    $smtpAdsiPath = "IIS://localhost/SmtpSvc/1"

    if ($smtpConfig -and $smtpConfig.Installed) {
        try {
            if ([System.DirectoryServices.DirectoryEntry]::Exists($smtpAdsiPath)) {
                $adsi = [ADSI]$smtpAdsiPath

                # Ensure Drop/Pickup/BadMail directories
                $dropDir = if ($parameters.SmtpOverrides.DropDir) { $parameters.SmtpOverrides.DropDir } else { $smtpConfig.Properties.DropDir }
                if ($dropDir -and -not (Test-Path -LiteralPath $dropDir)) {
                    $null = New-Item -ItemType Directory -Path $dropDir -Force
                }

                if ($dropDir) { $adsi.Properties["DropDir"].Value = $dropDir }
                if ($smtpConfig.Properties.PickupDir) { $adsi.Properties["PickupDir"].Value = $smtpConfig.Properties.PickupDir }
                if ($smtpConfig.Properties.BadMailDir) { $adsi.Properties["BadMailDir"].Value = $smtpConfig.Properties.BadMailDir }
                if ($parameters.SmtpOverrides.SmartHost) {
                    $adsi.Properties["SmartHost"].Value = $parameters.SmtpOverrides.SmartHost
                } elseif ($smtpConfig.Properties.SmartHost) {
                    $adsi.Properties["SmartHost"].Value = $smtpConfig.Properties.SmartHost
                }

                if ($smtpConfig.Properties.Port) { $adsi.Properties["Port"].Value = [int]$smtpConfig.Properties.Port }
                if ($smtpConfig.Properties.MaxMessageSize) { $adsi.Properties["MaxMessageSize"].Value = [int]$smtpConfig.Properties.MaxMessageSize }

                # Restore binary Relay IP list if captured
                if ($smtpConfig.RelayRestrictions -and $smtpConfig.RelayRestrictions.Base64 -and $parameters.SmtpOverrides.ApplyRelayList) {
                    $relayBytes = [System.Convert]::FromBase64String($smtpConfig.RelayRestrictions.Base64)
                    $adsi.Properties["RelayIpList"].Value = $relayBytes
                    Write-Host "  [+] Restored SMTP Relay IP Restrictions list" -ForegroundColor Green
                }

                $adsi.Properties["ServerAutoStart"].Value = 1
                $adsi.SetInfo()
                Write-Host "  [+] Configured IIS 6.0 SMTP Server successfully" -ForegroundColor Green
            }
            else {
                Write-Warning "IIS 6.0 SMTP container $smtpAdsiPath does not exist. Ensure SMTP Server feature is installed."
            }
        }
        catch {
            Write-Warning "Could not configure IIS 6.0 SMTP: $_"
        }
    }
}

# -------------------------------------------------------------
# STEP: SMTPSVC Service Recovery & Auto-Restart
# -------------------------------------------------------------
if ($Step -in @("All", "Service")) {
    Write-Host "`n[Stage: Service] Configuring SMTPSVC Service Startup & Auto-Restart Actions..." -ForegroundColor Cyan
    $smtpService = Load-Manifest "smtp-service.json"
    if ($smtpService -and $smtpService.ServiceFound) {
        # Set Startup Type
        Set-Service -Name SMTPSVC -StartupType Automatic -ErrorAction SilentlyContinue

        # Configure Failure Actions via sc.exe failure
        $resetSeconds = 86400
        $restartDelayMs = 60000

        if ($parameters -and $parameters.ServiceRecoveryOverrides) {
            if ($parameters.ServiceRecoveryOverrides.ResetPeriodSeconds) {
                $resetSeconds = $parameters.ServiceRecoveryOverrides.ResetPeriodSeconds
            }
            if ($parameters.ServiceRecoveryOverrides.RestartDelayMilliseconds) {
                $restartDelayMs = $parameters.ServiceRecoveryOverrides.RestartDelayMilliseconds
            }
        }
        elseif ($smtpService.RecoverySettings -and $smtpService.RecoverySettings.ResetPeriodSeconds) {
            $resetSeconds = $smtpService.RecoverySettings.ResetPeriodSeconds
        }

        # Build sc.exe command: restart/delay/restart/delay/restart/delay
        $actionString = "restart/$restartDelayMs/restart/$restartDelayMs/restart/$restartDelayMs"
        $scArgs = "failure SMTPSVC reset= $resetSeconds actions= $actionString"

        Write-Host "  Executing: sc.exe $scArgs" -ForegroundColor Gray
        $null = & "$env:SystemRoot\System32\sc.exe" failure SMTPSVC reset= $resetSeconds actions= $actionString
        
        # Start service
        Start-Service -Name SMTPSVC -ErrorAction SilentlyContinue
        Write-Host "  [+] Configured SMTPSVC failure recovery (Auto-Restart) and started service" -ForegroundColor Green
    }
}

# -------------------------------------------------------------
# STEP: Firewall
# -------------------------------------------------------------
if ($Step -in @("All", "Firewall")) {
    Write-Host "`n[Stage: Firewall] Configuring Inbound Windows Firewall Rules..." -ForegroundColor Cyan
    if (Get-Command -Name New-NetFirewallRule -ErrorAction SilentlyContinue) {
        $portsToOpen = @(
            @{ Name = "Twin-HTTP-In";   Port = 80;  DisplayName = "Twin HTTP (Port 80 Inbound)" },
            @{ Name = "Twin-HTTPS-In";  Port = 443; DisplayName = "Twin HTTPS (Port 443 Inbound)" },
            @{ Name = "Twin-SMTP-In";   Port = 25;  DisplayName = "Twin SMTP (Port 25 Inbound)" },
            @{ Name = "Twin-SMB-In";    Port = 445; DisplayName = "Twin SMB (Port 445 Inbound)" }
        )

        foreach ($p in $portsToOpen) {
            $existing = Get-NetFirewallRule -Name $p.Name -ErrorAction SilentlyContinue
            if (-not $existing) {
                New-NetFirewallRule -Name $p.Name -DisplayName $p.DisplayName -Direction Inbound -Protocol TCP -LocalPort $p.Port -Action Allow -ErrorAction SilentlyContinue | Out-Null
                Write-Host "  [+] Created Firewall Rule: $($p.DisplayName)" -ForegroundColor Green
            }
        }
    }
}

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host " Target VM Provisioning Complete!" -ForegroundColor Green
Write-Host " Run Test-TargetVmTwin.ps1 to verify parity." -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Cyan
