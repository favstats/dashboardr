# Generate lazy loading script for charts

Creates JavaScript code for Intersection Observer-based lazy loading and
tab-aware rendering of charts

## Usage

``` r
.generate_lazy_load_script(
  lazy_load_margin = "200px",
  lazy_load_tabs = TRUE,
  theme = "light",
  debug = FALSE
)
```

## Arguments

- lazy_load_margin:

  Viewport margin for intersection observer

- lazy_load_tabs:

  Whether to enable tab-aware lazy loading

## Value

Character vector of script lines
