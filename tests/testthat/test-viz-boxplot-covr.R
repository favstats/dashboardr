# Tests for viz_boxplot.R — lightweight, covr-safe
library(testthat)

df <- data.frame(
  value = c(rnorm(30, 50, 10), rnorm(30, 60, 15), rnorm(30, 45, 8)),
  group = rep(c("A", "B", "C"), each = 30),
  weight = runif(90, 0.5, 2.0),
  stringsAsFactors = FALSE
)

test_that("viz_boxplot basic", {
  hc <- viz_boxplot(df, y_var = "value")
  expect_s3_class(hc, "highchart")
})

test_that("viz_boxplot with title and labels", {
  hc <- viz_boxplot(df, y_var = "value",
                    title = "Value Distribution",
                    subtitle = "Sample data",
                    y_label = "Value")
  expect_s3_class(hc, "highchart")
})

test_that("viz_boxplot with x_var grouping", {
  hc <- viz_boxplot(df, y_var = "value", x_var = "group")
  expect_s3_class(hc, "highchart")
})

test_that("viz_boxplot with x_var and labels", {
  hc <- viz_boxplot(df, y_var = "value", x_var = "group",
                    x_label = "Group", y_label = "Value")
  expect_s3_class(hc, "highchart")
})

test_that("viz_boxplot horizontal", {
  hc <- viz_boxplot(df, y_var = "value", x_var = "group", horizontal = TRUE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_boxplot without outliers", {
  hc <- viz_boxplot(df, y_var = "value", show_outliers = FALSE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_boxplot with color_palette", {
  hc <- viz_boxplot(df, y_var = "value", x_var = "group",
                    color_palette = c("red", "blue", "green"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_boxplot with x_order", {
  hc <- viz_boxplot(df, y_var = "value", x_var = "group",
                    x_order = c("C", "B", "A"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_boxplot with weight_var", {
  hc <- viz_boxplot(df, y_var = "value", x_var = "group",
                    weight_var = "weight")
  expect_s3_class(hc, "highchart")
})

test_that("viz_boxplot with x_map_values", {
  hc <- viz_boxplot(df, y_var = "value", x_var = "group",
                    x_map_values = list("A" = "Alpha", "B" = "Beta", "C" = "Gamma"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_boxplot include_na", {
  df_na <- df
  df_na$group[c(1, 15, 60)] <- NA
  hc <- viz_boxplot(df_na, y_var = "value", x_var = "group",
                    include_na = TRUE, na_label = "Missing")
  expect_s3_class(hc, "highchart")
})

test_that("viz_boxplot with tooltip prefix/suffix", {
  hc <- viz_boxplot(df, y_var = "value", x_var = "group",
                    tooltip_prefix = "$", tooltip_suffix = "M")
  expect_s3_class(hc, "highchart")
})

test_that("viz_boxplot with tooltip string", {
  hc <- viz_boxplot(df, y_var = "value", x_var = "group",
                    tooltip = "{category}: median={median}")
  expect_s3_class(hc, "highchart")
})

test_that("viz_boxplot error: missing y_var column", {
  expect_error(viz_boxplot(df, y_var = "nonexistent"))
})

test_that("viz_boxplot error: non-data.frame", {
  expect_error(viz_boxplot("not_a_df", y_var = "value"))
})

test_that("viz_boxplot with haven_labelled x_var", {
  df_lab <- df
  df_lab$group <- structure(rep(1:3, each = 30),
                            labels = c("A" = 1, "B" = 2, "C" = 3),
                            class = "haven_labelled")
  hc <- viz_boxplot(df_lab, y_var = "value", x_var = "group")
  expect_s3_class(hc, "highchart")
})
