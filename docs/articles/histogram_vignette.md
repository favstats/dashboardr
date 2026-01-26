# Creating Histograms with viz_histogram()

## Introduction

The
[`viz_histogram()`](https://favstats.github.io/dashboardr/reference/viz_histogram.md)
function visualizes the distribution of continuous numeric variables.
Unlike bar charts (which count categories), histograms show how values
are spread across a range by grouping them into bins.

``` r
library(dashboardr)
library(dplyr)
library(gssr)
library(haven)

# Load GSS data
data(gss_all)
gss <- gss_all %>%
  select(year, age, sex, race, degree, happy, polviews) %>%
  filter(year == max(year, na.rm = TRUE), !is.na(age))
```

## Basic Histograms

Create a simple histogram showing the distribution of age:

``` r
plot <- viz_histogram(
  data = gss,
  x_var = "age",
  title = "Age Distribution",
  x_label = "Age (years)",
  y_label = "Frequency"
)

plot
```

## Controlling Bin Size

The `bins` parameter controls granularity. More bins = more detail but
noisier; fewer bins = smoother but less detail.

### Few Bins (Smooth)

``` r
plot <- viz_histogram(
  data = gss,
  x_var = "age",
  bins = 10,
  title = "Age Distribution (10 bins)"
)

plot
```

### Many Bins (Detailed)

``` r
plot <- viz_histogram(
  data = gss,
  x_var = "age",
  bins = 40,
  title = "Age Distribution (40 bins)"
)

plot
```

## Count vs. Percent

By default, histograms show counts. Use `histogram_type = "percent"` to
show percentages:

``` r
plot <- viz_histogram(
  data = gss,
  x_var = "age",
  histogram_type = "percent",
  title = "Age Distribution (%)",
  y_label = "Percentage"
)

plot
```

## Custom Colors

``` r
plot <- viz_histogram(
  data = gss,
  x_var = "age",
  bins = 25,
  color_palette = c("#9B59B6"),
  title = "Custom Colored Histogram"
)

plot
```

## Labels and Tooltips

Customize axis labels and tooltip text for a polished presentation:

``` r
plot <- viz_histogram(
  data = gss,
  x_var = "age",
  bins = 25,
  title = "Age Distribution",
  x_label = "Age (years)",
  y_label = "Number of Respondents",
  tooltip_suffix = " people",
  x_tooltip_suffix = " years old"
)

plot
```

| Parameter | Description | Example |
|----|----|----|
| `x_label` | Custom x-axis label | `"Age (years)"` |
| `y_label` | Custom y-axis label | `"Frequency"`, `"Percentage"` |
| `tooltip_prefix` | Text before tooltip value | `"Count: "` |
| `tooltip_suffix` | Text after tooltip value | `" respondents"` |
| `x_tooltip_suffix` | Text after x value in tooltip | `" years"` |

## Using with create_content()

Integrate histograms into dashboards using `type = "histogram"`:

``` r
content <- create_content(data = gss, type = "histogram") %>%
  add_viz(
    x_var = "age",
    bins = 25,
    title = "Age Distribution"
  )

content %>% preview()
```

Preview

Age Distribution

### Multiple Histograms with Filters

Compare distributions across groups using filters:

``` r
content <- create_content(data = gss, type = "histogram", bins = 20) %>%
  add_viz(
    x_var = "age",
    title = "Male",
    filter = ~ sex == "male",
    tabgroup = "By Sex"
  ) %>%
  add_viz(
    x_var = "age",
    title = "Female",
    filter = ~ sex == "female",
    tabgroup = "By Sex"
  )

content %>% preview()
```

Preview

By Sex

### Multiple Variables

``` r
# Prepare data with year as numeric
gss_numeric <- gss %>%
  mutate(year_num = as.numeric(year))

content <- create_content(data = gss_numeric, type = "histogram", bins = 20) %>%
  add_viz(x_var = "age", title = "Age Distribution", tabgroup = "Distributions")

content %>% preview()
```

Preview

Distributions

Age Distribution

## Interpreting Histograms

### Distribution Shapes

| Shape         | Meaning                 | Example                |
|---------------|-------------------------|------------------------|
| Normal (bell) | Symmetric around mean   | Test scores, heights   |
| Right-skewed  | Long tail to the right  | Income, response times |
| Left-skewed   | Long tail to the left   | Age at retirement      |
| Bimodal       | Two peaks               | Mixed populations      |
| Uniform       | Flat, equal frequencies | Random numbers         |

### What to Look For

1.  **Center** - Where is the middle of the distribution?
2.  **Spread** - How wide is the distribution?
3.  **Shape** - Is it symmetric, skewed, or multimodal?
4.  **Outliers** - Are there unusual values far from the center?

## When to Use Histograms

**Use
[`viz_histogram()`](https://favstats.github.io/dashboardr/reference/viz_histogram.md)
when:** - Showing distribution of a continuous variable - Analyzing
spread and shape of data - Looking for outliers or unusual patterns

**Use
[`viz_bar()`](https://favstats.github.io/dashboardr/reference/viz_bar.md)
when:** - Counting categorical values - Comparing groups side-by-side

## See Also

- [`?viz_histogram`](https://favstats.github.io/dashboardr/reference/viz_histogram.md) -
  Full function documentation
- [`vignette("bar_vignette")`](https://favstats.github.io/dashboardr/articles/bar_vignette.md) -
  For categorical data
- [`vignette("content-collections")`](https://favstats.github.io/dashboardr/articles/content-collections.md) -
  For dashboard integration
