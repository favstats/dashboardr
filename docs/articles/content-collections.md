# Content Collections: Deep Dive

This vignette goes deep into content collections - the first layer of
dashboardr’s architecture. For a quick overview, see
[`vignette("getting-started")`](https://favstats.github.io/dashboardr/articles/getting-started.md).

Throughout this vignette, we use the [General Social
Survey](https://kjhealy.github.io/gssr/) as example data. Click below to
see the data loading code.

📂 **Data Setup** (click to expand)

``` r
library(dashboardr)
library(dplyr)
library(gssr)
library(haven)

# Load GSS data
data(gss_all)

# Latest wave only (for most examples)
gss <- gss_all %>%
  select(year, age, sex, race, degree, happy, polviews, wtssps,
         # Continuous variables for scatter plots
         educ, childs,
         # Confidence in institutions (for multi-question stackedbar example)
         confinan, conbus, coneduc, confed, conmedic) %>%
  filter(year == max(year, na.rm = TRUE)) %>%
  # Filter to substantive responses for core variables
  filter(
    happy %in% 1:3,        # very happy, pretty happy, not too happy
    polviews %in% 1:7,     # extremely liberal to extremely conservative
    !is.na(age), !is.na(sex), !is.na(race), !is.na(degree)
  ) %>%
  # Convert to factors with proper labels
  mutate(
    happy = droplevels(as_factor(happy)),
    polviews = droplevels(as_factor(polviews)),
    degree = droplevels(as_factor(degree)),
    sex = droplevels(as_factor(sex)),
    race = droplevels(as_factor(race)),
    # Confidence variables: convert non-substantive (IAP, don't know, etc.) to NA
    # Then use drop_na_vars = TRUE in visualizations
    confinan = ifelse(confinan %in% 1:3, confinan, NA),
    conbus = ifelse(conbus %in% 1:3, conbus, NA),
    coneduc = ifelse(coneduc %in% 1:3, coneduc, NA),
    confed = ifelse(confed %in% 1:3, confed, NA),
    conmedic = ifelse(conmedic %in% 1:3, conmedic, NA),
    # Convert to labeled factors
    confinan = factor(confinan, levels = 1:3, labels = c("a great deal", "only some", "hardly any")),
    conbus = factor(conbus, levels = 1:3, labels = c("a great deal", "only some", "hardly any")),
    coneduc = factor(coneduc, levels = 1:3, labels = c("a great deal", "only some", "hardly any")),
    confed = factor(confed, levels = 1:3, labels = c("a great deal", "only some", "hardly any")),
    conmedic = factor(conmedic, levels = 1:3, labels = c("a great deal", "only some", "hardly any"))
  )

# Full time series (for timeline examples)
gss_timeline <- gss_all %>%
  select(year, happy) %>%
  filter(happy %in% 1:3, !is.na(year)) %>%
  mutate(happy = droplevels(as_factor(happy)))
```

## 📦 What Content Collections Store

A content collection is a container that holds visualizations, content
blocks, interactive inputs, and layout helpers. Here’s what you can add:

| Category | Types | Functions |
|----|----|----|
| **[Visualizations](#visualization-types)** | Bar, Stacked Bar, Histogram, Density, Boxplot, Timeline, Heatmap, Scatter, Treemap, Map | [`add_viz()`](https://favstats.github.io/dashboardr/reference/add_viz.md), [`add_vizzes()`](https://favstats.github.io/dashboardr/reference/add_vizzes.md) |
| **[Content Blocks](#content-blocks)** | Text, Callouts, Cards, Accordions, Quotes, Badges, Metrics, Value Boxes, Code, Images, Videos, iframes, HTML | [`add_text()`](https://favstats.github.io/dashboardr/reference/add_text.md), [`add_callout()`](https://favstats.github.io/dashboardr/reference/add_callout.md), [`add_card()`](https://favstats.github.io/dashboardr/reference/add_card.md), [`add_accordion()`](https://favstats.github.io/dashboardr/reference/add_accordion.md), [`add_quote()`](https://favstats.github.io/dashboardr/reference/add_quote.md), [`add_badge()`](https://favstats.github.io/dashboardr/reference/add_badge.md), [`add_metric()`](https://favstats.github.io/dashboardr/reference/add_metric.md), [`add_value_box()`](https://favstats.github.io/dashboardr/reference/add_value_box.md), [`add_code()`](https://favstats.github.io/dashboardr/reference/add_code.md), [`add_image()`](https://favstats.github.io/dashboardr/reference/add_image.md), [`add_html()`](https://favstats.github.io/dashboardr/reference/add_html.md) |
| **[Tables & Custom Charts](#tables-and-custom-charts)** | gt Tables, Reactable, DT DataTables, Basic Tables, Custom Highcharter Charts | [`add_gt()`](https://favstats.github.io/dashboardr/reference/add_gt.md), [`add_reactable()`](https://favstats.github.io/dashboardr/reference/add_reactable.md), [`add_DT()`](https://favstats.github.io/dashboardr/reference/add_DT.md), [`add_table()`](https://favstats.github.io/dashboardr/reference/add_table.md), [`add_hc()`](https://favstats.github.io/dashboardr/reference/add_hc.md) |
| **Interactive Inputs** *(see [Advanced Features](https://favstats.github.io/dashboardr/articles/advanced-features.md))* | Dropdowns, Checkboxes, Sliders, Radio buttons | [`add_input_row()`](https://favstats.github.io/dashboardr/reference/add_input_row.md), [`add_input()`](https://favstats.github.io/dashboardr/reference/add_input.md) |
| **[Layout Helpers](#layout-helpers)** | Dividers, Spacers, Pagination markers | [`add_divider()`](https://favstats.github.io/dashboardr/reference/add_divider.md), [`add_spacer()`](https://favstats.github.io/dashboardr/reference/add_spacer.md), [`add_pagination()`](https://favstats.github.io/dashboardr/reference/add_pagination.md) |

Everything is stored in a unified `items` list, and you can inspect it
anytime:

``` r
content <- create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "degree", title = "Education") %>%
  add_text("## Analysis", "", "Key findings:") %>%
  add_callout(paste0("Sample size: ", nrow(gss)), type = "note")

print(content)
#> -- Content Collection ----------------------------------------------------------
#> 3 items | v data: 2997 rows x 15 cols
#> 
#> * [Viz] Education (bar) x=degree
#> i [Text] "## Analysis Key findings:"
#> ! [Callout]
```

``` r
preview(content)
```

Preview

Education

Analysis

Key findings:

**NOTE**

Sample size: 2997

## ⚙️ The Defaults System

The defaults system lets you **set once, use many times**. Instead of
repeating the same parameters for every visualization, you define them
once in
[`create_content()`](https://favstats.github.io/dashboardr/reference/create_content.md)
and they automatically apply to all
[`add_viz()`](https://favstats.github.io/dashboardr/reference/add_viz.md)
calls.

### Why Use Defaults?

Without defaults, you’d need to repeat parameters for every chart:

``` r
# Repetitive - don't do this!
content %>%
  add_viz(x_var = "age", type = "bar", color_palette = c("#3498DB"), bar_type = "percent") %>%
  add_viz(x_var = "sex", type = "bar", color_palette = c("#3498DB"), bar_type = "percent") %>%
  add_viz(x_var = "race", type = "bar", color_palette = c("#3498DB"), bar_type = "percent")
```

With defaults, you set them once and they flow through:

``` r
# Clean - do this!
create_content(data = gss, type = "bar", color_palette = c("#3498DB"), bar_type = "percent") %>%
  add_viz(x_var = "age") %>%
  add_viz(x_var = "sex") %>%
  add_viz(x_var = "race")
```

### Override Hierarchy

Parameters are resolved in this order (later wins):

1.  **Collection defaults** - set in
    [`create_content()`](https://favstats.github.io/dashboardr/reference/create_content.md)
2.  **Individual viz settings** - set in
    [`add_viz()`](https://favstats.github.io/dashboardr/reference/add_viz.md)

This means you can set sensible defaults for most charts, then override
specific ones as needed:

``` r
# Default: horizontal percent bars in blue
content <- create_content(
  data = gss,
  type = "bar",
  bar_type = "percent",
  horizontal = TRUE,
  color_palette = c("#3498DB")
) %>%
  # Uses all defaults
  add_viz(x_var = "degree", title = "Education") %>%
  # Override: vertical instead of horizontal
  add_viz(x_var = "race", title = "Race (vertical)", horizontal = FALSE) %>%
  # Override: count instead of percent
  add_viz(x_var = "sex", title = "Sex (count)", bar_type = "count")

print(content)
#> -- Content Collection ----------------------------------------------------------
#> 3 items | v data: 2997 rows x 15 cols
#> 
#> * [Viz] Education (bar) x=degree
#> * [Viz] Race (vertical) (bar) x=race
#> * [Viz] Sex (count) (bar) x=sex
```

``` r
content %>% preview()
```

Preview

Education

Race (vertical)

Sex (count)

### Any Parameter Can Be a Default

**Any parameter** you can pass to
[`add_viz()`](https://favstats.github.io/dashboardr/reference/add_viz.md)
can be set as a default in
[`create_content()`](https://favstats.github.io/dashboardr/reference/create_content.md).
Common ones include:

| Parameter | Description | Example Values |
|----|----|----|
| `type` | Visualization type | `"bar"`, `"histogram"`, `"stackedbar"`, `"timeline"` |
| `color_palette` | Colors for charts | `c("#3498DB", "#E74C3C")` |
| `bar_type` | Bar chart display | `"count"`, `"percent"`, `"mean"` |
| `horizontal` | Flip chart orientation | `TRUE`, `FALSE` |
| `weight_var` | Survey weight column | `"wtssps"` |
| `drop_na_vars` | Remove NA values | `TRUE`, `FALSE` |
| `stacked_type` | Stacked bar display | `"count"`, `"percent"` |
| `bins` | Histogram bins | `20`, `30`, `50` |
| `x_label` | Custom x-axis label | `"Age (years)"` |
| `y_label` | Custom y-axis label | `"Number of Respondents"` |
| `tooltip_suffix` | Text after tooltip values | `"%"`, `" people"` |
| `error_bars` | Error bar type (for `bar_type = "mean"`) | `"none"`, `"sd"`, `"se"`, `"ci"` |
| `value_var` | Numeric variable for means | `"score"`, `"income"` |

See the [Visualization Types](#visualization-types) section for all
parameters available for each chart type.

## 🏷️ Custom Labels and Tooltips

Every visualization supports custom axis labels and tooltip formatting.
These help make your charts clearer and more professional.

### Axis Labels

By default, `dashboardr` uses your variable names as axis labels.
Override them with `x_label` and `y_label`:

``` r
# Without custom labels (uses variable names)
create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "degree", title = "Education Levels") %>%
  preview()
```

Preview

Education Levels

``` r
# With custom labels (more polished)
create_content(data = gss, type = "bar") %>%
  add_viz(
    x_var = "degree", 
    title = "Education Levels",
    x_label = "Highest Degree Earned",
    y_label = "Number of Respondents"
  ) %>%
  preview()
```

Preview

Education Levels

For stacked charts, you can also set `stack_label` to customize the
legend title:

``` r
create_content(data = gss, type = "stackedbar") %>%
  add_viz(
    x_var = "degree", 
    stack_var = "sex",
    title = "Education by Gender",
    x_label = "Highest Degree",
    y_label = "Count",
    stack_label = "Gender"
  ) %>%
  preview()
```

Preview

Education by Gender

### Tooltip Customization

Tooltips are the interactive popups that appear when users hover over
data points. Customize them with prefix and suffix options:

| Parameter          | Description             | Example                 |
|--------------------|-------------------------|-------------------------|
| `tooltip_prefix`   | Text before the value   | `"Count: "`, `"$"`      |
| `tooltip_suffix`   | Text after the value    | `"%"`, `" respondents"` |
| `x_tooltip_suffix` | Text after x-axis value | `" years"`, `" USD"`    |

``` r
# Add units to tooltips
create_content(data = gss, type = "histogram") %>%
  add_viz(
    x_var = "age", 
    title = "Age Distribution",
    x_label = "Age",
    y_label = "Count",
    tooltip_suffix = " respondents",
    x_tooltip_suffix = " years old"
  ) %>%
  preview()
```

Preview

Age Distribution

``` r
# Percentage tooltips for stacked bars
create_content(data = gss, type = "stackedbar") %>%
  add_viz(
    x_var = "happy", 
    stack_var = "sex",
    title = "Happiness by Gender",
    stacked_type = "percent",
    y_label = "Percentage",
    tooltip_suffix = "%"
  ) %>%
  preview()
```

Preview

Happiness by Gender

**Tip**: Labels and tooltip settings can also be set as collection
defaults in
[`create_content()`](https://favstats.github.io/dashboardr/reference/create_content.md),
so they apply to all visualizations:

``` r
# Set tooltip suffix as a default for all charts
create_content(
  data = gss, 
  type = "bar",
  bar_type = "percent",
  tooltip_suffix = "%",
  y_label = "Percentage"
) %>%
  add_viz(x_var = "degree", title = "Education") %>%
  add_viz(x_var = "race", title = "Race") %>%
  preview()
```

Preview

Education

Race

## ➕ Combining Collections

### The + Operator

Merge collections while preserving structure:

``` r
demographics <- create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "degree", title = "Education", tabgroup = "Demo")

attitudes <- create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "happy", title = "Happiness", tabgroup = "Attitudes")

combined <- demographics + attitudes
print(combined)
#> -- Content Collection ----------------------------------------------------------
#> 2 items | v data: 2997 rows x 15 cols
#> 
#> > [Tab] Demo (1 viz)
#>   * [Viz] Education (bar) x=degree
#> > [Tab] Attitudes (1 viz)
#>   * [Viz] Happiness (bar) x=happy
```

``` r
combined %>% preview()
```

Preview

Demo

Attitudes

Education

Happiness

### combine_viz()

Same as `+` but in pipe-friendly form:

``` r
all_content <- demographics %>%
  combine_viz(attitudes)

print(all_content)
#> -- Content Collection ----------------------------------------------------------
#> 2 items | v data: 2997 rows x 15 cols
#> 
#> > [Tab] Demo (1 viz)
#>   * [Viz] Education (bar) x=degree
#> > [Tab] Attitudes (1 viz)
#>   * [Viz] Happiness (bar) x=happy
```

## 📊 Visualization Types

dashboardr supports 11 visualization types. Each is optimized for
different data patterns. For detailed documentation on each type, see
the individual vignettes: - [Bar
Charts](https://favstats.github.io/dashboardr/articles/bar_vignette.md)
\| [Stacked
Bars](https://favstats.github.io/dashboardr/articles/stackedbar_vignette.md) -
[Histograms](https://favstats.github.io/dashboardr/articles/histogram_vignette.md)
\| [Density
Plots](https://favstats.github.io/dashboardr/articles/density_vignette.md)
\| [Box
Plots](https://favstats.github.io/dashboardr/articles/boxplot_vignette.md) -
[Timelines](https://favstats.github.io/dashboardr/articles/timeline_vignette.md)
\|
[Heatmaps](https://favstats.github.io/dashboardr/articles/heatmap_vignette.md)
\| [Scatter
Plots](https://favstats.github.io/dashboardr/articles/scatter_vignette.md) -
[Treemaps](https://favstats.github.io/dashboardr/articles/treemap_vignette.md)
\|
[Maps](https://favstats.github.io/dashboardr/articles/map_vignette.md)

### Bar Charts

Bar charts are the workhorse of categorical data. Use them when you want
to compare counts or proportions across categories.

The simplest bar chart counts occurrences of each category:

``` r
create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "degree", title = "Education Levels") %>%
  preview()
```

Preview

Education Levels

Often you’ll want percentages instead of raw counts. Set
`bar_type = "percent"` to show proportions that sum to 100%:

``` r
create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "race", title = "Race Distribution", bar_type = "percent") %>%
  preview()
```

Preview

Race Distribution

To compare categories across groups, add `group_var`. This creates
side-by-side bars:

``` r
create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "degree", group_var = "sex", title = "Education by Sex") %>%
  preview()
```

Preview

Education by Sex

For long category labels, flip to horizontal with `horizontal = TRUE`:

``` r
create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "degree", title = "Education (Horizontal)", horizontal = TRUE) %>%
  preview()
```

Preview

Education (Horizontal)

#### Means with Error Bars

For numeric outcomes, use `bar_type = "mean"` with `error_bars` to show
statistical uncertainty:

``` r
# Sample data with numeric scores
score_data <- data.frame(
  group = rep(c("Control", "Treatment"), each = 50),
  score = c(rnorm(50, 70, 10), rnorm(50, 78, 12))
)

create_content(data = score_data, type = "bar") %>%
  add_viz(
    x_var = "group",
    value_var = "score",
    bar_type = "mean",
    error_bars = "ci",           # "sd", "se", or "ci"
    title = "Mean Scores (95% CI)"
  ) %>%
  preview()
```

Preview

Mean Scores (95% CI)

| Error Type          | Parameter           | Shows                             |
|---------------------|---------------------|-----------------------------------|
| Standard Deviation  | `error_bars = "sd"` | Spread of individual values       |
| Standard Error      | `error_bars = "se"` | Precision of mean estimate        |
| Confidence Interval | `error_bars = "ci"` | Range likely to contain true mean |

See the [Bar Chart
vignette](https://favstats.github.io/dashboardr/articles/bar_vignette.md)
for more options including grouped means and error bar styling.

### Stacked Bars

Stacked bars show composition - how a whole breaks down into parts. Use
`stack_var` to specify what fills each bar.

This shows the happiness distribution within each education level as raw
counts:

``` r
create_content(data = gss, type = "stackedbar") %>%
  add_viz(x_var = "degree", stack_var = "happy", title = "Happiness by Education") %>%
  preview()
```

Preview

Happiness by Education

For easier comparison across groups of different sizes, use
`stacked_type = "percent"`. Now each bar sums to 100%, making patterns
clearer:

``` r
create_content(data = gss, type = "stackedbar") %>%
  add_viz(x_var = "degree", stack_var = "happy", title = "Happiness by Education (%)",
          stacked_type = "percent") %>%
  preview()
```

Preview

Happiness by Education (%)

Horizontal stacked bars work well when you have many categories or long
labels:

``` r
create_content(data = gss, type = "stackedbar") %>%
  add_viz(x_var = "degree", stack_var = "happy", title = "Horizontal Stacked",
          stacked_type = "percent", horizontal = TRUE) %>%
  preview()
```

Preview

Horizontal Stacked

See the [Stacked Bar
vignette](https://favstats.github.io/dashboardr/articles/stackedbar_vignette.md)
for more options.

### Histograms

Histograms show the distribution of continuous variables. The `bins`
parameter controls granularity - more bins show more detail, fewer bins
show smoother patterns.

``` r
create_content(data = gss, type = "histogram") %>%
  add_viz(x_var = "age", title = "Age Distribution", bins = 25,
          x_label = "Age (years)", y_label = "Frequency") %>%
  preview()
```

Preview

Age Distribution

See the [Histogram
vignette](https://favstats.github.io/dashboardr/articles/histogram_vignette.md)
for more options.

### Density Plots

Density plots show smooth estimates of the distribution of a continuous
variable. They’re useful when you want a cleaner view of the
distribution shape compared to histograms.

``` r
create_content(data = gss, type = "density") %>%
  add_viz(x_var = "age", title = "Age Distribution (Density)",
          x_label = "Age (years)") %>%
  preview()
```

Preview

Age Distribution (Density)

Add `group_var` to compare distributions across groups:

``` r
create_content(data = gss, type = "density") %>%
  add_viz(x_var = "age", group_var = "sex", 
          title = "Age Distribution by Sex") %>%
  preview()
```

Preview

Age Distribution by Sex

See the [Density
vignette](https://favstats.github.io/dashboardr/articles/density_vignette.md)
for more options.

### Box Plots

Box plots (also called box-and-whisker plots) show the distribution of a
numeric variable across categories. They display the median, quartiles,
and outliers, making it easy to compare distributions.

``` r
create_content(data = gss, type = "boxplot") %>%
  add_viz(x_var = "degree", y_var = "age", 
          title = "Age Distribution by Education Level",
          x_label = "Highest Degree", y_label = "Age") %>%
  preview()
```

Preview

Age Distribution by Education Level

See the [Box Plot
vignette](https://favstats.github.io/dashboardr/articles/boxplot_vignette.md)
for more options.

### Multiple Stacked Bars (Likert Scales)

When you have multiple survey questions with the same response scale
(like Likert items), use `type = "stackedbar"` with `x_vars` to display
them together for comparison. This is perfect for “confidence in
institutions” batteries or agreement scales.

Use `x_vars` for the question columns and `x_var_labels` for readable
labels. Note: These confidence questions use a split-ballot design, so
~1/3 of respondents have NA (question not asked). We use
`drop_na_vars = TRUE` to exclude those:

``` r
create_content(data = gss, type = "stackedbar", drop_na_vars = TRUE) %>%
  add_viz(
    x_vars = c("confinan", "conbus", "coneduc", "confed", "conmedic"),
    x_var_labels = c("Banks & financial institutions", 
                     "Major companies",
                     "Education",
                     "Federal government",
                     "Medicine"),
    title = "Confidence in Institutions",
    stacked_type = "percent",
    horizontal = TRUE
  ) %>%
  preview()
```

Preview

Confidence in Institutions

See the [Stacked Bar
vignette](https://favstats.github.io/dashboardr/articles/stackedbar_vignette.md)
for more options including multi-question mode.

### Timeline

Timeline charts track how responses change over time. You need a time
variable (`time_var`) and a response variable (`y_var`). Unlike other
chart types, timelines need data spanning multiple time periods.

``` r
create_content(data = gss_timeline, type = "timeline") %>%
  add_viz(
    time_var = "year",
    y_var = "happy",
    title = "Happiness Over Time",
    chart_type = "line"
  ) %>%
  preview()
```

Preview

Happiness Over Time

Use `chart_type = "stacked_area"` for a stacked area chart, which
emphasizes cumulative patterns:

``` r
create_content(data = gss_timeline, type = "timeline") %>%
  add_viz(
    time_var = "year",
    y_var = "happy",
    title = "Happiness Trends (Stacked Area)",
    chart_type = "stacked_area"
  ) %>%
  preview()
```

Preview

Happiness Trends (Stacked Area)

See the [Timeline
vignette](https://favstats.github.io/dashboardr/articles/timeline_vignette.md)
for more options.

### Heatmap

Heatmaps visualize how a numeric value varies across two categorical
dimensions, displayed as a color-coded grid. Each cell shows the
aggregated value for that combination of categories.

**Required parameters:**

| Parameter   | Description                                |
|-------------|--------------------------------------------|
| `x_var`     | Categorical variable for columns           |
| `y_var`     | Categorical variable for rows              |
| `value_var` | Numeric variable to aggregate and color by |

**How it works:** The heatmap automatically aggregates `value_var` for
each unique combination of `x_var` and `y_var`. **By default, it
calculates the mean** - so if you have 50 people with a bachelor’s
degree who are “very happy”, the cell shows their average age.

``` r
create_content(data = gss, type = "heatmap") %>%
  add_viz(
    x_var = "degree",
    y_var = "happy",
    value_var = "age",
    title = "Average Age by Education & Happiness"
  ) %>%
  preview()
```

Preview

Average Age by Education & Happiness

**Key optional parameters:**

| Parameter | Description | Default |
|----|----|----|
| `agg_fun` | Aggregation function | `mean` |
| `color_palette` | Two colors for gradient (low, high) | `c("#FFFFFF", "#7CB5EC")` |
| `color_min` / `color_max` | Fixed color scale bounds | Auto from data |
| `x_order` / `y_order` | Custom category ordering | Auto |
| `data_labels_enabled` | Show values in cells | `TRUE` |
| `weight_var` | Column for weighted aggregation | `NULL` |

**Change the aggregation function** with `agg_fun`. Use any R function
that takes a vector and returns a single value:

``` r
# Median instead of mean
create_content(data = gss, type = "heatmap") %>%
  add_viz(
    x_var = "degree",
    y_var = "happy",
    value_var = "age",
    agg_fun = median,
    title = "Median Age by Education & Happiness"
  ) %>%
  preview()
```

Preview

Median Age by Education & Happiness

**Customize the color gradient** with `color_palette` - provide low and
high colors:

``` r
create_content(data = gss, type = "heatmap") %>%
  add_viz(
    x_var = "degree",
    y_var = "happy",
    value_var = "age",
    title = "Custom Colors (Red gradient)",
    color_palette = c("#FFF5F0", "#67000D")
  ) %>%
  preview()
```

Preview

Custom Colors (Red gradient)

**Use survey weights** for proper weighted means:

``` r
create_content(data = gss, type = "heatmap") %>%
  add_viz(
    x_var = "degree",
    y_var = "happy",
    value_var = "age",
    weight_var = "wtssps",
    title = "Weighted Average Age"
  ) %>%
  preview()
```

Preview

Weighted Average Age

See the [Heatmap
vignette](https://favstats.github.io/dashboardr/articles/heatmap_vignette.md)
for more options.

### Scatter Plots

Scatter plots show relationships between two numeric variables. Each
point represents one observation. Key parameters:

- `x_var` - Variable for horizontal axis
- `y_var` - Variable for vertical axis  
- `color_var` - Optional grouping variable for colored points
- `size_var` - Optional variable to control point sizes
- `show_trend` - Add a trend line (`TRUE`/`FALSE`)
- `alpha` - Point transparency (0-1)

``` r
# Filter to respondents with valid education and children data
scatter_data <- gss %>%
  filter(!is.na(educ), !is.na(childs))

create_content(data = scatter_data, type = "scatter") %>%
  add_viz(
    x_var = "educ",
    y_var = "childs",
    color_var = "sex",
    title = "Education vs Number of Children",
    x_label = "Years of Education",
    y_label = "Number of Children",
    alpha = 0.4
  ) %>%
  preview()
```

Preview

Education vs Number of Children

See the [Scatter Plot
vignette](https://favstats.github.io/dashboardr/articles/scatter_vignette.md)
for more options.

### Treemap

Treemaps display hierarchical data as nested rectangles. The size of
each rectangle represents its value - larger rectangles mean larger
values. Great for showing composition and proportions across many
categories.

**Important**: Treemaps require pre-aggregated data with a value column.
You typically need to
[`count()`](https://dplyr.tidyverse.org/reference/count.html) or
[`summarize()`](https://dplyr.tidyverse.org/reference/summarise.html)
your data first.

Key parameters:

- `group_var` - Primary grouping variable (creates the rectangles)
- `subgroup_var` - Optional secondary grouping for hierarchical treemaps
- `value_var` - Numeric column that determines rectangle size
- `color_var` - Optional variable for coloring (defaults to group_var)

``` r
# Treemaps need pre-aggregated data
degree_counts <- gss %>%
  count(degree, name = "n")

create_content(data = degree_counts, type = "treemap") %>%
  add_viz(
    group_var = "degree",
    value_var = "n",
    title = "Education Distribution"
  ) %>%
  preview()
```

Preview

Education Distribution

For hierarchical treemaps, add `subgroup_var`:

``` r
# Two-level hierarchy: degree within sex
degree_sex_counts <- gss %>%
  count(sex, degree, name = "n")

create_content(data = degree_sex_counts, type = "treemap") %>%
  add_viz(
    group_var = "sex",
    subgroup_var = "degree",
    value_var = "n",
    title = "Education by Sex"
  ) %>%
  preview()
```

Preview

Education by Sex

See the [Treemap
vignette](https://favstats.github.io/dashboardr/articles/treemap_vignette.md)
for more options.

### Map

Geographic maps (choropleths) display data across regions using color
intensity. Each region is shaded based on a numeric value, making it
easy to see geographic patterns at a glance.

**Key parameters:**

| Parameter | Description |
|----|----|
| `value_var` | Numeric column for color intensity |
| `join_var` | Column with geographic codes (must match map’s internal codes) |
| `map_type` | Map geography: `"custom/world"`, `"countries/us/us-all"`, etc. |
| `color_palette` | Two colors for gradient (low, high) |
| `tooltip_vars` | Variables to show in hover tooltips |

**Important**: Maps require geographic identifier codes that match the
map’s internal region codes:

- **World maps**: Use 2-letter ISO country codes (`iso2c`): “US”, “DE”,
  “FR”, etc.
- **US state maps**: Use postal codes: “CA”, “NY”, “TX”, etc.

``` r
# Load gapminder data and add ISO country codes
library(gapminder)
library(countrycode)

# Get latest year and convert country names to ISO codes
map_data <- gapminder %>%
  filter(year == max(year)) %>%
  mutate(iso2c = countrycode(country, "country.name", "iso2c")) %>%
  filter(!is.na(iso2c))
```

Now create a world map showing life expectancy:

``` r
create_content(data = map_data, type = "map") %>%
  add_viz(
    value_var = "lifeExp",
    join_var = "iso2c",
    map_type = "custom/world",
    title = "Life Expectancy by Country (2007)",
    color_palette = c("#fee5d9", "#a50f15")
  ) %>%
  preview()
```

Preview

Life Expectancy by Country (2007)

**Custom color palettes** - use any two colors for the gradient:

``` r
create_content(data = map_data, type = "map") %>%
  add_viz(
    value_var = "gdpPercap",
    join_var = "iso2c",
    map_type = "custom/world",
    title = "GDP per Capita",
    color_palette = c("#f7fbff", "#08306b")  # Light to dark blue
  ) %>%
  preview()
```

Preview

GDP per Capita

**Available map types:**

| Map Type                 | Region                  | Join Key                  |
|--------------------------|-------------------------|---------------------------|
| `"custom/world"`         | World countries         | `iso2c` (2-letter ISO)    |
| `"custom/world-highres"` | World (high resolution) | `iso2c`                   |
| `"countries/us/us-all"`  | US states               | Postal codes (“CA”, “NY”) |
| `"countries/de/de-all"`  | German states           | State codes               |
| `"custom/europe"`        | European countries      | `iso2c`                   |

See the [Map
vignette](https://favstats.github.io/dashboardr/articles/map_vignette.md)
for more options.

## 📁 Organizing with Tabgroups

Tabgroups create tabbed interfaces in your dashboard:

``` r
content <- create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "degree", title = "Education", tabgroup = "demographics") %>%
  add_viz(x_var = "race", title = "Race", tabgroup = "demographics") %>%
  add_viz(x_var = "happy", title = "Happiness", tabgroup = "attitudes") %>%
  add_viz(x_var = "polviews", title = "Politics", tabgroup = "attitudes")

print(content)
#> -- Content Collection ----------------------------------------------------------
#> 4 items | v data: 2997 rows x 15 cols
#> 
#> > [Tab] demographics (2 vizs)
#>   * [Viz] Education (bar) x=degree
#>   * [Viz] Race (bar) x=race
#> > [Tab] attitudes (2 vizs)
#>   * [Viz] Happiness (bar) x=happy
#>   * [Viz] Politics (bar) x=polviews
```

### Nested Tabgroups

For complex dashboards, you can create **multi-level tab hierarchies**
using `/` as a separator:

``` r
nested <- create_content(data = gss, type = "bar") %>%
  # Top-level: "Demographics" with two sub-tabs
  add_viz(x_var = "degree", title = "Education Level", 
          tabgroup = "Demographics/Education") %>%
  add_viz(x_var = "race", title = "Race Distribution", 
          tabgroup = "Demographics/Race") %>%
  add_viz(x_var = "age", title = "Age Distribution", 
          tabgroup = "Demographics/Age") %>%
  # Top-level: "Attitudes" with sub-tabs
  add_viz(x_var = "happy", title = "General Happiness", 
          tabgroup = "Attitudes/Wellbeing") %>%
  add_viz(x_var = "polviews", title = "Political Views", 
          tabgroup = "Attitudes/Politics")

print(nested)
#> -- Content Collection ----------------------------------------------------------
#> 5 items | v data: 2997 rows x 15 cols
#> 
#> > [Tab] Demographics (3 tabs)
#>   > [Tab] Education (1 viz)
#>     * [Viz] Education Level (bar) x=degree
#>   > [Tab] Race (1 viz)
#>     * [Viz] Race Distribution (bar) x=race
#>   > [Tab] Age (1 viz)
#>     * [Viz] Age Distribution (bar) x=age
#> > [Tab] Attitudes (2 tabs)
#>   > [Tab] Wellbeing (1 viz)
#>     * [Viz] General Happiness (bar) x=happy
#>   > [Tab] Politics (1 viz)
#>     * [Viz] Political Views (bar) x=polviews
```

``` r
preview(nested)
```

Preview

Demographics

Attitudes

Education

Race

Age

Education Level

Race Distribution

Age Distribution

Wellbeing

Politics

General Happiness

Political Views

### Custom Tab Labels

Replace tabgroup IDs with readable labels using
[`set_tabgroup_labels()`](https://favstats.github.io/dashboardr/reference/set_tabgroup_labels.md):

``` r
labeled <- create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "degree", title = "Education", tabgroup = "demo") %>%
  add_viz(x_var = "happy", title = "Happiness", tabgroup = "attitudes") %>%
  set_tabgroup_labels(
    demo = "Demographics",
    attitudes = "Attitudes & Values"
  )

print(labeled)
#> -- Content Collection ----------------------------------------------------------
#> 2 items | v data: 2997 rows x 15 cols
#> 
#> > [Tab] demo (1 viz)
#>   * [Viz] Education (bar) x=degree
#> > [Tab] attitudes (1 viz)
#>   * [Viz] Happiness (bar) x=happy
```

``` r
labeled %>% preview()
```

Preview

Demographics

Attitudes & Values

Education

Happiness

## 📝 Content Blocks

Content blocks add non-visualization elements to your collections.

### Text Blocks

[`add_text()`](https://favstats.github.io/dashboardr/reference/add_text.md)
is a flexible function for adding markdown content. It has several smart
features:

**Multiple arguments become lines** - Pass as many strings as you want,
and they join with newlines:

``` r
create_content() %>%
  add_text(
    "## Survey Overview",
    "",
    "The General Social Survey (GSS) has been conducted since 1972.",
    "It covers demographics, attitudes, and social behaviors."
  ) %>%
  preview()
```

Preview

Survey Overview

The General Social Survey (GSS) has been conducted since 1972. It covers
demographics, attitudes, and social behaviors.

**Use empty strings for spacing** - An empty `""` creates a paragraph
break:

``` r
create_content() %>%
  add_text(
    "## Section One",
    "",
    "First paragraph of content.",
    "",
    "## Section Two",
    "",
    "Second paragraph with a gap above."
  ) %>%
  preview()
```

Preview

Section One

First paragraph of content.

Section Two

Second paragraph with a gap above.

**Full Markdown support** - Headers, lists, bold, italic, links, and
more:

``` r
text_example <- create_content() %>%
  add_text(
    "## Key Findings",
    "",
    "This analysis reveals **three important patterns**:",
    "",
    "1. Education correlates with happiness",
    "2. Age distribution is *roughly normal*",
    "3. Political views show [polarization](https://en.wikipedia.org/wiki/Political_polarization)",
    "",
    "### Methodology Note",
    "",
    "> Data weighted using GSS survey weights"
  )

print(text_example)
#> -- Content Collection ----------------------------------------------------------
#> 1 items | x no data
#> 
#> i [Text] "## Key Findings This analysis reveals **three i..."
```

``` r
text_example %>% preview()
```

Preview

Key Findings

This analysis reveals **three important patterns**:

1.  Education correlates with happiness
2.  Age distribution is *roughly normal*
3.  Political views show
    [polarization](https://en.wikipedia.org/wiki/Political_polarization)

Methodology Note

> Data weighted using GSS survey weights

**Works standalone or in pipes** - Call it directly or chain it:

``` r
# Standalone - returns a content block
block <- add_text("# Title")

# In a pipe - adds to existing collection
content %>% add_text("More content here")
```

### Callouts

Callouts draw attention to specific information with colored boxes and
icons. Use them to highlight notes, tips, warnings, or critical
information that readers shouldn’t miss.

**Five types for different purposes:**

| Type        | Use for                                   | Color  |
|-------------|-------------------------------------------|--------|
| `note`      | Additional context, background info       | Blue   |
| `tip`       | Helpful suggestions, best practices       | Green  |
| `warning`   | Potential issues, things to watch out for | Yellow |
| `caution`   | Proceed carefully, possible problems      | Orange |
| `important` | Critical information, must-read           | Red    |

``` r
callout_gallery <- create_content() %>%
  add_callout("Notes provide additional context or information.", type = "note", title = "Note") %>%
  add_callout("Tips offer helpful suggestions to improve workflow.", type = "tip", title = "Pro Tip") %>%
  add_callout("Warnings alert users to potential issues.", type = "warning", title = "Warning") %>%
  add_callout("Caution indicates something that needs careful attention.", type = "caution", title = "Caution") %>%
  add_callout("Important highlights critical information.", type = "important", title = "Important")

print(callout_gallery)
#> -- Content Collection ----------------------------------------------------------
#> 5 items | x no data
#> 
#> ! [Callout] Note
#> ! [Callout] Pro Tip
#> ! [Callout] Warning
#> ! [Callout] Caution
#> ! [Callout] Important
```

``` r
callout_gallery %>% preview()
```

Preview

**Note**

Notes provide additional context or information.

**Pro Tip**

Tips offer helpful suggestions to improve workflow.

**Warning**

Warnings alert users to potential issues.

**Caution**

Caution indicates something that needs careful attention.

**Important**

Important highlights critical information.

**Custom titles are optional** - If you omit `title`, the type name is
used:

``` r
create_content() %>%
  add_callout("Sample size is smaller than recommended for this analysis.", type = "warning") %>%
  preview()
```

Preview

**WARNING**

Sample size is smaller than recommended for this analysis.

**Practical example** - Combine callouts with visualizations:

``` r
create_content(data = gss, type = "bar") %>%
  add_callout("This chart shows unweighted counts. See methodology for weighted estimates.", type = "note") %>%
  add_viz(x_var = "degree", title = "Education Distribution") %>%
  add_callout("Education data may reflect selection bias in survey response rates.", type = "tip", title = "Interpretation Tip") %>%
  preview()
```

Preview

**NOTE**

This chart shows unweighted counts. See methodology for weighted
estimates.

Education Distribution

**Interpretation Tip**

Education data may reflect selection bias in survey response rates.

### Cards

Styled content containers with optional titles:

``` r
card_example <- create_content() %>%
  add_card(
    title = "Key Finding",
    text = "Education level shows a strong positive correlation with reported happiness levels across all demographic groups."
  ) %>%
  add_card(
    text = "Cards without titles work too. Great for quick content blocks."
  )

print(card_example)
#> -- Content Collection ----------------------------------------------------------
#> 2 items | x no data
#> 
#> [x] [Card] Key Finding
#> [x] [Card]
```

``` r
card_example %>% preview()
```

Preview

Key Finding

Education level shows a strong positive correlation with reported
happiness levels across all demographic groups.

Cards without titles work too. Great for quick content blocks.

### Accordions

Collapsible sections for supplementary or detailed content:

``` r
accordion_example <- create_content() %>%
  add_accordion(
    title = "Click to expand: Methodology",
    text = "This analysis uses weighted survey data from NORC. Sample size: 21,788 respondents."
  ) %>%
  add_accordion(
    title = "Click to expand: Data Sources",
    text = "General Social Survey (GSS), collected annually since 1972."
  )

print(accordion_example)
#> -- Content Collection ----------------------------------------------------------
#> 2 items | x no data
#> 
#> = [Accordion] Click to expand: Methodology
#> = [Accordion] Click to expand: Data Sources
```

``` r
accordion_example %>% preview()
```

Preview

Click to expand: Methodology

This analysis uses weighted survey data from NORC. Sample size: 21,788
respondents.

Click to expand: Data Sources

General Social Survey (GSS), collected annually since 1972.

### Quotes

Block quotes with optional attribution:

``` r
quote_example <- create_content() %>%
  add_quote(
    quote = "The only true wisdom is in knowing you know nothing.",
    attribution = "Socrates"
  )

print(quote_example)
#> -- Content Collection ----------------------------------------------------------
#> 1 items | x no data
#> 
#> * [quote]
```

``` r
quote_example %>% preview()
```

Preview

> The only true wisdom is in knowing you know nothing.
>
> \<U+2014\> Socrates

### Badges

Inline status indicators:

``` r
badge_example <- create_content() %>%
  add_text("Status indicators:") %>%
  add_badge("Complete", color = "success") %>%
  add_badge("In Progress", color = "warning") %>%
  add_badge("Not Started", color = "danger") %>%
  add_badge("Info", color = "info") %>%
  add_badge("Primary", color = "primary") %>%
  add_badge("Secondary", color = "secondary")

print(badge_example)
#> -- Content Collection ----------------------------------------------------------
#> 7 items | x no data
#> 
#> i [Text] "Status indicators:"
#> * [badge]
#> * [badge]
#> * [badge]
#> * [badge]
#> * [badge]
#> * [badge]
```

``` r
badge_example %>% preview()
```

Preview

Status indicators:

Complete In Progress Not Started Info Primary Secondary

### Metrics

Single KPI value boxes:

``` r
metric_example <- create_content() %>%
  add_metric(
    title = "Total Respondents",
    value = "21,788",
    icon = "ph:users"
  )

print(metric_example)
#> -- Content Collection ----------------------------------------------------------
#> 1 items | x no data
#> 
#> * [metric] Total Respondents
```

``` r
metric_example %>% preview()
```

Preview

ph:users

21,788

Total Respondents

### Value Boxes

Custom-styled value boxes with branding:

``` r
value_box_example <- create_content() %>%
  add_value_box(
    title = "Revenue",
    value = "$1.2M",
    bg_color = "#27AE60"
  )

print(value_box_example)
#> -- Content Collection ----------------------------------------------------------
#> 1 items | x no data
#> 
#> * [value_box] Revenue
```

``` r
value_box_example %>% preview()
```

Preview

Revenue

\$1.2M

### Value Box Rows

Multiple value boxes in a responsive row:

``` r
value_row_example <- create_content() %>%
  add_value_box_row() %>%
    add_value_box(title = "Users", value = "12,345", bg_color = "#3498DB") %>%
    add_value_box(title = "Sessions", value = "45,678", bg_color = "#9B59B6") %>%
    add_value_box(title = "Conversion", value = "3.2%", bg_color = "#E74C3C") %>%
  end_value_box_row()

print(value_row_example)
#> -- Content Collection ----------------------------------------------------------
#> 1 items | x no data
#> 
#> * [value_box_row]
```

``` r
value_row_example %>% preview()
```

Preview

Users

12,345

Sessions

45,678

Conversion

3.2%

### Code Blocks

Syntax-highlighted code snippets:

``` r
code_example <- create_content() %>%
  add_code(
    code = "library(dashboardr)\n\ncreate_content(data = df) %>%\n  add_viz(type = 'bar', x_var = 'category')",
    language = "r"
  )

print(code_example)
#> -- Content Collection ----------------------------------------------------------
#> 1 items | x no data
#> 
#> * [Code]
```

``` r
code_example %>% preview()
```

Preview

```
library(dashboardr)

create_content(data = df) %>%
  add_viz(type = 'bar', x_var = 'category')
```

### Images

Add images with optional captions. **Use full URLs** for images to
ensure they display on GitHub Pages:

``` r
image_example <- create_content() %>%
  add_image(
    src = "https://favstats.github.io/dashboardr/reference/figures/logo.svg",
    alt = "dashboardr Logo",
    caption = "The dashboardr package logo",
    width = "200px"
  )

print(image_example)
#> -- Content Collection ----------------------------------------------------------
#> 1 items | x no data
#> 
#> (*) [Image]
image_example %>% preview()
```

Preview

![The dashboardr package
logo](https://favstats.github.io/dashboardr/reference/figures/logo.svg)

The dashboardr package logo

> **Tip**: Always use absolute URLs (starting with `https://`) for
> images in vignettes. Local file paths like `"logo.png"` work during
> development but won’t display on GitHub Pages or pkgdown sites.

### Videos

For local video files, use
[`add_video()`](https://favstats.github.io/dashboardr/reference/add_video.md) -
but note these won’t work on GitHub Pages unless hosted elsewhere:

``` r
# Local video (works locally, not on GitHub)
create_content() %>%
  add_video(
    src = "presentation.mp4",
    caption = "Project overview video"
  )
```

For video content, use YouTube or Vimeo embeds via
[`add_iframe()`](https://favstats.github.io/dashboardr/reference/add_iframe.md) -
this is more reliable than direct video files:

``` r
# YouTube embed (recommended approach)
video_example <- create_content() %>%
  add_iframe(
    src = "https://www.youtube.com/embed/dQw4w9WgXcQ",
    height = "315px"
  )

print(video_example)
#> -- Content Collection ----------------------------------------------------------
#> 1 items | x no data
#> 
#> * [iframe]
video_example %>% preview()
```

Preview

# Er is een fout opgetreden.

JavaScript kan niet worden uitgevoerd.

### iframes

Embed external content like interactive maps, dashboards, or other web
pages:

``` r
iframe_example <- create_content() %>%
  add_iframe(
    src = "https://www.openstreetmap.org/export/embed.html?bbox=-0.1%2C51.5%2C0.0%2C51.52",
    height = "300px"
  )

print(iframe_example)
#> -- Content Collection ----------------------------------------------------------
#> 1 items | x no data
#> 
#> * [iframe]
iframe_example %>% preview()
```

Preview

![](data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMCIgaGVpZ2h0PSIwIiBjbGFzcz0iZW5kLTEwMCBwb3NpdGlvbi1hYnNvbHV0ZSI+CiAgPGRlZnM+CiAgICA8bGluZWFyZ3JhZGllbnQgaWQ9ImZpbGwiIHgxPSIwIiB4Mj0iMCIgeTE9IjAiIHkyPSI0MCIgZ3JhZGllbnR1bml0cz0idXNlclNwYWNlT25Vc2UiPgogICAgICA8c3RvcCBvZmZzZXQ9IjAiIHN0b3AtY29sb3I9IiNhYWE2Ij48L3N0b3A+CiAgICAgIDxzdG9wIG9mZnNldD0iMSIgc3RvcC1jb2xvcj0iIzIyMjQiPjwvc3RvcD4KICAgIDwvbGluZWFyZ3JhZGllbnQ+CiAgICA8bGluZWFyZ3JhZGllbnQgaWQ9InN0cm9rZSIgeDE9IjAiIHgyPSIwIiB5MT0iMCIgeTI9IjIwIiBncmFkaWVudHVuaXRzPSJ1c2VyU3BhY2VPblVzZSI+CiAgICAgIDxzdG9wIG9mZnNldD0iMCIgc3RvcC1jb2xvcj0iIzY2NjYiPjwvc3RvcD4KICAgICAgPHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjNDQ0OCI+PC9zdG9wPgogICAgPC9saW5lYXJncmFkaWVudD4KICAgIDxjbGlwcGF0aCBpZD0icGluLWNsaXAiPgogICAgICA8cGF0aCBpZD0icGluLXBhdGgiIGQ9Ik0xMi41IDQwIDIuOTQgMjEuNjQ0OEMxLjQ3IDE4LjgyMjQgMCAxNiAwIDEyLjVhMTIuNSAxMi41IDAgMCAxIDI1IDBjMCAzLjUtMS40NyA2LjMyMjQtMi45NCA5LjE0NDh6IiAvPgogICAgPC9jbGlwcGF0aD4KICAgIDxpbWFnZSBpZD0icGluLXNoYWRvdyIgeD0iLTEiIGhyZWY9Ii9hc3NldHMvbGVhZmxldC9kaXN0L2ltYWdlcy9tYXJrZXItc2hhZG93LWEyZDk0NDA2YmExOThmNjFmNjhhNzFlZDhmOWY5YzcwMTEyMmMwYzMzYjc3NWQ5OTBlZGNlYWU0YWVjZTU2N2YucG5nIj48L2ltYWdlPgoKCiAgICAgIDxwYXRoIGlkPSJkb3QtcGF0aCIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBmaWxsPSIjZmZmIiBkPSJNMTEuNSAxMGExIDEgMCAwIDAgMiA1IDEgMSAwIDAgMC0yLTUiIC8+CiAgICAgIDxnIGlkPSJwaW4tZG90IiBjbGlwLXBhdGg9InVybCgjcGluLWNsaXApIj4KICAgICAgICA8dXNlIGhyZWY9IiNwaW4tcGF0aCIgZmlsbD0iY3VycmVudENvbG9yIiAvPgogICAgICAgIDx1c2UgaHJlZj0iI3Bpbi1wYXRoIiBmaWxsPSJ1cmwoI2ZpbGwpIiAvPgogICAgICAgIDxnIHN0cm9rZT0iI2ZmZiIgb3BhY2l0eT0iMC4xMjIiPgogICAgICAgICAgPHVzZSBocmVmPSIjcGluLXBhdGgiIGZpbGw9Im5vbmUiIHN0cm9rZS13aWR0aD0iNC40IiAvPgogICAgICAgICAgPHVzZSBocmVmPSIjZG90LXBhdGgiIHN0cm9rZS13aWR0aD0iNy4yIiAvPgogICAgICAgIDwvZz4KICAgICAgICA8ZyBzdHJva2U9ImN1cnJlbnRDb2xvciI+CiAgICAgICAgICA8dXNlIGhyZWY9IiNwaW4tcGF0aCIgZmlsbD0ibm9uZSIgc3Ryb2tlLXdpZHRoPSIyLjIiIC8+CiAgICAgICAgICA8dXNlIGhyZWY9IiNkb3QtcGF0aCIgc3Ryb2tlLXdpZHRoPSI1IiAvPgogICAgICAgIDwvZz4KICAgICAgICA8ZyBzdHJva2U9InVybCgjc3Ryb2tlKSI+CiAgICAgICAgICA8dXNlIGhyZWY9IiNwaW4tcGF0aCIgZmlsbD0ibm9uZSIgc3Ryb2tlLXdpZHRoPSIyLjIiIC8+CiAgICAgICAgICA8dXNlIGhyZWY9IiNkb3QtcGF0aCIgc3Ryb2tlLXdpZHRoPSI1IiAvPgogICAgICAgIDwvZz4KICAgICAgICA8dXNlIGhyZWY9IiNkb3QtcGF0aCIgc3Ryb2tlPSIjZmZmIiBzdHJva2Utd2lkdGg9IjIuOCIgLz4KICAgICAgPC9nPgogIDwvZGVmcz4KPC9zdmc+)

### Raw HTML

Insert custom HTML when needed:

``` r
html_example <- create_content() %>%
  add_html('<div style="background: linear-gradient(to right, #667eea, #764ba2); color: white; padding: 20px; border-radius: 8px; text-align: center;"><h3>Custom HTML Block</h3><p>Style anything with raw HTML!</p></div>')

print(html_example)
#> -- Content Collection ----------------------------------------------------------
#> 1 items | x no data
#> 
#> * [html]
```

``` r
html_example %>% preview()
```

Preview

### Custom HTML Block

Style anything with raw HTML!

## 📊 Tables and Custom Charts

Beyond visualizations created with
[`add_viz()`](https://favstats.github.io/dashboardr/reference/add_viz.md),
you can embed tables and custom charts directly into content
collections.

### gt Tables

Use
[`add_gt()`](https://favstats.github.io/dashboardr/reference/add_gt.md)
to embed publication-quality tables created with the [gt
package](https://gt.rstudio.com/):

``` r
# Create a summary table
summary_data <- gss %>%
  group_by(degree) %>%
  summarise(
    n = n(),
    mean_age = round(mean(age, na.rm = TRUE), 1),
    .groups = "drop"
  )

gt_example <- create_content() %>%
  add_text("### Summary Statistics by Education") %>%
  add_gt(
    gt::gt(summary_data) %>%
      gt::cols_label(degree = "Education", n = "Count", mean_age = "Mean Age")
  )
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00A1>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00A2>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00A3>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00A4>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00A5>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00A6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00A7>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00A8>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00A9>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00AA>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00AB>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00AC>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00AE>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00AF>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00B0>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00B1>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00B2>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00B3>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00B4>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00B5>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00B6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00B7>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00B9>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00BA>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00BB>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00BC>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00BD>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00BE>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00BF>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00C0>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00C1>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00C2>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00C3>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00C4>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00C5>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00C6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00C7>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00C8>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00C9>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00CA>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00CB>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00CC>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00CD>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00CE>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00CF>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00D0>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00D1>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00D2>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00D3>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00D4>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00D5>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00D6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00D7>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00D8>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00D9>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00DA>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00DB>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00DC>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00DD>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00DE>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00DF>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00E0>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00E1>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00E2>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00E3>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00E4>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00E5>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00E6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00E7>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00E8>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00E9>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00EA>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00EB>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00EC>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00ED>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00EE>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00EF>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00F0>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00F1>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00F2>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00F3>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00F4>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00F5>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00F6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00F7>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00F8>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00F9>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00FA>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00FB>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00FC>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00FD>:' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00FE>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+00FF>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0100>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0101>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0102>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0103>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0104>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0105>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0108>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0109>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+010A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+010B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+010C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+010D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+010E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+010F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0110>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0111>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0112>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0113>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0114>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0115>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0116>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0117>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0118>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0119>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+011A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+011B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+011C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+011D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+011E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+011F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0120>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0121>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0122>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0123>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0124>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0125>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0126>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0127>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0128>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0129>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+012A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+012B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+012C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+012D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+012E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+012F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0130>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0131>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0132>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0133>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0134>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0135>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0136>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0137>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0138>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0139>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+013A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+013B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+013C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+013D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+013E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+013F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0140>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0141>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0142>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0143>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0144>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0145>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0146>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0147>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0148>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0149>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+014A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+014B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+014C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+014D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+014E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+014F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0150>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0151>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0152>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0153>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0154>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0155>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0156>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0157>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0158>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0159>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+015A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+015B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+015C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+015D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+015E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+015F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0160>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0161>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0162>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0163>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0164>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0165>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0166>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0167>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0168>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0169>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+016A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+016B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+016C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+016D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+016E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+016F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0170>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0171>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0172>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0173>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0174>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0175>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0176>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0177>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0178>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0179>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+017A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+017B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+017C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+017D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+017E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0192>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0195>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+019E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+01E7>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+01F5>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0228>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0229>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0259>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+025B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0278>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0294>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+029E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+02B7>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+02C6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+02C7>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+02D8>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+02D9>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+02DA>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+02DB>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+02DC>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+02DD>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0307>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0308>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0386>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0388>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0389>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+038A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+038C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+038E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+038F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0390>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0391>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0392>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0393>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0394>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0398>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+039B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+039E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03A0>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03A3>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03A5>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03A6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03A8>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03A9>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03AA>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03AB>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03AC>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03AD>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03AE>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03AF>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03B0>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03CA>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03CB>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03CC>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03CD>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03CE>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0251>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03B1>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03B2>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03B3>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03B4>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03B5>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03B6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03B7>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03B8>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03B9>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03BA>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03BB>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03BC>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03BD>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03BE>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03BF>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03C0>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03C1>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03C2>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03C3>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03C4>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03C5>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03C6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03C7>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03C8>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03C9>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03D1>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03D2>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03D5>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03D6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03F0>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03F1>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03F5>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+03F6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0400>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0401>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0402>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0403>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0404>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0405>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0406>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0407>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0408>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0409>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+040A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+040B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+040C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+040D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+040E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+040F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0410>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0411>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0412>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0413>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0414>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0415>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0416>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0417>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0418>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0419>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+041A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+041B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+041C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+041D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+041E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+041F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0420>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0421>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0422>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0423>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0424>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0425>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0426>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0427>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0428>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0429>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+042A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+042B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+042C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+042D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+042E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+042F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0430>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0431>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0432>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0433>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0434>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0435>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0436>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0437>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0438>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0439>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+043A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+043B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+043C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+043D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+043E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+043F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0440>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0441>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0442>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0443>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0444>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0445>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0446>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0447>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0448>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0449>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+044A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+044B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+044C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+044D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+044E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+044F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0450>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0451>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0452>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0453>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0454>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0455>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0456>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0457>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0458>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0459>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+045A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+045B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+045C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+045D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+045E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+045F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0460>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0461>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0462>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0463>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0464>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0465>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0466>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0467>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0468>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0469>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+046A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+046B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+046C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+046D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+046E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+046F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0470>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0471>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0472>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0473>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0474>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0475>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0476>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0477>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0478>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0479>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+047A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+047B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+047C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+047D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+047E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+047F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0480>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0481>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0482>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0488>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0489>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+048C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+048D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+048E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+048F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0490>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0491>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0492>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0493>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0494>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0495>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0496>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0497>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0498>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0499>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+049A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+049B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+049C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+049D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+049E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+049F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04A0>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04A1>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04A2>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04A3>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04A4>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04A5>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04A6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04A7>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04A8>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04A9>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04AA>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04AB>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04AC>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04AD>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04AE>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04AF>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04B0>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04B1>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04B2>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04B3>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04B4>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04B5>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04B6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04B7>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04B8>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04B9>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04BA>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04BB>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04BC>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04BD>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04BE>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04BF>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04C0>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04C1>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04C2>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04C3>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04C4>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04C5>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04C6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04C7>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04C8>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04CB>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04CC>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04CD>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04CE>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04D0>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04D1>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04D2>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04D3>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04D4>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04D5>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04D6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04D7>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04D8>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04D9>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04DA>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04DB>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04DC>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04DD>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04DE>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04DF>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04E0>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04E1>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04E2>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04E3>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04E4>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04E5>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04E6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04E7>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04E8>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04E9>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04EC>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04ED>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04EE>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04EF>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04F0>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04F1>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04F2>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04F3>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04F4>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04F5>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04F6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04F7>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04F8>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04F9>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04FA>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04FB>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04FC>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04FD>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04FE>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+04FF>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+0E3F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2000>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2001>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2002>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2003>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2004>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2005>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2006>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2007>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2008>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2009>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+200A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+200C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2011>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2013>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2014>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2015>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2016>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2018>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2019>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+201A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+201C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+201D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+201E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2020>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2021>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2022>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2026>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2030>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2031>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2032>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2033>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2034>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2035>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2039>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+203A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+203B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+203D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2044>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+204E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2052>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2057>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+205F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2060>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+20A1>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+20A4>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+20A6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+20A9>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+20AB>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+20AC>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+20B1>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2102>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2103>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2109>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+210A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+210B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+210C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+210D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+210E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+210F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2110>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2111>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2112>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2113>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2115>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2116>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2117>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2118>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+211E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2119>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+211A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+211B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+211C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+211D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2120>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2122>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2124>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2126>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2127>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2128>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+212A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+212B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+212C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+212D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+212E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+212F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2130>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2131>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2133>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2134>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2135>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2136>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2137>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2138>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2153>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2154>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2155>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2156>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2157>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2158>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2159>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+215A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+215B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+215C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+215D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+215E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2190>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2191>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2192>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2193>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2194>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2195>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2196>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2197>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2198>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2199>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+219A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+219B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+219C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+219D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+219E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21A0>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21A2>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21A3>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21A6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21A9>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21AA>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21AB>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21AC>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21AD>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21AE>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21B0>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21B1>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21B6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21B7>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21BA>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21BB>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21BC>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21BD>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21BE>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21BF>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21C0>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21C1>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21C2>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21C3>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21C4>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21C5>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21C6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21C7>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21C8>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21C9>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21CA>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21CB>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21CC>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21CD>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21CE>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21CF>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21D0>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21D1>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21D2>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21D3>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21D4>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21D5>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21DA>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21DB>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21DD>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+21F5>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2200>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2201>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2202>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2203>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2204>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2205>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2206>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2207>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2208>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2209>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+220A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+220B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+220C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+220D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+220E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+220F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2210>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2211>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2212>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2213>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2214>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2215>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2216>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2217>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2218>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2219>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+221A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+221B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+221C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+221D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+221E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+221F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2220>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2221>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2222>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2223>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2224>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2225>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2226>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2227>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2228>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2229>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+222A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+222B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+222C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+222D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+222E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+222F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2230>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2231>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2234>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2235>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+223A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+223B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+223C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+223D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+223E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2240>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2241>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2243>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2244>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2245>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2246>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2247>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2248>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2249>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+224A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+224B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+224C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+224D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+224E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+224F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2250>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2251>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2252>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2253>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2254>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2255>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2256>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2257>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2259>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+225B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+225C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2260>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2261>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2262>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2264>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2265>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2266>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2267>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2268>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2269>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+226A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+226B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+226C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+226D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+226E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+226F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2270>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2271>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2272>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2273>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2274>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2275>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2276>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2277>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2278>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2279>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+227A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+227B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+227C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+227D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+227E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+227F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2280>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2281>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2282>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2283>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2284>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2285>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2286>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2287>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2288>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2289>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+228A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+228B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+228E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+228F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2290>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2291>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2292>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2293>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2294>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2295>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2296>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2297>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2298>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2299>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+229A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+229B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+229D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+229E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+229F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22A0>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22A1>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22A2>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22A3>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22A4>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22A5>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22A7>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22A8>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22A9>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22AA>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22AB>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22AC>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22AD>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22AE>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22AF>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22B2>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22B3>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22B4>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22B5>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22B6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22B7>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22B8>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22B9>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22BA>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22BB>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22BE>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22C0>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22C1>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22C2>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22C3>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22C4>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22C5>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22C6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22C7>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22C8>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22C9>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22CA>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22CB>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22CC>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22CD>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22CE>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22CF>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22D0>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22D1>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22D2>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22D3>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22D4>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22D6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22D7>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22D8>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22D9>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22DA>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22DB>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22DE>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22DF>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22E2>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22E3>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22E6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22E7>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22E8>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22E9>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22EA>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22EB>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22EC>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22ED>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22EE>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22EF>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22F0>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+22F1>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2305>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2306>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2308>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2309>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+230A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+230B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2315>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2316>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+231C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+231D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+231E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+231F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2322>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2323>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+23B0>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+23B1>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2329>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+232A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2422>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2423>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+25A0>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+25A1>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+25AA>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+25AD>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+25B3>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+25B4>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+25B5>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+25B8>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+25B9>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+25BD>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+25BE>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+25BF>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+25C2>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+25C3>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+25CA>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+25CB>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+25E6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+25EF>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2662>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+266A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2669>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+266D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+266E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+266F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+27E8>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+27E9>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+27F5>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+27F6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+27F7>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+27F8>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+27F9>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+27FA>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+27FC>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+27FF>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2993>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+29EB>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2A0F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2A16>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2A3F>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2A6E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2A75>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2A7D>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2A7E>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2A85>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2A86>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2A87>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2A88>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2A89>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2A8A>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2A8B>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2A8C>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2A95>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2A96>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2AAF>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2AB0>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2AB5>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2AB6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2AB7>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2AB8>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2AB9>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2ABA>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2AC5>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2AC6>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2ACB>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2ACC>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+2AFD>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+3008>' to native encoding
#> Warning in
#> str2expression(readLines(system.file("latex_unicode/latex_unicode_conversion.txt",
#> : unable to translate '<U+3009>' to native encoding

print(gt_example)
#> -- Content Collection ----------------------------------------------------------
#> 2 items | x no data
#> 
#> i [Text] "### Summary Statistics by Education"
#> * [gt]
```

``` r
gt_example %>% preview()
```

Preview

Summary Statistics by Education

|        Education         | Count | Mean Age |
|:------------------------:|------:|---------:|
|  less than high school   |   242 |     49.5 |
|       high school        |  1361 |     50.0 |
| associate/junior college |   277 |     49.6 |
|        bachelor's        |   677 |     51.0 |
|         graduate         |   440 |     52.5 |

You can also pass a data frame directly - it will be converted to a gt
table automatically:

``` r
simple_gt <- create_content() %>%
  add_gt(head(summary_data, 3), caption = "Top 3 Education Levels")

simple_gt %>% preview()
```

Preview

|          degree          |    n | mean_age |
|:------------------------:|-----:|---------:|
|  less than high school   |  242 |     49.5 |
|       high school        | 1361 |     50.0 |
| associate/junior college |  277 |     49.6 |

### Reactable Tables

For interactive tables with sorting and filtering, use
[`add_reactable()`](https://favstats.github.io/dashboardr/reference/add_reactable.md):

``` r
reactable_example <- create_content() %>%
  add_text("### Interactive Summary Table") %>%
  add_reactable(
    reactable::reactable(summary_data, searchable = TRUE, striped = TRUE)
  )

print(reactable_example)
#> -- Content Collection ----------------------------------------------------------
#> 2 items | x no data
#> 
#> i [Text] "### Interactive Summary Table"
#> * [reactable]
```

``` r
reactable_example %>% preview()
```

Preview

Interactive Summary Table

### DT DataTables

For feature-rich interactive tables, use
[`add_DT()`](https://favstats.github.io/dashboardr/reference/add_DT.md):

``` r
dt_example <- create_content() %>%
  add_text("### DataTable with Search and Pagination") %>%
  add_DT(summary_data, options = list(pageLength = 5))

print(dt_example)
#> -- Content Collection ----------------------------------------------------------
#> 2 items | x no data
#> 
#> i [Text] "### DataTable with Search and Pagination"
#> * [DT]
```

``` r
dt_example %>% preview()
```

Preview

DataTable with Search and Pagination

### Basic Tables

For simple tables without dependencies, use
[`add_table()`](https://favstats.github.io/dashboardr/reference/add_table.md):

``` r
table_example <- create_content() %>%
  add_table(head(summary_data, 3), caption = "Sample Data")

print(table_example)
#> -- Content Collection ----------------------------------------------------------
#> 1 items | x no data
#> 
#> * [table]
```

``` r
table_example %>% preview()
```

Preview

Sample Data

| degree                   | n    | mean_age |
|--------------------------|------|----------|
| less than high school    | 242  | 49.5     |
| high school              | 1361 | 50       |
| associate/junior college | 277  | 49.6     |

### Custom Highcharter Charts

When you need a visualization that goes beyond what
[`add_viz()`](https://favstats.github.io/dashboardr/reference/add_viz.md)
offers, use
[`add_hc()`](https://favstats.github.io/dashboardr/reference/add_hc.md)
to embed any [highcharter](https://jkunst.com/highcharter/) chart:

``` r
library(highcharter)

# Create a custom chart
custom_chart <- highchart() %>%
  hc_chart(type = "pie") %>%
  hc_title(text = "Education Distribution") %>%
  hc_add_series(
    name = "Count",
    data = list(
      list(name = "Less than HS", y = sum(gss$degree == "less than high school")),
      list(name = "High School", y = sum(gss$degree == "high school")),
      list(name = "Junior College", y = sum(gss$degree == "junior college")),
      list(name = "Bachelor", y = sum(gss$degree == "bachelor")),
      list(name = "Graduate", y = sum(gss$degree == "graduate"))
    )
  )

hc_example <- create_content() %>%
  add_text("### Custom Pie Chart") %>%
  add_hc(custom_chart)

print(hc_example)
#> -- Content Collection ----------------------------------------------------------
#> 2 items | x no data
#> 
#> i [Text] "### Custom Pie Chart"
#> * [hc]
```

``` r
hc_example %>% preview()
```

Preview

Custom Pie Chart

This is useful for:

- Chart types not available in
  [`add_viz()`](https://favstats.github.io/dashboardr/reference/add_viz.md)
  (pie charts, gauges, etc.)
- Highly customized visualizations
- Integrating existing highcharter code

## 📈 Working with Pre-aggregated Data

While dashboardr was designed with survey data in mind (where you
typically count or aggregate responses), it works equally well with data
that’s already aggregated.

### Bar Charts with Pre-aggregated Data

Use the `y_var` parameter to specify a column containing pre-computed
values:

``` r
# Pre-aggregated data (e.g., from a database or API)
country_stats <- data.frame(
  country = c("USA", "Germany", "France", "UK", "Japan"),
  population_millions = c(331, 83, 67, 67, 126),
  gdp_trillions = c(21.4, 3.8, 2.6, 2.8, 5.1)
)

# Use y_var to plot pre-aggregated values directly
preagg_bar <- create_content(data = country_stats) %>%
  add_viz(
    type = "bar",
    x_var = "country",
    y_var = "population_millions",  # Pre-computed values
    title = "Population by Country (Millions)",
    x_order = c("USA", "Japan", "Germany", "UK", "France")
  )

preagg_bar %>% preview()
```

Preview

Population by Country (Millions)

This also works for grouped bar charts:

``` r
# Pre-aggregated grouped data
quarterly_sales <- data.frame(
  quarter = rep(c("Q1", "Q2", "Q3", "Q4"), each = 2),
  region = rep(c("North", "South"), 4),
  revenue = c(100, 80, 120, 95, 150, 110, 130, 100)
)

grouped_preagg <- create_content(data = quarterly_sales) %>%
  add_viz(
    type = "bar",
    x_var = "quarter",
    group_var = "region",
    y_var = "revenue",
    title = "Quarterly Revenue by Region"
  )

grouped_preagg %>% preview()
```

Preview

Quarterly Revenue by Region

### Stacked Bars with Pre-aggregated Data

The `y_var` parameter works the same way for stacked bar charts:

``` r
# Pre-aggregated stacked data
satisfaction_data <- data.frame(
  department = rep(c("Sales", "Engineering", "HR"), each = 3),
  rating = rep(c("Satisfied", "Neutral", "Dissatisfied"), 3),
  count = c(45, 30, 10, 60, 25, 15, 35, 20, 5)
)

stacked_preagg <- create_content(data = satisfaction_data) %>%
  add_viz(
    type = "stackedbar",
    x_var = "department",
    stack_var = "rating",
    y_var = "count",  # Pre-computed counts
    title = "Employee Satisfaction by Department"
  )

stacked_preagg %>% preview()
```

Preview

Employee Satisfaction by Department

### Histograms with Pre-aggregated Data

For pre-binned histogram data:

``` r
# Pre-binned data (e.g., from a reporting system)
age_bins <- data.frame(
  age_group = c("18-25", "26-35", "36-45", "46-55", "56-65", "65+"),
  count = c(150, 280, 320, 290, 210, 180)
)

hist_preagg <- create_content(data = age_bins) %>%
  add_viz(
    type = "histogram",
    x_var = "age_group",
    y_var = "count",  # Pre-computed bin counts
    title = "Age Distribution"
  )

hist_preagg %>% preview()
```

Preview

Age Distribution

### Timelines with Pre-aggregated Data

Use `agg = "none"` to skip aggregation for timeline data:

``` r
# Pre-aggregated time series
yearly_metrics <- data.frame(
  year = c(2020, 2021, 2022, 2023),
  value = c(1250, 1380, 1420, 1510)
)

timeline_preagg <- create_content(data = yearly_metrics) %>%
  add_viz(
    type = "timeline",
    time_var = "year",
    y_var = "value",
    agg = "none",  # Use values directly, no aggregation
    title = "Yearly Performance Trend"
  )

timeline_preagg %>% preview()
```

Preview

Yearly Performance Trend

### Heatmaps with Pre-aggregated Data

Use `pre_aggregated = TRUE` to skip the aggregation step:

``` r
# Pre-computed heatmap values (one row per cell)
correlation_data <- data.frame(
  var1 = rep(c("Age", "Income", "Education"), each = 3),
  var2 = rep(c("Age", "Income", "Education"), 3),
  correlation = c(1.0, 0.35, 0.28, 0.35, 1.0, 0.52, 0.28, 0.52, 1.0)
)

heatmap_preagg <- create_content(data = correlation_data) %>%
  add_viz(
    type = "heatmap",
    x_var = "var1",
    y_var = "var2",
    value_var = "correlation",
    pre_aggregated = TRUE,  # Skip aggregation
    title = "Correlation Matrix",
    color_min = -1,
    color_max = 1
  )

heatmap_preagg %>% preview()
```

Preview

Correlation Matrix

### Treemaps with Pre-aggregated Data

Use `pre_aggregated = TRUE` to use values directly without summing:

``` r
# Pre-aggregated hierarchical data
budget_data <- data.frame(
  category = c("Marketing", "Marketing", "Engineering", "Engineering", "Operations"),
  subcategory = c("Digital", "Events", "Frontend", "Backend", "Support"),
  amount = c(50000, 30000, 80000, 120000, 45000)
)

treemap_preagg <- create_content(data = budget_data) %>%
  add_viz(
    type = "treemap",
    group_var = "category",
    subgroup_var = "subcategory",
    value_var = "amount",
    pre_aggregated = TRUE,  # Use amounts directly
    title = "Budget Allocation"
  )

treemap_preagg %>% preview()
```

Preview

Budget Allocation

## 🔲 Layout Helpers

### Dividers

Visual separators between content sections:

``` r
divider_content <- create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "degree", title = "Education") %>%
  add_divider() %>%
  add_viz(x_var = "happy", title = "Happiness")

print(divider_content)
#> -- Content Collection ----------------------------------------------------------
#> 3 items | v data: 2997 rows x 15 cols
#> 
#> * [Viz] Education (bar) x=degree
#> - [Divider]
#> * [Viz] Happiness (bar) x=happy
```

``` r
divider_content %>% preview()
```

Preview

Education

------------------------------------------------------------------------

Happiness

### Spacers

Add vertical spacing between elements:

``` r
spacer_example <- create_content() %>%
  add_text("Content above") %>%
  add_spacer(height = "3rem") %>%
  add_text("Content below (after 3rem spacer)")

print(spacer_example)
#> -- Content Collection ----------------------------------------------------------
#> 3 items | x no data
#> 
#> i [Text] "Content above"
#> * [spacer]
#> i [Text] "Content below (after 3rem spacer)"
```

``` r
spacer_example %>% preview()
```

Preview

Content above

Content below (after 3rem spacer)

## 👁️ Previewing Content

Use
[`preview()`](https://favstats.github.io/dashboardr/reference/preview.md)
to quickly check your visualizations and content blocks during
development. It automatically validates your visualization specs and
catches errors like missing parameters or invalid column names before
rendering:

``` r
# Quick preview (fast, no Quarto)
content %>% preview()

# Full Quarto preview (slower, full features)
content %>% preview(quarto = TRUE)

# Save to specific location
content %>% preview(path = "my_preview.html")
```

### Limitations of Preview

> **Important:**
> [`preview()`](https://favstats.github.io/dashboardr/reference/preview.md)
> is a simplified rendering for quick checks during development. It does
> **not** show the final dashboard appearance.

**What preview shows well:**

- Individual visualizations and their data
- Basic tabgroup organization
- Content blocks (text, callouts, cards, etc.)
- Simple nested tabs

**What preview does NOT support:**

- Full dashboard navigation and layout
- Interactive inputs (dropdowns, sliders, checkboxes)
- Complex multi-page structures
- Dashboard theming and styling
- Sidebar navigation
- Mobile responsiveness

**For a real view of your dashboard**, you must run
[`generate_dashboard()`](https://favstats.github.io/dashboardr/reference/generate_dashboard.md)
and open the resulting Quarto site:

``` r
dashboard <- create_dashboard("My Dashboard") %>%

  add_page(my_page)

# Generate the full dashboard
generate_dashboard(dashboard)

# Then open _site/index.html in your browser
```

Think of
[`preview()`](https://favstats.github.io/dashboardr/reference/preview.md)
as a “sanity check” for your charts and content, not a representation of
the final product.

## ➡️ Next Steps

Once you have content, add it to a page:

``` r
create_page("Analysis", data = gss) %>%
  add_content(demographics) %>%
  add_content(attitudes)
```

See
[`vignette("pages")`](https://favstats.github.io/dashboardr/articles/pages.md)
for page creation details.
