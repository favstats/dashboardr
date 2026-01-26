# =================================================================
# Demo: Map Visualization Type
# =================================================================
# Demonstrates the new viz_map() function and add_viz(type = "map")
# for creating interactive choropleth maps with click navigation.
# =================================================================

library(dashboardr)
library(tidyverse)
library(highcharter)

# Output base directory - use tempdir() to avoid cluttering package directory
BASE_DIR <- file.path(tempdir(), "demo_maps")
cat("Output directory:", BASE_DIR, "\n")

# Create sample country data
country_data <- tibble(
  iso2c = c("US", "DE", "FR", "GB", "IT", "ES", "NL", "PL", "SE", "NO",
            "BR", "MX", "CA", "AU", "IN", "JP", "KR", "CN"),
  country = c("United States", "Germany", "France", "United Kingdom",
              "Italy", "Spain", "Netherlands", "Poland", "Sweden", "Norway",
              "Brazil", "Mexico", "Canada", "Australia", "India", "Japan",
              "South Korea", "China"),
  total_ads = c(15000, 8500, 6200, 7800, 4500, 3800, 2100, 3200, 1800, 1200,
                9500, 6800, 4200, 3100, 12000, 5500, 4800, 8900),
  total_spend = c(2500000, 1200000, 980000, 1100000, 650000, 520000, 380000,
                  420000, 290000, 180000, 1400000, 890000, 620000, 480000,
                  1800000, 820000, 710000, 1350000),
  category = sample(c("Political", "Commercial", "NGO"), 18, replace = TRUE)
)

# =================================================================
# Demo 1: Basic World Map
# =================================================================

cat("Creating Demo 1: Basic World Map...\n")

viz_basic <- create_viz() %>%
  add_viz(
    type = "map",
    value_var = "total_ads",
    join_var = "iso2c",
    title = "Ad Volume by Country",
    subtitle = "Total number of ads tracked",
    color_palette = c("#f7fbff", "#2171b5", "#08306b")
  )

demo1 <- create_dashboard(
  title = "Map Demo: Basic",
  output_dir = file.path(BASE_DIR, "demo_map_basic")
) %>%
  add_page(
    name = "World Map",
    data = country_data,
    visualizations = viz_basic,
    is_landing_page = TRUE
  )

# =================================================================
# Demo 2: Map with Click Navigation
# =================================================================

cat("Creating Demo 2: Map with Click Navigation...\n")

viz_clickable <- create_viz() %>%
  add_viz(
    type = "map",
    value_var = "total_ads",
    join_var = "iso2c",
    click_url_template = "{iso2c}_details.html",
    title = "Click a Country to Explore",
    subtitle = "Interactive map with navigation",
    color_palette = c("#eff3ff", "#6baed6", "#08519c"),
    tooltip_vars = c("country", "total_ads", "total_spend")
  )

demo2 <- create_dashboard(
  title = "Map Demo: Clickable",
  output_dir = file.path(BASE_DIR, "demo_map_clickable")
) %>%
  add_page(
    name = "World Map",
    data = country_data,
    visualizations = viz_clickable,
    is_landing_page = TRUE
  )

# =================================================================
# Demo 3: Map with Tabs (Multiple Metrics)
# =================================================================

cat("Creating Demo 3: Map with Tabs...\n")

viz_tabs <- create_viz() %>%
  add_viz(
    type = "map",
    value_var = "total_ads",
    join_var = "iso2c",
    tabgroup = "Metrics",
    title = "Total Ads",
    color_palette = c("#f7fbff", "#2171b5")
  ) %>%
  add_viz(
    type = "map",
    value_var = "total_spend",
    join_var = "iso2c",
    tabgroup = "Metrics",
    title = "Total Spend",
    color_palette = c("#fff5eb", "#d94801")
  )

demo3 <- create_dashboard(
  title = "Map Demo: Tabbed Metrics",
  output_dir = file.path(BASE_DIR, "demo_map_tabs")
) %>%
  add_page(
    name = "Metrics",
    data = country_data,
    visualizations = viz_tabs,
    is_landing_page = TRUE
  )

# =================================================================
# Demo 4: Map + Other Visualizations
# =================================================================

cat("Creating Demo 4: Map + Category Bar Chart...\n")

viz_combined <- create_viz() %>%
  add_viz(
    type = "map",
    value_var = "total_ads",
    join_var = "iso2c",
    tabgroup = "Views",
    title = "Map View",
    color_palette = c("#f7fbff", "#08306b")
  ) %>%
  add_viz(
    type = "bar",
    x_var = "category",
    tabgroup = "Views",
    title = "By Category",
    horizontal = TRUE
  )

demo4 <- create_dashboard(
  title = "Map Demo: Combined Views",
  output_dir = file.path(BASE_DIR, "demo_map_combined")
) %>%
  add_page(
    name = "Ad Analysis",
    data = country_data,
    visualizations = viz_combined,
    is_landing_page = TRUE
  )

# =================================================================
# Generate All Demos
# =================================================================

cat("\nGenerating all demos...\n\n")

# Using the new batch generation function
results <- generate_dashboards(
  list(
    basic = demo1,
    clickable = demo2,
    tabs = demo3,
    combined = demo4
  ),
  render = TRUE,
  continue_on_error = TRUE
)

cat("\n=== Demo Complete ===\n")
cat("Generated dashboards in:", BASE_DIR, "\n")
cat("  - demo_map_basic/docs/index.html\n")
cat("  - demo_map_clickable/docs/index.html\n")
cat("  - demo_map_tabs/docs/index.html\n")
cat("  - demo_map_combined/docs/index.html\n")

# Open the basic map demo in browser
cat("\nOpening demo_map_basic in browser...\n")
browseURL(file.path(BASE_DIR, "demo_map_basic/docs/index.html"))
