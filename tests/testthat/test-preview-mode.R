test_that("preview mode generates only specified page", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  # Create dashboard with multiple pages
  dashboard <- create_dashboard(
    "test_preview",
    "Preview Test",
    output_dir = temp_dir
  ) %>%
    add_dashboard_page(
      "Home",
      text = "Home page content",
      is_landing_page = TRUE
    ) %>%
    add_dashboard_page(
      "Analysis",
      text = "Analysis page content"
    ) %>%
    add_dashboard_page(
      "About",
      text = "About page content"
    )
  
  # Generate only Analysis page
  result <- generate_dashboard(dashboard, preview = "Analysis", render = FALSE)
  
  # Check that only Analysis.qmd was generated
  expect_true(file.exists(file.path(temp_dir, "analysis.qmd")))
  
  # Home and About should NOT exist (Home is landing page = index.qmd)
  expect_false(file.exists(file.path(temp_dir, "index.qmd")))
  expect_false(file.exists(file.path(temp_dir, "about.qmd")))
  
  # _quarto.yml should still be generated
  expect_true(file.exists(file.path(temp_dir, "_quarto.yml")))
})

test_that("preview mode handles page name case-insensitively", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  dashboard <- create_dashboard(
    "test_preview",
    "Preview Test",
    output_dir = temp_dir
  ) %>%
    add_dashboard_page("MyPage", text = "Content")
  
  # Should work with different cases
  r1 <- generate_dashboard(dashboard, preview = "mypage", render = FALSE)
  expect_s3_class(r1, "dashboard_project")
  r2 <- generate_dashboard(dashboard, preview = "MyPage", render = FALSE)
  expect_s3_class(r2, "dashboard_project")
  r3 <- generate_dashboard(dashboard, preview = "MYPAGE", render = FALSE)
  expect_s3_class(r3, "dashboard_project")
})

test_that("preview mode errors on non-existent page", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  dashboard <- create_dashboard(
    "test_preview",
    "Preview Test",
    output_dir = temp_dir
  ) %>%
    add_dashboard_page("Home", text = "Content")
  
  # Should error with helpful message (case-insensitive, so it lowercases input)
  expect_error(
    generate_dashboard(dashboard, preview = "NonExistent", render = FALSE),
    "Page 'nonexistent' not found"
  )
})

test_that("preview mode suggests alternatives for typos", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  dashboard <- create_dashboard(
    "test_preview",
    "Preview Test",
    output_dir = temp_dir
  ) %>%
    add_dashboard_page("Analysis", text = "Content")
  
  # Typo should suggest correct page
  expect_error(
    generate_dashboard(dashboard, preview = "Analisys", render = FALSE),
    "Analysis"
  )
})

test_that("preview mode works with multiple pages", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  dashboard <- create_dashboard(
    "test_preview",
    "Preview Test",
    output_dir = temp_dir
  ) %>%
    add_dashboard_page("Home", text = "Home") %>%
    add_dashboard_page("Analysis", text = "Analysis") %>%
    add_dashboard_page("About", text = "About")
  
  # Generate multiple pages
  result <- generate_dashboard(dashboard, preview = c("Home", "Analysis"), render = FALSE)
  
  expect_true(file.exists(file.path(temp_dir, "home.qmd")))
  expect_true(file.exists(file.path(temp_dir, "analysis.qmd")))
  expect_false(file.exists(file.path(temp_dir, "about.qmd")))
})

test_that("preview = NULL generates all pages", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  dashboard <- create_dashboard(
    "test_preview",
    "Preview Test",
    output_dir = temp_dir
  ) %>%
    add_dashboard_page("Home", text = "Home") %>%
    add_dashboard_page("About", text = "About")
  
  result <- generate_dashboard(dashboard, preview = NULL, render = FALSE)
  
  # All pages should be generated
  expect_true(file.exists(file.path(temp_dir, "home.qmd")))
  expect_true(file.exists(file.path(temp_dir, "about.qmd")))
})

test_that("preview mode still works correctly", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  # Dashboard with a landing page
  dashboard <- create_dashboard(
    "test_preview",
    "Preview Test",
    output_dir = temp_dir
  ) %>%
    add_dashboard_page("Home", text = "Home", is_landing_page = TRUE) %>%
    add_dashboard_page("About", text = "About")
  
  # Preview mode should work without issues
  expect_no_error(
    generate_dashboard(dashboard, preview = "Home", render = FALSE)
  )
  
  # Only home page should be generated
  expect_true(file.exists(file.path(temp_dir, "index.qmd")))
  expect_false(file.exists(file.path(temp_dir, "about.qmd")))
})

test_that("preview mode works with visualizations", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  test_data <- data.frame(x = 1:10, y = 1:10)
  
  viz <- create_viz() %>%
    add_viz(type = "histogram", x_var = "x", title = "Test")
  
  dashboard <- create_dashboard(
    "test_preview",
    "Preview Test",
    output_dir = temp_dir
  ) %>%
    add_dashboard_page(
      "Analysis",
      data = test_data,
      visualizations = viz,
      is_landing_page = TRUE
    ) %>%
    add_dashboard_page("About", text = "About")
  
  # Preview only Analysis page
  result <- generate_dashboard(dashboard, preview = "Analysis", render = FALSE)
  
  expect_true(file.exists(file.path(temp_dir, "index.qmd")))
  expect_false(file.exists(file.path(temp_dir, "about.qmd")))
  
  # Check that visualization code is in the generated QMD (landing page is index.qmd)
  qmd_content <- readLines(file.path(temp_dir, "index.qmd"))
  expect_true(any(grepl("viz_histogram", qmd_content)))
})

test_that("preview mode respects incremental builds", {
  skip_if_not_installed("quarto")
  
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  dashboard <- create_dashboard(
    "test_preview",
    "Preview Test",
    output_dir = temp_dir
  ) %>%
    add_dashboard_page("Home", text = "Home", is_landing_page = TRUE) %>%
    add_dashboard_page("Analysis", text = "Analysis")
  
  # First build (full)
  result1 <- generate_dashboard(dashboard, incremental = TRUE, render = FALSE)
  
  # Second build with preview should work with incremental
  result2 <- generate_dashboard(dashboard, preview = "Analysis", incremental = TRUE, render = FALSE)
  
  expect_true(file.exists(file.path(temp_dir, ".dashboardr_manifest.rds")))
})

