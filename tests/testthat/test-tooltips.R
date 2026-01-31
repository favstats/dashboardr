# Test: Tooltip System
# Tests for the unified tooltip API across all chart types

test_that("tooltip() creates correct structure", {
  # Basic tooltip
  tt <- tooltip()
  expect_s3_class(tt, "dashboardr_tooltip")
  expect_true(tt$enabled)
  expect_false(tt$shared)
  
  # With format string
  tt <- tooltip(format = "{category}: {value}")
  expect_equal(tt$format, "{category}: {value}")
  
  # With prefix/suffix
  tt <- tooltip(prefix = "$", suffix = " USD")
  expect_equal(tt$prefix, "$")
  expect_equal(tt$suffix, " USD")
  
  # With styling
  tt <- tooltip(
    backgroundColor = "#fff",
    borderColor = "#ccc",
    borderRadius = 10,
    style = list(fontSize = "14px")
  )
  expect_equal(tt$backgroundColor, "#fff")
  expect_equal(tt$borderColor, "#ccc")
  expect_equal(tt$borderRadius, 10)
  expect_equal(tt$style$fontSize, "14px")
  
  # With shared tooltip
  tt <- tooltip(shared = TRUE)
  expect_true(tt$shared)
  
  # Disabled tooltip
  tt <- tooltip(enabled = FALSE)
  expect_false(tt$enabled)
})

test_that("is_tooltip() correctly identifies tooltip objects", {
  tt <- tooltip()
  expect_true(dashboardr:::is_tooltip(tt))
  expect_false(dashboardr:::is_tooltip(list()))
  expect_false(dashboardr:::is_tooltip("string"))
  expect_false(dashboardr:::is_tooltip(NULL))
})

test_that("print.dashboardr_tooltip works", {
  tt <- tooltip(format = "{value}%", backgroundColor = "#fff")
  output <- capture.output(print(tt))
  expect_true(any(grepl("dashboardr_tooltip", output)))
  expect_true(any(grepl("format:", output)))
})

test_that(".process_tooltip_config handles Tier 1 (prefix/suffix)", {
  result <- dashboardr:::.process_tooltip_config(
    tooltip = NULL,
    tooltip_prefix = "Count: ",
    tooltip_suffix = " items",
    x_tooltip_suffix = NULL,
    chart_type = "bar",
    context = list(bar_type = "count", is_grouped = FALSE, total_value = 100)
  )
  
  expect_type(result, "list")
  expect_true("formatter_js" %in% names(result))
  expect_true("options" %in% names(result))
  expect_true(result$options$useHTML)
})

test_that(".process_tooltip_config handles Tier 2 (format string)", {
  result <- dashboardr:::.process_tooltip_config(
    tooltip = "{category}: {value}",
    tooltip_prefix = NULL,
    tooltip_suffix = NULL,
    x_tooltip_suffix = NULL,
    chart_type = "bar",
    context = list()
  )
  
  expect_type(result, "list")
  expect_true(!is.null(result$formatter_js))
  expect_true(grepl("\\{category\\}", result$formatter_js))
  expect_true(grepl("\\{value\\}", result$formatter_js))
})

test_that(".process_tooltip_config handles Tier 3 (tooltip() object)", {
  tt <- tooltip(
    format = "{value}%",
    backgroundColor = "#f5f5f5",
    borderRadius = 8
  )
  
  result <- dashboardr:::.process_tooltip_config(
    tooltip = tt,
    tooltip_prefix = NULL,
    tooltip_suffix = NULL,
    x_tooltip_suffix = NULL,
    chart_type = "bar",
    context = list()
  )
  
  expect_type(result, "list")
  expect_equal(result$options$backgroundColor, "#f5f5f5")
  expect_equal(result$options$borderRadius, 8)
})

test_that("viz_bar accepts tooltip parameter", {
  skip_if_not_installed("highcharter")
  
  data <- data.frame(category = c("A", "A", "B", "B", "B", "C"))
  
  # Tier 1: prefix/suffix
  p1 <- viz_bar(data, x_var = "category", tooltip_suffix = "%")
  expect_s3_class(p1, "highchart")
  expect_true(!is.null(p1$x$hc_opts$tooltip))
  
  # Tier 2: format string
  p2 <- viz_bar(data, x_var = "category", tooltip = "{category}: {value}")
  expect_s3_class(p2, "highchart")
  expect_true(!is.null(p2$x$hc_opts$tooltip$formatter))
  
  # Tier 3: tooltip() config
  p3 <- viz_bar(data, x_var = "category", 
                tooltip = tooltip(format = "{value}", backgroundColor = "#fff"))
  expect_s3_class(p3, "highchart")
  expect_equal(p3$x$hc_opts$tooltip$backgroundColor, "#fff")
})

