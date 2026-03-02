<#
.SYNOPSIS
    Downloads a Blogger post and measures its payload size.

.DESCRIPTION
    Retrieves the raw HTML of a blog post to identify size bloat. 
    Reports whether the size was derived from HTTP headers or a manual byte count.

.PARAMETER PostUrl
    The public URL of the Blogger post to measure.
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$PostUrl
)

try {
    $response = Invoke-WebRequest -Uri $PostUrl -Method Get -UseBasicParsing -ErrorAction Stop
    
    $rawSize = $response.RawContentLength
    $source = "RawContentLength header"

    # Fallback to manual byte count if header is missing or 0
    if ($null -eq $rawSize -or $rawSize -eq 0) {
        $rawSize = [System.Text.Encoding]::UTF8.GetByteCount($response.Content)
        $source = "manual UTF8 byte count"
    }

    $sizeKB = [math]::Round(($rawSize / 1KB), 2)
    
    # Using Write-Output so Tee-Object can capture the data
    Write-Output "----------------------------------------------------"
    Write-Output "URL:    $PostUrl"
    Write-Output "Size:   $sizeKB KB (Calculated via $source)"
    
    if ($sizeKB -gt 500) {
        Write-Output "WARNING: High bloat detected (> 500KB)."
    }
}
catch {
    Write-Output "Error: Could not access $PostUrl"
}