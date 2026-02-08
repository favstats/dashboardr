# =============================================================================
# dashboardr Feature Showcase: Multi-Backend + Inputs + show_when + Filterable Blocks
# =============================================================================
# Run with:
#   source("dev/demo_chart_backends.R")
#
# Generates a full demo dashboard at ./here (outside package root relocation may apply).

library(tidyverse)

devtools::load_all()

set.seed(42)

# -----------------------------------------------------------------------------
# Synthetic data
# -----------------------------------------------------------------------------

n <- 700
survey_data <- tibble(
  id = seq_len(n),
  year = sample(2018:2025, n, replace = TRUE),
  region = sample(c("Northeast", "South", "Midwest", "West"), n, replace = TRUE),
  gender = sample(c("Female", "Male"), n, replace = TRUE),
  education = sample(c("High School", "Some College", "Bachelor's", "Graduate"), n, replace = TRUE),
  happiness = sample(c("Very Happy", "Pretty Happy", "Not Too Happy"), n, replace = TRUE),
  age = pmax(18, pmin(85, round(rnorm(n, 45, 14)))),
  income = pmax(15000, round(rnorm(n, 65000, 22000))),
  score = pmax(20, pmin(100, round(rnorm(n, 70, 12)))),
  weight = runif(n, 0.5, 2.2)
)

sankey_agg <- survey_data %>%
  count(from = education, to = happiness, name = "value")

funnel_data <- tibble(
  stage = c("Visitors", "Signups", "Trial", "Paid", "Retained"),
  count = c(12000, 5300, 2200, 950, 620)
)

treemap_data <- survey_data %>%
  count(region, wt = income, name = "spend")

heatmap_data <- survey_data %>%
  count(region, education, name = "value")

# -----------------------------------------------------------------------------
# Inputs (sidebar + top row)
# -----------------------------------------------------------------------------

main_sidebar <-
  create_content() %>%
  add_sidebar(position = "left", width = "280px", title = "Interactive Filters") %>%
  add_input(
    input_id = "region_filter",
    label = "Region",
    type = "checkbox",
    filter_var = "region",
    options = sort(unique(survey_data$region)),
    default_selected = sort(unique(survey_data$region))
  ) %>%
  add_input(
    input_id = "gender_filter",
    label = "Gender",
    type = "checkbox",
    filter_var = "gender",
    options = sort(unique(survey_data$gender)),
    default_selected = sort(unique(survey_data$gender))
  ) %>%
  add_input(
    input_id = "year_filter",
    label = "Year",
    type = "slider",
    filter_var = "year",
    min = min(survey_data$year),
    max = max(survey_data$year),
    value = min(survey_data$year),
    step = 1
  ) %>%
  end_sidebar()

# -----------------------------------------------------------------------------
# Page 1: Backends overview + show_when
# -----------------------------------------------------------------------------

page_backends <- create_page(name = "Backends & show_when") %>%
  add_content(main_sidebar) %>%
  add_text("## Backend Showcase") %>%
  add_text(
    "This dashboard uses the same `add_viz()` grammar with multiple backends.",
    show_when = ~ year >= 2021
  ) %>%
  add_viz(
    type = "bar",
    data = survey_data,
    x_var = "region",
    title = "Bar (inherits dashboard backend)",
    tabgroup = "Bars"
  ) %>%
  add_viz(
    type = "bar",
    data = survey_data,
    x_var = "education",
    title = "Bar override: highcharter",
    backend = "highcharter",
    tabgroup = "Bars"
  ) %>%
  add_viz(
    type = "timeline",
    data = survey_data,
    time_var = "year",
    y_var = "score",
    group_var = "gender",
    title = "Timeline (cross-tab capable)",
    tabgroup = "Trends"
  ) %>%
  add_viz(
    type = "stackedbar",
    data = survey_data,
    x_var = "region",
    stack_var = "happiness",
    stacked_type = "percent",
    title = "Stacked Bar (cross-tab capable)",
    tabgroup = "Trends"
  )

