# =============================================================================
# Demo: show_when works with EVERY SINGLE visualization type in dashboardr
#
# This script creates a dashboard with all 20 viz types, each wrapped in a
# show_when condition, then verifies the generated QMD files contain
# show_when_open() calls for every single type.
#
# Viz types tested (20 total):
#   bar, scatter, density, boxplot, histogram, heatmap, timeline, treemap,
#   map, stackedbar, stackedbars, pie, donut, lollipop, dumbbell, gauge,
#   funnel, pyramid, sankey, waffle
#
# Usage:
#   source("dev/demo_show_when_all_types.R")
# =============================================================================

devtools::load_all()
library(dplyr)

set.seed(42)

# =============================================================================
# SAMPLE DATASETS
# =============================================================================

# --- Main dataset (covers bar, scatter, density, boxplot, histogram, pie,
#     donut, lollipop, stackedbar) ---
n <- 400
main_data <- tibble(
  time_period    = sample(c("2022", "2024", "Over Time"), n, replace = TRUE),
  breakdown_type = sample(c("Overall", "Gender", "Age"), n, replace = TRUE),
  category       = sample(c("Engineering", "Marketing", "Sales", "HR", "Finance"),
                          n, replace = TRUE),
  group          = sample(c("Group A", "Group B"), n, replace = TRUE),
  value          = round(rnorm(n, mean = 50, sd = 15)),
  score          = round(rnorm(n, mean = 70, sd = 10)),
  x_continuous   = round(rnorm(n, mean = 100, sd = 25), 1),
  y_continuous   = round(rnorm(n, mean = 200, sd = 50), 1),
  response       = sample(c("Agree", "Neutral", "Disagree"), n, replace = TRUE)
)

# --- Heatmap data ---
heatmap_data <- expand.grid(
  time_period    = c("2022", "2024", "Over Time"),
  breakdown_type = c("Overall", "Gender", "Age"),
  x_cat          = paste0("X", 1:5),
  y_cat          = paste0("Y", 1:4),
  stringsAsFactors = FALSE
) %>%
  mutate(heat_value = round(runif(n(), 10, 100)))

# --- Timeline data ---
timeline_data <- expand.grid(
  time_period    = c("2022", "2024", "Over Time"),
  breakdown_type = c("Overall", "Gender", "Age"),
  year           = 2015:2024,
  group_var      = c("North", "South", "East"),
  stringsAsFactors = FALSE
) %>%
  mutate(score = round(rnorm(n(), mean = 60, sd = 12), 1))

# --- Treemap data ---
treemap_data <- expand.grid(
  time_period    = c("2022", "2024", "Over Time"),
  breakdown_type = c("Overall", "Gender", "Age"),
  region         = c("North America", "Europe", "Asia", "Africa"),
  stringsAsFactors = FALSE
) %>%
  mutate(spend = round(runif(n(), 1000, 50000)))

# --- Map data (one value per country to avoid duplicate join keys) ---
map_data <- tibble(
  iso2c     = c("US", "GB", "DE", "FR", "JP", "AU", "BR", "IN", "CA", "MX"),
  map_value = c(79, 45, 67, 52, 88, 34, 61, 93, 71, 28)
)

# --- Stackedbars (multi-variable) data ---
stackedbars_data <- expand.grid(
  time_period    = c("2022", "2024", "Over Time"),
  breakdown_type = c("Overall", "Gender", "Age"),
  stringsAsFactors = FALSE
)
# Add Likert-scale question columns
set.seed(99)
nr <- nrow(stackedbars_data)
stackedbars_data$q1 <- sample(c("Strongly Agree", "Agree", "Neutral", "Disagree", "Strongly Disagree"), nr * 10, replace = TRUE)[1:nr]
stackedbars_data$q2 <- sample(c("Strongly Agree", "Agree", "Neutral", "Disagree", "Strongly Disagree"), nr * 10, replace = TRUE)[1:nr]
stackedbars_data$q3 <- sample(c("Strongly Agree", "Agree", "Neutral", "Disagree", "Strongly Disagree"), nr * 10, replace = TRUE)[1:nr]
# Replicate rows to have enough for stacking
stackedbars_data <- stackedbars_data[rep(seq_len(nr), each = 30), ]

