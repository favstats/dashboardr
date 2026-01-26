# =================================================================
# Tests: Lazy Loading Polish (R-First, Beautiful Skeletons)
# =================================================================

test_that("add_page respects lazy_load override", {
  proj <- create_dashboard("test_lazy_override", lazy_load_charts = TRUE) %>%
    add_page("Page1", lazy_load_charts = FALSE)
  
  expect_false(proj$pages$Page1$lazy_load_charts)
  
  # Cleanup
  unlink("test_lazy_override", recursive = TRUE)
})

test_that("pages inherit dashboard lazy_load settings", {
  proj <- create_dashboard("test_lazy_inherit", 
                          lazy_load_charts = TRUE, 
                          lazy_load_margin = "300px") %>%
    add_page("Page1")  # No override - should inherit
  
  expect_true(proj$pages$Page1$lazy_load_charts)
  expect_equal(proj$pages$Page1$lazy_load_margin, "300px")
  
  # Cleanup
  unlink("test_lazy_inherit", recursive = TRUE)
})

test_that("lazy loading uses Quarto div syntax not HTML", {
  skip_if_not_installed("quarto")
  
  proj <- create_dashboard("test_lazy_qmd", lazy_load_charts = TRUE) %>%
    add_page("Test", 
             data = mtcars, 
             visualizations = create_viz() %>% add_viz(type = "bar", x_var = "cyl"))
  
  result_proj <- generate_dashboard(proj, render = FALSE, open = FALSE)
  qmd_file <- readLines(file.path(result_proj$output_dir, "test.qmd"))
  
  # Should use ::: syntax
  expect_true(any(grepl("^:::", qmd_file)), 
              info = "Should use Quarto ::: div syntax")
  
  # Should have chart-lazy class
  expect_true(any(grepl("chart-lazy", qmd_file)),
              info = "Should have chart-lazy class")
  
  # Should NOT have verbose inline HTML styles in chart wrappers
  style_pattern <- "style='.*min-height.*background.*animation"
  expect_false(any(grepl(style_pattern, qmd_file)),
               info = "Should NOT have inline styles in chart wrappers")
  
  # Cleanup
  unlink("test_lazy_qmd", recursive = TRUE)
})

test_that("skeleton CSS uses overlay theme", {
  skip_if_not_installed("quarto")
  
  proj <- create_dashboard("test_lazy_theme", lazy_load_charts = TRUE) %>%
    add_page("Test", 
             data = mtcars,
             overlay = TRUE, 
             overlay_theme = "glass",
             visualizations = create_viz() %>% add_viz(type = "bar", x_var = "cyl"))
  
  result_proj <- generate_dashboard(proj, render = FALSE, open = FALSE)
  qmd_file <- readLines(file.path(result_proj$output_dir, "test.qmd"))
  qmd_text <- paste(qmd_file, collapse = "\n")
  
  # Should have theme-glass in skeleton styles
  expect_true(grepl("theme-glass", qmd_text),
              info = "Should have theme-glass CSS class")
  
  # Should have glass theme specific styles (backdrop-filter)
  expect_true(grepl("backdrop-filter.*blur", qmd_text),
              info = "Should have glass theme backdrop-filter CSS")
  
  # Cleanup
  unlink("test_lazy_theme", recursive = TRUE)
})

test_that("charts render even without JavaScript (R chunks preserved)", {
  skip_if_not_installed("quarto")
  
  proj <- create_dashboard("test_lazy_nojs", lazy_load_charts = TRUE) %>%
    add_page("Test", 
             data = mtcars, 
             visualizations = create_viz() %>% add_viz(type = "bar", x_var = "cyl"))
  
  result_proj <- generate_dashboard(proj, render = FALSE, open = FALSE)
  qmd_file <- readLines(file.path(result_proj$output_dir, "test.qmd"))
  
  # R chunk should still be there (graceful degradation)
  expect_true(any(grepl("```\\{r", qmd_file)),
              info = "R chunks should be preserved for no-JS fallback")
  
  # Chart creation code should be present (viz_* functions)
  expect_true(any(grepl("viz_", qmd_file)),
              info = "Chart creation code should be present")
  
  # Cleanup
  unlink("test_lazy_nojs", recursive = TRUE)
})

test_that("per-page lazy_load_margin override works", {
  proj <- create_dashboard("test_lazy_margin", 
                          lazy_load_charts = TRUE,
                          lazy_load_margin = "200px") %>%
    add_page("Page1") %>%  # Should inherit "200px"
    add_page("Page2", lazy_load_margin = "500px")  # Should override to "500px"
  
  expect_equal(proj$pages$Page1$lazy_load_margin, "200px")
  expect_equal(proj$pages$Page2$lazy_load_margin, "500px")
  
  # Cleanup
  unlink("test_lazy_margin", recursive = TRUE)
})

test_that("per-page lazy_load_tabs override works", {
  proj <- create_dashboard("test_lazy_tabs", 
                          lazy_load_charts = TRUE,
                          lazy_load_tabs = TRUE) %>%
    add_page("Page1") %>%  # Should inherit TRUE
    add_page("Page2", lazy_load_tabs = FALSE)  # Should override to FALSE
  
  expect_true(proj$pages$Page1$lazy_load_tabs)
  expect_false(proj$pages$Page2$lazy_load_tabs)
  
  # Cleanup
  unlink("test_lazy_tabs", recursive = TRUE)
})

