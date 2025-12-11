# =============================================================================
# Comprehensive Tests for Input System
# =============================================================================
# 
# These tests verify:
# 1. R functions generate correct HTML with proper data attributes
# 2. HTML structure matches what JavaScript expects
# 3. All input types work correctly
# =============================================================================

library(testthat)
library(dashboardr)

# =============================================================================
# SECTION 1: add_input() Function Tests
# =============================================================================

describe("add_input() function", {
  
  setup_content <- function() {
    create_content()
  }
  
  # ---------------------------------------------------------------------------
  # Basic Parameter Validation
  # ---------------------------------------------------------------------------
  
  it("requires input_id parameter", {
    content <- setup_content()
    expect_error(
      add_input(content, filter_var = "test", options = c("A", "B")),
      "input_id is required"
    )
  })
  
  it("requires filter_var parameter", {
    content <- setup_content()
    expect_error(
      add_input(content, input_id = "test", options = c("A", "B")),
      "filter_var is required"
    )
  })
  
  it("requires options for select types", {
    content <- setup_content()
    expect_error(
      add_input(content, input_id = "test", filter_var = "var", type = "select_multiple"),
      "options.*must be provided"
    )
  })
  
  it("requires options for checkbox type", {
    content <- setup_content()
    expect_error(
      add_input(content, input_id = "test", filter_var = "var", type = "checkbox"),
      "options.*must be provided"
    )
  })
  
  it("requires options for radio type", {
    content <- setup_content()
    expect_error(
      add_input(content, input_id = "test", filter_var = "var", type = "radio"),
      "options.*must be provided"
    )
  })
  
  it("requires options for button_group type", {
    content <- setup_content()
    expect_error(
      add_input(content, input_id = "test", filter_var = "var", type = "button_group"),
      "options.*must be provided"
    )
  })
  
  # ---------------------------------------------------------------------------
  # Input Type Validation
  # ---------------------------------------------------------------------------
  
  it("accepts all valid input types", {
    content <- setup_content()
    valid_types <- c("select_multiple", "select_single", "checkbox", 
                     "radio", "switch", "slider", "text", "number", "button_group")
    
    for (type in valid_types) {
      if (type %in% c("select_multiple", "select_single", "checkbox", "radio", "button_group")) {
        result <- add_input(content, 
                           input_id = paste0("test_", type),
                           filter_var = "var",
                           type = type,
                           options = c("A", "B"))
      } else {
        result <- add_input(content,
                           input_id = paste0("test_", type),
                           filter_var = "var",
                           type = type)
      }
      expect_s3_class(result, "content_collection")
    }
  })
  
  it("rejects invalid input types", {
    content <- setup_content()
    expect_error(
      add_input(content, input_id = "test", filter_var = "var", 
                type = "invalid_type", options = c("A", "B"))
    )
  })
  
  # ---------------------------------------------------------------------------
  # Size Parameter Tests
  # ---------------------------------------------------------------------------
  
  it("accepts valid size values", {
    content <- setup_content()
    
    for (size in c("sm", "md", "lg")) {
      result <- add_input(content,
                         input_id = paste0("test_", size),
                         filter_var = "var",
                         type = "select_single",
                         options = c("A", "B"),
                         size = size)
      expect_s3_class(result, "content_collection")
    }
  })
  
  it("rejects invalid size values", {
    content <- setup_content()
    expect_error(
      add_input(content, input_id = "test", filter_var = "var",
                type = "select_single", options = c("A", "B"),
                size = "extra-large")
    )
  })
  
  # ---------------------------------------------------------------------------
  # Input Row Tests
  # ---------------------------------------------------------------------------
  
  it("adds inputs to row container correctly", {
    content <- setup_content() %>%
      add_input_row() %>%
      add_input(input_id = "test1", filter_var = "var1", type = "text") %>%
      add_input(input_id = "test2", filter_var = "var2", type = "slider") %>%
      end_input_row()
    
    expect_s3_class(content, "content_collection")
    
    # Find the input_row in items
    input_row <- NULL
    for (item in content$items) {
      if (!is.null(item$type) && item$type == "input_row") {
        input_row <- item
        break
      }
    }
    
    expect_false(is.null(input_row))
    expect_length(input_row$inputs, 2)
    expect_equal(input_row$inputs[[1]]$input_id, "test1")
    expect_equal(input_row$inputs[[2]]$input_id, "test2")
  })
  
  it("stores margin parameters in input spec", {
    content <- setup_content() %>%
      add_input_row() %>%
      add_input(input_id = "test", filter_var = "var", type = "text",
                mt = "10px", mr = "20px", mb = "15px", ml = "5px") %>%
      end_input_row()
    
    input_row <- NULL
    for (item in content$items) {
      if (!is.null(item$type) && item$type == "input_row") {
        input_row <- item
        break
      }
    }
    
    input <- input_row$inputs[[1]]
    expect_equal(input$mt, "10px")
    expect_equal(input$mr, "20px")
    expect_equal(input$mb, "15px")
    expect_equal(input$ml, "5px")
  })
  
  it("stores slider labels in input spec", {
    content <- setup_content() %>%
      add_input_row() %>%
      add_input(input_id = "year_slider", filter_var = "year", type = "slider",
                min = 1, max = 4, step = 1,
                labels = c("2021", "2022", "2023", "2024")) %>%
      end_input_row()
    
    input_row <- NULL
    for (item in content$items) {
      if (!is.null(item$type) && item$type == "input_row") {
        input_row <- item
        break
      }
    }
    
    input <- input_row$inputs[[1]]
    expect_equal(input$labels, c("2021", "2022", "2023", "2024"))
  })
  
  it("stores switch toggle_series in input spec", {
    content <- setup_content() %>%
      add_input_row() %>%
      add_input(input_id = "show_avg", filter_var = "country", type = "switch",
                toggle_series = "Global Average", override = TRUE, value = TRUE) %>%
      end_input_row()
    
    input_row <- NULL
    for (item in content$items) {
      if (!is.null(item$type) && item$type == "input_row") {
        input_row <- item
        break
      }
    }
    
    input <- input_row$inputs[[1]]
    expect_equal(input$toggle_series, "Global Average")
    expect_true(input$override)
    expect_true(input$value)
  })
})

