# Blogger Blog Post Size Utility Scripts

These PowerShell scripts were developed using assistance of Gemini in chat with title: Blogger Feed Request Issue
in late Feb / early Mar 2026.

## postsize.ps1

Blogger feeds and Blogger API do not provide size metadata for blog posts.

Attempt to use Invoke-WebRequest with HEAD method to get Content-Length header for a post URL did not work.
It seems to return 0 KB as Content-Length due to Blogger’s hosting infrastructure using Chunked Transfer Encoding
for blog posts. When a server uses "chunked" encoding, it sends the data in a series of chunks as it's generated,
rather than measuring the whole thing first. So the server doesn't know the final size until the last chunk is sent.
Perhaps that's why it seems to send value 0 as Content-Length in the HEAD method response.

So we have to use GET method to retrieve the entire post content. We use the -UseBasicParsing switch to avoid the 
overhead of parsing the HTML content. If RawContentLength field in the response is not populated, we count the bytes 
in the content string.

### Example Usage

#### 1. Basic Console Output
Run the script with a single URL to see the size and the calculation method used:
```powershell
.\postsize.ps1 https://raviswdev.blogspot.com/2026/03/fixing-gemini-chat-to-blogger-compose.html
```
Console output:
```
URL:    https://raviswdev.blogspot.com/2026/03/fixing-gemini-chat-to-blogger-compose.html                                 Size:   177.29 KB (Calculated via RawContentLength header)
```

#### 2. Logging to a File (Pipeline Support)
Because the script uses Write-Output instead of Write-Host, you can use Tee-Object to view the results in the console while simultaneously saving them to a log file:  

```powershell
.\postsize.ps1 https://raviswdev.blogspot.com/2026/03/fixing-gemini-chat-to-blogger-compose.html | Tee-Object -FilePath "PostSizeReport.txt"
```

Console output:
```
URL:    https://raviswdev.blogspot.com/2026/03/fixing-gemini-chat-to-blogger-compose.html
Size:   177.29 KB (Calculated via RawContentLength header)
```

You can verify the saved report using the cat (Get-Content) command:
```
cat .\PostSizeReport.txt
```

Console output:
```
URL:    https://raviswdev.blogspot.com/2026/03/fixing-gemini-chat-to-blogger-compose.html
Size:   177.29 KB (Calculated via RawContentLength header)
```