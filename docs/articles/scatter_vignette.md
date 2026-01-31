# Creating Scatter Plots with viz_scatter()

## 📖 Introduction

The
[`viz_scatter()`](https://favstats.github.io/dashboardr/reference/viz_scatter.md)
function visualizes the relationship between two numeric variables. Each
point represents one observation, positioned by its x and y values.
Essential for exploring correlations, clusters, and outliers.

``` r
library(dashboardr)
library(dplyr)
library(gssr)
library(haven)

# Load GSS data - we need numeric variables for scatter plots
data(gss_all)
gss <- gss_all %>%
  select(year, age, sex, race, degree, happy, polviews, educ, realinc) %>%
  filter(year == 2022,  # Use 2022 which has realinc data
         !is.na(age), !is.na(educ), !is.na(realinc),
         realinc > 0, educ > 0) %>%
  mutate(
    sex = droplevels(as_factor(sex)),
    degree = droplevels(as_factor(degree))
  )
```

## 📊 Basic Scatter Plots

Create a simple scatter plot showing the relationship between education
(years) and income:

``` r
plot <- viz_scatter(
  data = gss,
  x_var = "educ",
  y_var = "realinc",
  title = "Education vs Income",
  x_label = "Years of Education",
  y_label = "Real Income ($)"
)

plot
```

## 📈 Adding Trend Lines

Use `show_trend = TRUE` to add a regression line:

``` r
plot <- viz_scatter(
  data = gss,
  x_var = "educ",
  y_var = "realinc",
  show_trend = TRUE,
  title = "Education vs Income (with trend)"
)

plot
```

## 🎨 Coloring by Groups

Use `color_var` to color points by a categorical variable:

``` r
plot <- viz_scatter(
  data = gss,
  x_var = "educ",
  y_var = "realinc",
  color_var = "sex",
  title = "Education vs Income by Sex",
  color_palette = c("#3498DB", "#E74C3C")
)

plot
```

## 📊 Age vs Education

Another relationship to explore - age and years of education:

``` r
plot <- viz_scatter(
  data = gss,
  x_var = "age",
  y_var = "educ",
  color_var = "degree",
  title = "Age vs Education by Degree",
  x_label = "Age (years)",
  y_label = "Years of Education",
  alpha = 0.5,
  color_palette = c("#E74C3C", "#F39C12", "#27AE60", "#3498DB", "#9B59B6")
)

plot
```

## 👁️ Handling Overlap with Transparency

For dense data, use `alpha` to reveal patterns:

``` r
plot <- viz_scatter(
  data = gss,
  x_var = "age",
  y_var = "realinc",
  alpha = 0.3,
  point_size = 3,
  title = "Age vs Income (with transparency)"
)

plot
```

## 🏷️ Labels and Tooltips

Customize axis labels and tooltip formatting for better readability:

``` r
plot <- viz_scatter(
  data = gss,
  x_var = "educ",
  y_var = "realinc",
  title = "Education vs Income",
  x_label = "Years of Education",
  y_label = "Annual Income (USD)",
  tooltip_format = "Education: {x} years, Income: ${y}"
)

plot
```

| Parameter        | Description             | Example                |
|------------------|-------------------------|------------------------|
| `x_label`        | Custom x-axis label     | `"Years of Education"` |
| `y_label`        | Custom y-axis label     | `"Income (USD)"`       |
| `tooltip_format` | Custom tooltip template | `"x: {x}, y: {y}"`     |

The `tooltip_format` parameter supports placeholders: `{x}` for x-value,
`{y}` for y-value, and `{color}` for the color group.

## 📁 Using with create_content()

Integrate scatter plots into dashboards:

``` r
content <- create_content(data = gss, type = "scatter") %>%
  add_viz(
    x_var = "educ",
    y_var = "realinc",
    show_trend = TRUE,
    title = "Education vs Income"
  )

content %>% preview()
```

Preview

Education vs Income

### With Filters

Compare relationships across groups:

``` r
content <- create_content(data = gss, type = "scatter", alpha = 0.5) %>%
  add_viz(
    x_var = "educ",
    y_var = "realinc",
    title = "Male",
    filter = ~ sex == "male",
    tabgroup = "By Sex"
  ) %>%
  add_viz(
    x_var = "educ",
    y_var = "realinc",
    title = "Female",
    filter = ~ sex == "female",
    tabgroup = "By Sex"
  )

content %>% preview()
```

Preview

By Sex

Male

Female

### Multiple Relationships

``` r
content <- create_content(data = gss, type = "scatter", alpha = 0.4, show_trend = TRUE) %>%
  add_viz(
    x_var = "educ",
    y_var = "realinc",
    title = "Education → Income",
    tabgroup = "Relationships"
  ) %>%
  add_viz(
    x_var = "age",
    y_var = "realinc",
    title = "Age → Income",
    tabgroup = "Relationships"
  )

content %>% preview()
```

Preview

Relationships

Education \<U+2192\> Income

Age \<U+2192\> Income

## 🔍 Interpreting Scatter Plots

### Correlation Patterns

| Pattern        | Meaning                |
|----------------|------------------------|
| Upward slope   | Positive relationship  |
| Downward slope | Negative relationship  |
| No pattern     | No linear relationship |
| Tight cluster  | Strong relationship    |
| Wide scatter   | Weak relationship      |

### What to Look For

1.  **Direction** - Positive, negative, or none?
2.  **Strength** - How tightly clustered?
3.  **Linearity** - Linear or curved?
4.  **Outliers** - Points far from the pattern?
5.  **Clusters** - Distinct groups?

## 💡 When to Use Scatter Plots

**Use
[`viz_scatter()`](https://favstats.github.io/dashboardr/reference/viz_scatter.md)
when:** - Exploring relationship between two numeric variables - Looking
for correlations - Identifying outliers - Showing individual-level data

**Use
[`viz_histogram()`](https://favstats.github.io/dashboardr/reference/viz_histogram.md)
when:** - Showing distribution of a single variable

**Use
[`viz_heatmap()`](https://favstats.github.io/dashboardr/reference/viz_heatmap.md)
when:** - Data is aggregated (means, counts) - Many overlapping points

## 📚 See Also

- [`?viz_scatter`](https://favstats.github.io/dashboardr/reference/viz_scatter.md) -
  Full function documentation
- [`vignette("histogram_vignette")`](https://favstats.github.io/dashboardr/articles/histogram_vignette.md) -
  For single-variable distributions
- [`vignette("heatmap_vignette")`](https://favstats.github.io/dashboardr/articles/heatmap_vignette.md) -
  For aggregated relationships
- [`vignette("content-collections")`](https://favstats.github.io/dashboardr/articles/content-collections.md) -
  For dashboard integration
