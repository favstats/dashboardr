library(dashboardr)

# Create a dashboard with pages on left and right of navbar
dashboard <- create_dashboard(
  title = "Navbar Alignment Demo",
  author = "Demo User",
  output_dir = "demo_navbar_align",
  sidebar = FALSE  # Disable sidebar for simpler demo
)

# Add landing page (always appears as "Home" on left)
dashboard <- dashboard %>%
  add_dashboard_page(
    name = "Welcome",
    text = "# Welcome\n\nThis is the landing page.",
    is_landing_page = TRUE
  )

# Add pages to the LEFT side of navbar (default)
dashboard <- dashboard %>%
  add_dashboard_page(
    name = "Dashboard",
    text = "# Dashboard\n\nThis page appears on the left.",
    navbar_align = "left",  # Explicit left (this is the default)
    icon = "ph:chart-bar"
  ) %>%
  add_dashboard_page(
    name = "Analysis",
    text = "# Analysis\n\nThis page also appears on the left.",
    navbar_align = "left",
    icon = "ph:chart-line"
  )

# Add pages to the RIGHT side of navbar
dashboard <- dashboard %>%
  add_dashboard_page(
    name = "About",
    text = "# About\n\nThis page appears on the right side of the navbar.",
    navbar_align = "right",
    icon = "ph:info"
  ) %>%
  add_dashboard_page(
    name = "Contact",
    text = "# Contact\n\nThis page also appears on the right side.",
    navbar_align = "right",
    icon = "ph:envelope"
  )

# Generate the dashboard
generate_dashboard(dashboard)

cat("\n✅ Dashboard generated!\n")
cat("📁 Output directory: demo_navbar_align\n")
cat("🌐 Open demo_navbar_align/index.html to view\n\n")
cat("Layout:\n")
cat("  Navbar left:  Home | Dashboard | Analysis\n")
cat("  Navbar right: About | Contact\n")

