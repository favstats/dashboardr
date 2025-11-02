# Create a new visualization collection

Initializes an empty collection for building up multiple visualizations
using the piping workflow. Optionally accepts custom display labels for
tab groups and default parameters that apply to all visualizations.

## Usage

``` r
create_viz(tabgroup_labels = NULL, ...)
```

## Arguments

- tabgroup_labels:

  Named vector/list mapping tabgroup IDs to display names

- ...:

  Default parameters to apply to all subsequent add_viz() calls. Any
  parameter specified in add_viz() will override the default. Useful for
  setting common parameters like type, color_palette, stacked_type, etc.

## Value

A viz_collection object

## Examples

``` r
if (FALSE) { # \dontrun{
# Create viz collection with custom group labels
vizzes <- create_viz(tabgroup_labels = c("demo" = "Demographics",
                                          "pol" = "Political Views"))
                                          
# Create viz collection with shared defaults
vizzes <- create_viz(
  type = "stackedbars",
  stacked_type = "percent",
  color_palette = c("#d7191c", "#fdae61", "#2b83ba"),
  horizontal = TRUE,
  x_label = ""
) %>%
  add_viz(title = "Wave 1", filter = ~ wave == 1) %>%  # Uses defaults
  add_viz(title = "Wave 2", filter = ~ wave == 2, horizontal = FALSE)  # Overrides horizontal
} # }
```
