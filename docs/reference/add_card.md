# Add card

Add card

## Usage

``` r
add_card(
  content,
  text,
  title = NULL,
  footer = NULL,
  tabgroup = NULL,
  show_when = NULL
)
```

## Arguments

- content:

  A content_collection or viz_collection object

- text:

  Card content

- title:

  Card title

- footer:

  Optional card footer

- tabgroup:

  Optional tabgroup for organizing content (character vector for nested
  tabs)

- show_when:

  One-sided formula controlling conditional display based on input
  values.

## Value

Updated content_collection
