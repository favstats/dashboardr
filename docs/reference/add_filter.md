# Add a filter control (simplified interface)

A convenience wrapper around
[`add_input`](https://favstats.github.io/dashboardr/reference/add_input.md)
for common filtering use cases. Options are automatically derived from
the data column specified by `filter_var`. All values are selected by
default.

## Usage

``` r
add_filter(
  content,
  filter_var,
  label = NULL,
  type = c("checkbox", "select", "radio"),
  ...
)
```

## Arguments

- content:

  A content_collection object

- filter_var:

  The column name in your data to filter by (quoted or unquoted)

- label:

  Optional label for the filter (defaults to the column name)

- type:

  Filter type: "checkbox" (default), "select", or "radio"

- ...:

  Additional arguments passed to
  [`add_input`](https://favstats.github.io/dashboardr/reference/add_input.md)

## Value

Updated content_collection

## Examples

``` r
if (FALSE) { # \dontrun{
# Simplest usage - just specify the column!
content <- create_content(data = mydata) %>%
  add_sidebar() %>%
    add_filter(filter_var = "education") %>%
    add_filter(filter_var = "gender") %>%
  end_sidebar() %>%
  add_viz(type = "stackedbar", x_var = "region", stack_var = "outcome")
} # }
```
