# Add a visualization to the collection

Adds a single visualization specification to an existing collection.
Visualizations with the same tabgroup value will be organized into tabs
on the generated page.

## Usage

``` r
add_viz(
  viz_collection,
  type,
  ...,
  tabgroup = NULL,
  title = NULL,
  text = NULL,
  icon = NULL,
  text_position = "above",
  height = NULL
)
```

## Arguments

- viz_collection:

  A viz_collection object

- type:

  Visualization type: "stackedbar", "heatmap", "histogram", "timeline"

- ...:

  Additional parameters passed to the visualization function

- tabgroup:

  Optional group ID for organizing related visualizations

- title:

  Display title for the visualization

- text:

  Optional markdown text to display above the visualization

- icon:

  Optional iconify icon shortcode for the visualization

- text_position:

  Position of text relative to visualization ("above" or "below")

- height:

  Optional height in pixels for highcharter visualizations (numeric
  value)

## Value

The updated viz_collection object

## Examples

``` r
if (FALSE) { # \dontrun{
page1_viz <- create_viz() %>%
  add_viz(type = "stackedbar", x_var = "education", stack_var = "gender",
          title = "Education by Gender", tabgroup = "demographics",
          text = "This chart shows educational attainment by gender.",
          icon = "ph:chart-bar")
} # }
```
