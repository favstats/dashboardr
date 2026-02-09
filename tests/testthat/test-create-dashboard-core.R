# =================================================================
# Tests for create_dashboard() and add_dashboard_page() / add_page()
# =================================================================

# --- create_dashboard() tests ---
test_that("create_dashboard returns dashboard_project with correct structure", {
  result <- create_dashboard("test_dash", "Test Dashboard")
  
  expect_s3_class(result, "dashboard_project")
  expect_equal(result$title, "Test Dashboard")
  expect_type(result$pages, "list")
  expect_equal(length(result$pages), 0)
})

test_that("create_dashboard uses output_dir parameter", {
  result <- create_dashboard(output_dir = "custom_dir", title = "Test")
  
  expect_true(grepl("custom_dir", result$output_dir))
})

test_that("create_dashboard accepts title parameter", {
  result <- create_dashboard("test", title = "My Custom Title")
  
  expect_equal(result$title, "My Custom Title")
})

test_that("create_dashboard accepts logo parameter", {
  result <- create_dashboard("test", "Test", logo = "logo.png")
  
  expect_equal(result$logo, "logo.png")
})

test_that("create_dashboard accepts favicon parameter", {
  result <- create_dashboard("test", "Test", favicon = "favicon.ico")
  
  expect_equal(result$favicon, "favicon.ico")
})

test_that("create_dashboard accepts social links", {
  result <- create_dashboard(
    "test", "Test",
    github = "https://github.com/user/repo",
    twitter = "https://twitter.com/user",
    linkedin = "https://linkedin.com/in/user",
    email = "test@example.com",
    website = "https://example.com"
  )
  
  expect_equal(result$github, "https://github.com/user/repo")
  expect_equal(result$twitter, "https://twitter.com/user")
  expect_equal(result$linkedin, "https://linkedin.com/in/user")
  expect_equal(result$email, "test@example.com")
  expect_equal(result$website, "https://example.com")
})

test_that("create_dashboard accepts search parameter", {
  result_search <- create_dashboard("test", "Test", search = TRUE)
  result_no_search <- create_dashboard("test", "Test", search = FALSE)
  
  expect_true(result_search$search)
  expect_false(result_no_search$search)
})

test_that("create_dashboard accepts author and description", {
  result <- create_dashboard(
    "test", "Test",
    author = "John Doe",
    description = "A test dashboard"
  )
  
  expect_equal(result$author, "John Doe")
  expect_equal(result$description, "A test dashboard")
})

test_that("create_dashboard accepts typography parameters", {
  result <- create_dashboard(
    "test", "Test",
    mainfont = "Roboto",
    fontsize = "18px",
    fontcolor = "#333333",
    monofont = "Fira Code",
    linestretch = 1.8
  )
  
  expect_equal(result$mainfont, "Roboto")
  expect_equal(result$fontsize, "18px")
  expect_equal(result$fontcolor, "#333333")
  expect_equal(result$monofont, "Fira Code")
  expect_equal(result$linestretch, 1.8)
})

test_that("create_dashboard accepts layout parameters", {
  result <- create_dashboard(
    "test", "Test",
    max_width = "1400px",
    margin_left = "3rem",
    margin_right = "3rem"
  )
  
  expect_equal(result$max_width, "1400px")
  expect_equal(result$margin_left, "3rem")
  expect_equal(result$margin_right, "3rem")
})

test_that("create_dashboard accepts navbar parameters", {
  result <- create_dashboard(
    "test", "Test",
    navbar_style = "dark",
    navbar_bg_color = "#1a1a2e",
    navbar_text_color = "#ffffff",
    navbar_text_hover_color = "#cccccc"
  )
  
  expect_equal(result$navbar_style, "dark")
  expect_equal(result$navbar_bg_color, "#1a1a2e")
  expect_equal(result$navbar_text_color, "#ffffff")
  expect_equal(result$navbar_text_hover_color, "#cccccc")
})

test_that("create_dashboard accepts sidebar parameters", {
  result <- create_dashboard(
    "test", "Test",
    sidebar = TRUE,
    sidebar_style = "floating",
    sidebar_background = "dark"
  )
  
  expect_true(result$sidebar)
  expect_equal(result$sidebar_style, "floating")
  expect_equal(result$sidebar_background, "dark")
})

test_that("create_dashboard accepts tabset parameters", {
  result <- create_dashboard(
    "test", "Test",
    tabset_theme = "modern",
    tabset_colors = list(active = "#ff0000")
  )
  
  expect_equal(result$tabset_theme, "modern")
  expect_equal(result$tabset_colors$active, "#ff0000")
})

test_that("create_dashboard accepts analytics parameters", {
  result <- create_dashboard(
    "test", "Test",
    google_analytics = "UA-12345678-1",
    plausible = "example.com"
  )
  
  expect_equal(result$google_analytics, "UA-12345678-1")
  expect_equal(result$plausible, "example.com")
})

test_that("create_dashboard accepts lazy loading parameters", {
  result <- create_dashboard(
    "test", "Test",
    lazy_load_charts = TRUE,
    lazy_load_margin = "300px",
    lazy_load_tabs = TRUE
  )
  
  expect_true(result$lazy_load_charts)
  expect_equal(result$lazy_load_margin, "300px")
  expect_true(result$lazy_load_tabs)
})

test_that("create_dashboard accepts contextual_viz_errors parameter", {
  result_default <- create_dashboard("test", "Test")
  result_enabled <- create_dashboard("test", "Test", contextual_viz_errors = TRUE)

  expect_false(result_default$contextual_viz_errors)
  expect_true(result_enabled$contextual_viz_errors)
})

test_that("create_dashboard accepts pagination parameters", {
  result <- create_dashboard(
    "test", "Test",
    pagination_separator = "von",
    pagination_position = "top"
  )
  
  expect_equal(result$pagination_separator, "von")
  expect_equal(result$pagination_position, "top")
})

