# Parse tabgroup into normalized hierarchy

Internal helper to parse tabgroup parameter from various formats into a
standardized character vector representing the hierarchy.

## Usage

``` r
add_viz(
  viz_collection,
  type = NULL,
  ...,
  tabgroup = NULL,
  title = NULL,
  title_tabset = NULL,
  text = NULL,
  icon = NULL,
  text_position = NULL,
  text_before_tabset = NULL,
  text_after_tabset = NULL,
  text_before_viz = NULL,
  text_after_viz = NULL,
  height = NULL,
  filter = NULL,
  data = NULL,
  drop_na_vars = FALSE
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

  Optional group ID for organizing related visualizations. Supports:

  - Simple string: `"demographics"` for a single tab group

  - Slash notation: `"demographics/details"` or
    `"demographics/details/regional"` for nested tabs

  - Named numeric vector:
    `c("1" = "demographics", "2" = "details", "3" = "regional")` for
    explicit hierarchy

- title:

  Display title for the visualization (shown above the chart)

- title_tabset:

  Optional tab label. If NULL, uses `title` for the tab label. Use this
  when you want a short tab name but a longer, descriptive visualization
  title.

- text:

  Optional markdown text to display above the visualization

- icon:

  Optional iconify icon shortcode for the visualization

- text_position:

  Position of text relative to visualization ("above" or "below")

- height:

  Optional height in pixels for highcharter visualizations (numeric
  value)

- filter:

  Optional filter expression to subset data for this visualization. Use
  formula syntax: `~ condition`. Examples: `~ wave == 1`, `~ age > 18`,
  `~ wave %in% c(1, 2, 3)`

- data:

  Optional dataset name when using multiple datasets. Can be:

  - NULL: Uses default dataset (or only dataset if single)

  - String: Name of dataset from named list (e.g., "survey",
    "demographics")

## Value

Character vector of hierarchy levels, or NULL Add a visualization to the
collection

Adds a single visualization specification to an existing collection.
Visualizations with the same tabgroup value will be organized into tabs
on the generated page. Supports nested tabsets through hierarchy
notation.

The updated viz_collection object

## Examples

``` r
if (FALSE) { # \dontrun{
# Simple tabgroup
page1_viz <- create_viz() %>%
  add_viz(type = "stackedbar", x_var = "education", stack_var = "gender",
          title = "Education by Gender", tabgroup = "demographics")
          
# Nested tabgroups using slash notation
page2_viz <- create_viz() %>%
  add_viz(type = "stackedbar", title = "Overview", 
          tabgroup = "demographics") %>%
  add_viz(type = "stackedbar", title = "Details",
          tabgroup = "demographics/details")
          
# Nested tabgroups using named numeric vector
page3_viz <- create_viz() %>%
  add_viz(type = "stackedbar", title = "Regional Details",
          tabgroup = c("1" = "demographics", "2" = "details", "3" = "regional"))
          
# Filter data per visualization
page4_viz <- create_viz() %>%
  add_viz(type = "histogram", x_var = "response", 
          title = "Wave 1", filter = ~ wave == 1) %>%
  add_viz(type = "histogram", x_var = "response",
          title = "Wave 2", filter = ~ wave == 2) %>%
  add_viz(type = "histogram", x_var = "response",
          title = "All Waves", filter = ~ wave %in% c(1, 2, 3))
          
# Multiple datasets
page5_viz <- create_viz() %>%
  add_viz(type = "histogram", x_var = "age", data = "demographics") %>%
  add_viz(type = "histogram", x_var = "response", data = "survey") %>%
  add_viz(type = "histogram", x_var = "outcome", data = "outcomes")
  
# Separate tab label from visualization title
page6_viz <- create_viz() %>%
  add_viz(
    type = "histogram",
    x_var = "age",
    tabgroup = "demographics",
    title_tabset = "Age",  # Short tab label
    title = "Age Distribution of Survey Respondents by Gender and Region"  # Long viz title
  )
} # }
```
