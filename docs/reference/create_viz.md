# Create a new visualization collection

Initializes an empty collection for building up multiple visualizations
using the piping workflow. Optionally accepts custom display labels for
tab groups.

## Usage

``` r
create_viz(tabgroup_labels = NULL)
```

## Arguments

- tabgroup_labels:

  Named vector/list mapping tabgroup IDs to display names

## Value

A viz_collection object

## Examples

``` r
if (FALSE) { # \dontrun{
# Create viz collection with custom group labels
vizzes <- create_viz(tabgroup_labels = c("demo" = "Demographics",
                                          "pol" = "Political Views"))
} # }
```
