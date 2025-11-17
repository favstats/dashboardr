# Demo: Iconify Icons in Tab Titles with Publishing Workflow

# Shows that prefer-html: true enables iconify in tab names
# and demonstrates the new simplified publishing workflow

library(dashboardr)
# devtools::load_all()

cat("\n╔══════════════════════════════════════════════════════════════╗\n")
cat("║          🎨 Iconify in Tabs Demo                            ║\n")
cat("╚══════════════════════════════════════════════════════════════╝\n\n")

# Sample data (mimicking your structure)
set.seed(123)
sample_data <- data.frame(
  category = rep(c("A", "B", "C", "D"), 50),
  value = rnorm(200, 50, 15),
  group = rep(c("Group 1", "Group 2"), each = 100),
  time = rep(c("Q1", "Q2", "Q3", "Q4"), 50)
)

# Create bar visualizations with iconify in tab names
bar_viz <- create_viz(
  type = "bar",
  x_var = "category",
  horizontal = TRUE,
  color_palette = c("#2563eb", "#7c3aed", "#059669", "#dc2626")
) %>%
  add_viz(
    tabgroup = "charts/basic"
  ) %>%
  add_viz(
    tabgroup = "charts/grouped"
  )

# Create timeline visualizations with icons
timeline_viz <- create_viz(
  type = "timeline",
  time_var = "time",
  response_var = "value",
  chart_type = "line"
) %>%
  add_viz(
    text = "Which of the <a href=\"#PDCCS1R\" class=\"modal-link\">following icons</a> refer to the function for cutting or removing parts of a picture (\\\"cropping\\\")?', preset = 'question'",
    tabgroup = "trends/overall"
  ) %>%
  add_viz(
    group_var = "group",
    tabgroup = "trends/grouped"
  ) %>%
  # Modal 2: With image
  add_modal(
    modal_id = "PDCCS1R",
    title = "Digital Content Creation: Performance Questions",
    image = "https://placehold.co/600x400/EEE/31343C",
    modal_content = "Information literacy scores were highest at 85%.
                     Participants excelled at search strategies and
                     source evaluation."
  )

# Different icon sets
icon_showcase_viz <- create_viz(
  type = "bar",
  x_var = "category",
  color_palette = c("#f59e0b", "#8b5cf6", "#10b981")
) %>%
  add_viz(
    tabgroup = "iconsets/fluent"
  ) %>%
  add_viz(
    tabgroup = "iconsets/carbon"
  ) %>%
  add_viz(
    tabgroup = "iconsets/hero"
  )

# Combine visualizations
all_viz <- bar_viz %>%
  combine_viz(timeline_viz) %>%
  add_pagination() %>%
  combine_viz(icon_showcase_viz) %>%
  add_pagination() %>%
  set_tabgroup_labels(
    charts = "{{< iconify ph:chart-bar-fill >}} Charts",
    trends = "{{< iconify ph:chart-line-fill >}} Trends",
    iconsets = "{{< iconify ph:palette-fill >}} Icon Sets",
    basic = "{{< iconify mdi:chart-bar >}} Basic Chart",
    grouped = "{{< iconify mdi gender-transgender >}} Grouped View",
    overall = "{{< iconify mdi:chart-timeline-variant >}} Overall Timeline",
    fluent = "{{< iconify fluent:data-bar-vertical-20-filled >}} Microsoft Fluent",
    carbon = "{{< iconify carbon:analytics >}} IBM Carbon",
    hero = "{{< iconify heroicons:chart-bar-solid >}} Heroicons"
  )

# Create dashboard
dashboard <- create_dashboard(
  output_dir = "qmd",
  publish_dir = "../docs",
  title = "Iconify in Tabs Demo",
  mobile_toc = TRUE,
  plausible = "pa-UnPiJwxFi8TS-XAvCdgQx",
  pagination_separator = "/",
  pagination_position = "bottom",
  viewport_width = 1200,
  viewport_scale = 0.3  # Zoom out to fit whole page
) %>%
  apply_theme(theme_modern(style = "purple")) %>%
  # Landing page
  add_page(
    overlay = TRUE,
    overlay_duration = 1,
    name = "Home",
    icon = "ph:house-fill",
    text = md_text(
      "# Welcome to Iconify Tabs Demo! 🎨",
      "",
      "This dashboard demonstrates that **iconify icons work in tab titles**!",
      "",
      "Navigate to the **Analysis** page to see tabs with icons.",
      "",
      "## How It Works",
      "",
      "By adding `prefer-html: true` to `_quarto.yml`, Quarto processes HTML",
      "in markdown headers, which enables iconify shortcodes in tab names.",
      "",
      "### Example Syntax:",
      "",
      "```r",
      "viz <- create_viz(type = \"bar\", ...) %>%",
      "  add_viz(tabgroup = \"charts/basic\") %>%",
      "  set_tabgroup_labels(",
      "    charts = \"Charts\",",
      "    basic = \"{{< iconify mdi:chart-bar >}} Basic Chart\"",
      "  )",
      "```",
      "",
      "## Try These Icon Sets:",
      "",
      "- **Material Design Icons**: `mdi:*`",
      "- **Phosphor**: `ph:*`",
      "- **Microsoft Fluent**: `fluent:*`",
      "- **IBM Carbon**: `carbon:*`",
      "- **Heroicons**: `heroicons:*`",
      "",
      "Browse all icons at: [https://icon-sets.iconify.design/](https://icon-sets.iconify.design/)"
    ),
    is_landing_page = TRUE
  ) %>%
  # Analysis page with iconified tabs
  add_page(
    overlay = TRUE,
    overlay_duration = 1,
    name = "Analysis",
    icon = "ph:chart-bar-fill",
    data = sample_data,
    visualizations = all_viz,
    text = md_text(
      "# Data Analysis with Iconified Tabs",
      "",
      "Check out the tabs below - they all have icons! ✨",
      "",
      "The icons appear directly in the tab titles, making navigation more intuitive and visually appealing."
    )
  ) %>%
  add_powered_by_dashboardr(style = "badge", size = "large")

