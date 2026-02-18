# Tests for add_input / add_linked_inputs in content_collection.R — lightweight, covr-safe
library(testthat)

df <- data.frame(
  country = c("US", "UK", "DE", "US", "UK", "DE", "FR"),
  metric = c("Revenue", "Revenue", "Users", "Users", "Growth", "Revenue", "Growth"),
  value = c(100, 200, 300, 400, 500, 600, 700),
  year = c(2020, 2021, 2020, 2021, 2020, 2021, 2020),
  stringsAsFactors = FALSE
)

# --- add_input: select_multiple (default) ---

test_that("add_input select_multiple with explicit options", {
  cc <- create_content(data = df) |>
    add_input(input_id = "country_filter", filter_var = "country",
              options = c("US", "UK", "DE"))
  # Should have an input block in items
  expect_true(length(cc$items) >= 1)
})

test_that("add_input auto-derives options from data", {
  cc <- create_content(data = df)
  expect_message(
    cc2 <- add_input(cc, input_id = "country_auto", filter_var = "country"),
    "Auto-derived"
  )
  expect_true(length(cc2$items) >= 1)
})

test_that("add_input select_single", {
  cc <- create_content(data = df) |>
    add_input(input_id = "metric_select", type = "select_single",
              filter_var = "metric", options = c("Revenue", "Users", "Growth"))
  expect_true(length(cc$items) >= 1)
})

# --- add_input: checkbox ---

test_that("add_input checkbox", {
  cc <- create_content(data = df) |>
    add_input(input_id = "metrics_check", type = "checkbox",
              filter_var = "metric", options = c("Revenue", "Users", "Growth"),
              inline = TRUE)
  expect_true(length(cc$items) >= 1)
})

# --- add_input: radio ---

test_that("add_input radio", {
  cc <- create_content(data = df) |>
    add_input(input_id = "chart_type", type = "radio",
              filter_var = "metric", options = c("Revenue", "Users"))
  expect_true(length(cc$items) >= 1)
})

test_that("add_input radio with add_all", {
  cc <- create_content(data = df) |>
    add_input(input_id = "chart_all", type = "radio",
              filter_var = "metric", options = c("Revenue", "Users"),
              add_all = TRUE, add_all_label = "All Metrics")
  expect_true(length(cc$items) >= 1)
})

# --- add_input: switch ---

test_that("add_input switch", {
  cc <- create_content(data = df) |>
    add_input(input_id = "show_avg", type = "switch",
              filter_var = "country",
              toggle_series = "Global Average",
              override = TRUE,
              value = TRUE)
  expect_true(length(cc$items) >= 1)
})

# --- add_input: slider ---

test_that("add_input slider", {
  cc <- create_content(data = df) |>
    add_input(input_id = "year_slider", type = "slider",
              filter_var = "year",
              min = 2020, max = 2025, step = 1, value = 2020)
  expect_true(length(cc$items) >= 1)
})

test_that("add_input slider with labels", {
  cc <- create_content(data = df) |>
    add_input(input_id = "decade_slider", type = "slider",
              filter_var = "year",
              min = 1, max = 4, step = 1, value = 1,
              labels = c("2000s", "2010s", "2020s", "2030s"))
  expect_true(length(cc$items) >= 1)
})

# --- add_input: text ---

test_that("add_input text", {
  cc <- create_content(data = df) |>
    add_input(input_id = "search_box", type = "text",
              filter_var = "country",
              placeholder = "Type to search...")
  expect_true(length(cc$items) >= 1)
})

# --- add_input: number ---

test_that("add_input number", {
  cc <- create_content(data = df) |>
    add_input(input_id = "num_input", type = "number",
              filter_var = "value",
              min = 0, max = 1000, step = 10, value = 100)
  expect_true(length(cc$items) >= 1)
})

# --- add_input: button_group ---

test_that("add_input button_group", {
  cc <- create_content(data = df) |>
    add_input(input_id = "period", type = "button_group",
              filter_var = "metric",
              options = c("Revenue", "Users", "Growth"))
  expect_true(length(cc$items) >= 1)
})

test_that("add_input button_group with add_all", {
  cc <- create_content(data = df) |>
    add_input(input_id = "period_all", type = "button_group",
              filter_var = "metric",
              options = c("Revenue", "Users"),
              add_all = TRUE)
  expect_true(length(cc$items) >= 1)
})

# --- add_input: styling options ---

test_that("add_input with size variants", {
  for (s in c("sm", "md", "lg")) {
    cc <- create_content(data = df) |>
      add_input(input_id = paste0("sz_", s), type = "text",
                filter_var = "country", size = s)
    expect_true(length(cc$items) >= 1)
  }
})

test_that("add_input with help text", {
  cc <- create_content(data = df) |>
    add_input(input_id = "help_input", type = "text",
              filter_var = "country", help = "Enter a country name")
  expect_true(length(cc$items) >= 1)
})

test_that("add_input with margins", {
  cc <- create_content(data = df) |>
    add_input(input_id = "margin_input", type = "text",
              filter_var = "country",
              mt = "10px", mr = "5px", mb = "10px", ml = "5px")
  expect_true(length(cc$items) >= 1)
})

