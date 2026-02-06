# =============================================================================
# Tests for show_when (Conditional Visibility) System
# =============================================================================
#
# These tests verify:
# 1. show_when_open() / show_when_close() helpers produce correct HTML
# 2. .parse_show_when() converts R formulas to correct JSON conditions
# 3. .generate_single_viz() emits show_when wrapper calls correctly
# 4. .generate_global_setup_chunk() includes fallback definitions when needed
# 5. show_when.js integration expectations (HTML structure)
# =============================================================================

library(testthat)
library(dashboardr)

# =============================================================================
# SECTION 1: show_when_open() / show_when_close() Helpers
# =============================================================================

describe("show_when_open()", {

  it("emits a div with data-show-when attribute", {
    json <- '{"var":"time_period","op":"in","val":["2022","2024"]}'
    out <- capture.output(show_when_open(json))
    expect_length(out, 1)
    expect_match(out, '<div class="viz-show-when"', fixed = TRUE)
    expect_match(out, "data-show-when='", fixed = TRUE)
    expect_match(out, json, fixed = TRUE)
  })

  it("wraps JSON in single quotes so double-quoted JSON is safe", {
    json <- '{"var":"x","op":"eq","val":"hello"}'
    out <- capture.output(show_when_open(json))
    # The JSON contains double quotes; the attribute uses single quotes
    expect_match(out, paste0("data-show-when='", json, "'>"), fixed = TRUE)
  })

  it("handles complex nested JSON conditions", {
    json <- '{"op":"and","conditions":[{"var":"a","op":"eq","val":"1"},{"var":"b","op":"neq","val":"2"}]}'
    out <- capture.output(show_when_open(json))
    expect_match(out, json, fixed = TRUE)
  })
})

describe("show_when_close()", {

  it("emits a closing div tag", {
    out <- capture.output(show_when_close())
    expect_length(out, 1)
    expect_equal(trimws(out), "</div>")
  })
})

describe("show_when_open / show_when_close round-trip", {

  it("produces well-formed HTML when used together", {
    json <- '{"var":"wave","op":"eq","val":"1"}'
    out <- capture.output({
      show_when_open(json)
      cat("<p>content</p>\n")
      show_when_close()
    })
    html <- paste(out, collapse = "\n")
    # Opening tag, some content, closing tag
    expect_match(html, '<div class="viz-show-when"', fixed = TRUE)
    expect_match(html, "<p>content</p>", fixed = TRUE)
    expect_match(html, "</div>", fixed = TRUE)
  })
})

# =============================================================================
# SECTION 2: .parse_show_when() (Formula → JSON)
# =============================================================================

describe(".parse_show_when()", {

  parse <- dashboardr:::.parse_show_when

  it("returns NULL for NULL input", {
    expect_null(parse(NULL))
  })

  it("errors on non-formula input", {
    expect_error(parse("not a formula"), "formula")
  })

  it("parses equality operator", {
    json <- as.character(parse(~ status == "active"))
    parsed <- jsonlite::fromJSON(json)
    expect_equal(parsed$var, "status")
    expect_equal(parsed$op, "eq")
    expect_equal(parsed$val, "active")
  })

  it("parses inequality operator", {
    json <- as.character(parse(~ status != "deleted"))
    parsed <- jsonlite::fromJSON(json)
    expect_equal(parsed$var, "status")
    expect_equal(parsed$op, "neq")
    expect_equal(parsed$val, "deleted")
  })

  it("parses %in% operator", {
    json <- as.character(parse(~ time_period %in% c("2022", "2024")))
    parsed <- jsonlite::fromJSON(json)
    expect_equal(parsed$var, "time_period")
    expect_equal(parsed$op, "in")
    expect_equal(parsed$val, c("2022", "2024"))
  })

  it("parses AND conditions", {
    json <- as.character(parse(~ status == "active" & wave == "1"))
    parsed <- jsonlite::fromJSON(json)
    expect_equal(parsed$op, "and")
    # jsonlite converts the conditions array to a data.frame (cols = var, op, val)
    expect_equal(nrow(parsed$conditions), 2)
    expect_true("status" %in% parsed$conditions$var)
    expect_true("wave" %in% parsed$conditions$var)
  })

  it("parses OR conditions", {
    json <- as.character(parse(~ status == "a" | status == "b"))
    parsed <- jsonlite::fromJSON(json)
    expect_equal(parsed$op, "or")
    expect_equal(nrow(parsed$conditions), 2)
  })

  it("parses comparison operators (>, <, >=, <=)", {
    json_gt <- as.character(parse(~ score > 50))
    parsed_gt <- jsonlite::fromJSON(json_gt)
    expect_equal(parsed_gt$op, "gt")
    expect_equal(parsed_gt$val, 50)

    json_lt <- as.character(parse(~ year < 2020))
    parsed_lt <- jsonlite::fromJSON(json_lt)
    expect_equal(parsed_lt$op, "lt")
    expect_equal(parsed_lt$val, 2020)

    json_gte <- as.character(parse(~ age >= 18))
    parsed_gte <- jsonlite::fromJSON(json_gte)
    expect_equal(parsed_gte$op, "gte")
    expect_equal(parsed_gte$val, 18)

    json_lte <- as.character(parse(~ score <= 100))
    parsed_lte <- jsonlite::fromJSON(json_lte)
    expect_equal(parsed_lte$op, "lte")
    expect_equal(parsed_lte$val, 100)
  })

  it("errors on truly unsupported operators", {
    expect_error(parse(~ x %% 5), "Unsupported operator")
  })
})

