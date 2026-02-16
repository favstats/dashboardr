# =============================================================================
# dashboardr Demo: ggiraph Backend Showcase
# =============================================================================
# Exercises every ggiraph-compatible chart type with color_palette and
# data_labels_enabled to visually verify coloring/labeling fixes.
#
# Run with:
#   source("dev/demo_ggiraph_showcase.R")

library(tidyverse)

devtools::load_all()

set.seed(42)

# =============================================================================
# Synthetic data
# =============================================================================

n <- 500

survey_data <- tibble(
  id = seq_len(n),
  year = sample(2020:2024, n, replace = TRUE),
  category = sample(c("Alpha", "Bravo", "Charlie", "Delta"), n, replace = TRUE),
  group = sample(c("Group 1", "Group 2"), n, replace = TRUE),
  gender = sample(c("Female", "Male"), n, replace = TRUE),
  region = sample(c("North", "South", "East", "West"), n, replace = TRUE),
  age = pmax(18, pmin(85, round(rnorm(n, 45, 14)))),
  income = pmax(15000, round(rnorm(n, 65000, 22000))),
  score = pmax(20, pmin(100, round(rnorm(n, 70, 12))))
)

# Funnel data
funnel_data <- tibble(
  stage = c("Visitors", "Signups", "Trial", "Paid", "Retained"),
  count = c(10000, 5200, 2800, 1400, 950)
)

# Sankey data
sankey_data <- tibble(
  source = c("Organic", "Organic", "Paid", "Paid", "Social", "Social"),
  target = c("Signup", "Bounce", "Signup", "Bounce", "Signup", "Bounce"),
  flow = c(300, 120, 180, 90, 150, 200)
)

# Heatmap data
heatmap_data <- expand.grid(
  x_cat = c("Mon", "Tue", "Wed", "Thu", "Fri"),
  y_cat = c("Morning", "Afternoon", "Evening")
) %>%
  as_tibble() %>%
  mutate(activity = round(runif(n(), 10, 100)))

# Dumbbell data
dumbbell_data <- tibble(
  department = c("Engineering", "Marketing", "Sales", "Support", "Design"),
  q1_score = c(72, 65, 58, 80, 70),
  q4_score = c(88, 78, 75, 85, 82)
)

# Color palettes
pal4 <- c("#E15759", "#4E79A7", "#76B7B2", "#F28E2B")
pal2 <- c("#E15759", "#4E79A7")
pal5 <- c("#E15759", "#4E79A7", "#76B7B2", "#F28E2B", "#59A14F")

# =============================================================================
# Page 1: Bar & Column Charts
# =============================================================================

page1_viz <- create_viz() %>%
  # Bug #1 fix: ungrouped bar with color_palette
  add_viz(
    type = "bar",
    x_var = "category",
    title = "Ungrouped Bar (color_palette)",
    color_palette = pal4,
    data_labels_enabled = TRUE,
    data = "survey",
    tabgroup = "Bars/Ungrouped"
  ) %>%
  # Grouped bar with color_palette
  add_viz(
    type = "bar",
    x_var = "category",
    group_var = "group",
    title = "Grouped Bar (color_palette)",
    color_palette = pal2,
    data_labels_enabled = TRUE,
    data = "survey",
    tabgroup = "Bars/Grouped"
  ) %>%
  # Bug #2 fix: percent bar with "%" labels
  add_viz(
    type = "bar",
    x_var = "category",
    bar_type = "percent",
    title = "Percent Bar (labels should show %)",
    color_palette = pal4,
    data_labels_enabled = TRUE,
    data = "survey",
    tabgroup = "Bars/Percent"
  ) %>%
  # Stacked bar with data labels
  add_viz(
    type = "stackedbar",
    x_var = "category",
    stack_var = "group",
    stacked_type = "percent",
    title = "Stacked Bar (percent, labels)",
    color_palette = pal2,
    data_labels_enabled = TRUE,
    data = "survey",
    tabgroup = "Stacked"
  ) %>%
  # Bug #4 & #5 fix: ungrouped lollipop with color + labels
  add_viz(
    type = "lollipop",
    x_var = "category",
    title = "Ungrouped Lollipop (color + labels)",
    color_palette = pal4,
    data_labels_enabled = TRUE,
    data = "survey",
    tabgroup = "Lollipops/Ungrouped"
  ) %>%
  # Grouped lollipop
  add_viz(
    type = "lollipop",
    x_var = "category",
    group_var = "group",
    title = "Grouped Lollipop (color_palette)",
    color_palette = pal2,
    data_labels_enabled = TRUE,
    data = "survey",
    tabgroup = "Lollipops/Grouped"
  ) %>%
  # Bug #7 fix: funnel with data labels
  add_viz(
    type = "funnel",
    x_var = "stage",
    y_var = "count",
    title = "Funnel (color + labels)",
    color_palette = pal5,
    data_labels_enabled = TRUE,
    data = "funnel"
  ) %>%
  # Histogram with color + labels
  add_viz(
    type = "histogram",
    x_var = "age",
    bins = 15,
    title = "Histogram (color + labels)",
    color_palette = "#4E79A7",
    data_labels_enabled = TRUE,
    data = "survey",
    tabgroup = "Histogram"
  )

# =============================================================================
# Page 2: Distributions & Relations
# =============================================================================

