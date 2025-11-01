# Dashboard Publishing Workflow Example
# This script demonstrates how to create and publish a dashboard to GitHub Pages or GitLab Pages

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

# Create a simple dashboard for publishing
cat("📊 Creating dashboard for publishing...\n")

# Create visualizations
viz_collection <- create_viz() %>%
  add_viz(type = "stackedbar",
          x_var = "degree_1a",
          stack_var = "happy_1a",
          title = "Happiness by Education",
          subtitle = "Distribution of happiness across education levels",
          x_label = "Education Level",
          y_label = "Percentage of Respondents",
          stack_label = "Happiness Level",
          stacked_type = "percent",
          x_order = c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate"),
          stack_order = c("Very Happy", "Pretty Happy", "Not Too Happy"),
          tooltip_suffix = "%",
          color_palette = c("#2E86AB", "#A23B72", "#F18F01"),
          text = "This chart shows how happiness levels vary across different education groups.",
          text_position = "above",
          icon = "ph:chart-bar",
          height = 500) %>%
  add_viz(type = "heatmap",
          x_var = "region_1a",
          y_var = "degree_1a",
          value_var = "trust_1a",
          title = "Trust by Region and Education",
          subtitle = "Educational and regional patterns in trust levels",
          x_label = "Region",
          y_label = "Education Level",
          value_label = "Trust Level",
          y_order = c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate"),
          color_palette = c("#d7191c", "#fdae61", "#ffffbf", "#abdda4", "#2b83ba"),
          tooltip_prefix = "Trust: ",
          tooltip_suffix = "/3",
          data_labels_format = "{point.value:.2f}",
          text = "Educational and regional patterns in trust distribution.",
          text_position = "above",
          icon = "ph:chart-pie",
          height = 600)

