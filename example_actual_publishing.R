# Actual Publishing Example - Ready to Run
# This script shows how to actually publish a dashboard to GitHub Pages

# Load the enhanced dashboard system
devtools::load_all()
source("R/create_dashboard_new.R")

# Load sample data
data(gss_panel20, package = "gssr")
gss_clean <- gss_panel20 %>%
  select(
    age_1a, sex_1a, degree_1a, region_1a,
    happy_1a, trust_1a, fair_1a, helpful_1a,
    polviews_1a, partyid_1a, class_1a
  ) %>%
  filter(if_any(everything(), ~ !is.na(.)))

cat("📊 CREATING DASHBOARD FOR PUBLISHING\n")
cat("══════════════════════════════════════════════════\n\n")

# Create visualizations
viz_collection <- create_viz() %>%
  add_viz(type = "stackedbar",
          x_var = "degree_1a",
          stack_var = "happy_1a",
          title = "Happiness by Education",
          subtitle = "Distribution of happiness across education levels",
          height = 500) %>%
  add_viz(type = "heatmap",
          x_var = "region_1a",
          y_var = "degree_1a",
          value_var = "trust_1a",
          title = "Trust by Region and Education",
          subtitle = "Educational and regional patterns in trust levels",
          height = 600)

# Create dashboard
dashboard <- create_dashboard(
  output_dir = "my_published_dashboard",
  title = "GSS Data Analysis Dashboard",
  github = "https://github.com/yourusername/gss-dashboard",
  twitter = "https://twitter.com/yourusername",
  author = "Data Analyst",
  description = "Analysis of General Social Survey data",
  page_footer = "© 2025 dashboardr Package - All Rights Reserved",
  search = TRUE,
  sidebar = TRUE,
  sidebar_style = "docked",
  sidebar_background = "light"
) %>%
  add_page(
    name = "Welcome",
    text = md_text(
      "# GSS Data Analysis Dashboard",
      "",
      "This dashboard provides insights into the General Social Survey data, focusing on happiness, trust, and demographic patterns.",
      "",
      "## Key Features",
      "",
      "- Interactive visualizations",
      "- Responsive design",
      "- Data exploration tools",
      "- Export capabilities"
    ),
    icon = "ph:house",
    is_landing_page = TRUE
  ) %>%
  add_page(
    name = "Analysis",
    data = gss_clean,
    visualizations = viz_collection,
    text = md_text(
      "## Data Analysis",
      "",
      "Explore the relationships between education, happiness, trust, and demographic factors using the interactive charts below."
    ),
    icon = "ph:chart-bar"
  ) %>%
  add_page(
    name = "About",
    text = md_text(
      "# About This Dashboard",
      "",
      "This dashboard was created using the `dashboardr` package for R.",
      "",
      "## Data Source",
      "",
      "The data comes from the General Social Survey (GSS), a nationally representative survey of adults in the United States.",
      "",
      "## Technology",
      "",
      "- **R**: Data analysis and visualization",
      "- **Quarto**: Web publishing framework",
      "- **Highcharter**: Interactive charts",
      "- **Bootstrap**: Responsive design"
    ),
    icon = "ph:info"
  )

# Generate the dashboard
cat("🔨 Generating dashboard files...\n")
generate_dashboard(dashboard, render = TRUE)

cat("\n🎉 DASHBOARD GENERATED SUCCESSFULLY!\n")
cat("══════════════════════════════════════════════════\n\n")

# ===================================================================
# USING THE EXISTING PUBLISH FUNCTION
# ===================================================================

# The dashboardr package already includes a comprehensive publish_dashboard() function!
# It handles GitHub Pages, GitLab Pages, git setup, and deployment configuration.


# Publish to GitHub Pages (recommended)
publish_dashboard(
  dashboard_path = '../my_published_dashboard',
  platform = 'github',
  repo_name = 'my-awesome-dashboard',
  username = 'favstats',
  private = FALSE,
  open_browser = TRUE
)
