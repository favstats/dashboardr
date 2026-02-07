# Tests for viz_treemap — lightweight, covr-safe
# Targets uncovered branches: subgroup_var, color_var, layout_algorithm,
# allow_drill_down, data_labels_enabled, pre_aggregated, color_palette
library(testthat)

test_that("viz_treemap basic chart", {
  df <- data.frame(
    region = c("North", "North", "South", "South"),
    city = c("NYC", "Boston", "Miami", "Atlanta"),
    spend = c(1000, 500, 800, 600)
  )
  hc <- viz_treemap(df, group_var = "region", value_var = "spend")
  expect_s3_class(hc, "highchart")
})

test_that("viz_treemap with subgroup_var", {
  df <- data.frame(
    region = c("North", "North", "South", "South"),
    city = c("NYC", "Boston", "Miami", "Atlanta"),
    spend = c(1000, 500, 800, 600)
  )
  hc <- viz_treemap(df, group_var = "region", subgroup_var = "city",
                    value_var = "spend")
  expect_s3_class(hc, "highchart")
})

test_that("viz_treemap with title and subtitle", {
  df <- data.frame(
    category = c("A", "B", "C"),
    value = c(30, 50, 20)
  )
  hc <- viz_treemap(df, group_var = "category", value_var = "value",
                    title = "Treemap", subtitle = "By category")
  expect_s3_class(hc, "highchart")
})

