test_that("validate_na_params validates include_na correctly", {
  # Valid inputs
  expect_equal(validate_na_params(TRUE, "(Missing)", "na_label"), "(Missing)")
  expect_equal(validate_na_params(FALSE, "NA", "na_label"), "NA")
  
  # Invalid include_na
  expect_error(
    validate_na_params("yes", "(Missing)", "na_label"),
    "`include_na` must be logical"
  )
  expect_error(
    validate_na_params(1, "(Missing)", "na_label"),
    "`include_na` must be logical"
  )
})

test_that("validate_na_params validates na_label correctly", {
  # Invalid na_label - not character
  expect_error(
    validate_na_params(TRUE, 123, "na_label"),
    "`na_label` must be a single character string"
  )
  
  # Invalid na_label - multiple values
  expect_error(
    validate_na_params(TRUE, c("NA", "Missing"), "na_label"),
    "`na_label` must be a single character string"
  )
  
  # Empty string gets warning and replacement
  expect_warning(
    result <- validate_na_params(TRUE, "", "na_label"),
    "`na_label` is empty string - using '\\(Missing\\)' instead"
  )
  expect_equal(result, "(Missing)")
})

test_that("validate_na_params respects param_name argument", {
  expect_error(
    validate_na_params(TRUE, 123, "custom_param"),
    "`custom_param` must be a single character string"
  )
  
  expect_warning(
    validate_na_params(TRUE, "", "my_label"),
    "`my_label` is empty string"
  )
})

test_that("handle_na_for_plotting works without NAs and include_na = FALSE", {
  df <- data.frame(
    x = c("A", "B", "C", "A", "B"),
    y = 1:5
  )
  
  result <- handle_na_for_plotting(
    data = df,
    var_name = "x",
    include_na = FALSE,
    na_label = "(Missing)"
  )
  
  expect_s3_class(result, "factor")
  expect_equal(levels(result), c("A", "B", "C"))
  expect_equal(as.character(result), c("A", "B", "C", "A", "B"))
})

test_that("handle_na_for_plotting excludes NAs when include_na = FALSE", {
  df <- data.frame(
    x = c("A", "B", NA, "C", NA, "A"),
    y = 1:6
  )
  
  result <- handle_na_for_plotting(
    data = df,
    var_name = "x",
    include_na = FALSE,
    na_label = "(Missing)"
  )
  
  expect_s3_class(result, "factor")
  expect_equal(levels(result), c("A", "B", "C"))
  # NAs should remain as NA in the factor
  expect_equal(sum(is.na(result)), 2)
})

test_that("handle_na_for_plotting includes NAs with custom label when include_na = TRUE", {
  df <- data.frame(
    x = c("A", "B", NA, "C", NA, "A"),
    y = 1:6
  )
  
  result <- handle_na_for_plotting(
    data = df,
    var_name = "x",
    include_na = TRUE,
    na_label = "(Missing)"
  )
  
  expect_s3_class(result, "factor")
  expect_equal(levels(result), c("A", "B", "C", "(Missing)"))
  expect_equal(sum(is.na(result)), 0)  # No NAs should remain
  expect_equal(as.character(result), c("A", "B", "(Missing)", "C", "(Missing)", "A"))
})

test_that("handle_na_for_plotting places NA label at end by default", {
  df <- data.frame(
    x = c("Z", "A", NA, "M", NA, "B"),
    y = 1:6
  )
  
  result <- handle_na_for_plotting(
    data = df,
    var_name = "x",
    include_na = TRUE,
    na_label = "No Data"
  )
  
  expect_s3_class(result, "factor")
  # Alphabetical order with NA label at end
  expect_equal(levels(result), c("A", "B", "M", "Z", "No Data"))
})

