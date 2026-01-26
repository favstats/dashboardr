# Demo: Interactive Input Filtering for Country Selection
#
# This example demonstrates how to use add_input() to create
# interactive multi-select dropdowns that filter Highcharts visualizations.
#
# Perfect for Mark's publication trends dashboard!

library(tidyverse)
devtools::load_all()

# =============================================================================
# Create sample publication data (similar to Mark's dataset)
# =============================================================================

set.seed(42)

# Sample countries
countries <- c(
  "Netherlands", "Germany", "United States", "United Kingdom",

  "France", "Canada", "Australia", "Japan", "China", "Brazil",
  "Global Average"
)

# Time periods
decades <- c("1970s", "1980s", "1990s", "2000s", "2010s", "2020s")

# Generate sample data
publication_data <- expand.grid(
  country = countries,
  decade = decades,
  stringsAsFactors = FALSE
) %>%
  mutate(
    # Base trends with some country variation
    base_female = case_when(
      country == "Global Average" ~ 15 + as.numeric(factor(decade)) * 5,
      TRUE ~ 10 + as.numeric(factor(decade)) * 5 + rnorm(n(), 0, 5)
    ),
    base_weird = case_when(
      country %in% c("United States", "United Kingdom", "Canada", "Australia") ~ 70 - as.numeric(factor(decade)) * 3,
      country == "Global Average" ~ 60 - as.numeric(factor(decade)) * 2,
      TRUE ~ 50 - as.numeric(factor(decade)) * 2 + rnorm(n(), 0, 5)
    ),
    pct_female = pmin(pmax(base_female, 5), 50),
    pct_weird = pmin(pmax(base_weird, 30), 90),
    pct_qualitative = 20 + rnorm(n(), 0, 5),
    pct_quantitative = 80 - pct_qualitative + rnorm(n(), 0, 3)
  ) %>%
  select(country, decade, pct_female, pct_weird, pct_qualitative, pct_quantitative)

# Reshape to long format for flexible visualization
publication_long <- publication_data %>%
  pivot_longer(
    cols = c(pct_female, pct_weird, pct_qualitative, pct_quantitative),
    names_to = "metric",
    values_to = "percentage"
  ) %>%
  mutate(
    metric_label = case_when(
      metric == "pct_female" ~ "Female Authorship",
      metric == "pct_weird" ~ "WEIRD Studies",
      metric == "pct_qualitative" ~ "Qualitative",
      metric == "pct_quantitative" ~ "Quantitative"
    )
  )

# =============================================================================
# Create visualizations - using timeline with line chart for connected lines!
# =============================================================================

viz <- create_viz() %>%
  # Female authorship trends - LINE chart with connected points
  add_viz(
    type = "timeline",
    time_var = "decade",
    y_var = "pct_female",
    group_var = "country",  # This creates series named by country!
    chart_type = "line",
    title = "% Female Authorship Over Time",
    subtitle = "Select countries using the dropdown above",
    x_label = "Decade",
    y_label = "Percentage",
    tabgroup = "trends/Female Authorship"
  ) %>%
  # WEIRD studies trends
  add_viz(
    type = "timeline",
    time_var = "decade",
    y_var = "pct_weird",
    group_var = "country",
    chart_type = "line",
    title = "% WEIRD Country Studies Over Time",
    subtitle = "Percentage of studies fielded in WEIRD countries",
    x_label = "Decade",
    y_label = "Percentage",
    tabgroup = "trends/WEIRD Studies"
  )

# =============================================================================
# Create content with input filter
# =============================================================================

content <- create_content() %>%
  add_text(md_text(
    "# Publication Trends Analysis",
    "",
    "Filter by country and/or decade. Both filters work together!"
  )) %>%
  # Add input row with multiple filters - SAME WIDTH for consistency
  add_input_row(style = "inline", align = "center") %>%
    add_input(
      input_id = "country_filter",
      label = "Select Countries:",
      filter_var = "country",  # Matches group_var in viz!
      options = countries,
      default_selected = c("Netherlands", "Germany", "Global Average"),
      placeholder = "Choose countries..."
    ) %>%
    add_input(
      input_id = "decade_filter",
      label = "Select Decades:",
      filter_var = "decade",  # Matches time_var categories
      options = decades,
      default_selected = decades,  # All selected by default
      placeholder = "Choose decades..."
    ) %>%
  end_input_row() %>%
  add_spacer(height = "0.5rem")

# =============================================================================
# Create dashboard
# =============================================================================

dashboard <- create_dashboard(
  title = "Publication Trends Dashboard",
  output_dir = "input_filter_demo",
  tabset_theme = "underline",
  author = "dashboardr Demo",
  description = "Interactive dashboard with country filtering"
) %>%
  add_page(
    name = "Country Trends",
    data = publication_data,
    visualizations = viz,
    content = content,  # Contains the input filter!
    icon = "ph:chart-line",
    is_landing_page = TRUE
  ) %>%
  add_page(
    name = "About",
    text = md_text(
      "# About This Dashboard",
      "",
      "This dashboard demonstrates the new **input filtering** feature in dashboardr.",
      "",
      "## How It Works",
      "",
      "1. The `add_input()` function creates a multi-select dropdown",
      "2. The `filter_var` parameter links to Highcharts series names",
      "3. When you select/deselect countries, the chart updates in real-time",
      "",
      "## Code Example",
      "",
      "```r",
      "content <- create_content() %>%",
      "  add_input_row() %>%",
      "    add_input(",
      "      input_id = \"country_filter\",",
      "      label = \"Select Countries:\",",
      "      filter_var = \"country\",",
      "      options_from = \"country\",",
      "      default_selected = c(\"Netherlands\", \"Germany\")",
      "    ) %>%",
      "  end_input_row()",
      "```",
      "",
      "The key is that `filter_var = \"country\"` must match the `group_var = \"country\"` ",
      "used in your `viz_timeline()` or other visualization functions."
    ),
    icon = "ph:info"
  )

# Print summary
print(dashboard)
print(viz)

# Generate the dashboard
generate_dashboard(dashboard, render = TRUE, open = "browser")

