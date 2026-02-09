# =============================================================================
# dashboardr Demo: Sidebar + Single Graph Edge Cases
# =============================================================================
# Run with:
#   source("dev/demo_sidebar_single_graph.R")
#
# Tests complex input logic with sidebar and ONE graph per page,
# covering pie, scatter, boxplot, show_when on charts, reset buttons,
# and compound show_when conditions.

library(tidyverse)

devtools::load_all()

set.seed(20260210)

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

base_data <- tidyr::crossing(
  year = years,
  region = regions,
  education = education_levels,
  happiness = happiness_levels,
  channel = channels,
  segment = segments,
  question_table
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
    score = pmax(
      35,
      pmin(
        98,
        round(
          55 +
            (year - min(years)) * 1.7 +
            rnorm(n(), 0, 6),
          1
        )
      )
    ),
    income = pmax(
      15000,
      round(base_income + education_bonus + happiness_bonus + (year - min(years)) * 1200 + rnorm(n(), 0, 9000), 0)
    ),
    count = pmax(1L, as.integer(round(rnorm(n(), 12, 4))))
  ) %>%
  select(year, region, education, happiness, channel, segment, dimension, question, age, income, score, count)

# Smaller slice for scatter plot (avoid huge point counts)
scatter_data <- base_data %>%
  slice_sample(n = 800)

# Boxplot data
boxplot_data <- base_data %>%
  select(year, region, education, income, score)

# Pie data: aggregate counts per region
pie_data <- base_data %>%
  count(region, education, happiness, name = "n")

# Stacked bar data for S7
stacked_data <- base_data %>%
  count(region, education, happiness, year, name = "n")

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

region_palette <- c(
  "Midwest" = "#4E79A7",
  "Northeast" = "#59A14F",
  "South" = "#F28E2B",
  "West" = "#E15759"
)

education_palette <- c(
  "High School" = "#4E79A7",
  "Some College" = "#59A14F",
  "Bachelor's" = "#F28E2B",
  "Graduate" = "#E15759"
)

happiness_palette <- c(
  "Very Happy" = "#2E86AB",
  "Pretty Happy" = "#F18F01",
  "Not Too Happy" = "#C73E1D"
)

# =============================================================================
# S1: All-input sidebar + single bar chart
# =============================================================================
# Tests all 9 input types filtering one bar chart

page_s1 <- function(data, sidebar_title) {
  create_page(name = "S1_All_Inputs_Single_Bar", data = data) %>%
    add_sidebar(position = "left", width = "300px", title = sidebar_title) %>%
    add_input(
      input_id = "s1_region_select",
      label = "Region (select multiple)",
      type = "select_multiple",
      filter_var = "region",
      options = regions,
      default_selected = regions
    ) %>%
    add_input(
      input_id = "s1_education_select",
      label = "Education (select single)",
      type = "select_single",
      filter_var = "education",
      options = education_levels,
      default_selected = education_levels[1]
    ) %>%
    add_input(
      input_id = "s1_happiness_checkbox",
      label = "Happiness (checkbox)",
      type = "checkbox",
      filter_var = "happiness",
      options = happiness_levels,
      default_selected = happiness_levels
    ) %>%
    add_input(
      input_id = "s1_channel_radio",
      label = "Channel (radio)",
      type = "radio",
      filter_var = "channel",
      options = channels,
      default_selected = "Web"
    ) %>%
    add_input(
      input_id = "s1_segment_button_group",
      label = "Segment (button group)",
      type = "button_group",
      filter_var = "segment",
      options = segments,
      default_selected = "Consumer"
    ) %>%
    add_input(
      input_id = "s1_year_slider",
      label = "Year (slider)",
      type = "slider",
      filter_var = "year",
      min = min(years),
      max = max(years),
      step = 1,
      value = min(years),
      labels = as.character(years),
      show_value = TRUE
    ) %>%
    end_sidebar() %>%
    add_html("<div id='pw-single-graph-s1'></div>") %>%
    add_text("### S1: All-input sidebar + single bar") %>%
    add_html("<div id='s1_dynamic_low' class='pw-dynamic-text'>Slider: early years (2019-2021)</div>", show_when = ~ year <= 2021) %>%
    add_html("<div id='s1_dynamic_high' class='pw-dynamic-text'>Slider: recent years (2022+)</div>", show_when = ~ year >= 2022) %>%
    add_viz(
      type = "bar",
      x_var = "region",
      group_var = "education",
      color_palette = unname(education_palette),
      title = "Responses by region and education"
    )
}

# =============================================================================
# S2: Pie + sidebar + show_when
# =============================================================================
# Pie chart with sidebar select + show_when on callout

