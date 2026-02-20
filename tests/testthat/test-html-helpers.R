# =================================================================
# Tests for html_helpers.R
# =================================================================

# --- html_spacer ---
test_that("html_spacer returns htmltools tag with correct height", {
  result <- html_spacer("2rem")
  expect_true(inherits(result, "shiny.tag"))
  html <- as.character(result)
  expect_true(grepl("height: 2rem", html))
})

test_that("html_spacer uses default height", {
  result <- html_spacer()
  html <- as.character(result)
  expect_true(grepl("height: 1rem", html))
})

# --- html_divider ---
test_that("html_divider returns hr tag for each style", {
  for (style in c("thick", "dashed", "dotted")) {
    result <- html_divider(style)
    expect_true(inherits(result, "shiny.tag"))
    html <- as.character(result)
    expect_true(grepl("<hr", html), info = paste("style:", style))
  }
})

test_that("html_divider thick style has correct CSS", {
  html <- as.character(html_divider("thick"))
  expect_true(grepl("border: 3px solid #333", html))
})

test_that("html_divider dashed style has correct CSS", {
  html <- as.character(html_divider("dashed"))
  expect_true(grepl("border-top: 2px dashed #ccc", html))
})

# --- html_card ---
test_that("html_card returns card with body", {
  result <- html_card("Some content")
  expect_true(inherits(result, "shiny.tag"))
  html <- as.character(result)
  expect_true(grepl("card", html))
  expect_true(grepl("card-body", html))
  expect_true(grepl("Some content", html))
})

test_that("html_card includes header when title provided", {
  result <- html_card("Body text", title = "My Card")
  html <- as.character(result)
  expect_true(grepl("card-header", html))
  expect_true(grepl("My Card", html))
})

test_that("html_card omits header when title is NULL", {
  result <- html_card("Body text")
  html <- as.character(result)
  expect_false(grepl("card-header", html))
})

# --- html_accordion ---
test_that("html_accordion returns details/summary", {
  result <- html_accordion("Hidden content", title = "Click me")
  expect_true(inherits(result, "shiny.tag"))
  html <- as.character(result)
  expect_true(grepl("<details>", html))
  expect_true(grepl("<summary>", html))
  expect_true(grepl("Click me", html))
  expect_true(grepl("Hidden content", html))
})

test_that("html_accordion uses default title", {
  result <- html_accordion("Content")
  html <- as.character(result)
  expect_true(grepl("Details", html))
})

# --- html_iframe ---
test_that("html_iframe returns iframe tag", {
  result <- html_iframe("https://example.com")
  expect_true(inherits(result, "shiny.tag"))
  html <- as.character(result)
  expect_true(grepl("<iframe", html))
  expect_true(grepl("https://example.com", html))
})

test_that("html_iframe applies custom dimensions", {
  result <- html_iframe("https://example.com", height = "800px", width = "50%")
  html <- as.character(result)
  expect_true(grepl("height: 800px", html))
  expect_true(grepl("width: 50%", html))
})

test_that("html_iframe applies extra style", {
  result <- html_iframe("https://example.com", style = "border: 1px solid red;")
  html <- as.character(result)
  expect_true(grepl("border: 1px solid red", html))
})

# --- html_badge ---
test_that("html_badge returns span with badge class", {
  result <- html_badge("Active", "success")
  expect_true(inherits(result, "shiny.tag"))
  html <- as.character(result)
  expect_true(grepl("badge", html))
  expect_true(grepl("badge-success", html))
  expect_true(grepl("Active", html))
})

test_that("html_badge defaults to primary", {
  result <- html_badge("Test")
  html <- as.character(result)
  expect_true(grepl("badge-primary", html))
})

# --- html_metric ---
test_that("html_metric returns metric div with value and title", {
  result <- html_metric(value = "42", title = "Users")
  expect_true(inherits(result, "shiny.tag"))
  html <- as.character(result)
  expect_true(grepl("metric", html))
  expect_true(grepl("42", html))
  expect_true(grepl("Users", html))
})

test_that("html_metric applies accent color as gradient", {
  result <- html_metric(value = "100", title = "Score", color = "#ff0000")
  html <- as.character(result)
  # Color is now used in a gradient background
  expect_true(grepl("#ff0000", html))
})

test_that("html_metric includes icon as web component", {
  result <- html_metric(value = "5", title = "Stars", icon = "mdi:star")
  html <- as.character(result)
  expect_true(grepl("iconify-icon", html))
  expect_true(grepl("mdi:star", html))
})

test_that("html_metric includes subtitle", {
  result <- html_metric(value = "99%", title = "Uptime", subtitle = "Last 30 days")
  html <- as.character(result)
  expect_true(grepl("Last 30 days", html))
})

test_that("html_metric supports aria_label", {
  result <- html_metric(value = "42", title = "Users", aria_label = "Total users count")
  html <- as.character(result)
  expect_true(grepl("aria-label", html))
  expect_true(grepl("Total users count", html))
})

test_that("html_metric applies bg_color", {
  result <- html_metric(value = "10", title = "Count", bg_color = "#3498db")
  html <- as.character(result)
  # bg_color overrides the default gradient
  expect_true(grepl("#3498db", html))
})

test_that("html_metric applies text_color", {
  result <- html_metric(value = "10", title = "Count", icon = "ph:star", text_color = "#ffffff")
  html <- as.character(result)
  expect_true(grepl("#ffffff", html))
  # Icon wrapper should NOT have the text-primary class when text_color is set
  expect_false(grepl("text-primary", html))
})

test_that("html_metric renders value_prefix and value_suffix", {
  result <- html_metric(value = "3.22", title = "Disp", value_prefix = "~", value_suffix = "L")
  html <- as.character(result)
  expect_true(grepl("~3.22L", html, fixed = TRUE))
})

test_that("html_metric applies border_radius", {
  result <- html_metric(value = "7", title = "Items", border_radius = "12px")
  html <- as.character(result)
  expect_true(grepl("border-radius: 12px;", html, fixed = TRUE))
})

test_that("html_metric combines color and bg_color", {
  result <- html_metric(value = "5", title = "Score", color = "#ff0000", bg_color = "#eef")
  html <- as.character(result)
  # bg_color takes precedence as the background
  expect_true(grepl("#eef", html))
})