# =============================================================================
# SECTION 3: .generate_single_viz() show_when wrapper emission
# =============================================================================

describe("viz chunk generation with show_when", {

  gen_viz <- dashboardr:::.generate_single_viz

  it("does not add results: asis or show_when calls when show_when is NULL", {
    spec <- list(
      viz_type = "stackedbar",
      title    = "Test Chart",
      x_var    = "x",
      y_var    = "y"
    )
    lines <- gen_viz("test_viz", spec)
    combined <- paste(lines, collapse = "\n")
    expect_false(grepl("results.*asis", combined))
    expect_false(grepl("show_when_open", combined))
    expect_false(grepl("show_when_close", combined))
  })

  it("adds results: asis and show_when_open/close when show_when is set", {
    spec <- list(
      viz_type  = "stackedbar",
      title     = "Test Chart",
      x_var     = "x",
      y_var     = "y",
      show_when = ~ wave %in% c("1", "2")
    )
    lines <- gen_viz("test_viz", spec)
    combined <- paste(lines, collapse = "\n")
    expect_match(combined, "results.*asis", perl = TRUE)
    expect_match(combined, "show_when_open(", fixed = TRUE)
    expect_match(combined, "show_when_close()", fixed = TRUE)
  })

  it("embeds correct JSON inside show_when_open call", {
    spec <- list(
      viz_type  = "stackedbar",
      title     = "Test Chart",
      x_var     = "x",
      y_var     = "y",
      show_when = ~ time_period == "Over Time"
    )
    lines <- gen_viz("test_viz", spec)
    combined <- paste(lines, collapse = "\n")
    # The JSON should be single-quoted in the generated R code
    expect_match(combined, "show_when_open('", fixed = TRUE)
    # Verify the JSON content is valid
    open_line <- lines[grep("show_when_open", lines)]
    json_str <- sub(".*show_when_open\\('(.+)'\\).*", "\\1", open_line)
    parsed <- jsonlite::fromJSON(json_str)
    expect_equal(parsed$var, "time_period")
    expect_equal(parsed$op, "eq")
    expect_equal(parsed$val, "Over Time")
  })

  it("show_when_open appears before viz code and show_when_close after", {
    spec <- list(
      viz_type  = "stackedbar",
      title     = "Test Chart",
      x_var     = "x",
      y_var     = "y",
      show_when = ~ wave == "1"
    )
    lines <- gen_viz("test_viz", spec)
    open_idx  <- grep("show_when_open", lines)
    close_idx <- grep("show_when_close", lines)
    viz_idx   <- grep("viz_stackedbar", lines)

    expect_length(open_idx, 1)
    expect_length(close_idx, 1)
    expect_true(length(viz_idx) > 0)
    # open before viz, close after
    expect_true(open_idx[1] < min(viz_idx))
    expect_true(close_idx[1] > max(viz_idx))
  })

  it("does not pass show_when to the viz function itself", {
    spec <- list(
      viz_type  = "stackedbar",
      title     = "Test Chart",
      x_var     = "x",
      y_var     = "y",
      show_when = ~ wave == "1"
    )
    lines <- gen_viz("test_viz", spec)
    # The show_when param should NOT appear as an argument to viz_stackedbar()
    # (it's listed in the excluded params)
    viz_lines <- lines[grep("viz_stackedbar", lines):length(lines)]
    viz_call <- paste(viz_lines, collapse = "\n")
    # show_when should only appear in show_when_open(), not as a parameter
    matches <- gregexpr("show_when", viz_call)[[1]]
    open_matches <- gregexpr("show_when_open|show_when_close", viz_call)
    # Every occurrence of "show_when" should be part of show_when_open/close
    # i.e. show_when should not appear as a standalone parameter
    # Simplest check: "show_when =" should not appear
    expect_false(grepl("show_when\\s*=", viz_call))
  })
})

# =============================================================================
# SECTION 4: Setup Chunk Fallback Definitions
# =============================================================================

