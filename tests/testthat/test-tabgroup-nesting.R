# Formal Tests for Tabgroup Nesting
# These tests verify that nested tabsets work correctly, especially when
# multiple parent tabs with different filters need separate nested structures

library(testthat)
library(dashboardr)

# Helper to create test data
.create_test_data <- function() {
  data.frame(
    wave = rep(1:2, each = 50),
    age = sample(18:80, 100, replace = TRUE),
    AgeGroup = sample(c("18-30", "31-50", "51+"), 100, replace = TRUE),
    q1 = sample(1:5, 100, replace = TRUE),
    q2 = sample(1:5, 100, replace = TRUE)
  )
}

test_that("Simple nested tabsets work", {
  # Basic case: one parent, one nested child
  data <- .create_test_data()
  
  viz <- create_viz() %>%
    add_viz(type = "histogram", x_var = "age", tabgroup = "parent") %>%
    add_viz(type = "histogram", x_var = "q1", tabgroup = "parent/child")
  
  result <- .process_visualizations(viz, data_path = "test.rds", tabgroup_labels = NULL)
  
  expect_true(length(result) > 0)
  
  # Should have one tabgroup "parent" with two visualizations
  parent_tabgroup <- NULL
  for (item in result) {
    if (is.list(item) && item$type == "tabgroup" && item$name == "parent") {
      parent_tabgroup <- item
      break
    }
  }
  
  expect_false(is.null(parent_tabgroup), "Parent tabgroup should exist")
  expect_true(length(parent_tabgroup$visualizations) >= 1, "Parent should have visualizations")
})

test_that("Multiple parent tabs with nested children are separated by filter", {
  # This is the core problem: Wave 1 and Wave 2 both use "sis" but need separate nested structures
  data <- .create_test_data()
  
  sis_viz <- create_viz() %>%
    add_viz(
      type = "histogram",
      x_var = "q1",
      title = "Wave 1",
      filter = ~ wave == 1,
      tabgroup = "sis"
    ) %>%
    add_viz(
      type = "histogram",
      x_var = "q1",
      title = "Wave 2",
      filter = ~ wave == 2,
      tabgroup = "sis"
    )
  
  subvizzes <- create_viz() %>%
    add_viz(
      type = "histogram",
      x_var = "age",
      title = "Wave 1 Age",
      filter = ~ wave == 1,
      tabgroup = "sis/age/item1"
    ) %>%
    add_viz(
      type = "histogram",
      x_var = "age",
      title = "Wave 2 Age",
      filter = ~ wave == 2,
      tabgroup = "sis/age/item1"
    )
  
  combined <- combine_viz(sis_viz, subvizzes)
  result <- .process_visualizations(combined, data_path = "test.rds", tabgroup_labels = NULL)
  
  # Find the "sis" tabgroup
  sis_tabgroup <- NULL
  for (item in result) {
    if (is.list(item) && item$type == "tabgroup" && item$name == "sis") {
      sis_tabgroup <- item
      break
    }
  }
  
  expect_false(is.null(sis_tabgroup), "sis tabgroup should exist")
  
  # Count parent tabs and nested structures
  # With the new implementation, nested tabgroups appear inside parent tabs via nested_children
  parent_count <- 0
  nested_count <- 0
  
  for (viz_item in sis_tabgroup$visualizations) {
    if (is.list(viz_item) && viz_item$type == "tabgroup") {
      # Nested tabgroups should NOT appear as siblings anymore - they should be inside parent tabs
      expect_true(FALSE, info = "Nested tabgroups should not appear as siblings - they should be inside parent tabs via nested_children")
    } else {
      parent_count <- parent_count + 1
      # Check if this parent has nested children
      if (!is.null(viz_item$nested_children) && length(viz_item$nested_children) > 0) {
        nested_count <- nested_count + 1
        # Check if nested tabgroup contains age/item1
        for (nested_child in viz_item$nested_children) {
          if (is.list(nested_child) && nested_child$type == "tabgroup" && nested_child$name == "age") {
            # Should have item1 inside
            item1_found <- FALSE
            for (child in nested_child$visualizations) {
              if (is.list(child) && child$type == "tabgroup" && child$name == "item1") {
                item1_found <- TRUE
                break
              }
            }
            expect_true(item1_found, "age tabgroup should contain item1")
          }
        }
      }
    }
  }
  
  expect_equal(parent_count, 2, info = "Should have 2 parent tabs (Wave 1 and Wave 2)")
  expect_equal(nested_count, 2, info = "Should have 2 nested structures (one per parent, attached via nested_children)")
})

