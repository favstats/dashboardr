# =============================================================================
# dashboardr Demo: Input Matrix Backends (core + mixed)
# =============================================================================
# Run with:
#   source("dev/demo_input_matrix_backends.R")

library(tidyverse)

devtools::load_all()

set.seed(20260209)

# -----------------------------------------------------------------------------
# Canonical deterministic data
# -----------------------------------------------------------------------------

years <- 2019:2025
regions <- c("Midwest", "Northeast", "South", "West")
education_levels <- c("High School", "Some College", "Bachelor's", "Graduate")
happiness_levels <- c("Very Happy", "Pretty Happy", "Not Too Happy")
channels <- c("Web", "Phone", "In Person")
segments <- c("Consumer", "Business", "Public")

questions_by_dimension <- list(
  Economy = c("Income", "Job Security", "Inflation"),
  Wellbeing = c("Life Satisfaction", "Stress", "Community"),
  Trust = c("Media Trust", "Gov Trust", "Business Trust")
)

question_table <- tibble::enframe(questions_by_dimension, name = "dimension", value = "question") %>%
  tidyr::unnest(question)

base_grid <- tidyr::crossing(
  year = years,
  region = regions,
  education = education_levels,
  happiness = happiness_levels,
  channel = channels,
  segment = segments,
  question_table
)

base_data <- base_grid %>%
  mutate(
    keep_prob = 0.45 +
      if_else(region == "Northeast", 0.10, 0) +
      if_else(region == "South", -0.05, 0) +
      if_else(education == "Graduate", 0.12, 0) +
      if_else(education == "High School", -0.08, 0) +
      if_else(happiness == "Very Happy", 0.14, 0) +
      if_else(happiness == "Not Too Happy", -0.10, 0) +
      if_else(channel == "Web", 0.06, 0) +
      if_else(segment == "Business", 0.05, 0) +
      if_else(dimension == "Economy", 0.05, 0) +
      ((year - min(years)) * 0.02),
    keep_prob = pmin(0.95, pmax(0.20, keep_prob)),
    keep_flag = runif(n()) <= keep_prob
  ) %>%
  filter(keep_flag) %>%
  select(-keep_prob, -keep_flag) %>%
  mutate(
    year = as.integer(year),
    region = factor(region, levels = regions),
    education = factor(education, levels = education_levels),
    happiness = factor(happiness, levels = happiness_levels),
    channel = factor(channel, levels = channels),
    segment = factor(segment, levels = segments),
    dimension = factor(dimension, levels = names(questions_by_dimension)),
    question = as.character(question)
  ) %>%
  mutate(
    age = pmax(18, pmin(85, round(rnorm(n(), mean = 44, sd = 13)))),
    base_income = case_when(
      region == "Northeast" ~ 76000,
      region == "West" ~ 72000,
      region == "Midwest" ~ 66000,
      TRUE ~ 61000
    ),
    education_bonus = case_when(
      education == "Graduate" ~ 24000,
      education == "Bachelor's" ~ 15000,
      education == "Some College" ~ 7000,
      TRUE ~ 0
    ),
    happiness_bonus = case_when(
      happiness == "Very Happy" ~ 6500,
      happiness == "Pretty Happy" ~ 2500,
      TRUE ~ -1500
    ),
    channel_shift = case_when(
      channel == "Web" ~ 1.5,
      channel == "Phone" ~ 0.5,
      TRUE ~ -0.25
    ),
    segment_shift = case_when(
      segment == "Business" ~ 4,
      segment == "Public" ~ -2,
      TRUE ~ 0
    ),
    score = pmax(
      35,
      pmin(
        98,
        round(
          55 +
            (year - min(years)) * 1.7 +
            segment_shift +
            channel_shift +
            rnorm(n(), 0, 6),
          1
        )
      )
    ),
    income = pmax(
      15000,
      round(base_income + education_bonus + happiness_bonus + (year - min(years)) * 1200 + rnorm(n(), 0, 9000), 0)
    ),
    count = pmax(1L, as.integer(round(rnorm(n(), 12, 4)))),
    view_mode = case_when(
      dimension == "Economy" ~ "Overview",
      dimension == "Wellbeing" ~ "Benchmark",
      TRUE ~ "Diagnostics"
    )
  ) %>%
  select(year, region, education, happiness, channel, segment, dimension, question, view_mode, age, income, score, count)

p5_observed <- base_data %>%
  count(year, region, view_mode, name = "count") %>%
  mutate(series_label = "Observed")

