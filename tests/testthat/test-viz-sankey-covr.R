# Tests for viz_sankey — lightweight, covr-safe (no skip_on_covr_ci)
library(testthat)

test_that("viz_sankey basic diagram", {
  df <- data.frame(
    from = c("A", "A", "B", "B"),
    to = c("X", "Y", "X", "Y"),
    flow = c(30, 20, 10, 40)
  )
  hc <- viz_sankey(df, from_var = "from", to_var = "to", value_var = "flow")
  expect_s3_class(hc, "highchart")
  expect_true(length(hc$x$hc_opts$series) >= 1)
})

test_that("viz_sankey with title and subtitle", {
  df <- data.frame(
    from = c("A", "A", "B"),
    to = c("X", "Y", "X"),
    flow = c(30, 20, 10)
  )
  hc <- viz_sankey(df, from_var = "from", to_var = "to", value_var = "flow",
                   title = "Flow Diagram", subtitle = "2024")
  expect_s3_class(hc, "highchart")
})

test_that("viz_sankey with named color_palette", {
  df <- data.frame(
    from = c("A", "A", "B"),
    to = c("X", "Y", "X"),
    flow = c(30, 20, 10)
  )
  hc <- viz_sankey(df, from_var = "from", to_var = "to", value_var = "flow",
                   color_palette = c("A" = "#ff0000", "B" = "#00ff00",
                                     "X" = "#0000ff", "Y" = "#ffff00"))
  expect_s3_class(hc, "highchart")
})

test_that("viz_sankey with custom node_width and node_padding", {
  df <- data.frame(
    from = c("A", "A", "B"),
    to = c("X", "Y", "X"),
    flow = c(30, 20, 10)
  )
  hc <- viz_sankey(df, from_var = "from", to_var = "to", value_var = "flow",
                   node_width = 30, node_padding = 15)
  expect_s3_class(hc, "highchart")
})

test_that("viz_sankey with link_opacity", {
  df <- data.frame(
    from = c("A", "B"),
    to = c("X", "Y"),
    flow = c(30, 20)
  )
  hc <- viz_sankey(df, from_var = "from", to_var = "to", value_var = "flow",
                   link_opacity = 0.8)
  expect_s3_class(hc, "highchart")
})

test_that("viz_sankey with data_labels_enabled FALSE", {
  df <- data.frame(
    from = c("A", "B"),
    to = c("X", "Y"),
    flow = c(30, 20)
  )
  hc <- viz_sankey(df, from_var = "from", to_var = "to", value_var = "flow",
                   data_labels_enabled = FALSE)
  expect_s3_class(hc, "highchart")
})

test_that("viz_sankey errors on missing columns", {
  df <- data.frame(a = "x", b = "y", c = 10)
  expect_error(
    viz_sankey(df, from_var = "nope", to_var = "b", value_var = "c"),
    "not found"
  )
})

test_that("viz_sankey errors on non-numeric value_var", {
  df <- data.frame(a = "x", b = "y", c = "z")
  expect_error(
    viz_sankey(df, from_var = "a", to_var = "b", value_var = "c"),
    "numeric"
  )
})