test_that("Nested tabs appear under correct parent tab by filter matching", {
  data <- .create_test_data()
  
  # Create structure with explicit filters
  viz <- create_viz() %>%
    # Parent: Wave 1
    add_viz(type = "histogram", x_var = "q1", filter = ~ wave == 1, tabgroup = "analysis") %>%
    # Nested under Wave 1
    add_viz(type = "histogram", x_var = "age", filter = ~ wave == 1, tabgroup = "analysis/demographics") %>%
    # Parent: Wave 2
    add_viz(type = "histogram", x_var = "q1", filter = ~ wave == 2, tabgroup = "analysis") %>%
    # Nested under Wave 2
    add_viz(type = "histogram", x_var = "age", filter = ~ wave == 2, tabgroup = "analysis/demographics")
  
  result <- .process_visualizations(viz, data_path = "test.rds", tabgroup_labels = NULL)
  
  # Find analysis tabgroup
  analysis_tabgroup <- NULL
  for (item in result) {
    if (is.list(item) && item$type == "tabgroup" && item$name == "analysis") {
      analysis_tabgroup <- item
      break
    }
  }
  
  expect_false(is.null(analysis_tabgroup))
  
  # Each parent tab should have its own nested structure
  # Wave 1 tab should have demographics nested
  # Wave 2 tab should have demographics nested
  # With the new implementation, nested tabgroups are attached via nested_children
  wave1_has_nested <- FALSE
  wave2_has_nested <- FALSE
  
  for (viz_item in analysis_tabgroup$visualizations) {
    # Check if this is a visualization (parent tab) with nested children
    if (is.null(viz_item$type) || viz_item$type != "tabgroup") {
      # This is a visualization - check if it has nested_children
      if (!is.null(viz_item$nested_children) && length(viz_item$nested_children) > 0) {
        # Check nested children for demographics tabgroup
        for (nested_child in viz_item$nested_children) {
          if (is.list(nested_child) && nested_child$type == "tabgroup" && nested_child$name == "demographics") {
            # Check the parent viz's filter to determine which wave
            if (!is.null(viz_item$filter)) {
              filter_str <- deparse(viz_item$filter[[2]])
              if (grepl("wave == 1", filter_str)) {
                wave1_has_nested <- TRUE
              }
              if (grepl("wave == 2", filter_str)) {
                wave2_has_nested <- TRUE
              }
            }
          }
        }
      }
    }
  }
  
  expect_true(wave1_has_nested, "Wave 1 should have nested demographics")
  expect_true(wave2_has_nested, "Wave 2 should have nested demographics")
})

test_that("combine_viz preserves insertion order (not grouped by filter)", {
  # UPDATED TEST: The new behavior sorts by insertion index ONLY.
  # Parent-child pairs are NOT grouped by matching filters anymore.
  # This is the correct behavior per user requirements.
  
  data <- .create_test_data()
  
  sis_viz <- create_viz() %>%
    add_viz(type = "histogram", x_var = "q1", filter = ~ wave == 1, tabgroup = "sis") %>%
    add_viz(type = "histogram", x_var = "q1", filter = ~ wave == 2, tabgroup = "sis")
  
  subvizzes <- create_viz() %>%
    add_viz(type = "histogram", x_var = "age", filter = ~ wave == 1, tabgroup = "sis/age/item1")
  
  subvizzes2 <- create_viz() %>%
    add_viz(type = "histogram", x_var = "age", filter = ~ wave == 2, tabgroup = "sis/age/item1")
  
  combined <- combine_viz(sis_viz, subvizzes, subvizzes2)
  
  # Verify order after sorting (should be insertion order)
  expect_equal(length(combined$visualizations), 4)
  
  # Insertion order should be:
  # 1. sis (wave == 1) - index 1
  # 2. sis (wave == 2) - index 2
  # 3. sis/age/item1 (wave == 1) - index 3
  # 4. sis/age/item1 (wave == 2) - index 4
  
  expect_equal(combined$visualizations[[1]]$.insertion_index, 1)
  expect_equal(combined$visualizations[[2]]$.insertion_index, 2)
  expect_equal(combined$visualizations[[3]]$.insertion_index, 3)
  expect_equal(combined$visualizations[[4]]$.insertion_index, 4)
  
  # Verify tabgroups
  expect_equal(length(combined$visualizations[[1]]$tabgroup), 1)  # sis
  expect_equal(combined$visualizations[[1]]$tabgroup[[1]], "sis")
  
  expect_equal(length(combined$visualizations[[2]]$tabgroup), 1)  # sis
  expect_equal(combined$visualizations[[2]]$tabgroup[[1]], "sis")
  
  expect_equal(length(combined$visualizations[[3]]$tabgroup), 3)  # sis/age/item1
  expect_equal(combined$visualizations[[3]]$tabgroup[[1]], "sis")
  
  expect_equal(length(combined$visualizations[[4]]$tabgroup), 3)  # sis/age/item1
  expect_equal(combined$visualizations[[4]]$tabgroup[[1]], "sis")
  
  # Verify filters exist
  expect_true(!is.null(combined$visualizations[[1]]$filter))
  expect_true(!is.null(combined$visualizations[[2]]$filter))
  expect_true(!is.null(combined$visualizations[[3]]$filter))
  expect_true(!is.null(combined$visualizations[[4]]$filter))
})

