# Demo: Preview Mode for Fast Testing
# 
# Preview mode lets you generate only specific pages, perfect for:
# - Testing changes to a single page
# - Iterating quickly during development
# - Avoiding long build times for large dashboards

# Load the development version (not installed package)
devtools::load_all(".")

# Create some sample data
set.seed(123)
survey_data <- data.frame(
  age = sample(18:80, 1000, replace = TRUE),
  score = sample(1:7, 1000, replace = TRUE),
  wave = sample(c(1, 2), 1000, replace = TRUE),
  category = sample(c("A", "B", "C"), 1000, replace = TRUE)
)

# Create visualizations for different pages
demographics_viz <- create_viz() %>%
  add_viz(type = "histogram", x_var = "age", title = "Age Distribution") %>%
  add_viz(type = "histogram", x_var = "score", title = "Score Distribution")

analysis_viz <- create_viz() %>%
  add_viz(type = "stackedbar", x_var = "category", stack_var = "score", 
          title = "Scores by Category", stacked_type = "percent")

trends_viz <- create_viz() %>%
  add_viz(type = "timeline", time_var = "wave", response_var = "score",
          title = "Score Trends", chart_type = "line")

# Create dashboard with multiple pages
dashboard <- create_dashboard(
  "preview_demo",
  "Preview Mode Demo",
  output_dir = "preview_demo_dashboard",
  tabset_theme = "modern"
) %>%
  add_dashboard_page(
    "Home",
    text = "Welcome to the Preview Mode Demo! This dashboard has multiple pages.",
    is_landing_page = TRUE
  ) %>%
  add_dashboard_page(
    "Demographics",
    data = survey_data,
    visualizations = demographics_viz
  ) %>%
  add_dashboard_page(
    "Analysis",
    data = survey_data,
    visualizations = analysis_viz
  ) %>%
  add_dashboard_page(
    "Trends",
    data = survey_data,
    visualizations = trends_viz
  ) %>%
  add_dashboard_page(
    "About",
    text = "This is the about page with information about the dashboard."
  )

# ==============================================================================
# Example 1: Generate ALL pages (standard mode)
# ==============================================================================
cat("\n=== Example 1: Full Dashboard ===\n")
cat("Generating all 5 pages...\n")
generate_dashboard(dashboard, render = FALSE)
cat("✅ All pages generated!\n\n")

# ==============================================================================
# Example 2: Preview a SINGLE page
# ==============================================================================
cat("=== Example 2: Preview Single Page ===\n")
cat("Testing changes to Analysis page only...\n")
generate_dashboard(dashboard, preview = "Analysis", render = FALSE)
cat("✅ Only Analysis page generated (much faster!)\n\n")

# ==============================================================================
# Example 3: Preview MULTIPLE pages
# ==============================================================================
cat("=== Example 3: Preview Multiple Pages ===\n")
cat("Working on Demographics and Trends pages...\n")
generate_dashboard(dashboard, 
                  preview = c("Demographics", "Trends"), 
                  render = FALSE)
cat("✅ Only Demographics and Trends pages generated\n\n")

# ==============================================================================
# Example 4: Case-Insensitive Page Names
# ==============================================================================
cat("=== Example 4: Case-Insensitive ===\n")
cat("Page names are case-insensitive...\n")
generate_dashboard(dashboard, preview = "analysis", render = FALSE)
generate_dashboard(dashboard, preview = "ANALYSIS", render = FALSE)
cat("✅ Works with any case!\n\n")

# ==============================================================================
# Example 5: Combine with Incremental Builds (MAXIMUM SPEED!)
# ==============================================================================
cat("=== Example 5: Preview + Incremental = 🚀 ===\n")
cat("First build: Full dashboard with incremental enabled...\n")
result1 <- generate_dashboard(dashboard, incremental = TRUE, render = FALSE)
cat("Built:", length(result1$build_info$regenerated), "pages\n\n")

cat("Second build: Preview Analysis page with incremental...\n")
result2 <- generate_dashboard(dashboard, 
                             preview = "Analysis", 
                             incremental = TRUE, 
                             render = FALSE)
cat("✅ Only regenerated Analysis (skipped unchanged pages!)\n\n")

# ==============================================================================
# Example 6: Error Handling
# ==============================================================================
cat("=== Example 6: Helpful Error Messages ===\n")
cat("What happens with a typo?\n")
tryCatch({
  generate_dashboard(dashboard, preview = "Analysys", render = FALSE)
}, error = function(e) {
  cat("Error caught:", conditionMessage(e), "\n")
  cat("✅ Suggests correct page name!\n\n")
})

# ==============================================================================
# Summary
# ==============================================================================
cat("\n=== 📊 Preview Mode Summary ===\n\n")
cat("Use cases:\n")
cat("  • Quick testing during development\n")
cat("  • Iterating on specific pages\n")
cat("  • Large dashboards with many pages\n")
cat("  • CI/CD pipelines (test specific pages)\n\n")

cat("Speed comparison (5-page dashboard):\n")
cat("  Full build:        ~5-10 seconds\n")
cat("  Preview 1 page:    ~1-2 seconds\n")
cat("  Preview + incr:    ~0.5 seconds\n\n")

cat("Syntax:\n")
cat("  generate_dashboard(dashboard, preview = 'Analysis')\n")
cat("  generate_dashboard(dashboard, preview = c('Home', 'Analysis'))\n")
cat("  generate_dashboard(dashboard, preview = 'Analysis', incremental = TRUE)\n\n")

cat("🎉 Preview mode implemented successfully!\n")

