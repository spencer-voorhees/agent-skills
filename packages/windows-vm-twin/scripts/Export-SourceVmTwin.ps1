<#
.SYNOPSIS
    Performs 100% read-only discovery of Windows VM configuration for cloning.
.DESCRIPTION
    Extracts IIS configurations, Application Pools, Websites, Virtual Directories,
    SMB Network Shares, NTFS ACLs (SDDL), IIS 6.0 SMTP Server settings,
    SMTPSVC Service failure/recovery actions, Windows Features, and Certificates.
    Guaranteed zero-mutation on the source machine.
.PARAMETER OutputDir
    Destination folder to store JSON manifests and markdown inventory report.
.PARAMETER IncludeCertificates
    Whether to capture SSL certificate metadata from LocalMachine store.
.PARAMETER IncludeFirewall
    Whether to capture relevant IIS/SMTP/SMB firewall rules.
.PARAMETER IncludeRawApplicationHostConfig
    Whether to save a read-only copy of %SystemRoot%\System32\inetsrv\config\applicationHost.config.
.EXAMPLE
    .\Export-SourceVmTwin.ps1 -OutputDir "C:\VM-Twin-Export" -IncludeCertificates -IncludeFirewall
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputDir = ".\VM-Twin-Export",

    [Parameter(Mandatory = $false)]
    [switch]$IncludeCertificates = $true,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeFirewall = $true,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeRawApplicationHostConfig = $true
)

$ErrorActionPreference = "Continue"
Set-StrictMode -Off

# Ensure Output Directory exists
$resolvedOutputDir = [System.IO.Path]::GetFullPath($OutputDir)
if (-not (Test-Path -LiteralPath $resolvedOutputDir)) {
    $null = New-Item -ItemType Directory -Path $resolvedOutputDir -Force
}

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host " Windows VM Configuration Twin - Read-Only Discovery Engine" -ForegroundColor Cyan
Write-Host " Target Output: $resolvedOutputDir" -ForegroundColor Yellow
Write-Host " Timestamp:     $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Cyan

$manifestSummary = [ordered]@{
    CaptureDateUtc  = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    ComputerName    = $env:COMPUTERNAME
    ExportDirectory = $resolvedOutputDir
    Components      = [ordered]@{}
}

# Helper to safely export JSON with formatting
function Write-ManifestJson {
    param(
        [string]$FileName,
        [object]$Data,
        [string]$Description
    )
    $filePath = Join-Path -Path $resolvedOutputDir -ChildPath $FileName
    try {
        # -InputObject preserves empty and single-element arrays as JSON arrays
        # (piping unrolls them: @() | ConvertTo-Json emits nothing at all).
        $json = ConvertTo-Json -InputObject $Data -Depth 15
        [System.IO.File]::WriteAllText($filePath, $json, [System.Text.Encoding]::UTF8)
        $sha256 = (Get-FileHash -Path $filePath -Algorithm SHA256).Hash
        $manifestSummary.Components[$FileName] = [ordered]@{
            Status      = "Success"
            Description = $Description
            Sha256      = $sha256
            Bytes       = (Get-Item -LiteralPath $filePath).Length
        }
        Write-Host "  [+] Exported: $FileName ($Description)" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to export ${FileName}: $_"
        $manifestSummary.Components[$FileName] = [ordered]@{
            Status = "Failed"
            Error  = $_.ToString()
        }
    }
}

# -------------------------------------------------------------
# 1. System Metadata & OS Info
# -------------------------------------------------------------
Write-Host "`n[1/11] Gathering System & OS Metadata..." -ForegroundColor Cyan
$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
$csInfo = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
$adapters = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" }

$systemMetadata = [ordered]@{
    ComputerName       = $env:COMPUTERNAME
    Domain             = if ($csInfo.PartOfDomain) { $csInfo.Domain } else { "WORKGROUP ($($csInfo.Workgroup))" }
    OperatingSystem    = $osInfo.Caption
    Version            = $osInfo.Version
    BuildNumber        = $osInfo.BuildNumber
    OSArchitecture     = $osInfo.OSArchitecture
    TotalPhysicalMemoryGB = [math]::Round($osInfo.TotalVisibleMemorySize / 1MB, 2)
    TimeZone           = (Get-TimeZone -ErrorAction SilentlyContinue).Id
    PowerShellVersion  = $PSVersionTable.PSVersion.ToString()
    IPv4Addresses      = @($adapters | ForEach-Object {
        [ordered]@{
            InterfaceAlias = $_.InterfaceAlias
            IPAddress      = $_.IPAddress
            PrefixLength   = $_.PrefixLength
        }
    })
    EnvironmentVariables = [ordered]@{}
}

