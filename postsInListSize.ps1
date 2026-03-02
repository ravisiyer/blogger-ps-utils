<#
.SYNOPSIS
    Iterates through a list of blog posts and measures the size of each.

.DESCRIPTION
    Parses an HTML file containing a list of blog posts, extracts URLs for a 
    specific blog domain, and invokes postsize.ps1 to report the payload size.

.PARAMETER BlogBaseUrl
    The base URL of the Blogger blog (e.g., https://ravisiyer.blogspot.com).
    Default: https://raviswdev.blogspot.com

.PARAMETER PostListFile
    The HTML file containing the post list (Default: PostsList.html).

.PARAMETER All
    If present, scans all posts. Otherwise, performs a 10-post test run.
#>

param (
    [Parameter(Mandatory=$false)]
    [string]$BlogBaseUrl = "https://raviswdev.blogspot.com",

    [Parameter(Mandatory=$false)]
    [string]$PostListFile = "PostsList.html",

    [Parameter(Mandatory=$false)]
    [switch]$All
)

$startTime = Get-Date
Write-Output "--- Starting Post Size Scan: $startTime ---"
Write-Output "Target Blog: $BlogBaseUrl"

# 1. Validation
if (-not (Test-Path $PostListFile)) {
    Write-Output "Error: Source list file not found: $PostListFile"
    return
}

# 2. Dynamic Regex Pattern
# [Regex]::Escape ensures characters like '.' in the URL don't break the pattern
$escapedBaseUrl = [Regex]::Escape($BlogBaseUrl)
$urlPattern = "class=`"post-item`">.*?href=`"($escapedBaseUrl/.*?\.html)`""

$content = Get-Content $PostListFile -Raw
$allMatches = [regex]::Matches($content, $urlPattern)
$totalFound = $allMatches.Count

if ($totalFound -eq 0) {
    Write-Output "Warning: No posts found matching $BlogBaseUrl in $PostListFile"
    return
}

# 3. Scope Logic
if ($All.IsPresent) {
    $targetMatches = $allMatches
    Write-Output "--- FULL SCAN MODE: Processing all $totalFound posts ---"
}
else {
    $targetMatches = $allMatches | Select-Object -First 10
    Write-Output "--- TEST RUN: Processing top 10 posts only ---"
    Write-Output "Tip: Use '-All' to scan every post in the list."
}

# 4. Execution Loop
$count = 1
foreach ($match in $targetMatches) {
    $url = $match.Groups[1].Value
    Write-Progress -Activity "Scanning Post Sizes" -Status "Checking [$count/$($targetMatches.Count)]: $url" -PercentComplete (($count / $targetMatches.Count) * 100)
    
    .\postsize.ps1 -PostUrl $url
    $count++
}

$endTime = Get-Date
$duration = $endTime - $startTime
Write-Output "`n--- Scan Complete ---"
Write-Output "Finished at: $endTime"
Write-Output "Total Duration: $($duration.Minutes)m $($duration.Seconds)s"