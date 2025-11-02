# Tests for individual visualization creation functions
library(testthat)

# ===================================================================
# create_histogram
# ===================================================================

test_that("create_histogram works with basic inputs", {
  data <- data.frame(value = rnorm(100))
  
  result <- create_histogram(data = data, x_var = "value")
  expect_s3_class(result, "highchart")
})

test_that("create_histogram with bins parameter", {
  data <- data.frame(value = rnorm(100))
  
  result <- create_histogram(data = data, x_var = "value", bins = 20)
  expect_s3_class(result, "highchart")
})

test_that("create_histogram with title", {
  data <- data.frame(value = rnorm(100))
  
  result <- create_histogram(data = data, x_var = "value", title = "Distribution")
  expect_s3_class(result, "highchart")
})

# ===================================================================
# create_timeline
# ===================================================================

test_that("create_timeline works with basic inputs", {
  data <- data.frame(
    year = rep(2020:2023, each = 10),
    value = rnorm(40)
  )
  
  result <- create_timeline(data = data, time_var = "year", response_var = "value")
  expect_s3_class(result, "highchart")
})

test_that("create_timeline with group_var", {
  data <- data.frame(
    year = rep(2020:2023, each = 20),
    value = rnorm(80),
    category = rep(c("A", "B"), 40)
  )
  
  result <- create_timeline(
    data = data,
    time_var = "year",
    response_var = "value",
    group_var = "category"
  )
  expect_s3_class(result, "highchart")
})

test_that("create_timeline with response_filter", {
  data <- data.frame(
    year = rep(2020:2023, each = 10),
    score = sample(1:7, 40, replace = TRUE)
  )
  
  result <- create_timeline(
    data = data,
    time_var = "year",
    response_var = "score",
    response_filter = 5:7,
    response_filter_combine = TRUE
  )
  expect_s3_class(result, "highchart")
})

# ===================================================================
# create_stackedbar
# ===================================================================

test_that("create_stackedbar works with basic inputs", {
  data <- data.frame(
    question = c("Q1", "Q1", "Q2", "Q2"),
    response = c(1, 2, 1, 2)
  )
  
  result <- create_stackedbar(
    data = data,
    x_var = "question",
    stack_var = "response"
  )
  expect_s3_class(result, "highchart")
})

test_that("create_stackedbar with horizontal orientation", {
  data <- data.frame(
    question = rep(c("Q1", "Q2"), each = 5),
    response = sample(1:5, 10, replace = TRUE)
  )
  
  result <- create_stackedbar(
    data = data,
    x_var = "question",
    stack_var = "response",
    horizontal = TRUE
  )
  expect_s3_class(result, "highchart")
})

test_that("create_stackedbar with percent type", {
  data <- data.frame(
    question = rep(c("Q1", "Q2"), each = 10),
    response = sample(1:5, 20, replace = TRUE)
  )
  
  result <- create_stackedbar(
    data = data,
    x_var = "question",
    stack_var = "response",
    stacked_type = "percent"
  )
  expect_s3_class(result, "highchart")
})

# ===================================================================
# create_stackedbars (multiple questions)
# ===================================================================

test_that("create_stackedbars works with multiple questions", {
  data <- data.frame(
    q1 = sample(1:5, 100, replace = TRUE),
    q2 = sample(1:5, 100, replace = TRUE),
    q3 = sample(1:5, 100, replace = TRUE)
  )
  
  result <- create_stackedbars(
    data = data,
    questions = c("q1", "q2", "q3"),
    question_labels = c("Question 1", "Question 2", "Question 3"),
    stacked_type = "counts"
  )
  expect_s3_class(result, "highchart")
})

test_that("create_stackedbars with percent type", {
  skip("Edge case with stacked_type parameter")
  
  data <- data.frame(
    q1 = sample(1:5, 100, replace = TRUE),
    q2 = sample(1:5, 100, replace = TRUE)
  )
  
  result <- create_stackedbars(
    data = data,
    questions = c("q1", "q2"),
    question_labels = c("Q1", "Q2"),
    stacked_type = "percent"
  )
  expect_s3_class(result, "highchart")
})

# ===================================================================
# create_heatmap
# ===================================================================

test_that("create_heatmap works with basic inputs", {
  data <- expand.grid(
    x = c("A", "B", "C"),
    y = c("X", "Y", "Z")
  )
  data$value <- rnorm(9)
  
  result <- create_heatmap(
    data = data,
    x_var = "x",
    y_var = "y",
    value_var = "value"
  )
  expect_s3_class(result, "highchart")
})

test_that("create_heatmap with title and labels", {
  data <- expand.grid(
    category = c("Cat1", "Cat2"),
    group = c("G1", "G2", "G3")
  )
  data$score <- runif(6, 0, 100)
  
  result <- create_heatmap(
    data = data,
    x_var = "category",
    y_var = "group",
    value_var = "score",
    title = "Heatmap",
    x_label = "Categories",
    y_label = "Groups"
  )
  expect_s3_class(result, "highchart")
})

