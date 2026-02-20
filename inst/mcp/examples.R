# =================================================================
# examples.R — Curated code snippets for the dashboardr MCP server
# =================================================================
#
# Each named list element is a runnable R code string returned by
# .mcp_examples() in R/mcp_server.R when an LLM calls the
# dashboardr_example tool.
#
# Organisation:
#   1. basic_dashboard   — Minimal 3-layer example (start here)
#   2. bar_chart         — Bar chart variants (count, grouped, horizontal)
#   3. multi_chart       — Multiple chart types + combine_content
#   4. inputs_filters    — Client-side data filtering with inputs
#   5. sidebar           — Sidebar layout with filters
#   6. value_boxes       — KPI value boxes at the top of a page
#   7. multi_page        — Multi-page navigation with landing page
#   8. stacked_bars      — Stacked bar charts (crosstab + Likert)
#   9. tables            — HTML, reactable, and gt tables
#  10. custom_layout     — Manual column/row layout (Bootstrap grid)
#  11. modals            — Modal dialogs attached to charts
#
# To add a new example:
#   1. Add a new named element to the list below
#   2. Add the pattern name to .tool_example()'s type_enum values in mcp_server.R
#   3. The code string should be fully self-contained and runnable
# =================================================================

list(

  # ── 1. basic_dashboard ─────────────────────────────────────────────────
  # The canonical "hello world" for dashboardr. Demonstrates all 3 layers:
  # Content (create_content + add_viz) → Page (create_page) → Dashboard.
  # Best starting point for users new to dashboardr.

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

  # ── 2. bar_chart ───────────────────────────────────────────────────────
  # Shows 3 common bar chart variations: simple counts, grouped bars with
  # percentages, and horizontal bars sorted by value. Also demonstrates
  # preview() for quick testing without generating a full dashboard.

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

  # ── 3. multi_chart ─────────────────────────────────────────────────────
  # Demonstrates mixing chart types (bar, histogram, scatter) across
  # multiple content collections, using tabgroups for tabbed panels,
  # and combine_content() to merge them onto a single page.

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

  # ── 4. inputs_filters ──────────────────────────────────────────────────
  # Demonstrates client-side data filtering. Key pattern: the input_id
  # ("trans") must match the filter_var on the charts, and "trans" must
  # be an actual column in the data. This enables interactive filtering
  # without server-side code.

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

  # ── 5. sidebar ─────────────────────────────────────────────────────────
  # Like inputs_filters but with filters placed in a sidebar panel.
  # add_sidebar() / end_sidebar() wraps inputs in a left-side panel,
  # with chart content in the main area.

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

  # ── 6. value_boxes ─────────────────────────────────────────────────────
  # KPI-style value boxes at the top of a page. Uses add_value_box_row()
  # to create a horizontal row of metric cards with icons and colours.
  # Icons use iconify format ("collection:name").

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

  # ── 7. multi_page ──────────────────────────────────────────────────────
  # Multi-page dashboard with navbar navigation. Pages appear as tabs.
  # The landing page (is_landing_page = TRUE) is text-only and doesn't
  # need a data argument. Other pages each have their own content.

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

  # ── 8. stacked_bars ────────────────────────────────────────────────────
  # Stacked bar charts for crosstabs and survey Likert scales.
  # Two modes: x_var + stack_var (crosstab of two categorical columns)
  # or x_vars (multiple survey items stacked together).

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

  # ── 9. tables ──────────────────────────────────────────────────────────
  # Three table backends: plain HTML (add_table), interactive reactable
  # (sortable, searchable), and publication-quality gt. reactable and gt
  # require their respective packages to be installed.

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

  # ── 10. custom_layout ──────────────────────────────────────────────────
  # Manual column/row layout using Bootstrap's 12-column grid.
  # add_layout_column(width = N) where N is the number of grid columns
  # (e.g., 8 + 4 = 12 for a 2/3 + 1/3 split).

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

  # ── 11. modals ─────────────────────────────────────────────────────────
  # Modal dialogs for supplementary information (methodology notes,
  # data sources, etc.). Attached to a content collection via add_modal().
  # A button appears next to the chart that opens the modal on click.

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
