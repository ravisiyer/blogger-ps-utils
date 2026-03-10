<#
.SYNOPSIS
    Batch runs a script against a list of URLs.
#>
param (
    [Parameter(Mandatory=$false)]
    [string]$UrlListFile="CleanUrlsList.txt",

    [Parameter(Mandatory=$false)]
    [string]$ScriptToRun = ".\postsize.ps1",

    [Parameter(Mandatory=$false)]
    [switch]$All
)

$startTime = Get-Date
Write-Output "--- Starting Batch Scan: $startTime ---"

if (-not (Test-Path $UrlListFile)) {
    Write-Error "URL list file not found: $UrlListFile"
    return
}

Write-Output "UrlListFile: $UrlListFile"
Write-Output "ScriptToRun: $ScriptToRun"

# Read simple line-by-line list
$urls = Get-Content $UrlListFile | Where-Object { $_ -match "http" }

if ($All.IsPresent) {
    $targetUrls = $urls
    Write-Output "--- FULL SCAN MODE: Processing all $($urls.Count) posts ---"
}
else {
    $targetUrls = $urls | Select-Object -First 10
    Write-Output "--- TEST RUN: Processing top 10 posts only ---"
}

$count = 1
foreach ($url in $targetUrls) {
    Write-Progress -Activity "Executing $ScriptToRun" -Status "Checking [$count/$($targetUrls.Count)]: $url" -PercentComplete (($count / $targetUrls.Count) * 100)
    
    # Execute the parameterized script
    & $ScriptToRun -PostUrl $url
    $count++
}

$duration = (Get-Date) - $startTime
Write-Output "`n--- Scan Complete. Duration: $($duration.Minutes)m $($duration.Seconds)s ---"