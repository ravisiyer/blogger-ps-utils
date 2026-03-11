# Blogger Blog Post Size Utility Scripts

These utility PowerShell scripts are designed to help measure the payload size of individual Blogger posts 
and to automate the process of getting size data for multiple posts of a blog. The main use case is to 
identify posts that may have excessive content (such as unnecessary CSS) that could lead to performance 
issues in Blogger feeds and Blogger Compose Post editing interface. Once identified, attempts can be made to remove unnecessary CSS from such posts by using HTML cleaning utilities like [prettyhtml.com](https://prettyhtml.com).

The main size related scripts are:
1. [postsize.ps1](#postsizeps1): Measures the full post size including Blogger theme, of a single Blogger post given its URL.
2. [postsInListSize.ps1](#postsinlistsizeps1): Parses a text file containing a list of Blogger post URLs and invokes a specified script (`postsize.ps1` by default) for each URL to generate a comprehensive report of sizes for all posts in the list.
3. [SimplifyBlogPostsList.ps1](#SimplifyBlogPostsList.ps1): Extracts blog post URLs from an HTML file by searching for href attributes and produces output text file with one URL per line. The latter file can be used as input to `postsInListSize.ps1`. 
4. [PostsSizeListReportToCSV.ps1](./PostsSizeListReportToCSV.ps1): Transforms the output file of `postsInListSize.ps1` into a CSV format suitable for Excel.

The section [Commands Sequence to Get Size Data of List of Posts](#commands-sequence-to-get-size-data-of-list-of-posts) shows how to combine above scripts to get size data for a list of posts of a blog. The related section [Example: Subset Blog Post Audit](#example-subset-blog-post-audit) covers a practical demonstration of the commands sequence to audit a subset of a live blog.

A separate document [checkPostBloat.md](./checkPostBloat.md) covers [checkPostBloat.ps1](./checkPostBloat.ps1) script which detects ChatGPT and Dark Reader CSS bloat. This was intially using a live blog post URL but that had some issues due to which it now uses a file which the user has to create by copying Edit HTML contents of post in Blogger Dashboard. However, this script is not very accurate. The clear idea of post bloat comes from the extent to which [prettyhtml.com](https://prettyhtml.com) cleaner is able to reduce the HTML size.

Related blog post: [Fixing Gemini/ChatGPT chat to Blogger Compose post copy-paste causing upto 1.5 MB post size bloat due to unnecessary CSS](https://raviswdev.blogspot.com/2026/03/fixing-gemini-chat-to-blogger-compose.html).  The `Summary` section at the top of the post gives a top-level view of the problem and gives the steps in the `sanitization` (cleaning) process.

The [checkPostBloat.md](./checkPostBloat.md) document also covers few additional scripts developed later on:
- [savepostasfile.ps1](./savepostasfile.ps1): Downloads a Blogger post using same approach used by postsize.ps1 of Invoke-WebRequest and saves it as a local file. This is useful to check the actual content returned by Invoke-WebRequest for a post URL when we want. Note that postsize.ps1 only reports the size and does not save the content. 
- [scrapePurePostSize.ps1](./scrapePurePostSize.ps1): Measures the byte size of "pure" blog post HTML content using scrape-blogger-post.ps1 with -f pure option.

The [checkPostBloat.md](./checkPostBloat.md) document is also a detailed log of exchanges with Gemini on analysis and checking of Blogger post bloat due to unwanted CSS and tag attributes, followed by my work on checking post bloat for my main sw dev blog and reducing it when the bloat had crossed a threshold. This log includes prompts I gave to Gemini and related exchanges with Gemini, to modify some scripts and to create some scripts.

[GColab/prompts.md](GColab/prompts.md) covers the prompts I gave to Google Colab AI related to extracting pre elements from original post HTML (post-orig.html), cleaning them up and then trying to auto-patch them back into PrettyHTML bloat cleanup output file (post-pretty.html). It also has some Gemini exchanges related to the Colab session. 

---

## postsize.ps1

[This script](./postsize.ps1) downloads a Blogger post and measures its payload size. It is useful for identifying posts 
that may have unnecessary CSS (for example, due to copy-pasting rich text from Gemini chat) or other 
similar content that may increase the post size to above 500 KB which may cause performance issues for 
blog feed requests and slow UI responses for blog post editing in Blogger Compose. 

After developing another script [checkPostBloat.ps1](./checkPostBloat.ps1), we learned after some usage of it that Invoke-WebRequest seems to get filtered by Blogger server content. postsize.ps1 also uses Invoke-WebRequest to get the post content. So it is possible that postsize.ps1 may also be getting filtered content and thus may be under-reporting the actual post size. To get the actual user-created/user-edited post size, the best measure is a count of Edit HTML content in Blogger Dashboard. postsize.ps1 perhaps is still useful for getting a relative measure of post size across posts and to identify the larger posts which are more likely to have bloat. 

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

[This script](./postsInListSize.ps1) automates the measurement of size of multiple blog posts by parsing a text file containing a list of Blogger post URLs and invokes a specified script (`postsize.ps1` by default) for each URL to generate a comprehensive report of sizes for all posts in the list. This report can be used to identify posts that may have excessive content and are candidates for optimization.

This script was changed in a big way on 10 Mar 2026 to get split into two scripts: [SimplifyBlogPostsList.ps1](#SimplifyBlogPostsList.ps1) and this script with more focused functionality.

Many of the data files currently (as of 10 Mar 2026) in the project were created by earlier version of the script. Please refer to older version of this Readme for documentation related to them.

### Parameters

* **`-UrlListFile`**: The file with list of URLs (Default: `CleanUrlsList.txt`).
* **`-ScriptToRun`**: The script to run for each URL, passing the URL as a parameter (Default: `postsize.ps1`).
* **`-All`**: A switch to scan the entire list. Without this, the script performs a first 10-posts "Test Run".

### Example Usage

#### 1. Standard Scan 

To run a full scan of the default blog and save the output:

```powershell
.\postsInListSize.ps1 -All | Tee-Object -FilePath "FullBlogScan.txt"
```

#### 2. Test Run (First 10 Posts)

Quickly verify connectivity and formatting without a full scan:

```powershell
.\postsInListSize.ps1
```

---

## SimplifyBlogPostsList.ps1

Extracts blog post URLs from an HTML file by searching for href attributes and produces output text file with one URL per line. This is useful for creating the input file for `postsInListSize.ps1` from the HTML list of posts file generated by my [BloggerAllPostsLister web app](https://ravisiyer.github.io/BloggerAllPostsLister/?blog=https://raviswdev.blogspot.com/). It is a generic script that looks only for href attributes and thus can be used for extracting URLs from any HTML file, not just the Blogger posts list HTML file. But the href attribute has to be provided in a single line.

### Example Usage

> `./SimplifyBlogPostsList.ps1` -InputFile `PostsList.html` -OutputFile `CleanUrlsList.txt` -BlogBaseUrl `https://raviswdev.blogspot.com`

## Commands Sequence to Get Size Data of List of Posts

1. Create input text file having list of blog post URLs.
   - For a full blog, [BloggerAllPostsLister web app](https://ravisiyer.github.io/BloggerAllPostsLister/?blog=https://raviswdev.blogspot.com/) output file can be provided as input to `SimplifyBlogPostsList.ps1` to produce the needed input text file with list of URLs.
   - For an arbitrary list of posts in a blog, you simply need to create a text file with that list of URLs.
2. Run `postsInListSize.ps1` with above list of blog post URLs text file as input. Note that it will invoke `postsize.ps1` by default for each URL in the input file.
   - Example command: `.\postsInListSize.ps1 -UrlListFile SwDevBlogURLs.txt -All | Tee-Object -FilePath "SwDevBlogSizeReport.txt"`
3. Run `PostsSizeListReportToCSV.ps1` to transform the output file of `postsInListSize.ps1` into a CSV format suitable for Excel.  
   - Example command: `./PostsSizeListReportToCSV.ps1 -InputFile SwDevBlogSizeReport.txt -OutputFile SwDevBlogSizeReport.csv`
4. `SwDevBlogSizeReport.csv` can be imported into an Excel workbook `SwDevBlogSizeReport.xlsx`. A copy can be made of the sheet so that you have a 'Raw Data' worksheet and a 'Sorted Data' worksheet with the latter having the rows in descending order of Size column value.    

## Example: Subset Blog Post Audit

A practical demonstration of the commands sequence to audit a subset of a live blog is available in the **[20260228-20260311-Posts-Size-Data](./20260228-20260311-Posts-Size-Data/)** folder which has a [README document](./20260228-20260311-Posts-Size-Data/Readme.md). This example documents a rapid health check performed on a small subset of 9 recent blog posts. 

It illustrates the end-to-end process:
   - From [using the copyashtml Chrome Bookmarklet](https://github.com/ravisiyer/bookmarklets/blob/main/stable-bml/copyashtml/README.md) to copy (as HTML) required part of the list of all posts in blog shown by [BloggerAllPostsLister web app](https://ravisiyer.github.io/BloggerAllPostsLister/?blog=https://raviswdev.blogspot.com/)
   - To the generation of both "Full Post" and "Pure Post" size reports and final CSV transformation.

---

## Author and Acknowledgements

These scripts were developed by Ravi S. Iyer using assistance of Gemini in few Gemini chats in late Feb / early Mar 2026.

---

---

# Older versions related

The sections below may still have useful information on how some of the data files in the project were created and also about the initial analysis of the scan data.

The section [Scan Data Processing and Payload Analysis](#scan-data-processing-and-payload-analysis) details the steps taken to transform the comprehensive report (raw scan output) of postsInListSize.ps1 for one particular Blogger blog into an Excel workbook with one sheet having sorted list of posts in descending order of post size. But these steps were quite cumbersome and time-consuming.

The section [Simpler Alternatives to Create Excel Spreadsheet from Raw Scan Output](#simpler-alternatives-to-create-excel-spreadsheet-from-raw-scan-output) gives some suggestion(s) for doing the above task in a simpler way.

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
* By running a separate [scrape-blogger-post](https://github.com/ravisiyer/scrape-blogger-post) utility on that post, it was determined the actual user-created post content in Blogger was only **1.82 KB** (size on disk for output file is 4 KB). *[8 Mar 2026 Update: We learned that PowerShell Invoke-WebRequest seems to get content which is filtered by Blogger server. scrape-blogger-post utility may also be getting similar filtered content. To get the actual user-created/user-edited post size, the best measure is a count of Edit HTML content in Blogger Dashboard.]*
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

The [Get-XlsxBlobStorage.ps1](./Get-XlsxBlobStorage.ps1) script helps to understand how much space Excel files were consuming across repository history. The background for this script is covered in my blog post [Git is not suitable for managing versions of Excel and Word files](https://raviswdev.blogspot.com/2026/03/git-is-not-suitable-for-managing.html). This Get-XlsxBlobStorage.ps1 script is not expected to be used further for this project's work but is being retained just in case it is useful for some other project or perhaps for this project itself in future.
