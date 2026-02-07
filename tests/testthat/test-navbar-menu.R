# Tests for navbar_menu() function
library(testthat)

# Skip entire file under covr CI to prevent OOM (exit code 143)
if (identical(Sys.getenv("DASHBOARDR_COVR_CI"), "true")) {
  test_that("skipped under covr CI", { skip("Memory-intensive tests skipped under covr CI") })
} else {

test_that("navbar_menu creates correct structure", {
  menu <- navbar_menu(
    text = "Analysis",
    pages = c("Page 1", "Page 2")
  )
  
  expect_type(menu, "list")
  expect_equal(menu$text, "Analysis")
  expect_equal(menu$menu_pages, c("Page 1", "Page 2"))
  expect_null(menu$icon)
})

test_that("navbar_menu accepts icon parameter", {
  menu <- navbar_menu(
    text = "Dimensions",
    pages = c("Strategic", "Critical"),
    icon = "ph:book"
  )
  
  expect_equal(menu$icon, "ph:book")
})

test_that("navbar_menu validates text parameter", {
  expect_error(
    navbar_menu(text = NULL, pages = c("A", "B")),
    "text must be a non-empty character string"
  )
  
  expect_error(
    navbar_menu(text = "", pages = c("A", "B")),
    "text must be a non-empty character string"
  )
  
  expect_error(
    navbar_menu(text = c("A", "B"), pages = c("A", "B")),
    "text must be a non-empty character string"
  )
  
  expect_error(
    navbar_menu(text = 123, pages = c("A", "B")),
    "text must be a non-empty character string"
  )
})

test_that("navbar_menu validates pages parameter", {
  expect_error(
    navbar_menu(text = "Menu", pages = NULL),
    "pages must be a non-empty character vector"
  )
  
  expect_error(
    navbar_menu(text = "Menu", pages = character(0)),
    "pages must be a non-empty character vector"
  )
  
  expect_error(
    navbar_menu(text = "Menu", pages = 123),
    "pages must be a non-empty character vector"
  )
})

test_that("navbar_menu works with single page", {
  menu <- navbar_menu(
    text = "Single",
    pages = "One Page"
  )
  
  expect_equal(menu$menu_pages, "One Page")
  expect_length(menu$menu_pages, 1)
})

test_that("navbar_menu works with many pages", {
  many_pages <- paste("Page", 1:10)
  menu <- navbar_menu(
    text = "Many",
    pages = many_pages
  )
  
  expect_equal(menu$menu_pages, many_pages)
  expect_length(menu$menu_pages, 10)
})

test_that("navbar_menu YAML generation works", {
  # Create a simple dashboard with navbar_menu
  menu <- navbar_menu(
    text = "Analysis",
    pages = c("Skills", "Performance"),
    icon = "ph:chart-line"
  )
  
  dashboard <- create_dashboard(
    output_dir = tempfile("navbar_menu_test"),
    title = "Test Dashboard",
    navbar_sections = list(menu)
  ) %>%
    add_page("Home", text = "Home page", is_landing_page = TRUE) %>%
    add_page("Skills", text = "Skills page", icon = "ph:graduation-cap") %>%
    add_page("Performance", text = "Performance page", icon = "ph:trophy")
  
  # Generate without rendering
  generate_dashboard(dashboard, render = FALSE)
  
  # Read the YAML
  yaml_file <- file.path(dashboard$output_dir, "_quarto.yml")
  yaml_content <- readLines(yaml_file, warn = FALSE)
  yaml_text <- paste(yaml_content, collapse = "\n")
  
  # Check that menu structure is present
  expect_true(grepl("menu:", yaml_text, fixed = TRUE))
  expect_true(grepl("Analysis", yaml_text, fixed = TRUE))
  expect_true(grepl("Skills", yaml_text, fixed = TRUE))
  expect_true(grepl("Performance", yaml_text, fixed = TRUE))
  
  # Check for icon (in iconify shortcode format)
  expect_true(grepl("iconify ph chart-line", yaml_text, fixed = TRUE))
  
  # Clean up
})

test_that("navbar_menu generates correct YAML indentation", {
  menu <- navbar_menu(
    text = "Dimensions",
    pages = c("Strategic Information", "Critical Information")
  )
  
  dashboard <- create_dashboard(
    output_dir = tempfile("navbar_menu_indent"),
    title = "Test Dashboard",
    navbar_sections = list(menu)
  ) %>%
    add_page("Home", text = "Home", is_landing_page = TRUE) %>%
    add_page("Strategic Information", text = "Strategic") %>%
    add_page("Critical Information", text = "Critical")
  
  generate_dashboard(dashboard, render = FALSE)
  
  yaml_file <- file.path(dashboard$output_dir, "_quarto.yml")
  yaml_content <- readLines(yaml_file, warn = FALSE)
  
  # Find the menu section
  menu_idx <- which(grepl("menu:", yaml_content, fixed = TRUE))
  expect_true(length(menu_idx) > 0)
  
  # Check that menu items are properly indented (10 spaces for nested items)
  menu_items <- yaml_content[(menu_idx + 1):length(yaml_content)]
  first_item_idx <- which(grepl("- href:", menu_items, fixed = TRUE))[1]
  
  if (!is.na(first_item_idx)) {
    first_item <- menu_items[first_item_idx]
    # Should have 10 spaces of indentation
    expect_true(grepl("^          - href:", first_item))
  }
  
})

test_that("navbar_menu works with multiple menus", {
  menu1 <- navbar_menu(
    text = "Analysis",
    pages = c("Skills", "Performance")
  )
  
  menu2 <- navbar_menu(
    text = "Reference",
    pages = c("About", "Help")
  )
  
  dashboard <- create_dashboard(
    output_dir = tempfile("multi_menu"),
    title = "Test Dashboard",
    navbar_sections = list(menu1, menu2)
  ) %>%
    add_page("Home", text = "Home", is_landing_page = TRUE) %>%
    add_page("Skills", text = "Skills") %>%
    add_page("Performance", text = "Performance") %>%
    add_page("About", text = "About") %>%
    add_page("Help", text = "Help")
  
  generate_dashboard(dashboard, render = FALSE)
  
  yaml_file <- file.path(dashboard$output_dir, "_quarto.yml")
  yaml_content <- readLines(yaml_file, warn = FALSE)
  yaml_text <- paste(yaml_content, collapse = "\n")
  
  # Both menus should be present
  expect_true(grepl("Analysis", yaml_text))
  expect_true(grepl("Reference", yaml_text))
  expect_true(grepl("Skills", yaml_text))
  expect_true(grepl("Help", yaml_text))
  
  # Should have 2 menu: entries
  menu_count <- length(grep("menu:", yaml_content, fixed = TRUE))
  expect_equal(menu_count, 2)
  
})

test_that("navbar_menu preserves page icons in dropdown", {
  menu <- navbar_menu(
    text = "Pages",
    pages = c("Page A", "Page B")
  )
  
  dashboard <- create_dashboard(
    output_dir = tempfile("menu_icons"),
    title = "Test",
    navbar_sections = list(menu)
  ) %>%
    add_page("Home", text = "Home", is_landing_page = TRUE) %>%
    add_page("Page A", text = "A", icon = "ph:star") %>%
    add_page("Page B", text = "B", icon = "ph:heart")
  
  generate_dashboard(dashboard, render = FALSE)
  
  yaml_file <- file.path(dashboard$output_dir, "_quarto.yml")
  yaml_content <- readLines(yaml_file, warn = FALSE)
  yaml_text <- paste(yaml_content, collapse = "\n")
  
  # Page icons should be present in menu items (in iconify shortcode format)
  expect_true(grepl("iconify ph star", yaml_text))
  expect_true(grepl("iconify ph heart", yaml_text))
  
})

test_that("navbar_menu works alongside regular pages", {
  menu <- navbar_menu(
    text = "Grouped",
    pages = c("Page 1", "Page 2")
  )
  
  dashboard <- create_dashboard(
    output_dir = tempfile("mixed_nav"),
    title = "Test",
    navbar_sections = list(menu)
  ) %>%
    add_page("Home", text = "Home", is_landing_page = TRUE) %>%
    add_page("Page 1", text = "In menu") %>%
    add_page("Page 2", text = "In menu") %>%
    add_page("Standalone", text = "Not in menu") %>%
    add_page("About", text = "Also standalone", navbar_align = "right")
  
  generate_dashboard(dashboard, render = FALSE)
  
  yaml_file <- file.path(dashboard$output_dir, "_quarto.yml")
  yaml_content <- readLines(yaml_file, warn = FALSE)
  yaml_text <- paste(yaml_content, collapse = "\n")
  
  # Menu should be present
  expect_true(grepl("menu:", yaml_text))
  expect_true(grepl("Grouped", yaml_text))
  
  # Standalone pages should also be present
  expect_true(grepl("Standalone", yaml_text))
  
  # Check left and right sections exist
  expect_true(grepl("left:", yaml_text))
  expect_true(grepl("right:", yaml_text))
  
})

test_that("navbar_menu handles missing pages gracefully", {
  menu <- navbar_menu(
    text = "Menu",
    pages = c("Exists", "DoesNotExist", "AlsoExists")
  )
  
  dashboard <- create_dashboard(
    output_dir = tempfile("missing_page"),
    title = "Test",
    navbar_sections = list(menu)
  ) %>%
    add_page("Home", text = "Home", is_landing_page = TRUE) %>%
    add_page("Exists", text = "This exists") %>%
    add_page("AlsoExists", text = "This also exists")
    # Note: "DoesNotExist" is NOT added
  
  # Should not error (may produce warnings about missing pages or Quarto)
  expect_no_error(generate_dashboard(dashboard, render = FALSE))
  
  yaml_file <- file.path(dashboard$output_dir, "_quarto.yml")
  yaml_content <- readLines(yaml_file, warn = FALSE)
  yaml_text <- paste(yaml_content, collapse = "\n")
  
  # Existing pages should be in menu
  expect_true(grepl("Exists", yaml_text))
  expect_true(grepl("AlsoExists", yaml_text))
  
  # Missing page should not cause issues (just skipped)
  # DoesNotExist might not appear, or might appear without href
  
})

test_that("navbar_menu can be mixed with navbar_section (hybrid)", {
  # This tests that both dropdown menus and sidebar references can coexist
  
  menu <- navbar_menu(
    text = "Simple Menu",
    pages = c("Page A")
  )
  
  sidebar_grp <- sidebar_group(
    id = "analysis",
    title = "Analysis",
    pages = c("Page B")
  )
  
  section <- navbar_section(
    text = "Hybrid Nav",
    sidebar_id = "analysis"
  )
  
  dashboard <- create_dashboard(
    output_dir = tempfile("mixed_nav_types"),
    title = "Test",
    navbar_sections = list(menu, section),
    sidebar_groups = list(sidebar_grp)
  ) %>%
    add_page("Home", text = "Home", is_landing_page = TRUE) %>%
    add_page("Page A", text = "In simple menu") %>%
    add_page("Page B", text = "In hybrid sidebar")
  
  # Should not error (may produce Quarto warnings)
  expect_no_error(generate_dashboard(dashboard, render = FALSE))
  
  yaml_file <- file.path(dashboard$output_dir, "_quarto.yml")
  yaml_content <- readLines(yaml_file, warn = FALSE)
  yaml_text <- paste(yaml_content, collapse = "\n")
  
  # Both menu and sidebar should be present
  expect_true(grepl("menu:", yaml_text))
  expect_true(grepl("sidebar:", yaml_text))
  
})

test_that("navbar_menu uses correct QMD filenames", {
  menu <- navbar_menu(
    text = "Menu",
    pages = c("My Page With Spaces", "Another-Page")
  )
  
  dashboard <- create_dashboard(
    output_dir = tempfile("qmd_names"),
    title = "Test",
    navbar_sections = list(menu)
  ) %>%
    add_page("Home", text = "Home", is_landing_page = TRUE) %>%
    add_page("My Page With Spaces", text = "Spaces") %>%
    add_page("Another-Page", text = "Dashes")
  
  generate_dashboard(dashboard, render = FALSE)
  
  yaml_file <- file.path(dashboard$output_dir, "_quarto.yml")
  yaml_content <- readLines(yaml_file, warn = FALSE)
  yaml_text <- paste(yaml_content, collapse = "\n")
  
  # Should use lowercase with underscores for filenames
  # Note: dashes are converted to underscores
  expect_true(grepl("my_page_with_spaces\\.qmd", yaml_text))
  expect_true(grepl("another_page\\.qmd", yaml_text))  # "Another-Page" -> "another_page.qmd"
  
})

test_that("navbar_menu with align='right' works correctly", {
  # Test that the align parameter is stored

  menu <- navbar_menu(
    text = "More Info",
    pages = c("About", "Wave 1"),
    icon = "ph:info",
    align = "right"
  )
  
  expect_equal(menu$align, "right")
  expect_equal(menu$text, "More Info")
  expect_equal(menu$menu_pages, c("About", "Wave 1"))
})

test_that("right-aligned navbar_menu pages don't appear as individual navbar items", {
  # This tests the fix for the bug where pages in right-aligned dropdown menus

  # were also appearing as separate navbar items
  
  left_menu <- navbar_menu(
    text = "Dimensions",
    pages = c("Skills", "Knowledge"),
    icon = "ph:book"
  )
  
  right_menu <- navbar_menu(
    text = "More Info",
    pages = c("About", "Wave 1"),
    icon = "ph:info",
    align = "right"
  )
  
  dashboard <- create_dashboard(
    output_dir = tempfile("right_align_test"),
    title = "Test Dashboard",
    navbar_sections = list(left_menu, right_menu)
  ) %>%
    add_page("Home", text = "Home page", is_landing_page = TRUE) %>%
    add_page("Skills", text = "Skills content") %>%
    add_page("Knowledge", text = "Knowledge content") %>%
    add_page("About", text = "About content", icon = "ph:info-fill") %>%
    add_page("Wave 1", text = "Wave 1 content", icon = "ph:number-one")
  
  generate_dashboard(dashboard, render = FALSE)
  
  yaml_file <- file.path(dashboard$output_dir, "_quarto.yml")
  yaml_content <- readLines(yaml_file, warn = FALSE)
  yaml_text <- paste(yaml_content, collapse = "\n")
  
  # Check both left: and right: sections exist
  expect_true(grepl("left:", yaml_text))
  expect_true(grepl("right:", yaml_text))
  
  # Find the left: section
  left_idx <- which(grepl("^\\s+left:", yaml_content))[1]
  right_idx <- which(grepl("^\\s+right:", yaml_content))[1]
  
  # Get content between left: and right: (the left navbar section)
  left_section <- yaml_content[(left_idx + 1):(right_idx - 1)]
  left_text <- paste(left_section, collapse = "\n")
  
  # About and Wave 1 should NOT appear as individual items in the left section
  # They should only be inside the right-aligned dropdown menu
  # Count how many times "about.qmd" appears - should only be once (inside the right menu)
  about_in_left <- sum(grepl("about\\.qmd", left_section, ignore.case = TRUE))
  wave1_in_left <- sum(grepl("wave_1\\.qmd", left_section, ignore.case = TRUE))
  
  expect_equal(about_in_left, 0, info = "About should not appear in left navbar section")
  expect_equal(wave1_in_left, 0, info = "Wave 1 should not appear in left navbar section")
  
  # But they SHOULD appear in the right section (inside the dropdown)
  right_section <- yaml_content[(right_idx + 1):length(yaml_content)]
  right_text <- paste(right_section, collapse = "\n")
  
  expect_true(grepl("about\\.qmd", right_text, ignore.case = TRUE), 
              info = "About should appear in right navbar dropdown")
  expect_true(grepl("wave_1\\.qmd", right_text, ignore.case = TRUE), 
              info = "Wave 1 should appear in right navbar dropdown")
  
  # Verify the dropdown menu structure exists in the right section
  expect_true(grepl("menu:", right_text), 
              info = "Dropdown menu should exist in right section")
  expect_true(grepl("More Info", right_text), 
              info = "Menu text should appear in right section")
})

test_that("mixed left and right navbar_menus work correctly", {
  # Test with multiple menus, some left-aligned and some right-aligned
  
  dims_menu <- navbar_menu(
    text = "Dimensions",
    pages = c("Strategic", "Critical")
  )
  
  info_menu <- navbar_menu(
    text = "Info",
    pages = c("About"),
    align = "right"
  )
  
  dashboard <- create_dashboard(
    output_dir = tempfile("mixed_align"),
    title = "Test",
    navbar_sections = list(dims_menu, info_menu)
  ) %>%
    add_page("Home", text = "Home", is_landing_page = TRUE) %>%
    add_page("Strategic", text = "Strategic content") %>%
    add_page("Critical", text = "Critical content") %>%
    add_page("About", text = "About content") %>%
    add_page("Standalone", text = "Not in any menu")  # This should appear as individual item
  
  generate_dashboard(dashboard, render = FALSE)
  
  yaml_file <- file.path(dashboard$output_dir, "_quarto.yml")
  yaml_content <- readLines(yaml_file, warn = FALSE)
  yaml_text <- paste(yaml_content, collapse = "\n")
  
  # Standalone page should appear as individual item (not in any menu)
  expect_true(grepl("standalone\\.qmd", yaml_text, ignore.case = TRUE))
  
  # Both menus should exist
  menu_count <- sum(grepl("^\\s+menu:", yaml_content))
  expect_equal(menu_count, 2, info = "Should have 2 dropdown menus")
})

} # end covr CI skip

