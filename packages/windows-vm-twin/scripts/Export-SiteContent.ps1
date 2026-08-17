<#
.SYNOPSIS
    Packages website roots and shared folder files into verified content archives (Read-Only).
.DESCRIPTION
    Reads discovered IIS site physical directories and SMB share paths, generates
    checksummed ZIP archives or sync manifests without mutating source files.
.PARAMETER ManifestDir
    Directory containing exported JSON manifests from Export-SourceVmTwin.ps1.
.PARAMETER OutputDir
    Destination folder to store compressed archives and content hash manifest.
.PARAMETER ExcludeLogs
    Whether to exclude runtime log directories (e.g., C:\inetpub\logs).
.PARAMETER Compress
    Compress each root folder into a individual .zip archive.
.EXAMPLE
    .\Export-SiteContent.ps1 -ManifestDir "C:\VM-Twin-Export" -OutputDir "C:\VM-Twin-Export\Content" -Compress
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ManifestDir = ".\VM-Twin-Export",

    [Parameter(Mandatory = $false)]
    [string]$OutputDir = ".\VM-Twin-Export\Content",

    [Parameter(Mandatory = $false)]
    [switch]$ExcludeLogs = $true,

    [Parameter(Mandatory = $false)]
    [switch]$Compress = $true
)

$ErrorActionPreference = "Stop"

$resolvedManifestDir = [System.IO.Path]::GetFullPath($ManifestDir)
$resolvedOutputDir = [System.IO.Path]::GetFullPath($OutputDir)

if (-not (Test-Path -LiteralPath $resolvedOutputDir)) {
    $null = New-Item -ItemType Directory -Path $resolvedOutputDir -Force
}

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host " Windows VM Configuration Twin - Content Archival Engine" -ForegroundColor Cyan
Write-Host " Source Manifest: $resolvedManifestDir" -ForegroundColor Yellow
Write-Host " Target Output:   $resolvedOutputDir" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Cyan

# Gather paths from iis-sites.json and smb-shares.json
$targetPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

$iisSitesFile = Join-Path -Path $resolvedManifestDir -ChildPath "iis-sites.json"
if (Test-Path -LiteralPath $iisSitesFile) {
    $sites = Get-Content -LiteralPath $iisSitesFile -Raw | ConvertFrom-Json
    foreach ($site in $sites) {
        foreach ($app in $site.Applications) {
            foreach ($vd in $app.VirtualDirectories) {
                if ($vd.PhysicalPath -and (Test-Path -LiteralPath $vd.PhysicalPath)) {
                    $null = $targetPaths.Add($vd.PhysicalPath)
                }
            }
        }
    }
}

$sharesFile = Join-Path -Path $resolvedManifestDir -ChildPath "smb-shares.json"
if (Test-Path -LiteralPath $sharesFile) {
    $shares = Get-Content -LiteralPath $sharesFile -Raw | ConvertFrom-Json
    foreach ($sh in $shares) {
        if ($sh.Path -and (Test-Path -LiteralPath $sh.Path)) {
            $null = $targetPaths.Add($sh.Path)
        }
    }
}

if ($targetPaths.Count -eq 0) {
    Write-Warning "No physical paths found in manifests or paths do not exist. Scanning default inetpub..."
    if (Test-Path "C:\inetpub\wwwroot") {
        $null = $targetPaths.Add("C:\inetpub\wwwroot")
    }
}

$contentManifest = [ordered]@{
    ArchiveDateUtc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    SourceHost     = $env:COMPUTERNAME
    Archives       = @()
}

Add-Type -AssemblyName System.IO.Compression           # ZipArchive, ZipArchiveMode, CompressionLevel
Add-Type -AssemblyName System.IO.Compression.FileSystem # ZipFile, ZipFileExtensions

