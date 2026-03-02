<#
.SYNOPSIS
    Iterates through a list of blog posts and measures the size of each.
    Part of the Blogger CSS Sanitization workflow.
    URL: https://raviswdev.blogspot.com/2026/03/fixing-gemini-chat-to-blogger-compose.html

.DESCRIPTION
    Parses an HTML file containing a list of blog posts, extracts the URLs, 
    and invokes postsize.ps1 to report the payload size of each.

.PARAMETER PostListFile
    The HTML file containing the post list (Default: PostsLists.html).

.PARAMETER All
    If present, scans all posts. Otherwise, performs a 10-post test run.
#>

param (
    [Parameter(Mandatory=$false)]
    [string]$PostListFile = "PostsList.html",

    [Parameter(Mandatory=$false)]
    [switch]$All
)

$startTime = Get-Date
Write-Output "--- Starting Post Size Scan: $startTime ---"

# 1. Validation
if (-not (Test-Path $PostListFile)) {
    Write-Output "Error: Source list file not found: $PostListFile"
    return
}

$content = Get-Content $PostListFile -Raw
$urlPattern = 'class="post-item">.*?href="(https://raviswdev\.blogspot\.com/.*?\.html)"'
$allMatches = [regex]::Matches($content, $urlPattern)
$totalFound = $allMatches.Count

# 2. Scope Logic
if ($All.IsPresent) {
    $targetMatches = $allMatches
    Write-Output "--- FULL SCAN MODE: Processing all $totalFound posts ---"
}
else {
    $targetMatches = $allMatches | Select-Object -First 10
    Write-Output "--- TEST RUN: Processing top 10 posts only ---"
    Write-Output "Tip: Use '-All' to scan every post in the list."
}

# 3. Execution Loop
$count = 1
foreach ($match in $targetMatches) {
    $url = $match.Groups[1].Value
    
    # Progress bar remains Write-Progress as it doesn't affect the text stream
    Write-Progress -Activity "Scanning Post Sizes" -Status "Checking [$count/$($targetMatches.Count)]: $url" -PercentComplete (($count / $targetMatches.Count) * 100)
    
    # Invoke the individual size script
    .\postsize.ps1 -PostUrl $url
    
    $count++
}

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Output "`n--- Scan Complete ---"
Write-Output "Finished at: $endTime"
Write-Output "Total Duration: $($duration.Minutes)m $($duration.Seconds)s"