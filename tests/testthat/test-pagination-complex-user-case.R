# Comprehensive pagination test for complex real-world use case
# This tests ALL layers that could cause pagination to disappear:
# 1. combine_viz() / combine_content()
# 2. set_tabgroup_labels()
# 3. Lazy loading
# 4. Complex nested tabgroups
# 5. Multiple viz types (stackedbars, timeline, stackedbar)
# 6. add_page()
# 7. generate_dashboard()

library(dashboardr)

test_that("pagination survives ALL layers in complex real-world use case", {
  
  # Simulate the user's data structure
  test_data <- mtcars %>% 
    dplyr::mutate(
      wave = sample(1:2, nrow(mtcars), replace = TRUE),
      wave_time_label = factor(ifelse(wave == 1, "Wave 1", "Wave 2"), 
                                levels = c("Wave 1", "Wave 2")),
      AgeGroup = sample(c("18-24", "25-34", "35-44"), nrow(mtcars), replace = TRUE),
      geslacht = sample(c("Male", "Female"), nrow(mtcars), replace = TRUE),
      Education = sample(c("Low", "Middle", "High"), nrow(mtcars), replace = TRUE)
    )
  
  # === LAYER 1: Create multiple viz collections with different types ===
  
  # Collection 1: stackedbars (multiple questions)
  perf_sis_viz <- create_viz(
    type = "stackedbars",
    questions = c("mpg", "cyl"),
    question_labels = c("Miles per Gallon", "Cylinders"),
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
  
  # Collection 2: timeline (over time)
  perf_cis_viz <- create_viz(
    type = "timeline",
    time_var = "wave_time_label",
    chart_type = "line",
    response_var = "disp"
  ) %>%
    add_viz(
      title = "Critical Info Over Time",
      tabgroup = "perf_cis/overtime/overall"
    ) %>%
    add_viz(
      title = "By Age",
      group_var = "AgeGroup",
      tabgroup = "perf_cis/overtime/age"
    )
  
  # Collection 3: stackedbar (demographics)
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
    )
  
  # Collection 4: Another stackedbar for wave 2
  perf_health_viz <- create_viz(
    type = "stackedbar",
    stacked_type = "percent",
    horizontal = TRUE,
    filter = ~ wave == 2
  ) %>%
    add_viz(
      title = "Health by Education",
      x_var = "Education",
      stack_var = "wt",
      tabgroup = "perf_health/wave2/edu"
    )
  
  # === LAYER 2: Multiple combine_viz() calls with pagination in between ===
  
  performance_collection <- perf_sis_viz %>%
    combine_viz(perf_cis_viz) %>%
    combine_viz(perf_dccs_viz) %>%
    add_pagination() %>%  # First pagination marker
    combine_viz(perf_health_viz)
  
  # Verify pagination marker exists after combines
  expect_true(
    any(sapply(performance_collection$items, function(x) {
      !is.null(x$pagination_break) && isTRUE(x$pagination_break)
    })),
    "Pagination marker should exist after combine_viz() calls"
  )
  
  # === LAYER 3: set_tabgroup_labels() ===
  
  performance_collection <- performance_collection %>%
    set_tabgroup_labels(list(
      perf_sis = "Strategic Information Performance",
      perf_cis = "Critical Information Performance",
      perf_dccs = "Digital Content Creation Performance",
      perf_health = "Health & Wellbeing Performance",
      wave1 = "Wave 1",
      wave2 = "Wave 2",
      age = "Age",
      gender = "Gender",
      edu = "Education",
      overtime = "Over Time",
      overall = "Overall"
    ))
  
  # Verify pagination marker survives set_tabgroup_labels()
  expect_true(
    any(sapply(performance_collection$items, function(x) {
      !is.null(x$pagination_break) && isTRUE(x$pagination_break)
    })),
    "Pagination marker should survive set_tabgroup_labels()"
  )
  
  # === LAYER 4: + operator (should also work) ===
  
  extra_viz <- create_viz(type = "bar") %>%
    add_viz(title = "Extra", x_var = "mpg", tabgroup = "extra/item1")
  
  performance_with_extra <- performance_collection + extra_viz
  
  # Verify pagination marker survives + operator
  expect_true(
    any(sapply(performance_with_extra$items, function(x) {
      !is.null(x$pagination_break) && isTRUE(x$pagination_break)
    })),
    "Pagination marker should survive + operator"
  )
  
  # === LAYER 5: add_page() with lazy loading ===
  
  dashboard <- create_dashboard(
    output_dir = "test_complex_pagination",
    lazy_load_charts = TRUE,
    lazy_load_margin = "300px",
    lazy_load_tabs = TRUE,
    lazy_debug = TRUE
  ) %>%
    add_page(
      name = "Performance",
      data = test_data,
      visualizations = performance_collection,
      lazy_load_charts = TRUE,
      lazy_load_tabs = TRUE,
      lazy_debug = TRUE,
      overlay = FALSE
    )
  
  # Check page has pagination markers
  page <- dashboard$pages[[1]]
  has_pagination <- any(sapply(page$visualizations, function(x) {
    !is.null(x$pagination_break) && isTRUE(x$pagination_break)
  }))
  
  expect_true(has_pagination, "Page should have pagination markers after add_page()")
  
  # === LAYER 6: generate_dashboard() ===
  
  result <- generate_dashboard(dashboard, render = FALSE, open = FALSE)
  output_dir <- normalizePath(result$output_dir, mustWork = FALSE)
  
  # Verify multiple page files were created
  expect_true(file.exists(file.path(output_dir, "performance.qmd")), 
              "First page file should exist")
  expect_true(file.exists(file.path(output_dir, "performance_p2.qmd")), 
              "Second page file should exist (pagination split)")
  
  # Verify content of first page
  page1_content <- readLines(file.path(output_dir, "performance.qmd"))
  
  # Should have navigation to next page
  expect_true(
    any(grepl("performance_p2\\.html", page1_content)),
    "First page should have navigation to second page"
  )
  
  # Verify content of second page
  page2_content <- readLines(file.path(output_dir, "performance_p2.qmd"))
  
  # Should have navigation back to first page
  expect_true(
    any(grepl("performance\\.html", page2_content)),
    "Second page should have navigation back to first page"
  )
  
  # Should contain the viz that came after pagination
  expect_true(
    any(grepl("perf_health", page2_content)),
    "Second page should contain visualizations that came after pagination marker"
  )
  
  # Clean up
})

