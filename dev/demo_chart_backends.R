# =============================================================================
# dashboardr Demo: 5 Layout Gallery (all backends)
# =============================================================================
# Run with:
#   source("dev/demo_chart_backends.R")

library(tidyverse)

devtools::load_all()

set.seed(42)

# -----------------------------------------------------------------------------
# Data
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
  score = pmax(20, pmin(100, round(rnorm(n, 70, 12))))
)

analysis_table <- survey_data %>%
  select(year, region, gender, education, happiness, age, income, score) %>%
  arrange(desc(year))

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

make_sidebar <- function(title_prefix, sidebar_key, data, filters) {
  prefix_id <- paste0(
    tolower(gsub("[^A-Za-z0-9]", "", title_prefix)),
    "_",
    sidebar_key
  )

  sidebar <- create_content() %>%
    add_sidebar(position = "left", width = "280px", title = title_prefix)

  if ("region" %in% filters) {
    sidebar <- sidebar %>%
      add_input(
        input_id = paste0(prefix_id, "_region"),
        label = "Region",
        type = "checkbox",
        filter_var = "region",
        options = sort(unique(data$region)),
        default_selected = sort(unique(data$region))
      )
  }

  if ("gender" %in% filters) {
    sidebar <- sidebar %>%
      add_input(
        input_id = paste0(prefix_id, "_gender"),
        label = "Gender",
        type = "checkbox",
        filter_var = "gender",
        options = sort(unique(data$gender)),
        default_selected = sort(unique(data$gender))
      )
  }

  if ("education" %in% filters) {
    sidebar <- sidebar %>%
      add_input(
        input_id = paste0(prefix_id, "_education"),
        label = "Education",
        type = "select_multiple",
        filter_var = "education",
        options = sort(unique(data$education)),
        default_selected = sort(unique(data$education))
      )
  }

  if ("happiness" %in% filters) {
    sidebar <- sidebar %>%
      add_input(
        input_id = paste0(prefix_id, "_happiness"),
        label = "Happiness",
        type = "select_multiple",
        filter_var = "happiness",
        options = sort(unique(data$happiness)),
        default_selected = sort(unique(data$happiness))
      )
  }

  if ("year" %in% filters) {
    sidebar <- sidebar %>%
      add_input(
        input_id = paste0(prefix_id, "_year"),
        label = "Year",
        type = "slider",
        filter_var = "year",
        min = min(data$year),
        max = max(data$year),
        value = min(data$year),
        step = 1
      )
  }

  sidebar %>% end_sidebar()
}

# -----------------------------------------------------------------------------
# Layout pages
# -----------------------------------------------------------------------------

layout_page_one_column <- function(sidebar_block, data) {
  create_page(name = "Layout 1 - Default One Column", data = data) %>%
    add_content(sidebar_block) %>%
    add_text("### Layout 1: global default one-column page (single full-width chart)") %>%
    add_viz(type = "timeline", time_var = "year", y_var = "score", group_var = "region", title = "Score trend by region (year: {year})")
}

layout_page_explicit_one_column <- function(sidebar_block, data) {
  create_page(name = "Layout 2 - Explicit One Column", data = data) %>%
    add_content(sidebar_block) %>%
    add_text("### Layout 2: explicit one-column layout API") %>%
    add_layout_column(class = "two-one-col") %>%
      add_layout_row(class = "two-r1") %>%
        add_viz(type = "timeline", time_var = "year", y_var = "income", group_var = "region", title = "Income trend by region (year: {year})") %>%
      end_layout_row() %>%
      add_layout_row(class = "two-r2") %>%
        add_viz(type = "timeline", time_var = "year", y_var = "score", group_var = "region", title = "Score trend by region (year: {year})") %>%
      end_layout_row() %>%
    end_layout_column()
}

layout_page_two_columns <- function(sidebar_block, data) {
  create_page(name = "Layout 3 - Two Columns", data = data) %>%
    add_content(sidebar_block) %>%
    add_text("### Layout 3: explicit 2-column split") %>%
    add_layout_column(class = "three-left") %>%
      add_layout_row(class = "three-left-r1") %>%
        add_viz(type = "boxplot", x_var = "education", y_var = "income", title = "Income by education ({education})") %>%
      end_layout_row() %>%
    end_layout_column() %>%
    add_layout_column(class = "three-right") %>%
      add_layout_row(class = "three-right-r1") %>%
        add_viz(type = "bar", x_var = "education", title = "Responses by education ({education})") %>%
      end_layout_row() %>%
    end_layout_column()
}

layout_page_two_columns_footer <- function(sidebar_block, data, table_data) {
  create_page(name = "Layout 4 - Two Columns + Table", data = data) %>%
    add_content(sidebar_block) %>%
    add_text("### Layout 4: two-column charts with table below") %>%
    add_layout_column(class = "four-left") %>%
      add_layout_row(class = "four-left-r1") %>%
        add_viz(type = "timeline", time_var = "year", y_var = "income", group_var = "region", title = "Income trend by region (year: {year})") %>%
      end_layout_row() %>%
    end_layout_column() %>%
    add_layout_column(class = "four-right") %>%
      add_layout_row(class = "four-right-r1") %>%
        add_viz(type = "timeline", time_var = "year", y_var = "score", group_var = "region", title = "Score trend by region (year: {year})") %>%
      end_layout_row() %>%
    end_layout_column() %>%
    add_DT(
      table_data = table_data,
      options = list(pageLength = 10, scrollX = TRUE),
      filter_vars = c("region", "gender", "education", "year")
    )
}