test_that("viz_treemap with color_palette", {
  df <- data.frame(
    category = c("A", "B", "C"),
    value = c(30, 50, 20)
  )
  hc <- viz_treemap(df, group_var = "category", value_var = "value",
                    color_palette = c("A" = "#ff0000", "B" = "#00ff00", "C" = "#0000ff"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_treemap with layout_algorithm strip", {
  df <- data.frame(
    category = c("A", "B", "C", "D"),
    value = c(30, 50, 20, 40)
  )
  hc <- viz_treemap(df, group_var = "category", value_var = "value",
                    layout_algorithm = "strip")
  expect_s3_class(hc, "highchart")
})

test_that("viz_treemap with layout_algorithm sliceAndDice", {
  df <- data.frame(
    category = c("A", "B", "C"),
    value = c(30, 50, 20)
  )
  hc <- viz_treemap(df, group_var = "category", value_var = "value",
                    layout_algorithm = "sliceAndDice")
  expect_s3_class(hc, "highchart")
})

test_that("viz_treemap with allow_drill_down FALSE", {
  df <- data.frame(
    region = c("North", "North", "South", "South"),
    city = c("NYC", "Boston", "Miami", "Atlanta"),
    spend = c(1000, 500, 800, 600)
  )
  hc <- viz_treemap(df, group_var = "region", subgroup_var = "city",
                    value_var = "spend", allow_drill_down = FALSE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_treemap with data_labels_enabled FALSE", {
  df <- data.frame(
    category = c("A", "B", "C"),
    value = c(30, 50, 20)
  )
  hc <- viz_treemap(df, group_var = "category", value_var = "value",
                    data_labels_enabled = FALSE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_treemap with pre_aggregated TRUE", {
  df <- data.frame(
    category = c("A", "B", "C"),
    value = c(30, 50, 20)
  )
  hc <- viz_treemap(df, group_var = "category", value_var = "value",
                    pre_aggregated = TRUE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_treemap with color_var", {
  df <- data.frame(
    category = c("A", "B", "C"),
    value = c(30, 50, 20),
    score = c(0.8, 0.5, 0.3)
  )
  hc <- viz_treemap(df, group_var = "category", value_var = "value",
                    color_var = "score")
  expect_s3_class(hc, "highchart")
})

test_that("viz_treemap with custom height", {
  df <- data.frame(
    category = c("A", "B"),
    value = c(30, 50)
  )
  hc <- viz_treemap(df, group_var = "category", value_var = "value",
                    height = 600)
  expect_s3_class(hc, "highchart")
})

# --- Additional targeted tests for uncovered branches ---

test_that("viz_treemap with unified tooltip system", {
  df <- data.frame(
    category = c("A", "B", "C"),
    value = c(30, 50, 20)
  )
  tt <- tooltip(format = "{name}: {value}")
  hc <- viz_treemap(df, group_var = "category", value_var = "value",
                    tooltip = tt)
  expect_s3_class(hc, "highchart")
})

test_that("viz_treemap with tooltip as format string", {
  df <- data.frame(
    category = c("A", "B", "C"),
    value = c(30, 50, 20)
  )
  hc <- viz_treemap(df, group_var = "category", value_var = "value",
                    tooltip = "{name}: {value}")
  expect_s3_class(hc, "highchart")
})

test_that("viz_treemap with legacy tooltip_format", {
  df <- data.frame(
    category = c("A", "B"),
    value = c(30, 50)
  )
  hc <- viz_treemap(df, group_var = "category", value_var = "value",
                    tooltip_format = "<b>{point.name}</b>: {point.value}")
  expect_s3_class(hc, "highchart")
})

test_that("viz_treemap with both tooltip and tooltip_format (backwards compat)", {
  df <- data.frame(
    category = c("A", "B"),
    value = c(30, 50)
  )
  tt <- tooltip(format = "{name}: {value}")
  # When both provided, tooltip_format wins for backwards compat
  hc <- viz_treemap(df, group_var = "category", value_var = "value",
                    tooltip = tt,
                    tooltip_format = "<b>{point.name}</b>: {point.value}")
  expect_s3_class(hc, "highchart")
})

test_that("viz_treemap deprecated show_labels warning", {
  df <- data.frame(
    category = c("A", "B"),
    value = c(30, 50)
  )
  expect_warning(
    viz_treemap(df, group_var = "category", value_var = "value",
                show_labels = FALSE),
    "deprecated"
  )
})

test_that("viz_treemap single color_palette string (gradient)", {
  df <- data.frame(
    category = c("A", "B", "C"),
    value = c(30, 50, 20)
  )
  hc <- viz_treemap(df, group_var = "category", value_var = "value",
                    color_palette = "#1a5276")
  expect_s3_class(hc, "highchart")
})

test_that("viz_treemap with haven_labelled value_var", {
  skip_if_not_installed("haven")
  df <- data.frame(
    category = c("A", "B", "C"),
    value = haven::labelled(c(30, 50, 20), labels = c("low" = 20, "high" = 50))
  )
  hc <- viz_treemap(df, group_var = "category", value_var = "value")
  expect_s3_class(hc, "highchart")
})

test_that("viz_treemap with haven_labelled group_var", {
  skip_if_not_installed("haven")
  df <- data.frame(
    category = haven::labelled(1:3, labels = c("A" = 1, "B" = 2, "C" = 3)),
    value = c(30, 50, 20)
  )
  hc <- viz_treemap(df, group_var = "category", value_var = "value")
  expect_s3_class(hc, "highchart")
})

test_that("viz_treemap with haven_labelled subgroup_var", {
  skip_if_not_installed("haven")
  df <- data.frame(
    region = c("North", "North", "South", "South"),
    city = haven::labelled(1:4, labels = c("NYC" = 1, "Boston" = 2, "Miami" = 3, "Atlanta" = 4)),
    spend = c(1000, 500, 800, 600)
  )
  hc <- viz_treemap(df, group_var = "region", subgroup_var = "city",
                    value_var = "spend")
  expect_s3_class(hc, "highchart")
})

test_that("viz_treemap with haven_labelled color_var", {
  skip_if_not_installed("haven")
  df <- data.frame(
    category = c("A", "B", "C"),
    value = c(30, 50, 20),
    color = haven::labelled(1:3, labels = c("red" = 1, "green" = 2, "blue" = 3))
  )
  hc <- viz_treemap(df, group_var = "category", value_var = "value",
                    color_var = "color")
  expect_s3_class(hc, "highchart")
})

test_that("viz_treemap with NA values removed", {
  df <- data.frame(
    category = c("A", "B", "C", NA, "D"),
    value = c(30, NA, 20, 40, 10)
  )
  hc <- viz_treemap(df, group_var = "category", value_var = "value")
  expect_s3_class(hc, "highchart")
})

test_that("viz_treemap non-pre-aggregated single-level (duplicates)", {
  df <- data.frame(
    category = c("A", "A", "A", "B", "B", "C"),
    value = c(10, 20, 30, 40, 50, 60)
  )
  hc <- viz_treemap(df, group_var = "category", value_var = "value",
                    pre_aggregated = FALSE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_treemap non-pre-aggregated with subgroup (aggregation)", {
  df <- data.frame(
    region = c("North", "North", "North", "South", "South"),
    city = c("NYC", "NYC", "Boston", "Miami", "Miami"),
    spend = c(100, 200, 300, 400, 500)
  )
  hc <- viz_treemap(df, group_var = "region", subgroup_var = "city",
                    value_var = "spend", pre_aggregated = FALSE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_treemap error: data is NULL", {
  expect_error(viz_treemap(data = NULL, group_var = "a", value_var = "b"), "required")
})

test_that("viz_treemap error: group_var not found", {
  df <- data.frame(a = 1, b = 2)
  expect_error(viz_treemap(df, group_var = "nonexistent", value_var = "b"), "not found")
})

test_that("viz_treemap error: value_var not found", {
  df <- data.frame(a = 1, b = 2)
  expect_error(viz_treemap(df, group_var = "a", value_var = "nonexistent"), "not found")
})

test_that("viz_treemap error: subgroup_var not found", {
  df <- data.frame(a = 1, b = 2)
  expect_error(viz_treemap(df, group_var = "a", value_var = "b",
                           subgroup_var = "nonexistent"), "not found")
})

test_that("viz_treemap with label_style override", {
  df <- data.frame(
    category = c("A", "B", "C"),
    value = c(30, 50, 20)
  )
  hc <- viz_treemap(df, group_var = "category", value_var = "value",
                    label_style = list(fontSize = "18px", color = "#333"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_treemap with credits enabled", {
  df <- data.frame(
    category = c("A", "B"),
    value = c(30, 50)
  )
  hc <- viz_treemap(df, group_var = "category", value_var = "value",
                    credits = TRUE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_treemap all NAs returns warning chart", {
  df <- data.frame(
    category = c(NA, NA),
    value = c(NA, NA)
  )
  expect_warning(
    hc <- viz_treemap(df, group_var = "category", value_var = "value"),
    "No data"
  )
  expect_s3_class(hc, "highchart")
})
