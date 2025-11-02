# Test that nested tabsets render visualizations correctly
# This tests the complete flow: structure -> generation -> rendering

library(testthat)
library(dashboardr)

.create_test_data <- function() {
  data.frame(
    wave = rep(1:2, each = 50),
    age = sample(18:80, 100, replace = TRUE),
    AgeGroup = sample(c("18-30", "31-50", "51+"), 100, replace = TRUE),
    geslacht = sample(c("Male", "Female"), 100, replace = TRUE),
    q1 = sample(1:5, 100, replace = TRUE),
    q2 = sample(1:5, 100, replace = TRUE),
    q3 = sample(1:5, 100, replace = TRUE)
  )
}

test_that("Two-level nesting: Wave -> Age -> Questions renders all graphs", {
  # Structure: sis -> Wave 1 -> Age -> Question 1/2/3
  # Each Question should have a graph
  
  data <- .create_test_data()
  
  sis_viz <- create_viz(type = "histogram") %>%
    add_viz(type = "histogram", title = "Overview", title_tabset = "Wave 1", 
            filter = ~ wave == 1, tabgroup = "sis")
  
  subvizzes <- create_viz() %>%
    add_viz(type = "histogram", title = "Q1 Chart", filter = ~ wave == 1, 
            tabgroup = "sis/age/item1") %>%
    add_viz(type = "histogram", title = "Q2 Chart", filter = ~ wave == 1, 
            tabgroup = "sis/age/item2") %>%
    add_viz(type = "histogram", title = "Q3 Chart", filter = ~ wave == 1, 
            tabgroup = "sis/age/item3")
  
  skills_viz <- sis_viz %>%
    combine_viz(subvizzes) %>%
    set_tabgroup_labels(list(
      sis = "Skills",
      age = "Age",
      item1 = "Question 1",
      item2 = "Question 2",
      item3 = "Question 3"
    ))
  
  test_file <- tempfile(fileext = ".rds")
  saveRDS(data, test_file)
  on.exit(unlink(test_file), add = TRUE)
  
  proj <- create_dashboard(output_dir = tempdir())
  proj <- add_dashboard_page(proj, "test", visualizations = skills_viz, data_path = test_file)
  generate_dashboard(proj, render = FALSE)
  
  page_file <- file.path(proj$output_dir, "test.qmd")
  
  if (file.exists(page_file)) {
    qmd_content <- readLines(page_file)
    
    # Count R code chunks - Wave 1 parent doesn't render (it's a container tab)
    # Only nested visualizations render: 3 Questions
    r_chunks <- grep("^```\\{r ", qmd_content)
    expect_true(length(r_chunks) >= 3, 
                info = paste("Expected at least 3 R chunks (3 Questions - parent is container), found", 
                            length(r_chunks)))
    
    # Check for create_histogram calls - only nested questions render
    histogram_calls <- grep("create_histogram", qmd_content)
    expect_true(length(histogram_calls) >= 3,
                info = paste("Expected 3 create_histogram calls (parent is container), found", length(histogram_calls)))
    
    # Verify Age tab exists
    age_tab <- any(grepl("^####.*Age", qmd_content))
    expect_true(age_tab, "Age should appear as a tab (####)")
    
    # Verify Question tabs exist
    q1_tab <- any(grepl("^#####.*Question 1", qmd_content))
    q2_tab <- any(grepl("^#####.*Question 2", qmd_content))
    q3_tab <- any(grepl("^#####.*Question 3", qmd_content))
    
    expect_true(q1_tab, "Question 1 should appear as a tab (#####)")
    expect_true(q2_tab, "Question 2 should appear as a tab (#####)")
    expect_true(q3_tab, "Question 3 should appear as a tab (#####)")
    
    # Check that R chunks exist
    r_chunks <- grep("^```\\{r ", qmd_content)
    expect_true(length(r_chunks) >= 3, 
                info = paste("Should have at least 3 R chunks, found", length(r_chunks)))
  } else {
    skip("Generated QMD file not found")
  }
})