p5_benchmark <- p5_observed %>%
  mutate(series_label = "Benchmark", count = pmax(1L, as.integer(round(count * 0.92))))

p5_data <- bind_rows(p5_observed, p5_benchmark)

analysis_table <- base_data %>%
  select(year, region, education, happiness, channel, segment, dimension, question, age, income, score, count) %>%
  arrange(desc(year), region, education)

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

prepare_output_dir <- function(path) {
  if (dir.exists(path)) {
    unlink(path, recursive = TRUE, force = TRUE)
  }
}

resolve_demo_open <- function() {
  raw <- tolower(trimws(Sys.getenv("DASHBOARDR_DEMO_OPEN", unset = "browser")))
  if (raw %in% c("false", "0", "no", "none")) {
    return(FALSE)
  }
  "browser"
}

resolve_demo_debug <- function() {
  raw <- tolower(trimws(Sys.getenv("DASHBOARDR_DEBUG", unset = "true")))
  if (raw %in% c("false", "0", "no", "off")) {
    return(FALSE)
  }
  TRUE
}

region_palette <- c(
  "Midwest" = "#4E79A7",
  "Northeast" = "#59A14F",
  "South" = "#F28E2B",
  "West" = "#E15759"
)

happiness_palette <- c(
  "Very Happy" = "#2E86AB",
  "Pretty Happy" = "#F18F01",
  "Not Too Happy" = "#C73E1D"
)

series_palette <- c(
  "Observed" = "#4E79A7",
  "Benchmark" = "#E15759"
)

sidebar_for_p1 <- function(sidebar_title) {
  create_content() %>%
    add_sidebar(position = "left", width = "285px", title = sidebar_title) %>%
    add_input(
      input_id = "p1_region",
      label = "Region",
      type = "checkbox",
      filter_var = "region",
      options = regions,
      default_selected = regions
    ) %>%
    add_input(
      input_id = "p1_year",
      label = "Year",
      type = "slider",
      filter_var = "year",
      min = min(years),
      max = max(years),
      step = 1,
      value = min(years),
      labels = as.character(years),
      show_value = TRUE
    ) %>%
    end_sidebar()
}

sidebar_for_p2 <- function(sidebar_title) {
  create_content() %>%
    add_sidebar(position = "left", width = "285px", title = sidebar_title) %>%
    add_input(
      input_id = "p2_education",
      label = "Education",
      type = "select_multiple",
      filter_var = "education",
      options = education_levels,
      default_selected = education_levels
    ) %>%
    add_input(
      input_id = "p2_channel",
      label = "Channel",
      type = "button_group",
      filter_var = "channel",
      options = channels,
      default_selected = "Web"
    ) %>%
    end_sidebar()
}

sidebar_for_p3 <- function(sidebar_title) {
  create_content() %>%
    add_sidebar(position = "left", width = "285px", title = sidebar_title) %>%
    add_input(
      input_id = "p3_channel",
      label = "Channel",
      type = "radio",
      filter_var = "channel",
      options = channels,
      default_selected = "Web"
    ) %>%
    add_input(
      input_id = "p3_year",
      label = "Year",
      type = "slider",
      filter_var = "year",
      min = min(years),
      max = max(years),
      step = 1,
      value = min(years),
      labels = as.character(years),
      show_value = TRUE
    ) %>%
    end_sidebar()
}

sidebar_for_p4 <- function(sidebar_title) {
  create_content() %>%
    add_sidebar(position = "left", width = "285px", title = sidebar_title) %>%
    add_linked_inputs(
      parent = list(
        id = "p4_dimension",
        label = "Dimension",
        filter_var = "dimension",
        options = names(questions_by_dimension)
      ),
      child = list(
        id = "p4_question",
        label = "Question",
        filter_var = "question",
        options_by_parent = questions_by_dimension
      )
    ) %>%
    add_input(
      input_id = "p4_segment",
      label = "Segment",
      type = "select_single",
      filter_var = "segment",
      options = segments,
      default_selected = segments[1]
    ) %>%
    end_sidebar()
}