test_that("handle_na_for_plotting respects custom_order", {
  df <- data.frame(
    x = c("Low", "Medium", "High", "Low", "High"),
    y = 1:5
  )
  
  result <- handle_na_for_plotting(
    data = df,
    var_name = "x",
    include_na = FALSE,
    na_label = "(Missing)",
    custom_order = c("Low", "Medium", "High")
  )
  
  expect_s3_class(result, "factor")
  expect_equal(levels(result), c("Low", "Medium", "High"))
})

test_that("handle_na_for_plotting adds NA label to custom_order if missing", {
  df <- data.frame(
    x = c("Low", "Medium", NA, "High", NA, "Low"),
    y = 1:6
  )
  
  result <- handle_na_for_plotting(
    data = df,
    var_name = "x",
    include_na = TRUE,
    na_label = "Unknown",
    custom_order = c("Low", "Medium", "High")
  )
  
  expect_s3_class(result, "factor")
  # NA label should be added at end of custom order
  expect_equal(levels(result), c("Low", "Medium", "High", "Unknown"))
})

test_that("handle_na_for_plotting preserves custom_order with NA label already included", {
  df <- data.frame(
    x = c("Low", "Medium", NA, "High", NA, "Low"),
    y = 1:6
  )
  
  result <- handle_na_for_plotting(
    data = df,
    var_name = "x",
    include_na = TRUE,
    na_label = "Unknown",
    custom_order = c("Low", "Unknown", "Medium", "High")
  )
  
  expect_s3_class(result, "factor")
  # Should preserve the custom order including NA label position
  expect_equal(levels(result), c("Low", "Unknown", "Medium", "High"))
})

test_that("handle_na_for_plotting handles custom_order with extra values", {
  df <- data.frame(
    x = c("Low", "Medium", "Low"),
    y = 1:3
  )
  
  result <- handle_na_for_plotting(
    data = df,
    var_name = "x",
    include_na = FALSE,
    na_label = "(Missing)",
    custom_order = c("Low", "Medium", "High", "Very High")
  )
  
  expect_s3_class(result, "factor")
  # When include_na = FALSE, factor() uses full custom_order as levels
  expect_equal(levels(result), c("Low", "Medium", "High", "Very High"))
  # But only present values appear in data
  expect_equal(as.character(result[!is.na(result)]), c("Low", "Medium", "Low"))
})

test_that("handle_na_for_plotting handles numeric-like strings correctly with include_na = TRUE", {
  df <- data.frame(
    x = c("1", "10", "2", "20", "3"),
    y = 1:5
  )
  
  result <- handle_na_for_plotting(
    data = df,
    var_name = "x",
    include_na = TRUE,  # Numeric sorting only happens with include_na = TRUE
    na_label = "(Missing)"
  )
  
  expect_s3_class(result, "factor")
  # Should sort numerically, not alphabetically
  expect_equal(levels(result), c("1", "2", "3", "10", "20"))
})

test_that("handle_na_for_plotting uses standard factor() with include_na = FALSE", {
  df <- data.frame(
    x = c("1", "10", "2", "20", "3"),
    y = 1:5
  )
  
  result <- handle_na_for_plotting(
    data = df,
    var_name = "x",
    include_na = FALSE,
    na_label = "(Missing)"
  )
  
  expect_s3_class(result, "factor")
  # Standard factor() sorts alphabetically
  expect_equal(levels(result), c("1", "10", "2", "20", "3"))
})

test_that("handle_na_for_plotting handles numeric-like strings with NAs", {
  df <- data.frame(
    x = c("1", "10", NA, "2", NA, "20"),
    y = 1:6
  )
  
  result <- handle_na_for_plotting(
    data = df,
    var_name = "x",
    include_na = TRUE,
    na_label = "No Response"
  )
  
  expect_s3_class(result, "factor")
  # Numeric sorting with NA label at end
  expect_equal(levels(result), c("1", "2", "10", "20", "No Response"))
})

