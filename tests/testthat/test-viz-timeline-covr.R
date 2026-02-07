# Tests for viz_timeline — lightweight, covr-safe
# Targets uncovered branches: chart_type, agg modes (mean, sum, none, percentage),
# y_levels, y_map_values, stacked_area, title/labels, color_palette, y_max/y_min
library(testthat)

test_that("viz_timeline basic line chart with percentage aggregation", {
  df <- data.frame(
    year = rep(2020:2023, each = 20),
    response = sample(c("Yes", "No"), 80, replace = TRUE)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "response")
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline with agg = 'none' simple line", {
  df <- data.frame(
    year = 2020:2023,
    score = c(50, 55, 48, 62)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "score", agg = "none")
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline with agg = 'none' (pre-aggregated)", {
  df <- data.frame(
    year = 2020:2023,
    value = c(10, 20, 15, 25)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "value", agg = "none")
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline stacked_area chart_type", {
  df <- data.frame(
    year = rep(2020:2023, each = 30),
    response = sample(c("A", "B", "C"), 120, replace = TRUE)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "response",
                     chart_type = "stacked_area")
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline with group_var percentage", {
  df <- data.frame(
    year = rep(2020:2023, each = 20),
    response = sample(c("Yes", "No"), 80, replace = TRUE),
    country = rep(c("US", "UK"), 40)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "response",
                     group_var = "country")
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline with y_levels", {
  df <- data.frame(
    year = rep(2020:2023, each = 20),
    response = sample(c("Low", "Medium", "High"), 80, replace = TRUE)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "response",
                     y_levels = c("Low", "Medium", "High"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline with y_map_values", {
  df <- data.frame(
    year = rep(2020:2023, each = 20),
    response = sample(c("1", "0"), 80, replace = TRUE)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "response",
                     y_map_values = list("1" = "Correct", "0" = "Incorrect"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline with y_filter and y_filter_combine", {
  df <- data.frame(
    year = rep(2020:2023, each = 20),
    score = sample(1:7, 80, replace = TRUE)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "score",
                     y_filter = 5:7, y_filter_combine = TRUE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline with y_filter_combine FALSE", {
  df <- data.frame(
    year = rep(2020:2023, each = 20),
    score = sample(1:7, 80, replace = TRUE)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "score",
                     y_filter = 5:7, y_filter_combine = FALSE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline with y_filter_label", {
  df <- data.frame(
    year = rep(2020:2023, each = 20),
    score = sample(1:7, 80, replace = TRUE)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "score",
                     y_filter = 5:7, y_filter_combine = TRUE,
                     y_filter_label = "Top scores (5-7)")
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline with y_breaks and y_bin_labels", {
  df <- data.frame(
    year = rep(2020:2023, each = 20),
    score = sample(1:7, 80, replace = TRUE)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "score",
                     y_breaks = c(0.5, 4.5, 7.5),
                     y_bin_labels = c("Low (1-4)", "High (5-7)"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline with title, x_label, y_label", {
  df <- data.frame(
    year = rep(2020:2023, each = 20),
    response = sample(c("A", "B"), 80, replace = TRUE)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "response",
                     title = "Trend", x_label = "Year", y_label = "Percentage")
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline with color_palette", {
  df <- data.frame(
    year = rep(2020:2023, each = 20),
    response = sample(c("A", "B"), 80, replace = TRUE)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "response",
                     color_palette = c("#ff0000", "#0000ff"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline with y_max and y_min", {
  df <- data.frame(
    year = rep(2020:2023, each = 20),
    response = sample(c("A", "B"), 80, replace = TRUE)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "response",
                     y_min = 0, y_max = 100)
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline with time_breaks and time_bin_labels", {
  df <- data.frame(
    year = rep(2000:2023, each = 10),
    response = sample(c("A", "B", "C"), 240, replace = TRUE)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "response",
                     time_breaks = c(2000, 2010, 2020, 2024),
                     time_bin_labels = c("2000s", "2010s", "2020s"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline percentage with group_var and y_filter", {
  df <- data.frame(
    year = rep(2020:2023, each = 40),
    score = sample(1:7, 160, replace = TRUE),
    group = rep(c("M", "F"), 80)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "score",
                     group_var = "group",
                     y_filter = 5:7, y_filter_combine = TRUE)
  expect_s3_class(hc, "highchart")
})

# --- agg = "mean" tests (previously broken due to summarize/summarise mismatch) ---

test_that("viz_timeline with agg = 'mean' without group_var", {
  df <- data.frame(
    year = rep(2020:2023, each = 10),
    score = rnorm(40, mean = 50, sd = 10)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "score", agg = "mean")
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline with agg = 'mean' with group_var", {
  df <- data.frame(
    year = rep(2020:2023, each = 20),
    score = rnorm(80, mean = 50, sd = 10),
    country = rep(c("US", "UK"), 40)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "score",
                     group_var = "country", agg = "mean")
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline with agg = 'mean' and title/labels", {
  df <- data.frame(
    year = rep(2020:2023, each = 10),
    value = rnorm(40, 50, 10)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "value",
                     agg = "mean",
                     title = "Average Score", x_label = "Year", y_label = "Mean Value")
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline with agg = 'mean' and y_min/y_max", {
  df <- data.frame(
    year = rep(2020:2023, each = 10),
    value = rnorm(40, 50, 10)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "value",
                     agg = "mean", y_min = 0, y_max = 100)
  expect_s3_class(hc, "highchart")
})

# --- agg = "sum" tests ---

test_that("viz_timeline with agg = 'sum' without group_var", {
  df <- data.frame(
    year = rep(2020:2023, each = 5),
    count = rpois(20, lambda = 10)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "count", agg = "sum")
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline with agg = 'sum' with group_var", {
  df <- data.frame(
    year = rep(2020:2023, each = 10),
    count = rpois(40, lambda = 10),
    region = rep(c("East", "West"), 20)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "count",
                     group_var = "region", agg = "sum")
  expect_s3_class(hc, "highchart")
})

# --- weight_var tests ---

test_that("viz_timeline percentage with weight_var", {
  df <- data.frame(
    year = rep(2020:2023, each = 20),
    response = sample(c("Yes", "No"), 80, replace = TRUE),
    weight = runif(80, 0.5, 2.0)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "response",
                     weight_var = "weight")
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline percentage with weight_var and group_var", {
  df <- data.frame(
    year = rep(2020:2023, each = 20),
    response = sample(c("Yes", "No"), 80, replace = TRUE),
    group = rep(c("A", "B"), 40),
    weight = runif(80, 0.5, 2.0)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "response",
                     group_var = "group", weight_var = "weight")
  expect_s3_class(hc, "highchart")
})

# --- agg = "none" with group_var ---

test_that("viz_timeline with agg = 'none' and group_var", {
  df <- data.frame(
    year = rep(2020:2023, 2),
    value = c(10, 20, 15, 25, 12, 18, 22, 28),
    series = rep(c("A", "B"), each = 4)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "value",
                     group_var = "series", agg = "none")
  expect_s3_class(hc, "highchart")
})

# --- single category y_filter ---

test_that("viz_timeline with single value y_filter", {
  df <- data.frame(
    year = rep(2020:2023, each = 20),
    response = sample(c("A", "B", "C"), 80, replace = TRUE)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "response",
                     y_filter = "A", y_filter_combine = TRUE)
  expect_s3_class(hc, "highchart")
})

# --- Additional targeted tests for remaining uncovered branches ---

test_that("viz_timeline with unified tooltip system", {
  df <- data.frame(
    year = rep(2020:2023, each = 20),
    response = sample(c("A", "B"), 80, replace = TRUE)
  )
  tt <- tooltip(format = "{series}: {y}%")
  hc <- viz_timeline(df, time_var = "year", y_var = "response",
                     tooltip = tt)
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline with tooltip_prefix and tooltip_suffix", {
  df <- data.frame(
    year = rep(2020:2023, each = 20),
    response = sample(c("Yes", "No"), 80, replace = TRUE)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "response",
                     tooltip_prefix = "~", tooltip_suffix = "pct")
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline with subtitle", {
  df <- data.frame(
    year = rep(2020:2023, each = 20),
    response = sample(c("A", "B"), 80, replace = TRUE)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "response",
                     title = "Trend", subtitle = "Sub")
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline with haven_labelled time_var", {
  skip_if_not_installed("haven")
  df <- data.frame(
    year = haven::labelled(rep(2020:2023, each = 20), labels = c("y2020" = 2020)),
    response = sample(c("Yes", "No"), 80, replace = TRUE)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "response")
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline with haven_labelled y_var", {
  skip_if_not_installed("haven")
  df <- data.frame(
    year = rep(2020:2023, each = 20),
    response = haven::labelled(
      sample(1:2, 80, replace = TRUE),
      labels = c("Yes" = 1, "No" = 2)
    )
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "response")
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline with haven_labelled group_var", {
  skip_if_not_installed("haven")
  df <- data.frame(
    year = rep(2020:2023, each = 20),
    response = sample(c("Yes", "No"), 80, replace = TRUE),
    group = haven::labelled(
      rep(1:2, 40),
      labels = c("Male" = 1, "Female" = 2)
    )
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "response",
                     group_var = "group")
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline stacked_area with agg = 'none' and no group_var", {
  df <- data.frame(
    year = 2020:2023,
    value = c(10, 20, 15, 25)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "value",
                     agg = "none", chart_type = "stacked_area")
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline stacked_area with group_var and agg = 'none'", {
  df <- data.frame(
    year = rep(2020:2023, 2),
    value = c(10, 20, 15, 25, 12, 18, 22, 28),
    series = rep(c("A", "B"), each = 4)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "value",
                     group_var = "series", agg = "none",
                     chart_type = "stacked_area")
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline stacked_area percentage with group_var", {
  df <- data.frame(
    year = rep(2020:2023, each = 40),
    response = sample(c("A", "B"), 160, replace = TRUE),
    group = rep(c("X", "Y"), 80)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "response",
                     group_var = "group",
                     chart_type = "stacked_area")
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline line with percentage and group_var (numeric y)", {
  df <- data.frame(
    year = rep(2020:2023, each = 20),
    score = rnorm(80, 50, 10),
    group = rep(c("A", "B"), 40)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "score",
                     group_var = "group", agg = "percentage")
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline line percentage with group_var, weight_var, and numeric y", {
  df <- data.frame(
    year = rep(2020:2023, each = 20),
    score = rnorm(80, 50, 10),
    group = rep(c("A", "B"), 40),
    weight = runif(80, 0.5, 2.0)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "score",
                     group_var = "group", weight_var = "weight",
                     agg = "percentage")
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline with group_order in line chart", {
  df <- data.frame(
    year = rep(2020:2023, each = 10),
    value = rnorm(40, 50, 10),
    group = rep(c("B", "A"), 20)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "value",
                     group_var = "group", agg = "mean",
                     group_order = c("A", "B"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline with named color_palette", {
  df <- data.frame(
    year = rep(2020:2023, each = 20),
    response = sample(c("Yes", "No"), 80, replace = TRUE)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "response",
                     color_palette = c("Yes" = "#00ff00", "No" = "#ff0000"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline with y_filter categorical (non-numeric)", {
  df <- data.frame(
    year = rep(2020:2023, each = 20),
    response = sample(c("Good", "Bad", "Neutral"), 80, replace = TRUE)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "response",
                     y_filter = c("Good", "Neutral"), y_filter_combine = FALSE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline with numeric y_filter not combined", {
  df <- data.frame(
    year = rep(2020:2023, each = 20),
    score = sample(1:5, 80, replace = TRUE)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "score",
                     y_filter = 4:5, y_filter_combine = FALSE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline include_na for y_var and group_var", {
  df <- data.frame(
    year = rep(2020:2023, each = 20),
    response = c(sample(c("Yes", "No", NA), 60, replace = TRUE),
                 sample(c("Yes", "No"), 20, replace = TRUE)),
    group = c(rep(c("A", NA), 40))
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "response",
                     group_var = "group",
                     include_na = TRUE, na_label_y = "No answer",
                     na_label_group = "Unknown")
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline percentage with group_var and categorical response", {
  df <- data.frame(
    year = rep(2020:2023, each = 40),
    response = sample(c("Yes", "No"), 160, replace = TRUE),
    group = rep(c("US", "UK"), 80)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "response",
                     group_var = "group")
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline with y_map_values and factor y_var", {
  df <- data.frame(
    year = rep(2020:2023, each = 20),
    response = factor(sample(c("1", "0"), 80, replace = TRUE))
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "response",
                     y_map_values = list("1" = "Correct", "0" = "Incorrect"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline categorical time (character time_var)", {
  df <- data.frame(
    period = rep(c("Q1", "Q2", "Q3", "Q4"), each = 20),
    response = sample(c("A", "B"), 80, replace = TRUE)
  )
  hc <- viz_timeline(df, time_var = "period", y_var = "response")
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline agg = 'sum' with stacked_area", {
  df <- data.frame(
    year = rep(2020:2023, each = 20),
    count = rpois(80, lambda = 5),
    group = rep(c("A", "B"), 40)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "count",
                     group_var = "group", agg = "sum",
                     chart_type = "stacked_area")
  expect_s3_class(hc, "highchart")
})

test_that("viz_timeline agg = 'mean' with stacked_area", {
  df <- data.frame(
    year = rep(2020:2023, each = 20),
    score = rnorm(80, 50, 10),
    group = rep(c("X", "Y"), 40)
  )
  hc <- viz_timeline(df, time_var = "year", y_var = "score",
                     group_var = "group", agg = "mean",
                     chart_type = "stacked_area")
  expect_s3_class(hc, "highchart")
})
