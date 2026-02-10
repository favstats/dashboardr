# =============================================================================
# Comprehensive Pagination Tests
# =============================================================================
# These tests verify that add_pagination() correctly splits content into
# separate pages, especially when combined with combine_viz() and tabgroups.

# Skip entire file under covr CI to prevent OOM (exit code 143)
if (identical(Sys.getenv("DASHBOARDR_COVR_CI"), "true") || !identical(Sys.getenv("NOT_CRAN"), "true")) {
  # skipped on CRAN/covr CI
} else {

# =============================================================================
# Basic add_pagination() Structure Tests
# =============================================================================

test_that("add_pagination creates pagination marker in viz_collection", {
  viz <- create_viz() %>%
    add_viz(type = "bar", x_var = "cyl") %>%
    add_pagination() %>%
    add_viz(type = "bar", x_var = "gear")
  
  expect_equal(length(viz$items), 3)
  expect_equal(viz$items[[1]]$type, "viz")
  expect_equal(viz$items[[2]]$type, "pagination")
  expect_true(viz$items[[2]]$pagination_break)
  expect_equal(viz$items[[3]]$type, "viz")
})

test_that("add_pagination preserves item order in combined collections", {
  viz1 <- create_viz() %>% add_viz(type = "bar", x_var = "cyl", title = "Viz1")
  viz2 <- create_viz() %>% add_viz(type = "bar", x_var = "gear", title = "Viz2")
  viz3 <- create_viz() %>% add_viz(type = "bar", x_var = "carb", title = "Viz3")
  
  combined <- viz1 %>%
    combine_viz(viz2) %>%
    add_pagination() %>%
    combine_viz(viz3)
  
  expect_equal(length(combined$items), 4)
  expect_equal(combined$items[[1]]$title, "Viz1")
  expect_equal(combined$items[[2]]$title, "Viz2")
  expect_true(combined$items[[3]]$pagination_break)
  expect_equal(combined$items[[4]]$title, "Viz3")
})

test_that("multiple add_pagination calls create multiple markers", {
  viz1 <- create_viz() %>% add_viz(type = "bar", x_var = "cyl", title = "Viz1")
  viz2 <- create_viz() %>% add_viz(type = "bar", x_var = "gear", title = "Viz2")
  viz3 <- create_viz() %>% add_viz(type = "bar", x_var = "carb", title = "Viz3")
  viz4 <- create_viz() %>% add_viz(type = "bar", x_var = "vs", title = "Viz4")
  
  combined <- viz1 %>%
    combine_viz(viz2) %>%
    add_pagination() %>%
    combine_viz(viz3) %>%
    add_pagination() %>%
    combine_viz(viz4)
  
  # Count pagination markers
  pagination_count <- sum(sapply(combined$items, function(x) 
    isTRUE(x$pagination_break)))
  
  expect_equal(pagination_count, 2)
})

# =============================================================================
# Pagination with Tabgroups Tests
# =============================================================================

test_that("pagination markers preserved with tabgroups", {
  viz1 <- create_viz(data = mtcars) %>%
    add_viz(type = "bar", x_var = "cyl", title = "Viz1", tabgroup = "group1")
  
  viz2 <- create_viz(data = mtcars) %>%
    add_viz(type = "bar", x_var = "gear", title = "Viz2", tabgroup = "group2")
  
  combined <- viz1 %>%
    add_pagination() %>%
    combine_viz(viz2)
  
  # Check raw items before processing
  expect_equal(length(combined$items), 3)
  expect_true(combined$items[[2]]$pagination_break)
})

test_that("user pattern: combine_viz with interspersed add_pagination", {
  # This is the exact pattern the user described as broken
  perf_sis_viz <- create_viz(data = mtcars) %>%
    add_viz(type = "bar", x_var = "cyl", title = "VIZ_SIS", tabgroup = "perf_sis")
  
  perf_cis_viz <- create_viz(data = mtcars) %>%
    add_viz(type = "bar", x_var = "gear", title = "VIZ_CIS", tabgroup = "perf_cis")
  
  perf_dccs_viz <- create_viz(data = mtcars) %>%
    add_viz(type = "bar", x_var = "carb", title = "VIZ_DCCS", tabgroup = "perf_dccs")
  
  perf_netiquette_viz <- create_viz(data = mtcars) %>%
    add_viz(type = "bar", x_var = "vs", title = "VIZ_NET", tabgroup = "perf_netiquette")
  
  perf_safety_viz <- create_viz(data = mtcars) %>%
    add_viz(type = "bar", x_var = "am", title = "VIZ_SAFETY", tabgroup = "perf_safety")
  
  performance_collection <- perf_sis_viz %>%
    combine_viz(perf_cis_viz) %>%
    add_pagination() %>%
    combine_viz(perf_dccs_viz) %>%
    combine_viz(perf_netiquette_viz) %>%
    add_pagination() %>%
    combine_viz(perf_safety_viz)
  
  # Verify structure: 5 viz + 2 pagination = 7 items
  expect_equal(length(performance_collection$items), 7)
  
  # Verify pagination markers are at correct positions
  expect_equal(performance_collection$items[[1]]$title, "VIZ_SIS")
  expect_equal(performance_collection$items[[2]]$title, "VIZ_CIS")
  expect_true(performance_collection$items[[3]]$pagination_break)
  expect_equal(performance_collection$items[[4]]$title, "VIZ_DCCS")
  expect_equal(performance_collection$items[[5]]$title, "VIZ_NET")
  expect_true(performance_collection$items[[6]]$pagination_break)
  expect_equal(performance_collection$items[[7]]$title, "VIZ_SAFETY")
})

# =============================================================================
# QMD Generation Tests - Verify Correct Content Per Page
# =============================================================================

test_that("pagination generates separate QMD files with correct content", {
  skip_on_cran()
  temp_dir <- withr::local_tempdir()
  
  viz1 <- create_viz(data = mtcars) %>%
    add_viz(type = "bar", x_var = "cyl", title = "VIZ_PAGE1", tabgroup = "grp1")
  
  viz2 <- create_viz(data = mtcars) %>%
    add_viz(type = "bar", x_var = "gear", title = "VIZ_PAGE2", tabgroup = "grp2")
  
  combined <- viz1 %>%
    add_pagination() %>%
    combine_viz(viz2)
  
  proj <- create_dashboard(output_dir = temp_dir, title = "Test") %>%
    add_page("Test", data = mtcars, visualizations = combined)
  
  result <- generate_dashboard(proj, render = FALSE, open = FALSE)
  
  # Verify files exist
  expect_true(file.exists(file.path(temp_dir, "test.qmd")))
  expect_true(file.exists(file.path(temp_dir, "test_p2.qmd")))
  
  # Check content of each page
  p1 <- paste(readLines(file.path(temp_dir, "test.qmd")), collapse = "\n")
  p2 <- paste(readLines(file.path(temp_dir, "test_p2.qmd")), collapse = "\n")
  
  # Page 1 should have VIZ_PAGE1 but NOT VIZ_PAGE2
  expect_true(grepl("VIZ_PAGE1", p1))
  expect_false(grepl("VIZ_PAGE2", p1))
  
  # Page 2 should have VIZ_PAGE2 but NOT VIZ_PAGE1
  expect_false(grepl("VIZ_PAGE1", p2))
  expect_true(grepl("VIZ_PAGE2", p2))
})

test_that("pagination with user pattern generates correct separate pages", {
  skip_on_cran()
  temp_dir <- withr::local_tempdir()
  
  perf_sis_viz <- create_viz(data = mtcars) %>%
    add_viz(type = "bar", x_var = "cyl", title = "VIZ_SIS", tabgroup = "perf_sis")
  
  perf_cis_viz <- create_viz(data = mtcars) %>%
    add_viz(type = "bar", x_var = "gear", title = "VIZ_CIS", tabgroup = "perf_cis")
  
  perf_dccs_viz <- create_viz(data = mtcars) %>%
    add_viz(type = "bar", x_var = "carb", title = "VIZ_DCCS", tabgroup = "perf_dccs")
  
  perf_netiquette_viz <- create_viz(data = mtcars) %>%
    add_viz(type = "bar", x_var = "vs", title = "VIZ_NET", tabgroup = "perf_netiquette")
  
  perf_safety_viz <- create_viz(data = mtcars) %>%
    add_viz(type = "bar", x_var = "am", title = "VIZ_SAFETY", tabgroup = "perf_safety")
  
  performance_collection <- perf_sis_viz %>%
    combine_viz(perf_cis_viz) %>%
    add_pagination() %>%
    combine_viz(perf_dccs_viz) %>%
    combine_viz(perf_netiquette_viz) %>%
    add_pagination() %>%
    combine_viz(perf_safety_viz)
  
  proj <- create_dashboard(output_dir = temp_dir, title = "Test") %>%
    add_page("Performance", data = mtcars, visualizations = performance_collection)
  
  result <- generate_dashboard(proj, render = FALSE, open = FALSE)
  
  # Verify 3 files exist
  expect_true(file.exists(file.path(temp_dir, "performance.qmd")))
  expect_true(file.exists(file.path(temp_dir, "performance_p2.qmd")))
  expect_true(file.exists(file.path(temp_dir, "performance_p3.qmd")))
  
  # Read all pages
  p1 <- paste(readLines(file.path(temp_dir, "performance.qmd")), collapse = "\n")
  p2 <- paste(readLines(file.path(temp_dir, "performance_p2.qmd")), collapse = "\n")
  p3 <- paste(readLines(file.path(temp_dir, "performance_p3.qmd")), collapse = "\n")
  
  # Page 1: VIZ_SIS, VIZ_CIS only
  expect_true(grepl("VIZ_SIS", p1))
  expect_true(grepl("VIZ_CIS", p1))
  expect_false(grepl("VIZ_DCCS", p1))
  expect_false(grepl("VIZ_NET", p1))
  expect_false(grepl("VIZ_SAFETY", p1))
  
  # Page 2: VIZ_DCCS, VIZ_NET only
  expect_false(grepl("VIZ_SIS", p2))
  expect_false(grepl("VIZ_CIS", p2))
  expect_true(grepl("VIZ_DCCS", p2))
  expect_true(grepl("VIZ_NET", p2))
  expect_false(grepl("VIZ_SAFETY", p2))
  
  # Page 3: VIZ_SAFETY only
  expect_false(grepl("VIZ_SIS", p3))
  expect_false(grepl("VIZ_CIS", p3))
  expect_false(grepl("VIZ_DCCS", p3))
  expect_false(grepl("VIZ_NET", p3))
  expect_true(grepl("VIZ_SAFETY", p3))
})

test_that("pagination with many pages generates all separate files", {
  skip_on_cran()
  temp_dir <- withr::local_tempdir()
  
  # Create 6 separate pages with 5 pagination markers
  vizzes <- list()
  for (i in 1:6) {
    vizzes[[i]] <- create_viz(data = mtcars) %>%
      add_viz(type = "bar", x_var = "cyl", 
              title = paste0("VIZ_PAGE", i), 
              tabgroup = paste0("grp", i))
  }
  
  # Combine with pagination between each
  combined <- vizzes[[1]]
  for (i in 2:6) {
    combined <- combined %>%
      add_pagination() %>%
      combine_viz(vizzes[[i]])
  }
  
  proj <- create_dashboard(output_dir = temp_dir, title = "Test") %>%
    add_page("Multi", data = mtcars, visualizations = combined)
  
  result <- generate_dashboard(proj, render = FALSE, open = FALSE)
  
  # Verify 6 files exist
  expect_true(file.exists(file.path(temp_dir, "multi.qmd")))
  for (i in 2:6) {
    expect_true(file.exists(file.path(temp_dir, paste0("multi_p", i, ".qmd"))))
  }
  
  # Verify each page has ONLY its designated content
  for (page_num in 1:6) {
    page_file <- if (page_num == 1) "multi.qmd" else paste0("multi_p", page_num, ".qmd")
    content <- paste(readLines(file.path(temp_dir, page_file)), collapse = "\n")
    
    for (viz_num in 1:6) {
      pattern <- paste0("VIZ_PAGE", viz_num)
      if (viz_num == page_num) {
        expect_true(grepl(pattern, content), 
                    label = paste("Page", page_num, "should contain", pattern))
      } else {
        expect_false(grepl(pattern, content), 
                     label = paste("Page", page_num, "should NOT contain", pattern))
      }
    }
  }
})

# =============================================================================
# Pagination Navigation Tests
# =============================================================================

test_that("pagination navigation has correct page numbers", {
  skip_on_cran()
  temp_dir <- withr::local_tempdir()
  
  vizzes <- create_viz(data = mtcars) %>%
    add_viz(type = "bar", x_var = "cyl") %>%
    add_pagination() %>%
    add_viz(type = "bar", x_var = "gear") %>%
    add_pagination() %>%
    add_viz(type = "bar", x_var = "carb")
  
  proj <- create_dashboard(output_dir = temp_dir, title = "Test") %>%
    add_page("Analysis", data = mtcars, visualizations = vizzes)
  
  result <- generate_dashboard(proj, render = FALSE, open = FALSE)
  
  # Check navigation page numbers in each QMD
  qmd1 <- paste(readLines(file.path(temp_dir, "analysis.qmd")), collapse = "\n")
  qmd2 <- paste(readLines(file.path(temp_dir, "analysis_p2.qmd")), collapse = "\n")
  qmd3 <- paste(readLines(file.path(temp_dir, "analysis_p3.qmd")), collapse = "\n")
  
  # Page 1: create_pagination_nav(1, 3, ...)
  expect_true(grepl('1, 3, "analysis"', qmd1, fixed = TRUE))
  
  # Page 2: create_pagination_nav(2, 3, ...)
  expect_true(grepl('2, 3, "analysis"', qmd2, fixed = TRUE))
  
  # Page 3: create_pagination_nav(3, 3, ...)
  expect_true(grepl('3, 3, "analysis"', qmd3, fixed = TRUE))
})

# =============================================================================
# Edge Cases
# =============================================================================

test_that("no pagination markers generates single page", {
  skip_on_cran()
  temp_dir <- withr::local_tempdir()
  
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "bar", x_var = "cyl", title = "Viz1") %>%
    add_viz(type = "bar", x_var = "gear", title = "Viz2")
  
  proj <- create_dashboard(output_dir = temp_dir, title = "Test") %>%
    add_page("Single", data = mtcars, visualizations = viz)
  
  result <- generate_dashboard(proj, render = FALSE, open = FALSE)
  
  # Only single.qmd should exist
  expect_true(file.exists(file.path(temp_dir, "single.qmd")))
  expect_false(file.exists(file.path(temp_dir, "single_p2.qmd")))
  
  # Content should have both vizzes
  content <- paste(readLines(file.path(temp_dir, "single.qmd")), collapse = "\n")
  expect_true(grepl("Viz1", content))
  expect_true(grepl("Viz2", content))
})

