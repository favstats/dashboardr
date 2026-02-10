test_that("serialize_arg handles curly braces correctly", {
  # Test single string with curly braces (used in Highcharts formatting)
  result <- dashboardr:::.serialize_arg("{point.value:.2f}")
  
  # Should produce a quoted string
  expect_true(grepl("^\".*\"$", result))
  
  # Verify it can be parsed as valid R code
  expect_silent(parse(text = result))
  
  # Test that it evaluates correctly (curly braces preserved)
  evaluated <- eval(parse(text = result))
  expect_equal(evaluated, "{point.value:.2f}")
})

test_that("serialize_arg handles quotes correctly", {
  # Test string with quotes
  result <- dashboardr:::.serialize_arg('He said "hello"')
  expect_equal(result, '"He said \\"hello\\""')
  
  # Verify it can be parsed
  expect_silent(parse(text = result))
})

test_that("serialize_arg handles combined special characters", {
  # Test string with both curly braces and quotes
  result <- dashboardr:::.serialize_arg('Format: "{value}" is {x}')
  expect_true(grepl("\\{", result))  # Has braces
  expect_true(grepl('\\\\"', result))  # Has escaped quotes
  
  # Verify it can be parsed
  expect_silent(parse(text = result))
  
  # Verify it evaluates correctly
  evaluated <- eval(parse(text = result))
  expect_equal(evaluated, 'Format: "{value}" is {x}')
})

test_that("serialize_arg handles vectors with curly braces", {
  # Test vector of strings with curly braces
  result <- dashboardr:::.serialize_arg(c("{x}", "{y}"))
  expect_true(grepl("\\{x\\}", result))
  expect_true(grepl("\\{y\\}", result))
  
  # Verify it can be parsed
  expect_silent(parse(text = result))
})

test_that("serialize_arg preserves other types correctly", {
  # Test NULL
  expect_equal(dashboardr:::.serialize_arg(NULL), "NULL")
  
  # Test numeric
  expect_equal(dashboardr:::.serialize_arg(42), "42")
  expect_equal(dashboardr:::.serialize_arg(c(1, 2, 3)), "c(1, 2, 3)")
  
  # Test logical
  expect_equal(dashboardr:::.serialize_arg(TRUE), "TRUE")
  expect_equal(dashboardr:::.serialize_arg(FALSE), "FALSE")
  
  # Test named list
  result <- dashboardr:::.serialize_arg(list(a = "x", b = "y"))
  expect_true(grepl("list", result))
  expect_true(grepl("a", result))
  expect_true(grepl("b", result))
})

test_that("tutorial_dashboard generates valid QMD with curly braces", {
  skip_if_not_installed("gssr")
  skip_on_cran()
  
  # Generate tutorial dashboard without rendering
  temp_dir <- tempfile("tutorial_test")
  
  # Suppress output and Quarto-not-available warnings
  suppressWarnings(capture.output({
    tutorial_dashboard(directory = temp_dir)
  }, type = "message"))
  
  # Check that QMD files were generated
  qmd_files <- list.files(temp_dir, pattern = "\\.qmd$", full.names = TRUE)
  expect_true(length(qmd_files) > 0)
  
  # Test that at least one QMD file has valid R chunks
  tested <- FALSE
  for (qmd_file in qmd_files) {
    qmd_content <- readLines(qmd_file)
    
    # Extract R chunks
    chunk_starts <- which(grepl("^```\\{r", qmd_content))
    chunk_ends <- which(grepl("^```$", qmd_content))
    
    if (length(chunk_starts) > 0 && length(chunk_ends) > 0) {
      # Test first chunk
      chunk_code <- qmd_content[(chunk_starts[1] + 1):(chunk_ends[1] - 1)]
      chunk_text <- paste(chunk_code, collapse = "\n")
      if (nchar(trimws(chunk_text)) > 0) {
        expect_silent(parse(text = chunk_text))
        tested <- TRUE
        break
      }
    }
  }
  expect_true(tested)
  
  # Cleanup
  unlink(temp_dir, recursive = TRUE)
})