sidebar_for_p5 <- function(sidebar_title) {
  create_content() %>%
    add_sidebar(position = "left", width = "285px", title = sidebar_title) %>%
    add_input(
      input_id = "p5_view_mode",
      label = "View mode",
      type = "radio",
      filter_var = "view_mode",
      options = c("Overview", "Benchmark", "Diagnostics"),
      default_selected = "Overview"
    ) %>%
    add_input(
      input_id = "p5_region",
      label = "Region",
      type = "checkbox",
      filter_var = "region",
      options = regions,
      default_selected = regions
    ) %>%
    add_input(
      input_id = "p5_benchmark_toggle",
      label = "Show benchmark series",
      type = "switch",
      filter_var = "benchmark_toggle",
      toggle_series = "Benchmark",
      override = TRUE,
      value = TRUE
    ) %>%
    end_sidebar()
}

sidebar_for_p6 <- function(sidebar_title) {
  create_content() %>%
    add_sidebar(position = "left", width = "285px", title = sidebar_title) %>%
    add_input(
      input_id = "p6_region_text",
      label = "Region search",
      type = "text",
      filter_var = "region",
      placeholder = "Type region text..."
    ) %>%
    add_input(
      input_id = "p6_year_number",
      label = "Exact year",
      type = "number",
      filter_var = "year",
      min = min(years),
      max = max(years),
      step = 1,
      value = min(years)
    ) %>%
    end_sidebar()
}

page_p1 <- function(data, sidebar_title) {
  create_page(name = "P1_Bar_Palette_Slider", data = data) %>%
    add_content(sidebar_for_p1(sidebar_title)) %>%
    add_html("<div id='pw-title-p1' class='pw-page-label'>P1: Bar + color palette + slider</div>") %>%
    add_html("<div id='p1_dynamic_low' class='pw-dynamic-text'>Context: Younger cohort (<=45).</div>", show_when = ~ age <= 45) %>%
    add_html("<div id='p1_dynamic_high' class='pw-dynamic-text'>Context: Older cohort (>=46).</div>", show_when = ~ age >= 46) %>%
    add_viz(
      type = "stackedbar",
      x_var = "region",
      stack_var = "segment",
      stacked_type = "percent",
      weight_var = "count",
      color_palette = c("#4E79A7", "#59A14F", "#F28E2B"),
      cross_tab_filter_vars = c("region", "age", "year", "education", "happiness", "channel", "segment", "dimension", "question"),
      title = "Segment composition by region ({region}, {year})"
    )
}

page_p2 <- function(data, sidebar_title) {
  create_page(name = "P2_Stackedbar_Palette", data = data) %>%
    add_content(sidebar_for_p2(sidebar_title)) %>%
    add_html("<div id='pw-title-p2' class='pw-page-label'>P2: Stackedbar + palette + button group</div>") %>%
    add_viz(
      type = "stackedbar",
      x_var = "education",
      stack_var = "happiness",
      stacked_type = "percent",
      weight_var = "count",
      color_palette = unname(happiness_palette),
      cross_tab_filter_vars = c("education", "channel", "region", "year", "segment", "dimension", "question"),
      title = "Education composition by happiness ({education}, {channel})"
    )
}

page_p3 <- function(data, sidebar_title) {
  create_page(name = "P3_Timeline_Radio", data = data) %>%
    add_content(sidebar_for_p3(sidebar_title)) %>%
    add_html("<div id='pw-title-p3' class='pw-page-label'>P3: Timeline + radio + slider</div>") %>%
    add_html("<div id='p3_dynamic_early' class='pw-dynamic-text'>Window: early period</div>", show_when = ~ year <= 2021) %>%
    add_html("<div id='p3_dynamic_late' class='pw-dynamic-text'>Window: late period</div>", show_when = ~ year >= 2022) %>%
    add_viz(
      type = "timeline",
      time_var = "year",
      y_var = "score",
      group_var = "channel",
      color_palette = c("#4E79A7", "#F28E2B", "#59A14F"),
      cross_tab_filter_vars = c("channel", "year", "region", "education", "happiness", "segment", "dimension", "question"),
      title = "Score trend by channel ({channel}, {year})"
    )
}

page_p4 <- function(data, sidebar_title) {
  create_page(name = "P4_Linked_Inputs", data = data) %>%
    add_content(sidebar_for_p4(sidebar_title)) %>%
    add_html("<div id='pw-title-p4' class='pw-page-label'>P4: Linked inputs (dimension -> question)</div>") %>%
    add_viz(
      type = "stackedbar",
      x_var = "question",
      stack_var = "segment",
      stacked_type = "count",
      weight_var = "count",
      color_palette = c("#4E79A7", "#F28E2B", "#76B7B2"),
      cross_tab_filter_vars = c("segment", "dimension", "question", "region", "education", "happiness", "channel", "year"),
      title = "Responses by question and segment ({segment}, {dimension}, {question})"
    )
}