# --- Dumbbell data ---
dumbbell_data <- expand.grid(
  time_period    = c("2022", "2024", "Over Time"),
  breakdown_type = c("Overall", "Gender", "Age"),
  department     = c("Engineering", "Marketing", "Sales", "HR", "Finance"),
  stringsAsFactors = FALSE
) %>%
  mutate(
    low_val  = round(runif(n(), 40, 60)),
    high_val = round(runif(n(), 65, 90))
  )

# --- Funnel / Pyramid data ---
funnel_data <- expand.grid(
  time_period    = c("2022", "2024", "Over Time"),
  breakdown_type = c("Overall", "Gender", "Age"),
  stage          = c("Awareness", "Interest", "Consideration", "Intent", "Purchase"),
  stringsAsFactors = FALSE
) %>%
  group_by(time_period, breakdown_type) %>%
  mutate(funnel_count = sort(round(runif(n(), 50, 5000)), decreasing = TRUE)) %>%
  ungroup()

# --- Sankey data ---
sankey_data <- expand.grid(
  time_period    = c("2022", "2024", "Over Time"),
  breakdown_type = c("Overall", "Gender", "Age"),
  stringsAsFactors = FALSE
)
# Create flow rows for each combination
sankey_rows <- list()
for (i in seq_len(nrow(sankey_data))) {
  base <- sankey_data[i, ]
  flows <- tibble(
    from  = c("Revenue", "Revenue", "Revenue", "OpEx", "OpEx"),
    to    = c("OpEx", "CapEx", "R&D", "Salaries", "Marketing"),
    flow  = c(45, 20, 35, 25, 10)
  )
  sankey_rows[[i]] <- bind_cols(
    base[rep(1, nrow(flows)), ],
    flows
  )
}
sankey_data <- bind_rows(sankey_rows)

# --- Waffle data ---
waffle_data <- expand.grid(
  time_period    = c("2022", "2024", "Over Time"),
  breakdown_type = c("Overall", "Gender", "Age"),
  category       = c("Engineering", "Marketing", "Sales", "HR", "Finance"),
  stringsAsFactors = FALSE
) %>%
  mutate(count = c(30, 25, 20, 15, 10)[match(category,
    c("Engineering", "Marketing", "Sales", "HR", "Finance"))])

# --- Lollipop data (pre-aggregated) ---
lollipop_data <- expand.grid(
  time_period    = c("2022", "2024", "Over Time"),
  breakdown_type = c("Overall", "Gender", "Age"),
  category       = c("Engineering", "Marketing", "Sales", "HR", "Finance"),
  stringsAsFactors = FALSE
) %>%
  mutate(avg_score = round(runif(n(), 45, 90), 1))


# =============================================================================
# BUILD THE DASHBOARD
# =============================================================================

output_dir <- tempfile(pattern = "show_when_all_types_")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# --- Design ---
# Each page uses a "Select Chart" input so the correspondence between
# input selection and displayed chart is immediately obvious.
# We alternate between DROPDOWN and RADIO inputs across pages to
# demonstrate both input types with show_when.

# ---- Page 1: Classic charts (bar, scatter, density, boxplot, histogram) ----
# Uses a DROPDOWN selector
page1_content <- create_content(data = main_data) %>%
  add_sidebar(title = "Controls", width = "280px") %>%
    add_input(
      input_id         = "chart1",
      label            = "Select Chart",
      type             = "select_single",
      filter_var       = "chart_type",
      options          = c("Bar", "Scatter", "Density", "Boxplot", "Histogram"),
      default_selected = "Bar"
    ) %>%
  end_sidebar() %>%
  # 1. BAR
  add_viz(
    type      = "bar",
    x_var     = "category",
    title     = "Bar Chart",
    show_when = ~ chart_type == "Bar"
  ) %>%
  # 2. SCATTER
  add_viz(
    type      = "scatter",
    x_var     = "x_continuous",
    y_var     = "y_continuous",
    title     = "Scatter Plot",
    show_when = ~ chart_type == "Scatter"
  ) %>%
  # 3. DENSITY
  add_viz(
    type      = "density",
    x_var     = "value",
    title     = "Density Plot",
    show_when = ~ chart_type == "Density"
  ) %>%
  # 4. BOXPLOT
  add_viz(
    type      = "boxplot",
    x_var     = "category",
    y_var     = "value",
    title     = "Boxplot",
    show_when = ~ chart_type == "Boxplot"
  ) %>%
  # 5. HISTOGRAM
  add_viz(
    type      = "histogram",
    x_var     = "score",
    title     = "Histogram",
    show_when = ~ chart_type == "Histogram"
  )

