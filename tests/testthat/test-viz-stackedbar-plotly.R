library(testthat)

`%||%` <- function(x, y) if (is.null(x)) y else x

test_that("viz_stackedbar supports x_vars mode with plotly backend", {
  skip_if_not_installed("plotly")

  set.seed(123)
  df <- data.frame(
    q1 = sample(c("Agree", "Neutral", "Disagree"), 40, replace = TRUE),
    q2 = sample(c("Agree", "Neutral", "Disagree"), 40, replace = TRUE),
    stringsAsFactors = FALSE
  )

  p <- viz_stackedbar(
    data = df,
    x_vars = c("q1", "q2"),
    backend = "plotly"
  )

  expect_s3_class(p, "plotly")
})

test_that("plotly stackedbar respects x_order and zero-fills missing combinations", {
  skip_if_not_installed("plotly")

  df <- data.frame(
    category = c("A", "A", "B", "C"),
    group = c("G1", "G2", "G1", "G2"),
    stringsAsFactors = FALSE
  )

  p <- viz_stackedbar(
    data = df,
    x_var = "category",
    stack_var = "group",
    x_order = c("A", "B", "C"),
    backend = "plotly"
  )

  expect_s3_class(p, "plotly")

  bar_traces <- Filter(function(tr) {
    is.list(tr) && identical(as.character(tr$type %||% ""), "bar")
  }, p$x$attrs %||% list())
  expect_equal(length(bar_traces), 2)

  g1 <- bar_traces[[which(vapply(bar_traces, function(tr) tr$name, character(1)) == "G1")]]
  g2 <- bar_traces[[which(vapply(bar_traces, function(tr) tr$name, character(1)) == "G2")]]

  expect_equal(as.character(g1$x), c("A", "B", "C"))
  expect_equal(as.numeric(g1$y), c(1, 1, 0))
  expect_equal(as.character(g2$x), c("A", "B", "C"))
  expect_equal(as.numeric(g2$y), c(1, 0, 1))

  expect_equal(p$x$layoutAttrs[[1]]$xaxis$categoryorder, "array")
  expect_equal(as.character(p$x$layoutAttrs[[1]]$xaxis$categoryarray), c("A", "B", "C"))
})

test_that("plotly stackedbar maps named color palette to matching stack names", {
  skip_if_not_installed("plotly")

  df <- data.frame(
    category = c("A", "A", "B", "B"),
    group = c("G1", "G2", "G1", "G2"),
    stringsAsFactors = FALSE
  )

  p <- viz_stackedbar(
    data = df,
    x_var = "category",
    stack_var = "group",
    backend = "plotly",
    color_palette = c(G2 = "#222222", G1 = "#111111")
  )

  bar_traces <- Filter(function(tr) {
    is.list(tr) && identical(as.character(tr$type %||% ""), "bar")
  }, p$x$attrs %||% list())

  trace_colors <- vapply(bar_traces, function(tr) tr$marker$color %||% NA_character_, character(1))
  names(trace_colors) <- vapply(bar_traces, function(tr) tr$name %||% "", character(1))

  expect_equal(trace_colors[["G1"]], "#111111")
  expect_equal(trace_colors[["G2"]], "#222222")
})

test_that("plotly stackedbar percent mode emits percent labels and tooltip template", {
  skip_if_not_installed("plotly")

  df <- data.frame(
    category = c("A", "A", "A", "B", "B"),
    group = c("G1", "G2", "G3", "G1", "G2"),
    stringsAsFactors = FALSE
  )

  p <- viz_stackedbar(
    data = df,
    x_var = "category",
    stack_var = "group",
    backend = "plotly",
    stacked_type = "percent",
    data_labels_enabled = TRUE
  )

  bar_traces <- Filter(function(tr) {
    is.list(tr) && identical(as.character(tr$type %||% ""), "bar")
  }, p$x$attrs %||% list())

  expect_true(length(bar_traces) >= 2)
  expect_true(any(grepl("%$", as.character(bar_traces[[1]]$text %||% character(0)))))
  expect_match(bar_traces[[1]]$hovertemplate %||% "", "Total: 100%", perl = TRUE)
})