foreach ($de in [System.Environment]::GetEnvironmentVariables("Machine").GetEnumerator()) {
    $systemMetadata.EnvironmentVariables[$de.Key] = $de.Value
}
Write-ManifestJson -FileName "system-metadata.json" -Data $systemMetadata -Description "Host system, OS build, network interfaces, and machine environment"

# -------------------------------------------------------------
# 2. Windows Features & Server Roles
# -------------------------------------------------------------
Write-Host "`n[2/11] Discovering Installed Windows Features & Roles..." -ForegroundColor Cyan
$installedFeatures = @()

if (Get-Command -Name Get-WindowsFeature -ErrorAction SilentlyContinue) {
    # Server SKU
    $features = Get-WindowsFeature | Where-Object { $_.Installed -eq $true }
    $installedFeatures = @($features | Select-Object Name, DisplayName, FeatureType, Path)
}
elseif (Get-Command -Name Get-WindowsOptionalFeature -ErrorAction SilentlyContinue) {
    # Client / DISM fallback
    $optFeatures = Get-WindowsOptionalFeature -Online | Where-Object { $_.State -eq "Enabled" }
    $installedFeatures = @($optFeatures | Select-Object FeatureName, State)
}
Write-ManifestJson -FileName "windows-features.json" -Data $installedFeatures -Description "Installed Windows Server features, roles, and sub-components"

# -------------------------------------------------------------
# 3. IIS Application Pools
# -------------------------------------------------------------
Write-Host "`n[3/11] Discovering IIS Application Pools..." -ForegroundColor Cyan
$appPoolList = @()
$iisInstalled = (Test-Path "$env:SystemRoot\System32\inetsrv\appcmd.exe")

if ($iisInstalled) {
    try {
        if (-not (Get-Module -Name WebAdministration -ListAvailable)) {
            Import-Module WebAdministration -ErrorAction SilentlyContinue
        }

        # Try Microsoft.Web.Administration reflection
        [System.Reflection.Assembly]::LoadFrom("$env:SystemRoot\System32\inetsrv\Microsoft.Web.Administration.dll") | Out-Null
        $serverManager = New-Object Microsoft.Web.Administration.ServerManager

        foreach ($pool in $serverManager.ApplicationPools) {
            $poolObj = [ordered]@{
                Name                     = $pool.Name
                State                    = $pool.State.ToString()
                AutoStart                = $pool.AutoStart
                ManagedRuntimeVersion    = $pool.ManagedRuntimeVersion
                ManagedPipelineMode      = $pool.ManagedPipelineMode.ToString()
                Enable32BitAppOnWin64    = $pool.Enable32BitAppOnWin64
                QueueLength              = $pool.QueueLength
                StartMode                = $pool.StartMode.ToString()
                ProcessModel             = [ordered]@{
                    IdentityType         = $pool.ProcessModel.IdentityType.ToString()
                    UserName             = $pool.ProcessModel.UserName
                    IdleTimeout          = $pool.ProcessModel.IdleTimeout.ToString()
                    MaxProcesses         = $pool.ProcessModel.MaxProcesses
                    PagingEnabled        = $pool.ProcessModel.PagingEnabled
                    ShutdownTimeLimit    = $pool.ProcessModel.ShutdownTimeLimit.ToString()
                    StartupTimeLimit     = $pool.ProcessModel.StartupTimeLimit.ToString()
                    LoadUserProfile      = $pool.ProcessModel.LoadUserProfile
                }
                Recycling                = [ordered]@{
                    PeriodicRestartTime  = $pool.Recycling.PeriodicRestart.Time.ToString()
                    PeriodicRestartRequests = $pool.Recycling.PeriodicRestart.Requests
                    MemoryLimit          = $pool.Recycling.PeriodicRestart.Memory
                    PrivateMemoryLimit   = $pool.Recycling.PeriodicRestart.PrivateMemory
                    Schedule             = @($pool.Recycling.PeriodicRestart.Schedule | ForEach-Object { $_.Time.ToString() })
                    LogEventOnRecycle    = $pool.Recycling.LogEventOnRecycle.ToString()
                }
                Failure                  = [ordered]@{
                    RapidFailProtection  = $pool.Failure.RapidFailProtection
                    RapidFailInterval    = $pool.Failure.RapidFailProtectionInterval.ToString()
                    RapidFailMaxCrashes  = $pool.Failure.RapidFailProtectionMaxCrashes
                    AutoShutdownStatus   = $pool.Failure.AutoShutdownStatus
                }
                Cpu                      = [ordered]@{
                    Limit                = $pool.Cpu.Limit
                    Action               = $pool.Cpu.Action.ToString()
                    ResetInterval        = $pool.Cpu.ResetInterval.ToString()
                    SmpAffinitized       = $pool.Cpu.SmpAffinitized
                }
            }
            $appPoolList += $poolObj
        }
    }
    catch {
        Write-Warning "Could not use Microsoft.Web.Administration: $_. Attempting appcmd.exe fallback..."
        $rawAppPools = & "$env:SystemRoot\System32\inetsrv\appcmd.exe" list apppool /xml
        $appPoolList = @{ RawXml = $rawAppPools }
    }
}
Write-ManifestJson -FileName "iis-apppools.json" -Data $appPoolList -Description "IIS Application Pools configuration, identities, and recycling policies"

