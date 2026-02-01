# Tutorial Dashboard Code Examples

### 🚀 View the Live Demo

See this code in action! **[Click here to view the Tutorial Dashboard
live demo
→](https://favstats.github.io/dashboardr/live-demos/tutorial/index.md)**

Or run it yourself:
[`dashboardr::tutorial_dashboard()`](https://favstats.github.io/dashboardr/reference/tutorial_dashboard.md)

## Overview

This vignette provides the **exact R code** for each visualization in
the Tutorial Dashboard. Each section shows the complete
[`add_viz()`](https://favstats.github.io/dashboardr/reference/add_viz.md)
call as it appears in the
[`tutorial_dashboard()`](https://favstats.github.io/dashboardr/reference/tutorial_dashboard.md)
function source code.

Click on any visualization in the live demo to see the “View R Code”
accordion, which links back to the corresponding section here.

------------------------------------------------------------------------

## Data Preparation

The Tutorial Dashboard uses data from the **General Social Survey
(GSS)** via the `gssr` package:

``` r
library(dashboardr)
library(dplyr)

# Load GSS panel data
data(gss_panel20, package = "gssr")

# Clean and select relevant variables
gss_clean <- gss_panel20 %>%
  select(
    age_1a, sex_1a, degree_1a, region_1a,
    happy_1a, trust_1a, fair_1a, helpful_1a,
    polviews_1a, partyid_1a, class_1a
  ) %>%
  filter(if_any(everything(), ~ !is.na(.)))
```

------------------------------------------------------------------------

## Example 1: Stacked Bars (Demographics Tabset)

### Happiness by Education

This is the first visualization in the “Example 1: Stacked Bars” tabset.

``` r
add_viz(type = "stackedbar",
        x_var = "degree_1a",
        stack_var = "happy_1a",
        title = "Change the title here...",
        subtitle = "You can add a subtitle using the subtitle argument",
        x_label = "Education Level",
        y_label = "Percentage of Respondents",
        stack_label = "Happiness Level",
        stacked_type = "percent",
        x_order = c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate"),
        stack_order = c("Very Happy", "Pretty Happy", "Not Too Happy"),
        tooltip_suffix = "%",
        color_palette = c("#2E86AB", "#A23B72", "#F18F01"),
        text = "If you want to add text within the tab, you can do so here.",
        text_position = "above",
        icon = "ph:chart-bar",
        height = 500,
        tabgroup = "demographics")
```

**Key parameters:**

- `stacked_type = "percent"`: Shows proportions within each category
- `x_order` / `stack_order`: Custom ordering of categories
- `tabgroup = "demographics"`: Groups this with other demographic charts
  in a tabset
- `text` / `text_position`: Adds explanatory text above or below the
  chart

------------------------------------------------------------------------

### Happiness by Gender

This is the second visualization in the “Example 1: Stacked Bars”
tabset.

``` r
add_viz(type = "stackedbar",
        x_var = "sex_1a",
        stack_var = "happy_1a",
        title = "Tabset #2",
        subtitle = "Another example subtitle here!",
        x_label = "Gender",
        y_label = "Percentage of Respondents",
        stack_label = "Happiness Level",
        stacked_type = "percent",
        stack_order = c("Very Happy", "Pretty Happy", "Not Too Happy"),
        tooltip_suffix = "%",
        color_palette = c("#2E86AB", "#A23B72", "#F18F01"),
        text = "Change the position of the text using the `text_position` argument.",
        text_position = "below",
        icon = "ph:gender-intersex",
        height = 450,
        tabgroup = "demographics")
```

------------------------------------------------------------------------

## Example 2: Heatmaps (Social Issues Tabset)

### Trust by Education and Age

This heatmap is in the “Example 2: Heatmap” tabset.

``` r
add_viz(type = "heatmap",
        x_var = "degree_1a",
        y_var = "age_1a",
        value_var = "trust_1a",
        title = "Trust by Education and Age",
        subtitle = "Average trust levels across education and age groups",
        x_label = "Example x axis",
        y_label = "Customizable y label",
        value_label = "You can change the label here too...",
        x_order = c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate"),
        color_palette = c("#d7191c", "#fdae61", "#ffffbf", "#abdda4", "#2b83ba"),
        tooltip_prefix = "Trust: ",
        tooltip_suffix = "/3",
        tooltip_labels_format = "{point.value:.2f}",
        text = "Here's another example of the kind of plots you can generate in your dashboard.",
        text_position = "above",
        icon = "ph:heatmap",
        height = 600,
        tabgroup = "social")
```

**Key parameters:**

- `value_var`: The numeric variable to aggregate for cell colors
- `color_palette`: Diverging color scale from red to blue
- `tooltip_labels_format`: Highcharts format string for tooltip values

------------------------------------------------------------------------

### Trust by Region and Education

This heatmap shows educational and regional patterns.

``` r
add_viz(type = "heatmap",
        x_var = "region_1a",
        y_var = "degree_1a",
        value_var = "trust_1a",
        title = "Trust by Region and Education",
        subtitle = "Educational and regional patterns in trust levels",
        x_label = "Region",
        y_label = "Education Level",
        value_label = "Trust Level",
        y_order = c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate"),
        color_palette = c("#d7191c", "#fdae61", "#ffffbf", "#abdda4", "#2b83ba"),
        tooltip_prefix = "Trust: ",
        tooltip_suffix = "/3",
        tooltip_labels_format = "{point.value:.2f}",
        text = "Educational and regional patterns in trust distribution.",
        text_position = "above",
        icon = "ph:chart-pie",
        height = 550,
        tabgroup = "social")
```

------------------------------------------------------------------------

## Standalone Charts (No Tabsets)

These charts appear on the “Standalone Charts” page without tabset
grouping.

### Overall Happiness by Education

``` r
add_viz(type = "stackedbar",
        x_var = "degree_1a",
        stack_var = "happy_1a",
        title = "This is a standalone chart.",
        subtitle = "Here you'll notice that this is a standalone plot.",
        x_label = "Education Level",
        y_label = "Percentage of Respondents",
        stack_label = "Happiness Level",
        stacked_type = "percent",
        x_order = c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate"),
        stack_order = c("Very Happy", "Pretty Happy", "Not Too Happy"),
        tooltip_suffix = "%",
        color_palette = c("#2E86AB", "#A23B72", "#F18F01"),
        text = "This standalone chart shows the overall distribution of happiness across education levels.",
        text_position = "above",
        icon = "ph:chart-bar",
        height = 600)
```

**Note:** No `tabgroup` parameter = standalone chart without tabs.

------------------------------------------------------------------------

### Trust by Party and Political Views

``` r
add_viz(type = "heatmap",
        x_var = "partyid_1a",
        y_var = "polviews_1a",
        value_var = "trust_1a",
        title = "Here's another summary chart",
        subtitle = "This summary chart visualizes trust patterns across political groups",
        x_label = "Party Identification",
        y_label = "Political Views",
        value_label = "Trust Level",
        x_order = c("Strong Democrat", "Not Very Strong Democrat", "Independent, Close to Democrat",
                    "Independent", "Independent, Close to Republican", "Not Very Strong Republican", "Strong Republican"),
        y_order = c("Extremely Liberal", "Liberal", "Slightly Liberal", "Moderate",
                    "Slightly Conservative", "Conservative", "Extremely Conservative"),
        color_palette = c("#d7191c", "#fdae61", "#ffffbf", "#abdda4", "#2b83ba"),
        tooltip_prefix = "Trust: ",
        tooltip_suffix = "/3",
        tooltip_labels_format = "{point.value:.2f}",
        text = "Subtitle for your standalone chart.",
        text_position = "below",
        icon = "ph:shield-check",
        height = 700)
```

------------------------------------------------------------------------

## Building the Complete Dashboard

Here’s the full structure showing how the Tutorial Dashboard combines
visualizations:

``` r
library(dashboardr)

# Create content with visualizations and accordions
analysis_vizzes <- create_content() %>%
  # Demographics tabset
  add_viz(type = "stackedbar", x_var = "degree_1a", stack_var = "happy_1a",
          tabgroup = "demographics", ...) %>%
  add_accordion(title = "View R Code", text = "...", tabgroup = "demographics") %>%
  add_viz(type = "stackedbar", x_var = "sex_1a", stack_var = "happy_1a",
          tabgroup = "demographics", ...) %>%
  add_accordion(title = "View R Code", text = "...", tabgroup = "demographics") %>%
  # Social Issues tabset
  add_viz(type = "heatmap", x_var = "degree_1a", y_var = "age_1a",
          value_var = "trust_1a", tabgroup = "social", ...) %>%
  add_accordion(title = "View R Code", text = "...", tabgroup = "social") %>%
  add_viz(type = "heatmap", x_var = "region_1a", y_var = "degree_1a",
          value_var = "trust_1a", tabgroup = "social", ...) %>%
  add_accordion(title = "View R Code", text = "...", tabgroup = "social") %>%
  set_tabgroup_labels(list(
    demographics = "Example 1: Stacked Bars",
    social = "Example 2: Heatmap"
  ))

# Build dashboard
dashboard <- create_dashboard(output_dir = "tutorial_dashboard", title = "Tutorial Dashboard") %>%
  add_page(name = "Welcome", text = "...", is_landing_page = TRUE) %>%
  add_page(name = "Example Dashboard", data = gss_clean, content = analysis_vizzes) %>%
  add_page(name = "Standalone Charts", data = gss_clean, content = summary_vizzes)

generate_dashboard(dashboard)
```

## Visualization Index

| Chart | Type | Page | Tabset | Anchor |
|----|----|----|----|----|
| Happiness by Education | Stacked Bar | Example Dashboard | Demographics | [\#stacked-bar-happiness-education](#stacked-bar-happiness-education) |
| Happiness by Gender | Stacked Bar | Example Dashboard | Demographics | [\#stacked-bar-happiness-gender](#stacked-bar-happiness-gender) |
| Trust by Education & Age | Heatmap | Example Dashboard | Social Issues | [\#heatmap-trust-education-age](#heatmap-trust-education-age) |
| Trust by Region & Education | Heatmap | Example Dashboard | Social Issues | [\#heatmap-trust-region-education](#heatmap-trust-region-education) |
| Overall Happiness | Stacked Bar | Standalone Charts | \- | [\#standalone-happiness-education](#standalone-happiness-education) |
| Trust by Politics | Heatmap | Standalone Charts | \- | [\#standalone-trust-politics](#standalone-trust-politics) |

## Next Steps

- **[View the live Tutorial Dashboard
  →](https://favstats.github.io/dashboardr/live-demos/tutorial/index.md)**
- See the [Showcase Dashboard
  Code](https://favstats.github.io/dashboardr/articles/showcase_dashboard_code.md)
  for more advanced examples
- Explore [visualization
  vignettes](https://favstats.github.io/dashboardr/articles/index.md)
  for detailed chart customization
