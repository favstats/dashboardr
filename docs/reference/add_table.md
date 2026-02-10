# Add generic table (data frame)

Add generic table (data frame)

## Usage

``` r
add_table(
  content,
  table_object,
  caption = NULL,
  tabgroup = NULL,
  filter_vars = NULL,
  show_when = NULL
)
```

## Arguments

- content:

  A content_collection object

- table_object:

  A data frame or tibble

- caption:

  Optional caption

- tabgroup:

  Optional tabgroup for organizing content (character vector for nested
  tabs)

- filter_vars:

  Optional character vector of input filter variables to apply to this
  block.

- show_when:

  One-sided formula controlling conditional display based on input
  values.

## Value

Updated content_collection
