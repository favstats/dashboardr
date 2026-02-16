# =================================================================
# Tests for value_box_render.R
# =================================================================

test_that("render_value_box returns htmltools tag", {
  result <- render_value_box("Users", "1,234")

  expect_true(inherits(result, "shiny.tag"))
  html <- as.character(result)

  # Should contain the value box content
  expect_true(grepl("Users", html))
  expect_true(grepl("1,234", html))
})

test_that("render_value_box uses default background color", {
  result <- render_value_box("Test", "Value")
  html <- as.character(result)

  # Default color is #2c3e50
  expect_true(grepl("#2c3e50", html))
})

test_that("render_value_box accepts custom background color", {
  result <- render_value_box("Test", "Value", bg_color = "#ff0000")
  html <- as.character(result)

  expect_true(grepl("#ff0000", html))
})

test_that("render_value_box includes logo_url when provided", {
  result <- render_value_box("Test", "Value", logo_url = "https://example.com/logo.png")
  html <- as.character(result)

  expect_true(grepl("https://example.com/logo.png", html))
  expect_true(grepl("object-fit: contain", html))
})

test_that("render_value_box includes logo_text when provided", {
  result <- render_value_box("Sales", "500K", logo_text = "$$$")
  html <- as.character(result)

  expect_true(grepl("\\$\\$\\$", html))
  expect_true(grepl("font-size: 3rem", html))
})

test_that("render_value_box uses default emoji when no logo specified", {
  result <- render_value_box("Metric", "100")
  html <- as.character(result)

  # Default uses a div with font-size: 3rem and opacity
  expect_true(grepl("font-size: 3rem", html))
  expect_true(grepl("opacity: 0.3", html))
})

test_that("render_value_box prioritizes logo_url over logo_text", {
  result <- render_value_box("Test", "Value",
                             logo_url = "test.png",
                             logo_text = "X")
  html <- as.character(result)

  # Should have img, not the text
  expect_true(grepl("<img", html))
  expect_true(grepl("test.png", html))
})

test_that("render_value_box returns tag object directly", {
  result <- render_value_box("Test", "Value")
  expect_true(inherits(result, "shiny.tag"))
})

test_that("render_value_box has correct CSS styling", {
  result <- render_value_box("Test", "Value")
  html <- as.character(result)

  # Key CSS properties
  expect_true(grepl("border-radius: 12px", html))
  expect_true(grepl("padding: 2rem", html))
  expect_true(grepl("color: white", html))
  expect_true(grepl("display: flex", html))
  expect_true(grepl("box-shadow", html))
})

test_that("render_value_box supports aria_label", {
  result <- render_value_box("Test", "Value", aria_label = "Total users metric")
  html <- as.character(result)

  expect_true(grepl('role="region"', html))
  expect_true(grepl("aria-label", html))
  expect_true(grepl("Total users metric", html))
})

# --- render_value_box_row() ---
test_that("render_value_box_row returns htmltools tag", {
  boxes <- list(
    list(title = "Users", value = "100", bg_color = "#3498db"),
    list(title = "Sales", value = "$500", bg_color = "#2ecc71")
  )

  result <- render_value_box_row(boxes)
  html <- as.character(result)

  expect_true(inherits(result, "shiny.tag"))

  # Should contain both boxes
  expect_true(grepl("Users", html))
  expect_true(grepl("100", html))
  expect_true(grepl("Sales", html))
  expect_true(grepl("\\$500", html))

  # Should have both colors
  expect_true(grepl("#3498db", html))
  expect_true(grepl("#2ecc71", html))
})

test_that("render_value_box_row creates flex container", {
  boxes <- list(
    list(title = "A", value = "1", bg_color = "#333")
  )

  result <- render_value_box_row(boxes)
  html <- as.character(result)

  # Container styles
  expect_true(grepl("display: flex", html))
  expect_true(grepl("gap: 1.5rem", html))
  expect_true(grepl("flex-wrap: wrap", html))
})

test_that("render_value_box_row handles logo_url in boxes", {
  boxes <- list(
    list(title = "Test", value = "100", bg_color = "#333",
         logo_url = "https://example.com/icon.png")
  )

  result <- render_value_box_row(boxes)
  html <- as.character(result)

  expect_true(grepl("https://example.com/icon.png", html))
})

test_that("render_value_box_row handles logo_text in boxes", {
  boxes <- list(
    list(title = "Revenue", value = "$1M", bg_color = "#27ae60",
         logo_text = "$$")
  )

  result <- render_value_box_row(boxes)
  html <- as.character(result)

  # Check for the logo text (dollar signs)
  expect_true(grepl("\\$\\$", html))
  expect_true(grepl("font-size: 3rem", html))
})

test_that("render_value_box_row uses default emoji for missing logos", {
  boxes <- list(
    list(title = "Count", value = "50", bg_color = "#9b59b6")
  )

  result <- render_value_box_row(boxes)
  html <- as.character(result)

  # Default uses a div with font-size: 3rem and opacity
  expect_true(grepl("font-size: 3rem", html))
  expect_true(grepl("opacity: 0.3", html))
})

test_that("render_value_box_row handles empty box list", {
  boxes <- list()

  result <- render_value_box_row(boxes)
  html <- as.character(result)

  # Should still produce container
  expect_true(inherits(result, "shiny.tag"))
  expect_true(grepl("display: flex", html))
})

test_that("render_value_box_row with multiple boxes has correct structure", {
  boxes <- list(
    list(title = "A", value = "1", bg_color = "#111"),
    list(title = "B", value = "2", bg_color = "#222"),
    list(title = "C", value = "3", bg_color = "#333")
  )

  result <- render_value_box_row(boxes)
  html <- as.character(result)

  # All boxes present
  expect_true(grepl("#111", html))
  expect_true(grepl("#222", html))
  expect_true(grepl("#333", html))

  # flex: 1 for responsive sizing
  expect_true(grepl("flex: 1", html))
  expect_true(grepl("min-width: 300px", html))
})
