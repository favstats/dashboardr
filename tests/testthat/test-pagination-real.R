test_that("add_pagination() creates pagination markers in viz collection", {
  vizzes <- create_viz() %>%
    add_viz(type = "bar", x_var = "cyl") %>%
    add_pagination() %>%
    add_viz(type = "histogram", x_var = "mpg")
  
  # Check that pagination marker was added
  expect_equal(length(vizzes$items), 3)
  expect_equal(vizzes$items[[2]]$type, "pagination")
  expect_true(vizzes$items[[2]]$pagination_break)
})

test_that("add_pagination() works with multiple markers", {
  vizzes <- create_viz() %>%
    add_viz(type = "bar", x_var = "cyl") %>%
    add_pagination() %>%
    add_viz(type = "histogram", x_var = "mpg") %>%
    add_pagination() %>%
    add_viz(type = "bar", x_var = "gear")
  
  # Check multiple pagination markers
  expect_equal(length(vizzes$items), 5)
  expect_equal(vizzes$items[[2]]$type, "pagination")
  expect_equal(vizzes$items[[4]]$type, "pagination")
})

test_that("pagination creates multiple QMD files", {
  temp_dir <- withr::local_tempdir()
  
  vizzes <- create_viz() %>%
    add_viz(type = "bar", x_var = "cyl") %>%
    add_pagination() %>%
    add_viz(type = "histogram", x_var = "mpg") %>%
    add_pagination() %>%
    add_viz(type = "bar", x_var = "gear")
  
  proj <- create_dashboard(output_dir = temp_dir, title = "Test") %>%
    add_page("Analysis", data = mtcars, visualizations = vizzes)
  
  result <- generate_dashboard(proj, render = FALSE, open = FALSE)
  
  # Get absolute paths
  output_dir <- normalizePath(result$output_dir, mustWork = FALSE)
  
  # Should create 3 separate QMD files
  expect_true(file.exists(file.path(output_dir, "analysis.qmd")))
  expect_true(file.exists(file.path(output_dir, "analysis_p2.qmd")))
  expect_true(file.exists(file.path(output_dir, "analysis_p3.qmd")))
})

test_that("first page has navigation to next", {
  temp_dir <- withr::local_tempdir()
  
  vizzes <- create_viz() %>%
    add_viz(type = "bar", x_var = "cyl") %>%
    add_pagination() %>%
    add_viz(type = "histogram", x_var = "mpg") %>%
    add_pagination() %>%
    add_viz(type = "bar", x_var = "gear")
  
  proj <- create_dashboard(output_dir = temp_dir, title = "Test") %>%
    add_page("Analysis", data = mtcars, visualizations = vizzes)
  
  result <- generate_dashboard(proj, render = FALSE, open = FALSE)
  
  # Get absolute paths
  output_dir <- normalizePath(result$output_dir, mustWork = FALSE)
  
  # First file should have pagination nav R call (page 1 of 3)
  qmd1 <- readLines(file.path(output_dir, "analysis.qmd"))
  # Check for create_pagination_nav call with page 1
  expect_true(any(grepl("create_pagination_nav", qmd1)))
  expect_true(any(grepl('1, 3, "analysis"', qmd1, fixed = TRUE)))
})

test_that("middle page has both prev and next navigation", {
  temp_dir <- withr::local_tempdir()
  
  vizzes <- create_viz() %>%
    add_viz(type = "bar", x_var = "cyl") %>%
    add_pagination() %>%
    add_viz(type = "histogram", x_var = "mpg") %>%
    add_pagination() %>%
    add_viz(type = "bar", x_var = "gear")
  
  proj <- create_dashboard(output_dir = temp_dir, title = "Test") %>%
    add_page("Analysis", data = mtcars, visualizations = vizzes)
  
  result <- generate_dashboard(proj, render = FALSE, open = FALSE)
  output_dir <- normalizePath(result$output_dir, mustWork = FALSE)
  
  # Middle file should have pagination nav R call (page 2 of 3)
  qmd2 <- readLines(file.path(output_dir, "analysis_p2.qmd"))
  expect_true(any(grepl("create_pagination_nav", qmd2)))
  expect_true(any(grepl('2, 3, "analysis"', qmd2, fixed = TRUE)))
})

