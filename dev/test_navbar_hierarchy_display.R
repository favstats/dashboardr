#!/usr/bin/env Rscript
# Test navbar hierarchy display in print method

devtools::load_all(".")

# Create sample data
data <- data.frame(x = rnorm(100))

# Create navbar menu
reports_menu <- navbar_menu(
  text = "Reports",
  pages = c("Monthly", "Quarterly", "Annual"),
  icon = "ph:file-text"
)

# Create sidebar group
analysis_sidebar <- sidebar_group(
  id = "analysis_group",
  title = "Analysis",
  pages = c("Analysis", "Insights")
)

# Create navbar section pointing to sidebar
analysis_section <- navbar_section(
  text = "Analysis",
  sidebar_id = "analysis_group",
  icon = "ph:chart-line"
)

# Create dashboard with navbar menu and sidebar
dashboard <- create_dashboard(
  "test_navbar_hierarchy",
  "Test Navbar Hierarchy Display",
  sidebar_groups = list(analysis_sidebar),
  navbar_sections = list(analysis_section, reports_menu)
) %>%
  add_page("Home", data = data, is_landing_page = TRUE) %>%
  add_page("Analysis", data = data) %>%
  add_page("Insights", data = data) %>%
  add_page("Monthly", data = data) %>%
  add_page("Quarterly", data = data) %>%
  add_page("Annual", data = data) %>%
  add_page("About", text = "Info", navbar_align = "right")

# Show the dashboard structure - should display navbar hierarchy
cat("\n╔════════════════════════════════════════════════════╗\n")
cat("║  TESTING NAVBAR HIERARCHY DISPLAY IN PRINT METHOD ║\n")
cat("╚════════════════════════════════════════════════════╝\n")
print(dashboard)

cat("\n✅ Expected output:\n")
cat("   • 📚 Analysis (Sidebar) with nested pages\n")
cat("   • 📑 Reports (Menu) with nested pages\n")
cat("   • Individual pages (Home, About) listed separately\n")

