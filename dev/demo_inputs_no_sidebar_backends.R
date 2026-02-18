# =============================================================================
# dashboardr Demo: Complex Inputs Without Sidebar (all core backends)
# =============================================================================
# Run with:
#   source("dev/demo_inputs_no_sidebar_backends.R")

library(tidyverse)

devtools::load_all()

set.seed(20260217)

# -----------------------------------------------------------------------------
# Canonical deterministic data
# -----------------------------------------------------------------------------

years <- 2019:2025
regions <- c("Midwest", "Northeast", "South", "West")
education_levels <- c("High School", "Some College", "Bachelor's", "Graduate")
channels <- c("Web", "Phone", "In Person")
segments <- c("Consumer", "Business", "Public")
questions_by_dimension <- list(
  Economy = c("Income", "Job Security", "Inflation"),
  Wellbeing = c("Life Satisfaction", "Stress", "Community"),
  Trust = c("Media Trust", "Gov Trust", "Business Trust")
)

question_table <- tibble::enframe(questions_by_dimension, name = "dimension", value = "question") %>%
  tidyr::unnest(question)

base_data <- tidyr::crossing(
  year = years,
  region = regions,
  education = education_levels,
  channel = channels,
  segment = segments,
  question_table
) %>%
  mutate(
    keep_prob = 0.50 +
      if_else(region == "Northeast", 0.08, 0) +
      if_else(region == "South", -0.05, 0) +
      if_else(education == "Graduate", 0.12, 0) +
      if_else(channel == "Web", 0.05, 0) +
      if_else(segment == "Business", 0.06, 0) +
      (year - min(years)) * 0.02,
    keep_prob = pmin(0.95, pmax(0.22, keep_prob)),
    keep_flag = runif(n()) <= keep_prob
  ) %>%
  filter(keep_flag) %>%
  select(-keep_prob, -keep_flag) %>%
  mutate(
    year = as.integer(year),
    region = factor(region, levels = regions),
    education = factor(education, levels = education_levels),
    channel = factor(channel, levels = channels),
    segment = factor(segment, levels = segments),
    dimension = factor(dimension, levels = names(questions_by_dimension)),
    question = as.character(question),
    score = pmax(
      35,
      pmin(
        98,
        round(
          58 +
            (year - min(years)) * 1.6 +
            if_else(segment == "Business", 3, if_else(segment == "Public", -2, 0)) +
            if_else(channel == "Web", 1.5, if_else(channel == "Phone", 0.4, -0.3)) +
            rnorm(n(), 0, 5.8),
          1
        )
      )
    ),
    count = pmax(1L, as.integer(round(rnorm(n(), mean = 12, sd = 4)))),
    view_mode = case_when(
      dimension == "Economy" ~ "Overview",
      dimension == "Wellbeing" ~ "Benchmark",
      TRUE ~ "Diagnostics"
    )
  )

n2_counts <- base_data %>%
  count(year, region, view_mode, name = "count") %>%
  mutate(series_label = "Observed")

n2_benchmark <- n2_counts %>%
  mutate(series_label = "Benchmark", count = pmax(1L, as.integer(round(count * 0.90))))

n2_chart_data <- bind_rows(n2_counts, n2_benchmark)

n2_trend_data <- base_data %>%
  group_by(year, region, view_mode) %>%
  summarise(score = round(mean(score), 1), .groups = "drop")

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

# -----------------------------------------------------------------------------
# Pages (all no-sidebar)
# -----------------------------------------------------------------------------