# -------------------------------------------------------------
# 4. IIS Websites, Applications, and Virtual Directories
# -------------------------------------------------------------
Write-Host "`n[4/11] Discovering IIS Websites, Apps & Bindings..." -ForegroundColor Cyan
$siteList = @()
$discoveredPhysicalPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

if ($iisInstalled) {
    try {
        if (-not $serverManager) {
            $serverManager = New-Object Microsoft.Web.Administration.ServerManager
        }

        foreach ($site in $serverManager.Sites) {
            $bindings = @()
            foreach ($b in $site.Bindings) {
                $certThumbprint = $null
                $certStore = $null
                if ($b.CertificateHash) {
                    $certThumbprint = [System.BitConverter]::ToString($b.CertificateHash) -replace '-'
                    $certStore = $b.CertificateStoreName
                }

                $bindings += [ordered]@{
                    Protocol               = $b.Protocol
                    BindingInformation    = $b.BindingInformation
                    Host                   = $b.Host
                    EndPoint               = if ($b.EndPoint) { $b.EndPoint.ToString() } else { $null }
                    SslFlags               = $b.SslFlags.ToString()
                    CertificateThumbprint  = $certThumbprint
                    CertificateStoreName   = $certStore
                }
            }

            $applications = @()
            foreach ($app in $site.Applications) {
                $vdirs = @()
                foreach ($vdir in $app.VirtualDirectories) {
                    if ($vdir.PhysicalPath) {
                        $null = $discoveredPhysicalPaths.Add($vdir.PhysicalPath)
                    }
                    $vdirs += [ordered]@{
                        Path         = $vdir.Path
                        PhysicalPath = $vdir.PhysicalPath
                        LogonMethod  = $vdir.LogonMethod.ToString()
                        UserName     = $vdir.UserName
                    }
                }

                $applications += [ordered]@{
                    Path                = $app.Path
                    ApplicationPoolName = $app.ApplicationPoolName
                    EnabledProtocols    = $app.EnabledProtocols
                    VirtualDirectories  = $vdirs
                }
            }

            $siteObj = [ordered]@{
                Id                  = $site.Id
                Name                = $site.Name
                State               = $site.State.ToString()
                ServerAutoStart     = $site.ServerAutoStart
                Bindings            = $bindings
                Applications        = $applications
                Limits              = [ordered]@{
                    MaxConnections  = $site.Limits.MaxConnections
                    ConnectionTimeout = $site.Limits.ConnectionTimeout.ToString()
                    MaxBandwidth    = $site.Limits.MaxBandwidth
                }
                LogFile             = [ordered]@{
                    Directory       = $site.LogFile.Directory
                    Period          = $site.LogFile.Period.ToString()
                    Format          = $site.LogFile.LogFormat.ToString()
                    Enabled         = $site.LogFile.Enabled
                }
            }
            $siteList += $siteObj
        }
    }
    catch {
        Write-Warning "Could not extract sites via MWA: $_"
    }
}
Write-ManifestJson -FileName "iis-sites.json" -Data $siteList -Description "IIS Websites, Applications, Virtual Directories, and Port/SSL Bindings"

# -------------------------------------------------------------
# 5. IIS Global Config & Raw applicationHost.config
# -------------------------------------------------------------
Write-Host "`n[5/11] Exporting IIS Global Configuration..." -ForegroundColor Cyan
if ($iisInstalled -and $IncludeRawApplicationHostConfig) {
    $appHostConfigPath = "$env:SystemRoot\System32\inetsrv\config\applicationHost.config"
    if (Test-Path -LiteralPath $appHostConfigPath) {
        $destAppHost = Join-Path -Path $resolvedOutputDir -ChildPath "applicationHost.config.bak"
        # Read-only stream copy
        $inStream = [System.IO.File]::OpenRead($appHostConfigPath)
        $outStream = [System.IO.File]::Create($destAppHost)
        $inStream.CopyTo($outStream)
        $inStream.Close()
        $outStream.Close()
        $sha = (Get-FileHash -Path $destAppHost -Algorithm SHA256).Hash
        $manifestSummary.Components["applicationHost.config.bak"] = [ordered]@{
            Status      = "Success"
            Description = "Read-only snapshot of raw applicationHost.config"
            Sha256      = $sha
            Bytes       = (Get-Item -LiteralPath $destAppHost).Length
        }
        Write-Host "  [+] Exported: applicationHost.config.bak (Raw IIS configuration)" -ForegroundColor Green
    }
}

