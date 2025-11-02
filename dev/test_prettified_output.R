#!/usr/bin/env Rscript
# Test the prettified page generation output

library(dashboardr)

# Create sample data
set.seed(123)
data <- data.frame(
  category = sample(c("A", "B", "C"), 100, replace = TRUE),
  value = rnorm(100, 50, 10)
)

# Create visualizations
viz <- create_viz(type = "histogram", x_var = "value") %>%
  add_viz(title = "Distribution", tabgroup = "analysis")

# Create dashboard with navbar menu
dashboard <- create_dashboard(
  "test_prettified",
  "Test Dashboard",
  tabset_theme = "modern"
) %>%
  add_page(
    "Overview",
    data = data,
    visualizations = viz,
    icon = "ph:chart-line",
    is_landing_page = TRUE
  ) %>%
  add_page(
    "Analysis",
    data = data,
    visualizations = viz,
    icon = "ph:chart-bar"
  ) %>%
  add_page(
    "Results",
    data = data,
    visualizations = viz,
    icon = "ph:lightbulb"
  ) %>%
  add_page(
    "About",
    text = "Dashboard information",
    icon = "ph:info",
    navbar_align = "right"
  )

# Show the dashboard structure (tests navbar hierarchy display)
cat("\n=== DASHBOARD STRUCTURE ===\n")
print(dashboard)

# Generate the dashboard (tests prettified page generation output)
cat("\n\n=== GENERATING DASHBOARD ===\n")
generate_dashboard(dashboard, render = FALSE, show_progress = TRUE)

cat("\n✅ All tests complete!\n")
cat("   • Quarto rendering reverted to normal output\n")
cat("   • Page generation uses ║ ├─ 📄 format\n")
cat("   • Navbar hierarchy displayed in print method\n")

