# Add a custom highcharter chart

Add a pre-built highcharter chart to your dashboard. This allows you to
create complex, customized highcharter visualizations and include them
directly without using dashboardr's viz\_\* functions.

## Usage

``` r
add_hc(content, hc_object, height = NULL, tabgroup = NULL)
```

## Arguments

- content:

  A content_collection, page_object, or dashboard object

- hc_object:

  A highcharter object created with highcharter::highchart() or hchart()

- height:

  Optional height for the chart (e.g., "400px", "50vh"). Defaults to
  "400px"

- tabgroup:

  Optional tabgroup for organizing content (character vector for nested
  tabs)

## Value

Updated content object

## Examples

``` r
if (FALSE) { # \dontrun{
library(highcharter)

# Create a custom highcharter chart
my_chart <- hchart(mtcars, "scatter", hcaes(x = wt, y = mpg, group = cyl)) %>%
  hc_title(text = "Custom Scatter Plot") %>%
  hc_subtitle(text = "Made with highcharter") %>%
  hc_add_theme(hc_theme_smpl())

# Add it to a page
page <- create_page("Charts") %>%
  add_hc(my_chart) %>%
  add_hc(another_chart, height = "500px", tabgroup = "My Charts")
} # }
```
