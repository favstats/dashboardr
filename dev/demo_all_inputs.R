# =============================================================================
# Demo: All Input Types - FULLY CONNECTED
# 
# Every input controls a different aspect of the visualization.
# =============================================================================

library(tidyverse)
devtools::load_all()

set.seed(42)

# =============================================================================
# Generate Demo Dataset
# =============================================================================

# Create data with multiple dimensions that each input can filter
categories <- c("Technology", "Finance", "Healthcare", "Retail", "Energy")
regions <- c("North", "South", "East", "West")
years <- 2019:2024
quarters <- paste0("Q", 1:4)
experience <- c("Junior", "Mid", "Senior")

# Generate comprehensive data
base_data <- expand_grid(
  category = categories,
  region = regions,
  year = years,
  quarter = quarters,
  experience = experience
) %>%
  mutate(
    # Create time period string
    period = paste0(year, " ", quarter),
    
    # Performance score varies by category and experience
    base_score = case_when(
      category == "Technology" ~ 75,
      category == "Finance" ~ 70,
      category == "Healthcare" ~ 72,
      category == "Retail" ~ 65,
      category == "Energy" ~ 68
    ),
    exp_bonus = case_when(
      experience == "Senior" ~ 15,
      experience == "Mid" ~ 8,
      experience == "Junior" ~ 0
    ),
    region_bonus = case_when(
      region == "North" ~ 5,
      region == "South" ~ 3,
      region == "East" ~ 4,
      region == "West" ~ 2
    ),
    # Time trend
    year_trend = (year - 2019) * 2,
    quarter_trend = as.numeric(gsub("Q", "", quarter)) * 0.5,
    
    # Final score with noise
    score = round(base_score + exp_bonus + region_bonus + year_trend + quarter_trend + rnorm(n(), 0, 5), 1),
    score = pmax(40, pmin(100, score)),
    
    # Revenue (in thousands)
    revenue = round(score * runif(n(), 8, 15) + rnorm(n(), 0, 20), 1),
    revenue = pmax(100, revenue),
    
    # Growth rate
    growth = round(rnorm(n(), 5, 8), 1)
  )

# Add "All Regions" aggregate for toggle
all_regions_data <- base_data %>%
  group_by(category, year, quarter, period, experience) %>%
  summarise(
    score = mean(score),
    revenue = sum(revenue) / 4,  # Average per region
    growth = mean(growth),
    .groups = "drop"
  ) %>%
  mutate(region = "All Regions Average")

# Combine
full_data <- bind_rows(base_data, all_regions_data)

# Create visualization data grouped by period and region
viz_data <- full_data %>%
  group_by(period, region) %>%
  summarise(
    score = round(mean(score), 1),
    revenue = round(mean(revenue), 1),
    growth = round(mean(growth), 1),
    .groups = "drop"
  ) %>%
  # Pivot for metric switching
  pivot_longer(
    cols = c(score, revenue, growth),
    names_to = "metric",
    values_to = "value"
  ) %>%
  mutate(
    metric = case_when(
      metric == "score" ~ "Performance Score",
      metric == "revenue" ~ "Revenue ($K)",
      metric == "growth" ~ "Growth Rate (%)",
      TRUE ~ metric
    )
  ) %>%
  # Add year column for slider filtering
  mutate(year = as.numeric(substr(period, 1, 4)))

cat("Generated", nrow(viz_data), "rows\n")
cat("Regions:", paste(unique(viz_data$region), collapse = ", "), "\n")
cat("Metrics:", paste(unique(viz_data$metric), collapse = ", "), "\n")
cat("Years:", paste(unique(viz_data$year), collapse = ", "), "\n")

# =============================================================================
# Visualization
# =============================================================================

viz <- create_viz() %>%
  add_viz(
    type = "timeline",
    time_var = "period",
    y_var = "value",
    group_var = "region",
    chart_type = "line",
    title = "Regional Performance Dashboard",
    subtitle = "All inputs below control different aspects of this chart",
    x_label = "Time Period",
    y_label = "Value"
  )

# =============================================================================
# Content with ALL CONNECTED Inputs
# =============================================================================

