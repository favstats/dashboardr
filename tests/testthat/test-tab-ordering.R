library(dashboardr)

test_that("User scenario: Overall tab appears FIRST, not last (sis/overall, sis/age, sis/gender, sis/edu)", {
  # This is the EXACT user scenario that was failing:
  # When combining viz collections for overall, age, gender, edu
  # The tab order should be: Overall, Age, Gender, Education
  # NOT alphabetical: Age, Education, Gender, Overall
  
  test_data <- data.frame(
    wave = rep(1:2, each = 50),
    SInfo5 = sample(1:5, 100, replace = TRUE),
    SInfo6 = sample(1:5, 100, replace = TRUE),
    SInfo7 = sample(1:5, 100, replace = TRUE),
    AgeGroup = sample(c("18-30", "31-50", "51+"), 100, replace = TRUE),
    geslacht = sample(c("Male", "Female"), 100, replace = TRUE),
    Education = sample(c("Low", "Mid", "High"), 100, replace = TRUE)
  )
  temp_data <- tempfile(fileext = ".rds")
  saveRDS(test_data, temp_data)
  
  # Create overall stackedbars (added FIRST)
  sis_viz <- create_viz(type = "stackedbars", questions = c("SInfo5", "SInfo6", "SInfo7")) %>%
    add_viz(title_tabset = "Wave 1", filter = ~ wave == 1, tabgroup = "cis/overall") %>%
    add_viz(title_tabset = "Wave 2", filter = ~ wave == 2, tabgroup = "cis/overall")
  
  # Create age stackedbars (added SECOND)
  age_vizzes <- create_viz(type = "stackedbar") %>%
    add_viz(x_var = "SInfo5", stack_var = "AgeGroup", filter = ~ wave == 1, tabgroup = "cis/age/item1") %>%
    add_viz(x_var = "SInfo5", stack_var = "AgeGroup", filter = ~ wave == 2, tabgroup = "cis/age/item1")
  
  # Create gender stackedbars (added THIRD)
  gender_vizzes <- create_viz(type = "stackedbar") %>%
    add_viz(x_var = "SInfo5", stack_var = "geslacht", filter = ~ wave == 1, tabgroup = "cis/gender/item1") %>%
    add_viz(x_var = "SInfo5", stack_var = "geslacht", filter = ~ wave == 2, tabgroup = "cis/gender/item1")
  
  # Create education stackedbars (added FOURTH)
  edu_vizzes <- create_viz(type = "stackedbar") %>%
    add_viz(x_var = "SInfo5", stack_var = "Education", filter = ~ wave == 1, tabgroup = "cis/edu/item1") %>%
    add_viz(x_var = "SInfo5", stack_var = "Education", filter = ~ wave == 2, tabgroup = "cis/edu/item1")
  
  # Combine in specific order: OVERALL, Age, Gender, Education
  combined <- sis_viz %>%
    combine_viz(age_vizzes) %>%
    combine_viz(gender_vizzes) %>%
    combine_viz(edu_vizzes) %>%
    set_tabgroup_labels(list(
      cis = "Critical Information Skills",
      overall = "Overall",
      age = "Age",
      gender = "Gender",
      edu = "Education"
    ))
  
  # Generate dashboard
  temp_dir <- tempfile()
  proj <- create_dashboard(output_dir = temp_dir, tabset_theme = "pills") %>%
    add_dashboard_page("test", visualizations = combined, data_path = temp_data)
  
  suppressMessages(generate_dashboard(proj, render = FALSE))
  
  # Read generated QMD
  qmd <- readLines(file.path(temp_dir, "test.qmd"))
  
  # Find the main section header (H2)
  h2_line <- grep("^## ", qmd)[1]
  expect_false(is.na(h2_line), "Main section should exist")
  
  # Find the H3 headers after the main section (these are the tabs: Overall, Age, Gender, Education)
  h3_lines <- grep("^### ", qmd)
  h3_tabs <- gsub("^### ", "", qmd[h3_lines])
  
  # Critical test: First tab should be "Overall", NOT "Age" (alphabetical)
  expect_true(length(h3_tabs) >= 4, 
              info = paste("Should have at least 4 tabs, found:", length(h3_tabs), 
                           "\nTabs:", paste(h3_tabs, collapse = ", ")))
  
  # Find which tabs appear first
  tab_order <- h3_tabs[1:min(4, length(h3_tabs))]
  
  expect_equal(tab_order[1], "Overall", 
               info = paste("FIRST tab should be 'Overall' (insertion order), NOT 'Age' (alphabetical). Found:", tab_order[1], 
                           "\nFull tab order:", paste(tab_order, collapse = ", ")))
  expect_equal(tab_order[2], "Age", 
               info = paste("SECOND tab should be 'Age'. Found:", tab_order[2]))
  expect_equal(tab_order[3], "Gender", 
               info = paste("THIRD tab should be 'Gender'. Found:", tab_order[3]))
  expect_equal(tab_order[4], "Education", 
               info = paste("FOURTH tab should be 'Education'. Found:", tab_order[4]))
  
  # Cleanup
  unlink(temp_dir, recursive = TRUE)
  unlink(temp_data)
})

