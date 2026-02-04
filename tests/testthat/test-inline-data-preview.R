# =============================================================================
# Tests for inline data and preview() function
# =============================================================================

# -----------------------------------------------------------------------------
# Tests for data parameter in create_viz() / create_content()
# -----------------------------------------------------------------------------

test_that("create_viz accepts data parameter", {
  viz <- create_viz(data = mtcars)
  
  expect_s3_class(viz, "viz_collection")
  expect_s3_class(viz, "content_collection")
  expect_identical(viz$data, mtcars)
})

test_that("create_content accepts data parameter", {
  content <- create_content(data = iris)
  
  expect_s3_class(content, "content_collection")
  expect_identical(content$data, iris)
})

test_that("create_viz with data and defaults works together", {
  viz <- create_viz(
    data = mtcars,
    type = "histogram",
    color_palette = c("red", "blue")
  )
  
  expect_identical(viz$data, mtcars)
  expect_equal(viz$defaults$type, "histogram")
  expect_equal(viz$defaults$color_palette, c("red", "blue"))
})

test_that("combine_content preserves data field", {
  viz1 <- create_viz(data = mtcars) %>%
    add_viz(type = "histogram", x_var = "mpg")
  
  viz2 <- create_viz() %>%
    add_viz(type = "histogram", x_var = "hp")
  
  combined <- combine_content(viz1, viz2)
  
  # Data from first collection should be preserved
  expect_identical(combined$data, mtcars)
})

# -----------------------------------------------------------------------------
# Tests for add_viz with inline data frames
# -----------------------------------------------------------------------------

test_that("add_viz accepts data frame as data parameter", {
  viz <- create_viz() %>%
    add_viz(type = "histogram", x_var = "mpg", data = mtcars)
  
  item <- viz$items[[1]]
  expect_true(item$data_is_dataframe)
  # Data frames are serialized to survive pipeline processing
  expect_true(!is.null(item$data_serialized))
  reconstructed <- as.data.frame(eval(parse(text = item$data_serialized)))
  # Compare data values (row.names may differ due to serialization)
  expect_equal(reconstructed, mtcars, ignore_attr = TRUE)
})

test_that("add_viz accepts string as data parameter (dataset name)", {
  viz <- create_viz() %>%
    add_viz(type = "histogram", x_var = "mpg", data = "my_dataset")
  
  item <- viz$items[[1]]
  expect_false(item$data_is_dataframe)
  expect_equal(item$data, "my_dataset")
})

# -----------------------------------------------------------------------------
# Tests for preview() function - direct mode
# -----------------------------------------------------------------------------

test_that("preview requires data to be attached", {
  viz <- create_viz() %>%
    add_viz(type = "histogram", x_var = "mpg")
  
  expect_error(
    preview(viz, open = FALSE),
    "No data attached"
  )
})

test_that("preview requires non-empty collection", {
  viz <- create_viz(data = mtcars)
  
  expect_error(
    preview(viz, open = FALSE),
    "Collection is empty"
  )
})

test_that("preview direct mode generates HTML file", {
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "histogram", x_var = "mpg", title = "Test Histogram")
  
  html_path <- preview(viz, open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(html_path))
  expect_match(html_path, "\\.html$")
  
  # Check content
  html_content <- readLines(html_path)
  expect_true(any(grepl("Test Histogram", html_content)))
})

test_that("preview direct mode works with multiple visualizations", {
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "histogram", x_var = "mpg", title = "MPG") %>%
    add_viz(type = "histogram", x_var = "hp", title = "HP")
  
  html_path <- preview(viz, open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(html_path))
  
  html_content <- paste(readLines(html_path), collapse = "\n")
  expect_true(grepl("MPG", html_content))
  expect_true(grepl("HP", html_content))
})

test_that("preview direct mode handles filters", {
  viz <- create_viz(data = mtcars) %>%
    add_viz(
      type = "histogram",
      x_var = "mpg",
      title = "Filtered",
      filter = ~ cyl == 4
    )
  
  # Should not error
  html_path <- preview(viz, open = FALSE, quarto = FALSE)
  expect_true(file.exists(html_path))
})

test_that("preview title parameter works", {
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "histogram", x_var = "mpg")
  
  html_path <- preview(viz, title = "Custom Title", open = FALSE, quarto = FALSE)
  
  html_content <- paste(readLines(html_path), collapse = "\n")
  expect_true(grepl("Custom Title", html_content))
})

# -----------------------------------------------------------------------------
# Tests for collection data fallback in add_page
# -----------------------------------------------------------------------------

test_that("add_page uses collection data as fallback", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  # Create viz with data attached
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "histogram", x_var = "mpg", title = "Test")
  
  # Create dashboard without passing data to add_page
  dashboard <- create_dashboard(
    output_dir = temp_dir,
    title = "Test Dashboard"
  ) %>%
    add_page("Analysis", visualizations = viz)  # No data = should use viz$data
  
  # Check page has data_path (meaning data was picked up)
  page <- dashboard$pages[[1]]
  expect_false(is.null(page$data_path))
})

# -----------------------------------------------------------------------------
# Tests for defaults inheritance (type parameter)
# -----------------------------------------------------------------------------

test_that("type default is inherited from create_viz to add_viz", {
  viz <- create_viz(type = "histogram") %>%
    add_viz(x_var = "mpg")
  
  item <- viz$items[[1]]
  expect_equal(item$viz_type, "histogram")
})