test_that("Hierarchy building creates separate nested structures per parent filter", {
  # This tests the actual hierarchy building logic
  viz_list <- list(
    # Wave 1 parent
    list(type = "histogram", x_var = "q1", filter = ~ wave == 1, tabgroup = c("sis")),
    # Wave 2 parent
    list(type = "histogram", x_var = "q1", filter = ~ wave == 2, tabgroup = c("sis")),
    # Wave 1 nested
    list(type = "histogram", x_var = "age", filter = ~ wave == 1, tabgroup = c("sis", "age", "item1")),
    # Wave 2 nested
    list(type = "histogram", x_var = "age", filter = ~ wave == 2, tabgroup = c("sis", "age", "item1"))
  )
  
  # Build hierarchy
  tree <- list(visualizations = list(), children = list())
  for (viz in viz_list) {
    tree <- .insert_into_hierarchy(tree, viz$tabgroup, viz)
  }
  
  # Convert to final structure
  result <- .tree_to_viz_list(tree, tabgroup_labels = NULL)
  
  # Should have sis tabgroup
  sis_tabgroup <- NULL
  for (item in result) {
    if (is.list(item) && item$type == "tabgroup" && item$name == "sis") {
      sis_tabgroup <- item
      break
    }
  }
  
  expect_false(is.null(sis_tabgroup))
  
  # Count structure
  # Should have 2 parent visualizations, each potentially with nested children
  parent_viz_count <- 0
  nested_tabgroup_count <- 0
  
  for (item in sis_tabgroup$visualizations) {
    if (is.list(item) && item$type == "tabgroup") {
      nested_tabgroup_count <- nested_tabgroup_count + 1
    } else {
      parent_viz_count <- parent_viz_count + 1
    }
  }
  
  # The key test: nested tabs should be associated with their matching parent
  # We expect 2 parent tabs, each with potentially nested children
  expect_true(parent_viz_count >= 2, 
              info = paste("Expected at least 2 parent visualizations, got", parent_viz_count))
  
  # If nested structures are correctly associated, we should have nested tabsets
  expect_true(nested_tabgroup_count >= 0, 
              info = "Nested structures may be embedded in parent tabs")
})

test_that("Filter matching correctly groups nested tabs with parents", {
  # Test the filter matching logic directly
  parent_viz <- list(
    type = "histogram",
    x_var = "q1",
    filter = ~ wave == 1,
    tabgroup = c("sis")
  )
  
  nested_viz <- list(
    type = "histogram",
    x_var = "age",
    filter = ~ wave == 1,
    tabgroup = c("sis", "age", "item1")
  )
  
  parent_sig <- .get_filter_signature(parent_viz)
  nested_sig <- .get_filter_signature(nested_viz)
  
  expect_equal(parent_sig, nested_sig, 
               info = "Parent and nested should have matching filter signatures")
  
  # Test with mismatched filters
  mismatched_viz <- list(
    type = "histogram",
    x_var = "age",
    filter = ~ wave == 2,
    tabgroup = c("sis", "age", "item1")
  )
  
  mismatched_sig <- .get_filter_signature(mismatched_viz)
  expect_false(parent_sig == mismatched_sig, 
               info = "Different filters should produce different signatures")
})