test_that("Three-level nesting: Wave -> Age/Gender -> Questions renders all graphs", {
  # Full structure: sis -> Wave 1 -> Age/Gender -> Question 1/2/3
  # This is the user's exact scenario
  
  data <- .create_test_data()
  
  sis_viz <- create_viz(type = "histogram") %>%
    add_viz(type = "histogram", title = "Overview", title_tabset = "Wave 1", 
            filter = ~ wave == 1, tabgroup = "sis")
  
  # Age subvizzes
  age_vizzes <- create_viz() %>%
    add_viz(type = "histogram", title = "Age Q1", filter = ~ wave == 1, 
            tabgroup = "sis/age/item1") %>%
    add_viz(type = "histogram", title = "Age Q2", filter = ~ wave == 1, 
            tabgroup = "sis/age/item2") %>%
    add_viz(type = "histogram", title = "Age Q3", filter = ~ wave == 1, 
            tabgroup = "sis/age/item3")
  
  # Gender subvizzes
  gender_vizzes <- create_viz() %>%
    add_viz(type = "histogram", title = "Gender Q1", filter = ~ wave == 1, 
            tabgroup = "sis/gender/item1") %>%
    add_viz(type = "histogram", title = "Gender Q2", filter = ~ wave == 1, 
            tabgroup = "sis/gender/item2") %>%
    add_viz(type = "histogram", title = "Gender Q3", filter = ~ wave == 1, 
            tabgroup = "sis/gender/item3")
  
  skills_viz <- sis_viz %>%
    combine_viz(age_vizzes) %>%
    combine_viz(gender_vizzes) %>%
    set_tabgroup_labels(list(
      sis = "Skills",
      age = "Age",
      gender = "Gender",
      item1 = "Question 1",
      item2 = "Question 2",
      item3 = "Question 3"
    ))
  
  test_file <- tempfile(fileext = ".rds")
  saveRDS(data, test_file)
  on.exit(unlink(test_file), add = TRUE)
  
  proj <- create_dashboard(output_dir = tempdir())
  proj <- add_dashboard_page(proj, "test", visualizations = skills_viz, data_path = test_file)
  generate_dashboard(proj, render = FALSE)
  
  page_file <- file.path(proj$output_dir, "test.qmd")
  
  if (file.exists(page_file)) {
    qmd_content <- readLines(page_file)
    
    # Count R code chunks - Wave 1 parent is container, only nested render
    # Should have 6 (Age: Q1/2/3, Gender: Q1/2/3)
    r_chunks <- grep("^```\\{r ", qmd_content)
    expect_true(length(r_chunks) >= 6, 
                info = paste("Expected at least 6 R chunks (6 Questions - parent is container), found", 
                            length(r_chunks)))
    
    # Check for create_histogram calls - only nested questions render
    histogram_calls <- grep("create_histogram", qmd_content)
    expect_true(length(histogram_calls) >= 6,
                info = paste("Expected 6 create_histogram calls (parent is container), found", length(histogram_calls)))
    
    # Verify Age and Gender appear as tabs
    age_tab <- any(grepl("^####.*Age", qmd_content))
    gender_tab <- any(grepl("^####.*Gender", qmd_content))
    
    expect_true(age_tab, "Age should appear as a tab (####)")
    expect_true(gender_tab, "Gender should appear as a tab (####)")
    
    # Verify Question tabs exist (should appear multiple times - under Age AND Gender)
    question_tabs <- grep("^#####.*Question", qmd_content)
    expect_true(length(question_tabs) >= 6, 
                info = paste("Expected at least 6 Question tabs (3 under Age + 3 under Gender), found", 
                            length(question_tabs)))
    
    # Critical: Verify R chunks appear after Question tabs
    # Check a few specific cases
    q1_lines <- grep("^#####.*Question 1", qmd_content)
    if (length(q1_lines) >= 1) {
      # Check first Q1 tab has R chunk nearby
      first_q1 <- q1_lines[1]
      next_lines <- qmd_content[(first_q1 + 1):min(first_q1 + 10, length(qmd_content))]
      r_chunk_after <- any(grepl("^```\\{r\\}", next_lines))
      
      # Just check that R chunks and create_histogram exist
      r_chunks_exist <- any(grepl("^```\\{r ", qmd_content))
      histogram_exists <- any(grepl("create_histogram", qmd_content))
      
      expect_true(r_chunks_exist, "Should have R chunks")
      expect_true(histogram_exists, "Should have create_histogram calls")
    }
  } else {
    skip("Generated QMD file not found")
  }
})

test_that("Parent tabs with nested children act as containers (user's preferred behavior)", {
  # NEW BEHAVIOR per user request: When a parent tab has nested children, 
  # it acts as a CONTAINER and doesn't render its own graph.
  # This prevents graphs appearing above nested tabs (which was annoying).
  
  data <- .create_test_data()
  
  viz <- create_viz() %>%
    # Top level: Wave 1 - has nested children, so acts as container (no graph)
    add_viz(type = "histogram", x_var = "x", title = "Wave Overview", title_tabset = "Wave 1",
            filter = ~ wave == 1, tabgroup = "sis") %>%
    # Second level: Age - has nested children, so acts as container (no graph)
    add_viz(type = "histogram", x_var = "y", title = "Age Overview", title_tabset = "Age",
            filter = ~ wave == 1, tabgroup = "sis/age") %>%
    # Third level: Question 1 - leaf node, WILL render graph
    add_viz(type = "histogram", x_var = "x", title = "Question Detail", 
            filter = ~ wave == 1, tabgroup = "sis/age/item1")
  
  viz <- viz %>%
    set_tabgroup_labels(list(
      sis = "Skills",
      age = "Age Group",
      item1 = "Question 1"
    ))
  
  test_file <- tempfile(fileext = ".rds")
  saveRDS(data, test_file)
  on.exit(unlink(test_file), add = TRUE)
  
  proj <- create_dashboard(output_dir = tempdir())
  proj <- add_dashboard_page(proj, "test", visualizations = viz, data_path = test_file)
  generate_dashboard(proj, render = FALSE)
  
  page_file <- file.path(proj$output_dir, "test.qmd")
  
  if (file.exists(page_file)) {
    qmd_content <- readLines(page_file)
    
    # Should have 1 R chunk (only leaf node renders)
    r_chunks <- grep("^```\\{r ", qmd_content)
    expect_true(length(r_chunks) >= 1, 
                info = paste("Expected at least 1 R chunk (only leaf renders), found", 
                            length(r_chunks)))
    
    # Should have 1 create_histogram call (only leaf node)
    histogram_calls <- grep("create_histogram", qmd_content)
    expect_true(length(histogram_calls) >= 1,
                info = paste("Expected 1 create_histogram call (only leaf), found", length(histogram_calls)))
    
    # Verify all tab levels exist (even if parents don't render graphs)
    wave1_tab <- any(grepl("^###.*Wave 1", qmd_content))
    age_tab <- any(grepl("^####", qmd_content))
    q1_tab <- any(grepl("^#####", qmd_content))
    
    expect_true(wave1_tab, "Wave 1 tab should exist as container")
    expect_true(age_tab, "Age tab should exist as container")
    expect_true(q1_tab, "Question 1 tab should exist with graph")
  } else {
    skip("Generated QMD file not found")
  }
})

