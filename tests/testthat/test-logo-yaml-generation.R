test_that("logo is correctly placed at navbar level in YAML", {
  skip_on_cran()
  
  # Create a minimal dashboard with logo and navbar sections
  proj <- create_dashboard(
    output_dir = tempfile(),
    title = "Test Dashboard",
    logo = "logo.png",
    navbar_sections = list(
      navbar_menu(
        text = "Test Menu",
        pages = c("Page 1", "Page 2"),
        icon = "ph:books-fill"
      )
    )
  ) %>%
    add_page(
      name = "Page 1",
      text = md_text("Content 1")
    ) %>%
    add_page(
      name = "Page 2",
      text = md_text("Content 2")
    )
  
  # Generate the YAML
  yaml_lines <- dashboardr:::.generate_quarto_yml(proj)
  
  # Find the navbar section
  navbar_idx <- which(yaml_lines == "  navbar:")
  left_idx <- which(yaml_lines == "    left:")
  logo_idx <- which(grepl("^    logo:", yaml_lines))
  
  # Tests
  expect_true(length(navbar_idx) == 1, "navbar section should exist")
  expect_true(length(left_idx) == 1, "left section should exist")
  expect_true(length(logo_idx) == 1, "logo line should exist")
  
  # Critical test: logo should come BEFORE left section
  expect_true(logo_idx < left_idx, 
              "logo should be at navbar level (before left:), not inside left section")
  
  # Verify logo has correct indentation (4 spaces, same as 'style:', 'brand:', etc.)
  logo_line <- yaml_lines[logo_idx]
  expect_true(grepl("^    logo: ", logo_line), 
              "logo should have 4-space indentation (navbar level)")
  expect_false(grepl("^      ", logo_line), 
               "logo should NOT have 6-space indentation (left level)")
  
  # Verify the YAML is valid by checking it can be parsed
  yaml_text <- paste(yaml_lines, collapse = "\n")
  expect_no_error({
    yaml::yaml.load(yaml_text)
  }, message = "Generated YAML should be parseable")
})

test_that("logo works with simple navigation (no navbar_sections)", {
  skip_on_cran()
  
  # Create a minimal dashboard with logo but no navbar sections
  proj <- create_dashboard(
    output_dir = tempfile(),
    title = "Test Dashboard",
    logo = "logo.png"
  ) %>%
    add_page(
      name = "Page 1",
      text = md_text("Content 1")
    )
  
  # Generate the YAML
  yaml_lines <- dashboardr:::.generate_quarto_yml(proj)
  
  # Verify logo placement
  logo_idx <- which(grepl("^    logo:", yaml_lines))
  left_idx <- which(yaml_lines == "    left:")
  
  expect_true(length(logo_idx) == 1, "logo should exist")
  expect_true(logo_idx < left_idx, "logo should come before left section")
  
  # Verify valid YAML
  yaml_text <- paste(yaml_lines, collapse = "\n")
  expect_no_error({
    yaml::yaml.load(yaml_text)
  })
})

test_that("dashboard without logo still works", {
  skip_on_cran()
  
  # Create a minimal dashboard without logo
  proj <- create_dashboard(
    output_dir = tempfile(),
    title = "Test Dashboard"
  ) %>%
    add_page(
      name = "Page 1",
      text = md_text("Content 1")
    )
  
  # Generate the YAML
  yaml_lines <- dashboardr:::.generate_quarto_yml(proj)
  
  # Verify no logo line exists
  logo_idx <- which(grepl("^    logo:", yaml_lines))
  expect_true(length(logo_idx) == 0, "logo should not exist when not provided")
  
  # Verify valid YAML
  yaml_text <- paste(yaml_lines, collapse = "\n")
  expect_no_error({
    yaml::yaml.load(yaml_text)
  })
})

test_that("logo with navbar sections generates valid YAML structure", {
  skip_on_cran()
  
  # Create dashboard similar to user's actual use case
  dimensions_menu <- navbar_menu(
    text = "Dimensions",
    pages = c("Strategic Information", "Critical Information", "Netiquette"),
    icon = "ph:books-fill"
  )
  
  proj <- create_dashboard(
    output_dir = tempfile(),
    title = "Digital Competence Insights",
    logo = "logo.png",
    navbar_sections = list(dimensions_menu),
    search = TRUE,
    theme = "flatly"
  ) %>%
    add_page(
      name = "Home",
      text = md_text("Welcome"),
      is_landing_page = TRUE
    ) %>%
    add_page(
      name = "Strategic Information",
      text = md_text("Strategic Info Content"),
      icon = "ph:magnifying-glass"
    ) %>%
    add_page(
      name = "Critical Information",
      text = md_text("Critical Info Content"),
      icon = "ph:shield"
    ) %>%
    add_page(
      name = "Netiquette",
      text = md_text("Netiquette Content"),
      icon = "ph:chat"
    )
  
  # Generate the YAML
  yaml_lines <- dashboardr:::.generate_quarto_yml(proj)
  
  # Write to temp file and validate with YAML parser
  temp_yaml <- tempfile(fileext = ".yml")
  writeLines(yaml_lines, temp_yaml)
  
  # Parse the YAML to ensure it's valid
  expect_no_error({
    parsed <- yaml::yaml.load_file(temp_yaml)
    
    # Verify structure
    expect_true("website" %in% names(parsed))
    expect_true("navbar" %in% names(parsed$website))
    expect_true("logo" %in% names(parsed$website$navbar))
    expect_equal(parsed$website$navbar$logo, "logo.png")
    expect_true("left" %in% names(parsed$website$navbar))
    
  }, message = "Complex dashboard with logo should generate valid YAML")
  
  unlink(temp_yaml)
})