test_that("handle_na_for_plotting handles mixed numeric/non-numeric strings", {
  df <- data.frame(
    x = c("1", "Yes", "2", "No", "3"),
    y = 1:5
  )
  
  result <- handle_na_for_plotting(
    data = df,
    var_name = "x",
    include_na = FALSE,
    na_label = "(Missing)"
  )
  
  expect_s3_class(result, "factor")
  # Should sort alphabetically when not all numeric
  expect_equal(levels(result), c("1", "2", "3", "No", "Yes"))
})

test_that("handle_na_for_plotting works with empty data after NA removal", {
  df <- data.frame(
    x = c(NA, NA, NA),
    y = 1:3
  )
  
  result_exclude <- handle_na_for_plotting(
    data = df,
    var_name = "x",
    include_na = FALSE,
    na_label = "(Missing)"
  )
  
  expect_s3_class(result_exclude, "factor")
  expect_equal(length(levels(result_exclude)), 0)
  expect_equal(sum(is.na(result_exclude)), 3)
  
  result_include <- handle_na_for_plotting(
    data = df,
    var_name = "x",
    include_na = TRUE,
    na_label = "(Missing)"
  )
  
  expect_s3_class(result_include, "factor")
  expect_equal(levels(result_include), "(Missing)")
  expect_equal(sum(is.na(result_include)), 0)
})

test_that("handle_na_for_plotting preserves remaining levels with include_na = TRUE", {
  df <- data.frame(
    x = c("A", "B", "C", "D", "E"),
    y = 1:5
  )
  
  result <- handle_na_for_plotting(
    data = df,
    var_name = "x",
    include_na = TRUE,  # Need include_na = TRUE to append remaining levels
    na_label = "(Missing)",
    custom_order = c("C", "A")  # Only specify some levels
  )
  
  expect_s3_class(result, "factor")
  # Specified levels first, then remaining in alphabetical order
  expect_equal(levels(result), c("C", "A", "B", "D", "E"))
})

test_that("handle_na_for_plotting with include_na = FALSE uses only custom_order", {
  df <- data.frame(
    x = c("A", "B", "C", "D", "E"),
    y = 1:5
  )
  
  result <- handle_na_for_plotting(
    data = df,
    var_name = "x",
    include_na = FALSE,
    na_label = "(Missing)",
    custom_order = c("C", "A")  # Only specify some levels
  )
  
  expect_s3_class(result, "factor")
  # With include_na = FALSE, only uses specified levels
  expect_equal(levels(result), c("C", "A"))
  # Values not in custom_order become NA
  expect_equal(sum(is.na(result)), 3)  # B, D, E become NA
})

test_that("integration: viz_histogram uses NA helpers correctly", {
  df <- data.frame(
    category = c("A", "B", NA, "C", NA, "A", "B"),
    count = 1:7
  )
  
  # Without NA inclusion
  plot1 <- viz_histogram(
    data = df,
    x_var = "category",
    include_na = FALSE
  )
  expect_s3_class(plot1, "highchart")
  
  # With NA inclusion
  plot2 <- viz_histogram(
    data = df,
    x_var = "category",
    include_na = TRUE,
    na_label = "Missing Data"
  )
  expect_s3_class(plot2, "highchart")
  
  # With custom ordering and NA
  plot3 <- viz_histogram(
    data = df,
    x_var = "category",
    include_na = TRUE,
    na_label = "No Response",
    x_order = c("C", "B", "A")
  )
  expect_s3_class(plot3, "highchart")
})