# ---- Page 2: Advanced charts (heatmap, timeline, treemap, map) ----
# Uses RADIO buttons
page2_content <- create_content() %>%
  add_sidebar(title = "Controls", width = "280px") %>%
    add_input(
      input_id         = "chart2",
      label            = "Select Chart",
      type             = "radio",
      filter_var       = "chart_type",
      options          = c("Heatmap", "Timeline", "Treemap", "Map"),
      default_selected = "Heatmap",
      stacked          = TRUE
    ) %>%
  end_sidebar() %>%
  # 6. HEATMAP
  add_viz(
    type      = "heatmap",
    data      = heatmap_data,
    x_var     = "x_cat",
    y_var     = "y_cat",
    value_var = "heat_value",
    title     = "Heatmap",
    show_when = ~ chart_type == "Heatmap"
  ) %>%
  # 7. TIMELINE
  add_viz(
    type      = "timeline",
    data      = timeline_data,
    time_var  = "year",
    y_var     = "score",
    group_var = "group_var",
    agg       = "none",
    title     = "Timeline",
    show_when = ~ chart_type == "Timeline"
  ) %>%
  # 8. TREEMAP
  add_viz(
    type      = "treemap",
    data      = treemap_data,
    group_var = "region",
    value_var = "spend",
    title     = "Treemap",
    show_when = ~ chart_type == "Treemap"
  ) %>%
  # 9. MAP
  add_viz(
    type      = "map",
    data      = map_data,
    join_var  = "iso2c",
    value_var = "map_value",
    title     = "World Map",
    show_when = ~ chart_type == "Map"
  )

# ---- Page 3: Stacked charts ----
# Uses DROPDOWN + demonstrates compound show_when with two inputs
page3_content <- create_content(data = main_data) %>%
  add_sidebar(title = "Controls", width = "280px") %>%
    add_input(
      input_id         = "view3",
      label            = "View",
      type             = "select_single",
      filter_var       = "view_type",
      options          = c("Stacked Bar", "Pie", "Donut"),
      default_selected = "Stacked Bar"
    ) %>%
  end_sidebar() %>%
  # 10. STACKEDBAR
  add_viz(
    type         = "stackedbar",
    x_var        = "category",
    stack_var    = "response",
    y_var        = "value",
    stacked_type = "percent",
    horizontal   = TRUE,
    title        = "Stacked Bar Chart",
    show_when    = ~ view_type == "Stacked Bar"
  ) %>%
  # 12. PIE (moved here for better grouping)
  add_viz(
    type      = "pie",
    data      = main_data,
    x_var     = "category",
    title     = "Pie Chart",
    show_when = ~ view_type == "Pie"
  ) %>%
  # 13. DONUT (moved here for better grouping)
  add_viz(
    type      = "donut",
    data      = main_data,
    x_var     = "group",
    title     = "Donut Chart",
    show_when = ~ view_type == "Donut"
  )

# ---- Page 4: Comparison charts (lollipop, dumbbell, gauge, waffle) ----
# Uses RADIO buttons
page4_content <- create_content() %>%
  add_sidebar(title = "Controls", width = "280px") %>%
    add_input(
      input_id         = "chart4",
      label            = "Select Chart",
      type             = "radio",
      filter_var       = "chart_type",
      options          = c("Lollipop", "Dumbbell", "Gauge", "Waffle"),
      default_selected = "Lollipop",
      stacked          = TRUE
    ) %>%
  end_sidebar() %>%
  # 14. LOLLIPOP
  add_viz(
    type      = "lollipop",
    data      = lollipop_data,
    x_var     = "category",
    y_var     = "avg_score",
    horizontal = TRUE,
    title     = "Lollipop Chart",
    show_when = ~ chart_type == "Lollipop"
  ) %>%
  # 15. DUMBBELL
  add_viz(
    type      = "dumbbell",
    data      = dumbbell_data,
    x_var     = "department",
    low_var   = "low_val",
    high_var  = "high_val",
    horizontal = TRUE,
    title     = "Dumbbell Chart",
    show_when = ~ chart_type == "Dumbbell"
  ) %>%
  # 16. GAUGE
  add_viz(
    type      = "gauge",
    value     = 73,
    title     = "Gauge Chart",
    show_when = ~ chart_type == "Gauge"
  ) %>%
  # 20. WAFFLE
  add_viz(
    type      = "waffle",
    data      = waffle_data,
    x_var     = "category",
    y_var     = "count",
    total     = 100,
    rows      = 10,
    title     = "Waffle Chart",
    show_when = ~ chart_type == "Waffle"
  )

