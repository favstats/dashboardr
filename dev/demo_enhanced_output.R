# Demo: Enhanced Dashboard Generation Output with Timing
# This showcases the new timing feature and beautiful output visualization

library(dashboardr)

# Create sample data
sample_data <- data.frame(
  category = rep(c("A", "B", "C"), each = 20),
  value = rnorm(60, 50, 10),
  year = rep(2020:2023, 15),
  score = sample(1:5, 60, replace = TRUE),
  group = sample(c("Group 1", "Group 2", "Group 3"), 60, replace = TRUE)
)

# Create visualizations for multiple pages
viz_page1 <- create_viz(
  type = "timeline",
  time_var = "year",
  response_var = "value",
  group_var = "category"
) %>%
  add_viz(title = "Trends Over Time", tabgroup = "overview") %>%
  add_viz(title = "By Category", tabgroup = "breakdown/category") %>%
  add_viz(title = "By Group", tabgroup = "breakdown/group")

viz_page2 <- create_viz(
  type = "histogram",
  x_var = "value"
) %>%
  add_viz(title = "Distribution") %>%
  add_viz(title = "Score Distribution", x_var = "score")

viz_page3 <- create_viz(
  type = "stackedbar",
  x_var = "category",
  stack_var = "group"
) %>%
  add_viz(title = "Category Breakdown")

# Create comprehensive dashboard
cat("\n")
cat("╔════════════════════════════════════════════════════════════╗\n")
cat("║          ENHANCED OUTPUT DEMO - WATCH THE MAGIC!          ║\n")
cat("╚════════════════════════════════════════════════════════════╝\n")
cat("\n")
cat("Generating dashboard with:\n")
cat("  • 5 pages\n")
cat("  • 8 visualizations\n")
cat("  • Multiple data files\n")
cat("  • Nested tabgroups\n")
cat("\n")
cat("Watch the beautiful output below...\n")
cat(paste(rep("─", 60), collapse = ""), "\n\n")

dashboard <- create_dashboard(
  output_dir = "enhanced_output_demo",
  title = "Enhanced Output Dashboard",
  author = "Demo User",
  description = "Showcasing enhanced generation output with timing",
  tabset_theme = "modern"
) %>%
  # Landing page
  add_page(
    name = "Welcome",
    icon = "ph:house",
    is_landing_page = TRUE,
    text = md_text(
      "# Welcome!",
      "",
      "This dashboard demonstrates the **enhanced generation output** with:",
      "",
      "- ⏱ **Timing information** - See how fast your dashboard generates!",
      "- 🎨 **Beautiful CLI output** - Clear, organized, emoji-rich feedback",
      "- 📊 **Detailed summaries** - Know exactly what was generated",
      "",
      "Check the terminal output above to see the magic! ✨"
    )
  ) %>%
  # Analysis pages with visualizations
  add_page(
    name = "Analysis",
    data = sample_data,
    visualizations = viz_page1,
    icon = "ph:chart-line"
  ) %>%
  add_page(
    name = "Distributions",
    data = sample_data,
    visualizations = viz_page2,
    icon = "ph:chart-bar"
  ) %>%
  add_page(
    name = "Breakdown",
    data = sample_data,
    visualizations = viz_page3,
    icon = "ph:stack"
  ) %>%
  # About page
  add_page(
    name = "About",
    icon = "ph:info",
    navbar_align = "right",
    text = md_text(
      "## About This Demo",
      "",
      "This dashboard was generated with the enhanced output feature.",
      "",
      "### Key Features:",
      "- **Timing**: Know exactly how long generation took",
      "- **Visual Feedback**: Beautiful, organized output",
      "- **Helpful Info**: File counts, locations, next steps",
      "",
      "### Timing Display:",
      "- < 1 second: Shows milliseconds (e.g., \"245.3 ms\")",
      "- 1-60 seconds: Shows seconds (e.g., \"3.45 seconds\")",
      "- > 60 seconds: Shows minutes + seconds (e.g., \"2 min 15.2 sec\")"
    )
  )

# Generate the dashboard (render = FALSE for demo)
generate_dashboard(dashboard, render = FALSE)

cat("\n")
cat("╔════════════════════════════════════════════════════════════╗\n")
cat("║                      DEMO COMPLETE!                        ║\n")
cat("╚════════════════════════════════════════════════════════════╝\n")
cat("\n")
cat("✅ Notice the enhanced output above with:\n")
cat("   • Generation timing (⏱)\n")
cat("   • Clear file organization (📄 📁 ⚙️)\n")
cat("   • Beautiful formatting with emojis and boxes\n")
cat("   • Helpful next steps guidance\n")
cat("\n")
cat("🚀 Your dashboard is ready at: enhanced_output_demo/\n")
cat("\n")

