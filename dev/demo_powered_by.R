# DEMO: add_powered_by_dashboardr() function
# This demonstrates the different styles and use cases for adding
# dashboardr branding to your dashboard footer

devtools::load_all()
library(dplyr)

# Sample data
data <- data.frame(
  category = c("A", "B", "C", "D"),
  value = c(23, 45, 12, 67)
)

# =============================================================================
# EXAMPLE 1: Default style (small, subtle)
# =============================================================================

dashboard_default <- create_dashboard(
  output_dir = "demo_powered_by_default",
  title = "Dashboard with Default Branding"
) %>%
  add_page(
    name = "Home",
    text = md_text(
      "## Welcome!",
      "",
      "This dashboard uses the **default** 'Powered by dashboardr' branding.",
      "",
      "Check the footer at the bottom right!"
    ),
    is_landing_page = TRUE
  ) %>%
  add_powered_by_dashboardr()  # Default: small size, default style

# Generate
# generate_dashboard(dashboard_default, render = TRUE, open = "browser")


# =============================================================================
# EXAMPLE 2: With existing footer (left + right)
# =============================================================================

dashboard_with_footer <- create_dashboard(
  output_dir = "demo_powered_by_with_footer",
  title = "Dashboard with Custom Footer",
  page_footer = "© 2025 My Company - All Rights Reserved"
) %>%
  add_page(
    name = "Home",
    text = md_text(
      "## Dashboard with Both Footers",
      "",
      "Notice how the dashboardr branding appears on the right,",
      "while your custom copyright notice stays on the left!"
    ),
    is_landing_page = TRUE
  ) %>%
  add_powered_by_dashboardr()  # Will add to right, keeps existing on left

# Generate
# generate_dashboard(dashboard_with_footer, render = TRUE, open = "browser")


# =============================================================================
# EXAMPLE 3: Minimal style
# =============================================================================

dashboard_minimal <- create_dashboard(
  output_dir = "demo_powered_by_minimal",
  title = "Dashboard with Minimal Branding"
) %>%
  add_page(
    name = "Home",
    text = md_text(
      "## Minimal Branding",
      "",
      "This uses the **minimal** style: just text, no icon.",
      "",
      "Perfect for ultra-clean designs!"
    ),
    is_landing_page = TRUE
  ) %>%
  add_powered_by_dashboardr(style = "minimal")

# Generate
# generate_dashboard(dashboard_minimal, render = TRUE, open = "browser")


# =============================================================================
# EXAMPLE 4: Badge style
# =============================================================================

dashboard_badge <- create_dashboard(
  output_dir = "demo_powered_by_badge",
  title = "Dashboard with Badge Branding"
) %>%
  add_page(
    name = "Home",
    text = md_text(
      "## Badge Style",
      "",
      "This uses the **badge** style with a subtle background box.",
      "",
      "Hover over it to see the nice transition effect!"
    ),
    is_landing_page = TRUE
  ) %>%
  add_powered_by_dashboardr(style = "badge", size = "large")

# Generate
generate_dashboard(dashboard_badge, render = TRUE, open = "browser")


# =============================================================================
# EXAMPLE 5: Larger size
# =============================================================================

dashboard_large <- create_dashboard(
  output_dir = "demo_powered_by_large",
  title = "Dashboard with Large Branding"
) %>%
  add_page(
    name = "Home",
    text = md_text(
      "## Large Branding",
      "",
      "This uses a **large** size - more prominent but still tasteful!"
    ),
    is_landing_page = TRUE
  ) %>%
  add_powered_by_dashboardr(size = "large", style = "minimal")

# Generate
generate_dashboard(dashboard_large, render = TRUE, open = "browser")


# =============================================================================
# EXAMPLE 6: Complete dashboard with visualizations
# =============================================================================

viz <- create_viz(
  type = "bar",
  x_var = "category",
  y_var = "value",
  title = "Sample Visualization"
) %>%
  add_viz()

dashboard_complete <- create_dashboard(
  output_dir = "demo_powered_by_complete",
  title = "Complete Dashboard",
  page_footer = "Research Dashboard © 2025"
) %>%
  add_page(
    name = "Home",
    text = md_text(
      "## Welcome to our Research Dashboard",
      "",
      "Built with **dashboardr** - the R package for creating beautiful dashboards!"
    ),
    is_landing_page = TRUE
  ) %>%
  add_page(
    name = "Analysis",
    data = data,
    visualizations = viz,
    text = "Here are our key findings..."
  ) %>%
  add_powered_by_dashboardr(style = "default", size = "small")

# Generate and view
generate_dashboard(dashboard_complete, render = TRUE, open = "browser")


# =============================================================================
# COMPARISON: View all styles at once
# =============================================================================

cat("
=== add_powered_by_dashboardr() Demo ===

This demo shows different styles and sizes:

1. Default style (small):    Subtle 'Powered by dashboardr' with icon
2. With existing footer:      Preserves your footer, adds branding to right
3. Minimal style:             Just text, no icon
4. Badge style:               Background box with hover effect
5. Large size:                More prominent branding
6. Complete dashboard:        Real-world example with visualizations

Features:
✓ Three styles: default, minimal, badge
✓ Three sizes: small, medium, large
✓ Auto-integrates with existing footers
✓ Hover effects and smooth transitions
✓ Links to dashboardr documentation

Uncomment the generate_dashboard() lines to view each example!
")

