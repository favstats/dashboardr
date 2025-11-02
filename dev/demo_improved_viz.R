devtools::load_all("..")

cat("\n═══════════════════════════════════════════════════════════════\n")
cat("  DEMO: Improved Dashboard Structure Visualization\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

# Create a complex dashboard structure to showcase the improved visualization
dashboard <- create_dashboard(
  title = "Research Dashboard 2024",
  author = "Data Science Team",
  description = "Comprehensive analysis of survey data",
  output_dir = "demo_viz_structure",
  sidebar = TRUE,
  search = TRUE,
  theme = "cosmo",
  tabset_theme = "pills",
  github = "https://github.com/example/repo"
)

# Create complex nested visualizations
viz <- create_viz(
  type = "stackedbar",
  color_palette = c("#d7191c", "#fdae61", "#2b83ba")
) %>%
  add_viz(title = "Overall Results", tabgroup = "results/overall") %>%
  add_viz(title = "By Age", tabgroup = "results/demographics/age") %>%
  add_viz(title = "By Gender", tabgroup = "results/demographics/gender") %>%
  add_viz(title = "By Education", tabgroup = "results/demographics/education") %>%
  add_viz(title = "Wave 1", tabgroup = "results/timeline/wave1") %>%
  add_viz(title = "Wave 2", tabgroup = "results/timeline/wave2") %>%
  add_viz(title = "Wave 3", tabgroup = "results/timeline/wave3")

cat("1️⃣  Displaying viz_collection object:\n")
cat("─────────────────────────────────────────────────────────────\n")
print(viz)

cat("\n2️⃣  Adding pages to dashboard...\n")

# Add landing page with overlay
dashboard <- dashboard %>%
  add_dashboard_page(
    "Home",
    text = "# Welcome\n\nThis is the landing page.",
    is_landing_page = TRUE,
    overlay = TRUE,
    overlay_theme = "accent"
  )

# Add analysis page with complex visualizations
dashboard <- dashboard %>%
  add_dashboard_page(
    "Analysis",
    text = "# Analysis Results",
    visualizations = viz,
    icon = "ph:chart-bar",
    overlay = TRUE,
    overlay_text = "Loading analysis..."
  )

# Add timeline visualizations
timeline_viz <- create_viz(type = "timeline", time_var = "wave") %>%
  add_viz(response_var = "satisfaction", tabgroup = "trends/satisfaction") %>%
  add_viz(response_var = "engagement", tabgroup = "trends/engagement") %>%
  add_viz(response_var = "performance", tabgroup = "trends/performance")

dashboard <- dashboard %>%
  add_dashboard_page(
    "Trends",
    text = "# Longitudinal Trends",
    visualizations = timeline_viz,
    icon = "ph:chart-line"
  )

# Add about page on the right
dashboard <- dashboard %>%
  add_dashboard_page(
    "About",
    text = "# About This Dashboard\n\nMethodology and details.",
    icon = "ph:info",
    navbar_align = "right"
  )

cat("\n3️⃣  Displaying complete dashboard_project object:\n")
cat("─────────────────────────────────────────────────────────────\n")
print(dashboard)

cat("\n✅ Demo complete! Notice the improved tree visualization showing:\n")
cat("   • Clear hierarchical structure with box-drawing characters\n")
cat("   • Emoji icons for different visualization types\n")
cat("   • Tabgroup nesting levels clearly visible\n")
cat("   • Page metadata (landing, overlay, navbar alignment, etc.)\n")
cat("   • Feature badges and integrations\n\n")

