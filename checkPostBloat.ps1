<#
.SYNOPSIS
    Detects ChatGPT and Dark Reader CSS bloat in a local HTML file.
.DESCRIPTION
    Scans a local file (copy-pasted from Blogger 'Edit HTML' window) for 
    specific signatures. The Invoke-WebRequest approach was abandoned 
    because Blogger's server-side rendering often strips these attributes 
    from the live URL, resulting in false negatives even when bloat exists 
    in the saved database content.
#>

function checkPostBloat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Path = "post-orig.html"
    )

    try {
        if (-not (Test-Path -Path $Path)) {
            Write-Error "File not found: $Path"
            return
        }

        # Get-Content -Raw is essential to keep the entire file as one string for regex matching
        $content = Get-Content -Path $Path -Raw
        
        if ($null -eq $content -or $content.Length -eq 0) {
            Write-Warning "File is empty: $Path"
            return
        }

        $fileSizeKb = [math]::Round($content.Length / 1KB, 2)
        
        # Signatures for detection (ChatGPT, Dark Reader, and Office)
        $signatures = @{
            "ChatGPT UI Classes"    = '(?<=class=|id=")[^">]*(markdown|prose|prose-invert|token)[^">]*'
            "Dark Reader Extension" = "darkreader|--darkreader|data-darkreader"            
            "Office/Mso Bloat"      = "mso-|mso-line-height-rule"
            "Excessive Inline CSS"  = "style=.*font-family:.*font-size:.*line-height:"
        }

        Write-Host "`n--- Local File Report: $Path ($fileSizeKb KB) ---" -ForegroundColor Cyan
        
        $totalFound = 0
        foreach ($entry in $signatures.GetEnumerator()) {
            # Ensure $null is on the left of equality comparisons
            $myMatches = [Regex]::Matches($content, $entry.Value)
            if ($null -ne $myMatches -and $myMatches.Count -gt 0) {
                Write-Host "[!] FOUND: $($entry.Key) ($($myMatches.Count) occurrences)" -ForegroundColor Yellow
                $totalFound += $myMatches.Count
            }
        }

        if (0 -eq $totalFound) {
            Write-Host "[OK] No common AI or Extension bloat detected in the local file." -ForegroundColor Green
        } else {
            # Calculate density (signatures per 100 characters)
            $density = [math]::Round(($totalFound / ($content.Length / 100)), 4)
            Write-Host "[SUMMARY] Database bloat found. Bloat Density Score: $density" -ForegroundColor Red
        }
    }
    catch {
        Write-Error "Failed to process $Path. Error: $($_.Exception.Message)"
    }
}

# Allow execution from command line with a path or default to post-orig.html
$targetFile = if ($null -ne $args[0]) { $args[0] } else { "post-orig.html" }
checkPostBloat -Path $targetFile