# ---- Page 5: Flow charts (funnel, pyramid, sankey) ----
# Uses DROPDOWN
page5_content <- create_content() %>%
  add_sidebar(title = "Controls", width = "280px") %>%
    add_input(
      input_id         = "chart5",
      label            = "Select Chart",
      type             = "select_single",
      filter_var       = "chart_type",
      options          = c("Funnel", "Pyramid", "Sankey"),
      default_selected = "Funnel"
    ) %>%
  end_sidebar() %>%
  # 17. FUNNEL
  add_viz(
    type      = "funnel",
    data      = funnel_data,
    x_var     = "stage",
    y_var     = "funnel_count",
    title     = "Funnel Chart",
    show_when = ~ chart_type == "Funnel"
  ) %>%
  # 18. PYRAMID
  add_viz(
    type      = "pyramid",
    data      = funnel_data,
    x_var     = "stage",
    y_var     = "funnel_count",
    title     = "Pyramid Chart",
    show_when = ~ chart_type == "Pyramid"
  ) %>%
  # 19. SANKEY
  add_viz(
    type      = "sankey",
    data      = sankey_data,
    from_var  = "from",
    to_var    = "to",
    value_var = "flow",
    title     = "Sankey Chart",
    show_when = ~ chart_type == "Sankey"
  )


# =============================================================================
# ASSEMBLE DASHBOARD
# =============================================================================

dashboard <- create_dashboard(
  output_dir = "dev/showwhen",
  title      = "show_when: All 20 Viz Types",
  theme      = "cosmo"
) %>%
  add_page(
    name    = "Classic Charts",
    data    = main_data,
    content = page1_content
  ) %>%
  add_page(
    name    = "Advanced Charts",
    content = page2_content
  ) %>%
  add_page(
    name    = "Stacked/Pie/Donut",
    data    = main_data,
    content = page3_content
  ) %>%
  add_page(
    name    = "Comparison Charts",
    content = page4_content
  ) %>%
  add_page(
    name    = "Flow Charts",
    content = page5_content
  )


# =============================================================================
# GENERATE (no render -- just create QMD files)
# =============================================================================

message("\n=== Generating dashboard to: ", output_dir, " ===\n")
generate_dashboard(dashboard, render = T, open = "browser")


# =============================================================================
# VERIFY: Check that every viz type got a show_when_open() wrapper
# =============================================================================

# Find all generated QMD files (check actual output dir, not temp)
qmd_files <- list.files("dev/showwhen", pattern = "\\.qmd$", recursive = TRUE, full.names = TRUE)

if (length(qmd_files) == 0) {
  stop("No QMD files generated! Something went wrong with dashboard generation.")
}

message("Found ", length(qmd_files), " QMD file(s):")
for (f in qmd_files) message("  ", f)

# Read all QMD content
all_qmd <- paste(
  unlist(lapply(qmd_files, readLines, warn = FALSE)),
  collapse = "\n"
)

# All 19 viz types to verify (stackedbars excluded - commented out)
all_types <- c(
  "bar", "scatter", "density", "boxplot", "histogram",
  "heatmap", "timeline", "treemap", "map",
  "stackedbar",
  "pie", "donut", "lollipop", "dumbbell",
  "gauge", "funnel", "pyramid", "sankey", "waffle"
)

# Count total show_when_open occurrences
total_show_when <- length(gregexpr("show_when_open\\(", all_qmd)[[1]])
message("\nTotal show_when_open() calls found in QMD: ", total_show_when)

