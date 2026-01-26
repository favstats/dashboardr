# Creating Bar Charts with viz_bar()

## Introduction

The
[`viz_bar()`](https://favstats.github.io/dashboardr/reference/viz_bar.md)
function creates grouped/clustered bar charts, perfect for comparing
categories across different groups or segments. Unlike histograms (which
show distributions) or stacked bars (which show composition), bar charts
excel at side-by-side comparisons.

``` r
library(dashboardr)
library(dplyr)
```

## Basic Bar Charts

### Simple Category Counts

``` r
# Sample data
data <- data.frame(
  category = c("A", "A", "B", "B", "B", "C", "C", "C", "C")
)

# Create bar chart
plot <- viz_bar(
  data = data,
  x_var = "category"
)

plot
```

### With Custom Labels

``` r
plot <- viz_bar(
  data = data,
  x_var = "category",
  title = "Category Distribution",
  x_label = "Categories",
  y_label = "Count"
)
```

## Grouped Bar Charts

### Basic Grouping

``` r
# Survey data
survey_data <- data.frame(
  question = rep(c("Q1", "Q2", "Q3"), each = 50),
  score_range = sample(c("Low", "Medium", "High"), 150, replace = TRUE)
)

# Grouped bar chart
plot <- viz_bar(
  data = survey_data,
  x_var = "question",
  group_var = "score_range",
  horizontal = TRUE,
  bar_type = "percent"
)

plot
```

### With Custom Colors

``` r
plot <- viz_bar(
  data = survey_data,
  x_var = "question",
  group_var = "score_range",
  horizontal = TRUE,
  bar_type = "percent",
  color_palette = c(
    "#E74C3C",  # Red for Low
    "#F39C12",  # Orange for Medium
    "#27AE60"   # Green for High
  ),
  group_order = c("Low", "Medium", "High")
)
```

## Horizontal vs. Vertical

### Vertical Bars

``` r
plot <- viz_bar(
  data = data,
  x_var = "category",
  group_var = "segment",
  horizontal = FALSE  # Vertical
)
```

### Horizontal Bars (Better for Long Labels)

``` r
data <- data.frame(
  question = rep(c(
    "I know how to search effectively",
    "I can evaluate information quality",
    "I understand data privacy"
  ), each = 40),
  response = sample(c("Agree", "Disagree"), 120, replace = TRUE)
)

plot <- viz_bar(
  data = data,
  x_var = "question",
  group_var = "response",
  horizontal = TRUE,  # Much better for long labels!
  bar_type = "percent"
)
```

## Count vs. Percent

### Count

``` r
plot <- viz_bar(
  data = data,
  x_var = "category",
  group_var = "segment",
  bar_type = "count",  # Show raw counts
  y_label = "Number of Responses"
)
```

### Percent

``` r
plot <- viz_bar(
  data = data,
  x_var = "category",
  group_var = "segment",
  bar_type = "percent",  # Show percentages
  y_label = "Percentage"
)
```

## Labels and Tooltips

### Axis Labels

``` r
plot <- viz_bar(
  data = survey_data,
  x_var = "question",
  group_var = "score_range",
  title = "Survey Results",
  x_label = "Question",
  y_label = "Percentage of Respondents"
)
```

### Tooltip Customization

Add prefix/suffix text to make tooltips more informative:

``` r
plot <- viz_bar(
  data = survey_data,
  x_var = "question",
  group_var = "score_range",
  bar_type = "percent",
  title = "Score Distribution",
  tooltip_prefix = "",
  tooltip_suffix = "% of responses",
  x_tooltip_suffix = ""
)
```

| Parameter          | Description                   | Example                   |
|--------------------|-------------------------------|---------------------------|
| `x_label`          | X-axis title                  | `"Category"`              |
| `y_label`          | Y-axis title                  | `"Count"`, `"Percentage"` |
| `tooltip_prefix`   | Text before value in tooltip  | `"N = "`                  |
| `tooltip_suffix`   | Text after value in tooltip   | `"%"`, `" respondents"`   |
| `x_tooltip_suffix` | Text after x value in tooltip | `" category"`             |

## Working with Numeric Variables

### Automatic Binning

``` r
# Age data
age_data <- data.frame(
  age = sample(18:65, 200, replace = TRUE)
)

# Automatically bins numeric values
plot <- viz_bar(
  data = age_data,
  x_var = "age"
)
```

### Custom Binning

``` r
plot <- viz_bar(
  data = age_data,
  x_var = "age",
  x_breaks = c(18, 25, 35, 50, 65),
  x_bin_labels = c("18-24", "25-34", "35-49", "50-64")
)
```

## Advanced Styling

### Custom Ordering

``` r
data <- data.frame(
  satisfaction = sample(c("Very Satisfied", "Satisfied", "Neutral", 
                         "Dissatisfied", "Very Dissatisfied"), 
                       100, replace = TRUE)
)

plot <- viz_bar(
  data = data,
  x_var = "satisfaction",
  x_order = c("Very Dissatisfied", "Dissatisfied", "Neutral", 
              "Satisfied", "Very Satisfied")
)
```

### Colorful Individual Bars

``` r
# When no group_var, can color each bar differently
data <- data.frame(
  category = c("A", "B", "C", "D")
)

plot <- viz_bar(
  data = data,
  x_var = "category",
  color_palette = c("#3498DB", "#E74C3C", "#F39C12", "#27AE60")
)
```

## Real-World Examples

### Survey Response Comparison

``` r
# Knowledge assessment across topics
knowledge_data <- data.frame(
  topic = rep(c("Search Skills", "Critical Thinking", 
                "Data Privacy", "Source Evaluation"), each = 100),
  proficiency = sample(c("Beginner", "Intermediate", "Advanced"), 
                      400, replace = TRUE)
)

plot <- viz_bar(
  data = knowledge_data,
  x_var = "topic",
  group_var = "proficiency",
  horizontal = TRUE,
  bar_type = "percent",
  title = "Self-Reported Proficiency by Topic",
  x_label = "",
  y_label = "Percentage of Respondents",
  color_palette = c("#E74C3C", "#F39C12", "#27AE60"),
  group_order = c("Beginner", "Intermediate", "Advanced")
)

plot
```

### Demographic Breakdown

``` r
demo_data <- data.frame(
  age_group = rep(c("18-24", "25-34", "35-44", "45-54", "55+"), each = 80),
  device_type = sample(c("Mobile", "Desktop", "Tablet"), 400, replace = TRUE)
)

plot <- viz_bar(
  data = demo_data,
  x_var = "age_group",
  group_var = "device_type",
  horizontal = FALSE,
  bar_type = "percent",
  title = "Device Usage by Age Group",
  color_palette = c("#3498DB", "#95A5A6", "#F39C12")
)
```

## Using with create_viz()

Integrate with the dashboard workflow:

``` r
viz <- create_viz(
  type = "bar",
  horizontal = TRUE,
  bar_type = "percent",
  color_palette = c("#E74C3C", "#F39C12", "#27AE60")
) %>%
  add_viz(
    x_var = "question1",
    group_var = "response_category",
    title = "Question 1 Results"
  ) %>%
  add_viz(
    x_var = "question2",
    group_var = "response_category",
    title = "Question 2 Results"
  ) %>%
  add_viz(
    x_var = "question3",
    group_var = "response_category",
    title = "Question 3 Results"
  )

# All inherit the defaults!
```

### With Filters

``` r
viz <- create_viz(
  type = "bar",
  x_var = "satisfaction",
  group_var = "score_range",
  horizontal = TRUE,
  bar_type = "percent"
) %>%
  add_viz(title = "Wave 1", filter = ~ wave == 1) %>%
  add_viz(title = "Wave 2", filter = ~ wave == 2) %>%
  add_viz(title = "Wave 3", filter = ~ wave == 3)
```

### With Tabgroups

``` r
viz <- create_viz(
  type = "bar",
  horizontal = TRUE,
  bar_type = "percent"
) %>%
  add_viz(
    x_var = "satisfaction",
    group_var = "score_range",
    title = "By Age",
    tabgroup = "demographics/age"
  ) %>%
  add_viz(
    x_var = "satisfaction",
    group_var = "score_range",
    title = "By Gender",
    tabgroup = "demographics/gender"
  ) %>%
  add_viz(
    x_var = "satisfaction",
    group_var = "score_range",
    title = "By Education",
    tabgroup = "demographics/education"
  )
```

## Comparison with Other Chart Types

### When to Use Bar Charts

**Use
[`viz_bar()`](https://favstats.github.io/dashboardr/reference/viz_bar.md)
when:** - Comparing categories across groups - Showing side-by-side
comparisons - Displaying survey responses by demographics - You want
grouped/clustered bars

**Use
[`viz_stackedbar()`](https://favstats.github.io/dashboardr/reference/viz_stackedbar.md)
when:** - Showing composition (parts of a whole) - Displaying Likert
scale responses - Emphasizing proportions within categories

**Use
[`viz_histogram()`](https://favstats.github.io/dashboardr/reference/viz_histogram.md)
when:** - Showing distributions of continuous variables - Displaying
frequency distributions - Analyzing data spread and shape

**Use
[`viz_timeline()`](https://favstats.github.io/dashboardr/reference/viz_timeline.md)
when:** - Showing changes over time - Displaying trends - Comparing time
series

## Tips and Best Practices

1.  **Use horizontal bars for long labels** - Much more readable
2.  **Choose percent for comparisons** - Easier to interpret than counts
3.  **Order categories meaningfully** - Use `x_order` or `group_order`
4.  **Limit colors** - 3-5 colors maximum for clarity
5.  **Use consistent colors** - Same meaning = same color across charts

## See Also

- [`?viz_bar`](https://favstats.github.io/dashboardr/reference/viz_bar.md) -
  Full function documentation
- [`vignette("stackedbar_vignette")`](https://favstats.github.io/dashboardr/articles/stackedbar_vignette.md) -
  For stacked/composed bars
- [`vignette("advanced-features")`](https://favstats.github.io/dashboardr/articles/advanced-features.md) -
  For defaults and filters
- [`vignette("getting-started")`](https://favstats.github.io/dashboardr/articles/getting-started.md) -
  For dashboard integration