layout_page_two_columns_stacked <- function(sidebar_block, data) {
  create_page(name = "Layout 5 - Two Columns Stacked", data = data) %>%
    add_content(sidebar_block) %>%
    add_text("### Layout 5: stacked two-column sections only") %>%
    add_layout_column(class = "five-left") %>%
      add_layout_row(class = "five-left-r1") %>%
        add_viz(type = "timeline", time_var = "year", y_var = "income", group_var = "happiness", title = "Income trend by happiness ({happiness})") %>%
      end_layout_row() %>%
      add_layout_row(class = "five-left-r2") %>%
        add_viz(type = "bar", x_var = "happiness", title = "Happiness count ({happiness})") %>%
      end_layout_row() %>%
    end_layout_column() %>%
    add_layout_column(class = "five-right") %>%
      add_layout_row(class = "five-right-r1") %>%
        add_viz(type = "timeline", time_var = "year", y_var = "score", group_var = "happiness", title = "Score trend by happiness ({happiness})") %>%
      end_layout_row() %>%
      add_layout_row(class = "five-right-r2") %>%
        add_viz(type = "boxplot", x_var = "happiness", y_var = "income", title = "Income by happiness ({happiness})") %>%
      end_layout_row() %>%
    end_layout_column()
}

build_dashboard <- function(title, output_dir, backend, data, table_data, sidebar_title) {
  prepare_output_dir(output_dir)

  sidebar_layout_1 <- make_sidebar(
    title_prefix = paste0(sidebar_title, " - Trend"),
    sidebar_key = "l1",
    data = data,
    filters = c("region", "year")
  )

  sidebar_layout_2 <- make_sidebar(
    title_prefix = paste0(sidebar_title, " - Income"),
    sidebar_key = "l2",
    data = data,
    filters = c("year")
  )

  sidebar_layout_3 <- make_sidebar(
    title_prefix = paste0(sidebar_title, " - Comparison"),
    sidebar_key = "l3",
    data = data,
    filters = c("education")
  )

  sidebar_layout_4 <- make_sidebar(
    title_prefix = paste0(sidebar_title, " - Table"),
    sidebar_key = "l4",
    data = data,
    filters = c("year")
  )

  sidebar_layout_5 <- make_sidebar(
    title_prefix = paste0(sidebar_title, " - Deep Dive"),
    sidebar_key = "l5",
    data = data,
    filters = c("happiness")
  )

  create_dashboard(
    title = title,
    output_dir = output_dir,
    backend = backend,
    chart_export = TRUE
  ) %>%
    add_pages(
      layout_page_one_column(sidebar_layout_1, data),
      layout_page_explicit_one_column(sidebar_layout_2, data),
      layout_page_two_columns(sidebar_layout_3, data),
      layout_page_two_columns_footer(sidebar_layout_4, data, table_data),
      layout_page_two_columns_stacked(sidebar_layout_5, data)
    )
}

# -----------------------------------------------------------------------------
# Generate all backend dashboards
# -----------------------------------------------------------------------------

proj_echarts <- build_dashboard(
  title = "dashboardr 5-Layout Showcase (ECharts)",
  output_dir = "here",
  backend = "echarts4r",
  data = survey_data,
  table_data = analysis_table,
  sidebar_title = "ECharts Filters"
)
demo_open <- resolve_demo_open()

res_echarts <- generate_dashboard(proj_echarts, render = TRUE, open = demo_open)
cat("\nGenerated ECharts dashboard at:", normalizePath(res_echarts$output_dir, mustWork = FALSE), "\n")

proj_plotly <- build_dashboard(
  title = "dashboardr 5-Layout Showcase (Plotly)",
  output_dir = "here_plotly",
  backend = "plotly",
  data = survey_data,
  table_data = analysis_table,
  sidebar_title = "Plotly Filters"
)
res_plotly <- generate_dashboard(proj_plotly, render = TRUE, open = demo_open)
cat("\nGenerated Plotly dashboard at:", normalizePath(res_plotly$output_dir, mustWork = FALSE), "\n")

proj_hc <- build_dashboard(
  title = "dashboardr 5-Layout Showcase (Highcharter)",
  output_dir = "here_hc",
  backend = "highcharter",
  data = survey_data,
  table_data = analysis_table,
  sidebar_title = "Highcharter Filters"
)
res_hc <- generate_dashboard(proj_hc, render = TRUE, open = demo_open)
cat("\nGenerated Highcharter dashboard at:", normalizePath(res_hc$output_dir, mustWork = FALSE), "\n")

cat("\n=== All dashboards regenerated with 5 layouts ===\n")
