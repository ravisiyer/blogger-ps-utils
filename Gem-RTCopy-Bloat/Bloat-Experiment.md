# Gemini Rich Text Copy Bloat Experiment

Date: 27 to 28 April 2026

Gemini chat: Gemini Rich Text Bloat Experiment

## Summary 

This summary has been initially provided by Gemini and later edited by me.

## The "Fidelity Tax": Diagnosing HTML Bloat from Rich-Text Clipboard Serialization

### Background
When copying text from dynamic web interfaces (such as Gemini AI chat) directly into WYSIWYG editors like Blogger's Compose mode, the resulting HTML payload often suffers from severe bloat. A recent investigation was conducted to isolate the exact mechanism behind this bloat, specifically analyzing the impact of browser extensions like Dark Reader on the clipboard serialization process. But it seems clear that while Dark Reader surely does contribute to the bloat, Gemini rich text copy itself may be the primary cause of the bloat.

### The Experiment
To understand how data is transformed during the copy-paste action, a controlled comparison was performed on a single segment of text:

1. **The Clipboard Payload - [tmp.html](tmp.html) :** One of Gemini's responses was copied using the copy button provided by web Gemini below its response. This was done while the Dark Reader extension was On. The resulting HTML payload was 241 KB.
2. **The Raw DOM [Chrome-Inspect-Element.html](Chrome-Inspect-Element.html) :** The exact same Gemini response was extracted directly from the browser's Document Object Model (DOM) using Chrome Inspector and its Copy element feature. This raw HTML file was 10 KB.

Both files were then rendered locally using VS Code Live Server and compared visually in both dark and light modes:
- Dark mode: [Rendering-Comp-tmp-vs-Chrome-Inspect-Element.png](Rendering-Comp-tmp-vs-Chrome-Inspect-Element.png) 
- Light mode: [Light-Rendering-Comp-tmp-vs-Chrome-Inspect-Element.png](Light-Rendering-Comp-tmp-vs-Chrome-Inspect-Element.png)

*Note that tmp.html is on the left side and Chrome-Inspect-Element.html is on the right side. Also, the above pics have been slightly edited to obscure part of the browser toolbar.*

### Key Findings and Analysis

#### 1. The Clipboard "Fidelity Tax"
The massive size discrepancy (241 KB vs. 10 KB) is caused by the browser's rich-text copy mechanism. To ensure that the copied text looks identical regardless of where it is pasted (e.g., an email client, Word, or Blogger), the clipboard serializer captures the **Computed Styles** of the elements. 

Instead of copying clean semantic tags, the browser bakes every active CSS property—including fonts, margins, line heights, and syntax highlighting colours—directly into the HTML as inline `style="..."` attributes. This creates a completely self-sufficient, standalone visual document, but at the cost of a 24x multiplier in file size.

#### 2. The Impact of Accessibility Extensions
When an extension like Dark Reader is active during a rich-text copy, its dynamic visual overrides are permanently trapped in the clipboard payload. 
* The raw DOM (`Chrome-Inspect-Element.html`) remained semantically clean, proving that Dark Reader's dynamic engine utilizes a global stylesheet rather than injecting inline junk into the DOM tree.
* However, the clipboard payload (`tmp.html`) captured Dark Reader's variables (e.g., `--darkreader-inline-color`) and hardcoded RGB values, treating them as native formatting.

#### 3. The Light Mode Anomaly
Rendering the bloated `tmp.html` file with Dark Reader turned *off* revealed a fractured payload. Because the syntax highlighting and background colours were hardcoded as exact RGB values calculated for a dark background, viewing them against a default light background resulted in orphaned styling and poor visual contrast. It proved that the clipboard attempts to freeze a temporary, dynamic visual state into permanent HTML.

#### 4. General Rich-Text Bloat
The investigation confirmed that the bloat is not exclusively the fault of Dark Reader. Even if all extensions are deactivated, copying rich text from Gemini responses, especially those with syntax highlighting will still generate massive inline CSS to preserve the native code block colours and typography. 

### Conclusion and Best Practices
The primary engine of HTML post bloat is the rich-text clipboard serialization process. Pasting this payload into Blogger's Compose mode results in heavily bloated HTML due to computed inline CSS being added to the post which when saved will put all that bloat into Blogger server data for that post.

To maintain a lean, high-performance Blogger content database, the rich-text clipboard must be strictly bypassed. Extracting Gemini or other AI tools' responses as markdown and then using a dedicated **Markdown-to-HTML conversion pipeline** is a much better option.

