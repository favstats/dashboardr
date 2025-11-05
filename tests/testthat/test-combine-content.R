# =================================================================
# Test Suite: Universal Content Combining & Propagation
# Phase 1: RED - All tests should FAIL before implementation
# =================================================================

library(testthat)
library(dashboardr)

# =================================================================
# Basic Combining Tests
# =================================================================

test_that("combine_content() combines two viz collections", {
  viz1 <- create_viz() %>%
    add_viz(type = "bar", x_var = "mpg", title = "Chart 1")
  
  viz2 <- create_viz() %>%
    add_viz(type = "bar", x_var = "cyl", title = "Chart 2")
  
  combined <- combine_content(viz1, viz2)
  
  expect_equal(length(combined$items), 2)
  expect_equal(combined$items[[1]]$title, "Chart 1")
  expect_equal(combined$items[[2]]$title, "Chart 2")
  expect_s3_class(combined, "content_collection")
  expect_s3_class(combined, "viz_collection")
})

test_that("combine_content() preserves tabgroup_labels", {
  viz1 <- create_viz(tabgroup_labels = c("demo" = "Demographics")) %>%
    add_viz(type = "bar", x_var = "mpg")
  
  viz2 <- create_viz(tabgroup_labels = c("pol" = "Politics")) %>%
    add_viz(type = "bar", x_var = "cyl")
  
  combined <- combine_content(viz1, viz2)
  
  expect_equal(combined$tabgroup_labels$demo, "Demographics")
  expect_equal(combined$tabgroup_labels$pol, "Politics")
})

test_that("combine_content() preserves defaults with e2 precedence", {
  viz1 <- create_viz(color_palette = c("red", "blue")) %>%
    add_viz(type = "bar", x_var = "mpg")
  
  viz2 <- create_viz(color_palette = c("green", "yellow"), horizontal = TRUE) %>%
    add_viz(type = "bar", x_var = "cyl")
  
  combined <- combine_content(viz1, viz2)
  
  # Later collection (viz2) takes precedence for color_palette
  expect_equal(combined$defaults$color_palette, c("green", "yellow"))
  expect_equal(combined$defaults$horizontal, TRUE)
})

test_that("+ operator combines viz_collections", {
  viz1 <- create_viz() %>%
    add_viz(type = "bar", x_var = "mpg", title = "Chart 1")
  
  viz2 <- create_viz() %>%
    add_viz(type = "bar", x_var = "cyl", title = "Chart 2")
  
  combined <- viz1 + viz2
  
  expect_equal(length(combined$items), 2)
  expect_equal(combined$items[[1]]$title, "Chart 1")
  expect_equal(combined$items[[2]]$title, "Chart 2")
})

test_that("+ operator works in pipe chains", {
  viz1 <- create_viz() %>%
    add_viz(type = "bar", x_var = "mpg", title = "Chart 1")
  
  viz2 <- create_viz() %>%
    add_viz(type = "bar", x_var = "cyl", title = "Chart 2")
  
  viz3 <- create_viz() %>%
    add_viz(type = "bar", x_var = "hp", title = "Chart 3")
  
  combined <- viz1 + viz2 + viz3
  
  expect_equal(length(combined$items), 3)
  expect_equal(combined$items[[1]]$title, "Chart 1")
  expect_equal(combined$items[[2]]$title, "Chart 2")
  expect_equal(combined$items[[3]]$title, "Chart 3")
})

# =================================================================
# Pagination Preservation Tests
# =================================================================

test_that("pagination markers survive combine_content()", {
  viz1 <- create_viz() %>%
    add_viz(type = "bar", x_var = "mpg") %>%
    add_pagination()
  
  viz2 <- create_viz() %>%
    add_viz(type = "bar", x_var = "cyl")
  
  combined <- combine_content(viz1, viz2)
  
  expect_equal(length(combined$items), 3)  # 1 viz + 1 pagination + 1 viz
  expect_equal(combined$items[[2]]$type, "pagination")
  expect_true(combined$items[[2]]$pagination_break)
})

