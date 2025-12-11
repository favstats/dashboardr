# Minimal test for input filter functionality
library(tidyverse)

# Install development version first
devtools::install(quiet = TRUE, upgrade = "never")
library(dashboardr)

# Set Quarto path for this session
Sys.setenv(QUARTO_PATH = "/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto")

# Simple data
data <- data.frame(
  country = rep(c("Netherlands", "Germany", "USA"), each = 3),
  year = rep(c(2020, 2021, 2022), 3),
  value = c(10, 15, 20, 25, 30, 35, 40, 45, 50)
)

# Create visualization with color_var (creates series per country)
viz <- create_viz() %>%
  add_viz(
    type = "scatter",
    x_var = "year",
    y_var = "value",
    color_var = "country",
    title = "Test Chart"
  )

# Create content with input
content <- create_content() %>%
  add_input_row() %>%
    add_input(
      input_id = "country_filter",
      label = "Select Countries:",
      filter_var = "country",
      options = c("Netherlands", "Germany", "USA"),
      default_selected = c("Netherlands", "Germany"),
      width = "350px"
    ) %>%
  end_input_row()

# Create dashboard
dashboard <- create_dashboard(
  title = "Input Test",
  output_dir = "test_input_minimal",
  tabset_theme = "modern"
) %>%
  add_page(
    name = "Test",
    data = data,
    visualizations = viz,
    content = content,
    is_landing_page = TRUE
  )

# Generate AND render
cat("\n=== Generating dashboard ===\n")
generate_dashboard(dashboard, render = TRUE, open = "browser")
cat("\n=== Done ===\n")