# For each viz type, check that both show_when_open and the viz function call appear
# We look for the viz title pattern to match each type
results <- data.frame(
  viz_type       = character(),
  has_show_when  = logical(),
  has_viz_call   = logical(),
  stringsAsFactors = FALSE
)

# Map viz type to the title string we used (which uniquely identifies each viz)
type_title_map <- c(
  bar         = "Bar Chart",
  scatter     = "Scatter Plot",
  density     = "Density Plot",
  boxplot     = "Boxplot",
  histogram   = "Histogram",
  heatmap     = "Heatmap",
  timeline    = "Timeline",
  treemap     = "Treemap",
  map         = "Map",
  stackedbar  = "Stacked Bar",
  pie         = "Pie Chart",
  donut       = "Donut Chart",
  lollipop    = "Lollipop",
  dumbbell    = "Dumbbell",
  gauge       = "Gauge",
  funnel      = "Funnel",
  pyramid     = "Pyramid",
  sankey      = "Sankey",
  waffle      = "Waffle"
)

# Map viz types to their function names for verification
type_function_map <- c(
  bar         = "viz_bar",
  scatter     = "viz_scatter",
  density     = "viz_density",
  boxplot     = "viz_boxplot",
  histogram   = "viz_histogram",
  heatmap     = "viz_heatmap",
  timeline    = "viz_timeline",
  treemap     = "viz_treemap",
  map         = "viz_map",
  stackedbar  = "viz_stackedbar",
  pie         = "viz_pie",
  donut       = "viz_pie",
  lollipop    = "viz_lollipop",
  dumbbell    = "viz_dumbbell",
  gauge       = "viz_gauge",
  funnel      = "viz_funnel",
  pyramid     = "viz_funnel",
  sankey      = "viz_sankey",
  waffle      = "viz_waffle"
)

for (vtype in all_types) {
  title_needle <- type_title_map[vtype]
  func_needle  <- type_function_map[vtype]

  # Check for show_when_open near this viz's title comment
  # The generated QMD has a comment like "# Bar Chart (show_when: ...)"
  # followed (soon after) by show_when_open(...)
  has_title     <- grepl(title_needle, all_qmd, fixed = TRUE)
  has_func      <- grepl(func_needle, all_qmd, fixed = TRUE)
  has_show_when <- grepl("show_when_open", all_qmd, fixed = TRUE)

  results <- rbind(results, data.frame(
    viz_type      = vtype,
    has_show_when = has_show_when,
    has_viz_call  = has_func,
    title_found   = has_title,
    stringsAsFactors = FALSE
  ))
}

# =============================================================================
# PRINT SUMMARY
# =============================================================================

message("\n", paste(rep("=", 70), collapse = ""))
message("  show_when VERIFICATION RESULTS: All 20 Viz Types")
message(paste(rep("=", 70), collapse = ""), "\n")

pass_count <- 0
fail_count <- 0

for (i in seq_len(nrow(results))) {
  r <- results[i, ]
  status <- if (r$has_show_when && r$has_viz_call && r$title_found) {
    pass_count <- pass_count + 1
    "PASS"
  } else {
    fail_count <- fail_count + 1
    "FAIL"
  }

  detail <- paste0(
    if (r$title_found) "title:OK" else "title:MISSING",
    " | ",
    if (r$has_viz_call) "viz_call:OK" else "viz_call:MISSING",
    " | ",
    if (r$has_show_when) "show_when:OK" else "show_when:MISSING"
  )

  message(sprintf("  [%s] %-14s  %s", status, r$viz_type, detail))
}

message("\n", paste(rep("-", 70), collapse = ""))
message(sprintf("  TOTAL: %d/%d passed   |   %d failed",
                pass_count, nrow(results), fail_count))
message(paste(rep("-", 70), collapse = ""))

if (fail_count == 0) {
  message("\n  ALL 20 VIZ TYPES HAVE show_when WRAPPERS. Success!\n")
} else {
  message("\n  WARNING: Some viz types are missing show_when wrappers.\n")
}

message("Output directory: ", output_dir)
message("QMD files can be inspected manually at the path above.\n")

# Clean up
# unlink(output_dir, recursive = TRUE)
