# =================================================================
# Demo: Linked Map Navigation
# =================================================================
# Demonstrates a main map dashboard that links to country dashboards
# This is the pattern for the elex worldwide use case.
# =================================================================

library(dashboardr)
library(tidyverse)

# Output directory - use tempdir() to avoid cluttering package directory
OUTPUT_DIR <- file.path(tempdir(), "demo_linked_dashboards")
cat("Output directory:", OUTPUT_DIR, "\n")

# Create sample country data
country_data <- tibble(
  iso2c = c("US", "DE", "FR", "GB", "IT"),
  country = c("United States", "Germany", "France", "United Kingdom", "Italy"),
  total_ads = c(15000, 8500, 6200, 7800, 4500),
  total_spend = c(2500000, 1200000, 980000, 1100000, 650000)
)

# Per-country detailed data (simulated)
make_country_detail <- function(iso2c, n = 100) {
  tibble(
    target = sample(c("Age", "Gender", "Location", "Interest", "Custom"), n, replace = TRUE),
    category = sample(c("Political Party", "Politician", "Government"), n, replace = TRUE),
    spend = runif(n, 100, 10000)
  )
}

# =================================================================
# 1. Create Main Map Dashboard
# =================================================================

cat("Creating main map dashboard...\n")

main_viz <- create_viz() %>%
  add_viz(
    type = "map",
    value_var = "total_ads",
    join_var = "iso2c",
    # This template creates links to country subdirectories
    click_url_template = "{iso2c}/index.html",
    title = "Election Ad Targeting by Country",
    subtitle = "Click a country to see detailed targeting data",
    color_palette = c("#f7fbff", "#2171b5", "#08306b"),
    tooltip_vars = c("country", "total_ads", "total_spend")
  )

main_dashboard <- create_dashboard(
  title = "Linked Map Demo",
  output_dir = OUTPUT_DIR
) %>%
  add_page(
    name = "World Map",
    data = country_data,
    visualizations = main_viz,
    is_landing_page = TRUE
  )

# =================================================================
# 2. Create Country Dashboards
# =================================================================

cat("Creating country dashboards...\n")

# Shared viz for all country dashboards
country_viz <- create_viz(
  type = "stackedbar",
  stacked_type = "percent",
  x_var = "target",
  stack_var = "category",
  horizontal = TRUE
) %>%
  add_viz(title = "Targeting Breakdown")

# Create dashboards using purrr::map (or use a for loop - same result)
country_dashboards <- country_data$iso2c %>%
  set_names() %>%
  map(~{
    country_name <- country_data$country[country_data$iso2c == .x]
    
    create_dashboard(
      title = paste("Election Ads:", country_name),
      output_dir = file.path(OUTPUT_DIR, .x)
    ) %>%
      add_page(
        name = "Targeting",
        data = make_country_detail(.x),
        visualizations = country_viz,
        is_landing_page = TRUE,
        text = paste0("[← Back to World Map](../index.html#)\n\n# ", country_name, " Targeting")
      )
  })

# =================================================================
# 3. Generate All Dashboards
# =================================================================

cat("\nGenerating all dashboards...\n\n")

# Combine main + country dashboards
all_dashboards <- c(
  list(main = main_dashboard),
  country_dashboards
)

# Generate with batch function - linked = TRUE aligns outputs automatically!
results <- generate_dashboards(
  all_dashboards,
  render = TRUE,
  continue_on_error = TRUE,
  linked = TRUE,  # Sub-dashboards go to main's docs/{name}/ automatically
  open = TRUE     # Open the main dashboard when done
)

# =================================================================
# Summary and Open
# =================================================================

cat("\n=== Demo Complete ===\n")
cat("Output:", OUTPUT_DIR, "\n")
cat("Structure:\n")
cat("  docs/\n")
cat("  ├── index.html        (main map)\n")
cat("  ├── US/index.html     (US details)\n")
cat("  ├── DE/index.html     (Germany details)\n")
cat("  ├── FR/index.html     (France details)\n")
cat("  ├── GB/index.html     (UK details)\n")
cat("  └── IT/index.html     (Italy details)\n")
cat("\nClick any country on the map to navigate to its dashboard!\n")
