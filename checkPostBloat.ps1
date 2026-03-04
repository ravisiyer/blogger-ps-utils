<#
.SYNOPSIS
    Detects ChatGPT and Dark Reader CSS bloat in a live blog post URL.
.DESCRIPTION
    Fetches HTML content from a URL using -UseBasicParsing and scans for 
    specific signatures like 'markdown prose' and 'darkreader' CSS.
#>

function checkPostBloat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Url
    )

    try {
        # Fetch content with Basic Parsing to avoid IE dependencies
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -Method Get
        
        if ($null -eq $response -or $null -eq $response.Content) {
            Write-Warning "Could not retrieve content from: $Url"
            return
        }

        $content = $response.Content
        $fileSizeKb = [math]::Round($content.Length / 1KB, 2)
        
        # Signatures for detection (ChatGPT, Dark Reader, and Office)
        $signatures = @{
          "ChatGPT UI Classes"    = '(?<=class=|id=")[^">]*(markdown|prose|prose-invert)[^">]*'
          # "ChatGPT UI Classes"    = "markdown|prose|dark:prose-invert"
            "Dark Reader Extension" = "darkreader|--darkreader"
            "Office/Mso Bloat"      = "mso-|mso-line-height-rule"
            "Excessive Inline CSS"  = "style=.*font-family:.*font-size:.*line-height:"
        }

        Write-Host "`n--- Live URL Report: $Url ($fileSizeKb KB) ---" -ForegroundColor Cyan
        
        $totalFound = 0
        foreach ($entry in $signatures.GetEnumerator()) {
            $myMatches = [Regex]::Matches($content, $entry.Value)
            if ($null -ne $myMatches -and $myMatches.Count -gt 0) {
                Write-Host "[!] FOUND: $($entry.Key) ($($myMatches.Count) occurrences)" -ForegroundColor Yellow
                $totalFound += $myMatches.Count
            }
        }

        if ($totalFound -eq 0) {
            Write-Host "[OK] No common AI or Extension bloat detected." -ForegroundColor Green
        } else {
            # Calculate density (signatures per 100 characters)
            $density = [math]::Round(($totalFound / ($content.Length / 100)), 4)
            Write-Host "[SUMMARY] Possible copy-paste bloat found. Bloat Density Score: $density" -ForegroundColor Red
        }
    }
    catch {
        Write-Error "Failed to fetch $Url. Error: $($_.Exception.Message)"
    }
}

checkPostBloat -Url $args[0]
