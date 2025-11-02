# Demo: Simple Navbar Dropdown Menus (without sidebar groups!)
# This shows how to create nested navbar items using navbar_menu()

library(dashboardr)

# Sample data
data <- data.frame(
  category = rep(c("A", "B", "C"), each = 10),
  value = rnorm(30, 50, 10),
  time = rep(1:10, 3)
)

# Create visualizations
skills_viz <- create_viz(
  type = "timeline",
  time_var = "time",
  response_var = "value",
  group_var = "category"
) %>%
  add_viz(title = "Skills Over Time")

performance_viz <- create_viz(
  type = "timeline",
  time_var = "time",
  response_var = "value",
  group_var = "category"
) %>%
  add_viz(title = "Performance Over Time")

# Create navbar dropdown menus (NO sidebar_groups required!)
dimensions_menu <- navbar_menu(
  text = "Dimensions",
  pages = c("Strategic Information", "Critical Information"),
  icon = "ph:book"
)

analysis_menu <- navbar_menu(
  text = "Analysis",
  pages = c("Skills", "Performance"),
  icon = "ph:chart-line"
)

# Create dashboard with navbar menus
dashboard <- create_dashboard(
  output_dir = "navbar_menu_demo",
  title = "Navbar Dropdown Menu Demo",
  navbar_sections = list(analysis_menu, dimensions_menu),  # Just pass the menus!
  search = TRUE,
  navbar_style = "dark"
) %>%
  # Landing page
  add_page(
    name = "Home",
    text = md_text(
      "# Welcome!",
      "",
      "This demo shows **navbar dropdown menus** - simple nested navigation without sidebar groups!",
      "",
      "Click on **Analysis** or **Dimensions** in the navbar to see the dropdown menus."
    ),
    icon = "ph:house",
    is_landing_page = TRUE
  ) %>%
  
  # Analysis menu pages
  add_page(
    name = "Skills",
    data = data,
    visualizations = skills_viz,
    icon = "ph:graduation-cap",
    text = md_text("### Skills Analysis", "This page is in the Analysis dropdown menu.")
  ) %>%
  add_page(
    name = "Performance",
    data = data,
    visualizations = performance_viz,
    icon = "ph:trophy",
    text = md_text("### Performance Analysis", "This page is also in the Analysis dropdown menu.")
  ) %>%
  
  # Dimensions menu pages
  add_page(
    name = "Strategic Information",
    icon = "ph:lightbulb",
    text = md_text(
      "### Strategic Information",
      "",
      "This page is in the Dimensions dropdown menu.",
      "",
      "**No sidebar groups required!** Just use `navbar_menu()` to create nested navigation."
    )
  ) %>%
  add_page(
    name = "Critical Information",
    icon = "ph:target",
    text = md_text(
      "### Critical Information",
      "",
      "This page is also in the Dimensions dropdown menu.",
      "",
      "Much simpler than hybrid navigation with sidebar groups!"
    )
  ) %>%
  
  # Regular page (not in any menu)
  add_page(
    name = "About",
    icon = "ph:info",
    navbar_align = "right",
    text = md_text(
      "## About This Demo",
      "",
      "This demonstrates the new `navbar_menu()` function which creates simple dropdown menus in the navbar.",
      "",
      "### Key Features:",
      "- ✅ No sidebar groups required",
      "- ✅ Simple dropdown menus",
      "- ✅ Icons supported",
      "- ✅ Mix with regular pages",
      "",
      "### Usage:",
      "```r",
      "# Create a dropdown menu",
      "my_menu <- navbar_menu(",
      "  text = 'Menu Name',",
      "  pages = c('Page 1', 'Page 2', 'Page 3'),",
      "  icon = 'ph:folder'",
      ")",
      "",
      "# Pass to dashboard",
      "dashboard <- create_dashboard(",
      "  navbar_sections = list(my_menu)",
      ")",
      "```"
    )
  )

# Generate the dashboard
generate_dashboard(dashboard)

cat("\n✅ Dashboard generated successfully!\n")
cat("📂 Output directory: navbar_menu_demo\n")
cat("🌐 To view: Open navbar_menu_demo/index.html in a browser\n")

