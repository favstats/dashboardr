# Comprehensive test for complex real-world user pattern
# This captures the EXACT pattern used in production with:
# - Multiple viz types (stackedbars, timeline, stackedbar)
# - Multiple combine_viz() calls
# - add_pagination() in between combinations
# - Filters (Wave 1, Wave 2) triggering filter grouping
# - Complex nested tabgroups (dimension/wave/demographic/item)
# - set_tabgroup_labels()
# - Lazy loading (lazy_load_charts, lazy_load_tabs, lazy_debug)
# - Multiple datasets
# - Real-world data structure

library(dashboardr)
library(dplyr)

# Skip entire file under covr CI to prevent OOM (exit code 143)
if (identical(Sys.getenv("DASHBOARDR_COVR_CI"), "true") || !identical(Sys.getenv("NOT_CRAN"), "true")) {
  test_that("skipped on CRAN/covr CI", { skip("Memory-intensive tests skipped on CRAN and covr CI") })
} else {

test_that("USER PATTERN: Complex production use case with all features", {

  # Simulate user's exact data structure
  digicom_data <- mtcars %>%
    mutate(
      wave = sample(1:2, nrow(mtcars), replace = TRUE),
      wave_time_label = factor(ifelse(wave == 1, "Wave 1", "Wave 2"), 
                                levels = c("Wave 1", "Wave 2")),
      AgeGroup = sample(c("18-24", "25-34", "35-44", "45-54"), nrow(mtcars), replace = TRUE),
      geslacht = sample(c("Male", "Female"), nrow(mtcars), replace = TRUE),
      Education = factor(sample(c("Low", "Middle", "High"), nrow(mtcars), replace = TRUE),
                         levels = c("Low", "Middle", "High"))
    )
  
  # === EXACT USER PATTERN: Multiple dimensions with filters and nested tabgroups ===
  
  # Dimension 1: Strategic Information Skills (stackedbars with Wave 1/2 filters)
  perf_sis_viz <- create_viz(
    type = "stackedbars",
    x_vars = c("mpg", "cyl"),
    x_var_labels = c("Miles per Gallon", "Cylinders"),
    stacked_type = "percent",
    horizontal = TRUE
  ) %>%
    add_viz(
      title = "Strategic Info Wave 1",
      filter = ~ wave == 1,
      tabgroup = "perf_sis/wave1/overall"
    ) %>%
    add_viz(
      title = "Strategic Info Wave 2",
      filter = ~ wave == 2,
      tabgroup = "perf_sis/wave2/overall"
    )
  
  # Dimension 2: Critical Information Skills (timeline with over time analysis)
  perf_cis_viz <- create_viz(
    type = "timeline",
    time_var = "wave_time_label",
    chart_type = "line",
    y_var = "disp"
  ) %>%
    add_viz(
      title = "Critical Info Over Time",
      tabgroup = "perf_cis/overtime/overall"
    ) %>%
    add_viz(
      title = "By Age",
      group_var = "AgeGroup",
      tabgroup = "perf_cis/overtime/age"
    ) %>%
    add_viz(
      title = "By Gender",
      group_var = "geslacht",
      tabgroup = "perf_cis/overtime/gender"
    )
  
  # Dimension 3: Digital Content Creation (stackedbar with demographics, Wave 1)
  perf_dccs_viz <- create_viz(
    type = "stackedbar",
    stacked_type = "percent",
    horizontal = TRUE,
    filter = ~ wave == 1
  ) %>%
    add_viz(
      title = "DCCS by Age",
      x_var = "AgeGroup",
      stack_var = "hp",
      tabgroup = "perf_dccs/wave1/age"
    ) %>%
    add_viz(
      title = "DCCS by Gender",
      x_var = "geslacht",
      stack_var = "hp",
      tabgroup = "perf_dccs/wave1/gender"
    ) %>%
    add_viz(
      title = "DCCS by Education",
      x_var = "Education",
      stack_var = "hp",
      tabgroup = "perf_dccs/wave1/edu"
    )
  
  # === PAGINATION MARKER 1: After first 3 dimensions ===
  
  # Dimension 4: Health (Wave 2 with demographics)
  perf_health_viz <- create_viz(
    type = "stackedbar",
    stacked_type = "percent",
    horizontal = TRUE,
    filter = ~ wave == 2
  ) %>%
    add_viz(
      title = "Health by Age",
      x_var = "AgeGroup",
      stack_var = "wt",
      tabgroup = "perf_health/wave2/age"
    ) %>%
    add_viz(
      title = "Health by Education",
      x_var = "Education",
      stack_var = "wt",
      tabgroup = "perf_health/wave2/edu"
    )
  
  # Dimension 5: Green Skills (simple bar charts)
  perf_green_viz <- create_viz(type = "bar") %>%
    add_viz(
      title = "Green Skills Overall",
      x_var = "drat",
      tabgroup = "perf_green/overall"
    )
  
  # Dimension 6: Problem Solving (timeline over time)
  perf_ps_viz <- create_viz(
    type = "timeline",
    time_var = "wave_time_label",
    chart_type = "line",
    y_var = "qsec"
  ) %>%
    add_viz(
      title = "Problem Solving Over Time",
      tabgroup = "perf_ps/overtime/overall"
    )
  
  # === PAGINATION MARKER 2: After dimensions 4-6 ===
  
  # Dimension 7: Transactional (Wave 1)
  perf_trans_viz <- create_viz(type = "bar", filter = ~ wave == 1) %>%
    add_viz(
      title = "Transactional Wave 1",
      x_var = "vs",
      tabgroup = "perf_trans/wave1/overall"
    )
  
  # Dimension 8: AI Skills (Wave 2)
  perf_ai_viz <- create_viz(type = "bar", filter = ~ wave == 2) %>%
    add_viz(
      title = "AI Skills Wave 2",
      x_var = "am",
      tabgroup = "perf_ai/wave2/overall"
    )
  
  # Dimension 9: GenAI Skills (both waves)
  perf_genai_viz <- create_viz(type = "bar") %>%
    add_viz(
      title = "GenAI Wave 1",
      x_var = "gear",
      filter = ~ wave == 1,
      tabgroup = "perf_genai/wave1/overall"
    ) %>%
    add_viz(
      title = "GenAI Wave 2",
      x_var = "gear",
      filter = ~ wave == 2,
      tabgroup = "perf_genai/wave2/overall"
    )
  
  # === USER'S EXACT COMBINING PATTERN ===
  performance_collection <- perf_sis_viz %>%
    combine_viz(perf_cis_viz) %>%
    combine_viz(perf_dccs_viz) %>%
    add_pagination() %>%  # PAGINATION 1
    combine_viz(perf_health_viz) %>%
    combine_viz(perf_green_viz) %>%
    combine_viz(perf_ps_viz) %>%
    add_pagination() %>%  # PAGINATION 2
    combine_viz(perf_trans_viz) %>%
    combine_viz(perf_ai_viz) %>%
    combine_viz(perf_genai_viz) %>%
    set_tabgroup_labels(list(
      perf_sis = "Strategic Information Performance",
      perf_cis = "Critical Information Performance",
      perf_dccs = "Digital Content Creation Performance",
      perf_health = "Health & Wellbeing Performance",
      perf_green = "Green Performance",
      perf_ps = "Problem Solving Performance",
      perf_trans = "Transactional Performance",
      perf_ai = "AI Performance",
      perf_genai = "GenAI Performance",
      wave1 = "Wave 1",
      wave2 = "Wave 2",
      age = "Age",
      gender = "Gender",
      edu = "Education",
      overtime = "Over Time",
      overall = "Overall"
    ))
  
  # Verify collection structure
  expect_true(inherits(performance_collection, "viz_collection"))
  expect_true(length(performance_collection$items) > 15)  # Should have many items
  
  # Count pagination markers
  pagination_count <- sum(sapply(performance_collection$items, function(x) {
    !is.null(x$type) && x$type == "pagination"
  }))
  expect_equal(pagination_count, 2, label = "Should have 2 pagination markers")
  
  # === USER'S DASHBOARD SETUP WITH LAZY LOADING ===
  # Use temp directory to avoid stale files from previous runs
  output_dir <- tempfile("test_user_complex_pattern")
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)
  
  dashboard <- create_dashboard(
    output_dir = output_dir,
    lazy_load_charts = TRUE,
    lazy_load_margin = "300px",
    lazy_load_tabs = TRUE,
    lazy_debug = TRUE
  ) %>%
    add_page(
      name = "Performance",
      data = digicom_data,
      visualizations = performance_collection,
      lazy_load_charts = TRUE,
      lazy_load_tabs = TRUE,
      lazy_debug = TRUE,
      overlay = FALSE
    )
  
  # Verify page has pagination markers
  page <- dashboard$pages[[1]]
  page_has_pagination <- any(sapply(page$visualizations, function(x) {
    !is.null(x$pagination_break) && isTRUE(x$pagination_break)
  }))
  expect_true(page_has_pagination, label = "Page should preserve pagination markers")
  
  # Verify lazy loading settings are preserved
  expect_true(page$lazy_load_charts, label = "lazy_load_charts should be TRUE")
  expect_true(page$lazy_load_tabs, label = "lazy_load_tabs should be TRUE")
  expect_true(page$lazy_debug, label = "lazy_debug should be TRUE")
  expect_equal(page$lazy_load_margin, "300px", label = "lazy_load_margin should be preserved")
  
  # === GENERATE DASHBOARD ===
  result <- generate_dashboard(dashboard, render = FALSE, open = FALSE)
  output_dir <- normalizePath(result$output_dir, mustWork = FALSE)
  
  # Verify all 3 paginated files were created
  expect_true(file.exists(file.path(output_dir, "performance.qmd")), 
              label = "First page file should exist")
  expect_true(file.exists(file.path(output_dir, "performance_p2.qmd")), 
              label = "Second page file should exist")
  expect_true(file.exists(file.path(output_dir, "performance_p3.qmd")), 
              label = "Third page file should exist")
  
  # Verify lazy loading script is in ALL paginated pages
  page1_content <- readLines(file.path(output_dir, "performance.qmd"))
  page2_content <- readLines(file.path(output_dir, "performance_p2.qmd"))
  page3_content <- readLines(file.path(output_dir, "performance_p3.qmd"))
  
  expect_true(any(grepl("Chart Lazy Loading", page1_content)), 
              label = "Page 1 should have lazy loading script")
  expect_true(any(grepl("Chart Lazy Loading", page2_content)), 
              label = "Page 2 should have lazy loading script")
  expect_true(any(grepl("Chart Lazy Loading", page3_content)), 
              label = "Page 3 should have lazy loading script")
  
  # Verify lazy load CSS is in all pages
  expect_true(any(grepl("chart-skeleton", page1_content)), 
              label = "Page 1 should have lazy loading CSS")
  expect_true(any(grepl("chart-skeleton", page2_content)), 
              label = "Page 2 should have lazy loading CSS")
  expect_true(any(grepl("chart-skeleton", page3_content)), 
              label = "Page 3 should have lazy loading CSS")
  
  # Verify lazy debug is enabled in all pages
  expect_true(any(grepl('console\\.log\\(.*Chart loaded', page1_content)), 
              label = "Page 1 should have lazy debug logging")
  expect_true(any(grepl('console\\.log\\(.*Chart loaded', page2_content)), 
              label = "Page 2 should have lazy debug logging")
  expect_true(any(grepl('console\\.log\\(.*Chart loaded', page3_content)), 
              label = "Page 3 should have lazy debug logging")
  
  # Verify navigation between pages (via create_pagination_nav R calls)
  expect_true(any(grepl('create_pagination_nav\\(1,', page1_content)), 
              label = "Page 1 should have pagination nav for page 1")
  expect_true(any(grepl('create_pagination_nav\\(2,', page2_content)), 
              label = "Page 2 should have pagination nav for page 2")
  expect_true(any(grepl('create_pagination_nav\\(2,', page2_content)), 
              label = "Page 2 pagination nav present")
  expect_true(any(grepl('create_pagination_nav\\(3,', page3_content)), 
              label = "Page 3 should have pagination nav for page 3")
  
  # Verify content distribution across pages
  # Just check that each page has visualizations (don't rely on specific variable names in output)
  # Page 1 should have visualizations
  expect_true(any(grepl("```\\{r", page1_content)), 
              label = "Page 1 should contain R chunks with visualizations")
  
  # Page 2 should have visualizations
  expect_true(any(grepl("```\\{r", page2_content)), 
              label = "Page 2 should contain R chunks with visualizations")
  
  # Page 3 should have visualizations
  expect_true(any(grepl("```\\{r", page3_content)), 
              label = "Page 3 should contain R chunks with visualizations")
  
  # Verify they're different pages by checking they have different titles or navigation
  expect_false(identical(page1_content, page2_content),
               label = "Pages 1 and 2 should have different content")
  expect_false(identical(page2_content, page3_content),
               label = "Pages 2 and 3 should have different content")
  
  # Clean up
})

