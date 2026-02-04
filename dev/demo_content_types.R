# ============================================================================
# Demo: Tables and Custom Charts in dashboardr
# ============================================================================
# This script demonstrates add_gt, add_reactable, add_DT, add_table, and add_hc
# in a full dashboard

devtools::load_all()
library(highcharter)
library(gt)
library(reactable)
library(DT)

# Sample data
sample_data <- data.frame(
  name = c("Alice", "Bob", "Charlie", "Diana", "Eve"),
  age = c(25, 30, 35, 28, 42),
  score = c(85, 92, 78, 95, 88)
)

# ============================================================================
# Page 1: Tables
# ============================================================================

tables_content <- create_content() %>%
  add_text("This page demonstrates different table types.") %>%

  # GT Table
  add_text("### GT Table") %>%
  add_gt(
    gt::gt(sample_data) %>%
      gt::tab_header(title = "Sample Data") %>%
      gt::cols_label(name = "Name", age = "Age", score = "Score"),
    tabgroup = "GT"
  ) %>%

  # Reactable
  add_text("### Reactable Table") %>%
  add_reactable(
    reactable::reactable(sample_data, searchable = TRUE, striped = TRUE),
    tabgroup = "Reactable"
  ) %>%

  # DT
  add_text("### DT DataTable???") %>%
  add_DT(sample_data, options = list(pageLength = 5), tabgroup = "DT") %>%

  # Basic Table
  add_text("### Basic Table") %>%
  add_table(sample_data, caption = "Simple HTML table", tabgroup = "Basic")

tables_page <- create_page("Tables") %>%
  add_content(tables_content)

preview(tables_content)

# ============================================================================
# Page 2: Custom Charts
# ============================================================================

# Pie chart (not available via add_viz)
pie_chart <- highchart() %>%
  hc_chart(type = "pie") %>%
  hc_title(text = "Score Distribution") %>%
  hc_add_series(
    name = "Score",
    data = lapply(1:nrow(sample_data), function(i) {
      list(name = sample_data$name[i], y = sample_data$score[i])
    })
  ) %>%
  hc_plotOptions(pie = list(
    dataLabels = list(enabled = TRUE, format = "{point.name}: {point.percentage:.1f}%")
  ))

# Column chart
column_chart <- highchart() %>%
  hc_chart(type = "column") %>%
  hc_title(text = "Scores by Person") %>%
  hc_xAxis(categories = sample_data$name) %>%
  hc_add_series(name = "Score", data = sample_data$score, colorByPoint = TRUE)

charts_content <- create_content() %>%
  add_text("Custom Highcharter charts that go beyond add_viz().") %>%
  add_hc(pie_chart, tabgroup = "Pie Chart") %>%
  add_hc(column_chart, tabgroup = "Column Chart")

charts_page <- create_page("Custom Charts") %>%
  add_content(charts_content)

# ============================================================================
# Page 3: Pre-aggregated Data
# ============================================================================

# Timeline data
yearly_metrics <- data.frame(
  year = c(2020, 2021, 2022, 2023),
  value = c(1250, 1380, 1420, 1510)
)

# Heatmap data
heatmap_data <- data.frame(
  var1 = rep(c("A", "B", "C"), each = 3),
  var2 = rep(c("X", "Y", "Z"), 3),
  correlation = c(1.0, 0.5, 0.3, 0.5, 1.0, 0.7, 0.3, 0.7, 1.0)
)

# Treemap data
budget_data <- data.frame(
  category = c("Marketing", "Engineering", "Operations", "HR", "Sales"),
  amount = c(50000, 120000, 45000, 30000, 80000)
)

# Bar chart data (pre-aggregated)
country_stats <- data.frame(
  country = c("USA", "Germany", "France", "UK", "Japan"),
  population = c(331, 83, 67, 67, 126)
)

preagg_content <- create_content(data = yearly_metrics) %>%
  add_viz(
    type = "timeline",
    time_var = "year",
    y_var = "value",
    agg = "none",
    title = "Yearly Trend (agg = 'none')",
    tabgroup = "Timeline"
  ) %>%
  add_viz(
    type = "heatmap",
    x_var = "var1",
    y_var = "var2",
    value_var = "correlation",
    pre_aggregated = TRUE,
    title = "Correlation Matrix (pre_aggregated = TRUE)",
    data_labels_enabled = TRUE,
    color_min = 0,
    color_max = 1,
    tabgroup = "Heatmap",
    data = heatmap_data  # Each viz can have its own data
  ) %>%
  add_viz(
    type = "treemap",
    group_var = "category",
    value_var = "amount",
    pre_aggregated = TRUE,
    title = "Budget by Department (pre_aggregated = TRUE)",
    tabgroup = "Treemap",
    data = budget_data  # Each viz can have its own data
  ) %>%
  add_viz(
    type = "bar",
    x_var = "country",
    y_var = "population",
    title = "Population by Country (y_var)",
    tabgroup = "Bar Chart",
    data = country_stats  # Each viz can have its own data
  )

preagg_page <- create_page("Pre-aggregated") %>%
  add_content(preagg_content)

# ============================================================================
# Page 4: Mixed Content
# ============================================================================

mixed_content <- create_content() %>%
  add_text("# Mixed Content Page") %>%
  add_text("This page shows tables and charts together.") %>%
  add_callout("This is a callout note!", type = "note", title = "Note") %>%
  add_divider() %>%
  add_gt(gt::gt(head(sample_data, 3))) %>%
  add_divider() %>%
  add_hc(
    highchart() %>%
      hc_chart(type = "bar") %>%
      hc_xAxis(categories = sample_data$name) %>%
      hc_add_series(name = "Age", data = sample_data$age)
  ) %>%
  add_text("**Above:** A simple bar chart showing ages.")

mixed_page <- create_page("Mixed") %>%
  add_content(mixed_content)

preview(tables_page)

# ============================================================================
# Generate Dashboard
# ============================================================================

output_dir <- "/Users/favstats/Dropbox/postdoc/content_types_demo"
cat("Generating dashboard to:", output_dir, "\n")

create_dashboard(
  title = "Content Types Demo",
  output_dir = output_dir
) %>%
  add_page(tables_page) %>%
  add_page(charts_page) %>%
  add_page(preagg_page) %>%
  add_page(mixed_page) %>%
  generate_dashboard()

cat("\n=== Dashboard generated! ===\n")
cat("Output directory:", output_dir, "\n")
cat("\nTo render:\n")
cat("  cd", output_dir, "\n")
cat("  quarto render\n")