# -----------------------------------------------------------------------------
# Page 2: Filterable tables + widgets
# -----------------------------------------------------------------------------

dt_df <- survey_data %>%
  select(year, region, gender, education, happiness, age, income, score) %>%
  arrange(desc(year)) %>%
  slice_head(n = 120)

plotly_widget <- plotly::plot_ly(
  data = survey_data,
  x = ~age,
  y = ~income,
  color = ~region,
  type = "scatter",
  mode = "markers"
) %>%
  plotly::layout(title = "Custom Plotly Widget")

page_content <- create_page(name = "Filterable Content") %>%
  add_content(main_sidebar) %>%
  add_text("## Table + Widget Integration") %>%
  add_table(
    table_object = dt_df %>% count(region, gender, name = "n"),
    caption = "HTML table filtered by sidebar inputs",
    filter_vars = c("region", "gender")
  ) %>%
  add_DT(
    table_data = dt_df,
    options = list(pageLength = 8, scrollX = TRUE),
    filter_vars = c("region", "gender", "year")
  ) %>%
  add_reactable(
    reactable_object = dt_df,
    filter_vars = c("region", "gender", "year")
  ) %>%
  add_plotly(
    plot = plotly_widget,
    title = "Embedded plotly via add_plotly()",
    filter_vars = c("region")
  )

# -----------------------------------------------------------------------------
# Page 3: Remaining chart families
# -----------------------------------------------------------------------------

page_more <- create_page(name = "More Charts") %>%
  add_content(main_sidebar) %>%
  add_input_row(style = "inline", align = "left") %>%
  add_input(
    input_id = "education_top",
    label = "Education (Top input row)",
    type = "select_multiple",
    filter_var = "education",
    options = sort(unique(survey_data$education)),
    default_selected = sort(unique(survey_data$education))
  ) %>%
  end_input_row() %>%
  add_viz(type = "scatter", data = survey_data, x_var = "age", y_var = "income", color_var = "gender", title = "Scatter") %>%
  add_viz(type = "histogram", data = survey_data, x_var = "education", title = "Histogram", backend = "plotly") %>%
  add_viz(type = "pie", data = survey_data, x_var = "happiness", title = "Pie", backend = "echarts4r") %>%
  add_viz(type = "heatmap", data = heatmap_data, x_var = "region", y_var = "education", value_var = "value", title = "Heatmap") %>%
  add_viz(type = "boxplot", data = survey_data, x_var = "region", y_var = "income", title = "Boxplot", backend = "plotly") %>%
  add_viz(type = "density", data = survey_data, x_var = "income", group_var = "gender", title = "Density") %>%
  add_viz(type = "treemap", data = treemap_data, group_var = "region", value_var = "spend", title = "Treemap", backend = "echarts4r") %>%
  add_viz(type = "sankey", data = sankey_agg, from_var = "from", to_var = "to", value_var = "value", title = "Sankey") %>%
  add_viz(type = "funnel", data = funnel_data, x_var = "stage", y_var = "count", title = "Funnel", backend = "plotly") %>%
  add_viz(type = "lollipop", data = survey_data, x_var = "region", y_var = "score", title = "Lollipop") %>%
  add_viz(
    type = "dumbbell",
    data = survey_data %>%
      mutate(period = if_else(year <= 2021, "Before", "After")) %>%
      group_by(region, period) %>%
      summarise(score = mean(score, na.rm = TRUE), .groups = "drop") %>%
      tidyr::pivot_wider(names_from = period, values_from = score),
    x_var = "region",
    low_var = "Before",
    high_var = "After",
    low_label = "Before",
    high_label = "After",
    title = "Dumbbell"
  )

# -----------------------------------------------------------------------------
# Page 4: Dataset reuse (page-level + viz-level same data)
# -----------------------------------------------------------------------------

