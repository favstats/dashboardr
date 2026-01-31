# =================================================================
# Extended tests for add_* content functions
# =================================================================

# --- add_video() ---
test_that("add_video works in pipeline", {
  content <- create_content() %>%
    add_text("Watch this:") %>%
    add_video(src = "demo.mp4", caption = "Demo")
  
  expect_length(content$items, 2)
  expect_equal(content$items[[2]]$type, "video")
})

test_that("add_video with all parameters in pipeline", {
  content <- create_content() %>%
    add_video(
      src = "video.mp4",
      caption = "Demo video",
      width = "800px",
      height = "450px"
    )
  
  block <- content$items[[1]]
  # src may be stored as 'src' or 'url' depending on implementation
  expect_true(!is.null(block$src) || !is.null(block$url) || !is.null(block$video_src))
  expect_equal(block$type, "video")
})

test_that("add_video with tabgroup in pipeline", {
  content <- create_content() %>%
    add_video(src = "vid.mp4", tabgroup = "media")
  
  expect_equal(content$items[[1]]$tabgroup, "media")
})

# --- add_iframe() ---
test_that("add_iframe works in pipeline", {
  content <- create_content() %>%
    add_text("Embedded content:") %>%
    add_iframe(src = "https://example.com/embed")
  
  expect_length(content$items, 2)
  expect_equal(content$items[[2]]$type, "iframe")
})

test_that("add_iframe with dimensions in pipeline", {
  content <- create_content() %>%
    add_iframe(
      src = "https://example.com",
      height = "600px",
      width = "100%"
    )
  
  block <- content$items[[1]]
  expect_equal(block$height, "600px")
  expect_equal(block$width, "100%")
})

# --- add_quote() ---
test_that("add_quote works in pipeline", {
  content <- create_content() %>%
    add_text("Here's a famous quote:") %>%
    add_quote(quote = "Stay hungry, stay foolish.", attribution = "Steve Jobs")
  
  expect_length(content$items, 2)
  expect_equal(content$items[[2]]$type, "quote")
})

test_that("add_quote with attribution and cite in pipeline", {
  content <- create_content() %>%
    add_quote(
      quote = "The only thing we have to fear is fear itself.",
      attribution = "Franklin D. Roosevelt",
      cite = "First Inaugural Address"
    )
  
  block <- content$items[[1]]
  expect_equal(block$quote, "The only thing we have to fear is fear itself.")
  expect_equal(block$attribution, "Franklin D. Roosevelt")
  expect_equal(block$cite, "First Inaugural Address")
})

# --- add_badge() ---
test_that("add_badge works in pipeline", {
  content <- create_content() %>%
    add_text("Status: ") %>%
    add_badge(text = "Active", color = "success")
  
  expect_length(content$items, 2)
  expect_equal(content$items[[2]]$type, "badge")
})

test_that("add_badge with color in pipeline", {
  content <- create_content() %>%
    add_badge(text = "Important", color = "danger")
  
  expect_equal(content$items[[1]]$text, "Important")
  expect_equal(content$items[[1]]$color, "danger")
})

test_that("add_badge default color is primary in pipeline", {
  content <- create_content() %>%
    add_badge(text = "Test")
  
  expect_equal(content$items[[1]]$color, "primary")
})

# --- add_metric() ---
test_that("add_metric works in pipeline", {
  content <- create_content() %>%
    add_metric(value = "500", title = "Customers") %>%
    add_metric(value = "85%", title = "Satisfaction")
  
  expect_length(content$items, 2)
  expect_equal(content$items[[1]]$type, "metric")
  expect_equal(content$items[[2]]$type, "metric")
})

test_that("add_metric with all parameters in pipeline", {
  content <- create_content() %>%
    add_metric(
      value = "$50,000",
      title = "Revenue",
      icon = "dollar",
      color = "#28a745",
      subtitle = "+15% from last month"
    )
  
  block <- content$items[[1]]
  expect_equal(block$value, "$50,000")
  expect_equal(block$title, "Revenue")
  expect_equal(block$icon, "dollar")
  expect_equal(block$color, "#28a745")
  expect_equal(block$subtitle, "+15% from last month")
})

# --- add_value_box() ---
test_that("add_value_box works in value_box_row pipeline", {
  content <- create_content() %>%
    add_value_box_row() %>%
    add_value_box(title = "Total Sales", value = "$1,000,000") %>%
    end_value_box_row()
  
  expect_s3_class(content, "content_collection")
})

test_that("add_value_box with logo_url in pipeline", {
  content <- create_content() %>%
    add_value_box_row() %>%
    add_value_box(
      title = "Users",
      value = "5,000",
      logo_url = "users.png",
      bg_color = "#3498db"
    ) %>%
    end_value_box_row()
  
  expect_s3_class(content, "content_collection")
})

test_that("add_value_box with logo_text in pipeline", {
  content <- create_content() %>%
    add_value_box_row() %>%
    add_value_box(
      title = "Revenue",
      value = "$100K",
      logo_text = "$$"
    ) %>%
    end_value_box_row()
  
  expect_s3_class(content, "content_collection")
})

# --- add_html() ---
test_that("add_html works in pipeline", {
  content <- create_content() %>%
    add_text("Custom HTML below:") %>%
    add_html(html = "<div class='custom'>Hello</div>")
  
  expect_length(content$items, 2)
  expect_equal(content$items[[2]]$type, "html")
  expect_true(grepl("custom", content$items[[2]]$html))
})

