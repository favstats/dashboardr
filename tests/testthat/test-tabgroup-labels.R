# Tests for set_tabgroup_labels feature
library(testthat)

test_that("set_tabgroup_labels basic functionality", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_viz(title = "Chart", tabgroup = "analysis") %>%
    set_tabgroup_labels(list(
      analysis = "Data Analysis"
    ))
  
  expect_equal(viz$tabgroup_labels$analysis, "Data Analysis")
})

test_that("set_tabgroup_labels with multiple labels", {
  viz <- create_viz(
    type = "stackedbar",
    x_var = "q",
    stack_var = "r"
  ) %>%
    add_viz(title = "Item 1", tabgroup = "demographics/age/item1") %>%
    add_viz(title = "Item 2", tabgroup = "demographics/gender/item2") %>%
    set_tabgroup_labels(list(
      demographics = "Demographics",
      age = "Age Groups",
      gender = "Gender Categories",
      item1 = "Question 1",
      item2 = "Question 2"
    ))
  
  expect_equal(viz$tabgroup_labels$demographics, "Demographics")
  expect_equal(viz$tabgroup_labels$age, "Age Groups")
  expect_equal(viz$tabgroup_labels$gender, "Gender Categories")
  expect_equal(viz$tabgroup_labels$item1, "Question 1")
  expect_equal(viz$tabgroup_labels$item2, "Question 2")
})

test_that("set_tabgroup_labels with icons", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_viz(title = "Chart", tabgroup = "analysis") %>%
    set_tabgroup_labels(list(
      analysis = "{{< iconify ph chart-line >}} Analysis"
    ))
  
  expect_true(grepl("iconify", viz$tabgroup_labels$analysis))
})

test_that("set_tabgroup_labels generates correct YAML", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_viz(title = "Chart", tabgroup = "analysis/deep") %>%
    set_tabgroup_labels(list(
      analysis = "Data Analysis",
      deep = "Deep Dive"
    ))
  
  dashboard <- create_dashboard(
    output_dir = tempfile("tabgroup_labels"),
    title = "Test"
  ) %>%
    add_page(
      "Home",
      data = data.frame(value = rnorm(100)),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_content <- paste(readLines(qmd_file, warn = FALSE), collapse = "\n")
  
  # Should have custom labels in tabset
  expect_true(grepl("Data Analysis", qmd_content))
  expect_true(grepl("Deep Dive", qmd_content))
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("set_tabgroup_labels overrides default labels", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_viz(title = "Chart", tabgroup = "wave1") %>%
    set_tabgroup_labels(list(
      wave1 = "Wave 1 (2020)"
    ))
  
  # Custom label should be stored
  expect_equal(viz$tabgroup_labels$wave1, "Wave 1 (2020)")
})

test_that("set_tabgroup_labels can be called with multiple labels", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_viz(title = "Chart 1", tabgroup = "group1") %>%
    add_viz(title = "Chart 2", tabgroup = "group2") %>%
    set_tabgroup_labels(list(
      group1 = "Group One",
      group2 = "Group Two"
    ))
  
  # Should have both labels
  expect_true("group1" %in% names(viz$tabgroup_labels))
  expect_true("group2" %in% names(viz$tabgroup_labels))
})

test_that("set_tabgroup_labels merges with existing labels", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_viz(title = "Chart 1", tabgroup = "group1") %>%
    add_viz(title = "Chart 2", tabgroup = "group2") %>%
    set_tabgroup_labels(list(
      group1 = "First Group"
    )) %>%
    set_tabgroup_labels(list(
      group1 = "Updated First Group",  # Update
      group2 = "Second Group"          # Add new
    ))
  
  # Should have updated label and new label
  expect_equal(viz$tabgroup_labels$group1, "Updated First Group")
  expect_equal(viz$tabgroup_labels$group2, "Second Group")
})

test_that("set_tabgroup_labels with empty list", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_viz(title = "Chart", tabgroup = "analysis") %>%
    set_tabgroup_labels(list())
  
  # Should not error, and original viz should be unchanged
  expect_s3_class(viz, "viz_collection")
})

