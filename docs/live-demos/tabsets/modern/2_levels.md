# 2 Levels

# 2 Levels

## Two Level Nested Tabs

Use `/` to create parent and child tabs:

``` r
add_viz(..., tabgroup = "satisfaction/by_age") %>%
add_viz(..., tabgroup = "satisfaction/by_education") %>%
add_viz(..., tabgroup = "education/by_age")
```

## Satisfaction Analysis

- By Age
- By Education
- By Region

## Education Analysis

- By Age
- By Region
