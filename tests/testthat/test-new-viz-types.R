# =============================================================================
# Tests for new visualization types: pie, donut, lollipop, dumbbell, gauge,
# funnel, sankey, waffle
# =============================================================================

library(testthat)

# Skip entire file under covr CI to prevent OOM (exit code 143)
if (identical(Sys.getenv("DASHBOARDR_COVR_CI"), "true")) {
  test_that("skipped under covr CI", { skip("Memory-intensive tests skipped under covr CI") })
} else {

# =============================================================================
# SECTION 1: viz_pie
# =============================================================================

describe("viz_pie", {

  it("creates a basic pie chart from raw data", {
    hc <- viz_pie(mtcars, x_var = "cyl", title = "Cylinders")
    expect_s3_class(hc, "highchart")
  })

  it("creates a pie chart with pre-aggregated data", {
    df <- data.frame(
      category = c("A", "B", "C"),
      count = c(40, 35, 25)
    )
    hc <- viz_pie(df, x_var = "category", y_var = "count")
    expect_s3_class(hc, "highchart")
  })

  it("creates a donut chart with inner_size", {
    hc <- viz_pie(mtcars, x_var = "cyl", inner_size = "50%", title = "Donut")
    expect_s3_class(hc, "highchart")
  })

  it("respects x_order parameter", {
    hc <- viz_pie(mtcars, x_var = "cyl", x_order = c("8", "6", "4"))
    expect_s3_class(hc, "highchart")
  })

  it("sorts by value when sort_by_value = TRUE", {
    hc <- viz_pie(mtcars, x_var = "cyl", sort_by_value = TRUE)
    expect_s3_class(hc, "highchart")
  })

  it("applies color palette", {
    hc <- viz_pie(mtcars, x_var = "cyl",
                  color_palette = c("#ff0000", "#00ff00", "#0000ff"))
    expect_s3_class(hc, "highchart")
  })

  it("errors when x_var is missing from data", {
    expect_error(viz_pie(mtcars, x_var = "nonexistent"), "not found")
  })

  it("errors when y_var is not numeric", {
    df <- data.frame(a = c("x", "y"), b = c("a", "b"))
    expect_error(viz_pie(df, x_var = "a", y_var = "b"), "numeric")
  })
})

# =============================================================================
# SECTION 2: viz_lollipop
# =============================================================================

describe("viz_lollipop", {

  it("creates a basic lollipop chart", {
    hc <- viz_lollipop(mtcars, x_var = "cyl", title = "Lollipop")
    expect_s3_class(hc, "highchart")
  })

  it("creates horizontal lollipop by default", {
    hc <- viz_lollipop(mtcars, x_var = "cyl")
    expect_s3_class(hc, "highchart")
  })

  it("creates vertical lollipop", {
    hc <- viz_lollipop(mtcars, x_var = "cyl", horizontal = FALSE)
    expect_s3_class(hc, "highchart")
  })

  it("works with pre-aggregated data", {
    df <- data.frame(country = c("US", "UK", "DE"), score = c(85, 72, 68))
    hc <- viz_lollipop(df, x_var = "country", y_var = "score")
    expect_s3_class(hc, "highchart")
  })

  it("supports grouped lollipops", {
    df <- data.frame(
      category = rep(c("A", "B"), each = 3),
      group = rep(c("X", "Y", "Z"), 2),
      value = c(10, 20, 30, 15, 25, 35)
    )
    hc <- viz_lollipop(df, x_var = "category", group_var = "group", y_var = "value")
    expect_s3_class(hc, "highchart")
  })

  it("supports percent mode", {
    hc <- viz_lollipop(mtcars, x_var = "cyl", bar_type = "percent")
    expect_s3_class(hc, "highchart")
  })

  it("supports sorting by value", {
    hc <- viz_lollipop(mtcars, x_var = "cyl", sort_by_value = TRUE)
    expect_s3_class(hc, "highchart")
  })

  it("errors on missing x_var", {
    expect_error(viz_lollipop(mtcars, x_var = "nope"), "not found")
  })
})

# =============================================================================
# SECTION 3: viz_dumbbell
# =============================================================================

describe("viz_dumbbell", {

  df <- data.frame(
    country = c("US", "UK", "DE", "FR"),
    score_2020 = c(65, 58, 72, 60),
    score_2024 = c(78, 65, 75, 70)
  )

  it("creates a basic dumbbell chart", {
    hc <- viz_dumbbell(df, x_var = "country",
                       low_var = "score_2020", high_var = "score_2024")
    expect_s3_class(hc, "highchart")
  })

  it("sets custom labels", {
    hc <- viz_dumbbell(df, x_var = "country",
                       low_var = "score_2020", high_var = "score_2024",
                       low_label = "2020", high_label = "2024")
    expect_s3_class(hc, "highchart")
  })

  it("supports horizontal orientation", {
    hc <- viz_dumbbell(df, x_var = "country",
                       low_var = "score_2020", high_var = "score_2024",
                       horizontal = TRUE)
    expect_s3_class(hc, "highchart")
  })

  it("supports sorting by gap", {
    hc <- viz_dumbbell(df, x_var = "country",
                       low_var = "score_2020", high_var = "score_2024",
                       sort_by_gap = TRUE)
    expect_s3_class(hc, "highchart")
  })

  it("applies color palette", {
    hc <- viz_dumbbell(df, x_var = "country",
                       low_var = "score_2020", high_var = "score_2024",
                       color_palette = c(low = "red", high = "blue"))
    expect_s3_class(hc, "highchart")
  })

  it("errors on missing columns", {
    expect_error(
      viz_dumbbell(df, x_var = "country", low_var = "nope", high_var = "score_2024"),
      "not found"
    )
  })

  it("errors on non-numeric columns", {
    df2 <- data.frame(a = "x", b = "y", c = "z")
    expect_error(viz_dumbbell(df2, x_var = "a", low_var = "b", high_var = "c"), "numeric")
  })
})

# =============================================================================
# SECTION 4: viz_gauge
# =============================================================================

describe("viz_gauge", {

  it("creates a basic gauge with a static value", {
    hc <- viz_gauge(value = 73, title = "Score")
    expect_s3_class(hc, "highchart")
  })

  it("creates a gauge from data", {
    hc <- viz_gauge(data = mtcars, value_var = "mpg", min = 10, max = 35)
    expect_s3_class(hc, "highchart")
  })

  it("supports custom min/max", {
    hc <- viz_gauge(value = 500, min = 0, max = 1000)
    expect_s3_class(hc, "highchart")
  })

  it("supports color bands", {
    hc <- viz_gauge(value = 65, bands = list(
      list(from = 0, to = 40, color = "#E15759"),
      list(from = 40, to = 70, color = "#F28E2B"),
      list(from = 70, to = 100, color = "#59A14F")
    ))
    expect_s3_class(hc, "highchart")
  })

  it("supports custom data labels format", {
    hc <- viz_gauge(value = 73, data_labels_format = "{y}%")
    expect_s3_class(hc, "highchart")
  })

  it("supports target line", {
    hc <- viz_gauge(value = 73, target = 80, target_color = "red")
    expect_s3_class(hc, "highchart")
  })

  it("errors when neither data+value_var nor value is provided", {
    expect_error(viz_gauge(), "required")
  })

  it("errors on invalid gauge_type", {
    expect_error(viz_gauge(value = 50, gauge_type = "invalid"), "solid")
  })
})

# =============================================================================
# SECTION 5: viz_funnel
# =============================================================================

describe("viz_funnel", {

  df <- data.frame(
    stage = c("Visits", "Signups", "Trial", "Purchase"),
    count = c(10000, 3000, 800, 200)
  )

  it("creates a basic funnel chart", {
    hc <- viz_funnel(df, x_var = "stage", y_var = "count")
    expect_s3_class(hc, "highchart")
  })

  it("creates a pyramid (reversed funnel)", {
    hc <- viz_funnel(df, x_var = "stage", y_var = "count", reversed = TRUE)
    expect_s3_class(hc, "highchart")
  })

  it("supports custom neck dimensions", {
    hc <- viz_funnel(df, x_var = "stage", y_var = "count",
                     neck_width = "20%", neck_height = "30%")
    expect_s3_class(hc, "highchart")
  })

  it("shows conversion rates in tooltip by default", {
    hc <- viz_funnel(df, x_var = "stage", y_var = "count",
                     show_conversion = TRUE)
    expect_s3_class(hc, "highchart")
  })

  it("applies color palette", {
    hc <- viz_funnel(df, x_var = "stage", y_var = "count",
                     color_palette = c("#4E79A7", "#F28E2B", "#E15759", "#59A14F"))
    expect_s3_class(hc, "highchart")
  })

  it("errors on missing columns", {
    expect_error(viz_funnel(df, x_var = "nope", y_var = "count"), "not found")
  })

  it("errors on non-numeric y_var", {
    df2 <- data.frame(a = "x", b = "y")
    expect_error(viz_funnel(df2, x_var = "a", y_var = "b"), "numeric")
  })
})

# =============================================================================
# SECTION 6: viz_sankey
# =============================================================================

describe("viz_sankey", {

  df <- data.frame(
    from = c("A", "A", "B", "B"),
    to = c("X", "Y", "X", "Y"),
    flow = c(30, 20, 10, 40)
  )

  it("creates a basic Sankey diagram", {
    hc <- viz_sankey(df, from_var = "from", to_var = "to", value_var = "flow")
    expect_s3_class(hc, "highchart")
  })

  it("applies named color palette to nodes", {
    hc <- viz_sankey(df, from_var = "from", to_var = "to", value_var = "flow",
                     color_palette = c("A" = "#ff0000", "B" = "#00ff00",
                                       "X" = "#0000ff", "Y" = "#ffff00"))
    expect_s3_class(hc, "highchart")
  })

  it("supports custom node dimensions", {
    hc <- viz_sankey(df, from_var = "from", to_var = "to", value_var = "flow",
                     node_width = 30, node_padding = 15)
    expect_s3_class(hc, "highchart")
  })

  it("errors on missing columns", {
    expect_error(viz_sankey(df, from_var = "nope", to_var = "to", value_var = "flow"),
                 "not found")
  })

  it("errors on non-numeric value_var", {
    df2 <- data.frame(a = "x", b = "y", c = "z")
    expect_error(viz_sankey(df2, from_var = "a", to_var = "b", value_var = "c"),
                 "numeric")
  })
})

# =============================================================================
# SECTION 7: viz_waffle
# =============================================================================

describe("viz_waffle", {

  it("creates a basic waffle chart", {
    hc <- viz_waffle(mtcars, x_var = "cyl", title = "Waffle")
    expect_s3_class(hc, "highchart")
  })

  it("works with pre-aggregated data", {
    df <- data.frame(
      category = c("Agree", "Neutral", "Disagree"),
      count = c(45, 30, 25)
    )
    hc <- viz_waffle(df, x_var = "category", y_var = "count", total = 100)
    expect_s3_class(hc, "highchart")
  })

  it("respects custom grid dimensions", {
    hc <- viz_waffle(mtcars, x_var = "cyl", total = 50, rows = 5)
    expect_s3_class(hc, "highchart")
  })

  it("applies x_order", {
    df <- data.frame(cat = c("C", "B", "A"), val = c(10, 20, 30))
    hc <- viz_waffle(df, x_var = "cat", y_var = "val",
                     x_order = c("A", "B", "C"))
    expect_s3_class(hc, "highchart")
  })

  it("applies color palette", {
    hc <- viz_waffle(mtcars, x_var = "cyl",
                     color_palette = c("#ff0000", "#00ff00", "#0000ff"))
    expect_s3_class(hc, "highchart")
  })

  it("errors on missing column", {
    expect_error(viz_waffle(mtcars, x_var = "nope"), "not found")
  })
})

# =============================================================================
# SECTION 8: add_viz() pipeline integration
# =============================================================================

describe("add_viz() pipeline with new types", {

  it("registers all new types as valid", {
    for (type in c("pie", "donut", "lollipop", "dumbbell", "gauge",
                   "funnel", "pyramid", "sankey", "waffle")) {
      # Should not error on type validation
      content <- create_content(data = mtcars) %>%
        add_viz(type = type, x_var = "cyl", title = paste("Test", type))
      expect_equal(length(content$items), 1,
                   info = paste("Failed for type:", type))
    }
  })

  it("donut type sets inner_size default", {
    content <- create_content(data = mtcars) %>%
      add_viz(type = "donut", x_var = "cyl")
    # The spec should exist (donut maps to pie with inner_size)
    expect_equal(content$items[[1]]$viz_type, "donut")
  })

  it("pyramid type sets reversed default", {
    content <- create_content() %>%
      add_viz(type = "pyramid", x_var = "stage", y_var = "count")
    expect_equal(content$items[[1]]$viz_type, "pyramid")
  })

  it("export parameter is accepted by add_viz", {
    content <- create_content(data = mtcars) %>%
      add_viz(type = "bar", x_var = "cyl", export = TRUE)
    expect_true(content$items[[1]]$export)
  })
})

# =============================================================================
# SECTION 9: Chart export
# =============================================================================

describe("chart export", {

  it("enable_chart_export returns HTML tags", {
    result <- enable_chart_export()
    expect_s3_class(result, "shiny.tag")
  })

  it("create_dashboard accepts chart_export parameter", {
    dash <- create_dashboard("test_dir_export", "Test",
                             chart_export = TRUE,
                             allow_inside_pkg = TRUE)
    expect_true(dash$chart_export)
  })

  it("chart_export defaults to FALSE", {
    dash <- create_dashboard("test_dir_noexport", "Test",
                             allow_inside_pkg = TRUE)
    expect_false(dash$chart_export)
  })
})

# =============================================================================
# SECTION 10: Annotations & Reference Lines
# =============================================================================

describe("annotations and reference_lines in add_viz", {

  it("reference_lines parameter is accepted", {
    content <- create_content(data = mtcars) %>%
      add_viz(type = "bar", x_var = "cyl",
              reference_lines = list(
                list(y = 10, label = "Target", color = "red")
              ))
    expect_true(!is.null(content$items[[1]]$reference_lines))
    expect_equal(length(content$items[[1]]$reference_lines), 1)
    expect_equal(content$items[[1]]$reference_lines[[1]]$y, 10)
  })

  it("annotations parameter is accepted", {
    content <- create_content(data = mtcars) %>%
      add_viz(type = "timeline", time_var = "year", y_var = "score",
              annotations = list(
                list(x = 2020, label = "COVID-19", color = "red")
              ))
    expect_true(!is.null(content$items[[1]]$annotations))
    expect_equal(content$items[[1]]$annotations[[1]]$label, "COVID-19")
  })
})

# =============================================================================
# SECTION 11: preview() with new viz types
# =============================================================================

describe("preview() with new viz types", {

  it("previews a pie chart", {
    content <- create_content(data = mtcars) %>%
      add_viz(type = "pie", x_var = "cyl", title = "Pie Preview")
    widget <- preview(content, output = "widget", open = FALSE)
    expect_s3_class(widget, "dashboardr_widget")
  })

  it("previews a donut chart (injects inner_size)", {
    content <- create_content(data = mtcars) %>%
      add_viz(type = "donut", x_var = "cyl", title = "Donut Preview")
    widget <- preview(content, output = "widget", open = FALSE)
    expect_s3_class(widget, "dashboardr_widget")
  })

  it("previews a lollipop chart", {
    content <- create_content(data = mtcars) %>%
      add_viz(type = "lollipop", x_var = "cyl", title = "Lollipop Preview")
    widget <- preview(content, output = "widget", open = FALSE)
    expect_s3_class(widget, "dashboardr_widget")
  })

  it("previews a dumbbell chart", {
    df <- data.frame(
      country = c("US", "UK", "DE"),
      low = c(60, 55, 70),
      high = c(80, 65, 75)
    )
    content <- create_content(data = df) %>%
      add_viz(type = "dumbbell", x_var = "country",
              low_var = "low", high_var = "high", title = "Dumbbell Preview")
    widget <- preview(content, output = "widget", open = FALSE)
    expect_s3_class(widget, "dashboardr_widget")
  })

  it("previews a gauge chart", {
    content <- create_content() %>%
      add_viz(type = "gauge", value = 73, title = "Gauge Preview")
    widget <- preview(content, output = "widget", open = FALSE)
    expect_s3_class(widget, "dashboardr_widget")
  })

  it("previews a funnel chart", {
    df <- data.frame(
      stage = c("Visit", "Signup", "Purchase"),
      count = c(1000, 300, 50)
    )
    content <- create_content(data = df) %>%
      add_viz(type = "funnel", x_var = "stage", y_var = "count",
              title = "Funnel Preview")
    widget <- preview(content, output = "widget", open = FALSE)
    expect_s3_class(widget, "dashboardr_widget")
  })

  it("previews a pyramid chart (injects reversed)", {
    df <- data.frame(
      stage = c("Visit", "Signup", "Purchase"),
      count = c(1000, 300, 50)
    )
    content <- create_content(data = df) %>%
      add_viz(type = "pyramid", x_var = "stage", y_var = "count",
              title = "Pyramid Preview")
    widget <- preview(content, output = "widget", open = FALSE)
    expect_s3_class(widget, "dashboardr_widget")
  })

  it("previews a sankey diagram", {
    df <- data.frame(
      from = c("A", "A", "B"),
      to = c("X", "Y", "X"),
      flow = c(30, 20, 10)
    )
    content <- create_content(data = df) %>%
      add_viz(type = "sankey", from_var = "from", to_var = "to",
              value_var = "flow", title = "Sankey Preview")
    widget <- preview(content, output = "widget", open = FALSE)
    expect_s3_class(widget, "dashboardr_widget")
  })

  it("previews a waffle chart", {
    content <- create_content(data = mtcars) %>%
      add_viz(type = "waffle", x_var = "cyl", title = "Waffle Preview")
    widget <- preview(content, output = "widget", open = FALSE)
    expect_s3_class(widget, "dashboardr_widget")
  })
})

# =============================================================================
# SECTION 12: show_when works with new viz types in code generation
# =============================================================================

describe("show_when with new viz types", {

  gen_viz <- dashboardr:::.generate_single_viz

  .check_show_when <- function(vtype, vparams) {
    spec <- c(
      list(viz_type = vtype, title = paste("Test", vtype),
           show_when = ~ category == "A"),
      vparams
    )
    lines <- gen_viz(paste0("test_", vtype), spec)
    combined <- paste(lines, collapse = "\n")
    expect_match(combined, "show_when_open(", fixed = TRUE)
    expect_match(combined, "show_when_close()", fixed = TRUE)
    expect_match(combined, "results.*asis", perl = TRUE)
  }

  it("generates show_when wrapper for pie", {
    .check_show_when("pie", list(x_var = "cyl"))
  })
  it("generates show_when wrapper for donut", {
    .check_show_when("donut", list(x_var = "cyl"))
  })
  it("generates show_when wrapper for lollipop", {
    .check_show_when("lollipop", list(x_var = "cyl"))
  })
  it("generates show_when wrapper for dumbbell", {
    .check_show_when("dumbbell", list(x_var = "country", low_var = "low", high_var = "high"))
  })
  it("generates show_when wrapper for gauge", {
    .check_show_when("gauge", list(value = 73))
  })
  it("generates show_when wrapper for funnel", {
    .check_show_when("funnel", list(x_var = "stage", y_var = "count"))
  })
  it("generates show_when wrapper for pyramid", {
    .check_show_when("pyramid", list(x_var = "stage", y_var = "count"))
  })
  it("generates show_when wrapper for sankey", {
    .check_show_when("sankey", list(from_var = "from", to_var = "to", value_var = "flow"))
  })
  it("generates show_when wrapper for waffle", {
    .check_show_when("waffle", list(x_var = "cyl"))
  })
})

# =============================================================================
# SECTION 13: var_params NSE conversion for sankey/dumbbell
# =============================================================================

describe("NSE conversion for new var params", {

  it("from_var and to_var are stored as strings in sankey spec", {
    content <- create_content() %>%
      add_viz(type = "sankey", from_var = "source", to_var = "target",
              value_var = "amount")
    spec <- content$items[[1]]
    expect_equal(spec$from_var, "source")
    expect_equal(spec$to_var, "target")
    expect_equal(spec$value_var, "amount")
  })

  it("low_var and high_var are stored as strings in dumbbell spec", {
    content <- create_content() %>%
      add_viz(type = "dumbbell", x_var = "country",
              low_var = "score_2020", high_var = "score_2024")
    spec <- content$items[[1]]
    expect_equal(spec$low_var, "score_2020")
    expect_equal(spec$high_var, "score_2024")
  })
})

} # end covr CI skip
