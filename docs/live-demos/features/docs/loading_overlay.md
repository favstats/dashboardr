# Loading Overlay

# Loading Overlay

Loading visualizations...

``` r
create_page(
  "Loading Overlay",
  data = gss,
  type = "bar",
  overlay = TRUE,
  overlay_theme = "glass",
  overlay_text = "Loading visualizations...",
  overlay_duration = 2000
) %>%
  add_viz(x_var = "degree", title = "Education")
```

## Charts

- Education Levels
- Race Distribution
- Happiness
