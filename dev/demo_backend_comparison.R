# =============================================================================
# dashboardr Demo: Backend Comparison (echarts4r, plotly, ggiraph)
# =============================================================================
# Exercises all non-highcharter backends across key viz types:
#   bar, histogram, density, timeline, stackedbar, scatter, boxplot,
#   heatmap, pie, treemap
#
# Tests: group_var, stacking, y_label, color_palette, horizontal,
#        sort_by_value, bar_type, error_bars, chart_type, etc.
#
# Run with:
#   source("dev/demo_backend_comparison.R")

library(tidyverse)
devtools::load_all()

set.seed(42)

# ---------------------------------------------------------------------------
# Deterministic data
# ---------------------------------------------------------------------------

regions    <- c("Midwest", "Northeast", "South", "West")
education  <- c("High School", "Some College", "Bachelor's", "Graduate")
happiness  <- c("Very Happy", "Pretty Happy", "Not Too Happy")
years      <- 2019:2025

n <- 2000

survey <- tibble(
  year      = sample(years, n, replace = TRUE),
  region    = factor(sample(regions, n, replace = TRUE), levels = regions),
  education = factor(sample(education, n, replace = TRUE), levels = education),
  happiness = factor(sample(happiness, n, replace = TRUE), levels = happiness),
  age       = pmax(18, pmin(85, round(rnorm(n, 44, 13)))),
  income    = pmax(15000, round(rnorm(n, 65000, 20000))),
  score     = round(runif(n, 1, 10), 1)
)

# Likert questions for stackedbars
survey <- survey %>%
  mutate(
    q_economy   = factor(sample(c("Strongly Disagree", "Disagree", "Neutral", "Agree", "Strongly Agree"), n, replace = TRUE,
                                prob = c(.08, .15, .30, .30, .17)),
                         levels = c("Strongly Disagree", "Disagree", "Neutral", "Agree", "Strongly Agree")),
    q_trust     = factor(sample(c("Strongly Disagree", "Disagree", "Neutral", "Agree", "Strongly Agree"), n, replace = TRUE,
                                prob = c(.12, .22, .28, .25, .13)),
                         levels = c("Strongly Disagree", "Disagree", "Neutral", "Agree", "Strongly Agree")),
    q_wellbeing = factor(sample(c("Strongly Disagree", "Disagree", "Neutral", "Agree", "Strongly Agree"), n, replace = TRUE,
                                prob = c(.05, .10, .25, .35, .25)),
                         levels = c("Strongly Disagree", "Disagree", "Neutral", "Agree", "Strongly Agree"))
  )

# Pre-aggregated heatmap data
heatmap_data <- survey %>%
  group_by(region, education) %>%
  summarise(mean_income = round(mean(income)), .groups = "drop")

# Treemap data
treemap_data <- survey %>%
  group_by(region, education) %>%
  summarise(total_income = sum(income), avg_score = mean(score), .groups = "drop")

# Palettes
region_pal  <- c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3")
edu_pal     <- c("#66C2A5", "#FC8D62", "#8DA0CB", "#E78AC3")
happy_pal   <- c("#1B9E77", "#D95F02", "#7570B3")
likert_pal  <- c("#D7191C", "#FDAE61", "#FFFFBF", "#A6D96A", "#1A9641")

# ---------------------------------------------------------------------------
# Helper: prepare output directory
# ---------------------------------------------------------------------------
prepare_output_dir <- function(dir) {
  if (dir.exists(dir)) unlink(dir, recursive = TRUE)
  invisible(NULL)
}

# ---------------------------------------------------------------------------
# Helper: show R code on the page
# ---------------------------------------------------------------------------
page_css <- ""

# Format an add_viz call as a Quarto fenced code block (```r)
code_block <- function(...) {
  lines <- c(...)
  txt <- paste(lines, collapse = "\n")
  paste0("\n```r\n", txt, "\n```\n")
}

# ==========================================================================
# PAGE BUILDERS — one page per viz type, exercising typical parameters
# ==========================================================================

