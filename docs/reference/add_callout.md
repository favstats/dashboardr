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
  tabgroup = NULL,
  show_when = NULL
)
```

## Arguments

- x:

  A content_collection, viz_collection, sidebar_container, or
  page_object

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

- show_when:

  One-sided formula controlling conditional display based on input
  values.

## Value

Updated content_collection
