test_that("code_tools = FALSE does not add code-tools to YAML", {
  dashboard <- create_dashboard(
    output_dir = "test_code_tools_false",
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
  
  # Cleanup
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("code_tools = TRUE adds code-tools to YAML", {
  dashboard <- create_dashboard(
    output_dir = "test_code_tools_true",
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
  
  # Cleanup
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("code_tools = NULL does not add code-tools to YAML", {
  dashboard <- create_dashboard(
    output_dir = "test_code_tools_null",
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
  
  # Cleanup
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("code_folding = FALSE does not add code-fold to YAML", {
  dashboard <- create_dashboard(
    output_dir = "test_code_folding_false",
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
  
  # Cleanup
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("code_folding = TRUE adds code-fold to YAML", {
  dashboard <- create_dashboard(
    output_dir = "test_code_folding_true",
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
  
  # Cleanup
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("both code_tools and code_folding work together correctly", {
  # Test all combinations
  
  # Both TRUE
  dashboard1 <- create_dashboard(
    output_dir = "test_both_true",
    title = "Test",
    code_tools = TRUE,
    code_folding = TRUE,
    allow_inside_pkg = TRUE
  )
  generate_dashboard(dashboard1, render = FALSE)
  yaml1 <- readLines(file.path(dashboard1$output_dir, "_quarto.yml"))
  expect_true(any(grepl("code-tools: true", yaml1)))
  expect_true(any(grepl("code-fold: true", yaml1)))
  unlink(dashboard1$output_dir, recursive = TRUE)
  
  # Both FALSE
  dashboard2 <- create_dashboard(
    output_dir = "test_both_false",
    title = "Test",
    code_tools = FALSE,
    code_folding = FALSE,
    allow_inside_pkg = TRUE  # Prevent path relocation
  )
  generate_dashboard(dashboard2, render = FALSE)
  yaml2 <- readLines(file.path(dashboard2$output_dir, "_quarto.yml"))
  expect_false(any(grepl("code-tools:", yaml2)))
  expect_false(any(grepl("code-fold:", yaml2)))
  unlink(dashboard2$output_dir, recursive = TRUE)
  
  # Mixed: tools TRUE, folding FALSE
  dashboard3 <- create_dashboard(
    output_dir = "test_mixed1",
    title = "Test",
    code_tools = TRUE,
    code_folding = FALSE,
    allow_inside_pkg = TRUE
  )
  generate_dashboard(dashboard3, render = FALSE)
  yaml3 <- readLines(file.path(dashboard3$output_dir, "_quarto.yml"))
  expect_true(any(grepl("code-tools: true", yaml3)))
  expect_false(any(grepl("code-fold:", yaml3)))
  unlink(dashboard3$output_dir, recursive = TRUE)
  
  # Mixed: tools FALSE, folding TRUE
  dashboard4 <- create_dashboard(
    output_dir = "test_mixed2",
    title = "Test",
    code_tools = FALSE,
    code_folding = TRUE,
    allow_inside_pkg = TRUE
  )
  generate_dashboard(dashboard4, render = FALSE)
  yaml4 <- readLines(file.path(dashboard4$output_dir, "_quarto.yml"))
  expect_false(any(grepl("code-tools:", yaml4)))
  expect_true(any(grepl("code-fold: true", yaml4)))
  unlink(dashboard4$output_dir, recursive = TRUE)
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
}
)

