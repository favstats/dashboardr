# Start a manual layout column

Creates a column container for explicit Quarto dashboard layout control.
Use with
[`add_layout_row()`](https://favstats.github.io/dashboardr/reference/add_layout_row.md)
and
[`end_layout_column()`](https://favstats.github.io/dashboardr/reference/end_layout_column.md).

## Usage

``` r
add_layout_column(
  content,
  width = NULL,
  class = NULL,
  tabgroup = NULL,
  show_when = NULL
)
```

## Arguments

- content:

  A content_collection or page_object.

- width:

  Optional Quarto column width value.

- class:

  Optional CSS class for the column.

- tabgroup:

  Optional tabgroup metadata (reserved for future use).

- show_when:

  Optional one-sided formula controlling visibility.

## Value

A layout_column_container for piping.

## Examples

``` r
if (FALSE) { # \dontrun{
content <- create_content() %>%
  add_layout_column(width = 60) %>%
  add_layout_row() %>%
    add_text("### Row content") %>%
  end_layout_row() %>%
end_layout_column()
} # }
```
