# Build Tabset Theme Demo Dashboards
# Creates 6 separate dashboards, one for each tabset theme
# Run from package root: source("pkgdown/build-tabsets-demo.R")

library(dashboardr)
library(dplyr)
library(tidyr)

cat("📊 Building Tabset Theme Dashboards...\n\n")

# =============================================================================
# Create beautiful sample data
# =============================================================================

set.seed(2024)

# Survey response data - simulating attitudes across demographics
regions <- c("North", "South", "East", "West")
age_groups <- c("18-29", "30-44", "45-59", "60+")
education <- c("High School", "Bachelor's", "Graduate")
satisfaction <- c("Very Satisfied", "Satisfied", "Neutral", "Dissatisfied")

# Generate realistic survey data
n <- 2000
survey_data <- tibble(
  respondent_id = 1:n,
  region = sample(regions, n, replace = TRUE, prob = c(0.25, 0.30, 0.20, 0.25)),
  age_group = sample(age_groups, n, replace = TRUE, prob = c(0.22, 0.28, 0.27, 0.23)),
  education = sample(education, n, replace = TRUE, prob = c(0.45, 0.35, 0.20)),
  satisfaction = sample(satisfaction, n, replace = TRUE, prob = c(0.25, 0.35, 0.25, 0.15))
)

# Color palettes
satisfaction_colors <- c("#22C55E", "#84CC16", "#EAB308", "#EF4444")
region_colors <- c("#3B82F6", "#8B5CF6", "#EC4899", "#F97316")
education_colors <- c("#06B6D4", "#8B5CF6", "#F43F5E")

# Find package root
find_pkg_root <- function() {
  dir <- getwd()
  for (i in 1:10) {
    if (file.exists(file.path(dir, "DESCRIPTION"))) {
      return(dir)
    }
    parent <- dirname(dir)
    if (parent == dir) break
    dir <- parent
  }
  if (requireNamespace("here", quietly = TRUE)) {
    return(here::here())
  }
  stop("Could not find package root. Run from package directory.")
}

pkg_root <- find_pkg_root()
cat("   Package root:", pkg_root, "\n")

# All available tabset themes
themes <- c("pills", "modern", "minimal", "classic", "underline", "segmented")