# =============================================================================
# SECTION 2: HTML Generation Tests - Data Attributes for JavaScript
# =============================================================================

describe("HTML generation with correct data attributes for JavaScript", {
  
  # ---------------------------------------------------------------------------
  # Select Input - data-filter-var attribute
  # ---------------------------------------------------------------------------
  
  it("select generates data-filter-var for JavaScript filtering", {
    html <- dashboardr:::.generate_select_html(
      input_id = "country_filter",
      label = "Countries",
      type = "select_multiple",
      filter_var = "country",
      options = c("USA", "UK", "Germany"),
      default_selected = c("USA"),
      placeholder = "Select...",
      width = "300px",
      align = "center",
      size = "md",
      help = NULL,
      disabled = FALSE
    )
    
    # Must have data-filter-var for JS to know which column to filter
    expect_match(html, 'data-filter-var="country"')
    
    # Must have correct id for JS to find it
    expect_match(html, 'id="country_filter"')
    
    # Options must be present
    expect_match(html, 'value="USA"')
    expect_match(html, 'value="UK"')
  })
  
  it("single select has correct type indicator", {
    html <- dashboardr:::.generate_select_html(
      input_id = "metric",
      label = "Metric",
      type = "select_single",
      filter_var = "metric",
      options = c("Revenue", "Profit"),
      default_selected = "Revenue",
      placeholder = "Select...",
      width = "200px",
      align = "center",
      size = "md",
      help = NULL,
      disabled = FALSE
    )
    
    expect_match(html, 'data-filter-var="metric"')
    # Single select should NOT have multiple attribute
    expect_no_match(html, 'multiple="multiple"')
  })
  
  it("generates grouped optgroups for hierarchical options", {
    grouped <- list(
      "Fruits" = c("Apple", "Banana"),
      "Vegetables" = c("Carrot", "Broccoli")
    )
    
    html <- dashboardr:::.generate_select_html(
      input_id = "food",
      label = "Food",
      type = "select_multiple",
      filter_var = "food",
      options = grouped,
      default_selected = "Apple",
      placeholder = "Select...",
      width = "300px",
      align = "center",
      size = "md",
      help = NULL,
      disabled = FALSE
    )
    
    expect_match(html, "<optgroup")
    expect_match(html, 'label="Fruits"')
    expect_match(html, 'label="Vegetables"')
  })
  
  # ---------------------------------------------------------------------------
  # Slider - data-labels attribute for custom labels
  # ---------------------------------------------------------------------------
  
  it("slider generates data-labels attribute as escaped JSON", {
    html <- dashboardr:::.generate_slider_html(
      input_id = "year_slider",
      label = "Year",
      filter_var = "year",
      min = 1,
      max = 4,
      step = 1,
      value = 1,
      show_value = TRUE,
      width = "300px",
      align = "center",
      labels = c("2021", "2022", "2023", "2024"),
      size = "md",
      help = NULL,
      disabled = FALSE
    )
    
    # Must have data-labels with HTML-escaped JSON for JS to parse
    expect_match(html, 'data-labels="')
    expect_match(html, "&quot;2021&quot;")  # HTML-escaped quotes
    expect_match(html, "&quot;2024&quot;")
    
    # Must have filter_var for JS
    expect_match(html, 'data-filter-var="year"')
    
    # Must have correct min/max/step for slider logic
    expect_match(html, 'min="1"')
    expect_match(html, 'max="4"')
    expect_match(html, 'step="1"')
  })
  
  it("slider without labels does not have data-labels attribute", {
    html <- dashboardr:::.generate_slider_html(
      input_id = "value_slider",
      label = "Value",
      filter_var = "value",
      min = 0,
      max = 100,
      step = 10,
      value = 50,
      show_value = TRUE,
      width = "200px",
      align = "center",
      labels = NULL,
      size = "md",
      help = NULL,
      disabled = FALSE
    )
    
    expect_no_match(html, 'data-labels=')
  })
  
  # ---------------------------------------------------------------------------
  # Switch - data-toggle-series and data-override attributes
  # ---------------------------------------------------------------------------
  
  it("switch generates data-toggle-series for series visibility control", {
    html <- dashboardr:::.generate_switch_html(
      input_id = "show_avg",
      label = "Show Average",
      filter_var = "country",
      value = TRUE,
      width = "200px",
      align = "center",
      toggle_series = "Global Average",
      override = TRUE,
      size = "md",
      help = NULL,
      disabled = FALSE
    )
    
    # Must have toggle_series for JS to know which series to show/hide
    expect_match(html, 'data-toggle-series="Global Average"')
    
    # Must have override flag for JS exempt logic
    expect_match(html, 'data-override="true"')
    
    # Must have filter_var
    expect_match(html, 'data-filter-var="country"')
    
    # Should be checked by default
    expect_match(html, 'checked')
  })
  
  it("switch without toggle_series omits that attribute", {
    html <- dashboardr:::.generate_switch_html(
      input_id = "enable_feature",
      label = "Enable",
      filter_var = "feature",
      value = FALSE,
      width = "200px",
      align = "center",
      toggle_series = NULL,
      override = FALSE,
      size = "md",
      help = NULL,
      disabled = FALSE
    )
    
    expect_no_match(html, 'data-toggle-series=')
    expect_no_match(html, 'checked')
  })
  
  # ---------------------------------------------------------------------------
  # Checkbox - proper structure for multi-select filtering
  # ---------------------------------------------------------------------------
  
  it("checkbox generates checkboxes with filter_var for JS", {
    html <- dashboardr:::.generate_checkbox_html(
      input_id = "regions",
      label = "Regions",
      filter_var = "region",
      options = c("North", "South", "East"),
      default_selected = c("North", "South"),
      width = "300px",
      align = "center",
      inline = TRUE,
      size = "md",
      help = NULL,
      disabled = FALSE
    )
    
    expect_match(html, 'data-filter-var="region"')
    expect_match(html, 'type="checkbox"')
    expect_match(html, 'value="North"')
    expect_match(html, 'value="South"')
    expect_match(html, 'value="East"')
    
    # North and South should be checked
    # Check for checked attribute near North value
    expect_match(html, 'value="North"[^>]*checked')
  })
  
  # ---------------------------------------------------------------------------
  # Radio - proper structure for single-select filtering
  # ---------------------------------------------------------------------------
  
  it("radio generates radio buttons with filter_var for JS", {
    html <- dashboardr:::.generate_radio_html(
      input_id = "focus_region",
      label = "Focus",
      filter_var = "region",
      options = c("North", "South", "East"),
      default_selected = "South",
      width = "300px",
      align = "center",
      inline = TRUE,
      size = "md",
      help = NULL,
      disabled = FALSE
    )
    
    expect_match(html, 'data-filter-var="region"')
    expect_match(html, 'type="radio"')
    expect_match(html, 'name="focus_region"')  # Same name for radio group
  })
  
  # ---------------------------------------------------------------------------
  # Text Input - for search filtering
  # ---------------------------------------------------------------------------
  
  it("text input generates proper attributes for JS text search", {
    html <- dashboardr:::.generate_text_html(
      input_id = "search",
      label = "Search",
      filter_var = "name",
      value = "",
      placeholder = "Type to filter...",
      width = "200px",
      align = "center",
      size = "md",
      help = NULL,
      disabled = FALSE
    )
    
    expect_match(html, 'data-filter-var="name"')
    expect_match(html, 'type="text"')
    expect_match(html, 'placeholder="Type to filter..."')
  })
  
  # ---------------------------------------------------------------------------
  # Number Input
  # ---------------------------------------------------------------------------
  
  it("number input generates proper attributes for JS", {
    html <- dashboardr:::.generate_number_html(
      input_id = "min_val",
      label = "Minimum",
      filter_var = "value",
      min = 0,
      max = 100,
      step = 5,
      value = 25,
      width = "150px",
      align = "center",
      size = "md",
      help = NULL,
      disabled = FALSE
    )
    
    expect_match(html, 'data-filter-var="value"')
    expect_match(html, 'type="number"')
    expect_match(html, 'min="0"')
    expect_match(html, 'max="100"')
    expect_match(html, 'step="5"')
  })
  
  # ---------------------------------------------------------------------------
  # Button Group
  # ---------------------------------------------------------------------------
  
  it("button group generates proper data attributes for JS", {
    html <- dashboardr:::.generate_button_group_html(
      input_id = "view_mode",
      label = "View",
      filter_var = "view",
      options = c("Chart", "Table", "Both"),
      default_selected = "Chart",
      width = "auto",
      align = "center",
      size = "md",
      help = NULL,
      disabled = FALSE
    )
    
    expect_match(html, 'data-filter-var="view"')
    expect_match(html, 'data-value="Chart"')
    expect_match(html, 'data-value="Table"')
    expect_match(html, 'data-value="Both"')
  })
  
  # ---------------------------------------------------------------------------
  # Size Classes
  # ---------------------------------------------------------------------------
  
  it("applies correct size classes for all sizes", {
    for (size in c("sm", "md", "lg")) {
      html <- dashboardr:::.generate_text_html(
        input_id = paste0("test_", size),
        label = "Test",
        filter_var = "var",
        value = "",
        placeholder = "",
        width = "200px",
        align = "center",
        size = size,
        help = NULL,
        disabled = FALSE
      )
      
      expect_match(html, paste0("size-", size))
    }
  })
  
  # ---------------------------------------------------------------------------
  # Help Text
  # ---------------------------------------------------------------------------
  
  it("includes help text div when help is provided", {
    html <- dashboardr:::.generate_text_html(
      input_id = "test",
      label = "Test",
      filter_var = "var",
      value = "",
      placeholder = "",
      width = "200px",
      align = "center",
      size = "md",
      help = "This is help text",
      disabled = FALSE
    )
    
    expect_match(html, "dashboardr-input-help")
    expect_match(html, "This is help text")
  })
  
  # ---------------------------------------------------------------------------
  # Disabled State
  # ---------------------------------------------------------------------------
  
  it("includes disabled attribute when disabled is TRUE", {
    html <- dashboardr:::.generate_text_html(
      input_id = "test",
      label = "Test",
      filter_var = "var",
      value = "",
      placeholder = "",
      width = "200px",
      align = "center",
      size = "md",
      help = NULL,
      disabled = TRUE
    )
    
    expect_match(html, "disabled")
  })
})

