# =================================================================
# Tests for loading_overlay.R
# =================================================================

test_that("create_loading_overlay returns htmltools tag", {
  result <- create_loading_overlay()
  
  expect_s3_class(result, "shiny.tag")
})

test_that("create_loading_overlay uses default parameters", {
  result <- create_loading_overlay()
  html <- as.character(result)
  
  # Check default text
  expect_true(grepl("Loading", html))
  
  # Check structure exists

  expect_true(grepl("page-loading-overlay", html))
  expect_true(grepl("plo-card", html))
  expect_true(grepl("plo-spinner", html))
})

test_that("create_loading_overlay accepts custom text", {
  result <- create_loading_overlay(text = "Please wait...")
  html <- as.character(result)
  
  expect_true(grepl("Please wait...", html))
})

test_that("create_loading_overlay accepts custom timeout", {
  result <- create_loading_overlay(timeout_ms = 5000)
  html <- as.character(result)
  
  # Check timeout value is in the JavaScript
  expect_true(grepl("5000", html))
})

test_that("create_loading_overlay supports light theme", {
  result <- create_loading_overlay(theme = "light")
  html <- as.character(result)
  
  # Light theme uses white background
  expect_true(grepl("rgba\\(255,255,255,0\\.98\\)", html))
})

test_that("create_loading_overlay supports glass theme", {
  result <- create_loading_overlay(theme = "glass")
  html <- as.character(result)
  
  # Glass theme has lower opacity background
  expect_true(grepl("rgba\\(255,255,255,0\\.45\\)", html) || 
              grepl("backdrop-filter.*blur\\(16px\\)", html))
})

test_that("create_loading_overlay supports dark theme", {
  result <- create_loading_overlay(theme = "dark")
  html <- as.character(result)
  
  # Dark theme uses dark gradients
  expect_true(grepl("radial-gradient", html))
  expect_true(grepl("#0f172a", html))
})

test_that("create_loading_overlay supports accent theme", {
  result <- create_loading_overlay(theme = "accent")
  html <- as.character(result)
  
  # Accent theme uses blue accents
  expect_true(grepl("59,130,246", html))  # Blue RGB values
})

test_that("create_loading_overlay includes necessary CSS classes", {
  result <- create_loading_overlay(theme = "light")
  html <- as.character(result)
  
  # Essential CSS selectors
  expect_true(grepl("#page-loading-overlay", html))
  expect_true(grepl("\\.plo-card", html))
  expect_true(grepl("\\.plo-spinner", html))
  expect_true(grepl("\\.plo-title", html))
})

test_that("create_loading_overlay includes JavaScript for auto-hide", {
  result <- create_loading_overlay(timeout_ms = 3000)
  html <- as.character(result)
  
  # JavaScript event listener
  expect_true(grepl("window\\.addEventListener", html))
  expect_true(grepl("setTimeout", html))
  expect_true(grepl("hide", html))
})

test_that("create_loading_overlay includes spinner animation", {
  result <- create_loading_overlay()
  html <- as.character(result)
  
  # Animation keyframes
  expect_true(grepl("@keyframes plo-spin", html))
  expect_true(grepl("animation:.*plo-spin", html))
})

test_that("create_loading_overlay theme argument validates input", {
  # Valid themes should work
  expect_no_error(create_loading_overlay(theme = "light"))
  expect_no_error(create_loading_overlay(theme = "glass"))
  expect_no_error(create_loading_overlay(theme = "dark"))
  expect_no_error(create_loading_overlay(theme = "accent"))
  
  # Invalid theme should error (match.arg)
  expect_error(create_loading_overlay(theme = "invalid"))
})

test_that("create_loading_overlay output structure is correct", {
  result <- create_loading_overlay()
  
  # Should be a div containing style, div, and script
  expect_equal(result$name, "div")
  expect_true(length(result$children) >= 3)
  
  # Check child types
  child_names <- sapply(result$children, function(x) x$name)
  expect_true("style" %in% child_names)
  expect_true("div" %in% child_names)
  expect_true("script" %in% child_names)
})

test_that("create_loading_overlay works with different parameter combinations", {
  # Custom everything
  result <- create_loading_overlay(
    text = "Dashboard Loading",
    timeout_ms = 1500,
    theme = "glass"
  )
  
  html <- as.character(result)
  
  expect_true(grepl("Dashboard Loading", html))
  expect_true(grepl("1500", html))
  expect_true(grepl("blur\\(16px\\)", html))
})
