# Creating Maps with viz_map()

## 📖 Introduction

The
[`viz_map()`](https://favstats.github.io/dashboardr/reference/viz_map.md)
function creates **choropleth maps** - geographic maps where regions are
colored by data values. They’re ideal for showing how a metric varies
across countries, states, or other geographic areas.

``` r
library(dashboardr)
library(dplyr)
```

### Preparing Map Data

Maps require a column with **geographic identifier codes** that match
the map’s internal region codes. For world maps, use 2-letter ISO
country codes (`iso2c`).

The [gapminder](https://cran.r-project.org/package=gapminder) dataset
provides country-level statistics. We use
[countrycode](https://cran.r-project.org/package=countrycode) to convert
country names to ISO codes:

``` r
library(gapminder)
library(countrycode)

map_data <- gapminder %>%
  filter(year == max(year)) %>%
  mutate(iso2c = countrycode(country, "country.name", "iso2c")) %>%
  filter(!is.na(iso2c))

head(map_data)
#> # A tibble: 6 × 7
#>   country     continent  year lifeExp      pop gdpPercap iso2c
#>   <fct>       <fct>     <int>   <dbl>    <int>     <dbl> <chr>
#> 1 Afghanistan Asia       2007    43.8 31889923      975. AF   
#> 2 Albania     Europe     2007    76.4  3600523     5937. AL   
#> 3 Algeria     Africa     2007    72.3 33333216     6223. DZ   
#> 4 Angola      Africa     2007    42.7 12420476     4797. AO   
#> 5 Argentina   Americas   2007    75.3 40301927    12779. AR   
#> 6 Australia   Oceania    2007    81.2 20434176    34435. AU
```

## 🌍 World Map: Life Expectancy

Create a world choropleth with
[`create_content()`](https://favstats.github.io/dashboardr/reference/create_content.md)
and
[`add_viz()`](https://favstats.github.io/dashboardr/reference/add_viz.md).
This example also demonstrates **tooltip customization** with
`tooltip_vars` to show extra columns on hover:

``` r
create_content(data = map_data, type = "map") %>%
  add_viz(
    value_var = "lifeExp",
    join_var = "iso2c",
    map_type = "custom/world",
    title = "Life Expectancy by Country (2007)",
    color_palette = c("#fee5d9", "#a50f15"),
    legend_title = "Life Expectancy (years)",
    tooltip_vars = c("country", "continent", "lifeExp", "pop")
  ) %>%
  preview()
```

Preview

Life Expectancy by Country (2007)

Key parameters:

| Parameter | Description |
|----|----|
| `value_var` | Numeric column that controls region color intensity |
| `join_var` | Column with geographic codes (must match the map’s internal codes) |
| `map_type` | Map geography (e.g. `"custom/world"`, `"countries/us/us-all"`) |
| `color_palette` | Two colors for the gradient: `c(low, high)` |
| `legend_title` | Label shown on the color legend |
| `tooltip_vars` | Extra columns to display in the hover tooltip |

## 💰 World Map: GDP per Capita

This example shows a different metric with a different color scheme,
plus `subtitle`, `na_color` for regions without data, and border
styling:

``` r
create_content(data = map_data, type = "map") %>%
  add_viz(
    value_var = "gdpPercap",
    join_var = "iso2c",
    map_type = "custom/world",
    title = "GDP per Capita by Country (2007)",
    subtitle = "Source: Gapminder",
    color_palette = c("#f7fbff", "#08306b"),
    legend_title = "GDP per Capita ($)",
    na_color = "#EEEEEE",
    border_color = "#CCCCCC",
    border_width = 0.3,
    height = 550
  ) %>%
  preview()
```

Preview

GDP per Capita by Country (2007)

| Parameter      | Description                                           |
|----------------|-------------------------------------------------------|
| `subtitle`     | Text displayed below the title                        |
| `na_color`     | Color for regions with no data (default: `"#E0E0E0"`) |
| `border_color` | Border color between regions (default: `"#FFFFFF"`)   |
| `border_width` | Border width in pixels (default: `0.5`)               |
| `height`       | Chart height in pixels (default: `500`)               |

## 📋 Available Map Types

| Map Type                 | Region                  | Join Key                  |
|--------------------------|-------------------------|---------------------------|
| `"custom/world"`         | World countries         | `iso2c` (2-letter ISO)    |
| `"custom/world-highres"` | World (high resolution) | `iso2c`                   |
| `"countries/us/us-all"`  | US states               | Postal codes (“CA”, “NY”) |
| `"countries/de/de-all"`  | German states           | State codes               |
| `"custom/europe"`        | European countries      | `iso2c`                   |

## 🔍 When to Use Maps

**Use maps when:**

- Showing geographic patterns or spatial variation
- Regional comparisons are important
- Location context adds meaning to the data

**Consider bar charts instead when:**

- Precise value comparisons matter more than geography
- Data isn’t inherently geographic
- You have many small regions that are hard to see on a map

## 📚 See Also

- [`?viz_map`](https://favstats.github.io/dashboardr/reference/viz_map.md) -
  Full function documentation
- [`vignette("content-collections")`](https://favstats.github.io/dashboardr/articles/content-collections.md) -
  For dashboard integration with maps
- [`vignette("heatmap_vignette")`](https://favstats.github.io/dashboardr/articles/heatmap_vignette.md) -
  For non-geographic grid visualizations
