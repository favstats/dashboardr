# =============================================================================
# Tests for viz_stackedbar with cross_tab_filter_vars & y_var aggregation
# =============================================================================
#
# Verifies that viz_stackedbar properly aggregates pre-computed counts (y_var)
# when the data contains extra filter columns (cross_tab_filter_vars).
# Without aggregation, duplicate x/stack combinations create broken charts.
# =============================================================================

library(testthat)
library(dashboardr)

# Helper: create synthetic data similar to the GSS demo
make_test_data <- function() {
  expand.grid(
    response        = c("Favor", "Oppose"),
    breakdown_value = c("All", "Male", "Female"),
    dimension       = c("Topic A", "Topic B"),
    question        = c("Q1", "Q2"),
    time_period     = c("2022", "2024"),
    breakdown_type  = c("Overall", "Sex"),
    stringsAsFactors = FALSE
  ) |>
    dplyr::mutate(n = sample(50:500, dplyr::n(), replace = TRUE))
}

# =============================================================================
# SECTION 1: y_var aggregation
# =============================================================================

describe("viz_stackedbar with y_var and extra columns", {

  it("produces a valid highchart when y_var is provided with extra columns", {
    d <- make_test_data()
    hc <- viz_stackedbar(
      data      = d,
      x_var     = "response",
      stack_var = "breakdown_value",
      y_var     = "n",
      title     = "Test"
    )
    expect_s3_class(hc, "highchart")
  })

  it("has correct number of x-axis categories (not hundreds)", {
    d <- make_test_data()
    hc <- viz_stackedbar(
      data      = d,
      x_var     = "response",
      stack_var = "breakdown_value",
      y_var     = "n",
      title     = "Test"
    )
    cats <- hc$x$hc_opts$xAxis$categories
    # Should be exactly 2 categories: "Favor" and "Oppose"
    expect_equal(length(cats), 2)
    expect_true("Favor" %in% cats)
    expect_true("Oppose" %in% cats)
  })

  it("has correct number of series (one per stack group)", {
    d <- make_test_data()
    hc <- viz_stackedbar(
      data      = d,
      x_var     = "response",
      stack_var = "breakdown_value",
      y_var     = "n",
      title     = "Test"
    )
    series_names <- vapply(hc$x$hc_opts$series, function(s) s$name, character(1))
    expect_equal(sort(series_names), c("All", "Female", "Male"))
  })

  it("aggregates y_var values across extra columns", {
    d <- data.frame(
      response        = c("A", "A", "A", "B", "B", "B"),
      breakdown_value = c("X", "X", "X", "X", "X", "X"),
      extra_col       = c("e1", "e2", "e3", "e1", "e2", "e3"),
      n               = c(10, 20, 30, 40, 50, 60),
      stringsAsFactors = FALSE
    )
    hc <- viz_stackedbar(
      data      = d,
      x_var     = "response",
      stack_var = "breakdown_value",
      y_var     = "n",
      title     = "Aggregation Test"
    )
    # Series "X" should have 2 data points: A=60, B=150
    series <- hc$x$hc_opts$series[[1]]
    expect_equal(series$name, "X")
    values <- vapply(series$data, function(p) p$y, numeric(1))
    expect_equal(sort(values), c(60, 150))
  })
})

# =============================================================================
# SECTION 2: cross_tab_filter_vars
# =============================================================================

