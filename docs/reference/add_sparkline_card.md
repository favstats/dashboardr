# Add a sparkline card

Adds a metric card with an embedded sparkline chart. The sparkline uses
the page's data (same as add_viz) and aggregates it by the x_var
(typically a date/time variable). The metric value is derived from the
aggregated data unless overridden.

## Usage

``` r
add_sparkline_card(
  content,
  x_var,
  y_var = NULL,
  value = NULL,
  subtitle = "",
  agg = "count",
  line_color = "#2b74ff",
  bg_color = "#ffffff",
  text_color = "#111827",
  height = 130,
  smooth = 0.6,
  area_opacity = 0.18,
  filter_expr = NULL,
  value_prefix = "",
  value_suffix = "",
  connect_group = NULL,
  tabgroup = NULL,
  show_when = NULL
)
```

## Arguments

- content:

  Content collection, page_object, or sparkline_card_row_container

- x_var:

  Column name for x-axis (typically a date or time variable)

- y_var:

  Column name for y-axis values to aggregate

- value:

  Main value to display. If NULL, automatically computed as the last
  value of the aggregated series.

- subtitle:

  Subtitle text below the value

- agg:

  Aggregation function: "count", "sum", "mean", "cumsum", "cumcount"
  (default "count")

- line_color:

  Color of the sparkline line (default "#2b74ff")

- bg_color:

  Background color of the card (default "#ffffff")

- text_color:

  Text color (default "#111827"; use "#ffffff" for dark backgrounds)

- height:

  Sparkline height in pixels (default 130)

- smooth:

  Smoothing factor for the line, 0-1 (default 0.6)

- area_opacity:

  Opacity of the fill area under the line, 0-1 (default 0.18)

- filter_expr:

  Optional filter expression as a string (e.g. "region == 'West'")

- value_prefix:

  Text to prepend to the displayed value (e.g. "\$")

- value_suffix:

  Text to append to the displayed value (e.g. "%")

- tabgroup:

  Optional tabgroup

- show_when:

  Optional conditional display formula

## Examples

``` r
if (FALSE) { # \dontrun{
page <- create_page(name = "Dashboard", data = survey) %>%
  add_sparkline_card_row() %>%
    add_sparkline_card(
      x_var = "year", y_var = "id",
      agg = "cumcount",
      subtitle = "Total responses tracked"
    ) %>%
    add_sparkline_card(
      x_var = "year", y_var = "score",
      agg = "mean",
      subtitle = "Average satisfaction",
      line_color = "#ffffff",
      bg_color = "#1f8cff",
      text_color = "#ffffff"
    ) %>%
  end_sparkline_card_row()
} # }
```
