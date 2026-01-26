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
  expect_true(file.exists(file.path(temp_dir, "example_dashboard.qmd")))
  
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
  
  # Read example dashboard QMD
  qmd_file <- file.path(temp_dir, "example_dashboard.qmd")
  expect_true(file.exists(qmd_file))
  
  qmd_content <- readLines(qmd_file)
  
  # Find lines with tooltip_labels_format
  format_lines <- grep("tooltip_labels_format", qmd_content, value = TRUE)
  expect_true(length(format_lines) > 0)
  
  # Verify curly braces are present (not escaped)
  expect_true(any(grepl('\\{point\\.value', format_lines)))
  
  # Extract R code chunks and verify they parse
  chunk_starts <- which(grepl("^```\\{r", qmd_content))
  chunk_ends <- which(grepl("^```$", qmd_content))
  
  expect_true(length(chunk_starts) > 0)
  expect_true(length(chunk_ends) > 0)
  
  # Test parsing of chunks with viz_heatmap
  for (i in seq_along(chunk_starts)) {
    if (i > length(chunk_ends)) break
    
    chunk_code <- qmd_content[(chunk_starts[i] + 1):(chunk_ends[i] - 1)]
    
    if (any(grepl("viz_heatmap", chunk_code))) {
      chunk_text <- paste(chunk_code, collapse = "\n")
      # This should parse without error (was failing before fix)
      expect_silent(parse(text = chunk_text))
    }
  }
  
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
  expect_true(file.exists(file.path(temp_dir, "gss_data_analysis.qmd")))
  
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
  
  # Read GSS data analysis QMD (has heatmaps)
  qmd_file <- file.path(temp_dir, "gss_data_analysis.qmd")
  expect_true(file.exists(qmd_file))
  
  qmd_content <- readLines(qmd_file)
  
  # Find lines with tooltip_labels_format
  format_lines <- grep("tooltip_labels_format", qmd_content, value = TRUE)
  expect_true(length(format_lines) > 0)
  
  # Verify curly braces are present (not escaped)
  expect_true(any(grepl('\\{point\\.value', format_lines)))
  
  # Extract R code chunks and verify they parse
  chunk_starts <- which(grepl("^```\\{r", qmd_content))
  chunk_ends <- which(grepl("^```$", qmd_content))
  
  expect_true(length(chunk_starts) > 0)
  
  # Test parsing of chunks with viz_heatmap
  for (i in seq_along(chunk_starts)) {
    if (i > length(chunk_ends)) break
    
    chunk_code <- qmd_content[(chunk_starts[i] + 1):(chunk_ends[i] - 1)]
    
    if (any(grepl("viz_heatmap", chunk_code))) {
      chunk_text <- paste(chunk_code, collapse = "\n")
      # This should parse without error
      expect_silent(parse(text = chunk_text))
    }
  }
  
  # Cleanup
  unlink(temp_dir, recursive = TRUE)
})

