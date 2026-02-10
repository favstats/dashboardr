# Add text to content collection (pipeable)

Adds a text block to a content collection. Can be used standalone or in
a pipe. Supports viz_collection as first argument for seamless piping.

## Usage

``` r
add_text(x = NULL, text, ..., tabgroup = NULL, show_when = NULL)
```

## Arguments

- x:

  A content_collection, viz_collection, sidebar_container, page_object,
  or NULL

- text:

  Markdown text content (can be multi-line)

- ...:

  Additional text lines (will be combined with newlines)

- tabgroup:

  Optional tabgroup for organizing content (character vector for nested
  tabs)

- show_when:

  One-sided formula controlling conditional display based on input
  values.

## Value

Updated content_collection object

## Examples

``` r
if (FALSE) { # \dontrun{
# Standalone
text_block <- add_text("# Welcome")

# Pipe with content
content <- create_content() %>%
  add_text("## Introduction")

# With tabgroup
content <- create_content() %>%
  add_text("## Section 1", tabgroup = "Overview")

# Pipe directly from viz
content <- create_viz() %>%
  add_viz(type = "histogram", x_var = "age") %>%
  add_text("Analysis complete")
} # }
```
