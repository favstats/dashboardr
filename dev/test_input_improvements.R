# Test: Input Filter Improvements
#
# Requirements:
# 1. Nicer input styling (more modern, polished)
# 2. Multiple inputs side by side work well
# 3. Timeline chart with actual lines through points
# 4. Hide unselected items from legend
# 5. Input placement option (position = "below_header" puts it under tabgroup header)

library(tidyverse)
devtools::install(quiet = TRUE, upgrade = "never")
library(dashboardr)

# =============================================================================
# Create sample data
# =============================================================================

set.seed(42)

countries <- c("Netherlands", "Germany", "United States", "United Kingdom",
               "France", "Global Average")
decades <- c("1970s", "1980s", "1990s", "2000s", "2010s", "2020s")
metrics <- c("Female Authorship", "WEIRD Studies", "Quantitative")

publication_data <- expand.grid(
  country = countries,
  decade = decades,
  stringsAsFactors = FALSE
) %>%
  mutate(
    decade_num = as.numeric(factor(decade)),
    pct_female = case_when(
      country == "Global Average" ~ 15 + decade_num * 5,
      TRUE ~ 10 + decade_num * 5 + rnorm(n(), 0, 3)
    ),
    pct_weird = case_when(
      country %in% c("United States", "United Kingdom") ~ 75 - decade_num * 4,
      country == "Global Average" ~ 60 - decade_num * 2,
      TRUE ~ 45 - decade_num * 2 + rnorm(n(), 0, 4)
    ),
    pct_quantitative = 60 + decade_num * 3 + rnorm(n(), 0, 3)
  ) %>%
  select(-decade_num)

# =============================================================================
# Create visualizations - USE TIMELINE with chart_type = "line" for connected lines!
# =============================================================================

viz <- create_viz() %>%
  # Female authorship - timeline with line chart
  add_viz(
    type = "timeline",
    time_var = "decade",
    y_var = "pct_female",
    group_var = "country",  # This creates series named by country!
    chart_type = "line",
    title = "% Female Authorship Over Time",
    subtitle = "Trend lines by country",
    x_label = "Decade",
    y_label = "Percentage",
    tabgroup = "trends/Female Authorship"
  ) %>%
  # WEIRD studies
  add_viz(
    type = "timeline",
    time_var = "decade",
    y_var = "pct_weird",
    group_var = "country",
    chart_type = "line",
    title = "% WEIRD Country Studies",
    subtitle = "Percentage over time",
    x_label = "Decade",
    y_label = "Percentage",
    tabgroup = "trends/WEIRD Studies"
  ) %>%
  # Quantitative studies
  add_viz(
    type = "timeline",
    time_var = "decade",
    y_var = "pct_quantitative",
    group_var = "country",
    chart_type = "line",
    title = "% Quantitative Studies",
    x_label = "Decade",
    y_label = "Percentage",
    tabgroup = "trends/Quantitative"
  )

# =============================================================================
# Create content with MULTIPLE inputs side by side
# =============================================================================

content <- create_content() %>%
  add_text(md_text(
    "# Publication Trends Analysis",
    "",
    "Compare publication metrics across countries and time periods.",
    "Use the filters below to select which data to display."
  )) %>%
  # Multiple inputs in a row with inline styling!
  add_input_row(style = "inline", align = "left") %>%
    add_input(
      input_id = "country_filter",
      label = "Select Countries:",
      filter_var = "country",
      options = countries,
      default_selected = c("Netherlands", "Germany", "Global Average"),
      placeholder = "Choose countries...",
      width = "350px"
    ) %>%
    add_input(
      input_id = "decade_filter",
      label = "Filter Decades:",
      filter_var = "decade",
      options = decades,
      default_selected = decades,  # All selected by default
      placeholder = "Choose decades...",
      width = "280px"
    ) %>%
  end_input_row() %>%
  add_spacer(height = "0.5rem")

# =============================================================================
# Create dashboard
# =============================================================================

dashboard <- create_dashboard(
  title = "Publication Trends Dashboard",
  output_dir = "test_input_improvements",
  tabset_theme = "modern",
  author = "dashboardr Demo"
) %>%
  add_page(
    name = "Country Trends",
    data = publication_data,
    visualizations = viz,
    content = content,
    icon = "ph:chart-line",
    is_landing_page = TRUE
  ) %>%
  add_page(
    name = "About",
    text = md_text(
      "# About",
      "",
      "This dashboard demonstrates improved input filtering with:",
      "",
      "- Multiple inputs side by side",
      "- Line charts with connected points",
      "- Hidden legend items for unselected series",
      "- Modern, polished styling"
    ),
    icon = "ph:info"
  )

# Generate and render
cat("\n=== Generating dashboard ===\n")
generate_dashboard(dashboard, render = TRUE, open = "browser")
cat("\n=== Done ===\n")