# --- Page 1: Bar charts
page_bars <- function(data) {
  create_page(name = "Bars", data = data) %>%
    add_html(page_css) %>%

    add_html(code_block('add_viz(type = "bar", x_var = "region",',
      '  bar_type = "count", color_palette = region_pal,',
      '  y_label = "Number of Respondents")')) %>%
    add_viz(type = "bar", x_var = "region", bar_type = "count",
      color_palette = region_pal, title = "Count by Region",
      y_label = "Number of Respondents") %>%

    add_html(code_block('add_viz(type = "bar", x_var = "region",',
      '  bar_type = "percent", color_palette = region_pal,',
      '  y_label = "Percentage (%)")')) %>%
    add_viz(type = "bar", x_var = "region", bar_type = "percent",
      color_palette = region_pal, title = "Percent by Region",
      y_label = "Percentage (%)") %>%

    add_html(code_block('add_viz(type = "bar", x_var = "education",',
      '  group_var = "region", value_var = "income",',
      '  bar_type = "mean", color_palette = region_pal,',
      '  error_bars = "se", y_label = "Mean Income ($)")')) %>%
    add_viz(type = "bar", x_var = "education", group_var = "region",
      value_var = "income", bar_type = "mean", color_palette = region_pal,
      title = "Mean Income by Education & Region",
      y_label = "Mean Income ($)", error_bars = "se") %>%

    add_html(code_block('add_viz(type = "bar", x_var = "education",',
      '  bar_type = "count", horizontal = TRUE,',
      '  sort_by_value = TRUE, color_palette = edu_pal)')) %>%
    add_viz(type = "bar", x_var = "education", bar_type = "count",
      horizontal = TRUE, sort_by_value = TRUE, color_palette = edu_pal,
      title = "Education (Horizontal, Sorted)", y_label = "Count") %>%

    add_html(code_block('# Data labels enabled',
      'add_viz(type = "bar", x_var = "region",',
      '  bar_type = "count", color_palette = region_pal,',
      '  data_labels_enabled = TRUE)')) %>%
    add_viz(type = "bar", x_var = "region", bar_type = "count",
      color_palette = region_pal, title = "Bar with Data Labels",
      data_labels_enabled = TRUE) %>%

    add_html(code_block('# Custom tooltip with prefix/suffix',
      'add_viz(type = "bar", x_var = "region",',
      '  bar_type = "count", color_palette = region_pal,',
      '  tooltip_prefix = "N = ", tooltip_suffix = " respondents")')) %>%
    add_viz(type = "bar", x_var = "region", bar_type = "count",
      color_palette = region_pal, title = "Bar with Custom Tooltip (hover me!)",
      tooltip_prefix = "N = ", tooltip_suffix = " respondents") %>%

    add_html(code_block('# legend_position: "top", "bottom", "left", "right", "none"',
      'add_viz(type = "bar", x_var = "education",',
      '  group_var = "region", bar_type = "count",',
      '  color_palette = region_pal,',
      '  legend_position = "bottom")')) %>%
    add_viz(type = "bar", x_var = "education", group_var = "region",
      bar_type = "count", color_palette = region_pal,
      title = "Grouped Bar with legend_position = 'bottom'",
      legend_position = "bottom")
}

# --- Page 2: Histograms
page_histograms <- function(data) {
  create_page(name = "Histograms", data = data) %>%
    add_html(page_css) %>%

    add_html(code_block('add_viz(type = "histogram", x_var = "age",',
      '  histogram_type = "count", color_palette = "#377EB8",',
      '  x_label = "Age", y_label = "Count")')) %>%
    add_viz(type = "histogram", x_var = "age", histogram_type = "count",
      color_palette = "#377EB8", title = "Age Distribution (Count)",
      x_label = "Age", y_label = "Count") %>%

    add_html(code_block('add_viz(type = "histogram", x_var = "age",',
      '  histogram_type = "percent", color_palette = "#E41A1C",',
      '  y_label = "Percentage (%)")')) %>%
    add_viz(type = "histogram", x_var = "age", histogram_type = "percent",
      color_palette = "#E41A1C", title = "Age Distribution (Percent)",
      x_label = "Age", y_label = "Percentage (%)") %>%

    add_html(code_block('add_viz(type = "histogram", x_var = "score",',
      '  bin_breaks = c(0, 2.5, 5, 7.5, 10),',
      '  bin_labels = c("Low", "Med-Low", "Med-High", "High"),',
      '  color_palette = c("#66C2A5", "#FC8D62", "#8DA0CB", "#E78AC3"))')) %>%
    add_viz(type = "histogram", x_var = "score",
      bin_breaks = c(0, 2.5, 5, 7.5, 10),
      bin_labels = c("Low (0-2.5)", "Med-Low (2.5-5)", "Med-High (5-7.5)", "High (7.5-10)"),
      color_palette = c("#66C2A5", "#FC8D62", "#8DA0CB", "#E78AC3"),
      title = "Score Bins", y_label = "Count") %>%

    add_html(code_block('add_viz(type = "histogram", x_var = "happiness",',
      '  color_palette = happy_pal,',
      '  tooltip = tooltip(prefix = "Count: "))')) %>%
    add_viz(type = "histogram", x_var = "happiness",
      color_palette = happy_pal, title = "Happiness (with tooltip() object)",
      y_label = "Respondents", tooltip = tooltip(prefix = "Count: "))
}

