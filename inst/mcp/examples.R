# Curated example code snippets for the dashboardr MCP server.
# Each example is a named list element containing runnable R code as a string.
# Returned by .mcp_examples() in R/mcp_server.R.

list(

  basic_dashboard = '
library(dashboardr)
library(dplyr)

# Prepare data
data <- mtcars %>% mutate(cyl_label = paste(cyl, "cylinders"))

# LAYER 1: Content - what to show
charts <- create_content(data = data, type = "bar") %>%
  add_viz(x_var = "cyl_label", title = "Cylinders", tabgroup = "overview") %>%
  add_viz(x_var = "gear", title = "Gears", tabgroup = "overview")

# LAYER 2: Pages - where content lives
home <- create_page("Home", is_landing_page = TRUE) %>%
  add_text("# Car Dashboard", "", "Explore the mtcars dataset.")

analysis <- create_page("Analysis", data = data) %>%
  add_content(charts)

# LAYER 3: Dashboard - final output
create_dashboard(
  title = "Car Explorer",
  output_dir = "my_dashboard",
  theme = "flatly"
) %>%
  add_pages(home, analysis) %>%
  generate_dashboard(render = TRUE, open = "browser")
',

  bar_chart = '
library(dashboardr)
library(dplyr)

data <- mtcars %>% mutate(cyl_label = paste(cyl, "cyl"))

# Simple bar chart (counts)
charts <- create_content(data = data, type = "bar") %>%
  add_viz(x_var = "cyl_label", title = "Count by Cylinders")

# Grouped bar chart
charts_grouped <- create_content(data = data, type = "bar") %>%
  add_viz(
    x_var = "cyl_label",
    group_var = "am",
    title = "Cylinders by Transmission",
    bar_type = "percent"
  )

# Horizontal bar chart sorted by value
charts_horiz <- create_content(data = data, type = "bar") %>%
  add_viz(
    x_var = "cyl_label",
    title = "Cylinders (Horizontal)",
    horizontal = TRUE,
    sort_by_value = TRUE
  )

# Preview without generating full dashboard
preview(charts)
',

  multi_chart = '
library(dashboardr)
library(dplyr)

data <- iris

# Multiple chart types in one collection using tabgroups
charts <- create_content(data = data, type = "bar") %>%
  add_viz(x_var = "Species", title = "Species Count",
          tabgroup = "overview") %>%
  add_viz(x_var = "Species", value_var = "Sepal.Length",
          bar_type = "mean", title = "Mean Sepal Length",
          tabgroup = "overview")

histograms <- create_content(data = data, type = "histogram") %>%
  add_viz(x_var = "Sepal.Length", title = "Sepal Length Distribution",
          tabgroup = "distributions") %>%
  add_viz(x_var = "Petal.Length", title = "Petal Length Distribution",
          tabgroup = "distributions")

scatter <- create_content(data = data, type = "scatter") %>%
  add_viz(x_var = "Sepal.Length", y_var = "Petal.Length",
          group_var = "Species", title = "Sepal vs Petal Length")

# Combine all content
all_content <- combine_content(charts, histograms, scatter)

page <- create_page("Analysis", data = data) %>%
  add_content(all_content)

create_dashboard(title = "Iris Explorer", output_dir = "iris_dashboard") %>%
  add_page(page) %>%
  generate_dashboard(render = TRUE)
',

  inputs_filters = '
library(dashboardr)
library(dplyr)

data <- mtcars %>%
  mutate(
    cyl_label = paste(cyl, "cylinders"),
    trans = ifelse(am == 0, "Automatic", "Manual")
  )

# Create charts with filter_var for interactivity
charts <- create_content(data = data, type = "bar") %>%
  add_viz(
    x_var = "cyl_label",
    title = "By Cylinders",
    filter_var = "trans",
    tabgroup = "cars"
  ) %>%
  add_viz(
    x_var = "gear",
    title = "By Gears",
    filter_var = "trans",
    tabgroup = "cars"
  )

# Build page with input filters
page <- create_page("Cars", data = data) %>%
  add_input(
    input_id = "trans",
    label = "Transmission",
    choices = c("Automatic", "Manual"),
    type = "dropdown"
  ) %>%
  add_reset_button() %>%
  add_content(charts)

create_dashboard(
  title = "Car Filters",
  output_dir = "filter_dashboard"
) %>%
  add_page(page) %>%
  generate_dashboard(render = TRUE)
',

  sidebar = '
library(dashboardr)
library(dplyr)

data <- mtcars %>%
  mutate(
    cyl_label = paste(cyl, "cylinders"),
    trans = ifelse(am == 0, "Automatic", "Manual")
  )

charts <- create_content(data = data, type = "bar") %>%
  add_viz(
    x_var = "cyl_label", title = "Cylinders",
    filter_var = "trans", tabgroup = "analysis"
  ) %>%
  add_viz(
    x_var = "gear", title = "Gears",
    filter_var = "trans", tabgroup = "analysis"
  )

# Page with sidebar containing filters
page <- create_page("Explorer", data = data) %>%
  add_sidebar() %>%
    add_input(
      input_id = "trans",
      label = "Transmission",
      choices = c("Automatic", "Manual"),
      type = "dropdown"
    ) %>%
    add_reset_button() %>%
  end_sidebar() %>%
  add_content(charts)

create_dashboard(
  title = "Sidebar Dashboard",
  output_dir = "sidebar_dashboard"
) %>%
  add_page(page) %>%
  generate_dashboard(render = TRUE)
',

  value_boxes = '
library(dashboardr)
library(dplyr)

data <- mtcars

# Page with value boxes at the top
page <- create_page("Overview", data = data) %>%
  add_value_box_row() %>%
    add_value_box(
      title = "Total Cars",
      value = nrow(data),
      icon = "mdi:car",
      color = "#2196F3"
    ) %>%
    add_value_box(
      title = "Avg MPG",
      value = round(mean(data$mpg), 1),
      icon = "mdi:fuel",
      color = "#4CAF50"
    ) %>%
    add_value_box(
      title = "Max HP",
      value = max(data$hp),
      icon = "mdi:speedometer",
      color = "#FF9800"
    ) %>%
  end_value_box_row() %>%
  add_content(
    create_content(data = data, type = "bar") %>%
      add_viz(x_var = "cyl", title = "Cylinders")
  )

create_dashboard(title = "KPI Dashboard", output_dir = "kpi_dashboard") %>%
  add_page(page) %>%
  generate_dashboard(render = TRUE)
',

  multi_page = '
library(dashboardr)
library(dplyr)

data <- mtcars %>%
  mutate(
    cyl_label = paste(cyl, "cylinders"),
    trans = ifelse(am == 0, "Automatic", "Manual")
  )

# Landing page with text
home <- create_page("Home", is_landing_page = TRUE) %>%
  add_text(
    "# My Dashboard",
    "",
    "Welcome to the multi-page dashboard.",
    "",
    "Use the navigation bar above to explore different analyses."
  )

# Analysis page with charts
analysis <- create_page("Analysis", data = data) %>%
  add_content(
    create_content(data = data, type = "bar") %>%
      add_viz(x_var = "cyl_label", title = "Cylinders",
              tabgroup = "charts") %>%
      add_viz(x_var = "gear", title = "Gears",
              tabgroup = "charts")
  )

# Distribution page
distributions <- create_page("Distributions", data = data) %>%
  add_content(
    create_content(data = data, type = "histogram") %>%
      add_viz(x_var = "mpg", title = "MPG Distribution",
              tabgroup = "dist") %>%
      add_viz(x_var = "hp", title = "Horsepower Distribution",
              tabgroup = "dist")
  )

create_dashboard(
  title = "Multi-Page Dashboard",
  output_dir = "multipage_dashboard",
  theme = "cosmo"
) %>%
  add_pages(home, analysis, distributions) %>%
  generate_dashboard(render = TRUE)
',

  stacked_bars = '
library(dashboardr)
library(dplyr)

data <- mtcars %>%
  mutate(
    cyl_label = paste(cyl, "cylinders"),
    trans = ifelse(am == 0, "Automatic", "Manual")
  )

# Crosstab stacked bar: x_var + stack_var
charts <- create_content(data = data, type = "stackedbar") %>%
  add_viz(
    x_var = "cyl_label",
    stack_var = "trans",
    title = "Transmission by Cylinders",
    percent = TRUE
  )

# For survey-style Likert data, use x_vars for multi-variable stacked bars
# survey_data <- data.frame(...)
# survey_charts <- create_content(data = survey_data, type = "stackedbar") %>%
#   add_viz(x_vars = c("q1", "q2", "q3"), title = "Survey Responses")

preview(charts)
',

  tables = '
library(dashboardr)
library(dplyr)

data <- mtcars %>%
  mutate(car = rownames(mtcars)) %>%
  select(car, mpg, cyl, hp, wt)

# Simple HTML table
page_simple <- create_page("Simple Table") %>%
  add_content(
    create_content(data = data) %>%
      add_table(title = "Car Data")
  )

# reactable table (interactive, sortable, searchable)
# Requires: install.packages("reactable")
page_react <- create_page("Interactive Table") %>%
  add_content(
    create_content(data = data) %>%
      add_reactable(title = "Car Data (Interactive)")
  )

# gt table (publication-quality)
# Requires: install.packages("gt")
page_gt <- create_page("GT Table") %>%
  add_content(
    create_content(data = head(data, 10)) %>%
      add_gt(title = "Top 10 Cars")
  )

create_dashboard(title = "Tables Demo", output_dir = "tables_dashboard") %>%
  add_pages(page_simple, page_react, page_gt) %>%
  generate_dashboard(render = TRUE)
',

  custom_layout = '
library(dashboardr)
library(dplyr)

data <- mtcars %>% mutate(cyl_label = paste(cyl, "cyl"))

# Manual layout with columns and rows for precise control
page <- create_page("Custom Layout", data = data) %>%
  add_layout_column(width = 8) %>%
    add_content(
      create_content(data = data, type = "bar") %>%
        add_viz(x_var = "cyl_label", title = "Main Chart")
    ) %>%
  end_layout_column() %>%
  add_layout_column(width = 4) %>%
    add_text("## Sidebar Info", "", "This column is narrower.") %>%
    add_content(
      create_content(data = data, type = "pie") %>%
        add_viz(x_var = "cyl_label", title = "Proportions")
    ) %>%
  end_layout_column()

create_dashboard(title = "Custom Layout", output_dir = "layout_dashboard") %>%
  add_page(page) %>%
  generate_dashboard(render = TRUE)
',

  modals = '
library(dashboardr)
library(dplyr)

data <- mtcars %>% mutate(cyl_label = paste(cyl, "cyl"))

# Add modals for drill-down or supplementary information
page <- create_page("With Modals", data = data) %>%
  add_content(
    create_content(data = data, type = "bar") %>%
      add_viz(x_var = "cyl_label", title = "Cylinders") %>%
      add_modal(
        id = "methods",
        title = "Methodology",
        body = "This chart shows cylinder counts from the mtcars dataset."
      )
  )

create_dashboard(title = "Modal Demo", output_dir = "modal_dashboard") %>%
  add_page(page) %>%
  generate_dashboard(render = TRUE)
'

)