# -------------------------------------------------------------
# 6. SMB Shared Folders & Share Permissions
# -------------------------------------------------------------
Write-Host "`n[6/11] Discovering SMB Network Shares & Share Permissions..." -ForegroundColor Cyan
$sharesList = @()
$systemShareNames = @("ADMIN$", "C$", "D$", "E$", "IPC$", "print$")

if (Get-Command -Name Get-SmbShare -ErrorAction SilentlyContinue) {
    $shares = Get-SmbShare | Where-Object { $systemShareNames -notcontains $_.Name }
    foreach ($sh in $shares) {
        $accessRights = @()
        try {
            $shareAccess = Get-SmbShareAccess -Name $sh.Name -ErrorAction SilentlyContinue
            foreach ($acc in $shareAccess) {
                $accessRights += [ordered]@{
                    AccountName       = $acc.AccountName
                    AccessRight       = $acc.AccessRight.ToString()
                    AccessControlType = $acc.AccessControlType.ToString()
                }
            }
        }
        catch {
            Write-Warning "Could not read share access for $($sh.Name): $_"
        }

        if ($sh.Path) {
            $null = $discoveredPhysicalPaths.Add($sh.Path)
        }

        $sharesList += [ordered]@{
            Name              = $sh.Name
            Path              = $sh.Path
            Description       = $sh.Description
            ContinuouslyAvailable = $sh.ContinuouslyAvailable
            EncryptData       = $sh.EncryptData
            FolderEnumerationMode = $sh.FolderEnumerationMode.ToString()
            CachingMode       = $sh.CachingMode.ToString()
            ShareState        = $sh.ShareState.ToString()
            ShareType         = $sh.ShareType.ToString()
            AccessPermissions = $accessRights
        }
    }
}
Write-ManifestJson -FileName "smb-shares.json" -Data $sharesList -Description "SMB Network Shares configuration and share-level Access Control Entries"

# -------------------------------------------------------------
# 7. NTFS Access Control Lists (ACLs) & SDDL
# -------------------------------------------------------------
Write-Host "`n[7/11] Extracting NTFS Access Control Lists (SDDL) for Discovered Paths..." -ForegroundColor Cyan
$aclEntries = @()

foreach ($path in $discoveredPhysicalPaths) {
    if ([string]::IsNullOrWhiteSpace($path)) { continue }
    if (Test-Path -LiteralPath $path) {
        try {
            $acl = Get-Acl -LiteralPath $path
            $sddl = $acl.Sddl
            $owner = $acl.Owner
            $accessRules = @()

            foreach ($rule in $acl.Access) {
                $accessRules += [ordered]@{
                    IdentityReference = $rule.IdentityReference.Value
                    FileSystemRights  = $rule.FileSystemRights.ToString()
                    AccessControlType = $rule.AccessControlType.ToString()
                    IsInherited       = $rule.IsInherited
                    InheritanceFlags  = $rule.InheritanceFlags.ToString()
                    PropagationFlags  = $rule.PropagationFlags.ToString()
                }
            }

            $aclEntries += [ordered]@{
                Path               = $path
                Owner              = $owner
                AreAccessRulesProtected = $acl.AreAccessRulesProtected
                Sddl               = $sddl
                AccessRules        = $accessRules
            }
        }
        catch {
            Write-Warning "Could not extract ACL for ${path}: $_"
        }
    }
    else {
        Write-Warning "Path referenced in config does not exist on disk: $path"
        $aclEntries += [ordered]@{
            Path   = $path
            Exists = $false
        }
    }
}
Write-ManifestJson -FileName "ntfs-acls.json" -Data $aclEntries -Description "NTFS Access Control Lists and exact SDDL security descriptors for site and share paths"

# -------------------------------------------------------------
# 8. IIS 6.0 SMTP Server Configuration (SmtpSvc/1)
# -------------------------------------------------------------
Write-Host "`n[8/11] Discovering IIS 6.0 SMTP Server Configuration..." -ForegroundColor Cyan
$smtpConfig = [ordered]@{
    Installed = $false
}

$smtpAdsiPath = "IIS://localhost/SmtpSvc/1"
$smtpInstalled = (Test-Path -Path "$env:SystemRoot\System32\inetsrv\smtpmeta.dll") -or 
                 (Test-Path -Path "$env:SystemRoot\System32\inetsrv\smtpadm.dll") -or
                 (Get-Service -Name SMTPSVC -ErrorAction SilentlyContinue)