page_p5 <- function(data, sidebar_title) {
  create_page(name = "P5_Complex_Show_When", data = data) %>%
    add_content(sidebar_for_p5(sidebar_title)) %>%
    add_html("<div id='pw-title-p5' class='pw-page-label'>P5: Complex show_when + switch</div>") %>%
    add_callout(
      title = "Overview mode",
      text = "Overview focuses on broad region-level differences.",
      type = "note",
      show_when = ~ view_mode == "Overview"
    ) %>%
    add_callout(
      title = "Benchmark mode",
      text = "Benchmark mode highlights observed vs benchmark.",
      type = "warning",
      show_when = ~ view_mode == "Benchmark"
    ) %>%
    add_callout(
      title = "Diagnostics mode",
      text = "Diagnostics surfaces edge-case patterns.",
      type = "tip",
      show_when = ~ view_mode == "Diagnostics"
    ) %>%
    add_html("<div id='p5_dynamic_detail' class='pw-dynamic-text'>Detail panel visible in benchmark/diagnostics.</div>", show_when = ~ view_mode != "Overview") %>%
    add_viz(
      type = "bar",
      x_var = "region",
      group_var = "series_label",
      y_var = "count",
      color_palette = unname(series_palette),
      cross_tab_filter_vars = c("view_mode", "region", "series_label"),
      title = "Observed vs benchmark by region ({view_mode})"
    )
}

page_p6 <- function(data, table_data, sidebar_title) {
  create_page(name = "P6_Text_Number", data = data) %>%
    add_content(sidebar_for_p6(sidebar_title)) %>%
    add_html("<div id='pw-title-p6' class='pw-page-label'>P6: Text + number filters</div>") %>%
    add_viz(
      type = "timeline",
      time_var = "year",
      y_var = "income",
      group_var = "region",
      color_palette = unname(region_palette),
      cross_tab_filter_vars = c("region", "year", "education", "happiness", "channel", "segment", "dimension", "question"),
      title = "Income trend by region (year: {year})"
    ) %>%
    add_DT(
      table_data = table_data,
      options = list(pageLength = 8, scrollX = TRUE),
      filter_vars = c("region", "year")
    )
}

build_core_dashboard <- function(title, output_dir, backend, data, p5_chart_data, table_data, sidebar_title, debug_mode = FALSE) {
  prepare_output_dir(output_dir)

  create_dashboard(
    title = title,
    output_dir = output_dir,
    backend = backend,
    chart_export = TRUE,
    lazy_debug = debug_mode
  ) %>%
    add_pages(
      page_p1(data, paste0(sidebar_title, " - P1")),
      page_p2(data, paste0(sidebar_title, " - P2")),
      page_p3(data, paste0(sidebar_title, " - P3")),
      page_p4(data, paste0(sidebar_title, " - P4")),
      page_p5(p5_chart_data, paste0(sidebar_title, " - P5")),
      page_p6(data, table_data, paste0(sidebar_title, " - P6"))
    )
}

