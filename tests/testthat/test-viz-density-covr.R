# Tests for viz_density — lightweight, covr-safe
# Targets uncovered branches: group_var, weight_var, include_na, fill_opacity,
# show_rug, bandwidth, group_order, labels, color_palette
library(testthat)

test_that("viz_density basic plot", {
  df <- data.frame(value = rnorm(100))
  hc <- viz_density(df, x_var = "value")
  expect_s3_class(hc, "highchart")
})

test_that("viz_density with title and labels", {
  df <- data.frame(value = rnorm(100))
  hc <- viz_density(df, x_var = "value",
                    title = "Density",
                    x_label = "Values",
                    y_label = "Density Est.")
  expect_s3_class(hc, "highchart")
})

test_that("viz_density with group_var", {
  df <- data.frame(
    value = c(rnorm(50, mean = 0), rnorm(50, mean = 3)),
    group = rep(c("A", "B"), each = 50)
  )
  hc <- viz_density(df, x_var = "value", group_var = "group")
  expect_s3_class(hc, "highchart")
})

test_that("viz_density with group_order", {
  df <- data.frame(
    value = c(rnorm(30), rnorm(30, 2)),
    group = rep(c("B", "A"), each = 30)
  )
  hc <- viz_density(df, x_var = "value", group_var = "group",
                    group_order = c("A", "B"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_density with color_palette", {
  df <- data.frame(
    value = c(rnorm(30), rnorm(30, 2)),
    group = rep(c("A", "B"), each = 30)
  )
  hc <- viz_density(df, x_var = "value", group_var = "group",
                    color_palette = c("#ff0000", "#0000ff"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_density with fill_opacity", {
  df <- data.frame(value = rnorm(50))
  hc <- viz_density(df, x_var = "value", fill_opacity = 0.5)
  expect_s3_class(hc, "highchart")
})

test_that("viz_density with show_rug", {
  df <- data.frame(value = rnorm(50))
  hc <- viz_density(df, x_var = "value", show_rug = TRUE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_density with custom bandwidth", {
  df <- data.frame(value = rnorm(50))
  hc <- viz_density(df, x_var = "value", bandwidth = 0.5)
  expect_s3_class(hc, "highchart")
})

test_that("viz_density with weight_var", {
  df <- data.frame(
    value = rnorm(50),
    weight = runif(50, 0.5, 2)
  )
  hc <- viz_density(df, x_var = "value", weight_var = "weight")
  expect_s3_class(hc, "highchart")
})

test_that("viz_density with include_na in group_var", {
  df <- data.frame(
    value = rnorm(30),
    group = c(rep("A", 10), rep("B", 10), rep(NA, 10))
  )
  hc <- viz_density(df, x_var = "value", group_var = "group",
                    include_na = TRUE, na_label = "Missing")
  expect_s3_class(hc, "highchart")
})

test_that("viz_density with subtitle", {
  df <- data.frame(value = rnorm(50))
  hc <- viz_density(df, x_var = "value",
                    title = "Main", subtitle = "Sub")
  expect_s3_class(hc, "highchart")
})

# --- Additional targeted tests for uncovered branches ---

test_that("viz_density show_rug with group_var (rug per group)", {
  df <- data.frame(
    value = c(rnorm(30, mean = 0), rnorm(30, mean = 3)),
    group = rep(c("A", "B"), each = 30)
  )
  hc <- viz_density(df, x_var = "value", group_var = "group",
                    show_rug = TRUE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_density with unified tooltip system", {
  df <- data.frame(value = rnorm(50))
  tt <- tooltip(format = "{x}: {y}")
  hc <- viz_density(df, x_var = "value", tooltip = tt)
  expect_s3_class(hc, "highchart")
})

test_that("viz_density with tooltip as format string", {
  df <- data.frame(value = rnorm(50))
  hc <- viz_density(df, x_var = "value", tooltip = "{x}: {value}")
  expect_s3_class(hc, "highchart")
})

test_that("viz_density with tooltip_suffix (legacy path)", {
  df <- data.frame(value = rnorm(50))
  hc <- viz_density(df, x_var = "value", tooltip_suffix = " units")
  expect_s3_class(hc, "highchart")
})

test_that("viz_density with haven_labelled x_var", {
  skip_if_not_installed("haven")
  df <- data.frame(
    value = haven::labelled(c(1:50), labels = c("one" = 1, "fifty" = 50))
  )
  hc <- viz_density(df, x_var = "value")
  expect_s3_class(hc, "highchart")
})

test_that("viz_density with haven_labelled group_var", {
  skip_if_not_installed("haven")
  df <- data.frame(
    value = rnorm(60),
    group = haven::labelled(rep(1:3, each = 20), labels = c("A" = 1, "B" = 2, "C" = 3))
  )
  hc <- viz_density(df, x_var = "value", group_var = "group")
  expect_s3_class(hc, "highchart")
})

test_that("viz_density with non-numeric x_var (coercible to numeric)", {
  df <- data.frame(value = as.character(rnorm(50)))
  hc <- viz_density(df, x_var = "value")
  expect_s3_class(hc, "highchart")
})

test_that("viz_density error: non-numeric x_var not coercible", {
  df <- data.frame(value = letters[1:20])
  expect_error(viz_density(df, x_var = "value"), "numeric")
})

test_that("viz_density error: missing x_var column", {
  df <- data.frame(value = rnorm(10))
  expect_error(viz_density(df, x_var = "nonexistent"), "not found")
})

test_that("viz_density error: missing group_var column", {
  df <- data.frame(value = rnorm(10))
  expect_error(viz_density(df, x_var = "value", group_var = "nonexistent"), "not found")
})

test_that("viz_density error: missing weight_var column", {
  df <- data.frame(value = rnorm(10))
  expect_error(viz_density(df, x_var = "value", weight_var = "nonexistent"), "not found")
})

test_that("viz_density error: data is not a data frame", {
  expect_error(viz_density(list(a = 1), x_var = "a"), "data frame")
})

test_that("viz_density weighted density with group_var", {
  df <- data.frame(
    value = c(rnorm(30), rnorm(30, 2)),
    group = rep(c("A", "B"), each = 30),
    wt = runif(60, 0.5, 2)
  )
  hc <- viz_density(df, x_var = "value", group_var = "group",
                    weight_var = "wt")
  expect_s3_class(hc, "highchart")
})

test_that("viz_density with explicit bandwidth and group_var", {
  df <- data.frame(
    value = c(rnorm(30), rnorm(30, 3)),
    group = rep(c("A", "B"), each = 30)
  )
  hc <- viz_density(df, x_var = "value", group_var = "group",
                    bandwidth = 0.8)
  expect_s3_class(hc, "highchart")
})

test_that("viz_density with NAs in x_var (removed)", {
  df <- data.frame(value = c(rnorm(40), rep(NA, 10)))
  hc <- viz_density(df, x_var = "value")
  expect_s3_class(hc, "highchart")
})

test_that("viz_density group with include_na FALSE (NA groups filtered)", {
  df <- data.frame(
    value = rnorm(30),
    group = c(rep("A", 10), rep("B", 10), rep(NA, 10))
  )
  hc <- viz_density(df, x_var = "value", group_var = "group",
                    include_na = FALSE)
  expect_s3_class(hc, "highchart")
})