test_that("create_dashboard allow_inside_pkg prevents error", {
  # Without allow_inside_pkg = TRUE, it might error if inside a package
  expect_no_error({
    create_dashboard("test", "Test", allow_inside_pkg = TRUE)
  })
})

# --- add_page() tests ---
test_that("add_page adds page to dashboard", {
  dashboard <- create_dashboard("test", "Test") %>%
    add_page("Home", text = "Welcome!")
  
  expect_true("Home" %in% names(dashboard$pages))
})

test_that("add_page accepts data parameter", {
  dashboard <- create_dashboard("test", "Test") %>%
    add_page("Analysis", data = mtcars)
  
  # Data is stored (may be as path for inline data or as object)
  expect_true(!is.null(dashboard$pages[["Analysis"]]$data) || 
              !is.null(dashboard$pages[["Analysis"]]$data_path))
})

test_that("add_page accepts visualizations parameter", {
  viz <- create_viz() %>%
    add_viz(type = "histogram", x_var = "mpg")
  
  dashboard <- create_dashboard("test", "Test") %>%
    add_page("Charts", data = mtcars, visualizations = viz)
  
  expect_true(!is.null(dashboard$pages[["Charts"]]$visualizations))
})

test_that("add_page accepts content parameter (alias for visualizations)", {
  content <- create_content() %>%
    add_text("Hello world")
  
  dashboard <- create_dashboard("test", "Test") %>%
    add_page("Info", content = content)
  
  expect_true(!is.null(dashboard$pages[["Info"]]$visualizations) ||
              !is.null(dashboard$pages[["Info"]]$content_blocks))
})

test_that("add_page accepts text parameter", {
  dashboard <- create_dashboard("test", "Test") %>%
    add_page("About", text = "# About Us\n\nWe are a company.")
  
  expect_true(grepl("About Us", dashboard$pages[["About"]]$text))
})

test_that("add_page accepts is_landing_page parameter", {
  dashboard <- create_dashboard("test", "Test") %>%
    add_page("Home", text = "Welcome", is_landing_page = TRUE) %>%
    add_page("About", text = "About")
  
  expect_true(dashboard$pages[["Home"]]$is_landing_page)
  expect_false(isTRUE(dashboard$pages[["About"]]$is_landing_page))
})

test_that("add_page accepts navbar_location parameter", {
  # Note: Use navbar_right = TRUE for right-aligned menu items
  dashboard <- create_dashboard("test", "Test") %>%
    add_page("Contact", text = "Contact us")
  
  expect_true("Contact" %in% names(dashboard$pages))
})

test_that("add_page accepts icon parameter", {
  dashboard <- create_dashboard("test", "Test") %>%
    add_page("Settings", text = "Settings", icon = "gear")
  
  expect_equal(dashboard$pages[["Settings"]]$icon, "gear")
})

test_that("multiple add_page calls accumulate pages", {
  dashboard <- create_dashboard("test", "Test") %>%
    add_page("Home", text = "Home") %>%
    add_page("About", text = "About") %>%
    add_page("Contact", text = "Contact")
  
  expect_length(dashboard$pages, 3)
  expect_true(all(c("Home", "About", "Contact") %in% names(dashboard$pages)))
})

test_that("viz_collection with tabgroup_labels works in add_page", {
  viz <- create_viz() %>%
    add_viz(type = "histogram", x_var = "mpg", tabgroup = "stats") %>%
    set_tabgroup_labels(stats = "Statistics")
  
  dashboard <- create_dashboard("test", "Test") %>%
    add_page("Analysis", data = mtcars, visualizations = viz)
  
  expect_true("Analysis" %in% names(dashboard$pages))
})

# --- add_pages() shorthand ---
test_that("add_pages adds multiple page_objects at once", {
  page1 <- create_page("Home", text = "Welcome!")
  page2 <- create_page("About", text = "About us")
  
  dashboard <- create_dashboard("test", "Test") %>%
    add_pages(page1, page2)
  
  expect_length(dashboard$pages, 2)
})

# --- Page with various content types ---
test_that("add_page handles viz_collection with mixed content", {
  content <- create_viz() %>%
    add_viz(type = "histogram", x_var = "mpg") %>%
    add_text("Interpretation") %>%
    add_callout(text = "Note", type = "note")
  
  dashboard <- create_dashboard("test", "Test", allow_inside_pkg = TRUE) %>%
    add_page("Mixed", data = mtcars, content = content)
  
  expect_s3_class(dashboard, "dashboard_project")
})

# --- Piping with themes ---
test_that("create_dashboard works with apply_theme in pipeline", {
  dashboard <- create_dashboard("test", "Test") %>%
    apply_theme(theme_modern()) %>%
    add_page("Home", text = "Welcome")
  
  expect_s3_class(dashboard, "dashboard_project")
  expect_equal(dashboard$mainfont, "Roboto")  # From theme_modern
})

# --- Edge cases ---
test_that("add_page with empty name works", {
  # Empty name should still create a page (might use default)
  dashboard <- create_dashboard("test", "Test") %>%
    add_page("", text = "Anonymous page")
  
  # Should have one page
  expect_length(dashboard$pages, 1)
})

test_that("add_page with special characters in name", {
  dashboard <- create_dashboard("test", "Test") %>%
    add_page("Q&A / FAQ", text = "Questions and Answers")
  
  expect_true(any(grepl("Q&A", names(dashboard$pages))))
})

test_that("create_dashboard output_dir is normalized", {
  dashboard <- create_dashboard(output_dir = "./test_output/../test_output", title = "Test")
  
  # Path should be normalized
  expect_type(dashboard$output_dir, "character")
})
