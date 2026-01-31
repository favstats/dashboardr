# =============================================================================
# Test Script: Visualization Spec Validation
# =============================================================================
# This script demonstrates the new validation system that catches errors early,
# before Quarto rendering, with helpful error messages.

library(dashboardr)

# Sample data for testing
data <- mtcars

# =============================================================================
# 1. VALID COLLECTION - Should pass validation
# =============================================================================
cat("\n", strrep("=", 60), "\n")
cat("TEST 1: Valid collection\n")
cat(strrep("=", 60), "\n\n")

viz_valid <- create_viz(data = data) %>%
  add_viz(type = "histogram", x_var = "mpg", title = "MPG Distribution") %>%
  add_viz(type = "scatter", x_var = "wt", y_var = "mpg", title = "Weight vs MPG")

# Validate manually
validate_specs(viz_valid)

# Preview should work without issues
# viz_valid %>% preview()

# =============================================================================
# 2. MISSING REQUIRED PARAMETER - stackedbar needs stack_var
# =============================================================================
cat("\n", strrep("=", 60), "\n")
cat("TEST 2: Missing required parameter (stack_var)\n")
cat(strrep("=", 60), "\n\n")

viz_missing_param <- create_viz(data = data) %>%
  add_viz(type = "stackedbar", x_var = "cyl", title = "Cylinders")  # Missing stack_var!

# This will show the validation error
validate_specs(viz_missing_param)
print(viz_missing_param, check = T)
# Uncomment to see preview() catch the error:
# viz_missing_param %>% preview()

# =============================================================================
# 3. INVALID COLUMN NAME - Column doesn't exist in data
# =============================================================================
cat("\n", strrep("=", 60), "\n")
cat("TEST 3: Invalid column name\n")
cat(strrep("=", 60), "\n\n")

viz_bad_column <- create_viz(data = data) %>%
  add_viz(type = "histogram", x_var = "nonexistent_column")

validate_specs(viz_bad_column)

# =============================================================================
# 4. TYPO IN COLUMN NAME - Should suggest correct name
# =============================================================================
cat("\n", strrep("=", 60), "\n")
cat("TEST 4: Typo in column name (should suggest correction)\n")
cat(strrep("=", 60), "\n\n")

viz_typo <- create_viz(data = data) %>%
  add_viz(type = "histogram", x_var = "mpgg")  # Typo: should be "mpg"

validate_specs(viz_typo)

# =============================================================================
# 5. MULTIPLE ERRORS - Shows all issues at once
# =============================================================================
cat("\n", strrep("=", 60), "\n")
cat("TEST 5: Multiple errors in collection\n")
cat(strrep("=", 60), "\n\n")

viz_multiple_errors <- create_viz(data = data) %>%
  add_viz(type = "stackedbar", x_var = "cyl") %>%           # Missing stack_var

  add_viz(type = "scatter", x_var = "wt") %>%               # Missing y_var
  add_viz(type = "heatmap", x_var = "cyl", y_var = "gear")  # Missing value_var

validate_specs(viz_multiple_errors)

# =============================================================================
# 6. PRINT WITH CHECK - Validate while viewing structure
# =============================================================================
cat("\n", strrep("=", 60), "\n")
cat("TEST 6: print(collection, check = TRUE)\n")
cat(strrep("=", 60), "\n\n")

viz_for_print <- create_viz(data = data) %>%
  add_viz(type = "histogram", x_var = "mpg") %>%
  add_viz(type = "bar", x_var = "cyl")

# This prints the structure AND validates
print(viz_for_print, check = TRUE)

# =============================================================================
# 7. PROGRAMMATIC VALIDATION - Silent mode for scripts
# =============================================================================
cat("\n", strrep("=", 60), "\n")
cat("TEST 7: Programmatic validation (verbose = FALSE)\n")
cat(strrep("=", 60), "\n\n")

viz_to_check <- create_viz(data = data) %>%
  add_viz(type = "stackedbar", x_var = "cyl")  # Missing stack_var

result <- validate_specs(viz_to_check, verbose = FALSE)

if (result) {
  cat("All specs are valid!\n")
} else {
  cat("Validation failed. Issues:\n")
  issues <- attr(result, "issues")
  print(issues)
}

# =============================================================================
# 8. PREVIEW CATCHES ERRORS EARLY
# =============================================================================
cat("\n", strrep("=", 60), "\n")
cat("TEST 8: preview() catches errors before rendering\n")
cat(strrep("=", 60), "\n\n")

viz_will_fail <- create_viz(data = data) %>%
  add_viz(type = "treemap", group_var = "cyl")  # Missing value_var

# This will error with a helpful message (not a cryptic Quarto error)
tryCatch({
  viz_will_fail %>% preview(open = FALSE)
}, error = function(e) {
  cat("Error caught by preview():\n")
  cat(e$message, "\n")
})

# =============================================================================
# 9. CONTENT-ONLY COLLECTIONS - No validation needed
# =============================================================================
cat("\n", strrep("=", 60), "\n")
cat("TEST 9: Content-only collection (no validation needed)\n")
cat(strrep("=", 60), "\n\n")

content_only <- create_content() %>%
  add_text("# My Analysis") %>%
  add_text("This is some descriptive text.") %>%
  add_callout("Important note!", type = "tip")

validate_specs(content_only)

# =============================================================================
# 10. MIXED CONTENT AND VIZ
# =============================================================================
cat("\n", strrep("=", 60), "\n")
cat("TEST 10: Mixed content and visualizations\n")
cat(strrep("=", 60), "\n\n")

mixed <- create_viz(data = data) %>%
  add_text("# Analysis Results") %>%
  add_viz(type = "histogram", x_var = "mpg", title = "Distribution") %>%
  add_text("The histogram shows the MPG distribution.") %>%
  add_viz(type = "scatter", x_var = "wt", y_var = "mpg", title = "Correlation")

validate_specs(mixed)

# =============================================================================
cat("\n", strrep("=", 60), "\n")
cat("ALL TESTS COMPLETED!\n")
cat(strrep("=", 60), "\n\n")

