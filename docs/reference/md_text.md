# Create multi-line markdown text content

Helper function to create readable multi-line markdown text content for
pages. Automatically handles line breaks and formatting for better
readability.

## Usage

``` r
md_text(...)
```

## Arguments

- ...:

  Text content as separate arguments or character vectors

## Value

Single character string with proper line breaks

## Examples

``` r
if (FALSE) { # \dontrun{
# Method 1: Separate arguments
text_content <- md_text(
  "# Welcome",
  "",
  "This is a multi-line text block.",
  "",
  "## Features",
  "- Feature 1",
  "- Feature 2"
)

# Method 2: Character vectors
lines <- c("# About", "", "This is about our study.")
text_content <- md_text(lines)

# Use in add_page
add_page("About", text = text_content)
} # }
```