page_s2 <- function(data, sidebar_title) {
  create_page(name = "S2_Pie_ShowWhen", data = data) %>%
    add_sidebar(position = "left", width = "285px", title = sidebar_title) %>%
    add_input(
      input_id = "s2_education",
      label = "Education",
      type = "select_single",
      filter_var = "education",
      options = education_levels,
      default_selected = education_levels[1]
    ) %>%
    add_input(
      input_id = "s2_happiness",
      label = "Happiness",
      type = "checkbox",
      filter_var = "happiness",
      options = happiness_levels,
      default_selected = happiness_levels
    ) %>%
    end_sidebar() %>%
    add_html("<div id='pw-single-graph-s2'></div>") %>%
    add_text("### S2: Pie + sidebar + show_when") %>%
    add_callout(
      title = "Graduate filter active",
      text = "You are filtering to Graduate education level.",
      type = "note",
      show_when = ~ education == "Graduate"
    ) %>%
    add_callout(
      title = "Non-graduate filter",
      text = "Viewing a non-graduate education level.",
      type = "tip",
      show_when = ~ education != "Graduate"
    ) %>%
    add_viz(
      type = "pie",
      x_var = "region",
      color_palette = unname(region_palette),
      title = "Distribution by region"
    )
}

# =============================================================================
# S3: Scatter + sidebar + linked inputs
# =============================================================================
# Scatter chart filtered by linked parent-child selects

page_s3 <- function(data, sidebar_title) {
  create_page(name = "S3_Scatter_Linked", data = data) %>%
    add_sidebar(position = "left", width = "285px", title = sidebar_title) %>%
    add_linked_inputs(
      parent = list(
        id = "s3_dimension",
        label = "Dimension",
        options = names(questions_by_dimension)
      ),
      child = list(
        id = "s3_question",
        label = "Question",
        options_by_parent = questions_by_dimension
      )
    ) %>%
    add_input(
      input_id = "s3_region",
      label = "Region",
      type = "select_single",
      filter_var = "region",
      options = regions,
      default_selected = regions[1]
    ) %>%
    end_sidebar() %>%
    add_html("<div id='pw-single-graph-s3'></div>") %>%
    add_text("### S3: Scatter + linked inputs") %>%
    add_viz(
      type = "scatter",
      x_var = "age",
      y_var = "score",
      color_var = "region",
      color_palette = unname(region_palette),
      title = "Score vs Age by region"
    )
}

# =============================================================================
# S4: Boxplot + sidebar + checkbox + slider
# =============================================================================
# Boxplot filtered by checkbox and slider

