# Creating Treemaps with viz_treemap()

## Introduction

Treemaps display hierarchical data as nested rectangles. The size of
each rectangle represents its value - larger rectangles mean larger
values. They’re excellent for showing composition and proportions across
many categories at once.

``` r
library(dashboardr)
library(dplyr)
library(gssr)
library(haven)

# Load GSS data
data(gss_all)
gss <- gss_all %>%
  select(year, age, sex, race, degree, happy, polviews, region) %>%
  filter(year == max(year, na.rm = TRUE), 
         !is.na(degree), !is.na(sex), !is.na(race), !is.na(region)) %>%
  mutate(
    degree = droplevels(as_factor(degree)),
    sex = droplevels(as_factor(sex)),
    race = droplevels(as_factor(race)),
    region = droplevels(as_factor(region))
  )
```

**Important**: Treemaps require **pre-aggregated data** with a value
column. You typically need to
[`count()`](https://dplyr.tidyverse.org/reference/count.html) or
[`summarize()`](https://dplyr.tidyverse.org/reference/summarise.html)
your data first.

## Basic Treemaps

### Simple Category Sizes

First, aggregate your data to get counts per category:

``` r
# Aggregate - treemaps need pre-summarized data!
degree_counts <- gss %>%
  count(degree, name = "n")

degree_counts
#> # A tibble: 5 × 2
#>   degree                       n
#>   <fct>                    <int>
#> 1 less than high school      287
#> 2 high school               1476
#> 3 associate/junior college   290
#> 4 bachelor's                 708
#> 5 graduate                   465
```

Now create the treemap:

``` r
plot <- viz_treemap(
  data = degree_counts,
  group_var = "degree",
  value_var = "n",
  title = "Education Level Distribution"
)

plot
```

### Race Distribution

``` r
race_counts <- gss %>%
  count(race, name = "n")

plot <- viz_treemap(
  data = race_counts,
  group_var = "race",
  value_var = "n",
  title = "Race Distribution",
  color_palette = c("#3498DB", "#E74C3C", "#27AE60")
)

plot
```

## Hierarchical Treemaps

Treemaps shine when showing nested categories. Use `subgroup_var` for a
second level:

``` r
# Two-level: degree within sex
degree_by_sex <- gss %>%
  count(sex, degree, name = "n")

degree_by_sex
#> # A tibble: 10 × 3
#>    sex    degree                       n
#>    <fct>  <fct>                    <int>
#>  1 male   less than high school      110
#>  2 male   high school                692
#>  3 male   associate/junior college   112
#>  4 male   bachelor's                 322
#>  5 male   graduate                   203
#>  6 female less than high school      177
#>  7 female high school                784
#>  8 female associate/junior college   178
#>  9 female bachelor's                 386
#> 10 female graduate                   262
```

``` r
plot <- viz_treemap(
  data = degree_by_sex,
  group_var = "sex",
  subgroup_var = "degree",
  value_var = "n",
  title = "Education by Sex"
)

plot
```

### Region by Race

``` r
region_race <- gss %>%
  count(region, race, name = "n")

plot <- viz_treemap(
  data = region_race,
  group_var = "region",
  subgroup_var = "race",
  value_var = "n",
  title = "Race Distribution by Region"
)

plot
```

## Custom Colors

``` r
plot <- viz_treemap(
  data = degree_counts,
  group_var = "degree",
  value_var = "n",
  title = "Education Levels",
  color_palette = c("#1ABC9C", "#3498DB", "#9B59B6", "#E74C3C", "#F39C12")
)

plot
```

## Labels and Tooltips

Customize what appears in the treemap cells and hover tooltips:

``` r
plot <- viz_treemap(
  data = degree_counts,
  group_var = "degree",
  value_var = "n",
  title = "Education Distribution",
  value_label = "Respondents",  # Label for the value in tooltips
  tooltip_suffix = " people"
)

plot
```

| Parameter        | Description                | Example                |
|------------------|----------------------------|------------------------|
| `value_label`    | Label for value in tooltip | `"Count"`, `"Revenue"` |
| `tooltip_prefix` | Text before value          | `"$"`, `"N = "`        |
| `tooltip_suffix` | Text after value           | `" units"`, `"%"`      |

For hierarchical treemaps, both group and subgroup appear in tooltips
automatically.

## Using with create_content()

### Basic Integration

``` r
content <- create_content(data = degree_counts, type = "treemap") %>%
  add_viz(
    group_var = "degree",
    value_var = "n",
    title = "Education Breakdown"
  )

content %>% preview()
```

Preview

Education Breakdown

### Multiple Treemaps

``` r
# Prepare different aggregations
sex_counts <- gss %>% count(sex, name = "n")
race_counts <- gss %>% count(race, name = "n")
region_counts <- gss %>% count(region, name = "n")

# Combine into one dataset with a category indicator
all_counts <- bind_rows(
  sex_counts %>% rename(category = sex) %>% mutate(type = "Sex"),
  race_counts %>% rename(category = race) %>% mutate(type = "Race"),
  region_counts %>% rename(category = region) %>% mutate(type = "Region")
)

content <- create_content(data = all_counts, type = "treemap") %>%
  add_viz(
    group_var = "category",
    value_var = "n",
    title = "By Sex",
    filter = ~ type == "Sex",
    tabgroup = "Demographics"
  ) %>%
  add_viz(
    group_var = "category",
    value_var = "n",
    title = "By Race",
    filter = ~ type == "Race",
    tabgroup = "Demographics"
  ) %>%
  add_viz(
    group_var = "category",
    value_var = "n",
    title = "By Region",
    filter = ~ type == "Region",
    tabgroup = "Demographics"
  )

content %>% preview()
```

Preview

Demographics

By Sex

By Race

By Region

## Data Preparation Tips

Treemaps need aggregated data. Here’s how to prepare GSS data:

### Simple Counts

``` r
# Count by one variable
gss %>% count(degree, name = "n")
#> # A tibble: 5 × 2
#>   degree                       n
#>   <fct>                    <int>
#> 1 less than high school      287
#> 2 high school               1476
#> 3 associate/junior college   290
#> 4 bachelor's                 708
#> 5 graduate                   465
```

### Hierarchical Counts

``` r
# Count by two variables for nested treemap
gss %>% count(sex, degree, name = "n")
#> # A tibble: 10 × 3
#>    sex    degree                       n
#>    <fct>  <fct>                    <int>
#>  1 male   less than high school      110
#>  2 male   high school                692
#>  3 male   associate/junior college   112
#>  4 male   bachelor's                 322
#>  5 male   graduate                   203
#>  6 female less than high school      177
#>  7 female high school                784
#>  8 female associate/junior college   178
#>  9 female bachelor's                 386
#> 10 female graduate                   262
```

### With Calculated Values

``` r
# Average age by education level
gss %>%
  group_by(degree) %>%
  summarize(avg_age = mean(age, na.rm = TRUE), .groups = "drop")
#> # A tibble: 5 × 2
#>   degree                   avg_age
#>   <fct>                      <dbl>
#> 1 less than high school       49.9
#> 2 high school                 49.8
#> 3 associate/junior college    49.8
#> 4 bachelor's                  51.1
#> 5 graduate                    52.4
```

## When to Use Treemaps

**Use treemaps when:** - Showing part-to-whole relationships - Comparing
sizes across many categories - Displaying hierarchical data - Space is
limited (more compact than bar charts)

**Use bar charts instead when:** - Precise comparisons are important -
You have few categories (\< 5) - Order matters (rankings)

## See Also

- [`?viz_treemap`](https://favstats.github.io/dashboardr/reference/viz_treemap.md) -
  Full function documentation
- [`vignette("bar_vignette")`](https://favstats.github.io/dashboardr/articles/bar_vignette.md) -
  For categorical comparisons
- [`vignette("content-collections")`](https://favstats.github.io/dashboardr/articles/content-collections.md) -
  For dashboard integration
