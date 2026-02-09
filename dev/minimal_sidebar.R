library(tidyverse)
devtools::load_all()

set.seed(20260210)

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
    score = rnorm(n(), 75, 10),
    income = rnorm(n(), 50000, 15000)
  )

scatter_data <- base_data %>%
  slice_sample(n = 800)

pie_data <- base_data %>%
  count(region, education, happiness, name = "n")

boxplot_data <- base_data %>%
  select(year, region, education, income, score)

education_palette <- c(
  "High School" = "#4E79A7",
  "Some College" = "#59A14F",
  "Bachelor's" = "#F28E2B",
  "Graduate" = "#E15759"
)

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
    end_sidebar() %>%
    add_viz(
      type = "bar",
      x_var = "region",
      group_var = "education",
      color_palette = unname(education_palette),
      title = "Responses by region and education"
    )
}

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
    end_sidebar() %>%
    add_viz(
      type = "pie",
      x_var = "region",
      color_palette = unname(region_palette),
      title = "Distribution by region"
    )
}

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
    end_sidebar() %>%
    add_viz(
      type = "scatter",
      x_var = "age",
      y_var = "score",
      color_var = "region",
      color_palette = unname(region_palette),
      title = "Score vs Age by region"
    )
}

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
    end_sidebar() %>%
    add_viz(
      type = "boxplot",
      x_var = "education",
      y_var = "income",
      group_var = "region",
      color_palette = unname(region_palette),
      title = "Income distribution by education"
    )
}

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
    add_viz(
      type = "bar",
      x_var = "region",
      group_var = "happiness",
      color_palette = unname(happiness_palette),
      title = "Region by happiness level"
    )
}


build_single_graph_dashboard <- function(title, output_dir, backend, sidebar_label) {
  if (dir.exists(output_dir)) {
    unlink(output_dir, recursive = TRUE, force = TRUE)
  }

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
      page_s5(base_data, paste0(sidebar_label, " - S5"))
    )
}

proj_echarts <- build_single_graph_dashboard(
  title = "Sidebar Single Graph (echarts4r)",
  output_dir = "sidebar_single_echarts",
  backend = "echarts4r",
  sidebar_label = "ECharts"
)
res_echarts <- generate_dashboard(proj_echarts, render = TRUE, open = FALSE)
cat("\nGenerated echarts4r sidebar-single-graph at:", normalizePath(res_echarts$output_dir, mustWork = FALSE), "\n")