test_that("type default is inherited from create_content to add_viz", {
  content <- create_content(type = "stackedbar") %>%
    add_viz(x_var = "cyl", stack_var = "gear")
  
  item <- content$items[[1]]
  expect_equal(item$viz_type, "stackedbar")
})

test_that("explicit type in add_viz overrides default", {
  viz <- create_viz(type = "histogram") %>%
    add_viz(type = "bar", x_var = "mpg")  # Override to bar
  
  item <- viz$items[[1]]
  expect_equal(item$viz_type, "bar")
})

# -----------------------------------------------------------------------------
# Tests for viz generation excludes internal params
# -----------------------------------------------------------------------------

test_that("data_is_dataframe is excluded from viz function calls", {
  # This tests that the internal parameter doesn't leak through
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "histogram", x_var = "mpg", data = mtcars)
  
  # Direct preview should work without "unused argument" error
  expect_no_error({
    html_path <- preview(viz, open = FALSE, quarto = FALSE)
  })
})

# -----------------------------------------------------------------------------
# Tests for knit_print methods
# -----------------------------------------------------------------------------

test_that("knit_print renders collection with data as HTML", {
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "histogram", x_var = "mpg", title = "MPG")
  
  result <- knitr::knit_print(viz)
  
  # Should be an asis_output (not showing structure)
  expect_s3_class(result, "knit_asis")
  # Should contain the title
  expect_true(grepl("MPG", as.character(result)))
})

test_that("knit_print shows structure for collection without data", {
  viz <- create_viz() %>%
    add_viz(type = "histogram", x_var = "mpg", title = "MPG")
  
  result <- knitr::knit_print(viz)
  
  # Should be an asis_output with structure
  expect_s3_class(result, "knit_asis")
  # Should contain "Collection" (from structure print)
  expect_true(grepl("Collection", as.character(result), ignore.case = TRUE))
})

test_that("knit_print handles tabgroups", {
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "histogram", x_var = "mpg", title = "MPG", tabgroup = "Test") %>%
    add_viz(type = "histogram", x_var = "hp", title = "HP", tabgroup = "Test")
  
  result <- knitr::knit_print(viz)
  
  expect_s3_class(result, "knit_asis")
  # Should contain tab elements (using vtab classes from .render_tabbed_simple)
  expect_true(grepl("vtab-btn|vtab-pane|data-tab", as.character(result)))
})

# -----------------------------------------------------------------------------
# Tests for .render_collection_inline
# -----------------------------------------------------------------------------

test_that(".render_collection_inline renders single viz", {
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "histogram", x_var = "mpg", title = "MPG")
  
  result <- .render_collection_inline(viz)
  
  expect_s3_class(result, "shiny.tag.list")
  expect_true(grepl("MPG", as.character(result)))
})

test_that(".render_collection_inline renders stacked vizzes", {
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "histogram", x_var = "mpg", title = "MPG") %>%
    add_viz(type = "histogram", x_var = "hp", title = "HP")
  
  result <- .render_collection_inline(viz)
  
  html_str <- as.character(result)
  expect_true(grepl("MPG", html_str))
  expect_true(grepl("HP", html_str))
})

test_that(".render_collection_inline renders tabgroups as Bootstrap tabs", {
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "histogram", x_var = "mpg", tabgroup = "Metrics") %>%
    add_viz(type = "histogram", x_var = "hp", tabgroup = "Metrics")
  
  result <- .render_collection_inline(viz)
  
  html_str <- as.character(result)
  # Should have Bootstrap tab classes (used by .render_collection_inline)
  expect_true(grepl("nav-tabs", html_str))
  expect_true(grepl("tab-content", html_str))
  expect_true(grepl("tab-pane", html_str))
})

# -----------------------------------------------------------------------------
# Tests for print with render argument
# -----------------------------------------------------------------------------

test_that("print with render = FALSE shows structure", {
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "histogram", x_var = "mpg")
  
  output <- capture.output(print(viz, render = FALSE))
  
  expect_true(any(grepl("Collection", output, ignore.case = TRUE)))
})

# -----------------------------------------------------------------------------
# Tests for path parameter
# -----------------------------------------------------------------------------

test_that("preview accepts path parameter as file", {
  temp_file <- tempfile(fileext = ".html")
  on.exit(unlink(temp_file), add = TRUE)
  
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "histogram", x_var = "mpg")
  
  result_path <- preview(viz, path = temp_file, open = FALSE, quarto = FALSE)
  
  expect_equal(normalizePath(result_path), normalizePath(temp_file))
  expect_true(file.exists(temp_file))
})

test_that("preview accepts path parameter as directory", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "histogram", x_var = "mpg")
  
  result_path <- preview(viz, path = temp_dir, open = FALSE, quarto = FALSE)
  
  expect_true(file.exists(result_path))
  expect_match(result_path, "preview\\.html$")
  expect_equal(dirname(normalizePath(result_path)), normalizePath(temp_dir))
})

# -----------------------------------------------------------------------------
# Tests for tabgroup warning
# -----------------------------------------------------------------------------

test_that("preview warns when using tabgroups with quarto = FALSE in interactive mode", {
  skip_if_not(interactive(), "Warning only shown in interactive sessions")
  
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "histogram", x_var = "mpg", tabgroup = "Test")
  
  expect_warning(
    preview(viz, open = FALSE, quarto = FALSE),
    "tabgroups/tabsets"
  )
})

test_that("preview does not warn without tabgroups", {
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "histogram", x_var = "mpg")
  
  expect_no_warning({
    preview(viz, open = FALSE, quarto = FALSE)
  })
})
