# Create a treemap visualization

Creates an interactive treemap using highcharter for hierarchical data.
Treemaps are useful for showing proportional data in a space-efficient
way.

## Usage

``` r
create_treemap(
  data,
  group_var,
  subgroup_var = NULL,
  value_var,
  color_var = NULL,
  title = NULL,
  subtitle = NULL,
  color_palette = NULL,
  height = 500,
  allow_drill_down = TRUE,
  layout_algorithm = "squarified",
  show_labels = TRUE,
  label_style = NULL,
  tooltip_format = NULL,
  credits = FALSE,
  ...
)
```

## Arguments

- data:

  Data frame containing the data

- group_var:

  Primary grouping variable (e.g., "region")

- subgroup_var:

  Optional secondary grouping variable (e.g., "city")

- value_var:

  Variable for sizing the rectangles (e.g., "spend")

- color_var:

  Optional variable for coloring (defaults to group_var)

- title:

  Chart title

- subtitle:

  Chart subtitle

- color_palette:

  Named vector of colors or palette name

- height:

  Chart height in pixels (default 500)

- allow_drill_down:

  Whether to allow drilling into subgroups (default TRUE)

- layout_algorithm:

  Layout algorithm: "squarified" (default), "strip", "sliceAndDice",
  "stripes"

- show_labels:

  Whether to show data labels (default TRUE)

- label_style:

  List of label styling options

- tooltip_format:

  Custom tooltip format

- credits:

  Whether to show Highcharts credits (default FALSE)

- ...:

  Additional parameters passed to highcharter

## Value

A highcharter treemap object

## Examples

``` r
if (FALSE) { # \dontrun{
# Simple treemap
data <- data.frame(
  region = c("North", "North", "South", "South"),
  city = c("NYC", "Boston", "Miami", "Atlanta"),
  spend = c(1000, 500, 800, 600)
)
create_treemap(data, group_var = "region", subgroup_var = "city", value_var = "spend")

# Single-level treemap
create_treemap(data, group_var = "city", value_var = "spend", title = "Spend by City")
} # }
```
