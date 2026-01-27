# Pills Theme

# Pills Theme

``` r
create_page(
  "Pills Theme",
  data = gss,
  type = "bar",
  tabset_theme = "pills"
) %>%
  add_viz(x_var = "degree", tabgroup = "Demographics") %>%
  add_viz(x_var = "race", tabgroup = "Demographics") %>%
  add_viz(x_var = "happy", tabgroup = "Attitudes")
```

## Demographics

- Education Levels
- Race Distribution

## Attitudes

- Happiness Levels
- Political Views
