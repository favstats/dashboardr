test_that("add_powered_by_dashboardr works with no existing footer", {
  dashboard <- create_dashboard("test_dash", "Test") %>%
    add_powered_by_dashboardr()
  
  expect_true(is.list(dashboard$page_footer))
  expect_equal(dashboard$page_footer$structure, "structured")
  expect_true(grepl("dashboardr", dashboard$page_footer$right))
  expect_true(grepl("https://favstats.github.io/dashboardr/", dashboard$page_footer$right))
})

test_that("add_powered_by_dashboardr works with existing simple footer", {
  dashboard <- create_dashboard(
    "test_dash", 
    "Test",
    page_footer = "© 2025 Test"
  ) %>%
    add_powered_by_dashboardr()
  
  expect_true(is.list(dashboard$page_footer))
  expect_equal(dashboard$page_footer$structure, "structured")
  expect_equal(dashboard$page_footer$left, "© 2025 Test")
  expect_true(grepl("dashboardr", dashboard$page_footer$right))
})

test_that("add_powered_by_dashboardr respects occupied right section", {
  # Create structured footer with occupied right
  dashboard <- create_dashboard("test_dash", "Test")
  dashboard$page_footer <- list(
    structure = "structured",
    left = "Left text",
    right = "Already occupied"
  )
  
  # Try to add branding
  expect_message(
    dashboard <- add_powered_by_dashboardr(dashboard),
    "Footer right section already occupied"
  )
  
  # Right section should remain unchanged
  expect_equal(dashboard$page_footer$right, "Already occupied")
})

test_that("add_powered_by_dashboardr validates size parameter", {
  dashboard <- create_dashboard("test_dash", "Test")
  
  expect_error(
    add_powered_by_dashboardr(dashboard, size = "invalid"),
    "'arg' should be one of"
  )
})

test_that("add_powered_by_dashboardr validates style parameter", {
  dashboard <- create_dashboard("test_dash", "Test")
  
  expect_error(
    add_powered_by_dashboardr(dashboard, style = "invalid"),
    "'arg' should be one of"
  )
})

test_that("add_powered_by_dashboardr generates different HTML for different styles", {
  dashboard1 <- create_dashboard("test", "Test") %>%
    add_powered_by_dashboardr(style = "default")
  
  dashboard2 <- create_dashboard("test", "Test") %>%
    add_powered_by_dashboardr(style = "minimal")
  
  dashboard3 <- create_dashboard("test", "Test") %>%
    add_powered_by_dashboardr(style = "badge")
  
  # All should have branding
  expect_true(grepl("dashboardr", dashboard1$page_footer$right))
  expect_true(grepl("dashboardr", dashboard2$page_footer$right))
  expect_true(grepl("dashboardr", dashboard3$page_footer$right))
  
  # But content should differ
  expect_true(grepl("Powered by", dashboard1$page_footer$right))
  expect_true(grepl("Built with", dashboard2$page_footer$right))
  expect_true(grepl("padding", dashboard3$page_footer$right)) # badge has padding
})

test_that("add_powered_by_dashboardr generates different sizes", {
  dashboard_small <- create_dashboard("test", "Test") %>%
    add_powered_by_dashboardr(size = "small")
  
  dashboard_medium <- create_dashboard("test", "Test") %>%
    add_powered_by_dashboardr(size = "medium")
  
  dashboard_large <- create_dashboard("test", "Test") %>%
    add_powered_by_dashboardr(size = "large")
  
  # Check font sizes are different
  expect_true(grepl("0.75rem", dashboard_small$page_footer$right))
  expect_true(grepl("0.875rem", dashboard_medium$page_footer$right))
  expect_true(grepl("1rem", dashboard_large$page_footer$right))
})

test_that("add_powered_by_dashboardr only accepts dashboard objects", {
  expect_error(
    add_powered_by_dashboardr("not a dashboard"),
    "must be a dashboard project"
  )
  
  expect_error(
    add_powered_by_dashboardr(list()),
    "must be a dashboard project"
  )
})

