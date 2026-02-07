# Checkbox

# Checkbox

## Checkbox Input

The **checkbox** input allows multiple selections with all options
visible. Great for 3-6 options.

``` r
add_input(
  input_id = "segment_filter",
  label = "Show Sectors",
  type = "checkbox",
  filter_var = "segment",
  options = c("Research", "Industry", "Government"),
  default_selected = c("Research", "Industry", "Government"),
  inline = TRUE
)
```

Show Sectors

Research

Industry

Government

Check/uncheck to show/hide sectors in the chart.

## Publications by Sector