# --- Page 3: Density plots
page_density <- function(data) {
  create_page(name = "Density", data = data) %>%
    add_html(page_css) %>%

    add_html(code_block('add_viz(type = "density", x_var = "age",',
      '  color_palette = "#377EB8",',
      '  x_label = "Age", y_label = "Density")')) %>%
    add_viz(type = "density", x_var = "age", color_palette = "#377EB8",
      title = "Age Density", x_label = "Age", y_label = "Density") %>%

    add_html(code_block('add_viz(type = "density", x_var = "income",',
      '  group_var = "region", color_palette = region_pal,',
      '  fill_opacity = 0.25,',
      '  x_label = "Income ($)", y_label = "Density")')) %>%
    add_viz(type = "density", x_var = "income", group_var = "region",
      color_palette = region_pal, fill_opacity = 0.25,
      title = "Income Density by Region",
      x_label = "Income ($)", y_label = "Density") %>%

    add_html(code_block('add_viz(type = "density", x_var = "age",',
      '  group_var = "happiness", color_palette = happy_pal)')) %>%
    add_viz(type = "density", x_var = "age", group_var = "happiness",
      color_palette = happy_pal, title = "Age Density by Happiness",
      x_label = "Age", y_label = "Density")
}

# --- Page 4: Timeline
page_timeline <- function(data) {
  create_page(name = "Timeline", data = data) %>%
    add_html(page_css) %>%

    add_html(code_block('add_viz(type = "timeline", time_var = "year",',
      '  y_var = "happiness", agg = "percentage",',
      '  chart_type = "line", color_palette = happy_pal,',
      '  y_label = "Percentage (%)")')) %>%
    add_viz(type = "timeline", time_var = "year", y_var = "happiness",
      agg = "percentage", chart_type = "line", color_palette = happy_pal,
      title = "Happiness Trends (Percentage)", y_label = "Percentage (%)") %>%

    add_html(code_block('add_viz(type = "timeline", time_var = "year",',
      '  y_var = "happiness", agg = "percentage",',
      '  chart_type = "stacked_area", color_palette = happy_pal)')) %>%
    add_viz(type = "timeline", time_var = "year", y_var = "happiness",
      agg = "percentage", chart_type = "stacked_area", color_palette = happy_pal,
      title = "Happiness Stacked Area", y_label = "Percentage (%)") %>%

    add_html(code_block('add_viz(type = "timeline", time_var = "year",',
      '  y_var = "income", group_var = "region",',
      '  agg = "mean", chart_type = "line",',
      '  color_palette = region_pal, y_label = "Mean Income ($)")')) %>%
    add_viz(type = "timeline", time_var = "year", y_var = "income",
      group_var = "region", agg = "mean", chart_type = "line",
      color_palette = region_pal, title = "Mean Income by Region over Time",
      y_label = "Mean Income ($)") %>%

    add_html(code_block('add_viz(type = "timeline", time_var = "year",',
      '  y_var = "happiness", group_var = "region",',
      '  agg = "percentage",',
      '  y_filter = "Very Happy", y_filter_combine = TRUE,',
      '  y_filter_label = "% Very Happy",',
      '  color_palette = region_pal)')) %>%
    add_viz(type = "timeline", time_var = "year", y_var = "happiness",
      group_var = "region", agg = "percentage",
      y_filter = "Very Happy", y_filter_combine = TRUE,
      y_filter_label = "% Very Happy", color_palette = region_pal,
      title = "% Very Happy by Region", y_label = "Percentage (%)")
}

