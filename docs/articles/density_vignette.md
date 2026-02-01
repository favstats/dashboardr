# Creating Density Plots with viz_density()

## 📖 Introduction

The
[`viz_density()`](https://favstats.github.io/dashboardr/reference/viz_density.md)
function creates kernel density estimate plots, which provide a smoothed
visualization of the distribution of a continuous variable. Unlike
histograms that use discrete bins, density plots show a continuous
estimate of the probability density function.

Density plots are particularly useful for: - Visualizing distribution
shapes without binning artifacts - Comparing multiple distributions on
the same plot - Identifying multimodal distributions

``` r
library(dashboardr)
library(dplyr)
library(gssr)

# Load GSS data
data(gss_all)
gss <- gss_all %>%
  select(year, age, sex, race, degree) %>%
  filter(year == max(year, na.rm = TRUE), !is.na(age))
```

## 📊 Basic Density Plot

Create a simple density plot showing the distribution of age:

``` r
plot <- viz_density(
  data = gss,
  x_var = "age",
  title = "Age Distribution",
  x_label = "Age (years)"
)

plot
```

## 📊 Grouped Densities

Compare distributions across groups by adding a `group_var`:

``` r
plot <- viz_density(
  data = gss,
  x_var = "age",
  group_var = "sex",
  title = "Age Distribution by Sex",
  x_label = "Age (years)",
  color_palette = c("#3498DB", "#E74C3C")
)

plot
```

## 🎨 Customizing Appearance

### Adjusting Fill Opacity

Control the transparency of the filled area with `fill_opacity` (0 =
transparent, 1 = opaque):

``` r
plot <- viz_density(
  data = gss,
  x_var = "age",
  title = "Age Distribution (Higher Opacity)",
  fill_opacity = 0.6
)

plot
```

### Adding Rug Marks

Rug marks show individual data points along the x-axis:

``` r
gss_sample <- gss %>% sample_n(min(200, n()))

plot <- viz_density(
  data = gss_sample,
  x_var = "age",
  title = "Age Distribution with Rug Marks",
  show_rug = TRUE
)

plot
```

## ⚙️ Controlling Bandwidth

The `bandwidth` parameter controls how smooth the density estimate is.
Lower values = more detail, higher values = smoother.

### Low Bandwidth (More Detail)

``` r
plot <- viz_density(
  data = gss,
  x_var = "age",
  bandwidth = 2,
  title = "Age Distribution (Bandwidth = 2)"
)

plot
```

### High Bandwidth (Smoother)

``` r
plot <- viz_density(
  data = gss,
  x_var = "age",
  bandwidth = 10,
  title = "Age Distribution (Bandwidth = 10)"
)

plot
```

## 📊 Multiple Group Comparison

Compare age distributions across race categories:

``` r
# Filter to categories with sufficient data
gss_race <- gss %>%
  filter(!is.na(race)) %>%
  mutate(race = as.character(haven::as_factor(race)))

plot <- viz_density(
  data = gss_race,
  x_var = "age",
  group_var = "race",
  title = "Age Distribution by Race",
  x_label = "Age (years)",
  fill_opacity = 0.3
)

plot
```

## 🔍 Handling Missing Groups

Use `include_na = TRUE` to show NA values as an explicit category:

``` r
# Create some NAs for demonstration
gss_with_na <- gss %>%
  mutate(sex_with_na = if_else(row_number() %% 10 == 0, NA_character_, as.character(haven::as_factor(sex))))

plot <- viz_density(
  data = gss_with_na,
  x_var = "age",
  group_var = "sex_with_na",
  title = "Age Distribution by Sex (Including Missing)",
  include_na = TRUE,
  na_label = "Not Reported"
)

plot
```

## 🔢 Custom Group Ordering

Control the order of groups in the legend:

``` r
gss_degree <- gss %>%
  filter(!is.na(degree)) %>%
  mutate(degree = as.character(haven::as_factor(degree)))

plot <- viz_density(
  data = gss_degree,
  x_var = "age",
  group_var = "degree",
  title = "Age Distribution by Education",
  group_order = c("graduate", "bachelor", "junior college", "high school", "lt high school")
)

plot
```

## 📚 Summary

The
[`viz_density()`](https://favstats.github.io/dashboardr/reference/viz_density.md)
function provides a flexible way to visualize continuous distributions
with these key features:

- **Basic density**: Just specify `data` and `x_var`
- **Grouped comparison**: Add `group_var` to compare distributions
- **Appearance control**: Use `fill_opacity`, `color_palette`, and
  `show_rug`
- **Smoothness**: Adjust `bandwidth` to control detail level
- **Missing values**: Handle with `include_na` and `na_label`
- **Ordering**: Control group order with `group_order`
