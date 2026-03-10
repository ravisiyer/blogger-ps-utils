<#
.SYNOPSIS
    Extracts blog post URLs from an HTML file by searching for href attributes.
#>
param (
    [Parameter(Mandatory=$false)]
    [string]$InputFile = "PostsList.html",

    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "CleanUrlsList.txt",

    [Parameter(Mandatory=$false)]
    [string]$BlogBaseUrl = "https://raviswdev.blogspot.com"
)

if (-not (Test-Path $InputFile)) {
    Write-Error "Input file not found: $InputFile"
    return
}

# 1. Generalized Regex Pattern
# Focuses strictly on the href attribute to handle multi-line formatting
$escapedBaseUrl = [Regex]::Escape($BlogBaseUrl)
$urlPattern = "href=`"($escapedBaseUrl/.*?\.html)`""

$content = Get-Content $InputFile -Raw
$myMatches = [regex]::Matches($content, $urlPattern)

if ($null -eq $myMatches -or $myMatches.Count -eq 0) {
    Write-Warning "No URLs found matching $BlogBaseUrl"
    return
}

# 2. Extraction and Deduplication
# Extracts the captured URL group and ensures each link appears only once
$urls = $myMatches | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique

# 3. Output
$urls | Out-File -FilePath $OutputFile -Encoding utf8

Write-Output "Successfully extracted $($urls.Count) URLs to $OutputFile"