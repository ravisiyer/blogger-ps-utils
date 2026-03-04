<#
.SYNOPSIS
    Calculates total historical Git blob storage for all .xlsx files in the repository.

.DESCRIPTION
    - Scans entire Git history (all branches).
    - Identifies blob objects corresponding to .xlsx files.
    - Reports:
        * Total number of historical versions
        * Total uncompressed blob storage (bytes and KB)
        * Per-file breakdown
    - Must be run from the root of a Git repository.

.NOTES
    Compatible with:
        - Windows 11
        - PowerShell 5.x
#>

# Ensure we are inside a Git repository
if (-not (Test-Path ".git")) {
    Write-Host "Error`: This script must be run from the root of a Git repository." -ForegroundColor Red
    exit 1
}

Write-Host "Scanning Git history for .xlsx blobs..." -ForegroundColor Cyan
Write-Host ""

# Get all blob objects with size and filename
$allObjects = git rev-list --objects --all |
    git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)"

# Filter only .xlsx blob entries
$xlsxBlobs = $allObjects | Where-Object {
    $_ -match "^blob" -and $_ -match "\.xlsx$"
}

if (-not $xlsxBlobs) {
    Write-Host "No .xlsx blobs found in repository history." -ForegroundColor Yellow
    exit 0
}

# Parse into structured objects
$parsed = foreach ($line in $xlsxBlobs) {
    $parts = $line -split "\s+", 3

    [PSCustomObject]@{
        Type     = $parts[0]
        Size     = [int64]$parts[1]
        FilePath = $parts[2]
    }
}

# Overall totals
$totalVersions = $parsed.Count
$totalBytes = ($parsed | Measure-Object -Property Size -Sum).Sum
$totalKB = [math]::Round($totalBytes / 1KB, 2)

Write-Host "Overall .xlsx historical storage" -ForegroundColor Green
Write-Host "---------------------------------"
Write-Host "Versions`:` $totalVersions"
Write-Host "TotalBytes`:` $totalBytes"
Write-Host ("TotalKB`:` {0:N2} KB" -f $totalKB)
Write-Host ""

# Per-file breakdown
Write-Host "Per-file breakdown" -ForegroundColor Green
Write-Host "-------------------"

$grouped = $parsed | Group-Object FilePath

foreach ($group in $grouped) {

    $fileVersions = $group.Count
    $fileBytes = ($group.Group | Measure-Object -Property Size -Sum).Sum
    $fileKB = [math]::Round($fileBytes / 1KB, 2)

    Write-Host ""
    Write-Host "File`:` $($group.Name)" -ForegroundColor Cyan
    Write-Host "  Versions`:` $fileVersions"
    Write-Host "  TotalBytes`:` $fileBytes"
    Write-Host ("  TotalKB`:` {0:N2} KB" -f $fileKB)
}

Write-Host ""
Write-Host "Done." -ForegroundColor Cyan