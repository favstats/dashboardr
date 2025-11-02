test_that("navbar_align defaults to 'left' when not specified", {
  proj <- create_dashboard("test", output_dir = tempdir())
  proj <- add_dashboard_page(proj, "Analysis", text = "# Test")
  
  expect_equal(proj$pages$Analysis$navbar_align, "left")
})

test_that("navbar_align accepts 'left' explicitly", {
  proj <- create_dashboard("test", output_dir = tempdir())
  proj <- add_dashboard_page(proj, "Analysis", text = "# Test", navbar_align = "left")
  
  expect_equal(proj$pages$Analysis$navbar_align, "left")
})

test_that("navbar_align accepts 'right'", {
  proj <- create_dashboard("test", output_dir = tempdir())
  proj <- add_dashboard_page(proj, "About", text = "# About", navbar_align = "right")
  
  expect_equal(proj$pages$About$navbar_align, "right")
})

test_that("navbar_align rejects invalid values", {
  proj <- create_dashboard("test", output_dir = tempdir())
  
  expect_error(
    add_dashboard_page(proj, "Analysis", text = "# Test", navbar_align = "center"),
    "'arg' should be one of"
  )
  
  expect_error(
    add_dashboard_page(proj, "Analysis", text = "# Test", navbar_align = "middle"),
    "'arg' should be one of"
  )
})

test_that("YAML generation places left-aligned pages in navbar left section", {
  proj <- create_dashboard("test", output_dir = tempdir())
  proj <- add_dashboard_page(proj, "Home", text = "# Home", is_landing_page = TRUE)
  proj <- add_dashboard_page(proj, "Analysis", text = "# Analysis", navbar_align = "left")
  
  yaml_content <- .generate_quarto_yml(proj)
  
  # Should have left: section
  expect_true(any(grepl("left:", yaml_content, fixed = TRUE)))
  
  # Analysis should be in the YAML before any right: section
  analysis_line <- which(grepl("Analysis", yaml_content))
  left_line <- which(grepl("^\\s+left:", yaml_content))
  
  expect_true(length(analysis_line) > 0)
  expect_true(length(left_line) > 0)
  expect_true(analysis_line[1] > left_line[1])
})

test_that("YAML generation places right-aligned pages in navbar right section", {
  proj <- create_dashboard("test", output_dir = tempdir())
  proj <- add_dashboard_page(proj, "Home", text = "# Home", is_landing_page = TRUE)
  proj <- add_dashboard_page(proj, "About", text = "# About", navbar_align = "right")
  
  yaml_content <- .generate_quarto_yml(proj)
  
  # Should have right: section
  expect_true(any(grepl("right:", yaml_content, fixed = TRUE)))
  
  # About should be in the YAML after the right: section
  about_line <- which(grepl("About", yaml_content))
  right_line <- which(grepl("^\\s+right:", yaml_content))
  
  expect_true(length(about_line) > 0)
  expect_true(length(right_line) > 0)
  expect_true(about_line[1] > right_line[1])
})

test_that("YAML generation handles mixed left and right alignment", {
  proj <- create_dashboard("test", output_dir = tempdir())
  proj <- add_dashboard_page(proj, "Home", text = "# Home", is_landing_page = TRUE)
  proj <- add_dashboard_page(proj, "Analysis", text = "# Analysis", navbar_align = "left")
  proj <- add_dashboard_page(proj, "Results", text = "# Results", navbar_align = "left")
  proj <- add_dashboard_page(proj, "About", text = "# About", navbar_align = "right")
  proj <- add_dashboard_page(proj, "Contact", text = "# Contact", navbar_align = "right")
  
  yaml_content <- .generate_quarto_yml(proj)
  
  # Should have both sections
  expect_true(any(grepl("left:", yaml_content, fixed = TRUE)))
  expect_true(any(grepl("right:", yaml_content, fixed = TRUE)))
  
  # Get line numbers
  left_line <- which(grepl("^\\s+left:", yaml_content))[1]
  right_line <- which(grepl("^\\s+right:", yaml_content))[1]
  analysis_line <- which(grepl("Analysis", yaml_content))[1]
  results_line <- which(grepl("Results", yaml_content))[1]
  about_line <- which(grepl("About", yaml_content))[1]
  contact_line <- which(grepl("Contact", yaml_content))[1]
  
  # Left-aligned pages should come after left: and before right:
  expect_true(analysis_line > left_line)
  expect_true(analysis_line < right_line)
  expect_true(results_line > left_line)
  expect_true(results_line < right_line)
  
  # Right-aligned pages should come after right:
  expect_true(about_line > right_line)
  expect_true(contact_line > right_line)
})

