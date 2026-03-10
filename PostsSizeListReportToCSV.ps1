<#
.SYNOPSIS
    Transforms a postsInListSize.ps1 output file into a CSV for Excel.
#>
param (
    [Parameter(Mandatory=$false)]
    [string]$InputFile = "PostsSizeListReport.txt",

    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "PostsSizeListReport.csv"
)

if (-not (Test-Path $InputFile)) {
    Write-Error "Log file not found: $InputFile"
    return
}

$logContent = Get-Content $InputFile -Raw
$results = New-Object System.Collections.Generic.List[PSObject]

# Regex to find URL and the decimal figure
# This looks for "URL: [URL]" and the next instance of "Size: [Number]"
$pattern = "(?s)URL:\s+(https?://[^\s]+).*?Size:\s+([\d\.]+)\s+KB"
$myMatches = [regex]::Matches($logContent, $pattern)

foreach ($item in $myMatches) {
    $results.Add([PSCustomObject]@{
        "URL"       = $item.Groups[1].Value
        "Size (KB)" = $item.Groups[2].Value
    })
}

if ($null -eq $results -or $results.Count -eq 0) {
    Write-Warning "No valid data found in the input file to transform."
}
else {
    $results | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding utf8
    Write-Output "Successfully transformed $($results.Count) entries to $OutputFile"
}