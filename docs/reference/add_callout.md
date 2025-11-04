# Add callout box

Add callout box

## Usage

``` r
add_callout(
  content,
  text,
  type = c("note", "tip", "warning", "caution", "important"),
  title = NULL,
  icon = NULL,
  collapse = FALSE
)
```

## Arguments

- content:

  A content_collection object

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

## Value

Updated content_collection