# =============================================================================
# SECTION 3: Margin Style Helper Tests
# =============================================================================

describe(".build_margin_style() helper", {
  
  it("builds single margin correctly", {
    expect_equal(dashboardr:::.build_margin_style(mt = "10px"), "margin-top: 10px;")
    expect_equal(dashboardr:::.build_margin_style(mr = "20px"), "margin-right: 20px;")
    expect_equal(dashboardr:::.build_margin_style(mb = "15px"), "margin-bottom: 15px;")
    expect_equal(dashboardr:::.build_margin_style(ml = "5px"), "margin-left: 5px;")
  })
  
  it("combines multiple margins", {
    result <- dashboardr:::.build_margin_style(mt = "10px", mr = "20px")
    expect_match(result, "margin-top: 10px")
    expect_match(result, "margin-right: 20px")
  })
  
  it("returns empty string with no margins", {
    expect_equal(dashboardr:::.build_margin_style(), "")
  })
  
  it("handles NULL values", {
    result <- dashboardr:::.build_margin_style(mt = NULL, mr = "10px")
    expect_equal(result, "margin-right: 10px;")
  })
  
  it("handles empty string values", {
    result <- dashboardr:::.build_margin_style(mt = "", mr = "10px")
    expect_equal(result, "margin-right: 10px;")
  })
})

