# Text & Content

# Text & Content

View Full Page Code

``` r
# === TEXT & CONTENT PAGE ===
# This page demonstrates markdown formatting and content blocks

# Create content with text and accordions
text_content <- create_content() %>%
  add_text(md_text(
    "This page demonstrates text formatting and content blocks.",
    "",
    "You can use **bold text** for emphasis, *italics* for subtle highlighting,",
    "and `inline code` for technical terms like `add_viz()`.",
    "",
    "Combine styles: ***bold and italic*** or **`bold code`**.",
    "Add [hyperlinks](https://dashboardr.dev) to external resources.",
    "",
    "Lists work too:",
    "",
    "- First item with **bold**",
    "- Second item with *italics*",
    "- Third item with `code`"
  )) %>%
  add_accordion(
    title = "What is an accordion?",
    text = "An **accordion** is a collapsible content block. Users click to
           expand and reveal hidden content. Great for FAQs or code examples."
  ) %>%
  add_accordion(
    title = "Pro tip: Nested content",
    text = md_text(
      "Inside accordions, you can include:",
      "",
      "- Markdown formatting like **bold** and *italics*",
      "- Code blocks for examples",
      "- Links to documentation"
    )
  ) %>%
  add_text("Text-only pages are useful for documentation or methodology notes.")

# Create page and add content
text_page <- create_page(name = "Text & Content", icon = "ph:chalkboard-simple-bold") %>%
  add_content(text_content)
```

This page demonstrates text formatting and content blocks available in
dashboardr.

You can use **bold text** for emphasis, *italics* for subtle
highlighting, and `inline code` for technical terms or function names
like `add_viz()`.

Combine styles: ***bold and italic*** or **`bold code`**. Add
[hyperlinks](https://dashboardr.dev) to external resources.

Lists work too:

- First item with **bold**
- Second item with *italics*
- Third item with `code`

What is an accordion?

An **accordion** is a collapsible content block. Users click to expand
and reveal hidden content. Great for FAQs, code examples, or additional
details that might clutter the main page.

Pro tip: Nested content

Inside accordions, you can include:

- Markdown formatting like **bold** and *italics*
- Code blocks for examples
- Links to documentation

This keeps your dashboard clean while providing depth for curious users.

------------------------------------------------------------------------

Text-only pages are useful for documentation, methodology notes, data
sources, or any context that helps users understand your visualizations.

Back to top