test_that("last page only has previous navigation", {
  temp_dir <- withr::local_tempdir()
  
  vizzes <- create_viz() %>%
    add_viz(type = "bar", x_var = "cyl") %>%
    add_pagination() %>%
    add_viz(type = "histogram", x_var = "mpg") %>%
    add_pagination() %>%
    add_viz(type = "bar", x_var = "gear")
  
  proj <- create_dashboard(output_dir = temp_dir, title = "Test") %>%
    add_page("Analysis", data = mtcars, visualizations = vizzes)
  
  result <- generate_dashboard(proj, render = FALSE, open = FALSE)
  output_dir <- normalizePath(result$output_dir, mustWork = FALSE)
  
  # Last file should have pagination nav R call (page 3 of 3)
  qmd3 <- readLines(file.path(output_dir, "analysis_p3.qmd"))
  expect_true(any(grepl("create_pagination_nav", qmd3)))
  expect_true(any(grepl('3, 3, "analysis"', qmd3, fixed = TRUE)))
})

test_that("each pagination page renders independently", {
  # Create dashboard with 100 charts split into 4 pages
  temp_dir <- withr::local_tempdir()
  
  vizzes <- create_viz()
  for (i in 1:25) vizzes <- vizzes %>% add_viz(type = "bar", x_var = "cyl")
  vizzes <- vizzes %>% add_pagination()
  for (i in 1:25) vizzes <- vizzes %>% add_viz(type = "bar", x_var = "gear")
  vizzes <- vizzes %>% add_pagination()
  for (i in 1:25) vizzes <- vizzes %>% add_viz(type = "bar", x_var = "carb")
  vizzes <- vizzes %>% add_pagination()
  for (i in 1:25) vizzes <- vizzes %>% add_viz(type = "bar", x_var = "vs")
  
  proj <- create_dashboard(output_dir = temp_dir, title = "Test") %>%
    add_page("Big", data = mtcars, visualizations = vizzes)
  
  # Generate (no render to save time in test)
  result <- generate_dashboard(proj, render = FALSE, open = FALSE)
  output_dir <- normalizePath(result$output_dir, mustWork = FALSE)
  
  # Each QMD should only have ~25 charts
  for (page_num in 1:4) {
    page_file <- if (page_num == 1) "big.qmd" else paste0("big_p", page_num, ".qmd")
    qmd <- readLines(file.path(output_dir, page_file))
    
    # Count R chunks (rough proxy for chart count)
    # Each page has ~25 chart chunks + setup/config + accessibility chunks (~6 overhead)
    chunk_count <- sum(grepl("```\\{r", qmd))
    expect_lt(chunk_count, 34,
              label = paste("Page", page_num, "should have ~25 charts, not all 100"))
  }
  
})

test_that("pagination navigation includes page indicators", {
  temp_dir <- withr::local_tempdir()
  
  vizzes <- create_viz() %>%
    add_viz(type = "bar", x_var = "cyl") %>%
    add_pagination() %>%
    add_viz(type = "histogram", x_var = "mpg") %>%
    add_pagination() %>%
    add_viz(type = "bar", x_var = "gear")
  
  proj <- create_dashboard(output_dir = temp_dir, title = "Test") %>%
    add_page("Analysis", data = mtcars, visualizations = vizzes)
  
  result <- generate_dashboard(proj, render = FALSE, open = FALSE)
  output_dir <- normalizePath(result$output_dir, mustWork = FALSE)
  
  # Check page indicators in each file via R function calls
  qmd1 <- readLines(file.path(output_dir, "analysis.qmd"))
  qmd2 <- readLines(file.path(output_dir, "analysis_p2.qmd"))
  qmd3 <- readLines(file.path(output_dir, "analysis_p3.qmd"))
  
  # All files should have create_pagination_nav R calls
  expect_true(any(grepl("create_pagination_nav", qmd1)))
  expect_true(any(grepl("create_pagination_nav", qmd2)))
  expect_true(any(grepl("create_pagination_nav", qmd3)))
  
  # Check that each file has the correct page number in the R call
  expect_true(any(grepl('1, 3, "analysis"', qmd1, fixed = TRUE)))
  expect_true(any(grepl('2, 3, "analysis"', qmd2, fixed = TRUE)))
  expect_true(any(grepl('3, 3, "analysis"', qmd3, fixed = TRUE)))
  
})

