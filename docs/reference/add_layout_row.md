# Start a manual layout row inside a layout column

Start a manual layout row inside a layout column

## Usage

``` r
add_layout_row(
  column_container,
  class = NULL,
  tabgroup = NULL,
  show_when = NULL
)
```

## Arguments

- column_container:

  A layout_column_container created by
  [`add_layout_column()`](https://favstats.github.io/dashboardr/reference/add_layout_column.md).

- class:

  Optional CSS class for the row.

- tabgroup:

  Optional tabgroup metadata (reserved for future use).

- show_when:

  Optional one-sided formula controlling visibility.

## Value

A layout_row_container for piping.
