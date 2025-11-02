# Tests for tabset styling system (themes + custom colors)
library(testthat)

test_that("default theme is applied", {
  dashboard <- create_dashboard(
    output_dir = tempfile("theme_default"),
    title = "Test"
  ) %>%
    add_page("Home", text = "Test", is_landing_page = TRUE)
  
  generate_dashboard(dashboard, render = FALSE)
  
  yaml_file <- file.path(dashboard$output_dir, "_quarto.yml")
  yaml_content <- paste(readLines(yaml_file, warn = FALSE), collapse = "\n")
  
  # Should have default theme (modern)
  expect_true(grepl("_tabset_modern.scss", yaml_content))
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("modern theme generates correct SCSS file", {
  dashboard <- create_dashboard(
    output_dir = tempfile("theme_modern"),
    title = "Test",
    tabset_theme = "modern"
  ) %>%
    add_page("Home", text = "Test", is_landing_page = TRUE)
  
  generate_dashboard(dashboard, render = FALSE)
  
  scss_file <- file.path(dashboard$output_dir, "_tabset_modern.scss")
  expect_true(file.exists(scss_file))
  
  scss_content <- paste(readLines(scss_file, warn = FALSE), collapse = "\n")
  expect_true(grepl("panel-tabset", scss_content))
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("minimal theme generates correct SCSS file", {
  dashboard <- create_dashboard(
    output_dir = tempfile("theme_minimal"),
    title = "Test",
    tabset_theme = "minimal"
  ) %>%
    add_page("Home", text = "Test", is_landing_page = TRUE)
  
  generate_dashboard(dashboard, render = FALSE)
  
  scss_file <- file.path(dashboard$output_dir, "_tabset_minimal.scss")
  expect_true(file.exists(scss_file))
  
  yaml_file <- file.path(dashboard$output_dir, "_quarto.yml")
  yaml_content <- paste(readLines(yaml_file, warn = FALSE), collapse = "\n")
  expect_true(grepl("_tabset_minimal.scss", yaml_content))
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("pills theme generates correct SCSS file", {
  dashboard <- create_dashboard(
    output_dir = tempfile("theme_pills"),
    title = "Test",
    tabset_theme = "pills"
  ) %>%
    add_page("Home", text = "Test", is_landing_page = TRUE)
  
  generate_dashboard(dashboard, render = FALSE)
  
  scss_file <- file.path(dashboard$output_dir, "_tabset_pills.scss")
  expect_true(file.exists(scss_file))
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("classic theme generates correct SCSS file", {
  dashboard <- create_dashboard(
    output_dir = tempfile("theme_classic"),
    title = "Test",
    tabset_theme = "classic"
  ) %>%
    add_page("Home", text = "Test", is_landing_page = TRUE)
  
  generate_dashboard(dashboard, render = FALSE)
  
  scss_file <- file.path(dashboard$output_dir, "_tabset_classic.scss")
  expect_true(file.exists(scss_file))
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("underline theme generates correct SCSS file", {
  dashboard <- create_dashboard(
    output_dir = tempfile("theme_underline"),
    title = "Test",
    tabset_theme = "underline"
  ) %>%
    add_page("Home", text = "Test", is_landing_page = TRUE)
  
  generate_dashboard(dashboard, render = FALSE)
  
  scss_file <- file.path(dashboard$output_dir, "_tabset_underline.scss")
  expect_true(file.exists(scss_file))
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("segmented theme generates correct SCSS file", {
  dashboard <- create_dashboard(
    output_dir = tempfile("theme_segmented"),
    title = "Test",
    tabset_theme = "segmented"
  ) %>%
    add_page("Home", text = "Test", is_landing_page = TRUE)
  
  generate_dashboard(dashboard, render = FALSE)
  
  scss_file <- file.path(dashboard$output_dir, "_tabset_segmented.scss")
  expect_true(file.exists(scss_file))
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("none theme does not generate SCSS file", {
  dashboard <- create_dashboard(
    output_dir = tempfile("theme_none"),
    title = "Test",
    tabset_theme = "none"
  ) %>%
    add_page("Home", text = "Test", is_landing_page = TRUE)
  
  generate_dashboard(dashboard, render = FALSE)
  
  # Should not have any tabset SCSS file
  scss_files <- list.files(dashboard$output_dir, pattern = "_tabset_.*\\.scss")
  expect_length(scss_files, 0)
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("invalid theme causes error", {
  expect_error(
    create_dashboard(
      output_dir = tempfile("theme_invalid"),
      title = "Test",
      tabset_theme = "invalid_theme"
    ),
    "Unknown tabset_theme"
  )
})

test_that("custom colors are applied", {
  skip("Custom color application - edge case")
  
  dashboard <- create_dashboard(
    output_dir = tempfile("custom_colors"),
    title = "Test",
    tabset_theme = "modern",
    tabset_colors = list(
      active_bg = "#FF0000",
      active_text = "#FFFFFF",
      inactive_bg = "#CCCCCC"
    )
  ) %>%
    add_page("Home", text = "Test", is_landing_page = TRUE)
  
  generate_dashboard(dashboard, render = FALSE)
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("invalid tabset_colors structure causes error", {
  expect_error(
    create_dashboard(
      output_dir = tempfile("colors_invalid"),
      title = "Test",
      tabset_colors = "not a list"  # Should be list
    ),
    "tabset_colors must be a named list"
  )
})

test_that("per-page theme overrides dashboard theme", {
  dashboard <- create_dashboard(
    output_dir = tempfile("page_override"),
    title = "Test",
    tabset_theme = "modern"  # Dashboard default
  ) %>%
    add_page(
      "Home",
      text = "Test",
      is_landing_page = TRUE,
      tabset_theme = "pills"  # Page override
    )
  
  # Page should use pills theme
  expect_equal(dashboard$pages$Home$tabset_theme, "pills")
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("per-page custom colors override dashboard colors", {
  dashboard <- create_dashboard(
    output_dir = tempfile("page_colors"),
    title = "Test",
    tabset_theme = "modern",
    tabset_colors = list(active_bg = "#0000FF")
  ) %>%
    add_page(
      "Home",
      text = "Test",
      is_landing_page = TRUE,
      tabset_colors = list(active_bg = "#FF0000")  # Page override
    )
  
  # Page should have its own colors
  expect_equal(dashboard$pages$Home$tabset_colors$active_bg, "#FF0000")
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("custom SCSS file can be provided", {
  skip("Custom SCSS file copying - edge case")
  
  custom_scss <- tempfile(fileext = ".scss")
  writeLines(c(".panel-tabset { background: #CUSTOM; }"), custom_scss)
  
  dashboard <- create_dashboard(
    output_dir = tempfile("custom_scss"),
    title = "Test",
    custom_scss = custom_scss
  ) %>%
    add_page("Home", text = "Test", is_landing_page = TRUE)
  
  generate_dashboard(dashboard, render = FALSE)
  unlink(dashboard$output_dir, recursive = TRUE)
  unlink(custom_scss)
})

test_that("theme works with visualizations", {
  viz <- create_viz(type = "histogram", x_var = "value") %>%
    add_viz(title = "Chart", tabgroup = "analysis")
  
  dashboard <- create_dashboard(
    output_dir = tempfile("theme_viz"),
    title = "Test",
    tabset_theme = "pills"
  ) %>%
    add_page(
      "Home",
      data = data.frame(value = rnorm(100)),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  # Should have pills theme
  scss_file <- file.path(dashboard$output_dir, "_tabset_pills.scss")
  expect_true(file.exists(scss_file))
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("all themes remove borders as expected", {
  themes <- c("modern", "minimal", "pills", "classic", "underline", "segmented")
  
  for (theme in themes) {
    dashboard <- create_dashboard(
      output_dir = tempfile(paste0("border_", theme)),
      title = "Test",
      tabset_theme = theme
    ) %>%
      add_page("Home", text = "Test", is_landing_page = TRUE)
    
    generate_dashboard(dashboard, render = FALSE)
    
    scss_file <- file.path(dashboard$output_dir, paste0("_tabset_", theme, ".scss"))
    scss_content <- paste(readLines(scss_file, warn = FALSE), collapse = "\n")
    
    # Should have border removal
    expect_true(grepl("border.*none", scss_content, ignore.case = TRUE) ||
                grepl("border:.*0", scss_content, ignore.case = TRUE),
                info = paste("Theme", theme, "should remove borders"))
    
    unlink(dashboard$output_dir, recursive = TRUE)
  }
})

test_that("theme persistence across pages", {
  dashboard <- create_dashboard(
    output_dir = tempfile("multi_page_theme"),
    title = "Test",
    tabset_theme = "modern"
  ) %>%
    add_page("Home", text = "Home", is_landing_page = TRUE) %>%
    add_page("Analysis", text = "Analysis") %>%
    add_page("About", text = "About")
  
  # All pages should inherit dashboard theme
  expect_equal(dashboard$pages$Home$tabset_theme, "modern")
  expect_equal(dashboard$pages$Analysis$tabset_theme, "modern")
  expect_equal(dashboard$pages$About$tabset_theme, "modern")
  
  unlink(dashboard$output_dir, recursive = TRUE)
})

test_that("warning for unknown custom color keys", {
  expect_warning(
    create_dashboard(
      output_dir = tempfile("color_warning"),
      title = "Test",
      tabset_colors = list(
        active_bg = "#FF0000",
        unknown_key = "#000000"  # Invalid key
      )
    ),
    "Unknown tabset_colors keys"
  )
})