test_that("right section is not added if only left-aligned pages exist", {
  proj <- create_dashboard("test", output_dir = tempdir())
  proj <- add_dashboard_page(proj, "Home", text = "# Home", is_landing_page = TRUE)
  proj <- add_dashboard_page(proj, "Analysis", text = "# Analysis", navbar_align = "left")
  
  yaml_content <- .generate_quarto_yml(proj)
  
  # Should have left: section but NOT right: section (unless there are tools)
  expect_true(any(grepl("left:", yaml_content, fixed = TRUE)))
  
  # Count right: occurrences - should only exist if there are tools
  right_lines <- grep("right:", yaml_content, fixed = TRUE)
  
  # If no social media/tools configured, should be 0
  if (is.null(proj$github) && is.null(proj$twitter) && is.null(proj$linkedin) && 
      is.null(proj$email) && is.null(proj$website)) {
    expect_equal(length(right_lines), 0)
  }
})

test_that("right section combines right-aligned pages with tools", {
  proj <- create_dashboard("test", output_dir = tempdir(), github = "https://github.com/test/repo")
  proj <- add_dashboard_page(proj, "Home", text = "# Home", is_landing_page = TRUE)
  proj <- add_dashboard_page(proj, "Analysis", text = "# Analysis", navbar_align = "left")
  proj <- add_dashboard_page(proj, "About", text = "# About", navbar_align = "right")
  
  yaml_content <- .generate_quarto_yml(proj)
  
  # Should have right: section
  expect_true(any(grepl("right:", yaml_content, fixed = TRUE)))
  
  # Should have both About page and github icon
  expect_true(any(grepl("About", yaml_content, fixed = TRUE)))
  expect_true(any(grepl("github", yaml_content, fixed = TRUE)))
  
  # About should come before github icon in the right section
  right_line <- which(grepl("^\\s+right:", yaml_content))[1]
  about_line <- which(grepl("About", yaml_content))[1]
  github_line <- which(grepl("github", yaml_content))[1]
  
  expect_true(about_line > right_line)
  expect_true(github_line > right_line)
  expect_true(about_line < github_line)  # Pages before tools
})

test_that("landing page is not affected by navbar_align", {
  proj <- create_dashboard("test", output_dir = tempdir())
  proj <- add_dashboard_page(proj, "Home", text = "# Home", is_landing_page = TRUE, navbar_align = "right")
  proj <- add_dashboard_page(proj, "Analysis", text = "# Analysis", navbar_align = "left")
  
  yaml_content <- .generate_quarto_yml(proj)
  
  # Landing page should still appear as "Home" in left section
  home_line <- which(grepl("Home", yaml_content))[1]
  left_line <- which(grepl("^\\s+left:", yaml_content))[1]
  
  expect_true(home_line > left_line)
})

test_that("navbar_align works with icons", {
  proj <- create_dashboard("test", output_dir = tempdir())
  proj <- add_dashboard_page(proj, "Home", text = "# Home", is_landing_page = TRUE)
  proj <- add_dashboard_page(proj, "Analysis", text = "# Analysis", 
                            icon = "ph:chart-bar", navbar_align = "left")
  proj <- add_dashboard_page(proj, "About", text = "# About", 
                            icon = "ph:info", navbar_align = "right")
  
  yaml_content <- .generate_quarto_yml(proj)
  
  # Should have both pages with icons
  expect_true(any(grepl("Analysis", yaml_content, fixed = TRUE)))
  expect_true(any(grepl("About", yaml_content, fixed = TRUE)))
  expect_true(any(grepl("chart-bar", yaml_content, fixed = TRUE)))
  expect_true(any(grepl("info", yaml_content, fixed = TRUE)))
})