page_dataset_reuse <- create_page(
  name = "Dataset Reuse",
  data = survey_data
) %>%
  add_text("## Dataset Interning / Reuse") %>%
  add_text("This page intentionally mixes page-level and viz-level `data` inputs.") %>%
  add_viz(
    type = "scatter",
    x_var = "age",
    y_var = "score",
    title = "Uses page-level data"
  ) %>%
  add_viz(
    type = "scatter",
    data = survey_data,
    x_var = "age",
    y_var = "income",
    title = "Same data passed at viz-level (should be deduped)"
  )

# =============================================================================
# Dashboard 1: ECharts default (original showcase)
# =============================================================================

output_dir <- "here"

proj <- create_dashboard(
  title = "dashboardr Feature Showcase",
  output_dir = output_dir,
  backend = "echarts",
  chart_export = TRUE
) |>
  add_pages(page_backends, page_content, page_more, page_dataset_reuse)

# Generate + render
res <- generate_dashboard(proj, render = TRUE, open = "browser")
cat("\nGenerated showcase dashboard at:", normalizePath(res$output_dir, mustWork = FALSE), "\n")

# =============================================================================
# Dashboard 2: Plotly-default with sidebar inputs
# =============================================================================

plotly_sidebar <-
  create_content() %>%
  add_sidebar(position = "left", width = "260px", title = "Plotly Dashboard Filters") %>%
  add_input(
    input_id = "pl_region",
    label = "Region",
    type = "checkbox",
    filter_var = "region",
    options = sort(unique(survey_data$region)),
    default_selected = sort(unique(survey_data$region))
  ) %>%
  add_input(
    input_id = "pl_gender",
    label = "Gender",
    type = "radio",
    filter_var = "gender",
    options = c("All", sort(unique(survey_data$gender))),
    default_selected = "All"
  ) %>%
  add_input(
    input_id = "pl_year",
    label = "Year",
    type = "slider",
    filter_var = "year",
    min = min(survey_data$year),
    max = max(survey_data$year),
    value = min(survey_data$year),
    step = 1
  ) %>%
  end_sidebar()

page_plotly_charts <- create_page(name = "Charts (Plotly)") %>%
  add_content(plotly_sidebar) %>%
  add_viz(type = "bar", data = survey_data, x_var = "region", title = "Bar – plotly",
          tabgroup = "Basics") %>%
  add_viz(type = "scatter", data = survey_data, x_var = "age", y_var = "income",
          color_var = "gender", title = "Scatter – plotly", tabgroup = "Basics") %>%
  add_viz(type = "histogram", data = survey_data, x_var = "score",
          title = "Histogram – plotly") %>%
  add_viz(type = "boxplot", data = survey_data, x_var = "education", y_var = "income",
          title = "Boxplot – plotly") %>%
  add_viz(type = "density", data = survey_data, x_var = "income", group_var = "gender",
          title = "Density – plotly") %>%
  add_viz(type = "funnel", data = funnel_data, x_var = "stage", y_var = "count",
          title = "Funnel – plotly") %>%
  add_viz(type = "pie", data = survey_data, x_var = "happiness",
          title = "Pie – plotly") %>%
  add_viz(type = "heatmap", data = heatmap_data, x_var = "region", y_var = "education",
          value_var = "value", title = "Heatmap – plotly") %>%
  add_viz(type = "sankey", data = sankey_agg, from_var = "from", to_var = "to",
          value_var = "value", title = "Sankey – plotly")

page_plotly_tables <- create_page(name = "Tables (Plotly)") %>%
  add_content(plotly_sidebar) %>%
  add_DT(
    table_data = dt_df,
    options = list(pageLength = 10, scrollX = TRUE),
    filter_vars = c("region", "gender", "year")
  ) %>%
  add_reactable(
    reactable_object = dt_df,
    filter_vars = c("region", "gender", "year")
  )

