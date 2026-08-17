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

Add-Type -AssemblyName System.IO.Compression.FileSystem

$index = 1
foreach ($sourcePath in $targetPaths) {
    # Clean identifier name from path
    $safeName = ($sourcePath -replace '[:\\/]', '_').Trim('_')
    $zipFileName = "$safeName.zip"
    $zipFilePath = Join-Path -Path $resolvedOutputDir -ChildPath $zipFileName

    Write-Host "`n[$index/$($targetPaths.Count)] Processing: $sourcePath" -ForegroundColor Cyan
    $index++

    if ($Compress) {
        if (Test-Path -LiteralPath $zipFilePath) {
            Remove-Item -LiteralPath $zipFilePath -Force
        }

        Write-Host "  Compressing to $zipFileName..." -ForegroundColor Gray
        try {
            [System.IO.Compression.ZipFile]::CreateFromDirectory($sourcePath, $zipFilePath, [System.IO.Compression.CompressionLevel]::Optimal, $false)
            $fileInfo = Get-Item -LiteralPath $zipFilePath
            $sha256 = (Get-FileHash -Path $zipFilePath -Algorithm SHA256).Hash

            $contentManifest.Archives += [ordered]@{
                OriginalPath = $sourcePath
                SafeName     = $safeName
                ArchiveFile  = $zipFileName
                SizeBytes    = $fileInfo.Length
                SizeMB       = [math]::Round($fileInfo.Length / 1MB, 2)
                Sha256       = $sha256
            }
            Write-Host "  [+] Created: $zipFileName ($([math]::Round($fileInfo.Length / 1MB, 2)) MB, SHA256: $sha256)" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to compress $sourcePath: $_"
        }
    }
}

# Write Content Manifest
$contentManifestPath = Join-Path -Path $resolvedOutputDir -ChildPath "content-manifest.json"
$json = $contentManifest | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($contentManifestPath, $json, [System.Text.Encoding]::UTF8)

Write-Host "`n[+] Content packaging complete. Manifest saved to $contentManifestPath" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