test_that("viz_scatter accepts tooltip parameter", {
  skip_if_not_installed("highcharter")
  
  data <- data.frame(x = 1:10, y = rnorm(10))
  
  # Tier 2: format string
  p <- viz_scatter(data, x_var = "x", y_var = "y", 
                   tooltip = "{x}: {y}")
  expect_s3_class(p, "highchart")
  expect_true(!is.null(p$x$hc_opts$tooltip$formatter))
  
  # Tier 3: tooltip() config with styling
  p2 <- viz_scatter(data, x_var = "x", y_var = "y",
                    tooltip = tooltip(backgroundColor = "#f0f0f0"))
  expect_equal(p2$x$hc_opts$tooltip$backgroundColor, "#f0f0f0")
})

test_that("viz_histogram accepts tooltip parameter", {
  skip_if_not_installed("highcharter")
  
  data <- data.frame(value = rnorm(100))
  
  # With tooltip config
  p <- viz_histogram(data, x_var = "value", 
                     tooltip = tooltip(format = "Count: {value}"))
  expect_s3_class(p, "highchart")
  expect_true(!is.null(p$x$hc_opts$tooltip))
})

test_that("viz_stackedbar accepts tooltip parameter", {
  skip_if_not_installed("highcharter")
  
  data <- data.frame(
    x = rep(c("A", "B"), each = 20),
    stack = sample(c("Low", "High"), 40, replace = TRUE)
  )
  
  p <- viz_stackedbar(data, x_var = "x", stack_var = "stack",
                      tooltip = tooltip(shared = TRUE))
  expect_s3_class(p, "highchart")
})

test_that("viz_heatmap accepts tooltip parameter", {
  skip_if_not_installed("highcharter")
  
  data <- expand.grid(x = 1:3, y = 1:3)
  data$value <- runif(9)
  
  p <- viz_heatmap(data, x_var = "x", y_var = "y", value_var = "value",
                   tooltip = tooltip(format = "Value: {value}"))
  expect_s3_class(p, "highchart")
})

test_that("viz_boxplot accepts tooltip parameter", {
  skip_if_not_installed("highcharter")
  
  data <- data.frame(
    group = rep(c("A", "B"), each = 50),
    value = c(rnorm(50, 10), rnorm(50, 15))
  )
  
  p <- viz_boxplot(data, y_var = "value", x_var = "group",
                   tooltip_suffix = " units")
  expect_s3_class(p, "highchart")
  expect_true(!is.null(p$x$hc_opts$tooltip))
})

test_that("viz_density accepts tooltip parameter", {
  skip_if_not_installed("highcharter")
  
  data <- data.frame(value = rnorm(100))
  
  p <- viz_density(data, x_var = "value",
                   tooltip = tooltip(format = "Density: {y}"))
  expect_s3_class(p, "highchart")
})

test_that("viz_treemap accepts tooltip parameter", {
  skip_if_not_installed("highcharter")
  
  data <- data.frame(
    group = c("A", "B", "C"),
    value = c(100, 200, 150)
  )
  
  p <- viz_treemap(data, group_var = "group", value_var = "value",
                   tooltip = tooltip(format = "{name}: {value}"))
  expect_s3_class(p, "highchart")
})

test_that("viz_timeline accepts tooltip parameter", {
  skip_if_not_installed("highcharter")
  
  data <- data.frame(
    year = rep(2020:2022, each = 100),
    response = sample(c("Yes", "No"), 300, replace = TRUE)
  )
  
  p <- viz_timeline(data, time_var = "year", y_var = "response",
                    tooltip_suffix = "%")
  expect_s3_class(p, "highchart")
  expect_true(!is.null(p$x$hc_opts$tooltip))
})

test_that("backwards compatibility: legacy parameters still work", {
  skip_if_not_installed("highcharter")
  
  data <- data.frame(category = c("A", "A", "B", "B", "C"))
  
  # Old-style prefix/suffix should still work
 p <- viz_bar(data, x_var = "category",
               tooltip_prefix = "N = ",
               tooltip_suffix = " items")
  expect_s3_class(p, "highchart")
  expect_true(!is.null(p$x$hc_opts$tooltip))
  
  # tooltip_format in scatter should still work
  data2 <- data.frame(x = 1:5, y = 1:5)
  p2 <- viz_scatter(data2, x_var = "x", y_var = "y",
                    tooltip_format = "<b>X:</b> {point.x}")
  expect_s3_class(p2, "highchart")
})

test_that("tooltip parameter takes precedence over legacy params", {
  skip_if_not_installed("highcharter")
  
  data <- data.frame(category = c("A", "A", "B", "B", "C"))
  
  # When both are provided, tooltip should win
  p <- viz_bar(data, x_var = "category",
               tooltip = tooltip(backgroundColor = "#custom"),
               tooltip_prefix = "ignored",
               tooltip_suffix = "ignored")
  
  expect_equal(p$x$hc_opts$tooltip$backgroundColor, "#custom")
})
