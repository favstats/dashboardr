# =============================================================================
# Tests for Sidebar Functionality
# =============================================================================
#
# These tests verify:
# 1. add_sidebar() and end_sidebar() work correctly
# 2. Sidebar content is properly stored and structured
# 3. Sidebar parameters are validated
# 4. Sidebar content renders correctly
# =============================================================================

library(testthat)
library(dashboardr)

# =============================================================================
# SECTION 1: add_sidebar() Function Tests
# =============================================================================

describe("add_sidebar() function", {
  
  setup_content <- function() {
    create_content()
  }
  
  # ---------------------------------------------------------------------------
  # Basic Functionality
  # ---------------------------------------------------------------------------
  
  it("creates a sidebar container", {
    content <- setup_content()
    result <- add_sidebar(content)
    
    expect_s3_class(result, "sidebar_container")
  })
  
  it("stores sidebar parameters", {
    content <- setup_content()
    result <- add_sidebar(content, width = "300px", title = "Filters", position = "right")
    
    expect_equal(result$width, "300px")
    expect_equal(result$title, "Filters")
    expect_equal(result$position, "right")
  })
  
  it("uses default parameters when not specified", {
    content <- setup_content()
    result <- add_sidebar(content)
    
    expect_equal(result$width, "250px")
    expect_null(result$title)
    expect_equal(result$position, "left")
  })
  
  it("accepts valid position values", {
    content <- setup_content()
    
    left <- add_sidebar(content, position = "left")
    expect_equal(left$position, "left")
    
    right <- add_sidebar(content, position = "right")
    expect_equal(right$position, "right")
  })
  
  # ---------------------------------------------------------------------------
  # Content Addition in Sidebar
  # ---------------------------------------------------------------------------
  
  it("allows adding text to sidebar", {
    content <- setup_content() %>%
      add_sidebar() %>%
      add_text("Test text")
    
    expect_s3_class(content, "sidebar_container")
    expect_true(length(content$blocks) >= 1)
  })
  
  it("allows adding inputs to sidebar", {
    content <- setup_content() %>%
      add_sidebar() %>%
      add_input(
        input_id = "test",
        filter_var = "var",
        type = "checkbox",
        options = c("A", "B", "C")
      )
    
    expect_s3_class(content, "sidebar_container")
    expect_true(length(content$blocks) >= 1)
  })
  
  it("allows adding dividers to sidebar", {
    content <- setup_content() %>%
      add_sidebar() %>%
      add_divider()
    
    expect_s3_class(content, "sidebar_container")
    expect_true(length(content$blocks) >= 1)
  })
  
  it("allows adding callouts to sidebar", {
    content <- setup_content() %>%
      add_sidebar() %>%
      add_callout("Test callout", type = "note")
    
    expect_s3_class(content, "sidebar_container")
    expect_true(length(content$blocks) >= 1)
  })
  
  it("allows adding badges to sidebar", {
    content <- setup_content() %>%
      add_sidebar() %>%
      add_badge("Test badge", color = "primary")
    
    expect_s3_class(content, "sidebar_container")
    expect_true(length(content$blocks) >= 1)
  })
  
  it("allows adding spacers to sidebar", {
    content <- setup_content() %>%
      add_sidebar() %>%
      add_spacer(height = "1rem")
    
    expect_s3_class(content, "sidebar_container")
    expect_true(length(content$blocks) >= 1)
  })
})

# =============================================================================
# SECTION 2: end_sidebar() Function Tests
# =============================================================================

describe("end_sidebar() function", {
  
  it("returns content_collection from sidebar_container", {
    content <- create_content() %>%
      add_sidebar() %>%
      add_text("Test") %>%
      end_sidebar()
    
    expect_s3_class(content, "content_collection")
    expect_false(inherits(content, "sidebar_container"))
  })
  
  it("preserves sidebar settings in content", {
    content <- create_content() %>%
      add_sidebar(width = "320px", title = "Options", position = "right") %>%
      add_text("Test") %>%
      end_sidebar()
    
    # The sidebar is stored as content$sidebar
    expect_s3_class(content, "content_collection")
    expect_false(is.null(content$sidebar))
    expect_equal(content$sidebar$width, "320px")
    expect_equal(content$sidebar$title, "Options")
    expect_equal(content$sidebar$position, "right")
  })
  
  it("preserves sidebar content blocks", {
    content <- create_content() %>%
      add_sidebar() %>%
      add_text("Line 1") %>%
      add_divider() %>%
      add_text("Line 2") %>%
      end_sidebar()
    
    # Sidebar content is in content$sidebar$blocks
    expect_true(length(content$sidebar$blocks) >= 3)
  })
  
  it("allows adding viz after sidebar", {
    content <- create_content(data = mtcars, type = "bar") %>%
      add_sidebar() %>%
      add_text("Filter options") %>%
      end_sidebar() %>%
      add_viz(x_var = "cyl", title = "Cylinders")
    
    expect_s3_class(content, "content_collection")
    # Should have sidebar
    expect_false(is.null(content$sidebar))
    # Viz is stored in items
    expect_true(length(content$items) >= 1)
  })
  
  it("errors when called without add_sidebar first", {
    content <- create_content()
    expect_error(end_sidebar(content), "sidebar_container")
  })
})