page_n1 <- function(data) {
  create_page(name = "N1_Inline_Filter_Matrix", data = data) %>%
    add_html("<div id='pw-title-ns1' class='pw-page-label'>N1: Inline filters + slider (no sidebar)</div>") %>%
    add_input_row(style = "boxed", align = "left") %>%
      add_input(
        input_id = "n1_region",
        label = "Region",
        type = "select_multiple",
        filter_var = "region",
        options = regions,
        default_selected = regions,
        width = "320px"
      ) %>%
      add_input(
        input_id = "n1_education",
        label = "Education",
        type = "select_single",
        filter_var = "education",
        options = education_levels,
        default_selected = education_levels[2],
        width = "220px"
      ) %>%
      add_input(
        input_id = "n1_channel",
        label = "Channel",
        type = "button_group",
        filter_var = "channel",
        options = channels,
        default_selected = "Web"
      ) %>%
    end_input_row() %>%
    add_input_row(style = "inline", align = "left") %>%
      add_input(
        input_id = "n1_year",
        label = "Year",
        type = "slider",
        filter_var = "year",
        min = min(years),
        max = max(years),
        step = 1,
        value = min(years),
        labels = as.character(years),
        show_value = TRUE,
        width = "340px"
      ) %>%
    end_input_row() %>%
    add_html("<div id='n1_dynamic_early' class='pw-dynamic-text'>Window: early period (2019-2021)</div>", show_when = ~ year <= 2021) %>%
    add_html("<div id='n1_dynamic_late' class='pw-dynamic-text'>Window: late period (2022+)</div>", show_when = ~ year >= 2022) %>%
    add_viz(
      type = "stackedbar",
      x_var = "region",
      stack_var = "segment",
      stacked_type = "percent",
      weight_var = "count",
      cross_tab_filter_vars = c("region", "education", "channel", "year", "segment", "dimension", "question"),
      title = "Segment composition by region ({region}, {education}, {channel}, {year})"
    )
}

page_n2 <- function(count_data, trend_data) {
  create_page(
    name = "N2_Inline_ShowWhen_Modes",
    data = list(counts = count_data, trend = trend_data)
  ) %>%
    add_html("<div id='pw-title-ns2' class='pw-page-label'>N2: Inline show_when modes (no sidebar)</div>") %>%
    add_input_row(style = "boxed", align = "left") %>%
      add_input(
        input_id = "n2_view_mode",
        label = "View mode",
        type = "radio",
        filter_var = "view_mode",
        options = c("Overview", "Benchmark", "Diagnostics"),
        default_selected = "Overview",
        inline = TRUE
      ) %>%
      add_input(
        input_id = "n2_region",
        label = "Region",
        type = "checkbox",
        filter_var = "region",
        options = regions,
        default_selected = regions,
        inline = TRUE
      ) %>%
      add_input(
        input_id = "n2_benchmark_toggle",
        label = "Show benchmark series",
        type = "switch",
        filter_var = "benchmark_toggle",
        toggle_series = "Benchmark",
        override = TRUE,
        value = TRUE
      ) %>%
    end_input_row() %>%
    add_callout(
      title = "Overview mode",
      text = "Overview emphasizes broad regional differences.",
      type = "note",
      show_when = ~ view_mode == "Overview"
    ) %>%
    add_callout(
      title = "Benchmark mode",
      text = "Benchmark compares observed counts against benchmark series.",
      type = "warning",
      show_when = ~ view_mode == "Benchmark"
    ) %>%
    add_callout(
      title = "Diagnostics mode",
      text = "Diagnostics switches to score trend detail.",
      type = "tip",
      show_when = ~ view_mode == "Diagnostics"
    ) %>%
    add_html("<div id='n2_dynamic_overview' class='pw-dynamic-text'>Overview panel active.</div>", show_when = ~ view_mode == "Overview") %>%
    add_html("<div id='n2_dynamic_detail' class='pw-dynamic-text'>Detail panel active.</div>", show_when = ~ view_mode != "Overview") %>%
    add_viz(
      type = "stackedbar",
      data = "counts",
      x_var = "region",
      stack_var = "series_label",
      stacked_type = "count",
      weight_var = "count",
      cross_tab_filter_vars = c("view_mode", "region", "series_label"),
      title = "Observed vs benchmark by region ({view_mode}, {region})",
      show_when = ~ view_mode != "Diagnostics"
    ) %>%
    add_viz(
      type = "timeline",
      data = "trend",
      time_var = "year",
      y_var = "score",
      group_var = "region",
      cross_tab_filter_vars = c("view_mode", "region", "year"),
      title = "Diagnostics score trend ({view_mode}, {region})",
      show_when = ~ view_mode == "Diagnostics"
    )
}

