library(dashboardr)

# Create a dashboard with loading overlays
dashboard <- create_dashboard(
  title = "Loading Overlay Demo",
  author = "Demo User",
  output_dir = "demo_loading_overlay",
  sidebar = FALSE
)

# Landing page with accent theme overlay
dashboard <- dashboard %>%
  add_dashboard_page(
    name = "Welcome",
    text = "# Welcome to the Dashboard\n\nThis page has a loading overlay with the **accent** theme.",
    is_landing_page = TRUE,
    overlay = TRUE,
    overlay_theme = "accent",
    overlay_text = "Loading dashboard..."
  )

# Page with light theme (default)
dashboard <- dashboard %>%
  add_dashboard_page(
    name = "Light Theme",
    text = "# Light Theme\n\nThis page uses the default **light** overlay theme.",
    overlay = TRUE
    # overlay_theme defaults to "light"
    # overlay_text defaults to "Loading"
  )

# Page with glass theme
dashboard <- dashboard %>%
  add_dashboard_page(
    name = "Glass Theme",
    text = "# Glass Theme\n\nThis page uses the modern **glass** overlay theme with glassmorphism effects.",
    overlay = TRUE,
    overlay_theme = "glass",
    overlay_text = "Even wachten…"
  )

# Page with dark theme
dashboard <- dashboard %>%
  add_dashboard_page(
    name = "Dark Theme",
    text = "# Dark Theme\n\nThis page uses the sleek **dark** overlay theme.",
    overlay = TRUE,
    overlay_theme = "dark",
    overlay_text = "Loading..."
  )

# Page WITHOUT overlay for comparison
dashboard <- dashboard %>%
  add_dashboard_page(
    name = "No Overlay",
    text = "# No Overlay\n\nThis page loads immediately without an overlay.",
    overlay = FALSE  # This is the default
  )

# Generate the dashboard
generate_dashboard(dashboard, render = FALSE)

cat("\n✅ Dashboard generated!\n")
cat("📁 Output directory: demo_loading_overlay\n")
cat("🌐 To view, render with Quarto:\n")
cat("   cd demo_loading_overlay && quarto preview\n\n")
cat("📋 Pages created:\n")
cat("  1. Welcome (accent theme) - 'Loading dashboard...'\n")
cat("  2. Light Theme (light theme) - 'Loading'\n")
cat("  3. Glass Theme (glass theme) - 'Even wachten…'\n")
cat("  4. Dark Theme (dark theme) - 'Loading...'\n")
cat("  5. No Overlay (no loading overlay)\n\n")
cat("💡 Each overlay disappears after ~2.2 seconds\n")

