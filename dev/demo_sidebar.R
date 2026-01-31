# =============================================================================
# Demo: Multi-Page Sidebar Feature
#
# Demonstrates the add_sidebar() / end_sidebar() functionality
# with multiple pages, each having different inputs and sidebars
# =============================================================================

library(tidyverse)
devtools::load_all()

set.seed(2024)

# Create demo data - GDP and unemployment for multiple countries
# Note: Keep year as numeric for slider filtering to work correctly
demo_data <- expand_grid(
  country = c("Netherlands", "Germany", "France", "United Kingdom", "Italy"),
  year = 2018:2024,
  metric = c("GDP Growth", "Unemployment")
) %>%
  mutate(
    value = case_when(
      # GDP Growth rates
      metric == "GDP Growth" & country == "Netherlands" ~ 2.5 + (year - 2018) * 0.3 + rnorm(n(), 0, 0.5),
      metric == "GDP Growth" & country == "Germany" ~ 1.8 + (year - 2018) * 0.2 + rnorm(n(), 0, 0.6),
      metric == "GDP Growth" & country == "France" ~ 1.5 + (year - 2018) * 0.25 + rnorm(n(), 0, 0.4),
      metric == "GDP Growth" & country == "United Kingdom" ~ 1.2 + (year - 2018) * 0.15 + rnorm(n(), 0, 0.5),
      metric == "GDP Growth" & country == "Italy" ~ 0.8 + (year - 2018) * 0.35 + rnorm(n(), 0, 0.3),
      # Unemployment rates
      metric == "Unemployment" & country == "Netherlands" ~ 4.5 - (year - 2018) * 0.2 + rnorm(n(), 0, 0.3),
      metric == "Unemployment" & country == "Germany" ~ 3.8 - (year - 2018) * 0.15 + rnorm(n(), 0, 0.4),
      metric == "Unemployment" & country == "France" ~ 8.5 - (year - 2018) * 0.3 + rnorm(n(), 0, 0.5),
      metric == "Unemployment" & country == "United Kingdom" ~ 4.2 - (year - 2018) * 0.1 + rnorm(n(), 0, 0.3),
      TRUE ~ 10.5 - (year - 2018) * 0.4 + rnorm(n(), 0, 0.6)  # Italy
    )
  )

# Split data for different pages
gdp_data <- demo_data %>% filter(metric == "GDP Growth")
unemployment_data <- demo_data %>% filter(metric == "Unemployment")

# Output directory
output_dir <- file.path(tempdir(), "sidebar_multipage_demo")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# =============================================================================
# PAGE 1: GDP Growth with country filter (checkbox)
# =============================================================================

page1_content <- create_content(data = gdp_data) %>%
  add_sidebar(width = "280px", title = "Country Filter") %>%
    add_text("Select countries to compare GDP growth rates.") %>%
    add_divider() %>%
    add_input(
      input_id = "country_filter",
      label = "Countries:",
      type = "checkbox",
      filter_var = "country",
      options = c("Netherlands", "Germany", "France", "United Kingdom", "Italy"),
      default_selected = c("Netherlands", "Germany", "France"),
      columns = 2
    ) %>%
    add_spacer(height = "1rem") %>%
    add_callout("GDP growth is the annual percentage change in real GDP.", type = "note") %>%
  end_sidebar() %>%
  add_viz(
    type = "timeline",
    time_var = "year",
    y_var = "value",
    group_var = "country",
    agg = "none",
    chart_type = "line",
    title = "GDP Growth Rate by Country",
    y_label = "Growth Rate (%)",
    x_label = "Year"
  )

page1 <- create_page("GDP Growth", data = gdp_data) %>%
  add_content(page1_content)

# =============================================================================
# PAGE 2: Unemployment with country filter (different input type)
# =============================================================================

page2_content <- create_content(data = unemployment_data) %>%
  add_sidebar(width = "280px", title = "Country Filter", position = "left") %>%
    add_text("Select countries using dropdown.") %>%
    add_divider() %>%
    add_input(
      input_id = "country_select",
      label = "Select Countries:",
      type = "select_multiple",
      filter_var = "country",
      options = c("Netherlands", "Germany", "France", "United Kingdom", "Italy"),
      default_selected = c("Netherlands", "Germany", "France")
    ) %>%
    add_spacer(height = "1rem") %>%
    add_badge("Eurostat Data", color = "primary") %>%
    add_text("*Unemployment as % of labor force*") %>%
  end_sidebar() %>%
  add_viz(
    type = "timeline",
    time_var = "year",
    y_var = "value",
    group_var = "country",
    agg = "none",
    chart_type = "line",
    title = "Unemployment Rate Over Time",
    y_label = "Unemployment Rate (%)",
    x_label = "Year"
  )

