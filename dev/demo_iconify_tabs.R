# Demo: Iconify Icons in Tab Titles
# Shows that prefer-html: true enables iconify in tab names

# library(dashboardr)
devtools::load_all()

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
    tabgroup = "trends/overall"
  ) %>%
  add_viz(
    group_var = "group",
    tabgroup = "trends/grouped"
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
  combine_viz(timeline_viz)  %>%
  add_pagination() %>%
  combine_viz(timeline_viz)  %>%
  add_pagination() %>%
  combine_viz(icon_showcase_viz) %>%
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
  output_dir = "iconify_tabs_demo",
  title = "Iconify in Tabs Demo",
  mobile_toc = T,
  pagination_separator = "/",
  pagination_position = "bottom",
  viewport_width = 1200,
  viewport_scale = 0.3  # Zoom out to fit whole page
) %>%
  apply_theme(theme_modern(style = "purple")) %>%

  # Landing page
  add_page(
    overlay = T, overlay_duration = 1,
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
    overlay = T, overlay_duration = 1,
    name = "Analysis",
    icon = "ph:chart-bar-fill",
    data = sample_data,
    visualizations = all_viz,
    text = md_text(
      "# Data Analysis with Iconified Tabs",
      "",
      "Check out the tabs below -x they all have icons! ✨",
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
