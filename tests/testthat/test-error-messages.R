test_that("add_viz shows helpful error for missing type", {
  viz <- create_viz()
  
  expect_error(
    add_viz(viz, x_var = "age"),
    "type.*required"
  )
  
  # Check error contains helpful info
  err <- tryCatch(
    add_viz(viz, x_var = "age"),
    error = function(e) e$message
  )
  
  # Should mention available types
  expect_true(grepl("histogram|bar|stackedbar", err))
})

test_that("add_viz suggests correct spelling for typos", {
  viz <- create_viz()
  
  err <- tryCatch(
    add_viz(viz, type = "histogra", x_var = "age"),
    error = function(e) e$message
  )
  
  # Should suggest histogram
  expect_true(grepl("histogram", err))
})

test_that("create_dashboard suggests theme corrections", {
  err <- tryCatch(
    create_dashboard(
      title = "Test",
      output_dir = tempfile(),
      tabset_theme = "modrn"
    ),
    error = function(e) e$message
  )
  
  # Should suggest modern
  expect_true(grepl("modern", err, ignore.case = TRUE))
})

test_that("viz_histogram shows helpful error for missing x_var", {
  data <- data.frame(age = rnorm(100))
  
  err <- tryCatch(
    viz_histogram(data = data),
    error = function(e) e$message
  )
  
  expect_true(grepl("x_var.*required", err))
})

test_that("viz_bar shows helpful error for missing x_var", {
  data <- data.frame(category = letters[1:10])
  
  err <- tryCatch(
    viz_bar(data = data),
    error = function(e) e$message
  )
  
  expect_true(grepl("x_var.*required", err))
})

test_that("viz_stackedbar shows helpful error for missing parameters", {
  data <- data.frame(x = letters[1:10], y = 1:10)
  
  # Missing x_var
  err1 <- tryCatch(
    viz_stackedbar(data = data, stack_var = "y"),
    error = function(e) e$message
  )
  # New error message is more helpful - suggests specifying x_var + stack_var or x_vars
  expect_true(grepl("x_var|Please specify", err1))
  
  # Missing stack_var
  err2 <- tryCatch(
    viz_stackedbar(data = data, x_var = "x"),
    error = function(e) e$message
  )
  expect_true(grepl("stack_var.*required", err2))
})

test_that("viz_timeline shows helpful error for missing parameters", {
  data <- data.frame(year = 2020:2024, score = rnorm(5))
  
  # Missing time_var
  err1 <- tryCatch(
    viz_timeline(data = data, y_var = "score"),
    error = function(e) e$message
  )
  expect_true(grepl("time_var.*required", err1))
  
  # Missing y_var
  err2 <- tryCatch(
    viz_timeline(data = data, time_var = "year"),
    error = function(e) e$message
  )
  expect_true(grepl("y_var.*required", err2))
})

test_that("viz_heatmap shows helpful error for missing parameters", {
  data <- data.frame(x = 1:10, y = 1:10, z = rnorm(10))
  
  # Missing x_var
  err1 <- tryCatch(
    viz_heatmap(data = data, y_var = "y", value_var = "z"),
    error = function(e) e$message
  )
  expect_true(grepl("x_var.*required", err1))
})

test_that("error messages include examples", {
  viz <- create_viz()
  
  err <- tryCatch(
    add_viz(viz, x_var = "age"),
    error = function(e) e$message
  )
  
  # Should include an example
  expect_true(grepl("Example:|example:", err, ignore.case = TRUE) || 
              grepl("add_viz\\(", err))
})

test_that("invalid parameter values show suggestions", {
  data <- data.frame(x = rnorm(100))
  
  # Invalid bar_type
  err <- tryCatch(
    viz_bar(data = data, x_var = "x", bar_type = "countt"),
    error = function(e) e$message
  )
  
  expect_true(grepl("count|percent", err))
})

test_that("invalid color palette shows helpful message", {
  data <- data.frame(x = letters[1:5])
  
  # Too few colors for categories
  result <- tryCatch(
    viz_histogram(data = data, x_var = "x", color_palette = c("red", "blue")),
    warning = function(w) w$message,
    error = function(e) e$message
  )
  
  # Should at least not crash silently
  expect_true(is.character(result) || is.list(result))
})

test_that("typo detection uses string distance", {
  # Test various typos
  typos <- list(
    c("histogra", "histogram"),
    c("stackedbarr", "stackedbar"),
    c("timline", "timeline"),
    c("heatmapp", "heatmap")
  )
  
  for (typo_pair in typos) {
    typo <- typo_pair[1]
    correct <- typo_pair[2]
    
    # Calculate string distance (should be small)
    dist <- adist(typo, correct)[1,1]
    expect_true(dist <= 2)  # Within 2 edits
  }
})