if ($smtpInstalled) {
    $smtpConfig.Installed = $true
    try {
        if ([System.DirectoryServices.DirectoryEntry]::Exists($smtpAdsiPath)) {
            $adsi = [ADSI]$smtpAdsiPath
            $smtpProperties = [ordered]@{}

            # Direct ADSI Property reads
            $propNames = @(
                "ServerComment", "ServerState", "Port", "SecurePort", "MaxConnections",
                "ConnectionTimeout", "ServerAutoStart", "SmartHost", "SmartHostType",
                "OutboundSecurity", "AuthFlags", "SmtpAuthAction", "DropDir", "PickupDir",
                "BadMailDir", "QueueDir", "MailFromFilter", "FullyQualifiedDomainName",
                "DefaultDomain", "MaxMessageSize", "MaxHopCount", "MaxRecipients",
                "LogType", "LogFileDirectory", "LogFilePeriod", "DoReverseDnsLookup"
            )

            foreach ($p in $propNames) {
                try {
                    $val = $adsi.Properties[$p].Value
                    if ($null -ne $val) {
                        $smtpProperties[$p] = $val
                    }
                }
                catch {}
            }

            # RelayIpList parsing
            $relayInfo = [ordered]@{
                RawBlobPresent = $false
                GrantByDefault = $null
                IpList         = @()
                DomainList     = @()
            }

            try {
                $relayBytes = $adsi.Properties["RelayIpList"].Value
                if ($null -ne $relayBytes) {
                    $relayInfo.RawBlobPresent = $true
                    # ADSI may surface the octet blob as object[]; coerce for Base64
                    $relayInfo.Base64 = [System.Convert]::ToBase64String([byte[]]$relayBytes)
                }
            }
            catch {}

            $smtpConfig.Properties = $smtpProperties
            $smtpConfig.RelayRestrictions = $relayInfo
            Write-Host "  [+] Extracted IIS 6.0 SMTP ADSI Metabase properties successfully." -ForegroundColor Green
        }
        else {
            $smtpConfig.AdsiAvailable = $false
            $smtpConfig.Notes = "SMTPSVC exists but ADSI SmtpSvc/1 container not reachable"
        }
    }
    catch {
        Write-Warning "Could not query IIS 6.0 SMTP ADSI: $_"
        $smtpConfig.Error = $_.ToString()
    }
}
Write-ManifestJson -FileName "smtp-config.json" -Data $smtpConfig -Description "IIS 6.0 SMTP Server settings, smart host, drop directory, ports, and relay IP lists"

# -------------------------------------------------------------
# 9. SMTPSVC Service Startup & Auto-Restart / Recovery Settings
# -------------------------------------------------------------
Write-Host "`n[9/11] Querying SMTPSVC Service Startup & Recovery/Restart Actions..." -ForegroundColor Cyan
$smtpServiceConfig = [ordered]@{
    ServiceFound = $false
}

$smtpSvc = Get-Service -Name SMTPSVC -ErrorAction SilentlyContinue
if ($smtpSvc) {
    $smtpServiceConfig.ServiceFound   = $true
    $smtpServiceConfig.ServiceName    = $smtpSvc.ServiceName
    $smtpServiceConfig.DisplayName    = $smtpSvc.DisplayName
    $smtpServiceConfig.Status         = $smtpSvc.Status.ToString()
    $smtpServiceConfig.StartType      = $smtpSvc.StartType.ToString()

    # Query Failure / Recovery Actions via sc.exe qfailure
    $qfailureRaw = & "$env:SystemRoot\System32\sc.exe" qfailure SMTPSVC
    $parsedActions = @()
    $resetPeriod = $null
    $rebootMsg = $null
    $command = $null

    foreach ($line in $qfailureRaw) {
        $trimmed = $line.Trim()
        if ($trimmed -match "RESET_PERIOD \(in seconds\) *:* *(\d+)") {
            $resetPeriod = [int]$matches[1]
        }
        elseif ($trimmed -match "REBOOT_MESSAGE *:* *(.*)") {
            $rebootMsg = $matches[1]
        }
        elseif ($trimmed -match "COMMAND_LINE *:* *(.*)") {
            $command = $matches[1]
        }
        elseif ($trimmed -match "RESTART *-- *delay = *(\d+) *milliseconds") {
            $parsedActions += [ordered]@{
                Action = "RestartService"
                DelayMilliseconds = [int]$matches[1]
            }
        }
        elseif ($trimmed -match "RUN PROCESS *-- *delay = *(\d+) *milliseconds") {
            $parsedActions += [ordered]@{
                Action = "RunCommand"
                DelayMilliseconds = [int]$matches[1]
            }
        }
        elseif ($trimmed -match "REBOOT *-- *delay = *(\d+) *milliseconds") {
            $parsedActions += [ordered]@{
                Action = "Reboot"
                DelayMilliseconds = [int]$matches[1]
            }
        }
        elseif ($trimmed -match "NONE") {
            $parsedActions += [ordered]@{
                Action = "None"
                DelayMilliseconds = 0
            }
        }
    }

    # Also capture binary registry FailureActions if present
    $failureActionsReg = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SMTPSVC" -Name FailureActions -ErrorAction SilentlyContinue).FailureActions
    $regBase64 = if ($failureActionsReg) { [System.Convert]::ToBase64String($failureActionsReg) } else { $null }

    $smtpServiceConfig.RecoverySettings = [ordered]@{
        ResetPeriodSeconds      = $resetPeriod
        RebootMessage           = $rebootMsg
        CommandLine             = $command
        ActionsSequence         = $parsedActions
        FailureActionsRegBase64 = $regBase64
        RawQFailureOutput       = $qfailureRaw
    }
}
Write-ManifestJson -FileName "smtp-service.json" -Data $smtpServiceConfig -Description "SMTPSVC Windows Service startup configuration and automatic restart on crash/failure settings"