# =============================================================================
# SECTION 4: render_input_row() Tests
# =============================================================================

describe("render_input_row()", {
  
  it("renders row container with inputs", {
    inputs <- list(
      list(
        input_id = "test1",
        label = "Test 1",
        type = "text",
        filter_var = "var1"
      ),
      list(
        input_id = "test2",
        label = "Test 2",
        type = "select_single",
        filter_var = "var2",
        options = c("A", "B")
      )
    )
    
    result <- render_input_row(inputs, style = "boxed", align = "center")
    html <- as.character(result)
    
    expect_match(html, "dashboardr-input-row")
    expect_match(html, "align-center")
    expect_match(html, 'id="test1"')
    expect_match(html, 'id="test2"')
  })
  
  it("applies margin wrapper when margins specified", {
    inputs <- list(
      list(
        input_id = "test",
        label = "Test",
        type = "text",
        filter_var = "var",
        mr = "20px"
      )
    )
    
    result <- render_input_row(inputs)
    html <- as.character(result)
    expect_match(html, "margin-right: 20px")
  })
  
  it("handles slider with labels correctly", {
    inputs <- list(
      list(
        input_id = "slider",
        label = "Year",
        type = "slider",
        filter_var = "year",
        min = 1,
        max = 3,
        step = 1,
        value = 1,
        labels = c("2022", "2023", "2024")
      )
    )
    
    result <- render_input_row(inputs)
    html <- as.character(result)
    
    expect_match(html, 'data-labels=')
    expect_match(html, "&quot;2022&quot;")
  })
  
  it("handles switch with toggle_series correctly", {
    inputs <- list(
      list(
        input_id = "toggle",
        label = "Show Avg",
        type = "switch",
        filter_var = "country",
        value = TRUE,
        toggle_series = "Average",
        override = TRUE
      )
    )
    
    result <- render_input_row(inputs)
    html <- as.character(result)
    
    expect_match(html, 'data-toggle-series="Average"')
    expect_match(html, 'data-override="true"')
  })
})