$index = 1
foreach ($sourcePath in $targetPaths) {
    # Clean identifier name from path; cap length (deep source paths would push the
    # zip path past MAX_PATH) with a short hash suffix to keep names unique
    $safeName = ($sourcePath -replace '[:\\/]', '_').Trim('_')
    if ($safeName.Length -gt 80) {
        $sha1 = [System.Security.Cryptography.SHA1]::Create()
        $pathHash = ([System.BitConverter]::ToString($sha1.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($sourcePath))) -replace '-').Substring(0, 8)
        $sha1.Dispose()
        $safeName = $safeName.Substring(0, 71) + "_" + $pathHash
    }
    $zipFileName = "$safeName.zip"
    $zipFilePath = Join-Path -Path $resolvedOutputDir -ChildPath $zipFileName

    Write-Host "`n[$index/$($targetPaths.Count)] Processing: $sourcePath" -ForegroundColor Cyan
    $index++

    # Enumerate files up front so log exclusion and per-file error handling apply
    # in both modes; a single locked file must not abort the whole export.
    $rootFull = [System.IO.Path]::GetFullPath($sourcePath).TrimEnd('\')
    $allFiles = @(Get-ChildItem -LiteralPath $sourcePath -Recurse -File -Force -ErrorAction SilentlyContinue)
    $included = @()
    $excludedLogCount = 0
    foreach ($f in $allFiles) {
        $rel = $f.FullName.Substring($rootFull.Length).TrimStart('\')
        if ($ExcludeLogs -and $rel -match '(^|\\)(logs|logfiles)(\\|$)') {
            $excludedLogCount++
            continue
        }
        $included += [pscustomobject]@{ File = $f; RelativePath = $rel }
    }
    if ($excludedLogCount -gt 0) {
        Write-Host "  Excluding $excludedLogCount log file(s) (-ExcludeLogs)" -ForegroundColor Gray
    }

    if ($Compress) {
        if (Test-Path -LiteralPath $zipFilePath) {
            Remove-Item -LiteralPath $zipFilePath -Force
        }

        Write-Host "  Compressing $($included.Count) file(s) to $zipFileName..." -ForegroundColor Gray
        $skippedLocked = 0
        $zip = [System.IO.Compression.ZipFile]::Open($zipFilePath, [System.IO.Compression.ZipArchiveMode]::Create)
        try {
            foreach ($item in $included) {
                try {
                    $entryName = $item.RelativePath -replace '\\', '/'
                    $null = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                        $zip, $item.File.FullName, $entryName, [System.IO.Compression.CompressionLevel]::Optimal)
                }
                catch {
                    $skippedLocked++
                    Write-Warning "Skipped locked/unreadable file: $($item.File.FullName)"
                }
            }
        }
        finally {
            $zip.Dispose()
        }

        $fileInfo = Get-Item -LiteralPath $zipFilePath
        $sha256 = (Get-FileHash -Path $zipFilePath -Algorithm SHA256).Hash

        $contentManifest.Archives += [ordered]@{
            OriginalPath      = $sourcePath
            SafeName          = $safeName
            Mode              = "Zip"
            ArchiveFile       = $zipFileName
            SizeBytes         = $fileInfo.Length
            SizeMB            = [math]::Round($fileInfo.Length / 1MB, 2)
            Sha256            = $sha256
            FileCount         = $included.Count - $skippedLocked
            ExcludedLogFiles  = $excludedLogCount
            SkippedLockedFiles = $skippedLocked
        }
        Write-Host "  [+] Created: $zipFileName ($([math]::Round($fileInfo.Length / 1MB, 2)) MB, SHA256: $sha256)" -ForegroundColor Green
    }
    else {
        # Inventory mode: no archive, just a checksummed file listing for sync/diff tooling
        Write-Host "  Building checksum inventory for $($included.Count) file(s)..." -ForegroundColor Gray
        $fileEntries = @()
        foreach ($item in $included) {
            $hash = $null
            try {
                $hash = (Get-FileHash -LiteralPath $item.File.FullName -Algorithm SHA256 -ErrorAction Stop).Hash
            }
            catch {
                Write-Warning "Could not hash locked/unreadable file: $($item.File.FullName)"
            }
            $fileEntries += [ordered]@{
                RelativePath = $item.RelativePath
                SizeBytes    = $item.File.Length
                Sha256       = $hash
            }
        }

        $contentManifest.Archives += [ordered]@{
            OriginalPath     = $sourcePath
            SafeName         = $safeName
            Mode             = "Inventory"
            FileCount        = $fileEntries.Count
            ExcludedLogFiles = $excludedLogCount
            Files            = $fileEntries
        }
        Write-Host "  [+] Inventoried: $sourcePath ($($fileEntries.Count) files)" -ForegroundColor Green
    }
}

# Write Content Manifest
$contentManifestPath = Join-Path -Path $resolvedOutputDir -ChildPath "content-manifest.json"
$json = $contentManifest | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($contentManifestPath, $json, [System.Text.Encoding]::UTF8)

Write-Host "`n[+] Content packaging complete. Manifest saved to $contentManifestPath" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
