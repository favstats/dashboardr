# Combined

# Combined

## Combined Inputs

Multiple inputs can work together. Here, a **select dropdown** filters
countries while a **switch** toggles the benchmark.

``` r
content <- create_content() %>%
  add_input_row(style = "inline", align = "center") %>%
    add_input(
      input_id = "country_filter",
      label = "Select Countries",
      filter_var = "country",
      options = countries_by_region,
      default_selected = c("United States", "Germany"),
      width = "450px"
    ) %>%
    add_input(
      input_id = "show_average",
      label = "Show Benchmark",
      type = "switch",
      filter_var = "country",
      toggle_series = "Global Average",
      override = TRUE,
      value = TRUE
    ) %>%
  end_input_row()
```

Select Countries United States Brazil United Kingdom Germany France
Japan China Australia Global AverageSelect countries to compare.

Show Benchmark

Toggle global average line.

## Global Publication Trends
