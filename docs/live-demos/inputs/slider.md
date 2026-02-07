# Slider

# Slider

## Slider Input

The **slider** input filters data by a numeric range. Use `labels` to
display custom text instead of numbers.

``` r
add_input(
  input_id = "decade_slider",
  label = "Starting Decade",
  type = "slider",
  filter_var = "decade",
  min = 1,
  max = 6,
  step = 1,
  value = 1,
  show_value = TRUE,
  labels = c("1970s", "1980s", "1990s", "2000s", "2010s", "2020s"),
  width = "500px"
)
```

Starting Decade 1970s

1970s 2020s

Drag to filter data from a specific decade onwards.

## Open Access Adoption