# --- Page 5: Stacked bars
page_stackedbar <- function(data) {
  create_page(name = "StackedBars", data = data) %>%
    add_html(page_css) %>%

    add_html(code_block('add_viz(type = "stackedbar",',
      '  x_var = "education", stack_var = "happiness",',
      '  stacked_type = "counts", color_palette = happy_pal,',
      '  y_label = "Count")')) %>%
    add_viz(type = "stackedbar", x_var = "education", stack_var = "happiness",
      stacked_type = "counts", color_palette = happy_pal,
      title = "Happiness by Education (Counts)", y_label = "Count") %>%

    add_html(code_block('add_viz(type = "stackedbar",',
      '  x_var = "education", stack_var = "happiness",',
      '  stacked_type = "percent", color_palette = happy_pal)')) %>%
    add_viz(type = "stackedbar", x_var = "education", stack_var = "happiness",
      stacked_type = "percent", color_palette = happy_pal,
      title = "Happiness by Education (Percent)", y_label = "Percentage (%)") %>%

    add_html(code_block('add_viz(type = "stackedbar",',
      '  x_var = "region", stack_var = "happiness",',
      '  stacked_type = "percent", horizontal = TRUE,',
      '  color_palette = happy_pal)')) %>%
    add_viz(type = "stackedbar", x_var = "region", stack_var = "happiness",
      stacked_type = "percent", horizontal = TRUE, color_palette = happy_pal,
      title = "Happiness by Region (Horizontal %)", y_label = "Percentage (%)") %>%

    add_html(code_block('# Stacked bar with data labels',
      'add_viz(type = "stackedbar",',
      '  x_var = "region", stack_var = "happiness",',
      '  stacked_type = "percent", color_palette = happy_pal,',
      '  data_labels_enabled = TRUE)')) %>%
    add_viz(type = "stackedbar", x_var = "region", stack_var = "happiness",
      stacked_type = "percent", color_palette = happy_pal,
      data_labels_enabled = TRUE,
      title = "With Data Labels (Percent)", y_label = "Percentage (%)") %>%

    add_html(code_block('add_viz(type = "stackedbar",',
      '  x_vars = c("q_economy", "q_trust", "q_wellbeing"),',
      '  x_var_labels = c("Economy", "Trust", "Wellbeing"),',
      '  response_levels = c("Strongly Disagree", ..., "Strongly Agree"),',
      '  stacked_type = "percent", color_palette = likert_pal)')) %>%
    add_viz(type = "stackedbar",
      x_vars = c("q_economy", "q_trust", "q_wellbeing"),
      x_var_labels = c("Economy", "Trust", "Wellbeing"),
      response_levels = c("Strongly Disagree", "Disagree", "Neutral", "Agree", "Strongly Agree"),
      stacked_type = "percent", color_palette = likert_pal,
      title = "Likert Comparison Across Questions", y_label = "Percentage (%)")
}

# --- Page 6: Scatter plots
page_scatter <- function(data) {
  create_page(name = "Scatter", data = data) %>%
    add_html(page_css) %>%

    add_html(code_block('add_viz(type = "scatter", x_var = "age",',
      '  y_var = "income", color_palette = "#377EB8",',
      '  x_label = "Age", y_label = "Income ($)")')) %>%
    add_viz(type = "scatter", x_var = "age", y_var = "income",
      color_palette = "#377EB8", title = "Age vs Income",
      x_label = "Age", y_label = "Income ($)") %>%

    add_html(code_block('add_viz(type = "scatter", x_var = "age",',
      '  y_var = "income", color_var = "region",',
      '  color_palette = region_pal, alpha = 0.5)')) %>%
    add_viz(type = "scatter", x_var = "age", y_var = "income",
      color_var = "region", color_palette = region_pal, alpha = 0.5,
      title = "Age vs Income by Region",
      x_label = "Age", y_label = "Income ($)") %>%

    add_html(code_block('add_viz(type = "scatter", x_var = "age",',
      '  y_var = "income", color_var = "education",',
      '  color_palette = edu_pal,',
      '  show_trend = TRUE, trend_method = "lm")')) %>%
    add_viz(type = "scatter", x_var = "age", y_var = "income",
      color_var = "education", color_palette = edu_pal,
      show_trend = TRUE, trend_method = "lm",
      title = "Income ~ Age with Trend (by Education)",
      x_label = "Age", y_label = "Income ($)")
}