test_that("print method handles pagination markers without crashing", {
  
  # Create collection with pagination
  viz_collection <- create_viz(type = "bar") %>%
    add_viz(title = "First", x_var = "mpg") %>%
    add_pagination() %>%
    combine_viz(create_viz(type = "bar") %>% 
                  add_viz(title = "Second", x_var = "cyl"))
  
  # This should not crash
  expect_no_error({
    output <- capture.output(print(viz_collection))
  })
  
  # Should mention pagination
  output <- capture.output(print(viz_collection))
  expect_true(any(grepl("PAGINATION", output)), 
              "Print output should mention pagination")
})

test_that("lazy loading does not interfere with pagination marker detection", {
  
  # Create paginated collection
  viz_collection <- create_viz(type = "bar") %>%
    add_viz(title = "Chart 1", x_var = "mpg") %>%
    add_pagination() %>%
    combine_viz(create_viz(type = "bar") %>% 
                  add_viz(title = "Chart 2", x_var = "cyl"))
  
  # Create dashboard with lazy loading
  dashboard <- create_dashboard(
    output_dir = "test_lazy_pagination",
    lazy_load_charts = TRUE,
    lazy_debug = TRUE
  ) %>%
    add_page(
      name = "Test",
      data = mtcars,
      visualizations = viz_collection,
      lazy_load_charts = TRUE
    )
  
  # Generate
  result <- generate_dashboard(dashboard, render = FALSE, open = FALSE)
  output_dir <- normalizePath(result$output_dir, mustWork = FALSE)
  
  # Should create paginated files even with lazy loading
  expect_true(file.exists(file.path(output_dir, "test.qmd")))
  expect_true(file.exists(file.path(output_dir, "test_p2.qmd")))
  
  # Verify lazy loading script is in BOTH pages
  page1_content <- readLines(file.path(output_dir, "test.qmd"))
  page2_content <- readLines(file.path(output_dir, "test_p2.qmd"))
  
  expect_true(any(grepl("lazyLoadCharts", page1_content)), 
              "First page should have lazy loading script")
  expect_true(any(grepl("lazyLoadCharts", page2_content)), 
              "Second page should have lazy loading script")
  
  # Clean up
})