test_that("add_input disabled", {
  cc <- create_content(data = df) |>
    add_input(input_id = "disabled_input", type = "text",
              filter_var = "country", disabled = TRUE)
  expect_true(length(cc$items) >= 1)
})

test_that("add_input with width", {
  cc <- create_content(data = df) |>
    add_input(input_id = "wide_input", type = "text",
              filter_var = "country", width = "500px")
  expect_true(length(cc$items) >= 1)
})

# --- add_input: stacked options ---

test_that("add_input checkbox stacked", {
  cc <- create_content(data = df) |>
    add_input(input_id = "stacked_check", type = "checkbox",
              filter_var = "metric", options = c("Revenue", "Users"),
              stacked = TRUE, stacked_align = "left")
  expect_true(length(cc$items) >= 1)
})

# --- add_input: validation ---

test_that("add_input error: missing input_id", {
  expect_error(
    create_content(data = df) |>
      add_input(filter_var = "country"),
    "input_id"
  )
})

test_that("add_input error: missing filter_var", {
  expect_error(
    create_content(data = df) |>
      add_input(input_id = "test"),
    "filter_var"
  )
})

test_that("add_input error: no options and no data", {
  expect_error(
    create_content() |>
      add_input(input_id = "test", filter_var = "country"),
    "options"
  )
})

test_that("add_input error: column not in data", {
  expect_error(
    create_content(data = df) |>
      add_input(input_id = "test", filter_var = "nonexistent"),
    "not found"
  )
})

test_that("add_input warns on option mismatch", {
  expect_warning(
    create_content(data = df) |>
      add_input(input_id = "test", filter_var = "country",
                options = c("US", "UK", "NOPE")),
    "don't match"
  )
})

# --- add_input in sidebar ---

test_that("add_input in sidebar", {
  cc <- create_content(data = df) |>
    add_sidebar() |>
      add_input(input_id = "side_filter", filter_var = "country",
                options = c("US", "UK", "DE")) |>
    end_sidebar()
  expect_true(!is.null(cc$sidebar))
})

# --- add_linked_inputs ---

test_that("add_linked_inputs creates parent-child inputs", {
  cc <- create_content(data = df) |>
    add_sidebar() |>
      add_linked_inputs(
        parent = list(id = "dim", label = "Dimension",
                      options = c("Revenue", "Users")),
        child = list(id = "question", label = "Question",
                     options_by_parent = list(
                       "Revenue" = c("Q1", "Q2"),
                       "Users" = c("Q3", "Q4")
                     ))
      ) |>
    end_sidebar()
  expect_true(!is.null(cc$sidebar))
  expect_true(isTRUE(cc$sidebar$needs_linked_inputs))
})

test_that("add_linked_inputs works in standalone content collections", {
  cc <- add_linked_inputs(
    create_content(),
    parent = list(id = "dim", label = "X", options = c("A")),
    child = list(id = "q", label = "Y", options_by_parent = list("A" = c("a")))
  )

  expect_true(inherits(cc, "content_collection"))
  expect_true(isTRUE(cc$needs_linked_inputs))
})

test_that("add_linked_inputs error: missing parent fields", {
  cc <- create_content() |> add_sidebar()
  expect_error(
    add_linked_inputs(cc,
      parent = list(id = "dim"),  # missing label, options
      child = list(id = "q", label = "Y", options_by_parent = list("A" = c("a")))
    ),
    "id, label, and options"
  )
})

test_that("add_linked_inputs error: missing child fields", {
  cc <- create_content() |> add_sidebar()
  expect_error(
    add_linked_inputs(cc,
      parent = list(id = "dim", label = "X", options = c("A")),
      child = list(id = "q")  # missing label, options_by_parent
    ),
    "id, label, and options_by_parent"
  )
})

test_that("add_linked_inputs normalizes options_by_parent values to character vectors", {
  cc <- create_content() |>
    add_sidebar() |>
    add_linked_inputs(
      parent = list(id = "dim", label = "Dimension", options = c("A", "B")),
      child = list(
        id = "q",
        label = "Question",
        options_by_parent = list(
          "A" = "alpha",
          "B" = c("beta", "gamma")
        )
      )
    ) |>
    end_sidebar()

  child_block <- cc$sidebar$blocks[[2]]
  expect_true(is.character(child_block$.options_by_parent$A))
  expect_identical(child_block$.options_by_parent$A, c("alpha"))
  expect_identical(child_block$.options_by_parent$B, c("beta", "gamma"))
})

test_that("add_linked_inputs errors when options_by_parent misses a parent option", {
  cc <- create_content() |> add_sidebar()
  expect_error(
    add_linked_inputs(
      cc,
      parent = list(id = "dim", label = "Dimension", options = c("A", "B")),
      child = list(
        id = "q",
        label = "Question",
        options_by_parent = list("A" = c("alpha"))
      )
    ),
    "must contain a key for parent value: B"
  )
})
