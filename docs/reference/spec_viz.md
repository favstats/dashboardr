# Create a single visualization specification

Helper function to create individual viz specs that can be combined into
a list or used directly in add_page().

## Usage

``` r
spec_viz(type, ..., tabgroup = NULL, title = NULL)
```

## Arguments

- type:

  Visualization type

- ...:

  Additional parameters

- tabgroup:

  Optional group ID

- title:

  Display title

## Value

A list containing the visualization specification

## Examples

``` r
if (FALSE) { # \dontrun{
viz1 <- spec_viz(type = "heatmap", x_var = "party", y_var = "ideology")
viz2 <- spec_viz(type = "histogram", x_var = "age")
page_viz <- list(viz1, viz2)
} # }
```
