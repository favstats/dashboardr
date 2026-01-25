# Start an input row

Creates a container for input widgets that will be displayed in a
horizontal row. The inputs will wrap responsively on smaller screens.
Use with end_input_row().

## Usage

``` r
add_input_row(
  content,
  tabgroup = NULL,
  style = c("boxed", "inline"),
  align = c("center", "left", "right")
)
```

## Arguments

- content:

  Content collection object

- tabgroup:

  Optional tabgroup for organizing content. Use this to place the input
  row inside a specific tab (e.g., "trends" or "trends/Female
  Authorship")

- style:

  Visual style: "boxed" (default, with background and border) or
  "inline" (compact, transparent background)

- align:

  Alignment: "center" (default), "left", or "right"

## Value

An input_row_container for piping

## Examples

``` r
if (FALSE) { # \dontrun{
content <- create_content() %>%
  add_input_row() %>%
    add_input(input_id = "country", filter_var = "country", options_from = "country") %>%
    add_input(input_id = "metric", filter_var = "metric", options_from = "metric") %>%
  end_input_row()

# Place inputs inside a tabgroup
content <- create_content() %>%
  add_input_row(tabgroup = "trends", style = "inline") %>%
    add_input(input_id = "country", filter_var = "country", options = c("A", "B")) %>%
  end_input_row()
} # }
```
