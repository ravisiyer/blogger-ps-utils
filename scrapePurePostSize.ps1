<#
.SYNOPSIS
    Measures the byte size of "pure" HTML content from scrape-blogger-post.ps1.

.PARAMETER PostUrl
    The public URL of the Blogger post.
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$PostUrl
)

try {
    # Execute the scraper with the 'pure' flag and capture output directly
    # Using the call operator (&) to execute the existing script
    $pureContent = & scrape-blogger-post.ps1 -f pure $PostUrl

    # Check if response is null using the left-side $null standard
    if ($null -eq $pureContent) {
        throw "No content returned from scrape-blogger-post.ps1 for $PostUrl"
    }

    # Calculate byte count based on UTF8 (matching your manual verification)
    $byteCount = [System.Text.Encoding]::UTF8.GetByteCount($pureContent)
    $sizeKB = [math]::Round(($byteCount / 1KB), 2)

    Write-Output "----------------------------------------------------"
    Write-Output "URL:        $PostUrl"
    Write-Output "Scraped Pure Post Size:  $sizeKB KB"
}
catch {
    Write-Output "Error: Could not calculate scraped pure post size for $PostUrl. $($_.Exception.Message)"
}