content <- create_content() %>%
  add_text(md_text(
    "## 🎛️ All Inputs Connected Demo",
    "",
    "**Every input below affects the chart.** Try them all!"
  )) %>%
  
  # =========================================
  # ROW 1: Region filter + Metric selector
  # =========================================
  add_input_row(style = "boxed", align = "center") %>%
    add_input(
      input_id = "region_filter",
      label = "🌍 Regions",
      type = "select_multiple",
      filter_var = "region",
      options = c("North", "South", "East", "West"),
      default_selected = c("North", "South", "East", "West"),
      placeholder = "Select regions...",
      width = "350px",
      help = "MULTI-SELECT: Filters which region lines appear on the chart.",
      mr = "20px"
    ) %>%
    add_input(
      input_id = "metric_select",
      label = "📊 Metric",
      type = "select_single",
      filter_var = "metric",
      options = c("Performance Score", "Revenue ($K)", "Growth Rate (%)"),
      default_selected = "Performance Score",
      width = "220px",
      help = "SINGLE-SELECT: Switches the entire dataset displayed."
    ) %>%
    add_input(
      input_id = "show_average",
      label = "Show All Regions Average",
      type = "switch",
      filter_var = "region",
      toggle_series = "All Regions Average",
      override = TRUE,
      value = TRUE,
      width = "auto",
      ml = "20px",
      help = "SWITCH: Toggles the 'All Regions Average' benchmark line."
    ) %>%
  end_input_row() %>%
  
  add_spacer(height = "1rem") %>%
  
  # =========================================
  # ROW 2: Year slider + Search
  # =========================================
  add_input_row(style = "boxed", align = "center") %>%
    add_input(
      input_id = "year_slider",
      label = "📅 Starting Year",
      type = "slider",
      filter_var = "year",
      min = 1,
      max = 6,
      step = 1,
      value = 1,
      show_value = TRUE,
      width = "300px",
      labels = c("2019", "2020", "2021", "2022", "2023", "2024"),
      help = "SLIDER: Shows data from this year onwards. Uses custom labels.",
      mr = "30px"
    ) %>%
    add_input(
      input_id = "search_region",
      label = "🔍 Search Regions",
      type = "text",
      filter_var = "region",
      placeholder = "Type to filter...",
      width = "200px",
      help = "TEXT: Filters regions containing this text (e.g., 'orth' matches 'North')."
    ) %>%
  end_input_row() %>%
  
  add_spacer(height = "1rem") %>%
  
  # =========================================
  # ROW 3: Checkboxes (region filter alternative)
  # =========================================
  add_input_row(style = "boxed", align = "center") %>%
    add_input(
      input_id = "region_checkboxes",
      label = "☑️ Quick Region Filter",
      type = "checkbox",
      filter_var = "region",
      options = c("North", "South", "East", "West"),
      default_selected = c("North", "South", "East", "West"),
      inline = TRUE,
      width = "500px",
      help = "CHECKBOX: Alternative way to filter regions. Works like multi-select."
    ) %>%
  end_input_row() %>%
  
  add_spacer(height = "1rem") %>%
  
  # =========================================
  # ROW 4: Radio buttons (single region focus)
  # =========================================
  add_input_row(style = "boxed", align = "center") %>%
    add_input(
      input_id = "focus_region",
      label = "🎯 Focus on Region",
      type = "radio",
      filter_var = "region",
      options = c("North", "South", "East", "West"),
      default_selected = "North",
      inline = TRUE,
      width = "400px",
      help = "RADIO: Single-choice filter. Shows only the selected region."
    ) %>%
  end_input_row() %>%
  
  add_spacer(height = "1rem") %>%
  
  # =========================================
  # ROW 5: Button Group (metric quick switch)
  # =========================================
  add_input_row(style = "boxed", align = "center") %>%
    add_input(
      input_id = "metric_buttons",
      label = "⚡ Quick Metric Switch",
      type = "button_group",
      filter_var = "metric",
      options = c("Performance Score", "Revenue ($K)", "Growth Rate (%)"),
      default_selected = "Performance Score",
      width = "auto",
      help = "BUTTON GROUP: Quick toggle between metrics. Same as single-select above."
    ) %>%
  end_input_row() %>%
  
  add_spacer(height = "1.5rem") %>%
  
  # =========================================
  # SIZE VARIANTS DEMO
  # =========================================
  add_text(md_text(
    "### Size Variants (sm / md / lg)",
    "These are display-only demos showing the three size options:"
  )) %>%
  
  add_input_row(style = "inline", align = "center") %>%
    add_input(
      input_id = "demo_sm",
      label = "Small (sm)",
      type = "select_single",
      filter_var = "demo",
      options = c("A", "B", "C"),
      default_selected = "A",
      width = "120px",
      size = "sm",
      mr = "15px"
    ) %>%
    add_input(
      input_id = "demo_md",
      label = "Medium (md)",
      type = "select_single",
      filter_var = "demo",
      options = c("A", "B", "C"),
      default_selected = "A",
      width = "140px",
      size = "md",
      mr = "15px"
    ) %>%
    add_input(
      input_id = "demo_lg",
      label = "Large (lg)",
      type = "select_single",
      filter_var = "demo",
      options = c("A", "B", "C"),
      default_selected = "A",
      width = "160px",
      size = "lg"
    ) %>%
  end_input_row()