test_that("multiple pagination markers create multiple pages", {
  
  # Create collection with 2 pagination markers = 3 pages
  viz_collection <- create_viz(type = "bar") %>%
    add_viz(title = "Page 1 Chart 1", x_var = "mpg") %>%
    add_viz(title = "Page 1 Chart 2", x_var = "cyl") %>%
    add_pagination() %>%
    combine_viz(create_viz(type = "bar") %>% 
                  add_viz(title = "Page 2 Chart", x_var = "disp")) %>%
    add_pagination() %>%
    combine_viz(create_viz(type = "bar") %>% 
                  add_viz(title = "Page 3 Chart", x_var = "hp"))
  
  dashboard <- create_dashboard(output_dir = "test_multi_pagination") %>%
    add_page(
      name = "Multi",
      data = mtcars,
      visualizations = viz_collection
    )
  
  result <- generate_dashboard(dashboard, render = FALSE, open = FALSE)
  output_dir <- normalizePath(result$output_dir, mustWork = FALSE)
  
  # Should create 3 page files
  expect_true(file.exists(file.path(output_dir, "multi.qmd")))
  expect_true(file.exists(file.path(output_dir, "multi_p2.qmd")))
  expect_true(file.exists(file.path(output_dir, "multi_p3.qmd")))
  
  # Clean up
})

test_that("complex nested tabgroups preserve pagination", {
  
  # Deep nesting like user's code: "perf_sis/wave1/overall"
  viz1 <- create_viz(type = "stackedbars", questions = c("mpg", "cyl")) %>%
    add_viz(title = "T1", tabgroup = "dimension1/wave1/overall/item1") %>%
    add_viz(title = "T2", tabgroup = "dimension1/wave1/age/item1")
  
  viz2 <- create_viz(type = "timeline", time_var = "cyl") %>%
    add_viz(title = "T3", response_var = "disp", tabgroup = "dimension2/overtime/overall")
  
  viz3 <- create_viz(type = "bar") %>%
    add_viz(title = "T4", x_var = "hp", tabgroup = "dimension3/wave2/gender/item1")
  
  # Combine with pagination
  combined <- viz1 %>%
    combine_viz(viz2) %>%
    add_pagination() %>%
    combine_viz(viz3) %>%
    set_tabgroup_labels(list(
      dimension1 = "Dimension 1",
      dimension2 = "Dimension 2",
      dimension3 = "Dimension 3",
      wave1 = "Wave 1",
      wave2 = "Wave 2",
      overtime = "Over Time",
      overall = "Overall",
      age = "Age",
      gender = "Gender",
      item1 = "Question 1"
    ))
  
  # Test pagination survives
  dashboard <- create_dashboard(output_dir = "test_nested_tabgroups") %>%
    add_page(name = "Test", data = mtcars, visualizations = combined)
  
  result <- generate_dashboard(dashboard, render = FALSE, open = FALSE)
  output_dir <- normalizePath(result$output_dir, mustWork = FALSE)
  
  expect_true(file.exists(file.path(output_dir, "test.qmd")))
  expect_true(file.exists(file.path(output_dir, "test_p2.qmd")))
  
  # Clean up
})