# Function to create a tabset demo dashboard for a given theme
create_tabset_demo <- function(theme_name) {
  output_dir <- file.path(pkg_root, "docs", "live-demos", "tabsets", theme_name)
  
  cat("   Creating", theme_name, "theme demo...\n")
  
  # Clean up old files
  if (dir.exists(output_dir)) {
    unlink(output_dir, recursive = TRUE)
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  
  # ==========================================================================
  # LEVEL 1: Each viz gets a DIFFERENT tabgroup name = top-level tabs
  # ==========================================================================
  level1_vizzes <- create_viz() %>%
    add_viz(
      type = "stackedbar",
      x_var = "age_group",
      stack_var = "satisfaction",
      title = "Satisfaction by Age",
      subtitle = "How different generations feel",
      x_label = "Age Group",
      y_label = "Percentage",
      stack_label = "Satisfaction",
      stacked_type = "percent",
      x_order = age_groups,
      stack_order = satisfaction,
      color_palette = satisfaction_colors,
      tooltip_suffix = "%",
      height = 500,
      tabgroup = "age"
    ) %>%
    add_viz(
      type = "stackedbar",
      x_var = "education",
      stack_var = "satisfaction",
      title = "Satisfaction by Education",
      subtitle = "Education level and satisfaction",
      x_label = "Education Level",
      y_label = "Percentage",
      stack_label = "Satisfaction",
      stacked_type = "percent",
      x_order = education,
      stack_order = satisfaction,
      color_palette = satisfaction_colors,
      tooltip_suffix = "%",
      height = 500,
      tabgroup = "education"
    ) %>%
    add_viz(
      type = "stackedbar",
      x_var = "region",
      stack_var = "satisfaction",
      title = "Satisfaction by Region",
      subtitle = "Regional patterns",
      x_label = "Region",
      y_label = "Percentage",
      stack_label = "Satisfaction",
      stacked_type = "percent",
      x_order = regions,
      stack_order = satisfaction,
      color_palette = satisfaction_colors,
      tooltip_suffix = "%",
      height = 500,
      horizontal = TRUE,
      tabgroup = "region"
    ) %>%
    set_tabgroup_labels(list(
      age = "By Age",
      education = "By Education",
      region = "By Region"
    ))
  
  # ==========================================================================
  # LEVEL 2: Nested tabgroups (Topic / Subtopic)
  # ==========================================================================
  level2_vizzes <- create_viz() %>%
    # Satisfaction > By Age
    add_viz(
      type = "stackedbar",
      x_var = "age_group",
      stack_var = "satisfaction",
      title = "Satisfaction by Age",
      x_label = "Age Group",
      y_label = "Percentage",
      stack_label = "Satisfaction",
      stacked_type = "percent",
      x_order = age_groups,
      stack_order = satisfaction,
      color_palette = satisfaction_colors,
      tooltip_suffix = "%",
      height = 480,
      tabgroup = "satisfaction/by_age"
    ) %>%
    # Satisfaction > By Education
    add_viz(
      type = "stackedbar",
      x_var = "education",
      stack_var = "satisfaction",
      title = "Satisfaction by Education",
      x_label = "Education",
      y_label = "Percentage",
      stack_label = "Satisfaction",
      stacked_type = "percent",
      x_order = education,
      stack_order = satisfaction,
      color_palette = satisfaction_colors,
      tooltip_suffix = "%",
      height = 480,
      tabgroup = "satisfaction/by_education"
    ) %>%
    # Satisfaction > By Region
    add_viz(
      type = "stackedbar",
      x_var = "region",
      stack_var = "satisfaction",
      title = "Satisfaction by Region",
      x_label = "Region",
      y_label = "Percentage",
      stack_label = "Satisfaction",
      stacked_type = "percent",
      x_order = regions,
      stack_order = satisfaction,
      color_palette = satisfaction_colors,
      tooltip_suffix = "%",
      height = 480,
      horizontal = TRUE,
      tabgroup = "satisfaction/by_region"
    ) %>%
    # Education > By Age
    add_viz(
      type = "stackedbar",
      x_var = "age_group",
      stack_var = "education",
      title = "Education by Age Group",
      x_label = "Age Group",
      y_label = "Percentage",
      stack_label = "Education",
      stacked_type = "percent",
      x_order = age_groups,
      stack_order = education,
      color_palette = education_colors,
      tooltip_suffix = "%",
      height = 480,
      tabgroup = "education/by_age"
    ) %>%
    # Education > By Region
    add_viz(
      type = "stackedbar",
      x_var = "region",
      stack_var = "education",
      title = "Education by Region",
      x_label = "Region",
      y_label = "Percentage",
      stack_label = "Education",
      stacked_type = "percent",
      x_order = regions,
      stack_order = education,
      color_palette = education_colors,
      tooltip_suffix = "%",
      height = 480,
      horizontal = TRUE,
      tabgroup = "education/by_region"
    ) %>%
    set_tabgroup_labels(list(
      satisfaction = "Satisfaction Analysis",
      by_age = "By Age",
      by_education = "By Education",
      by_region = "By Region",
      education = "Education Analysis"
    ))
  
  # ==========================================================================
  # LEVEL 3: Deep nested tabgroups (Category / Subcategory / Detail)
  # ==========================================================================
  level3_vizzes <- create_viz() %>%
    # Survey > Satisfaction > Age
    add_viz(
      type = "stackedbar",
      x_var = "age_group",
      stack_var = "satisfaction",
      title = "Age Distribution",
      x_label = "Age",
      y_label = "%",
      stack_label = "Satisfaction",
      stacked_type = "percent",
      x_order = age_groups,
      stack_order = satisfaction,
      color_palette = satisfaction_colors,
      tooltip_suffix = "%",
      height = 460,
      tabgroup = "survey/satisfaction/age"
    ) %>%
    # Survey > Satisfaction > Education
    add_viz(
      type = "stackedbar",
      x_var = "education",
      stack_var = "satisfaction",
      title = "Education Distribution",
      x_label = "Education",
      y_label = "%",
      stack_label = "Satisfaction",
      stacked_type = "percent",
      x_order = education,
      stack_order = satisfaction,
      color_palette = satisfaction_colors,
      tooltip_suffix = "%",
      height = 460,
      tabgroup = "survey/satisfaction/education"
    ) %>%
    # Survey > Demographics > Age
    add_viz(
      type = "stackedbar",
      x_var = "age_group",
      stack_var = "region",
      title = "Age by Region",
      x_label = "Age",
      y_label = "%",
      stack_label = "Region",
      stacked_type = "percent",
      x_order = age_groups,
      stack_order = regions,
      color_palette = region_colors,
      tooltip_suffix = "%",
      height = 460,
      tabgroup = "survey/demographics/age"
    ) %>%
    # Survey > Demographics > Education
    add_viz(
      type = "stackedbar",
      x_var = "education",
      stack_var = "region",
      title = "Education by Region",
      x_label = "Education",
      y_label = "%",
      stack_label = "Region",
      stacked_type = "percent",
      x_order = education,
      stack_order = regions,
      color_palette = region_colors,
      tooltip_suffix = "%",
      height = 460,
      horizontal = TRUE,
      tabgroup = "survey/demographics/education"
    ) %>%
    # Analysis > Trends > Regional
    add_viz(
      type = "stackedbar",
      x_var = "region",
      stack_var = "age_group",
      title = "Regional Age Distribution",
      x_label = "Region",
      y_label = "%",
      stack_label = "Age Group",
      stacked_type = "percent",
      x_order = regions,
      stack_order = age_groups,
      color_palette = c("#3B82F6", "#10B981", "#F59E0B", "#EF4444"),
      tooltip_suffix = "%",
      height = 460,
      horizontal = TRUE,
      tabgroup = "analysis/trends/regional"
    ) %>%
    # Analysis > Trends > Educational
    add_viz(
      type = "stackedbar",
      x_var = "education",
      stack_var = "age_group",
      title = "Educational Age Distribution",
      x_label = "Education",
      y_label = "%",
      stack_label = "Age Group",
      stacked_type = "percent",
      x_order = education,
      stack_order = age_groups,
      color_palette = c("#3B82F6", "#10B981", "#F59E0B", "#EF4444"),
      tooltip_suffix = "%",
      height = 460,
      tabgroup = "analysis/trends/educational"
    ) %>%
    set_tabgroup_labels(list(
      survey = "Survey Results",
      satisfaction = "Satisfaction",
      demographics = "Demographics",
      age = "By Age",
      education = "By Education",
      analysis = "Analysis",
      trends = "Trends",
      regional = "Regional",
      educational = "Educational"
    ))
  
  # Create the dashboard
  dashboard <- create_dashboard(
    title = paste0("Tabset Theme: ", tools::toTitleCase(theme_name)),
    output_dir = output_dir,
    theme = "flatly",
    tabset_theme = theme_name,
    allow_inside_pkg = TRUE
  ) %>%
    add_page(
      name = "Home",
      icon = "ph:house",
      is_landing_page = TRUE,
      text = md_text(
        paste0("# ", tools::toTitleCase(theme_name), " Tabset Theme"),
        "",
        paste0("This dashboard demonstrates the **", theme_name, "** tabset theme with different nesting levels."),
        "",
        "## How to Use This Theme",
        "",
        "```r",
        "create_dashboard(",
        "  title = \"My Dashboard\",",
        "  output_dir = \"my_dashboard\",",
        paste0("  tabset_theme = \"", theme_name, "\""),
        ")",
        "```",
        "",
        "## Demo Pages",
        "",
        "- **1 Level** - Simple tabs (Demographics, Regions)",
        "- **2 Levels** - Nested tabs (Topic > Subtopic)",
        "- **3 Levels** - Deep nesting (Category > Subcategory > Detail)"
      )
    ) %>%
    add_page(
      name = "1 Level",
      icon = "ph:rows",
      data = survey_data,
      visualizations = level1_vizzes,
      text = md_text(
        "## Single Level Tabs",
        "",
        "Each visualization gets a **different** tabgroup name, creating separate top-level tabs:",
        "",
        "```r",
        "add_viz(..., tabgroup = \"age\") %>%",
        "add_viz(..., tabgroup = \"education\") %>%",
        "add_viz(..., tabgroup = \"region\")",
        "```"
      )
    ) %>%
    add_page(
      name = "2 Levels",
      icon = "ph:stack",
      data = survey_data,
      visualizations = level2_vizzes,
      text = md_text(
        "## Two Level Nested Tabs",
        "",
        "Use `/` to create parent and child tabs:",
        "",
        "```r",
        "add_viz(..., tabgroup = \"satisfaction/by_age\") %>%",
        "add_viz(..., tabgroup = \"satisfaction/by_education\") %>%",
        "add_viz(..., tabgroup = \"education/by_age\")",
        "```"
      )
    ) %>%
    add_page(
      name = "3 Levels",
      icon = "ph:tree-structure",
      data = survey_data,
      visualizations = level3_vizzes,
      text = md_text(
        "## Three Level Nested Tabs",
        "",
        "Add more `/` for deeper nesting:",
        "",
        "```r",
        "add_viz(..., tabgroup = \"survey/satisfaction/age\") %>%",
        "add_viz(..., tabgroup = \"survey/demographics/education\") %>%",
        "add_viz(..., tabgroup = \"analysis/trends/regional\")",
        "```"
      )
    ) %>%
    add_powered_by_dashboardr(size = "small", style = "minimal")
  
  # Generate
  result <- tryCatch(
    generate_dashboard(dashboard, render = TRUE, open = FALSE),
    error = function(e) {
      cat("      ⚠️  Error:", e$message, "\n")
      NULL
    }
  )
  
  # Check for HTML and move if in docs/ subdirectory
  html_locations <- c(
    file.path(output_dir, "index.html"),
    file.path(output_dir, "docs", "index.html")
  )
  
  for (loc in html_locations) {
    if (file.exists(loc)) {
      if (grepl("/docs/index.html$", loc)) {
        docs_dir <- dirname(loc)
        files_to_move <- list.files(docs_dir, full.names = TRUE)
        for (f in files_to_move) {
          file.copy(f, output_dir, recursive = TRUE, overwrite = TRUE)
        }
        unlink(docs_dir, recursive = TRUE)
      }
      cat("      ✅", theme_name, "dashboard created\n")
      return(TRUE)
    }
  }
  
  cat("      ⚠️  QMD files created (needs Quarto render)\n")
  return(FALSE)
}

# Generate all 6 tabset theme dashboards
results <- list()
for (theme in themes) {
  results[[theme]] <- create_tabset_demo(theme)
}

# Summary
cat("\n═══════════════════════════════════════════════════════════════════════════\n")
cat("  Tabset Theme Dashboards Summary\n")
cat("═══════════════════════════════════════════════════════════════════════════\n\n")

for (theme in themes) {
  status <- if (isTRUE(results[[theme]])) "✅ Success" else "⚠️  QMD only"
  cat(sprintf("   %-12s %s\n", theme, status))
}

cat("\n📁 Output location:", file.path(pkg_root, "docs", "live-demos", "tabsets"), "\n")
cat("\n🔗 URLs (after deployment):\n")
for (theme in themes) {
  cat("   https://favstats.github.io/dashboardr/live-demos/tabsets/", theme, "/index.html\n", sep = "")
}
