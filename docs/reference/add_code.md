# Add code block

Add code block

## Usage

``` r
add_code(
  content,
  code,
  language = "r",
  caption = NULL,
  filename = NULL,
  tabgroup = NULL,
  show_when = NULL
)
```

## Arguments

- content:

  A content_collection, viz_collection, or page_object

- code:

  Code content

- language:

  Programming language for syntax highlighting

- caption:

  Optional caption

- filename:

  Optional filename to display

- tabgroup:

  Optional tabgroup for organizing content (character vector for nested
  tabs)

- show_when:

  One-sided formula controlling conditional display based on input
  values.

## Value

Updated object (same type as input)