page2_viz <- create_viz() %>%
  # Bug #3 fix: boxplot with fill colors
  add_viz(
    type = "boxplot",
    x_var = "category",
    y_var = "income",
    title = "Boxplot (color_palette fills)",
    color_palette = pal4,
    data = "survey",
    tabgroup = "Boxplot"
  ) %>%
  # Density with group colors
  add_viz(
    type = "density",
    x_var = "age",
    group_var = "gender",
    title = "Density (grouped, color_palette)",
    color_palette = pal2,
    data = "survey",
    tabgroup = "Density"
  ) %>%
  # Scatter with color_var
  add_viz(
    type = "scatter",
    x_var = "age",
    y_var = "income",
    color_var = "region",
    title = "Scatter (color_var + palette)",
    color_palette = pal4,
    data = "survey",
    tabgroup = "Scatter"
  ) %>%
  # Pie
  add_viz(
    type = "pie",
    x_var = "region",
    title = "Pie Chart (color_palette)",
    color_palette = pal4,
    data = "survey",
    tabgroup = "Pie & Donut/Pie"
  ) %>%
  # Donut
  add_viz(
    type = "donut",
    x_var = "category",
    title = "Donut Chart (color_palette)",
    color_palette = pal4,
    inner_size = "50%",
    data = "survey",
    tabgroup = "Pie & Donut/Donut"
  ) %>%
  # Waffle
  add_viz(
    type = "waffle",
    x_var = "region",
    title = "Waffle (color_palette)",
    color_palette = pal4,
    data = "survey",
    tabgroup = "Waffle"
  ) %>%
  # Heatmap (gradient)
  add_viz(
    type = "heatmap",
    x_var = "x_cat",
    y_var = "y_cat",
    value_var = "activity",
    title = "Heatmap (gradient palette)",
    color_palette = c("#f7fbff", "#08519c"),
    data = "heatmap",
    tabgroup = "Heatmap"
  ) %>%
  # Dumbbell
  add_viz(
    type = "dumbbell",
    x_var = "department",
    low_var = "q1_score",
    high_var = "q4_score",
    title = "Dumbbell (low/high colors)",
    low_color = "#E15759",
    high_color = "#4E79A7",
    data = "dumbbell",
    tabgroup = "Dumbbell"
  ) %>%
  # Sankey
  add_viz(
    type = "sankey",
    from_var = "source",
    to_var = "target",
    value_var = "flow",
    title = "Sankey (color_palette)",
    color_palette = c("#E15759", "#4E79A7", "#76B7B2"),
    data = "sankey",
    tabgroup = "Sankey"
  )

# =============================================================================
# Page 3: Time Series
# =============================================================================

page3_viz <- create_viz() %>%
  # Timeline line (grouped)
  add_viz(
    type = "timeline",
    time_var = "year",
    y_var = "score",
    group_var = "region",
    chart_type = "line",
    title = "Timeline Line (grouped, color_palette)",
    color_palette = pal4,
    tabgroup = "Line"
  ) %>%
  # Bug #6 fix: timeline column with fill scale
  add_viz(
    type = "timeline",
    time_var = "year",
    y_var = "score",
    group_var = "region",
    chart_type = "column",
    agg = "mean",
    title = "Timeline Column (grouped, color_palette)",
    color_palette = pal4,
    tabgroup = "Column"
  ) %>%
  # Timeline stacked area
  add_viz(
    type = "timeline",
    time_var = "year",
    y_var = "region",
    chart_type = "stacked_area",
    title = "Timeline Stacked Area (color_palette)",
    color_palette = pal4,
    tabgroup = "Stacked Area"
  )

# =============================================================================
# Build Dashboard
# =============================================================================

output_dir <- "dev/ggiraph_showcase"
if (dir.exists(output_dir)) unlink(output_dir, recursive = TRUE, force = TRUE)

dashboard <- create_dashboard(
  output_dir = output_dir,
  title = "Ggiraph Backend Showcase",
  backend = "ggiraph"
) %>%
  add_page(
    name = "Bar & Column Charts",
    icon = "ph:chart-bar",
    data = list(survey = survey_data, funnel = funnel_data),
    visualizations = page1_viz
  ) %>%
  add_page(
    name = "Distributions & Relations",
    icon = "ph:chart-scatter",
    data = list(
      survey = survey_data,
      heatmap = heatmap_data,
      dumbbell = dumbbell_data,
      sankey = sankey_data
    ),
    visualizations = page2_viz
  ) %>%
  add_page(
    name = "Time Series",
    icon = "ph:chart-line",
    data = survey_data,
    visualizations = page3_viz
  )

# =============================================================================
# Generate and open
# =============================================================================

resolve_demo_open <- function() {
  raw <- tolower(trimws(Sys.getenv("DASHBOARDR_DEMO_OPEN", unset = "browser")))
  if (raw %in% c("false", "0", "no", "none")) return(FALSE)
  "browser"
}

generate_dashboard(dashboard, render = TRUE, open = resolve_demo_open())

cat("\nGgiraph showcase dashboard generated at:", normalizePath(output_dir, mustWork = FALSE), "\n")
cat("\nVerification checklist:\n")
cat(" 1. Ungrouped bar/lollipop use color_palette colors (not gray)\n")
cat(" 2. Percent bar labels show '%' suffix\n")
cat(" 3. Boxplot boxes are colored by category\n")
cat(" 4. Lollipop dots show data labels\n")
cat(" 5. Funnel shows data labels\n")
cat(" 6. Timeline column chart uses color_palette\n")