test_that("pagination at end creates page with all content before marker", {
  skip_on_cran()
  temp_dir <- withr::local_tempdir()
  
  viz <- create_viz(data = mtcars) %>%
    add_viz(type = "bar", x_var = "cyl", title = "Viz1") %>%
    add_viz(type = "bar", x_var = "gear", title = "Viz2") %>%
    add_pagination()  # Pagination at end - nothing after it
  
  proj <- create_dashboard(output_dir = temp_dir, title = "Test") %>%
    add_page("EndPag", data = mtcars, visualizations = viz)
  
  result <- generate_dashboard(proj, render = FALSE, open = FALSE)
  
  # Should only have one page (nothing after pagination)
  expect_true(file.exists(file.path(temp_dir, "endpag.qmd")))
  # No second page needed (empty after pagination)
})

test_that("pagination with create_page and add_content works", {
  skip_on_cran()
  temp_dir <- withr::local_tempdir()
  
  viz1 <- create_viz(data = mtcars) %>%
    add_viz(type = "bar", x_var = "cyl", title = "VIZ_A", tabgroup = "grpA")
  
  viz2 <- create_viz(data = mtcars) %>%
    add_viz(type = "bar", x_var = "gear", title = "VIZ_B", tabgroup = "grpB")
  
  combined <- viz1 %>%
    add_pagination() %>%
    combine_viz(viz2)
  
  page_obj <- create_page("Test", data = mtcars) %>%
    add_content(combined)
  
  proj <- create_dashboard(output_dir = temp_dir, title = "Test") %>%
    add_page(page_obj)
  
  result <- generate_dashboard(proj, render = FALSE, open = FALSE)
  
  # Verify files exist
  expect_true(file.exists(file.path(temp_dir, "test.qmd")))
  expect_true(file.exists(file.path(temp_dir, "test_p2.qmd")))
  
  # Verify content split
  p1 <- paste(readLines(file.path(temp_dir, "test.qmd")), collapse = "\n")
  p2 <- paste(readLines(file.path(temp_dir, "test_p2.qmd")), collapse = "\n")
  
  expect_true(grepl("VIZ_A", p1))
  expect_false(grepl("VIZ_B", p1))
  expect_false(grepl("VIZ_A", p2))
  expect_true(grepl("VIZ_B", p2))
})