page_n3 <- function(data) {
  create_page(name = "N3_Inline_Linked_MultiChart", data = data) %>%
    add_html("<div id='pw-title-ns3' class='pw-page-label'>N3: Inline controls + multi-chart (no sidebar)</div>") %>%
    add_input_row(style = "boxed", align = "left") %>%
      add_input(
        input_id = "n3_dimension",
        label = "Dimension",
        type = "select_single",
        filter_var = "dimension",
        options = names(questions_by_dimension),
        default_selected = names(questions_by_dimension)[1]
      ) %>%
      add_input(
        input_id = "n3_question",
        label = "Question",
        type = "select_single",
        filter_var = "question",
        options = unique(unlist(questions_by_dimension)),
        default_selected = questions_by_dimension[[1]][1]
      ) %>%
      add_input(
        input_id = "n3_segment",
        label = "Segment",
        type = "select_single",
        filter_var = "segment",
        options = segments,
        default_selected = segments[1]
      ) %>%
    end_input_row() %>%
    add_input_row(style = "inline", align = "left") %>%
      add_input(
        input_id = "n3_year",
        label = "Year",
        type = "slider",
        filter_var = "year",
        min = min(years),
        max = max(years),
        step = 1,
        value = min(years),
        labels = as.character(years),
        show_value = TRUE,
        width = "320px"
      ) %>%
      add_input(
        input_id = "n3_region",
        label = "Region",
        type = "checkbox",
        filter_var = "region",
        options = regions,
        default_selected = regions,
        inline = TRUE
      ) %>%
    end_input_row() %>%
    add_viz(
      type = "stackedbar",
      x_var = "question",
      stack_var = "segment",
      stacked_type = "percent",
      weight_var = "count",
      cross_tab_filter_vars = c("dimension", "question", "segment", "year", "region", "education", "channel"),
      title = "Question mix by segment ({dimension}, {question}, {segment}, {year})"
    ) %>%
    add_viz(
      type = "timeline",
      time_var = "year",
      y_var = "score",
      group_var = "segment",
      cross_tab_filter_vars = c("dimension", "question", "segment", "year", "region", "education", "channel"),
      title = "Score trend by segment ({dimension}, {question}, {segment}, {year})"
    )
}

build_no_sidebar_dashboard <- function(title, output_dir, backend, debug_mode = FALSE) {
  prepare_output_dir(output_dir)
  create_dashboard(
    title = title,
    output_dir = output_dir,
    backend = backend,
    chart_export = TRUE,
    lazy_debug = debug_mode
  ) %>%
    add_pages(
      page_n1(base_data),
      page_n2(n2_chart_data, n2_trend_data),
      page_n3(base_data)
    )
}

# -----------------------------------------------------------------------------
# Generate all backends
# -----------------------------------------------------------------------------

demo_open <- resolve_demo_open()
demo_debug <- resolve_demo_debug()
cat("Debug mode (DASHBOARDR_DEBUG):", demo_debug, "\n")

proj_echarts <- build_no_sidebar_dashboard(
  title = "Complex Inputs No Sidebar (echarts4r)",
  output_dir = "input_nosidebar_echarts",
  backend = "echarts4r",
  debug_mode = demo_debug
)
res_echarts <- generate_dashboard(proj_echarts, render = TRUE, open = demo_open)
cat("\nGenerated echarts4r no-sidebar input demo at:", normalizePath(res_echarts$output_dir, mustWork = FALSE), "\n")

proj_plotly <- build_no_sidebar_dashboard(
  title = "Complex Inputs No Sidebar (plotly)",
  output_dir = "input_nosidebar_plotly",
  backend = "plotly",
  debug_mode = demo_debug
)
res_plotly <- generate_dashboard(proj_plotly, render = TRUE, open = demo_open)
cat("\nGenerated plotly no-sidebar input demo at:", normalizePath(res_plotly$output_dir, mustWork = FALSE), "\n")

proj_hc <- build_no_sidebar_dashboard(
  title = "Complex Inputs No Sidebar (highcharter)",
  output_dir = "input_nosidebar_hc",
  backend = "highcharter",
  debug_mode = demo_debug
)
res_hc <- generate_dashboard(proj_hc, render = TRUE, open = demo_open)
cat("\nGenerated highcharter no-sidebar input demo at:", normalizePath(res_hc$output_dir, mustWork = FALSE), "\n")

cat("\n=== No-sidebar complex input demos regenerated ===\n")
