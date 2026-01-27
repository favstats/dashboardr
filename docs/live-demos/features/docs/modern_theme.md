# Modern Theme

# Modern Theme

``` r
create_page(
  "Modern Theme",
  data = gss,
  type = "bar",
  tabset_theme = "modern"
) %>%
  add_viz(x_var = "degree", tabgroup = "Section A") %>%
  add_viz(x_var = "happy", tabgroup = "Section B")
```

## Section A

- Education
- Gender

## Section B

- Happiness
- Race
