# Create a new visualization collection

Initializes an empty collection for building up multiple visualizations
using the piping workflow. Optionally accepts custom display labels for
tab groups and default parameters that apply to all visualizations.

## Usage

``` r
create_viz(data = NULL, tabgroup_labels = NULL, ...)
```

## Arguments

- data:

  Optional data frame to use for all visualizations in this collection.
  This data will be used by add_viz() calls and can be used with
  preview(). Can also be passed to add_page() which will use this as
  fallback if no page-level data is provided.

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
# Create viz collection with data for preview
vizzes <- create_viz(data = mtcars) %>%
  add_viz(type = "histogram", x_var = "mpg", title = "MPG Distribution") %>%
  preview()

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