# --- Page 7: Boxplots
page_boxplot <- function(data) {
  create_page(name = "Boxplot", data = data) %>%
    add_html(page_css) %>%

    add_html(code_block('add_viz(type = "boxplot", y_var = "income",',
      '  color_palette = "#377EB8", y_label = "Income ($)")')) %>%
    add_viz(type = "boxplot", y_var = "income", color_palette = "#377EB8",
      title = "Income Distribution", y_label = "Income ($)") %>%

    add_html(code_block('add_viz(type = "boxplot", y_var = "income",',
      '  x_var = "region", color_palette = region_pal)')) %>%
    add_viz(type = "boxplot", y_var = "income", x_var = "region",
      color_palette = region_pal, title = "Income by Region",
      y_label = "Income ($)") %>%

    add_html(code_block('add_viz(type = "boxplot", y_var = "age",',
      '  x_var = "education", horizontal = TRUE,',
      '  color_palette = edu_pal)')) %>%
    add_viz(type = "boxplot", y_var = "age", x_var = "education",
      horizontal = TRUE, color_palette = edu_pal,
      title = "Age by Education (Horizontal)", y_label = "Age") %>%

    add_html(code_block('# Custom tooltip with prefix/suffix',
      'add_viz(type = "boxplot", y_var = "income",',
      '  x_var = "region", color_palette = region_pal,',
      '  tooltip_prefix = "$", tooltip_suffix = " USD")')) %>%
    add_viz(type = "boxplot", y_var = "income", x_var = "region",
      color_palette = region_pal, title = "Boxplot with Tooltip Prefix/Suffix",
      y_label = "Income ($)", tooltip_prefix = "$", tooltip_suffix = " USD")
}

# --- Page 8: Heatmap
page_heatmap <- function(hm_data) {
  create_page(name = "Heatmap", data = hm_data) %>%
    add_html(page_css) %>%

    add_html(code_block('add_viz(type = "heatmap",',
      '  x_var = "region", y_var = "education",',
      '  value_var = "mean_income", pre_aggregated = TRUE,',
      '  color_palette = c("#FFFFFF", "#084594"),',
      '  label_decimals = 0,',
      '  x_label = "Region", y_label = "Education")')) %>%
    add_viz(type = "heatmap", x_var = "region", y_var = "education",
      value_var = "mean_income", pre_aggregated = TRUE,
      color_palette = c("#FFFFFF", "#084594"),
      title = "Mean Income Heatmap", x_label = "Region",
      y_label = "Education", label_decimals = 0)
}

# --- Page 9: Pie + Donut
page_pie <- function(data) {
  create_page(name = "Pie_Donut", data = data) %>%
    add_html(page_css) %>%

    add_html(code_block('add_viz(type = "pie", x_var = "region",',
      '  color_palette = region_pal)')) %>%
    add_viz(type = "pie", x_var = "region", color_palette = region_pal,
      title = "Respondents by Region") %>%

    add_html(code_block('add_viz(type = "pie", x_var = "education",',
      '  inner_size = "50%", color_palette = edu_pal)')) %>%
    add_viz(type = "pie", x_var = "education", inner_size = "50%",
      color_palette = edu_pal, title = "Education (Donut)") %>%

    add_html(code_block('add_viz(type = "pie", x_var = "happiness",',
      '  sort_by_value = TRUE, color_palette = happy_pal)')) %>%
    add_viz(type = "pie", x_var = "happiness", sort_by_value = TRUE,
      color_palette = happy_pal, title = "Happiness (Sorted)")
}

# --- Page 10: Treemap
page_treemap <- function(tm_data) {
  create_page(name = "Treemap", data = tm_data) %>%
    add_html(page_css) %>%

    add_html(code_block('add_viz(type = "treemap",',
      '  group_var = "region", subgroup_var = "education",',
      '  value_var = "total_income", pre_aggregated = TRUE,',
      '  color_palette = region_pal)')) %>%
    add_viz(type = "treemap", group_var = "region",
      subgroup_var = "education", value_var = "total_income",
      color_palette = region_pal, title = "Income by Region & Education",
      pre_aggregated = TRUE)
}