# =============================================================================
# SECTION 3: Sidebar with Multiple Input Types
# =============================================================================

describe("sidebar with various input types", {
  
  it("handles checkbox inputs", {
    content <- create_content() %>%
      add_sidebar() %>%
      add_input(
        input_id = "checkbox_test",
        label = "Options:",
        type = "checkbox",
        filter_var = "category",
        options = c("A", "B", "C"),
        default_selected = c("A", "B")
      ) %>%
      end_sidebar()
    
    expect_s3_class(content, "content_collection")
    expect_false(is.null(content$sidebar))
    expect_true(length(content$sidebar$blocks) >= 1)
  })
  
  it("handles radio inputs", {
    content <- create_content() %>%
      add_sidebar() %>%
      add_input(
        input_id = "radio_test",
        label = "Select one:",
        type = "radio",
        filter_var = "metric",
        options = c("Option 1", "Option 2"),
        default_selected = "Option 1"
      ) %>%
      end_sidebar()
    
    expect_s3_class(content, "content_collection")
  })
  
  it("handles slider inputs", {
    content <- create_content() %>%
      add_sidebar() %>%
      add_input(
        input_id = "slider_test",
        label = "Year:",
        type = "slider",
        filter_var = "year",
        min = 2018,
        max = 2024,
        value = 2021
      ) %>%
      end_sidebar()
    
    expect_s3_class(content, "content_collection")
  })
  
  it("handles select inputs", {
    content <- create_content() %>%
      add_sidebar() %>%
      add_input(
        input_id = "select_test",
        label = "Choose:",
        type = "select_multiple",
        filter_var = "country",
        options = c("USA", "UK", "Germany", "France")
      ) %>%
      end_sidebar()
    
    expect_s3_class(content, "content_collection")
  })
})

# =============================================================================
# SECTION 4: Input columns parameter
# =============================================================================

describe("columns parameter for inputs", {
  
  it("accepts columns parameter for checkbox", {
    # Test via HTML generation function directly
    html <- dashboardr:::.generate_checkbox_html(
      input_id = "cols_test",
      label = "Options:",
      filter_var = "cat",
      options = c("A", "B", "C", "D"),
      default_selected = c("A"),
      width = "100%",
      align = "left",
      inline = FALSE,
      size = "md",
      help = NULL,
      disabled = FALSE,
      columns = 2
    )
    
    expect_true(grepl("grid-2", html))
  })
  
  it("accepts columns parameter for radio", {
    html <- dashboardr:::.generate_radio_html(
      input_id = "radio_cols",
      label = "Choice:",
      filter_var = "choice",
      options = c("X", "Y", "Z"),
      default_selected = "X",
      width = "100%",
      align = "left",
      inline = FALSE,
      size = "md",
      help = NULL,
      disabled = FALSE,
      columns = 3
    )
    
    expect_true(grepl("grid-3", html))
  })
  
  it("inline takes priority over columns", {
    html <- dashboardr:::.generate_checkbox_html(
      input_id = "combo_test",
      label = "Options:",
      filter_var = "cat",
      options = c("A", "B"),
      default_selected = NULL,
      width = "100%",
      align = "left",
      inline = TRUE,
      size = "md",
      help = NULL,
      disabled = FALSE,
      columns = 2
    )
    
    expect_true(grepl("inline", html))
    expect_false(grepl("grid-2", html))
  })
})

# =============================================================================
# SECTION 5: Complete Sidebar Workflow
# =============================================================================

describe("complete sidebar workflow", {
  
  it("supports full sidebar workflow with viz", {
    # Create sample data
    test_data <- data.frame(
      category = c("A", "B", "C", "A", "B", "C"),
      value = c(10, 20, 30, 15, 25, 35),
      group = c("X", "X", "X", "Y", "Y", "Y")
    )
    
    content <- create_content(data = test_data, type = "bar") %>%
      add_sidebar(width = "280px", title = "Filters") %>%
        add_text("Select options below:") %>%
        add_divider() %>%
        add_input(
          input_id = "group_filter",
          label = "Group:",
          type = "checkbox",
          filter_var = "group",
          options = c("X", "Y"),
          default_selected = c("X", "Y")
        ) %>%
        add_spacer(height = "1rem") %>%
        add_callout("Data updates automatically.", type = "tip") %>%
      end_sidebar() %>%
      add_viz(x_var = "category", title = "Categories")
    
    expect_s3_class(content, "content_collection")
    # Should have sidebar
    expect_false(is.null(content$sidebar))
    expect_equal(content$sidebar$width, "280px")
    expect_equal(content$sidebar$title, "Filters")
    expect_true(length(content$sidebar$blocks) >= 4)
    # Viz is stored in items
    expect_true(length(content$items) >= 1)
  })
  
  it("supports page with sidebar content", {
    test_data <- data.frame(
      x = c("A", "B", "C"),
      y = c(1, 2, 3)
    )
    
    # Create content with sidebar and add it to page
    sidebar_content <- create_content(data = test_data, type = "bar") %>%
      add_sidebar(title = "Options") %>%
        add_text("Filter data:") %>%
        add_input(
          input_id = "x_filter",
          label = "Categories:",
          type = "checkbox",
          filter_var = "x",
          options = c("A", "B", "C")
        ) %>%
      end_sidebar() %>%
      add_viz(x_var = "x", title = "Test")
    
    # Sidebar should be in the content
    expect_s3_class(sidebar_content, "content_collection")
    expect_false(is.null(sidebar_content$sidebar))
    expect_equal(sidebar_content$sidebar$title, "Options")
  })
})

