param (
    [Parameter(Mandatory=$false)]
    [switch]$All
)

# 1. Configuration
$htmlFile = "20260301-raviswdev-Posts-list.html"
if (-not (Test-Path $htmlFile)) {
    Write-Error "Source list file not found: $htmlFile"
    exit
}

$content = Get-Content $htmlFile -Raw
$urlPattern = 'class="post-item">.*?href="(https://raviswdev\.blogspot\.com/.*?\.html)"'

# Use [regex]::Matches and store in a custom variable to avoid $matches conflict
$allMatches = [regex]::Matches($content, $urlPattern)
$totalFound = $allMatches.Count

# 2. Determine Scope Logic
if ($All.IsPresent) {
    $targetMatches = $allMatches
    Write-Host "--- FULL AUDIT MODE: Processing all $totalFound posts ---" -ForegroundColor Red
}
else {
    $targetMatches = $allMatches | Select-Object -First 10
    Write-Host "--- TEST RUN: Processing top 10 posts only ---" -ForegroundColor Cyan
    Write-Host "Tip: Use '.\Audit-AllPosts.ps1 -All' to scan every post." -ForegroundColor Gray
}

# 3. Execution Loop
$count = 1
foreach ($match in $targetMatches) {
    $url = $match.Groups[1].Value
    
    # Progress feedback
    Write-Progress -Activity "Auditing Blog" -Status "Checking [$count/$($targetMatches.Count)]: $url" -PercentComplete (($count / $targetMatches.Count) * 100)
    
    # Invoke your existing postsize script
    .\postsize.ps1 -PostUrl $url
    
    $count++
}

Write-Host "`nAudit complete." -ForegroundColor Green