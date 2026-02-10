# Add collapsible accordion/details section

Add collapsible accordion/details section

## Usage

``` r
add_accordion(
  content,
  title,
  text,
  open = FALSE,
  tabgroup = NULL,
  show_when = NULL
)
```

## Arguments

- content:

  A content_collection or viz_collection object

- title:

  Section title

- text:

  Section content

- open:

  Whether section starts open (default: FALSE)

- tabgroup:

  Optional tabgroup for organizing content (character vector for nested
  tabs)

- show_when:

  One-sided formula controlling conditional display based on input
  values.

## Value

Updated content_collection
