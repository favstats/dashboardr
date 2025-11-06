# Create text content from a character vector

Alternative helper for creating text content from existing character
vectors.

## Usage

``` r
text_lines(lines)
```

## Arguments

- lines:

  Character vector of text lines

## Value

Single character string with proper line breaks

## Examples

``` r
if (FALSE) { # \dontrun{
lines <- c("# Title", "", "Content here")
text_content <- text_lines(lines)
add_page("Page", text = text_content)
} # }
```