# --- Page 11: Sparkline Cards
page_sparkline <- function(data) {
  create_page(name = "Sparkline Cards", data = data) %>%
    add_html(page_css) %>%

    add_html(code_block('add_sparkline_card_row() %>%',
      '  add_sparkline_card(',
      '    x_var = "year", agg = "cumcount",',
      '    subtitle = "Total responses tracked"',
      '  ) %>%',
      '  add_sparkline_card(',
      '    x_var = "year", y_var = "income",',
      '    agg = "mean", value_prefix = "$",',
      '    subtitle = "Average income",',
      '    line_color = "#ffffff",',
      '    bg_color = "#1f8cff", text_color = "#ffffff"',
      '  ) %>%',
      'end_sparkline_card_row()')) %>%
    add_sparkline_card_row() %>%
      add_sparkline_card(
        x_var = "year", agg = "cumcount",
        subtitle = "Total responses tracked",
        connect_group = "sparkline-row1"
      ) %>%
      add_sparkline_card(
        x_var = "year", y_var = "income",
        agg = "mean", value_prefix = "$",
        subtitle = "Average income",
        line_color = "#ffffff",
        bg_color = "#1f8cff", text_color = "#ffffff",
        connect_group = "sparkline-row1"
      ) %>%
    end_sparkline_card_row() %>%

    add_html(code_block('add_sparkline_card_row() %>%',
      '  add_sparkline_card(',
      '    x_var = "year", y_var = "score",',
      '    agg = "mean", subtitle = "Mean Score Over Time"',
      '  ) %>%',
      '  add_sparkline_card(',
      '    x_var = "year", agg = "count",',
      '    subtitle = "Responses per Year",',
      '    line_color = "#E41A1C", bg_color = "#1a1a2e",',
      '    text_color = "#ffffff"',
      '  ) %>%',
      'end_sparkline_card_row()')) %>%
    add_sparkline_card_row() %>%
      add_sparkline_card(
        x_var = "year", y_var = "score",
        agg = "mean", subtitle = "Mean Score Over Time",
        connect_group = "sparkline-row2"
      ) %>%
      add_sparkline_card(
        x_var = "year", agg = "count",
        subtitle = "Responses per Year",
        line_color = "#E41A1C", bg_color = "#1a1a2e",
        text_color = "#ffffff",
        connect_group = "sparkline-row2"
      ) %>%
    end_sparkline_card_row()
}

# ==========================================================================
# Dashboard builder for a given backend
# ==========================================================================
build_backend_dashboard <- function(backend_name) {
  output_dir <- paste0("demo_backend_", backend_name)
  prepare_output_dir(output_dir)

  # treemap not supported on ggiraph
  pages <- list(
    page_bars(survey),
    page_histograms(survey),
    page_density(survey),
    page_timeline(survey),
    page_stackedbar(survey),
    page_scatter(survey),
    page_boxplot(survey),
    page_heatmap(heatmap_data),
    page_pie(survey),
    page_sparkline(survey)
  )

  # treemap only supported on echarts4r and plotly
  if (backend_name %in% c("echarts4r", "plotly")) {
    pages <- c(pages, list(page_treemap(treemap_data)))
  }

  proj <- create_dashboard(
    title       = paste0("Backend Comparison: ", backend_name),
    output_dir  = output_dir,
    backend     = backend_name,
    chart_export = TRUE
  )

  for (pg in pages) {
    proj <- proj %>% add_pages(pg)
  }

  proj
}

# ==========================================================================
# Generate all three backends
# ==========================================================================
backends <- c("echarts4r", "plotly", "ggiraph")

message("\n=== Generating dashboards for backends: ", paste(backends, collapse = ", "), " ===\n")

results <- list()

for (be in backends) {
  message(">>> Building: ", be)
  proj <- build_backend_dashboard(be)
  res  <- generate_dashboard(proj, render = TRUE, open = FALSE)
  results[[be]] <- res
  message("    Done: ", be, "\n")
}

# Open each in browser
for (be in backends) {
  output_dir <- paste0("demo_backend_", be)
  index_path <- file.path(output_dir, "docs", "index.html")
  if (file.exists(index_path)) {
    message("Opening ", be, " dashboard: ", index_path)
    browseURL(index_path)
    Sys.sleep(1)  # small delay so tabs open cleanly
  }
}

message("\n=== All dashboards generated and opened! ===")
