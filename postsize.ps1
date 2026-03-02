param (
    [Parameter(Mandatory=$true)]
    [string]$PostUrl
)

try {
    # We must use GET because HEAD doesn't return size for chunked Blogger posts
    # -UseBasicParsing keeps it fast by not rendering the HTML
    $response = Invoke-WebRequest -Uri $PostUrl -Method Get -UseBasicParsing -ErrorAction Stop
    
    # Measure the actual byte count of the raw content
    $rawSize = $response.RawContentLength
    
    # If RawContentLength is not populated, we count the bytes in the content string
    if ($null -eq $rawSize -or $rawSize -eq 0) {
        $rawSize = [System.Text.Encoding]::UTF8.GetByteCount($response.Content)
    }

    $sizeKB = [math]::Round(($rawSize / 1KB), 2)
    Write-Host "Success: Post downloaded and measured." -ForegroundColor Green
    Write-Host "URL:  $PostUrl"
    Write-Host "Size: $sizeKB KB" -ForegroundColor Cyan
    
    if ($sizeKB -gt 500) {
        Write-Host "WARNING: High bloat detected (> 500KB)." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Error: Could not access $PostUrl" -ForegroundColor Red
}