# Create dashboard
dashboard <- create_dashboard(
  output_dir = "publishable_dashboard",
  title = "GSS Data Analysis Dashboard",
  github = "https://github.com/username/dashboardr",
  twitter = "https://twitter.com/username",
  author = "Data Analyst",
  description = "Analysis of General Social Survey data",
  page_footer = "© 2025 dashboardr Package - All Rights Reserved",
  search = TRUE,
  sidebar = TRUE,
  sidebar_style = "docked",
  sidebar_background = "light"
) %>%
  # Landing page
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
    icon = "ph:house"
  ) %>%
  # Analysis page
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
  # About page
  add_page(
    name = "About",
    text = md_text(
      "# About This Dashboard",
      "",
      "This dashboard was created using the `dashboardr` package for R, which provides a simple way to create interactive data visualizations and publish them as web dashboards.",
      "",
      "## Data Source",
      "",
      "The data comes from the General Social Survey (GSS), a nationally representative survey of adults in the United States conducted by NORC at the University of Chicago.",
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
# PUBLISHING TO GITHUB PAGES
# ===================================================================

cat("🚀 PUBLISHING TO GITHUB PAGES\n")
cat("══════════════════════════════════════════════════\n\n")

# Option 1: Automatic publishing with publish_dashboard()
cat("📦 OPTION 1: AUTOMATIC PUBLISHING\n")
cat("──────────────────────────────────────────────────\n")

# This will create a git repository, push to GitHub, and set up GitHub Pages
cat("Using publish_dashboard() for automatic setup...\n")

# Uncomment the following lines to actually publish:
# publish_result <- publish_dashboard(
#   dashboard_dir = "publishable_dashboard",
#   repo_name = "gss-dashboard-demo",
#   github_username = "your-github-username",  # Replace with your GitHub username
#   github_token = Sys.getenv("GITHUB_TOKEN"),  # Set this environment variable
#   branch = "main",
#   message = "Initial dashboard commit",
#   private = FALSE,  # Set to TRUE for private repository
#   auto_open = TRUE
# )

cat("✅ Automatic publishing code ready (uncomment to use)\n\n")

# Option 2: Manual publishing steps
cat("📝 OPTION 2: MANUAL PUBLISHING STEPS\n")
cat("──────────────────────────────────────────────────\n")

cat("If you prefer manual control, follow these steps:\n\n")

cat("1️⃣  Initialize Git Repository:\n")
cat("   cd publishable_dashboard\n")
cat("   git init\n")
cat("   git add .\n")
cat("   git commit -m 'Initial dashboard commit'\n\n")

cat("2️⃣  Create GitHub Repository:\n")
cat("   - Go to https://github.com/new\n")
cat("   - Repository name: gss-dashboard-demo\n")
cat("   - Description: GSS Data Analysis Dashboard\n")
cat("   - Public repository (for free GitHub Pages)\n")
cat("   - Don't initialize with README (we already have files)\n\n")

cat("3️⃣  Connect Local Repository to GitHub:\n")
cat("   git remote add origin https://github.com/YOUR-USERNAME/gss-dashboard-demo.git\n")
cat("   git branch -M main\n")
cat("   git push -u origin main\n\n")

cat("4️⃣  Enable GitHub Pages:\n")
cat("   - Go to repository Settings > Pages\n")
cat("   - Source: Deploy from a branch\n")
cat("   - Branch: main\n")
cat("   - Folder: / (root)\n")
cat("   - Click Save\n\n")

cat("5️⃣  Update Quarto Configuration:\n")
cat("   - Edit _quarto.yml to set output-dir: docs\n")
cat("   - Re-render: quarto render\n")
cat("   - Commit and push changes\n\n")

cat("6️⃣  Configure GitHub Pages for Quarto:\n")
cat("   - Go to Settings > Pages\n")
cat("   - Source: Deploy from a branch\n")
cat("   - Branch: main\n")
cat("   - Folder: /docs\n")
cat("   - Click Save\n\n")

# Option 3: Using usethis for repository creation
cat("🔧 OPTION 3: USING USETHIS PACKAGE\n")
cat("──────────────────────────────────────────────────\n")

cat("For more advanced repository management:\n\n")

cat("# Install usethis if not already installed\n")
cat("if (!requireNamespace('usethis', quietly = TRUE)) {\n")
cat("  install.packages('usethis')\n")
cat("}\n\n")

cat("# Set up git and GitHub (run once)\n")
cat("usethis::use_git()\n")
cat("usethis::use_github()\n\n")

cat("# Create repository and push\n")
cat("usethis::use_github_pages()\n\n")

# Option 4: Complete automated workflow
cat("🤖 OPTION 4: COMPLETE AUTOMATED WORKFLOW\n")
cat("──────────────────────────────────────────────────\n")

cat("Here's a complete function for automated publishing:\n\n")

cat("publish_to_github_pages <- function(\n")
cat("  dashboard_dir = 'publishable_dashboard',\n")
cat("  repo_name = 'my-dashboard',\n")
cat("  github_username = NULL,\n")
cat("  github_token = Sys.getenv('GITHUB_TOKEN'),\n")
cat("  private = FALSE,\n")
cat("  auto_open = TRUE\n")
cat(") {\n")
cat("  \n")
cat("  # Check if git is available\n")
cat("  if (system('git --version', ignore.stdout = TRUE) != 0) {\n")
cat("    stop('Git is not installed. Please install git first.')\n")
cat("  }\n")
cat("  \n")
cat("  # Check if GitHub token is provided\n")
cat("  if (is.null(github_token) || github_token == '') {\n")
cat("    stop('GitHub token required. Set GITHUB_TOKEN environment variable.')\n")
cat("  }\n")
cat("  \n")
cat("  # Set up git repository\n")
cat("  setwd(dashboard_dir)\n")
cat("  system('git init')\n")
cat("  system('git add .')\n")
cat("  system('git commit -m \"Initial dashboard commit\"')\n")
cat("  \n")
cat("  # Create GitHub repository using GitHub API\n")
cat("  # (Implementation would use httr or gh package)\n")
cat("  \n")
cat("  # Push to GitHub\n")
cat("  repo_url <- paste0('https://github.com/', github_username, '/', repo_name, '.git')\n")
cat("  system(paste0('git remote add origin ', repo_url))\n")
cat("  system('git branch -M main')\n")
cat("  system('git push -u origin main')\n")
cat("  \n")
cat("  # Open GitHub Pages settings\n")
cat("  if (auto_open) {\n")
cat("    pages_url <- paste0('https://github.com/', github_username, '/', repo_name, '/settings/pages')\n")
cat("    browseURL(pages_url)\n")
cat("  }\n")
cat("  \n")
cat("  cat('✅ Dashboard published successfully!\\n')\n")
cat("  cat('📱 Your dashboard will be available at:')\n")
cat("  cat(paste0('https://', github_username, '.github.io/', repo_name, '/\\n'))\n")
cat("}\n\n")

# Environment setup instructions
cat("🔑 ENVIRONMENT SETUP\n")
cat("══════════════════════════════════════════════════\n\n")

cat("Before publishing, set up your environment:\n\n")

cat("1️⃣  Install Git:\n")
cat("   - Windows: https://git-scm.com/download/win\n")
cat("   - Mac: brew install git\n")
cat("   - Linux: sudo apt install git\n\n")

cat("2️⃣  Create GitHub Personal Access Token:\n")
cat("   - Go to https://github.com/settings/tokens\n")
cat("   - Click 'Generate new token (classic)'\n")
cat("   - Select scopes: repo, workflow\n")
cat("   - Copy the token\n\n")

cat("3️⃣  Set Environment Variable:\n")
cat("   # In R:\n")
cat("   Sys.setenv(GITHUB_TOKEN = 'your-token-here')\n\n")
cat("   # Or in .Renviron file:\n")
cat("   # GITHUB_TOKEN=your-token-here\n\n")

cat("4️⃣  Configure Git (if first time):\n")
cat("   git config --global user.name 'Your Name'\n")
cat("   git config --global user.email 'your.email@example.com'\n\n")

# Final instructions
cat("🎯 NEXT STEPS\n")
cat("══════════════════════════════════════════════════\n\n")

cat("1. Choose your preferred publishing method above\n")
cat("2. Set up your GitHub token and git configuration\n")
cat("3. Run the publishing code\n")
cat("4. Configure GitHub Pages settings\n")
cat("5. Share your dashboard URL!\n\n")

cat("📚 For more details, see the PUBLISHING_GUIDE.md file\n")
cat("🚀 Happy publishing!\n")