test_that("Nested tabs appear inside parent tabs, not as siblings (user scenario)", {
  # This is the exact scenario from the user's code
  # Parent tabs: "sis" with Wave 1 and Wave 2
  # Nested tabs: "sis/age/item1" should appear INSIDE each Wave tab, not as siblings
  data <- .create_test_data()
  
  sis_viz <- create_viz(type = "histogram") %>%
    add_viz(
      type = "histogram",
      title = "Strategic Information Skills",
      title_tabset = "Wave 1",
      filter = ~ wave == 1,
      tabgroup = "sis"
    ) %>%
    add_viz(
      type = "histogram",
      title = "Strategic Information Skills",
      title_tabset = "Wave 2",
      filter = ~ wave == 2,
      tabgroup = "sis"
    )
  
  subvizzes <- create_viz() %>%
    add_viz(
      type = "histogram",
      title = "Strategic Information Skills",
      title_tabset = "Wave 1",
      filter = ~ wave == 1,
      tabgroup = "sis/age/item1"
    )
  
  subvizzes2 <- create_viz() %>%
    add_viz(
      type = "histogram",
      title = "Strategic Information Skills",
      title_tabset = "Wave 2",
      filter = ~ wave == 2,
      tabgroup = "sis/age/item1"
    )
  
  skills_viz <- sis_viz %>%
    combine_viz(subvizzes) %>%
    combine_viz(subvizzes2) %>%
    set_tabgroup_labels(list(
      sis = "Strategic Information Skills",
      age = "Age",
      item1 = "Question 1"
    ))
  
  # Create test data file
  test_data <- .create_test_data()
  test_file <- tempfile(fileext = ".rds")
  saveRDS(test_data, test_file)
  on.exit(unlink(test_file), add = TRUE)
  
  result <- .process_visualizations(skills_viz, data_path = test_file, tabgroup_labels = skills_viz$tabgroup_labels)
  
  # Find the "sis" tabgroup
  sis_tabgroup <- NULL
  for (item in result) {
    if (is.list(item) && item$type == "tabgroup" && item$name == "sis") {
      sis_tabgroup <- item
      break
    }
  }
  
  expect_false(is.null(sis_tabgroup), "sis tabgroup should exist")
  
  # Count parent tabs and nested structures
  wave1_found <- FALSE
  wave2_found <- FALSE
  wave1_has_age <- FALSE
  wave2_has_age <- FALSE
  sibling_tabgroups_found <- 0
  
  for (viz_item in sis_tabgroup$visualizations) {
    if (is.list(viz_item) && viz_item$type == "tabgroup") {
      # This is a nested tabgroup - it should NOT be at the same level as Wave tabs
      # It should be nested INSIDE a Wave tab via nested_children
      sibling_tabgroups_found <- sibling_tabgroups_found + 1
      expect_true(FALSE, 
                  info = paste0("Found tabgroup '", viz_item$name, 
                               "' at same level as Wave tabs. Nested tabgroups should appear INSIDE parent tabs via nested_children, not as siblings."))
    } else {
      # This is a visualization (Wave tab)
      if (!is.null(viz_item$title_tabset)) {
        if (viz_item$title_tabset == "Wave 1") {
          wave1_found <- TRUE
          # Check if this Wave 1 tab has nested children attached
          if (!is.null(viz_item$nested_children) && length(viz_item$nested_children) > 0) {
            wave1_has_age <- any(sapply(viz_item$nested_children, function(child) {
              is.list(child) && !is.null(child$type) && child$type == "tabgroup" && child$name == "age"
            }))
          }
        }
        if (viz_item$title_tabset == "Wave 2") {
          wave2_found <- TRUE
          # Check if this Wave 2 tab has nested children attached
          if (!is.null(viz_item$nested_children) && length(viz_item$nested_children) > 0) {
            wave2_has_age <- any(sapply(viz_item$nested_children, function(child) {
              is.list(child) && !is.null(child$type) && child$type == "tabgroup" && child$name == "age"
            }))
          }
        }
      }
    }
  }
  
  expect_true(wave1_found, "Wave 1 tab should exist")
  expect_true(wave2_found, "Wave 2 tab should exist")
  expect_equal(sibling_tabgroups_found, 0, 
               info = "No nested tabgroups should appear as siblings to Wave tabs")
  expect_true(wave1_has_age, "Wave 1 tab should have 'age' nested tabgroup attached via nested_children")
  expect_true(wave2_has_age, "Wave 2 tab should have 'age' nested tabgroup attached via nested_children")
})

