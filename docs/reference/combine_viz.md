# Combine visualization collections

This function has been superseded by
[`combine_content()`](https://favstats.github.io/dashboardr/reference/combine_content.md).
It still works but we recommend using
[`combine_content()`](https://favstats.github.io/dashboardr/reference/combine_content.md)
for new code as it handles all content types and attributes more
reliably.

## Usage

``` r
combine_viz(...)
```

## Arguments

- ...:

  One or more viz_collection objects to combine

## Value

A combined viz_collection

## Examples

``` r
if (FALSE) { # \dontrun{
viz1 <- create_viz() %>% add_viz(type = "histogram", x_var = "age")
viz2 <- create_viz() %>% add_viz(type = "histogram", x_var = "income")
combined <- combine_viz(viz1, viz2)  # Combines both
} # }
```
