## Skip entire file under covr CI to prevent OOM (exit code 143)
if (identical(Sys.getenv("DASHBOARDR_COVR_CI"), "true") || !identical(Sys.getenv("NOT_CRAN"), "true")) {
  test_that("skipped on CRAN/covr CI", { skip("Memory-intensive tests skipped on CRAN and covr CI") })
} else {

test_that("tutorial_dashboard respects directory parameter", {
  skip_if_not_installed("gssr")
  skip_on_cran()
  
  # Create temporary directory
  temp_dir <- tempfile("tutorial_dir_test")
  
  # Suppress messages
  suppressMessages({
    tutorial_dashboard(directory = temp_dir)
  })
  
  # Verify dashboard was created in specified directory
  expect_true(dir.exists(temp_dir))
  
  # Verify key files exist
  expect_true(file.exists(file.path(temp_dir, "_quarto.yml")))
  expect_true(file.exists(file.path(temp_dir, "index.qmd")))
  expect_true(file.exists(file.path(temp_dir, "charts.qmd")))
  
  # Cleanup
  unlink(temp_dir, recursive = TRUE)
})

test_that("tutorial_dashboard generates valid QMD with curly braces", {
  skip_if_not_installed("gssr")
  skip_on_cran()
  
  # Create temporary directory
  temp_dir <- tempfile("tutorial_curly_test")
  
  # Suppress messages
  suppressMessages({
    tutorial_dashboard(directory = temp_dir)
  })
  
  # Read charts QMD (has visualizations)
  qmd_file <- file.path(temp_dir, "charts.qmd")
  expect_true(file.exists(qmd_file))
  
  qmd_content <- readLines(qmd_file)
  
  # Verify file has content
  expect_true(length(qmd_content) > 10)
  
  # Find lines with viz_ function calls (these should have valid R syntax)
  viz_lines <- grep("viz_bar|viz_stackedbar", qmd_content, value = TRUE)
  expect_true(length(viz_lines) > 0)
  
  # Cleanup
  unlink(temp_dir, recursive = TRUE)
})

test_that("showcase_dashboard respects directory parameter", {
  skip_if_not_installed("gssr")
  skip_on_cran()
  
  # Create temporary directory
  temp_dir <- tempfile("showcase_dir_test")
  
  # Suppress messages
  suppressMessages({
    showcase_dashboard(directory = temp_dir)
  })
  
  # Verify dashboard was created in specified directory
  expect_true(dir.exists(temp_dir))
  
  # Verify key files exist
  expect_true(file.exists(file.path(temp_dir, "_quarto.yml")))
  expect_true(file.exists(file.path(temp_dir, "index.qmd")))
  expect_true(file.exists(file.path(temp_dir, "demographics.qmd")))
  
  # Cleanup
  unlink(temp_dir, recursive = TRUE)
})

test_that("showcase_dashboard generates valid QMD with curly braces", {
  skip_if_not_installed("gssr")
  skip_on_cran()
  
  # Create temporary directory
  temp_dir <- tempfile("showcase_curly_test")
  
  # Suppress messages
  suppressMessages({
    showcase_dashboard(directory = temp_dir)
  })
  
  # Read demographics QMD (has visualizations)
  qmd_file <- file.path(temp_dir, "demographics.qmd")
  expect_true(file.exists(qmd_file))
  
  qmd_content <- readLines(qmd_file)
  
  # Find R code chunks
  chunk_starts <- which(grepl("^```\\{r", qmd_content))
  chunk_ends <- which(grepl("^```$", qmd_content))
  expect_true(length(chunk_starts) > 0)
  
  # Test parsing of a few chunks to verify valid R code
  chunks_tested <- 0
  for (i in seq_along(chunk_starts)) {
    if (i > length(chunk_ends)) break
    if (chunks_tested >= 3) break  # Test first 3 chunks
    
    chunk_code <- qmd_content[(chunk_starts[i] + 1):(chunk_ends[i] - 1)]
    chunk_text <- paste(chunk_code, collapse = "\n")
    
    # Skip empty chunks
    if (nchar(trimws(chunk_text)) == 0) next
    
    # This should parse without error
    expect_silent(parse(text = chunk_text))
    chunks_tested <- chunks_tested + 1
  }
  
  # Cleanup
  unlink(temp_dir, recursive = TRUE)
})

} # end covr CI skip
