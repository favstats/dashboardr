# Backends

dashboardr supports four chart rendering backends. The default is
**highcharter**. You can switch to **plotly**, **echarts4r**, or
**ggiraph** at the collection or dashboard level (e.g. with
`backend = "echarts4r"`).

## Backend overview

| Backend (`backend=`) | R package (CRAN link) | Licensing considerations | Approx. coverage in dashboardr |
|----|----|----|----|
| `"highcharter"` | [highcharter](https://cran.r-project.org/package=highcharter) | **Free for academia/non-profit, paid for commercial use.** Highcharts JS requires a separate license for commercial or government projects. | **Full** |
| `"plotly"` | [plotly](https://cran.r-project.org/package=plotly) | **Free (MIT).** Fully open source for both personal and commercial applications without fees. | **Well covered** |
| `"echarts4r"` | [echarts4r](https://cran.r-project.org/package=echarts4r) | **Free (Apache 2.0).** Open source and safe for commercial products with no licensing costs. | **Decent coverage** |
| `"ggiraph"` | [ggiraph](https://cran.r-project.org/package=ggiraph) | **Free (GPL-3).** Standard open-source license that allows commercial use. | **Low** |

### Licensing & Usage Warnings

- **Highcharter:** While the R wrapper is MIT licensed, the underlying
  **Highcharts JavaScript library** is a commercial product. If your
  dashboard is for a for-profit company or a government entity, you must
  purchase a license. It is free only for personal, non-commercial, or
  school-related projects.

- **Plotly & Echarts4r:** These are the preferred enterprise-safe
  options when there is no budget for per-developer or per-site
  licenses. Their underlying libraries (Plotly.js and Apache ECharts)
  are permissive and free for commercial use.

- **Distribution:** If you are distributing your dashboard as a
  standalone product, check the **GPL-3** requirements for `ggiraph`.
  This license requires that any derivative works also be made open
  source under the same terms.

------------------------------------------------------------------------

**Data Setup** (click to expand)

``` r
library(dashboardr)
library(dplyr)
library(gssr)
library(haven)

data(gss_all)

gss <- gss_all %>%
  select(year, age, sex, race, degree, happy) %>%
  filter(year == max(year, na.rm = TRUE)) %>%
  filter(
    happy %in% 1:3,
    !is.na(age), !is.na(sex), !is.na(race), !is.na(degree)
  ) %>%
  mutate(
    happy = droplevels(as_factor(happy)),
    degree = droplevels(as_factor(degree)),
    sex = droplevels(as_factor(sex)),
    race = droplevels(as_factor(race))
  )
```

## Supported Backends

| Backend         | Package           | Notes                                 |
|-----------------|-------------------|---------------------------------------|
| `"highcharter"` | highcharter       | Default. Cross-tab filtering support. |
| `"plotly"`      | plotly            | Plotly.js with zoom, pan, hover.      |
| `"echarts4r"`   | echarts4r         | Apache ECharts with animations.       |
| `"ggiraph"`     | ggiraph + ggplot2 | Interactive ggplot2 with tooltips.    |

Only highcharter is a hard dependency. The others are optional
(`Suggests`):

``` r
install.packages("plotly")
install.packages("echarts4r")
install.packages(c("ggiraph", "ggplot2"))
```

## Default: Highcharter

When no `backend` is specified, highcharter is used:

``` r
create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "degree", title = "Education (Highcharter)") %>%
  preview()
```

Preview

Education (Highcharter)

## Switching Backends

Set `backend` on individual
[`add_viz()`](https://favstats.github.io/dashboardr/reference/add_viz.md)
calls:

### Plotly

``` r
create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "degree", title = "Education (Plotly)", backend = "plotly") %>%
  preview()
```

Preview

Education (Plotly)

### ECharts

``` r
create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "degree", title = "Education (ECharts)", backend = "echarts4r") %>%
  preview()
```

Preview

Education (ECharts)

### ggiraph

``` r
create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "degree", title = "Education (ggiraph)", backend = "ggiraph") %>%
  preview()
```

Preview

Education (ggiraph)

## Collection-Wide Backend

Set `backend` in
[`create_content()`](https://favstats.github.io/dashboardr/reference/create_content.md)
so all
[`add_viz()`](https://favstats.github.io/dashboardr/reference/add_viz.md)
calls inherit it:

``` r
create_content(data = gss, type = "bar", backend = "plotly") %>%
  add_viz(x_var = "degree", title = "Education") %>%
  add_viz(x_var = "race", title = "Race") %>%
  preview()
```

Preview

Education

Race

## Dashboard-Wide Backend

Set `backend` in
[`create_dashboard()`](https://favstats.github.io/dashboardr/reference/create_dashboard.md)
for the entire project. Individual charts can still override:

``` r
proj <- create_dashboard(
  title = "Plotly Dashboard",
  output_dir = tempdir(),
  backend = "plotly"
) %>%
  add_dashboard_page(page_title = "Overview", data = gss) %>%
  add_viz(type = "bar", x_var = "degree") %>%
  add_viz(type = "bar", x_var = "race") %>%
  # Override one chart back to highcharter
  add_viz(type = "bar", x_var = "sex", backend = "highcharter")
```

## Validation with print(check = TRUE)

`print(collection, check = TRUE)` validates parameters and column names.
This works regardless of which backend is set:

``` r
content <- create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "degree", title = "Highcharter Bar", backend = "highcharter") %>%
  add_viz(x_var = "race", title = "Plotly Bar", backend = "plotly") %>%
  add_viz(x_var = "sex", title = "ECharts Bar", backend = "echarts4r")

print(content, check = TRUE)
#> -- Content Collection ──────────────────────────────────────────────────────────
#> 3 items | ✔ data: 3118 rows x 6 cols
#> 
#> • [Viz] Highcharter Bar (bar) x=degree
#> • [Viz] Plotly Bar (bar) x=race
#> • [Viz] ECharts Bar (bar) x=sex
```

Backend validity is checked at render time when you call
[`preview()`](https://favstats.github.io/dashboardr/reference/preview.md)
or
[`generate_dashboard()`](https://favstats.github.io/dashboardr/reference/generate_dashboard.md),
not during validation.

## Limitations

- **Feature parity**: All backends support core features (titles,
  colors, labels, tooltips).

- **Chart type coverage**: Most viz types support all 4 backends. A few
  exceptions exist (e.g.,
  [`viz_gauge()`](https://favstats.github.io/dashboardr/reference/viz_gauge.md)
  does not support ggiraph,
  [`viz_waffle()`](https://favstats.github.io/dashboardr/reference/viz_waffle.md)
  does not support echarts4r).
