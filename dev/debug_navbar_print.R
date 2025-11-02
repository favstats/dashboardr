#!/usr/bin/env Rscript
# Debug why navbar hierarchy isn't showing in print method

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

# Create dashboard
dashboard <- create_dashboard(
  "debug_navbar",
  "Debug Navbar",
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

# Debug: Check what's in navbar_sections
cat("\n=== NAVBAR_SECTIONS CONTENT ===\n")
cat("Length:", length(dashboard$navbar_sections), "\n")
cat("Names:", names(dashboard$navbar_sections), "\n")
str(dashboard$navbar_sections)

cat("\n=== SIDEBAR_GROUPS CONTENT ===\n")
cat("Length:", length(dashboard$sidebar_groups), "\n")
str(dashboard$sidebar_groups)

