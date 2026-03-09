<#
.SYNOPSIS
    Downloads a Blogger post and saves it as a local file.

.PARAMETER PostUrl
    The public URL of the Blogger post to download.

.PARAMETER OutputPath
    The local path where the downloaded post will be saved.
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$PostUrl,
    [Parameter(Mandatory=$false)]
    [string]$OutputPath="savepostoutput.html"
)

# Validation: Check if the output file already exists
if (Test-Path -Path $OutputPath) {
    Write-Error "Abort: The file '$OutputPath' already exists."
    return
}

try {
    # Fetch the live URL
    $response = Invoke-WebRequest -Uri $PostUrl -Method Get -UseBasicParsing -ErrorAction Stop
    
    # Check if response is null using the left-side $null standard
    if ($null -eq $response) {
        throw "No response received from $PostUrl"
    }

    # Save content to a file
    $response.Content | Out-File -FilePath $OutputPath -Encoding utf8
    Write-Output "Post saved to $OutputPath"    
}
catch {
    Write-Output "Error: Could not access $PostUrl. $($_.Exception.Message)"
}