test_that("multiple pagination markers with combine_content()", {
  viz1 <- create_viz() %>%
    add_viz(type = "bar", x_var = "mpg") %>%
    add_pagination()
  
  viz2 <- create_viz() %>%
    add_viz(type = "bar", x_var = "cyl") %>%
    add_pagination()
  
  viz3 <- create_viz() %>%
    add_viz(type = "bar", x_var = "hp")
  
  combined <- combine_content(viz1, viz2, viz3)
  
  expect_equal(length(combined$items), 5)  # 3 viz + 2 pagination
  expect_equal(combined$items[[2]]$type, "pagination")
  expect_equal(combined$items[[4]]$type, "pagination")
})

test_that("user's exact pattern: multiple combine + pagination", {
  perf_sis_viz <- create_viz() %>%
    add_viz(type = "bar", x_var = "mpg", title = "SIS")
  
  perf_cis_viz <- create_viz() %>%
    add_viz(type = "bar", x_var = "cyl", title = "CIS")
  
  perf_dccs_viz <- create_viz() %>%
    add_viz(type = "bar", x_var = "disp", title = "DCCS")
  
  perf_health_viz <- create_viz() %>%
    add_viz(type = "bar", x_var = "hp", title = "Health")
  
  # User's exact pattern
  performance_collection <- perf_sis_viz %>%
    combine_content(perf_cis_viz) %>%
    combine_content(perf_dccs_viz) %>%
    add_pagination() %>%
    combine_content(perf_health_viz)
  
  # Verify structure: 4 viz + 1 pagination
  expect_equal(length(performance_collection$items), 5)
  expect_equal(performance_collection$items[[1]]$title, "SIS")
  expect_equal(performance_collection$items[[2]]$title, "CIS")
  expect_equal(performance_collection$items[[3]]$title, "DCCS")
  expect_equal(performance_collection$items[[4]]$type, "pagination")
  expect_true(performance_collection$items[[4]]$pagination_break)
  expect_equal(performance_collection$items[[5]]$title, "Health")
})

test_that("+ operator preserves pagination markers", {
  viz1 <- create_viz() %>%
    add_viz(type = "bar", x_var = "mpg") %>%
    add_pagination()
  
  viz2 <- create_viz() %>%
    add_viz(type = "bar", x_var = "cyl")
  
  combined <- viz1 + viz2
  
  expect_equal(length(combined$items), 3)
  expect_equal(combined$items[[2]]$type, "pagination")
  expect_true(combined$items[[2]]$pagination_break)
})

# =================================================================
# Lazy Loading Preservation Tests
# =================================================================

test_that("lazy loading attributes preserved through combine_content()", {
  # Create collection with lazy loading attribute
  viz1 <- create_viz() %>%
    add_viz(type = "bar", x_var = "mpg")
  viz1$lazy_load_charts <- TRUE
  viz1$lazy_load_margin <- "300px"
  
  viz2 <- create_viz() %>%
    add_viz(type = "bar", x_var = "cyl")
  
  combined <- combine_content(viz1, viz2)
  
  # Lazy loading attributes should be preserved (later collection overrides)
  expect_true(!is.null(combined$lazy_load_charts))
  expect_equal(combined$lazy_load_charts, TRUE)
  expect_equal(combined$lazy_load_margin, "300px")
})

test_that("lazy loading attributes preserved through + operator", {
  viz1 <- create_viz() %>%
    add_viz(type = "bar", x_var = "mpg")
  viz1$lazy_load_charts <- TRUE
  viz1$lazy_load_margin <- "400px"
  
  viz2 <- create_viz() %>%
    add_viz(type = "bar", x_var = "cyl")
  
  combined <- viz1 + viz2
  
  expect_equal(combined$lazy_load_charts, TRUE)
  expect_equal(combined$lazy_load_margin, "400px")
})

test_that("multiple collections with different lazy loading settings merge correctly", {
  viz1 <- create_viz() %>%
    add_viz(type = "bar", x_var = "mpg")
  viz1$lazy_load_charts <- TRUE
  viz1$lazy_load_margin <- "200px"
  
  viz2 <- create_viz() %>%
    add_viz(type = "bar", x_var = "cyl")
  viz2$lazy_load_charts <- FALSE
  viz2$lazy_load_margin <- "500px"
  
  viz3 <- create_viz() %>%
    add_viz(type = "bar", x_var = "hp")
  # viz3 has no lazy loading settings
  
  combined <- combine_content(viz1, viz2, viz3)
  
  # Later collection (viz2) should take precedence
  expect_equal(combined$lazy_load_charts, FALSE)
  expect_equal(combined$lazy_load_margin, "500px")
})