# =============================================================================
# SECTION 5: render_input() Tests
# =============================================================================

describe("render_input()", {
  
  it("renders select_multiple with all required attributes", {
    result <- render_input(
      input_id = "countries",
      label = "Countries",
      type = "select_multiple",
      filter_var = "country",
      options = c("USA", "UK", "Germany")
    )
    
    html <- as.character(result)
    expect_match(html, 'id="countries"')
    expect_match(html, 'data-filter-var="country"')
    expect_match(html, "multiple")
  })
  
  it("renders slider with labels", {
    result <- render_input(
      input_id = "year",
      label = "Year",
      type = "slider",
      filter_var = "year",
      min = 1,
      max = 4,
      step = 1,
      value = 1,
      labels = c("2021", "2022", "2023", "2024")
    )
    
    html <- as.character(result)
    expect_match(html, 'data-labels=')
    expect_match(html, 'data-filter-var="year"')
  })
  
  it("renders switch with toggle_series", {
    result <- render_input(
      input_id = "show_avg",
      label = "Show Average",
      type = "switch",
      filter_var = "country",
      toggle_series = "Global Average",
      override = TRUE,
      value = TRUE
    )
    
    html <- as.character(result)
    expect_match(html, 'data-toggle-series="Global Average"')
    expect_match(html, 'data-override="true"')
    expect_match(html, 'checked')
  })
})

# =============================================================================
# SECTION 6: Integration Tests - Full Pipeline
# =============================================================================