page_s4 <- function(data, sidebar_title) {
  create_page(name = "S4_Boxplot_Checkbox_Slider", data = data) %>%
    add_sidebar(position = "left", width = "285px", title = sidebar_title) %>%
    add_input(
      input_id = "s4_region",
      label = "Region",
      type = "checkbox",
      filter_var = "region",
      options = regions,
      default_selected = regions
    ) %>%
    add_input(
      input_id = "s4_year",
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
    end_sidebar() %>%
    add_html("<div id='pw-single-graph-s4'></div>") %>%
    add_text("### S4: Boxplot + checkbox + slider") %>%
    add_html("<div id='s4_dynamic_low' class='pw-dynamic-text'>Slider: early years</div>", show_when = ~ year <= 2021) %>%
    add_html("<div id='s4_dynamic_high' class='pw-dynamic-text'>Slider: recent years</div>", show_when = ~ year >= 2022) %>%
    add_viz(
      type = "boxplot",
      x_var = "region",
      y_var = "income",
      color_palette = unname(region_palette),
      title = "Income distribution by region"
    )
}

# =============================================================================
# S5: Single bar + reset button
# =============================================================================
# Bar chart with reset button in sidebar

page_s5 <- function(data, sidebar_title) {
  create_page(name = "S5_Bar_Reset_Button", data = data) %>%
    add_sidebar(position = "left", width = "285px", title = sidebar_title) %>%
    add_input(
      input_id = "s5_region",
      label = "Region",
      type = "checkbox",
      filter_var = "region",
      options = regions,
      default_selected = regions
    ) %>%
    add_input(
      input_id = "s5_education",
      label = "Education",
      type = "select_multiple",
      filter_var = "education",
      options = education_levels,
      default_selected = education_levels
    ) %>%
    add_reset_button() %>%
    end_sidebar() %>%
    add_html("<div id='pw-single-graph-s5'></div>") %>%
    add_text("### S5: Single bar + reset button") %>%
    add_viz(
      type = "bar",
      x_var = "region",
      group_var = "happiness",
      color_palette = unname(happiness_palette),
      title = "Region by happiness level"
    )
}

# =============================================================================
# S6: Show_when on chart itself
# =============================================================================
# A chart conditionally visible via switch input

page_s6 <- function(data, sidebar_title) {
  create_page(name = "S6_ShowWhen_On_Chart", data = data) %>%
    add_sidebar(position = "left", width = "285px", title = sidebar_title) %>%
    add_input(
      input_id = "s6_view_mode",
      label = "View mode",
      type = "select_single",
      filter_var = "view_mode",
      options = c("Chart", "Summary"),
      default_selected = "Chart"
    ) %>%
    add_input(
      input_id = "s6_region",
      label = "Region",
      type = "checkbox",
      filter_var = "region",
      options = regions,
      default_selected = regions
    ) %>%
    end_sidebar() %>%
    add_html("<div id='pw-single-graph-s6'></div>") %>%
    add_text("### S6: Show_when on chart itself") %>%
    add_html("<div id='s6_dynamic_chart' class='pw-dynamic-text'>Chart view is active.</div>", show_when = ~ view_mode == "Chart") %>%
    add_html("<div id='s6_dynamic_summary' class='pw-dynamic-text'>Summary view is active.</div>", show_when = ~ view_mode == "Summary") %>%
    add_viz(
      type = "bar",
      x_var = "region",
      group_var = "education",
      color_palette = unname(education_palette),
      title = "Region by education (chart view)",
      show_when = ~ view_mode == "Chart"
    ) %>%
    add_callout(
      title = "Summary view",
      text = "The chart is hidden in summary mode. Switch to Chart to see it.",
      type = "note",
      show_when = ~ view_mode == "Summary"
    )
}

# =============================================================================
# S7: Stacked bar + compound show_when
# =============================================================================
# show_when with and/or compound conditions on callouts

page_s7 <- function(data, sidebar_title) {
  create_page(name = "S7_Stacked_Compound_ShowWhen", data = data) %>%
    add_sidebar(position = "left", width = "285px", title = sidebar_title) %>%
    add_input(
      input_id = "s7_region",
      label = "Region",
      type = "radio",
      filter_var = "region",
      options = regions,
      default_selected = "Midwest"
    ) %>%
    add_input(
      input_id = "s7_happiness",
      label = "Happiness",
      type = "checkbox",
      filter_var = "happiness",
      options = happiness_levels,
      default_selected = happiness_levels
    ) %>%
    end_sidebar() %>%
    add_html("<div id='pw-single-graph-s7'></div>") %>%
    add_text("### S7: Stacked bar + compound show_when") %>%
    add_callout(
      title = "Midwest selected",
      text = "You are viewing the Midwest region.",
      type = "note",
      show_when = ~ region == "Midwest"
    ) %>%
    add_callout(
      title = "Non-Midwest selected",
      text = "You are viewing a non-Midwest region.",
      type = "tip",
      show_when = ~ region != "Midwest"
    ) %>%
    add_html("<div id='s7_dynamic_midwest' class='pw-dynamic-text'>Region: Midwest</div>", show_when = ~ region == "Midwest") %>%
    add_html("<div id='s7_dynamic_other' class='pw-dynamic-text'>Region: other</div>", show_when = ~ region != "Midwest") %>%
    add_viz(
      type = "stackedbar",
      x_var = "education",
      stack_var = "happiness",
      stacked_type = "percent",
      color_palette = unname(happiness_palette),
      cross_tab_filter_vars = c("education", "happiness", "region", "year"),
      title = "Education by happiness level"
    )
}

# =============================================================================
# Build dashboard for a given backend
# =============================================================================

build_single_graph_dashboard <- function(title, output_dir, backend, sidebar_label) {
  prepare_output_dir(output_dir)

  create_dashboard(
    title = title,
    output_dir = output_dir,
    backend = backend,
    chart_export = TRUE
  ) %>%
    add_pages(
      page_s1(base_data, paste0(sidebar_label, " - S1")),
      page_s2(pie_data, paste0(sidebar_label, " - S2")),
      page_s3(scatter_data, paste0(sidebar_label, " - S3")),
      page_s4(boxplot_data, paste0(sidebar_label, " - S4")),
      page_s5(base_data, paste0(sidebar_label, " - S5")),
      page_s6(base_data, paste0(sidebar_label, " - S6")),
      page_s7(stacked_data, paste0(sidebar_label, " - S7"))
    )
}

# =============================================================================
# Generate all dashboards
# =============================================================================

demo_open <- resolve_demo_open()

proj_echarts <- build_single_graph_dashboard(
  title = "Sidebar Single Graph (echarts4r)",
  output_dir = "sidebar_single_echarts",
  backend = "echarts4r",
  sidebar_label = "ECharts"
)
res_echarts <- generate_dashboard(proj_echarts, render = TRUE, open = demo_open)
cat("\nGenerated echarts4r sidebar-single-graph at:", normalizePath(res_echarts$output_dir, mustWork = FALSE), "\n")

proj_plotly <- build_single_graph_dashboard(
  title = "Sidebar Single Graph (plotly)",
  output_dir = "sidebar_single_plotly",
  backend = "plotly",
  sidebar_label = "Plotly"
)
res_plotly <- generate_dashboard(proj_plotly, render = TRUE, open = demo_open)
cat("\nGenerated plotly sidebar-single-graph at:", normalizePath(res_plotly$output_dir, mustWork = FALSE), "\n")

proj_hc <- build_single_graph_dashboard(
  title = "Sidebar Single Graph (highcharter)",
  output_dir = "sidebar_single_hc",
  backend = "highcharter",
  sidebar_label = "Highcharter"
)
res_hc <- generate_dashboard(proj_hc, render = TRUE, open = demo_open)
cat("\nGenerated highcharter sidebar-single-graph at:", normalizePath(res_hc$output_dir, mustWork = FALSE), "\n")

cat("\n=== Sidebar single-graph demos regenerated ===\n")