test_that("integration: viz_stackedbar uses NA helpers correctly", {
  df <- data.frame(
    question = c("Q1", "Q2", NA, "Q1", "Q2", NA),
    response = c("Yes", NA, "No", "Yes", "No", NA),
    count = 1:6
  )
  
  # Without NA inclusion
  plot1 <- viz_stackedbar(
    data = df,
    x_var = "question",
    stack_var = "response",
    include_na = FALSE
  )
  expect_s3_class(plot1, "highchart")
  
  # With NA inclusion for both variables
  plot2 <- viz_stackedbar(
    data = df,
    x_var = "question",
    stack_var = "response",
    include_na = TRUE,
    na_label_x = "(No Question)",
    na_label_stack = "(No Answer)"
  )
  expect_s3_class(plot2, "highchart")
  
  # With custom ordering and NA
  plot3 <- viz_stackedbar(
    data = df,
    x_var = "question",
    stack_var = "response",
    include_na = TRUE,
    na_label_x = "Missing Q",
    na_label_stack = "Missing R",
    x_order = c("Q2", "Q1"),
    stack_order = c("Yes", "No")
  )
  expect_s3_class(plot3, "highchart")
})

test_that("integration: NA helpers work with weight_var", {
  df <- data.frame(
    category = c("A", "B", NA, "C", NA, "A"),
    weight = c(1.5, 2.0, 1.0, 2.5, 1.5, 1.0)
  )
  
  # Histogram with weights and NA inclusion
  plot1 <- viz_histogram(
    data = df,
    x_var = "category",
    weight_var = "weight",
    include_na = TRUE,
    na_label = "Weighted Missing"
  )
  expect_s3_class(plot1, "highchart")
  
  # Stackedbar with weights and NA inclusion
  df2 <- data.frame(
    x = c("A", "B", NA, "A", "B"),
    stack = c("1", NA, "2", "1", "2"),
    weight = c(1.0, 2.0, 1.5, 1.5, 2.5)
  )
  
  plot2 <- viz_stackedbar(
    data = df2,
    x_var = "x",
    stack_var = "stack",
    weight_var = "weight",
    include_na = TRUE,
    na_label_x = "(No X)",
    na_label_stack = "(No Stack)"
  )
  expect_s3_class(plot2, "highchart")
})

test_that("edge case: handle_na_for_plotting with all same value plus NAs", {
  df <- data.frame(
    x = c("A", "A", NA, "A", NA, "A"),
    y = 1:6
  )
  
  result <- handle_na_for_plotting(
    data = df,
    var_name = "x",
    include_na = TRUE,
    na_label = "Missing"
  )
  
  expect_s3_class(result, "factor")
  expect_equal(levels(result), c("A", "Missing"))
  expect_equal(sum(result == "A"), 4)
  expect_equal(sum(result == "Missing"), 2)
})

test_that("edge case: handle_na_for_plotting with single row", {
  df <- data.frame(x = "A", y = 1)
  
  result <- handle_na_for_plotting(
    data = df,
    var_name = "x",
    include_na = FALSE
  )
  
  expect_s3_class(result, "factor")
  expect_equal(levels(result), "A")
  expect_equal(length(result), 1)
})

test_that("edge case: custom_order with no matching values and include_na = FALSE", {
  df <- data.frame(
    x = c("A", "B", "C"),
    y = 1:3
  )
  
  result <- handle_na_for_plotting(
    data = df,
    var_name = "x",
    include_na = FALSE,
    custom_order = c("X", "Y", "Z")
  )
  
  expect_s3_class(result, "factor")
  # With include_na = FALSE, uses custom_order levels even if they don't match
  expect_equal(levels(result), c("X", "Y", "Z"))
  # All data values become NA since they don't match levels
  expect_equal(sum(is.na(result)), 3)
})

test_that("edge case: custom_order with no matching values and include_na = TRUE", {
  df <- data.frame(
    x = c("A", "B", "C"),
    y = 1:3
  )
  
  result <- handle_na_for_plotting(
    data = df,
    var_name = "x",
    include_na = TRUE,
    custom_order = c("X", "Y", "Z")
  )
  
  expect_s3_class(result, "factor")
  # With include_na = TRUE, appends actual data values to custom_order
  # Since no overlap, all actual values are in "remaining"
  expect_equal(levels(result), c("A", "B", "C"))
})

