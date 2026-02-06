# Charts

# Charts

View Full Page Code

``` r
# === CHARTS PAGE ===
# This page shows a bar chart and stacked bar chart

# Data preparation
library(gssr)
data(gss_panel20, package = "gssr")
gss_clean <- gss_panel20 %>%
  dplyr::mutate(
    degree = as.character(haven::as_factor(degree_1a)),
    happy = as.character(haven::as_factor(happy_1a))
  ) %>%
  dplyr::filter(!is.na(degree), !is.na(happy))

# Create visualizations
chart_vizzes <- create_content() %>%
  add_viz(type = "bar",
          x_var = "degree",
          title = "Education Level Distribution",
          subtitle = "Count of respondents by highest degree attained",
          x_label = "Education",
          y_label = "Count",
          x_order = c("less than high school", "high school",
                      "associate/junior college", "bachelor's", "graduate"),
          color_palette = c("#3498db", "#2ecc71", "#9b59b6", "#e74c3c", "#f39c12"),
          height = 400) %>%
  add_viz(type = "stackedbar",
          x_var = "degree",
          stack_var = "happy",
          title = "Happiness by Education Level",
          subtitle = "Self-reported happiness across education groups",
          x_label = "Education",
          y_label = "Percentage",
          stack_label = "Happiness",
          stacked_type = "percent",
          x_order = c("less than high school", "high school",
                      "associate/junior college", "bachelor's", "graduate"),
          stack_order = c("very happy", "pretty happy", "not too happy"),
          color_palette = c("#27ae60", "#f39c12", "#e74c3c"),
          height = 450)

# Create page and add content
charts_page <- create_page(name = "Charts", data = gss_clean, icon = "ph:chart-bar") %>%
  add_content(chart_vizzes)
```

This page demonstrates three common chart types: a **bar chart** for
counts, and a **stacked bar chart** for proportions.

## Education Level Distribution

View R Code

``` r
add_viz(type = "bar",
        x_var = "degree",
        title = "Education Level Distribution",
        subtitle = "Count of respondents by highest degree attained",
        x_label = "Education",
        y_label = "Count",
        x_order = c("less than high school", "high school",
                    "associate/junior college", "bachelor's", "graduate"),
        color_palette = c("#3498db", "#2ecc71", "#9b59b6", "#e74c3c", "#f39c12"),
        height = 400)
```

## Happiness by Education Level

View R Code

``` r
add_viz(type = "stackedbar",
        x_var = "degree",
        stack_var = "happy",
        title = "Happiness by Education Level",
        subtitle = "Self-reported happiness across education groups",
        x_label = "Education",
        y_label = "Percentage",
        stack_label = "Happiness",
        stacked_type = "percent",
        x_order = c("less than high school", "high school",
                    "associate/junior college", "bachelor's", "graduate"),
        stack_order = c("very happy", "pretty happy", "not too happy"),
        color_palette = c("#27ae60", "#f39c12", "#e74c3c"),
        height = 450)
```

Back to top
