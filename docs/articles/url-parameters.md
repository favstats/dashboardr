# URL Parameters

dashboardr can sync filter state to URL query parameters, enabling
shareable links that restore a specific view of the dashboard.

``` r
library(dashboardr)
```

## Enabling URL Parameters

Add
[`enable_url_params()`](https://favstats.github.io/dashboardr/reference/enable_url_params.md)
to your dashboard to activate URL deep linking. This requires
[`enable_inputs()`](https://favstats.github.io/dashboardr/reference/enable_inputs.md)
to also be active (inputs must exist for URL parameters to control).

The simplest way is to set `url_params = TRUE` on
[`enable_inputs()`](https://favstats.github.io/dashboardr/reference/enable_inputs.md):

``` r
page <- create_page("Analysis") %>%
  add_input(
    input_id = "region",
    type = "select_multiple",
    label = "Region",
    filter_var = "region",
    options = c("North", "South", "East", "West")
  ) %>%
  add_viz(
    type = "bar",
    x_var = "category",
    cross_tab_filter_vars = "region"
  )
```

When
[`enable_url_params()`](https://favstats.github.io/dashboardr/reference/enable_url_params.md)
is included, the dashboard will:

1.  **Read** filter state from the URL on page load
2.  **Update** the URL as the user changes filters
3.  **Support** tab navigation via URL hash fragments

## URL Format

Filter values are stored as query parameters using the filter variable
name:

    dashboard.html?region=North,South&year=2020

- Multiple selected values are comma-separated
- Parameter names match the `filter_var` values from your inputs
- Tab state is stored in the URL hash: `dashboard.html#TabName`

## Sharing Pre-Filtered Links

You can construct URLs manually to share a specific dashboard view:

    https://example.com/dashboard.html?region=North&year=2020,2021#Demographics

This link would:

- Set the region filter to “North”
- Set the year filter to “2020” and “2021”
- Navigate to the “Demographics” tab

## Nested Tabs

For dashboards with nested tabgroups, use `/` to specify the tab path:

    dashboard.html#Demographics/Age

This activates the “Demographics” parent tab and then the “Age” child
tab.

## Example Dashboard

``` r
data <- data.frame(
  region = rep(c("North", "South", "East", "West"), each = 25),
  year = rep(2018:2022, 20),
  value = round(rnorm(100, 50, 15))
)

dashboard <- create_dashboard(
  title = "Regional Analysis",
  data = data
) %>%
  add_page(
    create_page("Overview") %>%
      add_input(
        input_id = "region_filter",
        type = "select_multiple",
        label = "Region",
        filter_var = "region",
        options = c("North", "South", "East", "West")
      ) %>%
      add_input(
        input_id = "year_filter",
        type = "select_multiple",
        label = "Year",
        filter_var = "year",
        options = as.character(2018:2022)
      ) %>%
      add_viz(
        type = "bar",
        x_var = "region",
        title = "By Region",
        cross_tab_filter_vars = c("region", "year")
      )
  )
```

After generating this dashboard, users can share links like:

    docs/index.html?region=North,South&year=2020
