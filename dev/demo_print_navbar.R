# Demo: Enhanced Print Output with Navbar Structure
# Shows how the print method now displays navbar menus and sidebar groups

devtools::load_all(".")

# Create a dashboard with navbar structure
dashboard <- create_dashboard(
  "navbar_demo",
  "Navbar Structure Demo",
  tabset_theme = "modern"
) %>%
  add_dashboard_page(
    "Home",
    text = "# Welcome",
    is_landing_page = TRUE,
    icon = "ph:house"
  ) %>%
  add_dashboard_page(
    "Analysis1",
    text = "# Analysis 1",
    icon = "ph:chart-bar",
    overlay = TRUE
  ) %>%
  add_dashboard_page(
    "Analysis2",
    text = "# Analysis 2",
    icon = "ph:chart-line"
  ) %>%
  add_dashboard_page(
    "Report1",
    text = "# Report 1",
    icon = "ph:file-text"
  ) %>%
  add_dashboard_page(
    "Report2",
    text = "# Report 2",
    icon = "ph:file-pdf"
  ) %>%
  add_dashboard_page(
    "About",
    text = "# About",
    icon = "ph:info",
    navbar_align = "right"
  )

# Add navbar menu for Analysis pages
dashboard <- dashboard %>%
  navbar_menu(
    text = "Analysis",
    pages = c("Analysis1", "Analysis2"),
    icon = "ph:chart-bar-horizontal"
  )

# Add sidebar group for Report pages
dashboard <- dashboard %>%
  sidebar_group(
    "Reports",
    pages = c("Report1", "Report2"),
    icon = "ph:file-text"
  )

cat("╔══════════════════════════════════════════════════════════╗\n")
cat("║  DEMO: Enhanced Print Output with Navbar Structure     ║\n")
cat("╚══════════════════════════════════════════════════════════╝\n\n")

print(dashboard)

cat("\n\n")
cat("Key improvements:\n")
cat("  ✓ Shows navbar menus with 📑 icon\n")
cat("  ✓ Shows sidebar groups with 📚 icon\n")
cat("  ✓ Displays nested structure of pages within menus/sidebars\n")
cat("  ✓ Shows pages not in any structure separately\n")
cat("  ✓ Clean tree visualization with proper indentation\n")
cat("  ✓ Removed progress bar for page generation (it's fast!)\n\n")

