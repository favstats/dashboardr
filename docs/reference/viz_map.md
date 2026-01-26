# Create an interactive map visualization

Creates a Highcharter choropleth map with optional click navigation to
other pages/dashboards. Designed to work within the dashboardr
visualization system via add_viz(type = "map", ...).

## Usage

``` r
viz_map(
  data,
  map_type = "custom/world",
  value_var,
  join_var = "iso2c",
  title = NULL,
  subtitle = NULL,
  legend_title = NULL,
  color_stops = NULL,
  color_palette = c("#f7fbff", "#08306b"),
  na_color = "#E0E0E0",
  click_url_template = NULL,
  click_var = NULL,
  tooltip_vars = NULL,
  tooltip_format = NULL,
  height = 500,
  border_color = "#FFFFFF",
  border_width = 0.5,
  credits = FALSE,
  ...
)
```

## Arguments

- data:

  Data frame with geographic data

- map_type:

  Map type: "custom/world", "custom/world-highres",
  "countries/us/us-all", etc. See Highcharts map collection.

- value_var:

  Column name for color values (required)

- join_var:

  Column name to join with map geography (default: "iso2c")

- title:

  Chart title

- subtitle:

  Chart subtitle

- legend_title:

  Legend title (defaults to value_var)

- color_stops:

  Numeric vector of color gradient stops

- color_palette:

  Character vector of colors for gradient

- na_color:

  Color for missing/NA values (default: "#E0E0E0")

- click_url_template:

  URL template for click navigation. Use `{var}` syntax for variable
  substitution, e.g., "{iso2c}\_dashboard/index.html"

- click_var:

  Variable to use in click URL (defaults to join_var)

- tooltip_vars:

  Character vector of variables to show in tooltip

- tooltip_format:

  Custom tooltip format string (overrides tooltip_vars)

- height:

  Chart height in pixels (default: 500)

- border_color:

  Border color between regions (default: "#FFFFFF")

- border_width:

  Border width (default: 0.5

- credits:

  Show Highcharts credits (default: FALSE)

- ...:

  Additional arguments passed to highcharter::hcmap()

## Value

A highchart object

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic world map
country_data <- data.frame(
  iso2c = c("US", "DE", "FR"),
  total_ads = c(1000, 500, 300)
)

viz_map(
  data = country_data,
  value_var = "total_ads",
  join_var = "iso2c",
  title = "Ad Spending by Country"
)

# With click navigation to country dashboards
viz_map(
  data = country_data,
  value_var = "total_ads",
  click_url_template = "{iso2c}_dashboard/index.html",
  title = "Click a country to explore"
)

# Using with add_viz()
viz <- create_viz() %>%
  add_viz(
    type = "map",
    value_var = "total_ads",
    join_var = "iso2c",
    click_url_template = "{iso2c}_dashboard/index.html"
  )
} # }
```