# -------------------------------------------------------------
# 10. SSL Certificates (Metadata Only - Read-Only)
# -------------------------------------------------------------
Write-Host "`n[10/11] Querying SSL Certificates Metadata..." -ForegroundColor Cyan
$certList = @()
if ($IncludeCertificates) {
    $certStores = @("Cert:\LocalMachine\My", "Cert:\LocalMachine\WebHosting")
    foreach ($storePath in $certStores) {
        if (Test-Path -LiteralPath $storePath) {
            $certs = Get-ChildItem -Path $storePath -ErrorAction SilentlyContinue
            foreach ($c in $certs) {
                $certList += [ordered]@{
                    Store          = $storePath
                    Subject        = $c.Subject
                    FriendlyName   = $c.FriendlyName
                    Thumbprint     = $c.Thumbprint
                    Issuer         = $c.Issuer
                    NotBefore      = $c.NotBefore.ToString("yyyy-MM-ddTHH:mm:ssZ")
                    NotAfter       = $c.NotAfter.ToString("yyyy-MM-ddTHH:mm:ssZ")
                    HasPrivateKey  = $c.HasPrivateKey
                    SerialNumber   = $c.SerialNumber
                    DnsNameList    = @($c.DnsNameList | ForEach-Object { $_.Unicode })
                }
            }
        }
    }
}
Write-ManifestJson -FileName "ssl-certificates.json" -Data $certList -Description "SSL certificate metadata and thumbprints required for HTTPS site bindings"

# -------------------------------------------------------------
# 11. Firewall Rules & Local Accounts
# -------------------------------------------------------------
Write-Host "`n[11/11] Querying Firewall Rules & Local Accounts..." -ForegroundColor Cyan
$firewallList = @()
if ($IncludeFirewall -and (Get-Command -Name Get-NetFirewallRule -ErrorAction SilentlyContinue)) {
    $relevantPorts = @("80", "443", "25", "587", "445")
    $rules = Get-NetFirewallRule -Enabled True -Direction Inbound -ErrorAction SilentlyContinue
    foreach ($r in $rules) {
        $portFilter = $r | Get-NetFirewallPortFilter -ErrorAction SilentlyContinue
        # Exact port comparison (a substring regex like "80|25" would also match 8080, 2525, ...)
        $rulePorts = @($portFilter.LocalPort | ForEach-Object { "$_" })
        $portMatch = @($rulePorts | Where-Object { $relevantPorts -contains $_ }).Count -gt 0
        if ($portMatch -or $r.DisplayGroup -match "World Wide Web|IIS|SMTP|File and Printer") {
            $firewallList += [ordered]@{
                Name         = $r.Name
                DisplayName  = $r.DisplayName
                DisplayGroup = $r.DisplayGroup
                Direction    = $r.Direction.ToString()
                Action       = $r.Action.ToString()
                Protocol     = $portFilter.Protocol
                LocalPort    = $portFilter.LocalPort
            }
        }
    }
}
Write-ManifestJson -FileName "firewall-rules.json" -Data $firewallList -Description "Inbound Windows Firewall rules for HTTP, HTTPS, SMTP, and SMB"