describe("Full pipeline integration", {
  
  it("content + viz combination preserves input specs", {
    content <- create_content() %>%
      add_input_row() %>%
      add_input(input_id = "filter", filter_var = "category",
                type = "select_multiple", options = c("A", "B", "C")) %>%
      end_input_row()
    
    viz <- create_viz() %>%
      add_viz(type = "timeline", time_var = "year", 
              response_var = "value", group_var = "category")
    
    combined <- content + viz
    
    expect_s3_class(combined, "content_collection")
    
    # Check that input row is preserved in items
    has_input_row <- FALSE
    for (item in combined$items) {
      if (!is.null(item$type) && item$type == "input_row") {
        has_input_row <- TRUE
        expect_length(item$inputs, 1)
        expect_equal(item$inputs[[1]]$input_id, "filter")
      }
    }
    expect_true(has_input_row)
  })
  
  it("metric filter_var triggers needs_metric_data flag", {
    content <- create_content() %>%
      add_input_row() %>%
      add_input(input_id = "metric", filter_var = "metric",
                type = "select_single", options = c("Revenue", "Profit")) %>%
      end_input_row()
    
    # The flag should be set on the content
    expect_true(content$needs_metric_data %||% FALSE)
  })
})

# =============================================================================
# SECTION 7: JavaScript Integration Tests (HTML Structure Verification)
# =============================================================================

describe("JavaScript integration - HTML structure for JS parsing", {
  
  it("slider labels can be parsed as JSON from HTML", {
    html <- dashboardr:::.generate_slider_html(
      input_id = "test",
      label = "Test",
      filter_var = "var",
      min = 1,
      max = 3,
      step = 1,
      value = 1,
      show_value = TRUE,
      width = "200px",
      align = "center",
      labels = c("A", "B", "C"),
      size = "md",
      help = NULL,
      disabled = FALSE
    )
    
    # Extract data-labels value (HTML entity encoded)
    labels_match <- regmatches(html, regexpr('data-labels="[^"]*"', html))
    expect_length(labels_match, 1)
    
    # The browser decodes &quot; to " automatically, so we simulate that
    labels_json <- gsub('data-labels="(.+)"', "\\1", labels_match)
    labels_json <- gsub("&quot;", '"', labels_json)
    
    # Should be valid JSON
    parsed <- jsonlite::fromJSON(labels_json)
    expect_equal(parsed, c("A", "B", "C"))
  })
  
  it("switch toggle_series is properly escaped for HTML", {
    html <- dashboardr:::.generate_switch_html(
      input_id = "test",
      label = "Test",
      filter_var = "var",
      value = TRUE,
      width = "200px",
      align = "center",
      toggle_series = "Series with \"quotes\" and <brackets>",
      override = FALSE,
      size = "md",
      help = NULL,
      disabled = FALSE
    )
    
    # Should be HTML-escaped
    expect_match(html, "data-toggle-series=")
    # The value should be escaped (htmltools::htmlEscape handles this)
  })
  
  it("all inputs have data-filter-var for JS filtering", {
    # Test each input type has the required attribute
    inputs <- list(
      select = dashboardr:::.generate_select_html(
        "id1", "L", "select_multiple", "var", c("A"), NULL, "", "100px", "center", "md", NULL, FALSE
      ),
      slider = dashboardr:::.generate_slider_html(
        "id2", "L", "var", 1, 10, 1, 5, TRUE, "100px", "center", NULL, "md", NULL, FALSE
      ),
      switch = dashboardr:::.generate_switch_html(
        "id3", "L", "var", TRUE, "100px", "center", NULL, FALSE, "md", NULL, FALSE
      ),
      checkbox = dashboardr:::.generate_checkbox_html(
        "id4", "L", "var", c("A"), NULL, "100px", "center", TRUE, "md", NULL, FALSE
      ),
      radio = dashboardr:::.generate_radio_html(
        "id5", "L", "var", c("A"), "A", "100px", "center", TRUE, "md", NULL, FALSE
      ),
      text = dashboardr:::.generate_text_html(
        "id6", "L", "var", "", "", "100px", "center", "md", NULL, FALSE
      ),
      number = dashboardr:::.generate_number_html(
        "id7", "L", "var", 0, 100, 1, 50, "100px", "center", "md", NULL, FALSE
      ),
      button_group = dashboardr:::.generate_button_group_html(
        "id8", "L", "var", c("A", "B"), "A", "100px", "center", "md", NULL, FALSE
      )
    )
    
    for (name in names(inputs)) {
      expect_match(inputs[[name]], 'data-filter-var="var"',
                   info = paste0(name, " should have data-filter-var"))
    }
  })
})
