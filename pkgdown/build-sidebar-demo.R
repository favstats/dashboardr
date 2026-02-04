# Build Sidebar Demo Dashboard
# Showcases sidebar functionality with filters and inputs
# Run from package root: source("pkgdown/build-sidebar-demo.R")

library(dplyr)
library(tidyr)

# Load development version of dashboardr
if (file.exists("DESCRIPTION")) {
  devtools::load_all()
} else {
  library(dashboardr)
}

cat("📊 Building Sidebar Demo Dashboard...\n\n")

# =============================================================================
# Generate demo data - Economic indicators for multiple countries
# =============================================================================

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

# =============================================================================
# Find package root and set output directory
# =============================================================================

find_pkg_root <- function() {
  dir <- getwd()
  for (i in 1:10) {
    if (file.exists(file.path(dir, "DESCRIPTION"))) {
      return(dir)
    }
    parent <- dirname(dir)
    if (parent == dir) break
    dir <- parent
  }
  if (requireNamespace("here", quietly = TRUE)) {
    return(here::here())
  }
  stop("Could not find package root. Run from package directory.")
}

pkg_root <- find_pkg_root()
output_dir <- file.path(pkg_root, "docs", "live-demos", "sidebar")

cat("   Package root:", pkg_root, "\n")
cat("   Output dir:", output_dir, "\n\n")

# =============================================================================
# PAGE 1: GDP Growth with Checkbox Filter (Left Sidebar)
# =============================================================================

cat("📄 Creating Page 1: GDP Growth (Checkbox filter)...\n")

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

page1 <- create_page("GDP Growth", data = gdp_data, icon = "ph:chart-line-up", is_landing_page = TRUE) %>%
  add_content(page1_content)

# =============================================================================
# PAGE 2: Unemployment with Multi-Select (Left Sidebar)
# =============================================================================

cat("📄 Creating Page 2: Unemployment (Multi-select)...\n")

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

page2 <- create_page("Unemployment", data = unemployment_data, icon = "ph:users") %>%
  add_content(page2_content)

# =============================================================================
# PAGE 3: Combined View with Radio + Checkbox (Right Sidebar)
# =============================================================================

cat("📄 Creating Page 3: Combined (Radio + Checkbox, Right sidebar)...\n")

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

page3 <- create_page("Combined", data = demo_data, icon = "ph:arrows-merge") %>%
  add_content(page3_content)

# =============================================================================
# PAGE 4: Year Filter with Slider
# =============================================================================

cat("📄 Creating Page 4: Slider Demo...\n")

page4_content <- create_content(data = gdp_data) %>%
  add_sidebar(width = "280px", title = "Year Range") %>%
    add_text("Use the slider to filter the timeline starting from a specific year.") %>%
    add_divider() %>%
    add_input(
      input_id = "year_slider",
      label = "Start Year:",
      type = "slider",
      filter_var = "year",
      min = 2018,
      max = 2024,
      value = 2018,
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
    add_callout("Move the slider to filter data from a specific year onwards.", type = "tip") %>%
  end_sidebar() %>%
  add_viz(
    type = "timeline",
    time_var = "year",
    y_var = "value",
    group_var = "country",
    agg = "none",
    chart_type = "line",
    title = "GDP Growth Over Time",
    y_label = "Growth Rate (%)",
    x_label = "Year"
  )

page4 <- create_page("Slider Demo", data = gdp_data, icon = "ph:sliders-horizontal") %>%
  add_content(page4_content)

# =============================================================================
# PAGE 5: About (No Sidebar)
# =============================================================================

cat("📄 Creating Page 5: About...\n")

page5 <- create_page("About", icon = "ph:info") %>%
  add_text("### About This Dashboard") %>%
  add_text("This dashboard demonstrates the **multi-page sidebar** feature in dashboardr.") %>%
  add_text("Each page can have:") %>%
  add_text("- Its own sidebar (or none)") %>%
  add_text("- Different input types (checkbox, radio, select, slider)") %>%
  add_text("- Left or right sidebar position") %>%
  add_text("- Independent filtering for that page's visualizations") %>%
  add_text("- Multi-column grid layouts for checkboxes (using `columns = 2`)") %>%
  add_divider() %>%
  add_text("### Features Demonstrated") %>%
  add_text("1. **GDP Growth**: Left sidebar with checkbox filters in 2-column grid") %>%
  add_text("2. **Unemployment**: Left sidebar with multi-select dropdown") %>%
  add_text("3. **Combined**: Right sidebar with radio buttons + checkboxes") %>%
  add_text("4. **Slider Demo**: Left sidebar with year slider + checkboxes") %>%
  add_divider() %>%
  add_text("*Data is simulated for demonstration purposes.*")

# =============================================================================
# Create and generate the dashboard
# =============================================================================

cat("\n🔧 Building dashboard...\n")

dashboard <- create_dashboard(
  title = "Sidebar Demo",
  output_dir = output_dir,
  theme = "cosmo",
  allow_inside_pkg = TRUE
) %>%
  add_page(page1) %>%
  add_page(page2) %>%
  add_page(page3) %>%
  add_page(page4) %>%
  add_page(page5) %>%
  add_powered_by_dashboardr(style = "minimal")

# Generate the dashboard
result <- generate_dashboard(dashboard, render = TRUE, open = FALSE)

cat("\n✅ Sidebar demo built successfully!\n")
cat("   Location:", output_dir, "\n")
cat("   Open:", file.path(output_dir, "index.html"), "\n\n")

# Note: No need to create about.md since we have about.qmd page