$localAccounts = [ordered]@{
    Users  = @()
    Groups = @()
}
if (Get-Command -Name Get-LocalUser -ErrorAction SilentlyContinue) {
    # Exclude built-in accounts: RID 500 Administrator, 501 Guest, 503 DefaultAccount,
    # 504 WDAGUtilityAccount; and BUILTIN groups (SID prefix S-1-5-32).
    $localAccounts.Users = @(Get-LocalUser |
        Where-Object { $_.SID.Value -notmatch '-(500|501|503|504)$' } |
        Select-Object Name, Enabled, Description, PasswordRequired, UserMayChangePassword)
    $localAccounts.Groups = @(Get-LocalGroup |
        Where-Object { $_.SID.Value -notlike 'S-1-5-32-*' } |
        Select-Object Name, Description)
}
Write-ManifestJson -FileName "local-accounts.json" -Data $localAccounts -Description "Non-domain local users and groups"

# -------------------------------------------------------------
# Write Master Manifest Index
# -------------------------------------------------------------
$manifestPath = Join-Path -Path $resolvedOutputDir -ChildPath "manifest.json"
$manifestJson = $manifestSummary | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($manifestPath, $manifestJson, [System.Text.Encoding]::UTF8)

# -------------------------------------------------------------
# Generate Human-Readable Markdown Report
# -------------------------------------------------------------
$reportPath = Join-Path -Path $resolvedOutputDir -ChildPath "Source-VM-Inventory-Report.md"
$reportBuilder = [System.Text.StringBuilder]::new()