test_that("Tabs preserve insertion order when using combine_viz", {
  # Create test data
  test_data <- data.frame(
    wave = rep(1:2, each = 50),
    SAI1 = sample(1:5, 100, replace = TRUE),
    AgeGroup = sample(c("18-30", "31-50"), 100, replace = TRUE),
    Gender = sample(c("M", "F"), 100, replace = TRUE),
    Education = sample(c("Low", "High"), 100, replace = TRUE)
  )
  temp_data <- tempfile(fileext = ".rds")
  saveRDS(test_data, temp_data)
  
  # Order of adding: overall, age, gender, edu
  sis_viz <- create_viz(type = "stackedbars", questions = "SAI1") %>%
    add_viz(title_tabset = "Wave 1", filter = ~ wave == 1, tabgroup = "ais/overall")
  
  sis_age <- create_viz(type = "stackedbar") %>%
    add_viz(x_var = "SAI1", stack_var = "AgeGroup", filter = ~ wave == 1, tabgroup = "ais/age/item1")
  
  sis_gender <- create_viz(type = "stackedbar") %>%
    add_viz(x_var = "SAI1", stack_var = "Gender", filter = ~ wave == 1, tabgroup = "ais/gender/item1")
  
  sis_edu <- create_viz(type = "stackedbar") %>%
    add_viz(x_var = "SAI1", stack_var = "Education", filter = ~ wave == 1, tabgroup = "ais/edu/item1")
  
  # Combine in order: overall, age, gender, edu
  combined <- sis_viz %>%
    combine_viz(sis_age) %>%
    combine_viz(sis_gender) %>%
    combine_viz(sis_edu)
  
  # Generate dashboard
  temp_dir <- tempfile()
  proj <- create_dashboard(output_dir = temp_dir, tabset_theme = "pills") %>%
    add_dashboard_page("test", visualizations = combined, data_path = temp_data)
  
  suppressMessages(generate_dashboard(proj, render = FALSE))
  
  # Read generated QMD
  qmd <- readLines(file.path(temp_dir, "test.qmd"))
  h3_lines <- grep("^### ", qmd, value = TRUE)
  tabs <- gsub("^### ", "", h3_lines)
  
  # Test: tabs should be in insertion order
  expect_equal(tabs[1], "overall", label = "First tab should be 'overall'")
  expect_equal(tabs[2], "age", label = "Second tab should be 'age'")
  expect_equal(tabs[3], "gender", label = "Third tab should be 'gender'")
  expect_equal(tabs[4], "edu", label = "Fourth tab should be 'edu'")
  
  # Cleanup
  unlink(temp_dir, recursive = TRUE)
  unlink(temp_data)
})