describe("global setup chunk show_when fallback", {

  gen_setup <- dashboardr:::.generate_global_setup_chunk

  it("includes show_when helper fallback when page needs_show_when = TRUE", {
    page <- list(needs_show_when = TRUE)
    lines <- gen_setup(page)
    combined <- paste(lines, collapse = "\n")
    expect_match(combined, "show_when_open", fixed = TRUE)
    expect_match(combined, "show_when_close", fixed = TRUE)
    expect_match(combined, "if (!exists(", fixed = TRUE)
  })

  it("does NOT include show_when fallback when needs_show_when is FALSE", {
    page <- list(needs_show_when = FALSE)
    lines <- gen_setup(page)
    combined <- paste(lines, collapse = "\n")
    expect_false(grepl("show_when_open", combined))
  })

  it("does NOT include show_when fallback when needs_show_when is NULL", {
    page <- list()
    lines <- gen_setup(page)
    combined <- paste(lines, collapse = "\n")
    expect_false(grepl("show_when_open", combined))
  })

  it("fallback defines both show_when_open and show_when_close", {
    page <- list(needs_show_when = TRUE)
    lines <- gen_setup(page)
    combined <- paste(lines, collapse = "\n")
    # Both functions should be defined in the fallback block
    expect_match(combined, "show_when_open", fixed = TRUE)
    expect_match(combined, "show_when_close", fixed = TRUE)
    expect_match(combined, "function", fixed = TRUE)
  })
})

# =============================================================================
# SECTION 5: HTML Structure Contract (for show_when.js)
# =============================================================================

describe("show_when HTML structure contract", {

  it("uses the CSS class 'viz-show-when' that show_when.js queries", {
    json <- '{"var":"x","op":"eq","val":"1"}'
    out <- capture.output(show_when_open(json))
    # show_when.js does: document.querySelectorAll('[data-show-when]')
    expect_match(out, 'class="viz-show-when"', fixed = TRUE)
    expect_match(out, "data-show-when=", fixed = TRUE)
  })

  it("data-show-when attribute contains valid JSON", {
    json <- '{"var":"time_period","op":"in","val":["Wave 1","Wave 2"]}'
    out <- capture.output(show_when_open(json))
    # Extract the JSON from the attribute
    attr_val <- sub(".*data-show-when='([^']+)'.*", "\\1", out)
    parsed <- jsonlite::fromJSON(attr_val)
    expect_equal(parsed$var, "time_period")
    expect_equal(parsed$op, "in")
    expect_equal(parsed$val, c("Wave 1", "Wave 2"))
  })
})

# =============================================================================
# SECTION 6: Edge Cases
# =============================================================================

describe("show_when edge cases", {

  it("handles single-value %in% correctly", {
    json <- as.character(dashboardr:::.parse_show_when(~ x %in% c("only_one")))
    parsed <- jsonlite::fromJSON(json)
    expect_equal(parsed$op, "in")
    expect_equal(parsed$val, "only_one")
  })

  it("handles numeric values in conditions", {
    json <- as.character(dashboardr:::.parse_show_when(~ year == 2024))
    parsed <- jsonlite::fromJSON(json)
    expect_equal(parsed$val, 2024)
  })

  it("handles values with spaces", {
    json <- as.character(dashboardr:::.parse_show_when(~ category %in% c("Wave 1", "Over Time")))
    parsed <- jsonlite::fromJSON(json)
    expect_equal(parsed$val, c("Wave 1", "Over Time"))
    # Also verify the generated HTML handles spaces correctly
    out <- capture.output(show_when_open(json))
    expect_match(out, "Wave 1", fixed = TRUE)
    expect_match(out, "Over Time", fixed = TRUE)
  })

  it("multiple viz chunks with different show_when conditions stay independent", {
    gen_viz <- dashboardr:::.generate_single_viz

    spec1 <- list(
      viz_type = "stackedbar", title = "A", x_var = "x", y_var = "y",
      show_when = ~ wave == "1"
    )
    spec2 <- list(
      viz_type = "timeline", title = "B", time_var = "t", y_var = "y",
      show_when = ~ wave == "Over Time"
    )

    lines1 <- gen_viz("viz1", spec1)
    lines2 <- gen_viz("viz2", spec2)

    # Each should have exactly one open and one close
    expect_equal(sum(grepl("show_when_open", lines1)), 1)
    expect_equal(sum(grepl("show_when_close", lines1)), 1)
    expect_equal(sum(grepl("show_when_open", lines2)), 1)
    expect_equal(sum(grepl("show_when_close", lines2)), 1)

    # They should contain different JSON
    open1 <- lines1[grep("show_when_open", lines1)]
    open2 <- lines2[grep("show_when_open", lines2)]
    expect_false(identical(open1, open2))
  })
})