test_that("USER PATTERN: Lazy loading works without pagination", {
  # Simpler test to isolate lazy loading
  
  simple_data <- mtcars[1:10, ]
  
  viz <- create_viz(type = "bar") %>%
    add_viz(title = "Chart 1", x_var = "mpg", tabgroup = "grp1") %>%
    add_viz(title = "Chart 2", x_var = "cyl", tabgroup = "grp2")
  
  # Use temp directory to avoid stale files
  test_output_dir <- tempfile("test_lazy_simple")
  on.exit(unlink(test_output_dir, recursive = TRUE), add = TRUE)
  
  dashboard <- create_dashboard(
    output_dir = test_output_dir,
    lazy_load_charts = TRUE,
    lazy_load_tabs = TRUE,
    lazy_debug = TRUE,
    lazy_load_margin = "400px"
  ) %>%
    add_page(
      name = "Test",
      data = simple_data,
      visualizations = viz,
      lazy_load_charts = TRUE,
      lazy_load_tabs = TRUE,
      lazy_debug = TRUE
    )
  
  # Verify settings preserved
  page <- dashboard$pages[[1]]
  expect_true(page$lazy_load_charts)
  expect_true(page$lazy_load_tabs)
  expect_true(page$lazy_debug)
  expect_equal(page$lazy_load_margin, "400px")
  
  result <- generate_dashboard(dashboard, render = FALSE, open = FALSE)
  output_dir <- normalizePath(result$output_dir, mustWork = FALSE)
  
  content <- readLines(file.path(output_dir, "test.qmd"))
  
  # Verify lazy loading script is present
  expect_true(any(grepl("Chart Lazy Loading", content)), 
              label = "Should have lazy loading script")
  expect_true(any(grepl("chart-skeleton", content)), 
              label = "Should have lazy loading CSS")
  expect_true(any(grepl("rootMargin.*400px", content)), 
              label = "Should use custom margin")
  expect_true(any(grepl('console\\.log\\(.*Chart loaded', content)),
              label = "Should have debug logging")

})

} # end covr CI skip