# =============================================================================
# SECTION 6: Edge Cases
# =============================================================================

describe("sidebar edge cases", {
  
  it("handles empty sidebar", {
    content <- create_content() %>%
      add_sidebar() %>%
      end_sidebar()
    
    expect_s3_class(content, "content_collection")
  })
  
  it("handles sidebar with only title", {
    content <- create_content() %>%
      add_sidebar(title = "Options") %>%
      end_sidebar()
    
    expect_s3_class(content, "content_collection")
    expect_equal(content$sidebar$title, "Options")
  })
  
  it("handles very wide sidebar width", {
    content <- create_content() %>%
      add_sidebar(width = "500px") %>%
      end_sidebar()
    
    expect_equal(content$sidebar$width, "500px")
  })
  
  it("handles percentage width", {
    content <- create_content() %>%
      add_sidebar(width = "30%") %>%
      end_sidebar()
    
    expect_equal(content$sidebar$width, "30%")
  })
  
  it("handles background color", {
    content <- create_content() %>%
      add_sidebar(background = "#f8f9fa") %>%
      end_sidebar()
    
    expect_equal(content$sidebar$background, "#f8f9fa")
  })
  
  it("handles border = FALSE", {
    content <- create_content() %>%
      add_sidebar(border = FALSE) %>%
      end_sidebar()
    
    expect_false(content$sidebar$border)
  })
})

# =============================================================================
# SECTION 7: CSS Class Generation
# =============================================================================

describe("input columns CSS generation", {
  
  it("generates correct grid class for columns = 2", {
    html <- dashboardr:::.generate_checkbox_html(
      input_id = "test_grid",
      label = "Options",
      filter_var = "var",
      options = c("A", "B", "C", "D"),
      default_selected = c("A"),
      width = "100%",
      align = "left",
      inline = FALSE,
      size = "md",
      help = NULL,
      disabled = FALSE,
      columns = 2
    )
    
    expect_true(grepl("grid-2", html))
  })
  
  it("generates correct grid class for columns = 3", {
    html <- dashboardr:::.generate_checkbox_html(
      input_id = "test_grid3",
      label = "Options",
      filter_var = "var",
      options = c("A", "B", "C"),
      default_selected = NULL,
      width = "100%",
      align = "left",
      inline = FALSE,
      size = "md",
      help = NULL,
      disabled = FALSE,
      columns = 3
    )
    
    expect_true(grepl("grid-3", html))
  })
  
  it("generates correct grid class for columns = 4", {
    html <- dashboardr:::.generate_checkbox_html(
      input_id = "test_grid4",
      label = "Options",
      filter_var = "var",
      options = c("A", "B", "C", "D"),
      default_selected = NULL,
      width = "100%",
      align = "left",
      inline = FALSE,
      size = "md",
      help = NULL,
      disabled = FALSE,
      columns = 4
    )
    
    expect_true(grepl("grid-4", html))
  })
  
  it("generates inline class when inline = TRUE", {
    html <- dashboardr:::.generate_checkbox_html(
      input_id = "test_inline",
      label = "Options",
      filter_var = "var",
      options = c("A", "B"),
      default_selected = NULL,
      width = "100%",
      align = "left",
      inline = TRUE,
      size = "md",
      help = NULL,
      disabled = FALSE,
      columns = NULL
    )
    
    expect_true(grepl("inline", html))
    expect_false(grepl("grid-", html))
  })
  
  it("generates radio grid class", {
    html <- dashboardr:::.generate_radio_html(
      input_id = "test_radio_grid",
      label = "Choice",
      filter_var = "var",
      options = c("X", "Y", "Z"),
      default_selected = "X",
      width = "100%",
      align = "left",
      inline = FALSE,
      size = "md",
      help = NULL,
      disabled = FALSE,
      columns = 2
    )
    
    expect_true(grepl("grid-2", html))
  })
  
  it("does not add grid class when columns is NULL", {
    html <- dashboardr:::.generate_checkbox_html(
      input_id = "test_no_grid",
      label = "Options",
      filter_var = "var",
      options = c("A", "B"),
      default_selected = NULL,
      width = "100%",
      align = "left",
      inline = FALSE,
      size = "md",
      help = NULL,
      disabled = FALSE,
      columns = NULL
    )
    
    expect_false(grepl("grid-", html))
    expect_false(grepl("inline", html))
  })
})