# =================================================================
# Integration Tests
# =================================================================

test_that("full integration: combine + pagination + lazy loading", {
  viz1 <- create_viz() %>%
    add_viz(type = "bar", x_var = "mpg")
  viz1$lazy_load_charts <- TRUE
  
  viz2 <- create_viz() %>%
    add_viz(type = "bar", x_var = "cyl") %>%
    add_pagination()
  
  viz3 <- create_viz() %>%
    add_viz(type = "bar", x_var = "hp")
  
  combined <- combine_content(viz1, viz2, viz3)
  
  # Should have all items
  expect_equal(length(combined$items), 4)  # 3 viz + 1 pagination
  
  # Should preserve pagination marker
  expect_equal(combined$items[[3]]$type, "pagination")
  
  # Should preserve lazy loading
  expect_equal(combined$lazy_load_charts, TRUE)
})

test_that("combine_viz() still works (backward compat)", {
  viz1 <- create_viz() %>%
    add_viz(type = "bar", x_var = "mpg", title = "Chart 1")
  
  viz2 <- create_viz() %>%
    add_viz(type = "bar", x_var = "cyl", title = "Chart 2")
  
  # Should work exactly like combine_content()
  combined <- combine_viz(viz1, viz2)
  
  expect_equal(length(combined$items), 2)
  expect_equal(combined$items[[1]]$title, "Chart 1")
  expect_equal(combined$items[[2]]$title, "Chart 2")
})

test_that("combine_content() works with mixed content types", {
  viz1 <- create_viz() %>%
    add_viz(type = "bar", x_var = "mpg")
  
  viz2 <- create_viz() %>%
    add_viz(type = "histogram", x_var = "cyl") %>%
    add_pagination()
  
  viz3 <- create_viz() %>%
    add_viz(type = "bar", x_var = "hp")
  
  combined <- combine_content(viz1, viz2, viz3)
  
  expect_equal(length(combined$items), 4)
  expect_equal(combined$items[[1]]$viz_type, "bar")
  expect_equal(combined$items[[2]]$viz_type, "histogram")
  expect_equal(combined$items[[3]]$type, "pagination")
  expect_equal(combined$items[[4]]$viz_type, "bar")
})

# =================================================================
# Real-World Dashboard Integration Test
# =================================================================

test_that("user's exact failing pattern generates correct dashboard", {
  temp_dir <- withr::local_tempdir()
  
  perf_sis_viz <- create_viz() %>%
    add_viz(type = "bar", x_var = "mpg", title = "SIS")
  
  perf_cis_viz <- create_viz() %>%
    add_viz(type = "bar", x_var = "cyl", title = "CIS")
  
  perf_dccs_viz <- create_viz() %>%
    add_viz(type = "bar", x_var = "disp", title = "DCCS")
  
  perf_health_viz <- create_viz() %>%
    add_viz(type = "bar", x_var = "hp", title = "Health")
  
  # User's exact pattern
  performance_collection <- perf_sis_viz %>%
    combine_content(perf_cis_viz) %>%
    combine_content(perf_dccs_viz) %>%
    add_pagination() %>%
    combine_content(perf_health_viz)
  
  # Test dashboard generation
  proj <- create_dashboard(output_dir = temp_dir, title = "Test") %>%
    add_page("Performance", data = mtcars, visualizations = performance_collection)
  
  result <- generate_dashboard(proj, render = FALSE, open = FALSE)
  output_dir <- normalizePath(result$output_dir, mustWork = FALSE)
  
  # Should create 2 pages (split at pagination marker)
  expect_true(file.exists(file.path(output_dir, "performance.qmd")))
  expect_true(file.exists(file.path(output_dir, "performance_p2.qmd")))
  
  # First page should have first 3 charts
  qmd1 <- readLines(file.path(output_dir, "performance.qmd"))
  qmd1_text <- paste(qmd1, collapse = "\n")
  expect_true(grepl("SIS", qmd1_text))
  expect_true(grepl("CIS", qmd1_text))
  expect_true(grepl("DCCS", qmd1_text))
  
  # Second page should have last chart
  qmd2 <- readLines(file.path(output_dir, "performance_p2.qmd"))
  qmd2_text <- paste(qmd2, collapse = "\n")
  expect_true(grepl("Health", qmd2_text))
  
})