test_that("set_tabgroup_labels with combine_viz", {
  viz1 <- create_viz(type = "histogram", x_var = "value") %>%
    add_viz(title = "Chart 1", tabgroup = "group1")
  
  viz2 <- create_viz(type = "histogram", x_var = "value") %>%
    add_viz(title = "Chart 2", tabgroup = "group2")
  
  combined <- combine_viz(viz1, viz2) %>%
    set_tabgroup_labels(list(
      group1 = "First Group",
      group2 = "Second Group"
    ))
  
  expect_equal(combined$tabgroup_labels$group1, "First Group")
  expect_equal(combined$tabgroup_labels$group2, "Second Group")
})

test_that("set_tabgroup_labels preserves visualization order", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_viz(title = "Chart 1", tabgroup = "a") %>%
    add_viz(title = "Chart 2", tabgroup = "b") %>%
    add_viz(title = "Chart 3", tabgroup = "c") %>%
    set_tabgroup_labels(list(
      a = "Alpha",
      b = "Beta",
      c = "Gamma"
    ))
  
  # Visualizations should still be in original order
  expect_equal(viz$items[[1]]$title, "Chart 1")
  expect_equal(viz$items[[2]]$title, "Chart 2")
  expect_equal(viz$items[[3]]$title, "Chart 3")
})

test_that("set_tabgroup_labels works with special characters", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_viz(title = "Chart", tabgroup = "special_chars") %>%
    set_tabgroup_labels(list(
      special_chars = "Special: &<>\" Characters"
    ))
  
  # Should handle special characters
  expect_equal(viz$tabgroup_labels$special_chars, "Special: &<>\" Characters")
})

test_that("set_tabgroup_labels with HTML formatting", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_viz(title = "Chart", tabgroup = "formatted") %>%
    set_tabgroup_labels(list(
      formatted = "<strong>Bold</strong> Text"
    ))
  
  # Should store HTML
  expect_true(grepl("<strong>", viz$tabgroup_labels$formatted))
})

test_that("set_tabgroup_labels works with valid input", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_viz(title = "Chart", tabgroup = "analysis")
  
  # Should work with a list
  result <- set_tabgroup_labels(viz, list(analysis = "Analysis"))
  expect_s3_class(result, "viz_collection")
})

test_that("set_tabgroup_labels works with named list", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_viz(title = "Chart", tabgroup = "analysis")
  
  result <- set_tabgroup_labels(viz, list(analysis = "Analysis"))
  expect_s3_class(result, "viz_collection")
})

test_that("set_tabgroup_labels with nested structure", {
  viz <- create_viz(
    type = "stackedbar",
    x_var = "q",
    stack_var = "r"
  ) %>%
    add_viz(title = "Item 1", tabgroup = "level1/level2/level3/item1") %>%
    set_tabgroup_labels(list(
      level1 = "Level One",
      level2 = "Level Two",
      level3 = "Level Three",
      item1 = "Item One"
    ))
  
  dashboard <- create_dashboard(
    output_dir = tempfile("nested_labels"),
    title = "Test"
  ) %>%
    add_page(
      "Home",
      data = data.frame(
        q = c("Q1", "Q2"),
        r = c("R1", "R2")
      ),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_content <- paste(readLines(qmd_file, warn = FALSE), collapse = "\n")
  
  # All custom labels should appear
  expect_true(grepl("Level One", qmd_content))
  expect_true(grepl("Level Two", qmd_content))
  expect_true(grepl("Level Three", qmd_content))
  expect_true(grepl("Item One", qmd_content))
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("set_tabgroup_labels with add_vizzes", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_vizzes(
      title = c("Wave 1", "Wave 2", "Wave 3"),
      .tabgroup_template = "waves/{title}"
    ) %>%
    set_tabgroup_labels(list(
      waves = "Survey Waves"
    ))
  
  expect_equal(viz$tabgroup_labels$waves, "Survey Waves")
})

test_that("set_tabgroup_labels preserves defaults", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value",
    bins = 30
  ) %>%
    add_viz(title = "Chart", tabgroup = "analysis") %>%
    set_tabgroup_labels(list(
      analysis = "Analysis"
    ))
  
  # Defaults should still be present
  expect_equal(viz$defaults$bins, 30)
})

test_that("set_tabgroup_labels doesn't error with extra labels", {
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_viz(title = "Chart", tabgroup = "existing")
  
  # Should not error even with extra labels
  result <- set_tabgroup_labels(viz, list(
    existing = "Exists",
    nonexistent = "Extra"
  ))
  expect_s3_class(result, "viz_collection")
})

