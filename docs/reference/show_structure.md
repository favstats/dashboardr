# Show collection structure (even with data attached)

Forces display of the collection structure instead of rendering
visualizations. Useful when you want to inspect the structure of a
collection that has data attached, or when documenting the collection's
organization.

## Usage

``` r
show_structure(x)
```

## Arguments

- x:

  A content_collection or viz_collection object

## Value

In knitr: formatted HTML output. In console: invisible(x) after
printing.

## Examples

``` r
if (FALSE) { # \dontrun{
# In a vignette or R Markdown, pipe into print() to see the tree
# even when data is attached:
create_viz(data = mtcars, type = "bar") %>%
  add_viz(x_var = "cyl", title = "Cylinders") %>%
  print()
} # }
```
