# Dot-source this file to load its aliases/functions into the current PowerShell session's scope.
# This makes the aliases/functions available to be called directly from the terminal for this session.
#
# Usage: . .\blogger-alias-cmds.ps1
#
# You can also dot-source the file into your Powershell profile. See comments at end of file about
# how to have basic error handling in that case.

# Set this path to folder having the scripts.
$blcmdsPath = "C:\Users\xyz-user\PS-Blogger"

# postsize.ps1 measures the full post size including Blogger theme, of a single Blogger post given its URL.
Set-Alias blpsz (Join-Path $blcmdsPath "postsize.ps1")

# scrapePurePostSize.ps1 measures the byte size of user-created Blogger post content ("pure" content) using scrape-blogger-post.ps1.
# No file is created on filesystem. URL of blog post has to passed as parameter.
Set-Alias blucpsz (Join-Path $blcmdsPath "scrapePurePostSize.ps1")

# checkPostBloat.ps1 detects ChatGPT and Dark Reader CSS bloat in a local HTML file which is post-orig.html by default.
# To use it with a different local file pass it as the first parameter.
Set-Alias blcpb (Join-Path $blcmdsPath "checkPostBloat.ps1")

# savepostasfile.ps1 uses Invoke-WebRequest which will download the whole blog post including theme.
# This is in contrast to scrape-blogger-post.ps1 which extracts the user-created Blogger post content only and excludes theme
Set-Alias blspaf (Join-Path $blcmdsPath "savepostasfile.ps1")

# BloggerMaxPostSize.md - Blogger Post Sizing and Deep-Dive Usability document
function blmaxpsz {
    Start-Process "C:\RI\OnlyRegReqRIData\MyWebSites\KBDocs\BloggerMaxPostSize.md"
}

Remove-Variable blcmdsPath


# Example code to dot-source the file into your Powershell profile. 
# blogger-alias-cmds.ps1 may be in user's PATH but not in same folder as .profile
# Find where this file lives in user's PATH, grab the full address, and then dot source it.
# Includes some error handling.

# Following code has to be added to user's profile after uncommenting the code part.
# $bloggerScript = Get-Command blogger-alias-cmds.ps1 -ErrorAction SilentlyContinue
# if ($bloggerScript) {
#     . $bloggerScript.Source
# }
# Remove-Variable bloggerScript

# Use below function to view blogger-alias-cmds.ps1 to see commands and associated aliases.
# function blcmdslist {
#     Get-Content (Get-Command blogger-alias-cmds.ps1).Source
# }