[void]$reportBuilder.AppendLine("# Source VM Configuration Inventory Report")
[void]$reportBuilder.AppendLine("Generated: **$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')**  ")
[void]$reportBuilder.AppendLine("Source Host: **$($env:COMPUTERNAME)**  ")
[void]$reportBuilder.AppendLine("OS: **$($osInfo.Caption) ($($osInfo.Version), Build $($osInfo.BuildNumber))**  ")
[void]$reportBuilder.AppendLine("")
[void]$reportBuilder.AppendLine("---")
[void]$reportBuilder.AppendLine("## 1. Executive Summary")
[void]$reportBuilder.AppendLine("")
[void]$reportBuilder.AppendLine("| Subsystem | Status / Count | Summary Details |")
[void]$reportBuilder.AppendLine("|---|---|---|")
[void]$reportBuilder.AppendLine("| **Windows Features** | $($installedFeatures.Count) installed | Roles and subfeatures captured |")
[void]$reportBuilder.AppendLine("| **IIS Application Pools** | $($appPoolList.Count) pools | Identities, CLR versions, recycling policies |")
[void]$reportBuilder.AppendLine("| **IIS Websites** | $($siteList.Count) sites | Bindings, virtual directories, physical paths |")
[void]$reportBuilder.AppendLine("| **SMB Network Shares** | $($sharesList.Count) shares | Network share definitions and permissions |")
[void]$reportBuilder.AppendLine("| **NTFS Protected Paths** | $($aclEntries.Count) paths | SDDL security descriptors captured |")
[void]$reportBuilder.AppendLine("| **IIS 6.0 SMTP Server** | $(if ($smtpConfig.Installed) { 'Installed' } else { 'Not Found' }) | Smart host, drop dir, relay restrictions |")
[void]$reportBuilder.AppendLine("| **SMTPSVC Auto-Restart** | $(if ($smtpServiceConfig.ServiceFound) { $smtpServiceConfig.StartType } else { 'Not Present' }) | Service failure recovery actions captured |")
[void]$reportBuilder.AppendLine("| **SSL Certificates** | $($certList.Count) certs | Thumbprints and domain bindings |")
[void]$reportBuilder.AppendLine("")
[void]$reportBuilder.AppendLine("---")
[void]$reportBuilder.AppendLine("## 2. IIS Application Pools")
[void]$reportBuilder.AppendLine("")
[void]$reportBuilder.AppendLine("| Name | .NET Version | Pipeline | 32-Bit | Identity | Periodic Restart |")
[void]$reportBuilder.AppendLine("|---|---|---|---|---|---|")
foreach ($p in $appPoolList) {
    if ($p -is [hashtable] -or $p -is [System.Collections.Specialized.OrderedDictionary]) {
        [void]$reportBuilder.AppendLine("| **$($p.Name)** | $($p.ManagedRuntimeVersion) | $($p.ManagedPipelineMode) | $($p.Enable32BitAppOnWin64) | $($p.ProcessModel.IdentityType)$(if ($p.ProcessModel.UserName) { " ($($p.ProcessModel.UserName))" }) | $($p.Recycling.PeriodicRestartTime) |")
    }
}
[void]$reportBuilder.AppendLine("")
[void]$reportBuilder.AppendLine("---")
[void]$reportBuilder.AppendLine("## 3. IIS Websites & Bindings")
[void]$reportBuilder.AppendLine("")
foreach ($s in $siteList) {
    if ($s -is [hashtable] -or $s -is [System.Collections.Specialized.OrderedDictionary]) {
        [void]$reportBuilder.AppendLine("### Site: $($s.Name) (ID: $($s.Id))")
        [void]$reportBuilder.AppendLine("- **State**: $($s.State)")
        [void]$reportBuilder.AppendLine("- **Bindings**:")
        foreach ($b in $s.Bindings) {
            [void]$reportBuilder.AppendLine("  - ``$($b.Protocol)://$($b.BindingInformation)`` $(if ($b.CertificateThumbprint) { "[SSL: $($b.CertificateThumbprint)]" })")
        }
        [void]$reportBuilder.AppendLine("- **Applications / Virtual Directories**:")
        foreach ($app in $s.Applications) {
            [void]$reportBuilder.AppendLine("  - App Path: ``$($app.Path)`` (AppPool: **$($app.ApplicationPoolName)**)")
            foreach ($vd in $app.VirtualDirectories) {
                [void]$reportBuilder.AppendLine("    - VDir ``$($vd.Path)`` -> ``$($vd.PhysicalPath)``")
            }
        }
        [void]$reportBuilder.AppendLine("")
    }
}
[void]$reportBuilder.AppendLine("---")
[void]$reportBuilder.AppendLine("## 4. SMB Network Shares & NTFS Permissions")
[void]$reportBuilder.AppendLine("")
[void]$reportBuilder.AppendLine("| Share Name | Physical Path | Description | Share Permissions |")
[void]$reportBuilder.AppendLine("|---|---|---|---|")
foreach ($sh in $sharesList) {
    $perms = ($sh.AccessPermissions | ForEach-Object { "$($_.AccountName) ($($_.AccessRight))" }) -join ", "
    [void]$reportBuilder.AppendLine("| **$($sh.Name)** | ``$($sh.Path)`` | $($sh.Description) | $perms |")
}
[void]$reportBuilder.AppendLine("")
[void]$reportBuilder.AppendLine("---")
[void]$reportBuilder.AppendLine("## 5. IIS 6.0 SMTP & Service Recovery")
[void]$reportBuilder.AppendLine("")
if ($smtpConfig.Installed) {
    [void]$reportBuilder.AppendLine("- **Smart Host**: ``$($smtpConfig.Properties.SmartHost)``")
    [void]$reportBuilder.AppendLine("- **Drop Directory**: ``$($smtpConfig.Properties.DropDir)``")
    [void]$reportBuilder.AppendLine("- **Pickup Directory**: ``$($smtpConfig.Properties.PickupDir)``")
    [void]$reportBuilder.AppendLine("- **Port**: $($smtpConfig.Properties.Port)")
    [void]$reportBuilder.AppendLine("- **Relay Restrictions Configured**: $(if ($smtpConfig.RelayRestrictions.RawBlobPresent) { 'Yes (Binary Relay List Captured)' } else { 'Default' })")
} else {
    [void]$reportBuilder.AppendLine("*IIS 6.0 SMTP Server is not installed or configured on this machine.*")
}
[void]$reportBuilder.AppendLine("")
if ($smtpServiceConfig.ServiceFound) {
    [void]$reportBuilder.AppendLine("### SMTPSVC Service Recovery Actions")
    [void]$reportBuilder.AppendLine("- **Startup Type**: $($smtpServiceConfig.StartType)")
    [void]$reportBuilder.AppendLine("- **Status**: $($smtpServiceConfig.Status)")
    [void]$reportBuilder.AppendLine("- **Reset Failure Count**: $($smtpServiceConfig.RecoverySettings.ResetPeriodSeconds) seconds")
    [void]$reportBuilder.AppendLine("- **Failure Actions**:")
    foreach ($act in $smtpServiceConfig.RecoverySettings.ActionsSequence) {
        [void]$reportBuilder.AppendLine("  - Action: **$($act.Action)** (Delay: $($act.DelayMilliseconds) ms)")
    }
}
[void]$reportBuilder.AppendLine("")
[void]$reportBuilder.AppendLine("---")
[void]$reportBuilder.AppendLine("## 6. Next Steps: Twin Provisioning")
[void]$reportBuilder.AppendLine("1. Package content using ``Export-SiteContent.ps1``.")
[void]$reportBuilder.AppendLine("2. Generate target parameters using ``New-TwinBlueprint.ps1``.")
[void]$reportBuilder.AppendLine("3. Replay configuration on blank target VM using ``Apply-TargetVmTwin.ps1``.")
[void]$reportBuilder.AppendLine("4. Verify parity using ``Test-TargetVmTwin.ps1``.")

[System.IO.File]::WriteAllText($reportPath, $reportBuilder.ToString(), [System.Text.Encoding]::UTF8)
Write-Host "`n[+] Generated Inventory Report: $reportPath" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host " Discovery Complete. All operations were 100% read-only." -ForegroundColor Cyan
Write-Host " Output bundle ready at: $resolvedOutputDir" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Cyan