describe("viz_stackedbar with cross_tab_filter_vars", {

  it("attaches cross_tab attributes when cross_tab_filter_vars is provided", {
    d <- make_test_data()
    hc <- viz_stackedbar(
      data                 = d,
      x_var                = "response",
      stack_var            = "breakdown_value",
      y_var                = "n",
      cross_tab_filter_vars = c("dimension", "question", "time_period", "breakdown_type"),
      title                = "Cross-tab Test"
    )
    expect_false(is.null(attr(hc, "cross_tab_data")))
    expect_false(is.null(attr(hc, "cross_tab_config")))
    expect_false(is.null(attr(hc, "cross_tab_id")))
  })

  it("cross_tab_data contains all filter variable columns", {
    d <- make_test_data()
    filter_vars <- c("dimension", "question", "time_period", "breakdown_type")
    hc <- viz_stackedbar(
      data                 = d,
      x_var                = "response",
      stack_var            = "breakdown_value",
      y_var                = "n",
      cross_tab_filter_vars = filter_vars,
      title                = "Cross-tab Test"
    )
    ct <- attr(hc, "cross_tab_data")
    expect_true(all(filter_vars %in% names(ct)))
    expect_true("n" %in% names(ct))
    expect_true("response" %in% names(ct))
    expect_true("breakdown_value" %in% names(ct))
  })

  it("cross_tab_config includes x/stack order and filter vars", {
    d <- make_test_data()
    hc <- viz_stackedbar(
      data                 = d,
      x_var                = "response",
      stack_var            = "breakdown_value",
      y_var                = "n",
      cross_tab_filter_vars = c("dimension", "time_period"),
      stack_order          = c("All", "Male", "Female"),
      x_order              = c("Favor", "Oppose"),
      title                = "Config Test"
    )
    cfg <- attr(hc, "cross_tab_config")
    expect_equal(cfg$xVar, "response")
    expect_equal(cfg$stackVar, "breakdown_value")
    expect_equal(cfg$stackOrder, c("All", "Male", "Female"))
    expect_equal(cfg$xOrder, c("Favor", "Oppose"))
    expect_equal(cfg$filterVars, c("dimension", "time_period"))
  })
})

# =============================================================================
# SECTION 3: horizontal + percent stacking
# =============================================================================

describe("viz_stackedbar horizontal + percent", {

  it("renders a horizontal bar chart with correct stacking", {
    d <- data.frame(
      response = rep(c("Favor", "Oppose"), each = 2),
      group    = rep(c("Male", "Female"), 2),
      n        = c(100, 120, 80, 90),
      stringsAsFactors = FALSE
    )
    hc <- viz_stackedbar(
      data         = d,
      x_var        = "response",
      stack_var    = "group",
      y_var        = "n",
      stacked_type = "percent",
      horizontal   = TRUE,
      title        = "Horizontal Percent Test"
    )
    expect_s3_class(hc, "highchart")
    # Chart type should be "bar" for horizontal
    series <- hc$x$hc_opts$series
    expect_true(length(series) > 0)
    # Plot options should have bar.stacking = "percent"
    bar_opts <- hc$x$hc_opts$plotOptions$bar
    expect_equal(bar_opts$stacking, "percent")
  })

  it("y-axis label says 'Percentage' for percent stacking", {
    d <- data.frame(
      response = c("A", "B"),
      group    = c("X", "X"),
      n        = c(50, 50),
      stringsAsFactors = FALSE
    )
    hc <- viz_stackedbar(
      data         = d,
      x_var        = "response",
      stack_var    = "group",
      y_var        = "n",
      stacked_type = "percent",
      title        = "Label Test"
    )
    y_title <- hc$x$hc_opts$yAxis$title$text
    expect_equal(y_title, "Percentage")
  })
})

# =============================================================================
# SECTION 4: stack_order and x_order
# =============================================================================

describe("viz_stackedbar ordering", {

  it("respects x_order for x-axis categories", {
    d <- data.frame(
      response = rep(c("Favor", "Oppose", "Neutral"), each = 2),
      group    = rep(c("A", "B"), 3),
      stringsAsFactors = FALSE
    )
    hc <- viz_stackedbar(
      data    = d,
      x_var   = "response",
      stack_var = "group",
      x_order = c("Neutral", "Oppose", "Favor"),
      title   = "Order Test"
    )
    cats <- hc$x$hc_opts$xAxis$categories
    expect_equal(cats, c("Neutral", "Oppose", "Favor"))
  })

  it("respects stack_order for series", {
    d <- data.frame(
      response = rep("A", 3),
      group    = c("Z", "Y", "X"),
      stringsAsFactors = FALSE
    )
    hc <- viz_stackedbar(
      data        = d,
      x_var       = "response",
      stack_var   = "group",
      stack_order = c("X", "Y", "Z"),
      title       = "Stack Order Test"
    )
    series_names <- vapply(hc$x$hc_opts$series, function(s) s$name, character(1))
    expect_equal(series_names, c("X", "Y", "Z"))
  })
})