# Generate the dashboard
generate_dashboard(dashboard, render = TRUE, open = "browser")

cat("\n╔══════════════════════════════════════════════════════════════╗\n")
cat("║                  ✅ DEMO GENERATED!                         ║\n")
cat("╚══════════════════════════════════════════════════════════════╝\n\n")
cat("🎨 Check the tabs - they all have icons now!\n\n")

# ═══════════════════════════════════════════════════════════════
# Publishing Workflow Demo
# ═══════════════════════════════════════════════════════════════

cat("\n╔══════════════════════════════════════════════════════════════╗\n")
cat("║          📤 Publishing Workflow Demo                        ║\n")
cat("╚══════════════════════════════════════════════════════════════╝\n\n")

## Navigate to the dashboard directory first
# setwd("path/to/your/dashboard")

## INITIAL PUBLISH: Set up git, GitHub, and GitHub Pages
## Only run this once for a new dashboard
if (FALSE) {  # Set to TRUE when ready to publish
  
  publish_dashboard(
    message = "Initial dashboard publication",
    restart = FALSE,           # Don't force RStudio restart
    private = FALSE,           # Create public repository
    protocol = "https",        # Use HTTPS (or "ssh" if you prefer)
    branch = usethis::git_default_branch(),  # Usually "main"
    path = "/docs"            # GitHub Pages will serve from /docs
  )
  
  cat("✅ Dashboard published successfully!\n")
  cat("🌐 Your dashboard will be live at: https://USERNAME.github.io/REPO-NAME\n")
  cat("⏱️  GitHub Pages deployment takes 2-5 minutes\n\n")
  
}

## SUBSEQUENT UPDATES: Quick updates after making changes
## Run this every time you want to push updates
if (FALSE) {  # Set to TRUE when ready to update
  
  # Update all files with default message
  update_dashboard()
  
  # Or with a custom message
  update_dashboard(message = "Update iconify demos and styling")
  
  # Or update specific files only
  update_dashboard(
    files = c("docs/index.html", "docs/analysis.html"),
    message = "Update main pages only"
  )
  
  # Or update all HTML files
  update_dashboard(
    files = "docs/*.html",
    message = "Regenerate all HTML pages"
  )
  
  cat("✅ Dashboard updated and pushed to GitHub!\n")
  cat("🔄 Changes will appear on your site in 1-2 minutes\n\n")
  
}

# ═══════════════════════════════════════════════════════════════
# Complete Workflow Example
# ═══════════════════════════════════════════════════════════════

cat("\n╔══════════════════════════════════════════════════════════════╗\n")
cat("║          📋 Complete Workflow Summary                       ║\n")
cat("╚══════════════════════════════════════════════════════════════╝\n\n")

cat("1️⃣  Generate your dashboard:\n")
cat("   generate_dashboard(dashboard, render = TRUE)\n\n")

cat("2️⃣  Navigate to dashboard directory:\n")
cat("   setwd('path/to/dashboard')\n\n")

cat("3️⃣  Publish for the first time:\n")
cat("   publish_dashboard()\n\n")

cat("4️⃣  Make updates to your dashboard:\n")
cat("   generate_dashboard(dashboard, render = TRUE)\n\n")

cat("5️⃣  Push updates to GitHub:\n")
cat("   update_dashboard(message = 'Updated visualizations')\n\n")

cat("That's it! 🎉\n\n")

# ═══════════════════════════════════════════════════════════════
# Advanced Publishing Options
# ═══════════════════════════════════════════════════════════════

cat("\n╔══════════════════════════════════════════════════════════════╗\n")
cat("║          ⚙️  Advanced Publishing Options                    ║\n")
cat("╚══════════════════════════════════════════════════════════════╝\n\n")

## Publish to an organization
if (FALSE) {
  publish_dashboard(
    organisation = "my-organization",
    private = FALSE
  )
}

## Publish a private repository
if (FALSE) {
  publish_dashboard(
    private = TRUE,
    message = "Private dashboard - initial commit"
  )
}

## Use SSH instead of HTTPS
if (FALSE) {
  publish_dashboard(
    protocol = "ssh"
  )
}

## Custom branch and path
if (FALSE) {
  publish_dashboard(
    branch = "gh-pages",
    path = "/"  # Serve from root instead of /docs
  )
}

## Allow RStudio restart (if you want to see Git pane immediately)
if (FALSE) {
  publish_dashboard(
    restart = TRUE
  )
}

cat("\n💡 Tips:\n")
cat("  - The .gitignore will automatically exclude data files and large files (>10MB)\n")
cat("  - Your GitHub token (GITHUB_PAT) must be set for authentication\n")
cat("  - Run usethis::create_github_token() if you need to set up a token\n")
cat("  - GitHub Pages serves from the /docs directory by default\n")
cat("  - Updates usually appear within 1-2 minutes after pushing\n\n")