proj_plotly <- create_dashboard(
  title = "Plotly Backend Showcase",
  output_dir = "here_plotly",
  backend = "plotly",
  chart_export = TRUE
) |>
  add_pages(page_plotly_charts, page_plotly_tables)

res_plotly <- generate_dashboard(proj_plotly, render = TRUE, open = "browser")
cat("\nGenerated Plotly dashboard at:", normalizePath(res_plotly$output_dir, mustWork = FALSE), "\n")

# =============================================================================
# Dashboard 3: Highcharter-default with sidebar inputs
# =============================================================================

hc_sidebar <-
  create_content() %>%
  add_sidebar(position = "left", width = "260px", title = "Highcharter Filters") %>%
  add_input(
    input_id = "hc_region",
    label = "Region",
    type = "select_multiple",
    filter_var = "region",
    options = sort(unique(survey_data$region)),
    default_selected = sort(unique(survey_data$region))
  ) %>%
  add_input(
    input_id = "hc_education",
    label = "Education",
    type = "checkbox",
    filter_var = "education",
    options = sort(unique(survey_data$education)),
    default_selected = sort(unique(survey_data$education))
  ) %>%
  add_input(
    input_id = "hc_year",
    label = "Year",
    type = "slider",
    filter_var = "year",
    min = min(survey_data$year),
    max = max(survey_data$year),
    value = min(survey_data$year),
    step = 1
  ) %>%
  end_sidebar()

page_hc_charts <- create_page(name = "Charts (HC)") %>%
  add_content(hc_sidebar) %>%
  add_viz(type = "timeline", data = survey_data, time_var = "year", y_var = "score",
          group_var = "gender", title = "Timeline", tabgroup = "Trends") %>%
  add_viz(type = "stackedbar", data = survey_data, x_var = "region",
          stack_var = "happiness", stacked_type = "percent",
          title = "Stacked Bar %", tabgroup = "Trends") %>%
  add_viz(type = "bar", data = survey_data, x_var = "region",
          title = "Bar – highcharter") %>%
  add_viz(type = "pie", data = survey_data, x_var = "happiness",
          title = "Pie – highcharter") %>%
  add_viz(type = "heatmap", data = heatmap_data, x_var = "region", y_var = "education",
          value_var = "value", title = "Heatmap – highcharter") %>%
  add_viz(type = "lollipop", data = survey_data, x_var = "region", y_var = "score",
          title = "Lollipop – highcharter") %>%
  add_viz(
    type = "dumbbell",
    data = survey_data %>%
      mutate(period = if_else(year <= 2021, "Before", "After")) %>%
      group_by(region, period) %>%
      summarise(score = mean(score, na.rm = TRUE), .groups = "drop") %>%
      tidyr::pivot_wider(names_from = period, values_from = score),
    x_var = "region",
    low_var = "Before", high_var = "After",
    low_label = "Before", high_label = "After",
    title = "Dumbbell – highcharter"
  ) %>%
  add_viz(type = "scatter", data = survey_data, x_var = "age", y_var = "income",
          color_var = "region", title = "Scatter – highcharter") %>%
  add_viz(type = "density", data = survey_data, x_var = "income", group_var = "gender",
          title = "Density – highcharter") %>%
  add_viz(type = "sankey", data = sankey_agg, from_var = "from", to_var = "to",
          value_var = "value", title = "Sankey – highcharter")

proj_hc <- create_dashboard(
  title = "Highcharter Backend Showcase",
  output_dir = "here_hc",
  backend = "highcharter",
  chart_export = TRUE
) |>
  add_pages(page_hc_charts)

res_hc <- generate_dashboard(proj_hc, render = TRUE, open = "browser")
cat("\nGenerated Highcharter dashboard at:", normalizePath(res_hc$output_dir, mustWork = FALSE), "\n")

cat("\n=== All 3 dashboards generated ===\n")