page2 <- create_page("Unemployment", data = unemployment_data) %>%
  add_content(page2_content)

# =============================================================================
# PAGE 3: Combined view with metric selector (right sidebar)
# =============================================================================

page3_content <- create_content(data = demo_data) %>%
  add_sidebar(width = "300px", title = "Data Selection", position = "right") %>%
    add_text("Choose metric and countries to display.") %>%
    add_divider() %>%
    add_input(
      input_id = "metric_filter",
      label = "Metric:",
      type = "radio",
      filter_var = "metric",
      options = c("GDP Growth", "Unemployment"),
      default_selected = "GDP Growth"
    ) %>%
    add_spacer(height = "0.5rem") %>%
    add_input(
      input_id = "country_filter2",
      label = "Countries:",
      type = "checkbox",
      filter_var = "country",
      options = c("Netherlands", "Germany", "France", "United Kingdom", "Italy"),
      default_selected = c("Netherlands", "Germany"),
      columns = 2
    ) %>%
    add_divider() %>%
    add_callout("Switch between GDP Growth and Unemployment using the radio buttons above.", type = "tip") %>%
  end_sidebar() %>%
  add_viz(
    type = "timeline",
    time_var = "year",
    y_var = "value",
    group_var = "country",
    agg = "none",
    chart_type = "line",
    title = "Economic Indicators Over Time",
    y_label = "Value (%)",
    x_label = "Year"
  )

page3 <- create_page("Combined", data = demo_data) %>%
  add_content(page3_content)

# =============================================================================
# PAGE 4: Year filter with SLIDER
# =============================================================================

page4_content <- create_content(data = gdp_data) %>%
  add_sidebar(width = "280px", title = "Year Range") %>%
    add_text("Use the slider to filter by year.") %>%
    add_divider() %>%
    add_input(
      input_id = "year_slider",
      label = "Select Year:",
      type = "slider",
      filter_var = "year",
      min = 2018,
      max = 2024,
      value = 2021,
      step = 1
    ) %>%
    add_spacer(height = "1rem") %>%
    add_input(
      input_id = "country_filter3",
      label = "Countries:",
      type = "checkbox",
      filter_var = "country",
      options = c("Netherlands", "Germany", "France", "United Kingdom", "Italy"),
      default_selected = c("Netherlands", "Germany", "France"),
      columns = 2
    ) %>%
    add_divider() %>%
    add_callout("Drag the slider to select a specific year.", type = "tip") %>%
  end_sidebar() %>%
  add_viz(
    type = "bar",
    x_var = "country",
    value_var = "value",
    bar_type = "mean",
    title = "GDP Growth by Country",
    y_label = "Growth Rate (%)",
    x_label = "Country"
  )

page4 <- create_page("Slider Demo", data = gdp_data) %>%
  add_content(page4_content)

# =============================================================================
# PAGE 5: Summary page WITHOUT sidebar
# =============================================================================

page5 <- create_page("About") %>%
  add_text("### About This Dashboard") %>%
  add_text("This dashboard demonstrates the **multi-page sidebar** feature in dashboardr.") %>%
  add_text("Each page can have:") %>%
  add_text("- Its own sidebar (or none)") %>%
  add_text("- Different input types (checkbox, radio, select, etc.)") %>%
  add_text("- Left or right sidebar position") %>%
  add_text("- Independent filtering for that page's visualizations") %>%
  add_divider() %>%
  add_text("*Data is simulated for demonstration purposes.*")

# =============================================================================
# Create and generate the dashboard
# =============================================================================

dashboard <- create_dashboard(
  title = "Multi-Page Sidebar Demo",
  output_dir = "output_dir",
  theme = "cosmo"
) %>%
  add_page(page1) %>%
  add_page(page2) %>%
  add_page(page3) %>%
  add_page(page4) %>%
  add_page(page5)

# Generate and preview
generate_dashboard(dashboard, open = "browser")

cat("\n\n=== Dashboard generated at:", output_dir, "===\n")
cat("Pages:\n")
cat("  1. GDP Growth - checkbox filter (left sidebar)\n")
cat("  2. Unemployment - multi-select filter (left sidebar)\n")
cat("  3. Combined - radio + checkbox filters (RIGHT sidebar)\n")
cat("  4. Slider Demo - slider + checkbox filters (left sidebar)\n")
cat("  5. About - no sidebar\n")
