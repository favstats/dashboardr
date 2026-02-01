# Add callout box

Add callout box

## Usage

``` r
add_callout(
  x,
  text,
  type = c("note", "tip", "warning", "caution", "important"),
  title = NULL,
  icon = NULL,
  collapse = FALSE,
  tabgroup = NULL
)
```

## Arguments

- text:

  Callout content

- type:

  Callout type (note/tip/warning/caution/important)

- title:

  Optional title

- icon:

  Optional icon

- collapse:

  Whether callout is collapsible

- tabgroup:

  Optional tabgroup for organizing content (character vector for nested
  tabs)

- content:

  A content_collection or viz_collection object

## Value

Updated content_collection