# =============================================================================
# Split Function Tests
# =============================================================================

test_that(".split_by_pagination correctly splits items", {
  items <- list(
    list(type = "viz", title = "Viz1"),
    list(type = "viz", title = "Viz2"),
    list(type = "pagination", pagination_break = TRUE),
    list(type = "viz", title = "Viz3"),
    list(type = "pagination", pagination_break = TRUE),
    list(type = "viz", title = "Viz4")
  )
  
  sections <- dashboardr:::.split_by_pagination(items)
  
  expect_equal(length(sections), 3)
  
  # Section 1: Viz1, Viz2
  expect_equal(length(sections[[1]]$items), 2)
  expect_equal(sections[[1]]$items[[1]]$title, "Viz1")
  expect_equal(sections[[1]]$items[[2]]$title, "Viz2")
  expect_true(sections[[1]]$pagination_after$pagination_break)
  
  # Section 2: Viz3
  expect_equal(length(sections[[2]]$items), 1)
  expect_equal(sections[[2]]$items[[1]]$title, "Viz3")
  expect_true(sections[[2]]$pagination_after$pagination_break)
  
  # Section 3: Viz4
  expect_equal(length(sections[[3]]$items), 1)
  expect_equal(sections[[3]]$items[[1]]$title, "Viz4")
  expect_null(sections[[3]]$pagination_after)
})