# Combine
this <- content + viz

# =============================================================================
# Dashboard
# =============================================================================

dashboard <- create_dashboard(
  title = "All Inputs Demo",
  output_dir = "demo_all_inputs_dashboard",
  tabset_theme = "modern",
  author = "dashboardr",
  description = "Every input type connected and functional"
) %>%
  add_page(
    name = "Demo",
    data = viz_data,
    content = this,
    time_var = "period",
    icon = "ph:sliders-horizontal",
    is_landing_page = TRUE
  ) %>%
  add_page(
    name = "Input Reference",
    text = md_text(
      "# Input Types Reference",
      "",
      "## What Each Input Does",
      "",
      "| Input | Type | filter_var | Effect |",
      "|-------|------|------------|--------|",
      "| Regions | `select_multiple` | `region` | Shows/hides region lines |",
      "| Metric | `select_single` | `metric` | Switches entire dataset |",
      "| Show Average | `switch` | `region` + `toggle_series` | Toggles benchmark line |",
      "| Year Slider | `slider` | `year` | Filters time range |",
      "| Search | `text` | `region` | Text search on series names |",
      "| Checkboxes | `checkbox` | `region` | Multi-select alternative |",
      "| Radio | `radio` | `region` | Single region focus |",
      "| Buttons | `button_group` | `metric` | Quick metric toggle |",
      "",
      "## Key Parameters",
      "",
      "```r",
      "add_input(",
      "  input_id = 'my_filter',",
      "  label = 'My Label',",
      "  type = 'select_multiple',  # Input type",
      "  filter_var = 'column_name', # Column to filter",
      "  options = c('A', 'B', 'C'), # Available options",
      "  default_selected = 'A',     # Initial selection",
      "  width = '300px',            # Input width",
      "  size = 'md',                # sm, md, lg",
      "  help = 'Help text',         # Description below",
      "  mt = '10px',                # Margin top",
      "  mr = '10px',                # Margin right",
      "  mb = '10px',                # Margin bottom",
      "  ml = '10px'                 # Margin left",
      ")",
      "```",
      "",
      "## Special Parameters",
      "",
      "### Slider with Labels",
      "```r",
      "labels = c('2019', '2020', '2021', '2022')",
      "```",
      "",
      "### Switch with Toggle Series",
      "```r",
      "toggle_series = 'Series Name'",
      "override = TRUE  # Exempt from other filters",
      "```",
      "",
      "### Grouped Options",
      "```r",
      "options = list(",
      "  'Group A' = c('Option 1', 'Option 2'),",
      "  'Group B' = c('Option 3', 'Option 4')",
      ")",
      "```"
    ),
    icon = "ph:book-open"
  ) %>%
  add_powered_by_dashboardr(size = "small")

print(dashboard)

cat("\n=== Generating All Inputs Demo ===\n")
generate_dashboard(dashboard, render = TRUE, open = "browser")
cat("\n=== Done! ===\n")
