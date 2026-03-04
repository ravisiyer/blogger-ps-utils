# Blogger Blog Post Size Utility Scripts

These utility PowerShell scripts are designed to help measure the payload size of individual Blogger posts 
and to automate the process of scanning multiple posts of a blog for size analysis. The main goal is to 
identify posts that may have excessive content (such as unnecessary CSS) that could lead to performance 
issues in Blogger feeds and Blogger Compose Post editing interface.

The scripts are:
1. [postsize.ps1](#postsizeps1): Measures the size of a single Blogger post given its URL.
2. [postsInListSize.ps1](#postsinlistsizeps1): Parses a local HTML file containing a list of Blogger post URLs (in a particular format) and invokes `postsize.ps1` for each URL to generate a comprehensive report of sizes for all posts in the list.

The section [Scan Data Processing and Payload Analysis](#scan-data-processing-and-payload-analysis) details the steps taken to transform the comprehensive report (raw scan output) of postsInListSize.ps1 for one particular Blogger blog into an Excel workbook with one sheet having sorted list of posts in descending order of post size. But these steps were quite cumbersome and time-consuming.

The section [Simpler Alternatives to Create Excel Spreadsheet from Raw Scan Output](#simpler-alternatives-to-create-excel-spreadsheet-from-raw-scan-output) gives some suggestion(s) for doing the above task in a simpler way.

A separate document [checkPostBloat.md](./checkPostBloat.md) covers [checkPostBloat.ps1](./checkPostBloat.ps1) script which detects ChatGPT and Dark Reader CSS bloat  in a live blog post URL.

The [Get-XlsxBlobStorage.ps1](./Get-XlsxBlobStorage.ps1) script helps to understand how much space Excel files were consuming across repository history. The background for this script is covered in my blog post [Git is not suitable for managing versions of Excel and Word files](https://raviswdev.blogspot.com/2026/03/git-is-not-suitable-for-managing.html). This Get-XlsxBlobStorage.ps1 script is not expected to be used further for this project's work but is being retained just in case it is useful for some other project or perhaps for this project itself in future.

---

## postsize.ps1

This script downloads a Blogger post and measures its payload size. It is useful for identifying posts 
that may have unnecessary CSS (for example, due to copy-pasting rich text from Gemini chat) or other 
similar content that may increase the post size to above 500 KB which may cause performance issues for 
blog feed requests and slow UI responses for blog post editing in Blogger Compose.  

### Implementation Notes
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
URL:    https://raviswdev.blogspot.com/2026/03/fixing-gemini-chat-to-blogger-compose.html
Size:   177.29 KB (Calculated via RawContentLength header)
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
---

## postsInListSize.ps1

This script automates the measurement of size of multiple blog posts by parsing a local HTML list of posts file (typically `PostsList.html`) and invoking `postsize.ps1` for each identified URL. This results in a comprehensive report of sizes for all posts in the list, which can be used to identify posts that may have excessive content and are candidates for optimization.

The local HTML list of posts file is expected to be created through my [BloggerAllPostsLister web app](https://ravisiyer.github.io/BloggerAllPostsLister/?blog=https://raviswdev.blogspot.com/). After the list of posts for a Blogger blog is dynamically generated by the web app, you can click on the 'Save as HTML' button to download the posts list HTML file, which serves as the input for `postsInListSize.ps1`.

`20260301-raviswdev-Posts-list.html` is an example of such a file that I have created for the default raviswdev blog on 1 March 2026. I later made a copy of this file and named it as `PostsList.html`.

Gemini studied the structure of this HTML file and implemented a regular expression to extract post URLs by identifying the `post-item` class containers.

### Key Features

* **Targeted Scanning**: Extracts only the URLs belonging to a specific blog domain to avoid processing external links.
* **Flexible Inputs**: Supports custom blog URLs and different source HTML list files via parameters.
* **Scan Logging**: Fully compatible with `Tee-Object` to create timestamped reports of blog health.

### Parameters

* **`-BlogBaseUrl`**: The home URL of the Blogger blog. (Default: `https://raviswdev.blogspot.com`).
* **`-PostListFile`**: The HTML file containing the post list. (Default: `PostsList.html`).
* **`-All`**: A switch to scan the entire list. Without this, the script performs a first 10-posts "Test Run".

### Example Usage

#### 1. Standard Scan (Default Blog)

To run a full scan of the default blog and save the output:

```powershell
.\postsInListSize.ps1 -All | Tee-Object -FilePath "FullBlogScan.txt"
```

#### 2. Test Run (First 10 Posts)

Quickly verify connectivity and formatting without a full scan:

```powershell
.\postsInListSize.ps1
```

#### 3. Scanning a Different Blog

*`Note that the code seems to cater to this use case but this use case has not been tested.`*

To scan another blog:

```powershell
.\postsInListSize.ps1 -BlogBaseUrl "https://ravisiyer.blogspot.com" -All
```

### Measurement Logic

The script uses a regular expression to find `post-item` classes within your local HTML file. It then passes these URLs to `postsize.ps1`, which calculates the size based on the `RawContentLength` header or a manual UTF8 byte count.

---

## Scan Data Processing and Payload Analysis

Initial prompt given to Gemini for this task: 

`I uploaded file: "2026-03-02 17-40-20PostsInListSizeReport.txt" which is the output file of the -All run for default blog. Can you create an Excel or Google Sheets sheet - your choice - which will convert the output file to a spreadsheet with two columns for each file (I meant post) - URL and size. The size column can omit the '(Calculated via RawContentLength header)' part.`

Note that, IFIRC, I later renamed "2026-03-02 17-40-20PostsInListSizeReport.txt" to "2026-03-02 17-40-20-Orig-PostsInListSizeReport.txt".

Gemini did not create an Excel or Google Sheets sheet. Neither did it provide me a .csv or .md file to download. This seems to be a limitation of Gemini chat even with 'Google AI Pro' plan. Instead Gemini provided me a very long Markdown table with requested data as part of its response and then asked me to insert that data into Google Sheets. 

Using Gemini guidance, I was able to correctly get the data into separate columns in Google Sheets, remove markdown code for URL and delete unwanted blank lines. That procedure turned out to be quite cumbersome and time-consuming. It is given below in rest of this section, and is a Gemini provided draft modified by me. In it, the 'User' is me.

Also see the next section [Simpler Alternatives to Create Excel Spreadsheet from Raw Scan Output](#simpler-alternatives-to-create-excel-spreadsheet-from-raw-scan-output).

Given below are the steps taken by the user to transform the raw scan output into a structured, actionable data set.

### 1. Data Transformation and Formatting

* The user provided the raw output file, **2026-03-02 17-40-20PostsInListSizeReport.txt**, which contained the full scan results for the default blog.
* A request was made to convert this text report into a two-column spreadsheet format consisting of **URL** and **Size** (omitting the "Calculated via..." metadata).
* In response, Gemini provided a Markdown table to be copy-pasted into Google Sheets.

### 2. Google Sheets Refinement

* Guidance was provided on using the **Split text to columns** feature to correctly separate the data after pasting.
    - Select the Data: Click the header of Column A to highlight all the pasted rows.
    - Open the Tool: In the top menu, navigate to Data and then select Split text to columns.
    - Choose the Separator: A small dropdown menu will appear near the bottom of the selection. Change Separator: Detect automatically to Custom.
    - Enter the Pipe Symbol: Type the pipe character | into the custom box.

* Regular expressions were used within Google Sheets to remove the Markdown URL code, leaving only plain, functional hyperlinks.
    - Select the URL Column: Click the letter at the top of the column containing the Markdown links (likely Column A).
    - Open Find and Replace: Press Ctrl + H.
    - Enter the Pattern:
      - Find: `^.*?\((https?://.*?)\).*$`
      - Replace with: `$1`
    - Enable Regex: Check the box that says Search using regular expressions.
    - Apply: Click Replace all.
    - Why this works
      - `The Regex pattern ^.*?\((https?://.*?)\).*$ identifies the text inside the parentheses - which is the actual URL - and the $1 replacement tells Google Sheets to discard everything else and keep only that specific captured group.`

* Unwanted blank lines generated during the copy-paste process were removed using sorting and filtering techniques.
    - Turn on Filter: Highlight Column A and click Data > Create a filter.
    - Filter for Blanks: Click the green filter icon in cell A1, click Clear, and then check only the box for (Blanks). Click OK.
    - Delete Rows: Now that only the empty rows are visible, highlight them (starting from row 2 down to the end), right-click, and select Delete selected rows.
    - Turn off Filter: Go back to the filter icon in A1 and select Select all, or go to Data > Remove filter.

### 3. Data Integrity and Manual Verification

* The user identified a missing entry in the spreadsheet compared to the expected post count.
* Analysis of the report file revealed an access error for one specific URL: `notes-on-2nd-round-of-nodejs-expressjs.html`.
* The user manually executed `postsize.ps1` for the failed URL, obtained the correct size data, and integrated it into the spreadsheet to ensure a 100% complete dataset of 297 entries.

### 4. Final Organization

* The final dataset was moved into an Excel workbook `2026-03-02 17-40-20PostsInListSizeReport.xlsx` containing two primary sheets:  
    * **Raw Data**: The complete list of URLs and their sizes.
    * **Sorted Data**: The list sorted in descending order by size to highlight the largest "bloat" candidates.

### 5. Template Overhead Analysis

* The user performed a comparative analysis using the lowest size entry found in the Scan (**109.28 KB**).
* By running a separate [scrape-blogger-post](https://github.com/ravisiyer/scrape-blogger-post) utility on that post, it was determined the actual user-created post content in Blogger was only **1.82 KB** (size on disk for output file is 4 KB).
* This experiment allowed the user to calculate that the fixed overhead for the blog template (headers, footers, and CSS) is approximately **107 KB** per post (109.28 - 1.82 = 107.46).
* A later comparison for a recent post: https://raviswdev.blogspot.com/2026/03/identifying-blogger-blog-posts-with.html gives this data:
  - `postsize.ps1` output: Size:   111.92 KB (Calculated via RawContentLength header)
  - `scrape-blogger-post` output file size for the same post: 3.48 KB (size on disk is 4 KB) 
  - So the template overhead is 108.44 KB for this recent post.
* This benchmark enables the user to determine that a 160 KB post would probably contain around 51 to 53 KB of actual user-created post content payload.

### 6. To Do If Needed

* A mechanism should be explored for `postsize.ps1` to return explicit signals (such as exit codes) to the caller when errors occur.
* The calling script should then be updated to utilize these signals to provide a final summary of successful versus failed measurements at the end of a run.

## Simpler Alternatives to Create Excel spreadsheet from Raw Scan Output
  *`Note that this section is written by me and not drafted by Gemini.`*
  * I had thought that Gemini in my 'Google AI Pro' plan may have the ability to create an Excel or Google Sheets spreadsheet from a raw data text file that I provided. But Gemini was not able to do that. On asking about it, Gemini said, "No Direct File Downloads: Currently, the assistant cannot generate a physical .md or .csv file for the user to download directly to a hard drive." It is possible that Google Colab and other Google AI tools may not have the same limitation.
  * Where Gemini does a good or reasonable job is in providing scripts that do conversion which I run rather than Gemini doing the conversion itself.
  * So in future, I could ask Gemini or some other Google AI tool to provide me a nodejs script or a powershell script  which will take a scan report file like `2026-03-02 17-40-20PostsInListSizeReport.txt` as input and generate the URL and Size pair CSV file which can then be easily imported into Excel or Google Sheets.
  * Another possibility is to modify postsize.ps1 to generate the output in a URL and Size pair CSV format suitable for direct import into Excel.
  * This time around as I have already gone through the cumbersome process described in above section and have got the final Excel spreadsheet that I wanted, I don't want to invest further time in this matter.

---

## Author and Acknowledgements

These scripts were developed by Ravi S. Iyer using assistance of Gemini in chat with title: `Blogger Feed Request Issue`
in late Feb / early Mar 2026.
