# Combine visualization collections

Alternative function to combine viz_collection objects. Use this if the
`+` operator doesn't work (e.g., with devtools::load_all()).

## Usage

``` r
combine_viz(...)
```

## Arguments

- ...:

  One or more viz_collection objects to combine

## Value

A combined viz_collection

A combined viz_collection

## Examples

``` r
if (FALSE) { # \dontrun{
viz1 <- create_viz() %>% add_viz(type = "histogram", x_var = "age")
viz2 <- create_viz() %>% add_viz(type = "histogram", x_var = "income")
combined <- combine_viz(viz1, viz2)  # Combines both
} # }
```