test_that("Tabs preserve insertion order with pipe operator", {
  # Create simple test
  test_data <- data.frame(
    x = 1:100,
    y = rnorm(100),
    group = sample(c("A", "B"), 100, replace = TRUE)
  )
  temp_data <- tempfile(fileext = ".rds")
  saveRDS(test_data, temp_data)
  
  # Add in specific order: zebra, apple, mango
  viz1 <- create_viz() %>%
    add_viz(type = "histogram", x_var = "x", tabgroup = "test/zebra")
  
  viz2 <- create_viz() %>%
    add_viz(type = "histogram", x_var = "y", tabgroup = "test/apple")
  
  viz3 <- create_viz() %>%
    add_viz(type = "histogram", x_var = "x", group_var = "group", tabgroup = "test/mango")
  
  # Combine - should preserve order: zebra, apple, mango (NOT alphabetical)
  combined <- viz1 + viz2 + viz3
  
  # Generate dashboard
  temp_dir <- tempfile()
  proj <- create_dashboard(output_dir = temp_dir) %>%
    add_dashboard_page("test", visualizations = combined, data_path = temp_data)
  
  suppressMessages(generate_dashboard(proj, render = FALSE))
  
  # Read generated QMD
  qmd <- readLines(file.path(temp_dir, "test.qmd"))
  h3_lines <- grep("^### ", qmd, value = TRUE)
  tabs <- gsub("^### ", "", h3_lines)
  
  # Test: NOT alphabetical (apple, mango, zebra) but insertion order (zebra, apple, mango)
  expect_equal(tabs[1], "zebra", label = "First tab should be 'zebra' (not alphabetical)")
  expect_equal(tabs[2], "apple", label = "Second tab should be 'apple'")
  expect_equal(tabs[3], "mango", label = "Third tab should be 'mango'")
  
  # Cleanup
  unlink(temp_dir, recursive = TRUE)
  unlink(temp_data)
})

test_that("Insertion indices are correctly assigned in add_viz", {
  viz <- create_viz() %>%
    add_viz(type = "histogram", x_var = "x", tabgroup = "first") %>%
    add_viz(type = "histogram", x_var = "y", tabgroup = "second") %>%
    add_viz(type = "histogram", x_var = "z", tabgroup = "third")
  
  # Check that insertion indices are sequential
  expect_equal(viz$visualizations[[1]]$.insertion_index, 1)
  expect_equal(viz$visualizations[[2]]$.insertion_index, 2)
  expect_equal(viz$visualizations[[3]]$.insertion_index, 3)
})

test_that("Insertion indices are renumbered correctly in combine_viz", {
  viz1 <- create_viz() %>%
    add_viz(type = "histogram", x_var = "a", tabgroup = "first") %>%
    add_viz(type = "histogram", x_var = "b", tabgroup = "second")
  
  viz2 <- create_viz() %>%
    add_viz(type = "histogram", x_var = "c", tabgroup = "third")
  
  combined <- combine_viz(viz1, viz2)
  
  # Check that indices are renumbered sequentially
  expect_equal(combined$visualizations[[1]]$.insertion_index, 1)
  expect_equal(combined$visualizations[[2]]$.insertion_index, 2)
  expect_equal(combined$visualizations[[3]]$.insertion_index, 3)
})

test_that("Tabs with borders removed in pills theme", {
  temp_dir <- tempfile()
  proj <- create_dashboard(output_dir = temp_dir, tabset_theme = "pills") %>%
    add_dashboard_page("test", visualizations = create_viz(), data_path = NULL)
  
  suppressMessages(generate_dashboard(proj, render = FALSE))
  
  # Check SCSS file
  scss_file <- file.path(temp_dir, "_tabset_pills.scss")
  expect_true(file.exists(scss_file))
  
  scss <- readLines(scss_file)
  
  # Check for border removal
  expect_true(any(grepl("border: none !important", scss)), 
              label = "Pills theme should have border: none")
  
  # Cleanup
  unlink(temp_dir, recursive = TRUE)
})