build_mixed_dashboard <- function(title, output_dir, data, debug_mode = FALSE) {
  prepare_output_dir(output_dir)

  mixed_sidebar <- create_content() %>%
    add_sidebar(position = "left", width = "285px", title = "Mixed Filters") %>%
    add_input(
      input_id = "m1_region",
      label = "Region",
      type = "checkbox",
      filter_var = "region",
      options = regions,
      default_selected = regions
    ) %>%
    add_input(
      input_id = "m1_year",
      label = "Year",
      type = "slider",
      filter_var = "year",
      min = min(years),
      max = max(years),
      step = 1,
      value = min(years),
      labels = as.character(years),
      show_value = TRUE
    ) %>%
    add_input(
      input_id = "m1_education",
      label = "Education",
      type = "select_multiple",
      filter_var = "education",
      options = education_levels,
      default_selected = education_levels
    ) %>%
    end_sidebar()

  hc_widget_data <- data %>%
    count(year, region, name = "n")

  hc_widget <- highcharter::hchart(
    hc_widget_data,
    "column",
    highcharter::hcaes(x = year, y = n, group = region)
  ) %>%
    highcharter::hc_title(text = "Highcharter widget: region over time")

  plotly_widget <- plotly::plot_ly(
    data = dplyr::slice_sample(data, n = 1200),
    x = ~age,
    y = ~score,
    color = ~education,
    type = "scatter",
    mode = "markers"
  ) %>%
    plotly::layout(title = "Plotly widget: score vs age")

  mixed_page <- create_page(name = "M1_Mixed_Backends_Integration", data = data) %>%
    add_content(mixed_sidebar) %>%
    add_html("<div id='pw-title-m1' class='pw-page-label'>M1: Mixed backend integration</div>") %>%
    add_html("<div id='m1_dynamic_low' class='pw-dynamic-text'>Mixed helper: early-year context.</div>", show_when = ~ year <= 2021) %>%
    add_html("<div id='m1_dynamic_high' class='pw-dynamic-text'>Mixed helper: recent-year context.</div>", show_when = ~ year >= 2022) %>%
    add_layout_column(class = "m1-left") %>%
      add_layout_row(class = "m1-native") %>%
        add_viz(
          type = "stackedbar",
          x_var = "region",
          stack_var = "education",
          stacked_type = "percent",
          weight_var = "count",
          color_palette = c("#4E79A7", "#59A14F", "#F28E2B", "#E15759"),
          cross_tab_filter_vars = c("region", "year", "education", "happiness", "channel", "segment", "dimension", "question"),
          title = "Native backend chart"
        ) %>%
      end_layout_row() %>%
      add_layout_row(class = "m1-hc") %>%
        add_text("#### Highcharter widget") %>%
        add_hc(
          hc_object = hc_widget,
          filter_vars = c("region", "education", "year")
        ) %>%
      end_layout_row() %>%
      add_layout_row(class = "m1-plotly") %>%
        add_text("#### Plotly widget") %>%
        add_plotly(
          plot = plotly_widget,
          filter_vars = c("education", "region", "year")
        ) %>%
      end_layout_row() %>%
    end_layout_column()

  create_dashboard(
    title = title,
    output_dir = output_dir,
    backend = "echarts4r",
    chart_export = TRUE,
    lazy_debug = debug_mode
  ) %>%
    add_pages(mixed_page)
}

# -----------------------------------------------------------------------------
# Generate all dashboards
# -----------------------------------------------------------------------------

demo_open <- resolve_demo_open()
demo_debug <- resolve_demo_debug()
cat("Debug mode (DASHBOARDR_DEBUG):", demo_debug, "\n")

proj_echarts <- build_core_dashboard(
  title = "Input Matrix Demo (echarts4r)",
  output_dir = "input_matrix_echarts",
  backend = "echarts4r",
  data = base_data,
  p5_chart_data = p5_data,
  table_data = analysis_table,
  sidebar_title = "ECharts Input Matrix",
  debug_mode = demo_debug
)
res_echarts <- generate_dashboard(proj_echarts, render = TRUE, open = demo_open)
cat("\nGenerated echarts4r input matrix at:", normalizePath(res_echarts$output_dir, mustWork = FALSE), "\n")

proj_plotly <- build_core_dashboard(
  title = "Input Matrix Demo (plotly)",
  output_dir = "input_matrix_plotly",
  backend = "plotly",
  data = base_data,
  p5_chart_data = p5_data,
  table_data = analysis_table,
  sidebar_title = "Plotly Input Matrix",
  debug_mode = demo_debug
)
res_plotly <- generate_dashboard(proj_plotly, render = TRUE, open = demo_open)
cat("\nGenerated plotly input matrix at:", normalizePath(res_plotly$output_dir, mustWork = FALSE), "\n")

proj_hc <- build_core_dashboard(
  title = "Input Matrix Demo (highcharter)",
  output_dir = "input_matrix_hc",
  backend = "highcharter",
  data = base_data,
  p5_chart_data = p5_data,
  table_data = analysis_table,
  sidebar_title = "Highcharter Input Matrix",
  debug_mode = demo_debug
)
res_hc <- generate_dashboard(proj_hc, render = TRUE, open = demo_open)
cat("\nGenerated highcharter input matrix at:", normalizePath(res_hc$output_dir, mustWork = FALSE), "\n")

proj_mixed <- build_mixed_dashboard(
  title = "Input Matrix Demo (mixed backends)",
  output_dir = "input_matrix_mixed",
  data = base_data,
  debug_mode = demo_debug
)
res_mixed <- generate_dashboard(proj_mixed, render = TRUE, open = demo_open)
cat("\nGenerated mixed-backend input matrix at:", normalizePath(res_mixed$output_dir, mustWork = FALSE), "\n")

cat("\n=== Input matrix backend demos regenerated ===\n")
