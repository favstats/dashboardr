test_that("Plausible analytics integrates correctly", {
  skip_on_cran()
  
  library(dashboardr)
  
  temp_dir <- tempfile("plausible_test_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  # Test 1: Simple domain string
  dash1 <- create_dashboard(
    output_dir = temp_dir,
    title = "Test Dashboard",
    plausible = "example.com"
  )
  
  expect_equal(dash1$plausible, "example.com")
  
  # Test 2: List with domain only
  dash2 <- create_dashboard(
    output_dir = temp_dir,
    title = "Test Dashboard",
    plausible = list(domain = "example.com")
  )
  
  expect_equal(dash2$plausible$domain, "example.com")
  
  # Test 3: List with domain and script_hash (proxy script)
  dash3 <- create_dashboard(
    output_dir = temp_dir,
    title = "Test Dashboard",
    plausible = list(
      domain = "example.com",
      script_hash = "pa-TestHash123"
    )
  )
  
  expect_equal(dash3$plausible$domain, "example.com")
  expect_equal(dash3$plausible$script_hash, "pa-TestHash123")
})

test_that("Plausible generates correct YAML", {
  skip_on_cran()
  
  library(dashboardr)
  
  temp_dir <- tempfile("plausible_yaml_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  # Test 1: Simple domain generates standard Plausible YAML
  dash1 <- create_dashboard(
    output_dir = temp_dir,
    title = "Test",
    plausible = "example.com"
  ) %>%
    add_page(
      name = "test",
      text = "# Test Page\n\nTest content",
      is_landing_page = TRUE
    )
  
  generate_dashboard(dash1, render = FALSE, quiet = TRUE)
  
  yaml_file <- file.path(temp_dir, "_quarto.yml")
  expect_true(file.exists(yaml_file))
  
  yaml_content <- readLines(yaml_file, warn = FALSE)
  yaml_text <- paste(yaml_content, collapse = "\n")
  
  # Should have plausible: domain: format
  expect_true(any(grepl("plausible:", yaml_content, fixed = TRUE)))
  expect_true(any(grepl('domain: "example.com"', yaml_content, fixed = TRUE)))
  
  # Should NOT have Plausible proxy script in header
  expect_false(any(grepl("plausible.io/js/pa-", yaml_content, fixed = TRUE)))
  
  # Test 2: Proxy script generates include-in-header
  temp_dir2 <- tempfile("plausible_proxy_")
  dir.create(temp_dir2)
  on.exit(unlink(temp_dir2, recursive = TRUE), add = TRUE)
  
  dash2 <- create_dashboard(
    output_dir = temp_dir2,
    title = "Test",
    plausible = list(
      domain = "example.com",
      script_hash = "pa-TestHash123"
    )
  ) %>%
    add_page(
      name = "test",
      text = "# Test Page\n\nTest content",
      is_landing_page = TRUE
    )
  
  generate_dashboard(dash2, render = FALSE, quiet = TRUE)
  
  yaml_file2 <- file.path(temp_dir2, "_quarto.yml")
  yaml_content2 <- readLines(yaml_file2, warn = FALSE)
  yaml_text2 <- paste(yaml_content2, collapse = "\n")
  
  # Should have include-in-header with custom script
  expect_true(any(grepl("include-in-header:", yaml_content2, fixed = TRUE)))
  expect_true(any(grepl("Privacy-friendly analytics by Plausible", yaml_content2, fixed = TRUE)))
  expect_true(any(grepl("pa-TestHash123.js", yaml_content2, fixed = TRUE)))
  expect_true(any(grepl("window.plausible", yaml_content2, fixed = TRUE)))
  expect_true(any(grepl("plausible.init()", yaml_content2, fixed = TRUE)))
  
  # Should NOT have standard plausible: domain: format
  expect_false(any(grepl('plausible:', yaml_content2, fixed = TRUE)))
})

test_that("Plausible proxy script format is correct", {
  skip_on_cran()
  
  library(dashboardr)
  
  temp_dir <- tempfile("plausible_format_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  dash <- create_dashboard(
    output_dir = temp_dir,
    title = "Test",
    plausible = list(
      domain = "example.com",
      script_hash = "pa-FakeTestHash123456"
    )
  ) %>%
    add_page(
      name = "test",
      text = "# Test Page\n\nTest content",
      is_landing_page = TRUE
    )
  
  generate_dashboard(dash, render = FALSE, quiet = TRUE)
  
  yaml_file <- file.path(temp_dir, "_quarto.yml")
  yaml_content <- readLines(yaml_file, warn = FALSE)
  
  # Check for correct script URL format
  script_line <- grep("plausible.io/js/", yaml_content, value = TRUE)
  expect_length(script_line, 1)
  expect_match(script_line, "https://plausible.io/js/pa-FakeTestHash123456.js")
  
  # Check initialization code
  expect_true(any(grepl("window.plausible=window.plausible", yaml_content, fixed = TRUE)))
  expect_true(any(grepl("plausible.init()", yaml_content, fixed = TRUE)))
  
  # Check async attribute
  expect_true(any(grepl("async", yaml_content, fixed = TRUE)))
})

