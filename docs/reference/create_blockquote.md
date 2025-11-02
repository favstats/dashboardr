# Create a Styled Blockquote

Creates a custom-styled blockquote with customizable colors, borders,
and styling. Useful for highlighting questions, quotes, or important
text in dashboards.

## Usage

``` r
create_blockquote(
  text,
  preset = NULL,
  class_name = "custom-blockquote",
  font_size = "1em",
  text_color = "#333",
  border_width = "5px",
  border_color = "#0056b3",
  background_color = "#f0f8ff",
  padding = "10px 20px",
  margin = "20px 0",
  line_height = "1.6",
  return_css = FALSE,
  use_class = FALSE
)
```

## Arguments

- text:

  Character string. The text content to display in the blockquote.

- preset:

  Either a character string for built-in presets ("question", "info",
  "warning", "success", "error", "note") OR a named list with custom
  styling parameters (e.g., list(border_color = "#0056b3",
  background_color = "#e3f2fd")). Default is NULL (uses default
  styling).

- class_name:

  Character string. CSS class name for the blockquote. Default is
  "custom-blockquote".

- font_size:

  Character string. Font size (e.g., "1em", "16px"). Default is "1em".

- text_color:

  Character string. Text color (hex, rgb, or named color). Default is
  "#333".

- border_width:

  Character string. Left border width (e.g., "5px", "3px"). Default is
  "5px".

- border_color:

  Character string. Left border color. Default is "#0056b3".

- background_color:

  Character string. Background color. Default is "#f0f8ff".

- padding:

  Character string. Padding inside the blockquote. Default is "10px
  20px".

- margin:

  Character string. Margin around the blockquote. Default is "20px 0".

- line_height:

  Character string. Line height for text. Default is "1.6".

- return_css:

  Logical. If TRUE, returns only the CSS. If FALSE (default), returns
  HTML with inline CSS.

- use_class:

  Logical. If TRUE, returns HTML with class reference and separate CSS
  block. If FALSE (default), uses inline styles.

## Value

If `use_class = FALSE`: HTML blockquote with inline styles. If
`use_class = TRUE`: List with `html` and `css` elements. If
`return_css = TRUE`: Only the CSS string.

## Examples

``` r
# Basic usage with defaults
create_blockquote("This is an important question about data quality.")
#> <blockquote style="font-size: 1em; color: #333; border-left: 5px solid #0056b3; background-color: #f0f8ff; padding: 10px 20px; margin: 20px 0; line-height: 1.6; position: relative;">
#> This is an important question about data quality.
#> </blockquote>

# Using built-in presets (as strings)
create_blockquote("How do you rate our service?", preset = "question")
#> <blockquote style="font-size: 1em; color: #333; border-left: 5px solid #0056b3; background-color: #f0f8ff; padding: 10px 20px; margin: 20px 0; line-height: 1.6; position: relative;">
#> How do you rate our service?
#> </blockquote>
create_blockquote("Please check your input.", preset = "warning")
#> <blockquote style="font-size: 1em; color: #856404; border-left: 5px solid #ffc107; background-color: #fff3cd; padding: 10px 20px; margin: 20px 0; line-height: 1.6; position: relative;">
#> Please check your input.
#> </blockquote>
create_blockquote("Operation completed!", preset = "success")
#> <blockquote style="font-size: 1em; color: #155724; border-left: 5px solid #28a745; background-color: #d4edda; padding: 10px 20px; margin: 20px 0; line-height: 1.6; position: relative;">
#> Operation completed!
#> </blockquote>

# Using custom presets (as lists) - pass directly!
algosoc_style <- list(
  border_color = "#0056b3",
  background_color = "#e3f2fd",
  text_color = "#1565c0"
)
create_blockquote("AlgoSoc question here", preset = algosoc_style)
#> <blockquote style="font-size: 1em; color: #1565c0; border-left: 5px solid #0056b3; background-color: #e3f2fd; padding: 10px 20px; margin: 20px 0; line-height: 1.6; position: relative;">
#> AlgoSoc question here
#> </blockquote>

# Define multiple custom styles and reuse
survey_style <- list(border_color = "#6f42c1", background_color = "#f8f5ff")
important_style <- list(border_color = "#e74c3c", background_color = "#ffebee", border_width = "8px")

create_blockquote("Survey question 1", preset = survey_style)
#> <blockquote style="font-size: 1em; color: #333; border-left: 5px solid #6f42c1; background-color: #f8f5ff; padding: 10px 20px; margin: 20px 0; line-height: 1.6; position: relative;">
#> Survey question 1
#> </blockquote>
create_blockquote("Survey question 2", preset = survey_style)
#> <blockquote style="font-size: 1em; color: #333; border-left: 5px solid #6f42c1; background-color: #f8f5ff; padding: 10px 20px; margin: 20px 0; line-height: 1.6; position: relative;">
#> Survey question 2
#> </blockquote>
create_blockquote("IMPORTANT!", preset = important_style)
#> <blockquote style="font-size: 1em; color: #333; border-left: 8px solid #e74c3c; background-color: #ffebee; padding: 10px 20px; margin: 20px 0; line-height: 1.6; position: relative;">
#> IMPORTANT!
#> </blockquote>

# Custom styling (overriding preset)
create_blockquote(
  "Warning: Please review the data before proceeding.",
  preset = "warning",
  border_width = "8px",  # Override preset border width
  font_size = "1.2em"     # Override preset font size
)
#> <blockquote style="font-size: 1.2em; color: #856404; border-left: 8px solid #ffc107; background-color: #fff3cd; padding: 10px 20px; margin: 20px 0; line-height: 1.6; position: relative;">
#> Warning: Please review the data before proceeding.
#> </blockquote>

# Fully custom (no preset)
create_blockquote(
  "How satisfied are you with our service?",
  border_color = "#6f42c1",
  background_color = "#f8f5ff",
  font_size = "1.1em",
  padding = "15px 25px"
)
#> <blockquote style="font-size: 1.1em; color: #333; border-left: 5px solid #6f42c1; background-color: #f8f5ff; padding: 15px 25px; margin: 20px 0; line-height: 1.6; position: relative;">
#> How satisfied are you with our service?
#> </blockquote>

# Using class-based approach (for multiple blockquotes)
result <- create_blockquote(
  "Question 1: What is your opinion?",
  preset = "question",
  use_class = TRUE
)
# Add the CSS to your document header
cat(result$css)
#> Error in cat(result$css): argument 1 (type 'list') cannot be handled by 'cat'
# Use the HTML in your content
cat(result$html)
#> <blockquote class="question-text">
#> Question 1: What is your opinion?
#> </blockquote>
```
