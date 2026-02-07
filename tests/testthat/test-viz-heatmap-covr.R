# Tests for viz_heatmap.R — lightweight, covr-safe
library(testthat)

df <- expand.grid(
  x_cat = c("A", "B", "C"),
  y_cat = c("Low", "Medium", "High"),
  stringsAsFactors = FALSE
)
df$value <- c(10, 20, 30, 15, 25, 35, 5, 50, 45)
df$weight <- runif(9, 0.5, 2.0)

test_that("viz_heatmap basic", {
  hc <- viz_heatmap(df, x_var = "x_cat", y_var = "y_cat", value_var = "value")
  expect_s3_class(hc, "highchart")
})

test_that("viz_heatmap with title and labels", {
  hc <- viz_heatmap(df, x_var = "x_cat", y_var = "y_cat", value_var = "value",
                    title = "Heatmap",
                    subtitle = "Test",
                    x_label = "X Category",
                    y_label = "Y Category",
                    value_label = "Score")
  expect_s3_class(hc, "highchart")
})

test_that("viz_heatmap with color_palette gradient", {
  hc <- viz_heatmap(df, x_var = "x_cat", y_var = "y_cat", value_var = "value",
                    color_palette = c("#FFFFFF", "#7CB5EC"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_heatmap with color_min/max", {
  hc <- viz_heatmap(df, x_var = "x_cat", y_var = "y_cat", value_var = "value",
                    color_min = 0, color_max = 100)
  expect_s3_class(hc, "highchart")
})

test_that("viz_heatmap with x_order and y_order", {
  hc <- viz_heatmap(df, x_var = "x_cat", y_var = "y_cat", value_var = "value",
                    x_order = c("C", "B", "A"),
                    y_order = c("High", "Medium", "Low"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_heatmap with x_order_by ascending", {
  hc <- viz_heatmap(df, x_var = "x_cat", y_var = "y_cat", value_var = "value",
                    x_order_by = "asc")
  expect_s3_class(hc, "highchart")
})

test_that("viz_heatmap with y_order_by descending", {
  hc <- viz_heatmap(df, x_var = "x_cat", y_var = "y_cat", value_var = "value",
                    y_order_by = "desc")
  expect_s3_class(hc, "highchart")
})

test_that("viz_heatmap data_labels disabled", {
  hc <- viz_heatmap(df, x_var = "x_cat", y_var = "y_cat", value_var = "value",
                    data_labels_enabled = FALSE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_heatmap label_decimals", {
  hc <- viz_heatmap(df, x_var = "x_cat", y_var = "y_cat", value_var = "value",
                    label_decimals = 2)
  expect_s3_class(hc, "highchart")
})

test_that("viz_heatmap with tooltip prefix/suffix", {
  hc <- viz_heatmap(df, x_var = "x_cat", y_var = "y_cat", value_var = "value",
                    tooltip_prefix = "$", tooltip_suffix = "K")
  expect_s3_class(hc, "highchart")
})

test_that("viz_heatmap with tooltip string", {
  hc <- viz_heatmap(df, x_var = "x_cat", y_var = "y_cat", value_var = "value",
                    tooltip = "{x} vs {y}: {value}")
  expect_s3_class(hc, "highchart")
})

test_that("viz_heatmap with x/y tooltip prefix/suffix", {
  hc <- viz_heatmap(df, x_var = "x_cat", y_var = "y_cat", value_var = "value",
                    x_tooltip_prefix = "Cat: ", x_tooltip_suffix = "!",
                    y_tooltip_prefix = "Level: ", y_tooltip_suffix = ".")
  expect_s3_class(hc, "highchart")
})

test_that("viz_heatmap include_na", {
  df_na <- df
  df_na$x_cat[1] <- NA
  df_na$y_cat[5] <- NA
  hc <- viz_heatmap(df_na, x_var = "x_cat", y_var = "y_cat", value_var = "value",
                    include_na = TRUE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_heatmap with x/y map_values", {
  hc <- viz_heatmap(df, x_var = "x_cat", y_var = "y_cat", value_var = "value",
                    x_map_values = list("A" = "Alpha"),
                    y_map_values = list("Low" = "Bajo"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_heatmap with weight_var", {
  hc <- viz_heatmap(df, x_var = "x_cat", y_var = "y_cat", value_var = "value",
                    weight_var = "weight")
  expect_s3_class(hc, "highchart")
})

test_that("viz_heatmap pre_aggregated", {
  hc <- viz_heatmap(df, x_var = "x_cat", y_var = "y_cat", value_var = "value",
                    pre_aggregated = TRUE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_heatmap with agg_fun max", {
  # Create duplicate x/y combos
  df2 <- rbind(df, df)
  df2$value <- c(df$value, df$value + 5)
  hc <- viz_heatmap(df2, x_var = "x_cat", y_var = "y_cat", value_var = "value",
                    agg_fun = max)
  expect_s3_class(hc, "highchart")
})

test_that("viz_heatmap with na_color", {
  df_na <- df
  df_na$value[1] <- NA
  hc <- viz_heatmap(df_na, x_var = "x_cat", y_var = "y_cat", value_var = "value",
                    na_color = "#cccccc")
  expect_s3_class(hc, "highchart")
})

test_that("viz_heatmap error: missing column", {
  expect_error(viz_heatmap(df, x_var = "nonexistent", y_var = "y_cat", value_var = "value"))
})

test_that("viz_heatmap error: non-data.frame", {
  expect_error(viz_heatmap("not_a_df", x_var = "x_cat", y_var = "y_cat", value_var = "value"))
})

test_that("viz_heatmap with haven_labelled vars", {
  df_lab <- df
  df_lab$x_cat <- structure(rep(1:3, 3),
                            labels = c("A" = 1, "B" = 2, "C" = 3),
                            class = "haven_labelled")
  hc <- viz_heatmap(df_lab, x_var = "x_cat", y_var = "y_cat", value_var = "value")
  expect_s3_class(hc, "highchart")
})
