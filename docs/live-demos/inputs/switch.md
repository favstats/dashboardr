# Switch

# Switch

## Switch Toggle

The **switch** input toggles a specific series on/off. Use
`toggle_series` to specify which series to control.

``` r
add_input(
  input_id = "show_average",
  label = "Show Global Average",
  type = "switch",
  filter_var = "country",
  toggle_series = "Global Average",
  override = TRUE,
  value = TRUE
)
```

Select Countries United States United Kingdom Germany France Japan China
Brazil Australia

Show Global Average

Toggle benchmark line on/off.

## Female Authorship with Benchmark
