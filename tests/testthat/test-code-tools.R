test_that("code_tools = FALSE does not add code-tools to YAML", {
  # Use temp directory to avoid stale files
  output_dir <- tempfile("test_code_tools_false")
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)
  
  dashboard <- create_dashboard(
    output_dir = output_dir,
    title = "Test Dashboard",
    code_tools = FALSE
  )
  
  # Generate the dashboard (skip rendering)
  generate_dashboard(dashboard, render = FALSE)
  
  # Read the generated _quarto.yml
  yaml_path <- file.path(dashboard$output_dir, "_quarto.yml")
  expect_true(file.exists(yaml_path))
  
  yaml_content <- readLines(yaml_path)
  
  # Check that code-tools is NOT in the YAML
  expect_false(any(grepl("code-tools:", yaml_content)))
})

test_that("code_tools = TRUE adds code-tools to YAML", {
  # Use temp directory to avoid stale files
  output_dir <- tempfile("test_code_tools_true")
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)
  
  dashboard <- create_dashboard(
    output_dir = output_dir,
    title = "Test Dashboard",
    code_tools = TRUE
  )
  
  # Generate the dashboard (skip rendering)
  generate_dashboard(dashboard, render = FALSE)
  
  # Read the generated _quarto.yml
  yaml_path <- file.path(dashboard$output_dir, "_quarto.yml")
  expect_true(file.exists(yaml_path))
  
  yaml_content <- readLines(yaml_path)
  
  # Check that code-tools IS in the YAML
  expect_true(any(grepl("code-tools: true", yaml_content)))
})

test_that("code_tools = NULL does not add code-tools to YAML", {
  # Use temp directory to avoid stale files
  output_dir <- tempfile("test_code_tools_null")
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)
  
  dashboard <- create_dashboard(
    output_dir = output_dir,
    title = "Test Dashboard"
    # code_tools not specified (NULL)
  )
  
  # Generate the dashboard (skip rendering)
  generate_dashboard(dashboard, render = FALSE)
  
  # Read the generated _quarto.yml
  yaml_path <- file.path(dashboard$output_dir, "_quarto.yml")
  expect_true(file.exists(yaml_path))
  
  yaml_content <- readLines(yaml_path)
  
  # Check that code-tools is NOT in the YAML
  expect_false(any(grepl("code-tools:", yaml_content)))
})

test_that("code_folding = FALSE does not add code-fold to YAML", {
  # Use temp directory to avoid stale files
  output_dir <- tempfile("test_code_folding_false")
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)
  
  dashboard <- create_dashboard(
    output_dir = output_dir,
    title = "Test Dashboard",
    code_folding = FALSE
  )
  
  # Generate the dashboard (skip rendering)
  generate_dashboard(dashboard, render = FALSE)
  
  # Read the generated _quarto.yml
  yaml_path <- file.path(dashboard$output_dir, "_quarto.yml")
  expect_true(file.exists(yaml_path))
  
  yaml_content <- readLines(yaml_path)
  
  # Check that code-fold is NOT in the YAML
  expect_false(any(grepl("code-fold:", yaml_content)))
})

test_that("code_folding = TRUE adds code-fold to YAML", {
  # Use temp directory to avoid stale files
  output_dir <- tempfile("test_code_folding_true")
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)
  
  dashboard <- create_dashboard(
    output_dir = output_dir,
    title = "Test Dashboard",
    code_folding = TRUE
  )
  
  # Generate the dashboard (skip rendering)
  generate_dashboard(dashboard, render = FALSE)
  
  # Read the generated _quarto.yml
  yaml_path <- file.path(dashboard$output_dir, "_quarto.yml")
  expect_true(file.exists(yaml_path))
  
  yaml_content <- readLines(yaml_path)
  
  # Check that code-fold IS in the YAML
  expect_true(any(grepl("code-fold: true", yaml_content)))
})

test_that("both code_tools and code_folding work together correctly", {
  # Test all combinations
  
  # Both TRUE
  output_dir1 <- tempfile("test_both_true")
  on.exit(unlink(output_dir1, recursive = TRUE), add = TRUE)
  dashboard1 <- create_dashboard(
    output_dir = output_dir1,
    title = "Test",
    code_tools = TRUE,
    code_folding = TRUE,
    allow_inside_pkg = TRUE
  )
  generate_dashboard(dashboard1, render = FALSE)
  yaml1 <- readLines(file.path(dashboard1$output_dir, "_quarto.yml"))
  expect_true(any(grepl("code-tools: true", yaml1)))
  expect_true(any(grepl("code-fold: true", yaml1)))
  
  # Both FALSE
  output_dir2 <- tempfile("test_both_false")
  on.exit(unlink(output_dir2, recursive = TRUE), add = TRUE)
  dashboard2 <- create_dashboard(
    output_dir = output_dir2,
    title = "Test",
    code_tools = FALSE,
    code_folding = FALSE,
    allow_inside_pkg = TRUE  # Prevent path relocation
  )
  generate_dashboard(dashboard2, render = FALSE)
  yaml2 <- readLines(file.path(dashboard2$output_dir, "_quarto.yml"))
  expect_false(any(grepl("code-tools:", yaml2)))
  expect_false(any(grepl("code-fold:", yaml2)))
  
  # Mixed: tools TRUE, folding FALSE
  output_dir3 <- tempfile("test_mixed1")
  on.exit(unlink(output_dir3, recursive = TRUE), add = TRUE)
  dashboard3 <- create_dashboard(
    output_dir = output_dir3,
    title = "Test",
    code_tools = TRUE,
    code_folding = FALSE,
    allow_inside_pkg = TRUE
  )
  generate_dashboard(dashboard3, render = FALSE)
  yaml3 <- readLines(file.path(dashboard3$output_dir, "_quarto.yml"))
  expect_true(any(grepl("code-tools: true", yaml3)))
  expect_false(any(grepl("code-fold:", yaml3)))
  
  # Mixed: tools FALSE, folding TRUE
  output_dir4 <- tempfile("test_mixed2")
  on.exit(unlink(output_dir4, recursive = TRUE), add = TRUE)
  dashboard4 <- create_dashboard(
    output_dir = output_dir4,
    title = "Test",
    code_tools = FALSE,
    code_folding = TRUE,
    allow_inside_pkg = TRUE
  )
  generate_dashboard(dashboard4, render = FALSE)
  yaml4 <- readLines(file.path(dashboard4$output_dir, "_quarto.yml"))
  expect_false(any(grepl("code-tools:", yaml4)))
  expect_true(any(grepl("code-fold: true", yaml4)))
})

test_that("code_tools parameter is stored correctly in dashboard object", {
  # Test TRUE
  dash_true <- create_dashboard("test1", "Test", code_tools = TRUE)
  expect_true(dash_true$code_tools)
  
  # Test FALSE
  dash_false <- create_dashboard("test2", "Test", code_tools = FALSE)
  expect_false(dash_false$code_tools)
  
  # Test NULL (default)
  dash_null <- create_dashboard("test3", "Test")
  expect_null(dash_null$code_tools)
})

test_that("code_folding parameter is stored correctly in dashboard object", {
  # Test TRUE
  dash_true <- create_dashboard("test1", "Test", code_folding = TRUE)
  expect_true(dash_true$code_folding)
  
  # Test FALSE
  dash_false <- create_dashboard("test2", "Test", code_folding = FALSE)
  expect_false(dash_false$code_folding)
  
  # Test NULL (default)
  dash_null <- create_dashboard("test3", "Test")
  expect_null(dash_null$code_folding)
})