# --- add_accordion() ---
test_that("add_accordion works in pipeline", {
  content <- create_content() %>%
    add_accordion(title = "Q1", text = "A1") %>%
    add_accordion(title = "Q2", text = "A2")
  
  expect_length(content$items, 2)
  expect_equal(content$items[[1]]$type, "accordion")
  expect_equal(content$items[[2]]$type, "accordion")
})

test_that("add_accordion with open = TRUE in pipeline", {
  content <- create_content() %>%
    add_accordion(title = "FAQ", text = "Answer text", open = TRUE)
  
  expect_true(content$items[[1]]$open)
})

# --- add_card() ---
test_that("add_card works in pipeline", {
  content <- create_content() %>%
    add_card(text = "Card 1", title = "First") %>%
    add_card(text = "Card 2", title = "Second")
  
  expect_length(content$items, 2)
  expect_equal(content$items[[1]]$type, "card")
})

test_that("add_card with footer in pipeline", {
  content <- create_content() %>%
    add_card(text = "Content", title = "Title", footer = "Last updated: 2024")
  
  expect_equal(content$items[[1]]$footer, "Last updated: 2024")
})

# --- add_callout() ---
test_that("add_callout creates callout block", {
  content <- create_content() %>%
    add_callout(text = "Important notice", type = "warning")
  
  block <- content$items[[1]]
  expect_equal(block$type, "callout")
  # Text is stored in either text or content field
  expect_true(isTRUE(block$text == "Important notice") || isTRUE(block$content == "Important notice"))
})

test_that("add_callout supports different types", {
  types <- c("note", "tip", "warning", "caution", "important")
  
  for (callout_type in types) {
    content <- create_content() %>%
      add_callout(text = "Test", type = callout_type)
    
    expect_equal(content$items[[1]]$callout_type, callout_type,
                 info = paste("Failed for type:", callout_type))
  }
})

# --- add_divider() ---
test_that("add_divider creates divider block", {
  content <- create_content() %>%
    add_divider()
  
  expect_equal(content$items[[1]]$type, "divider")
})

test_that("add_divider with style", {
  content <- create_content() %>%
    add_divider(style = "thick")
  
  expect_equal(content$items[[1]]$style, "thick")
})

# --- add_code() ---
test_that("add_code creates code block", {
  content <- create_content() %>%
    add_code(code = "x <- 1:10", language = "r")
  
  block <- content$items[[1]]
  expect_equal(block$type, "code")
  expect_equal(block$code, "x <- 1:10")
  expect_equal(block$language, "r")
})

test_that("add_code with caption and filename", {
  content <- create_content() %>%
    add_code(
      code = "print('hello')",
      language = "python",
      caption = "Simple example",
      filename = "hello.py"
    )
  
  block <- content$items[[1]]
  expect_equal(block$caption, "Simple example")
  expect_equal(block$filename, "hello.py")
})

# --- add_spacer() ---
test_that("add_spacer creates spacer block", {
  content <- create_content() %>%
    add_spacer()
  
  expect_equal(content$items[[1]]$type, "spacer")
})

test_that("add_spacer with custom height", {
  content <- create_content() %>%
    add_spacer(height = "5rem")
  
  expect_equal(content$items[[1]]$height, "5rem")
})

test_that("add_spacer default height is 2rem", {
  content <- create_content() %>%
    add_spacer()
  
  expect_equal(content$items[[1]]$height, "2rem")
})

# --- add_table() ---
test_that("add_table creates table block", {
  tbl <- data.frame(x = 1:3, y = c("a", "b", "c"))
  
  content <- create_content() %>%
    add_table(table_object = tbl)
  
  expect_equal(content$items[[1]]$type, "table")
})

test_that("add_table with caption", {
  tbl <- data.frame(x = 1:3)
  
  content <- create_content() %>%
    add_table(table_object = tbl, caption = "Sample data")
  
  expect_equal(content$items[[1]]$caption, "Sample data")
})

# --- Chaining multiple content types ---
test_that("complex content pipeline works", {
  content <- create_content() %>%
    add_text("# Welcome") %>%
    add_divider() %>%
    add_callout(text = "Note: Read carefully", type = "note") %>%
    add_code(code = "library(dashboardr)", language = "r") %>%
    add_spacer() %>%
    add_quote(quote = "Code is poetry", attribution = "Unknown") %>%
    add_accordion(title = "Details", text = "More info") %>%
    add_badge(text = "New", color = "success")
  
  expect_length(content$items, 8)
  expect_equal(content$items[[1]]$type, "text")
  expect_equal(content$items[[2]]$type, "divider")
  expect_equal(content$items[[3]]$type, "callout")
  expect_equal(content$items[[4]]$type, "code")
  expect_equal(content$items[[5]]$type, "spacer")
  expect_equal(content$items[[6]]$type, "quote")
  expect_equal(content$items[[7]]$type, "accordion")
  expect_equal(content$items[[8]]$type, "badge")
})

# --- Mixing viz and content ---
test_that("viz and content can be mixed in pipeline", {
  content <- create_viz() %>%
    add_viz(type = "histogram", x_var = "mpg") %>%
    add_text("Analysis complete") %>%
    add_callout(text = "Key finding", type = "tip") %>%
    add_viz(type = "bar", x_var = "cyl")
  
  expect_s3_class(content, "content_collection")
  expect_length(content$items, 4)
})