test_that("pagination navigation matches theme", {
  proj <- create_dashboard("test_theme_nav", theme = "darkly") %>%
    add_page("Test", 
             data = mtcars,
             visualizations = create_viz() %>%
               add_viz(type = "bar", x_var = "cyl") %>%
               add_pagination() %>%
               add_viz(type = "bar", x_var = "gear"))
  
  result <- generate_dashboard(proj, render = FALSE, open = FALSE)
  output_dir <- normalizePath(result$output_dir, mustWork = FALSE)
  qmd <- readLines(file.path(output_dir, "test.qmd"))
  qmd_text <- paste(qmd, collapse = "\n")
  
  # Check that pagination.css is loaded globally (not inline)
  expect_true(file.exists(file.path(output_dir, "assets", "pagination.css")))
  
  # Check that create_pagination_nav R call is present (generates pagination-nav HTML)
  expect_true(grepl("create_pagination_nav", qmd_text))
  
  # Cleanup
  unlink(output_dir, recursive = TRUE)
})

test_that("pagination CSS uses Bootstrap variables for theme compatibility", {
  temp_dir <- withr::local_tempdir()
  
  vizzes <- create_viz() %>%
    add_viz(type = "bar", x_var = "cyl") %>%
    add_pagination() %>%
    add_viz(type = "histogram", x_var = "mpg")
  
  proj <- create_dashboard(output_dir = temp_dir, title = "Test") %>%
    add_page("Test", data = mtcars, visualizations = vizzes)
  
  result <- generate_dashboard(proj, render = FALSE, open = FALSE)
  output_dir <- normalizePath(result$output_dir, mustWork = FALSE)
  
  # Check that external CSS file exists
  css_file <- file.path(output_dir, "assets", "pagination.css")
  expect_true(file.exists(css_file))
  
  # Read the external CSS file
  css_content <- paste(readLines(css_file), collapse = "\n")
  
  # Check for Bootstrap CSS variable usage in the external file
  expect_true(grepl("var\\(--bs-", css_content))
  expect_true(grepl("\\.pagination-nav", css_content))
  
  # Check for back-to-top button positioning in CSS
  expect_true(grepl("\\.back-to-top", css_content))
  expect_true(grepl("right:\\s*2rem", css_content))
  
})

test_that("single section page (no pagination) works normally", {
  temp_dir <- withr::local_tempdir()
  
  vizzes <- create_viz() %>%
    add_viz(type = "bar", x_var = "cyl") %>%
    add_viz(type = "histogram", x_var = "mpg")
  
  proj <- create_dashboard(output_dir = temp_dir, title = "Test") %>%
    add_page("Single", data = mtcars, visualizations = vizzes)
  
  result <- generate_dashboard(proj, render = FALSE, open = FALSE)
  output_dir <- normalizePath(result$output_dir, mustWork = FALSE)
  
  # Should only create one QMD file
  expect_true(file.exists(file.path(output_dir, "single.qmd")))
  expect_false(file.exists(file.path(output_dir, "single_p2.qmd")))
  
  # Should not have pagination navigation
  qmd <- readLines(file.path(output_dir, "single.qmd"))
  expect_false(any(grepl("pagination-nav", qmd)))
  
})

