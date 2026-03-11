# Subset Blog Post Audit: Feb 28 to Mar 11, 2026

This folder serves as a technical demonstration of using the utility scripts to perform a targeted "subset audit" of a live blog. Instead of scanning the entire blog, this process focuses on a specific date range to verify that recent posts remain within healthy size thresholds.

## Process Overview

The audit was conducted on March 11, 2026, covering 9 posts published between February 28, 2026, and March 8, 2026. The previous audit for the full blog was based on full list of posts in blog generated on March 1, 2026. 

The working folder for this audit was the NotInGit folder at project root. Later all the related files in NotInGit folder were copied to `20260228-20260311-Posts-Size-Data` folder.

### 1. Data Extraction

The list of posts was generated using the [Blogger All Post Titles Lister](https://ravisiyer.github.io/BloggerAllPostsLister/?blog=https://raviswdev.blogspot.com/) web app. A subset of the resulting list was copied as HTML [using the copyashtml Chrome Bookmarklet](https://github.com/ravisiyer/bookmarklets/blob/main/stable-bml/copyashtml/README.md) and saved to [20260228-20260311-PostsList.html](./20260228-20260311-PostsList.html).

### 2. URL Simplification

The HTML file was processed to extract a clean list of URLs:

> ..\SimplifyBlogPostsList.ps1 -InputFile .\20260228-20260311-PostsList.html 

**Result**: 9 URLs successfully extracted and written to default OutputFile: `CleanUrlsList.txt`.

### 3. Size Measurement (Full Post Size)

The batch script was executed to measure the full post size including Blogger theme, of each post:

> ..\postsInListSize.ps1 -UrlListFile CleanUrlsList.txt -ScriptToRun "../postsize.ps1" -All | Tee-Object -FilePath "20260228-20260311-PostsSizeReport.txt"

**Key Finding**: All posts were safely under 200 KB. The largest post was **196.92 KB**, and the smallest was **111.11 KB**.

### 4. Pure Post Content Scrape

A secondary scan was performed to isolate the author-generated HTML content from the Blogger theme overhead:

> ..\postsInListSize.ps1 -UrlListFile CleanUrlsList.txt -ScriptToRun "../scrapePurePostSize.ps1" -All | Tee-Object -FilePath "20260228-20260311-PurePostsSizeReport.txt"

The scrapePurePostSize.ps1 reported HTML size is typically almost the same, if not the same, as the HTML shown in Blogger Dashboard 'Edit HTML' mode for the post, which is being referred to as author-generated HTML content.

**Key Finding**: Pure post content ranged from **0.94 KB** to **70.16 KB**, confirming that recent technical posts (including Gemini/ChatGPT chat transfers) are not introducing significant CSS bloat.

### 5. CSV Transformation

Finally, the text log was converted to a CSV format for Excel analysis:

> ..\PostsSizeListReportToCSV.ps1 -InputFile 20260228-20260311-PostsSizeReport.txt -OutputFile 20260228-20260311-PostsSizeReport.csv

The above csv file could be opened in Excel and the data could be easily sorted in descending order of size. 

## Conclusion

This subset audit shows that the modular script architecture allows for rapid health checks of small lists of posts of a blog. 

---

### Folder Contents

* [20260228-20260311-PostsList.html](./20260228-20260311-PostsList.html): Original HTML source from the Lister app.
* [CleanUrlsList.txt](./CleanUrlsList.txt): The processed list of URLs used as input for batch scripts.
* [20260228-20260311-PostsSizeReport.txt](./20260228-20260311-PostsSizeReport.txt): The standard size report log.
* [20260228-20260311-PurePostsSizeReport.txt](./20260228-20260311-PurePostsSizeReport.txt): The "Pure" content size report log.
* `20260228-20260311-PostsSizeReport.csv`: The final structured data for Excel.