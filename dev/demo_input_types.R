# =============================================================================
# Demo: All Input Types
#
# Each input type controls something DIFFERENT to show they all work together
# =============================================================================

library(tidyverse)
devtools::load_all()

set.seed(2024)

# Create demo data with MULTIPLE METRICS
countries_data <- expand_grid(
  country = c("Netherlands", "Germany", "France", "United Kingdom", "Italy"),
  year = as.character(2015:2024)
) %>%
  mutate(
    year_num = as.numeric(year),
    # GDP Index (different patterns per country)
    GDP = case_when(
      country == "Netherlands" ~ 95 + (year_num - 2015) * 3.5 + rnorm(n(), 0, 2),
      country == "Germany" ~ 100 + (year_num - 2015) * 2.8 + rnorm(n(), 0, 3),
      country == "France" ~ 92 + (year_num - 2015) * 3.0 + rnorm(n(), 0, 2.5),
      country == "United Kingdom" ~ 98 + (year_num - 2015) * 2.5 + rnorm(n(), 0, 3),
      country == "Italy" ~ 88 + (year_num - 2015) * 2.0 + rnorm(n(), 0, 2)
    ),
    # Employment Rate (%)
    Employment = case_when(
      country == "Netherlands" ~ 78 + (year_num - 2015) * 0.8 + rnorm(n(), 0, 1),
      country == "Germany" ~ 76 + (year_num - 2015) * 0.9 + rnorm(n(), 0, 1.2),
      country == "France" ~ 70 + (year_num - 2015) * 0.6 + rnorm(n(), 0, 1),
      country == "United Kingdom" ~ 75 + (year_num - 2015) * 0.7 + rnorm(n(), 0, 1.1),
      country == "Italy" ~ 62 + (year_num - 2015) * 1.2 + rnorm(n(), 0, 1.5)
    ),
    # Trade Volume Index
    Trade = case_when(
      country == "Netherlands" ~ 120 + (year_num - 2015) * 5 + rnorm(n(), 0, 4),
      country == "Germany" ~ 110 + (year_num - 2015) * 4 + rnorm(n(), 0, 5),
      country == "France" ~ 85 + (year_num - 2015) * 3 + rnorm(n(), 0, 3),
      country == "United Kingdom" ~ 95 + (year_num - 2015) * 2 + rnorm(n(), 0, 4),
      country == "Italy" ~ 75 + (year_num - 2015) * 3.5 + rnorm(n(), 0, 3)
    )
  ) %>%
  select(-year_num)

# Reshape to long format with metric column
demo_data_long <- countries_data %>%
  pivot_longer(cols = c(GDP, Employment, Trade),
               names_to = "metric",
               values_to = "value")

# Add Global Average for each metric
global_avg <- demo_data_long %>%
  group_by(year, metric) %>%
  summarise(value = mean(value), .groups = "drop") %>%
  mutate(country = "Global Average")

demo_data <- bind_rows(demo_data_long, global_avg)

# Use full data - JS will handle metric filtering
# The chart groups by country, so it will show all countries
# but JS will filter the data points based on selected metric

# Create visualization - GDP Index by country
viz <- create_viz() %>%
  add_viz(
    type = "timeline",
    time_var = "year",
    response_var = "value",
    group_var = "country",
    chart_type = "line",
    title = "GDP Index by Country",
    subtitle = "Base Year 2015 = 100",
    x_label = "Year",
    y_label = "GDP Index"
  )

# Create content with all input types - each controls something DIFFERENT
content <- create_content() %>%
  # add_text(md_text(
  #   "### Interactive Filters",
  #   "Each input controls a different aspect of the visualization."
  # )) %>%

  # Row 1: Multi-select (countries) and Single-select (METRIC)
  add_input_row(style = "boxed", align = "center") %>%
    add_input(
      input_id = "countries_multi",
      label = "Select Countries:",
      type = "select_multiple",
      filter_var = "country",
      options = c("Netherlands", "Germany", "France", "United Kingdom", "Italy"),
      default_selected = c("Netherlands", "Germany", "France")
    ) %>%
    add_input(
      input_id = "metric_select",
      label = "Select Metric:",
      type = "select_single",
      filter_var = "metric",
      options = c("GDP", "Employment", "Trade"),
      default_selected = "GDP"
    ) %>%
  end_input_row() %>%

  # Row 2: Checkbox for years
  add_input_row(style = "inline", align = "center") %>%
    add_input(
      input_id = "years_checkbox",
      label = "Include Years:",
      type = "checkbox",
      filter_var = "year",
      options = as.character(2015:2024),
      default_selected = as.character(2015:2024),
      inline = TRUE
    ) %>%
  end_input_row() %>%

  # Row 3: Radio for period selection
  add_input_row(style = "inline", align = "center") %>%
    add_input(
      input_id = "period_radio",
      label = "Quick Period:",
      type = "radio",
      filter_var = "period",
      options = c("All Years", "Pre-COVID (2015-2019)", "Post-COVID (2020-2024)"),
      default_selected = "All Years",
      inline = TRUE
    ) %>%
  end_input_row() %>%

  # Row 4: Switches and Slider
  add_input_row(style = "boxed", align = "center") %>%
    add_input(
      input_id = "show_average",
      label = "Show Global Average",
      type = "switch",
      filter_var = "country",       # The column that has "Global Average"
      options = "Global Average",   # Toggle this value on/off
      value = TRUE,
      override = TRUE               # Override other filters for this series
    ) %>%
    add_input(
      input_id = "show_legend",
      label = "Show Legend",
      type = "switch",
      filter_var = "show_legend",
      value = TRUE
    ) %>%
    add_input(
      input_id = "start_year",
      label = "Start From Year:",
      type = "slider",
      filter_var = "year",
      min = 2015,
      max = 2024,
      step = 1,
      value = 2015,
      show_value = TRUE,
      width = "250px"
    ) %>%
  end_input_row() %>%

  add_spacer(height = "0.5rem")

this <- viz+content

# Create dashboard
dashboard <- create_dashboard(
  title = "Input Types Demo",
  output_dir = "input_types_demo",
  tabset_theme = "underline",
  author = "dashboardr",
  description = "Demo of all input types: select, checkbox, radio, switch, slider"
) %>%
  add_page(
    name = "Demo",
    data = demo_data,  # Full data with all metrics - JS handles switching
    content = this,
    icon = "ph:sliders",
    is_landing_page = TRUE
  )

# Generate
cat("\n=== Generating Input Types Demo ===\n")
generate_dashboard(dashboard, render = TRUE, open = "browser")
cat("\n=== Done! ===\n")
