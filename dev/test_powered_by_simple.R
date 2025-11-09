# Quick test of add_powered_by_dashboardr()
library(dashboardr)

# Simple dashboard with branding
dashboard <- create_dashboard(
  output_dir = "test_powered_by_demo",
  title = "Test Dashboard",
  page_footer = "© 2025 Test Company"
) %>%
  add_page(
    name = "Home",
    text = md_text(
      "## Welcome!",
      "",
      "This is a simple test of the `add_powered_by_dashboardr()` function.",
      "",
      "**Check the footer at the bottom of the page:**",
      "",
      "- **Left**: Your custom copyright notice",
      "- **Right**: Sleek 'Powered by dashboardr' branding with the **real dashboardr logo**!",
      "",
      "### Features:",
      "- ✓ Small and subtle (60% opacity)",
      "- ✓ Hover to see it brighten to 100%",
      "- ✓ Clickable link to dashboardr documentation",
      "- ✓ **Actual dashboardr hexagonal logo** (loaded from GitHub)",
      "- ✓ Seamlessly integrated with your footer",
      "",
      "Try the different styles in `demo_powered_by.R`!"
    ),
    is_landing_page = TRUE
  ) %>%
  add_powered_by_dashboardr()  # That's all you need!

# Generate and open
generate_dashboard(dashboard, render = TRUE, open = "browser")