test_that(".has_pagination_markers detects pagination in page", {
  # Page with pagination
  page_with_pag <- list(
    visualizations = list(
      list(type = "viz"),
      list(type = "pagination", pagination_break = TRUE),
      list(type = "viz")
    )
  )
  expect_true(dashboardr:::.has_pagination_markers(page_with_pag))
  
  # Page without pagination
  page_without_pag <- list(
    visualizations = list(
      list(type = "viz"),
      list(type = "viz")
    )
  )
  expect_false(dashboardr:::.has_pagination_markers(page_without_pag))
  
  # Page with empty visualizations
  page_empty <- list(visualizations = list())
  expect_false(dashboardr:::.has_pagination_markers(page_empty))
  
  # Page with NULL visualizations
  page_null <- list(visualizations = NULL)
  expect_false(dashboardr:::.has_pagination_markers(page_null))
})

# =============================================================================
# Regression Tests
# =============================================================================

test_that("each paginated QMD file has unique content (regression test)", {
  # This test ensures pages don't accidentally duplicate content
  skip_on_cran()
  temp_dir <- withr::local_tempdir()
  
  # Create collection with 10 distinct visualizations across 5 pages
  vizzes <- list()
  for (i in 1:10) {
    vizzes[[i]] <- create_viz(data = mtcars) %>%
      add_viz(type = "bar", x_var = "cyl", 
              title = paste0("UNIQUE_VIZ_", sprintf("%02d", i)),
              tabgroup = paste0("tg", i))
  }
  
  # 2 vizzes per page, 4 pagination breaks
  combined <- vizzes[[1]] %>% combine_viz(vizzes[[2]]) %>%
    add_pagination() %>%
    combine_viz(vizzes[[3]]) %>% combine_viz(vizzes[[4]]) %>%
    add_pagination() %>%
    combine_viz(vizzes[[5]]) %>% combine_viz(vizzes[[6]]) %>%
    add_pagination() %>%
    combine_viz(vizzes[[7]]) %>% combine_viz(vizzes[[8]]) %>%
    add_pagination() %>%
    combine_viz(vizzes[[9]]) %>% combine_viz(vizzes[[10]])
  
  proj <- create_dashboard(output_dir = temp_dir, title = "Test") %>%
    add_page("Regression", data = mtcars, visualizations = combined)
  
  result <- generate_dashboard(proj, render = FALSE, open = FALSE)
  
  # Expected mapping: page -> viz numbers
  expected <- list(
    c(1, 2),
    c(3, 4),
    c(5, 6),
    c(7, 8),
    c(9, 10)
  )
  
  for (page_num in 1:5) {
    page_file <- if (page_num == 1) "regression.qmd" else paste0("regression_p", page_num, ".qmd")
    content <- paste(readLines(file.path(temp_dir, page_file)), collapse = "\n")
    
    for (viz_num in 1:10) {
      pattern <- paste0("UNIQUE_VIZ_", sprintf("%02d", viz_num))
      should_exist <- viz_num %in% expected[[page_num]]
      
      if (should_exist) {
        expect_true(grepl(pattern, content),
                    info = paste("Page", page_num, "should contain", pattern))
      } else {
        expect_false(grepl(pattern, content),
                     info = paste("Page", page_num, "should NOT contain", pattern))
      }
    }
  }
})

} # end covr CI skip
