# Set or update tabgroup display labels

Updates the display labels for tab groups in a visualization collection.
Useful when you want to change the section headers after creating the
collection.

## Usage

``` r
set_tabgroup_labels(viz_collection, labels = NULL, ...)
```

## Arguments

- viz_collection:

  A viz_collection object

- labels:

  Named character vector or list mapping tabgroup IDs to labels
  (deprecated, use ... instead)

- ...:

  Named arguments where names are tabgroup IDs and values are display
  labels

## Value

The updated viz_collection

## Examples

``` r
if (FALSE) { # \dontrun{
# New style: direct key-value pairs (recommended)
vizzes <- create_viz() %>%
  add_viz(type = "heatmap", tabgroup = "demo") %>%
  set_tabgroup_labels(demo = "Demographic Breakdowns", age = "Age Groups")

# Old style: still supported for backwards compatibility
vizzes <- create_viz() %>%
  add_viz(type = "heatmap", tabgroup = "demo") %>%
  set_tabgroup_labels(list(demo = "Demographic Breakdowns"))
} # }
```
