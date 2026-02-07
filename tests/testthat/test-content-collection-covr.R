# Tests for content_collection.R — lightweight, covr-safe
# Targets ALL add_*() functions that build data structures (no HTML rendering)
library(testthat)

# --- create_content ---

test_that("create_content returns a content/viz collection", {
 cc <- create_content()
 expect_true(inherits(cc, "viz_collection") || inherits(cc, "content_collection"))
})

test_that("create_content with data argument", {
 cc <- create_content(data = mtcars)
 expect_true(!is.null(cc))
})

test_that("create_content with tabgroup_labels", {
 cc <- create_content(tabgroup_labels = list("Tab1" = "First Tab"))
 expect_true(!is.null(cc))
})

# --- add_text ---

test_that("add_text standalone mode (NULL first arg)", {
 block <- add_text(text = "Hello world")
 expect_s3_class(block, "content_block")
 expect_equal(block$type, "text")
 expect_equal(block$content, "Hello world")
})

test_that("add_text standalone with string as first arg", {
 block <- add_text("# Title")
 expect_s3_class(block, "content_block")
 expect_equal(block$content, "# Title")
})

test_that("add_text piped to content collection", {
 cc <- create_content()
 cc2 <- add_text(cc, "Some text")
 expect_true(length(cc2$items) == 1)
 expect_equal(cc2$items[[1]]$type, "text")
})

test_that("add_text with multiple text arguments via ...", {
 cc <- create_content()
 cc2 <- add_text(cc, "Line 1", "Line 2", "Line 3")
 expect_true(grepl("Line 1", cc2$items[[1]]$content))
 expect_true(grepl("Line 3", cc2$items[[1]]$content))
})

test_that("add_text with tabgroup", {
 cc <- create_content()
 cc2 <- add_text(cc, "Tab content", tabgroup = "MyTab")
 expect_true(!is.null(cc2$items[[1]]$tabgroup))
})

test_that("add_text chaining multiple texts", {
 cc <- create_content() |>
   add_text("First") |>
   add_text("Second") |>
   add_text("Third")
 expect_equal(length(cc$items), 3)
})

# --- add_image ---

test_that("add_image standalone", {
 block <- add_image(src = "test.png")
 expect_s3_class(block, "content_block")
 expect_equal(block$type, "image")
 expect_equal(block$src, "test.png")
})

test_that("add_image with all options", {
 block <- add_image(src = "photo.jpg", alt = "A photo", caption = "My photo",
                    width = "300px", height = "200px", align = "left",
                    link = "https://example.com", class = "rounded")
 expect_equal(block$alt, "A photo")
 expect_equal(block$caption, "My photo")
 expect_equal(block$width, "300px")
 expect_equal(block$align, "left")
 expect_equal(block$link, "https://example.com")
})

test_that("add_image piped to collection", {
 cc <- create_content() |>
   add_image(src = "img.png", alt = "test")
 expect_equal(length(cc$items), 1)
 expect_equal(cc$items[[1]]$type, "image")
})

test_that("add_image with tabgroup", {
 cc <- create_content() |>
   add_image(src = "a.png", tabgroup = "Photos")
 expect_true(!is.null(cc$items[[1]]$tabgroup))
})

test_that("add_image error: empty src", {
 expect_error(add_image(src = ""), "non-empty")
})

test_that("add_image error: invalid alt", {
 expect_error(add_image(src = "x.png", alt = 123), "character string")
})

# --- add_callout ---

test_that("add_callout basic", {
 cc <- create_content() |>
   add_callout("This is important", type = "warning")
 expect_equal(cc$items[[1]]$type, "callout")
 expect_equal(cc$items[[1]]$callout_type, "warning")
})

test_that("add_callout with title and collapse", {
 cc <- create_content() |>
   add_callout("Content", type = "tip", title = "Pro Tip", collapse = TRUE)
 expect_equal(cc$items[[1]]$title, "Pro Tip")
 expect_true(cc$items[[1]]$collapse)
})

test_that("add_callout all types", {
 types <- c("note", "tip", "warning", "caution", "important")
 for (t in types) {
   cc <- create_content() |>
     add_callout("text", type = t)
   expect_equal(cc$items[[1]]$callout_type, t)
 }
})

test_that("add_callout with tabgroup", {
 cc <- create_content() |>
   add_callout("msg", type = "note", tabgroup = "Info")
 expect_true(!is.null(cc$items[[1]]$tabgroup))
})

# --- add_divider ---

test_that("add_divider basic", {
 cc <- create_content() |> add_divider()
 expect_equal(cc$items[[1]]$type, "divider")
 expect_equal(cc$items[[1]]$style, "default")
})

test_that("add_divider with styles", {
 for (s in c("default", "thick", "dashed", "dotted")) {
   cc <- create_content() |> add_divider(style = s)
   expect_equal(cc$items[[1]]$style, s)
 }
})

test_that("add_divider with tabgroup", {
 cc <- create_content() |> add_divider(tabgroup = "Section")
 expect_true(!is.null(cc$items[[1]]$tabgroup))
})

# --- add_code ---

test_that("add_code basic", {
 cc <- create_content() |>
   add_code("x <- 1 + 1")
 expect_equal(cc$items[[1]]$type, "code")
 expect_equal(cc$items[[1]]$language, "r")
})

test_that("add_code with language and caption", {
 cc <- create_content() |>
   add_code("print('hello')", language = "python", caption = "Example")
 expect_equal(cc$items[[1]]$language, "python")
 expect_equal(cc$items[[1]]$caption, "Example")
})

test_that("add_code with filename", {
 cc <- create_content() |>
   add_code("code here", filename = "script.R")
 expect_equal(cc$items[[1]]$filename, "script.R")
})

# --- add_spacer ---

test_that("add_spacer basic", {
 cc <- create_content() |> add_spacer()
 expect_equal(cc$items[[1]]$type, "spacer")
 expect_equal(cc$items[[1]]$height, "2rem")
})

test_that("add_spacer custom height", {
 cc <- create_content() |> add_spacer(height = "50px")
 expect_equal(cc$items[[1]]$height, "50px")
})

# --- add_gt ---

test_that("add_gt with data frame", {
 cc <- create_content() |>
   add_gt(head(mtcars), caption = "Cars")
 expect_equal(cc$items[[1]]$type, "gt")
 expect_true(cc$items[[1]]$is_dataframe)
 expect_equal(cc$items[[1]]$caption, "Cars")
})

test_that("add_gt with tabgroup", {
 cc <- create_content() |>
   add_gt(iris[1:5, ], tabgroup = "Tables")
 expect_true(!is.null(cc$items[[1]]$tabgroup))
})

# --- add_reactable ---

test_that("add_reactable with data frame", {
 cc <- create_content() |>
   add_reactable(head(mtcars))
 expect_equal(cc$items[[1]]$type, "reactable")
 expect_true(cc$items[[1]]$is_dataframe)
})

test_that("add_reactable with tabgroup", {
 cc <- create_content() |>
   add_reactable(iris[1:5, ], tabgroup = "Data")
 expect_true(!is.null(cc$items[[1]]$tabgroup))
})

# --- add_table ---

test_that("add_table basic", {
 cc <- create_content() |>
   add_table(head(mtcars), caption = "Motor Cars")
 expect_equal(cc$items[[1]]$type, "table")
 expect_equal(cc$items[[1]]$caption, "Motor Cars")
})

# --- add_DT ---

test_that("add_DT with data frame", {
 cc <- create_content() |>
   add_DT(head(mtcars), options = list(pageLength = 5))
 expect_equal(cc$items[[1]]$type, "DT")
 expect_equal(cc$items[[1]]$options$pageLength, 5)
})

test_that("add_DT with tabgroup", {
 cc <- create_content() |>
   add_DT(iris[1:5, ], tabgroup = "Tables")
 expect_true(!is.null(cc$items[[1]]$tabgroup))
})

# --- add_hc ---

test_that("add_hc with highcharter object", {
 hc <- highcharter::highchart() |>
   highcharter::hc_add_series(data = 1:5)
 cc <- create_content() |>
   add_hc(hc)
 expect_equal(cc$items[[1]]$type, "hc")
})

test_that("add_hc with height option", {
 hc <- highcharter::highchart()
 cc <- create_content() |>
   add_hc(hc, height = "500px")
 expect_equal(cc$items[[1]]$height, "500px")
})

test_that("add_hc error: not a highcharter object", {
 expect_error(
   create_content() |> add_hc("not a chart"),
   "highcharter"
 )
})

# --- add_video ---

test_that("add_video basic", {
 cc <- create_content() |>
   add_video(src = "https://example.com/video.mp4")
 expect_equal(cc$items[[1]]$type, "video")
 expect_equal(cc$items[[1]]$url, "https://example.com/video.mp4")
})

test_that("add_video with caption and dimensions", {
 cc <- create_content() |>
   add_video(src = "vid.mp4", caption = "Demo", width = "640", height = "480")
 expect_equal(cc$items[[1]]$caption, "Demo")
 expect_equal(cc$items[[1]]$width, "640")
})

# --- add_iframe ---

test_that("add_iframe basic", {
 cc <- create_content() |>
   add_iframe(src = "https://example.com")
 expect_equal(cc$items[[1]]$type, "iframe")
 expect_equal(cc$items[[1]]$height, "500px")
 expect_equal(cc$items[[1]]$width, "100%")
})

test_that("add_iframe custom dimensions", {
 cc <- create_content() |>
   add_iframe(src = "https://example.com", height = "800px", width = "50%")
 expect_equal(cc$items[[1]]$height, "800px")
 expect_equal(cc$items[[1]]$width, "50%")
})

# --- add_accordion ---

test_that("add_accordion basic", {
 cc <- create_content() |>
   add_accordion(title = "Details", text = "Hidden content")
 expect_equal(cc$items[[1]]$type, "accordion")
 expect_equal(cc$items[[1]]$title, "Details")
 expect_false(cc$items[[1]]$open)
})

test_that("add_accordion starts open", {
 cc <- create_content() |>
   add_accordion(title = "Details", text = "Content", open = TRUE)
 expect_true(cc$items[[1]]$open)
})

# --- add_card ---

test_that("add_card basic", {
 cc <- create_content() |>
   add_card(text = "Card body")
 expect_equal(cc$items[[1]]$type, "card")
 expect_equal(cc$items[[1]]$text, "Card body")
})

test_that("add_card with title and footer", {
 cc <- create_content() |>
   add_card(text = "Body", title = "Card Title", footer = "Footer text")
 expect_equal(cc$items[[1]]$title, "Card Title")
 expect_equal(cc$items[[1]]$footer, "Footer text")
})

# --- add_html ---

test_that("add_html basic", {
 cc <- create_content() |>
   add_html("<div class='custom'>Hello</div>")
 expect_equal(cc$items[[1]]$type, "html")
 expect_true(grepl("custom", cc$items[[1]]$html))
})

# --- add_quote ---

test_that("add_quote basic", {
 cc <- create_content() |>
   add_quote("To be or not to be")
 expect_equal(cc$items[[1]]$type, "quote")
 expect_equal(cc$items[[1]]$quote, "To be or not to be")
})

test_that("add_quote with attribution and cite", {
 cc <- create_content() |>
   add_quote("Knowledge is power", attribution = "Francis Bacon",
             cite = "https://example.com")
 expect_equal(cc$items[[1]]$attribution, "Francis Bacon")
 expect_equal(cc$items[[1]]$cite, "https://example.com")
})

# --- add_badge ---

test_that("add_badge basic", {
 cc <- create_content() |>
   add_badge("Active", color = "success")
 expect_equal(cc$items[[1]]$type, "badge")
})

# --- add_metric ---

test_that("add_metric basic", {
 cc <- create_content() |>
   add_metric(title = "Users", value = "1,234")
 expect_equal(cc$items[[1]]$type, "metric")
})

# --- add_value_box ---

test_that("add_value_box basic", {
 cc <- create_content() |>
   add_value_box(title = "Revenue", value = "$1M")
 expect_equal(cc$items[[1]]$type, "value_box")
 expect_equal(cc$items[[1]]$title, "Revenue")
 expect_equal(cc$items[[1]]$value, "$1M")
})

test_that("add_value_box with all options", {
 cc <- create_content() |>
   add_value_box(title = "Growth", value = "+23%",
                 logo_url = "logo.png", logo_text = "Logo",
                 bg_color = "#ff0000", description = "Year over year",
                 description_title = "Source")
 item <- cc$items[[1]]
 expect_equal(item$logo_url, "logo.png")
 expect_equal(item$bg_color, "#ff0000")
 expect_equal(item$description, "Year over year")
})

# --- add_value_box_row / end_value_box_row ---

test_that("value_box_row pipeline", {
 cc <- create_content() |>
   add_value_box_row() |>
     add_value_box(title = "A", value = "1") |>
     add_value_box(title = "B", value = "2") |>
     add_value_box(title = "C", value = "3") |>
   end_value_box_row()
 expect_equal(length(cc$items), 1)
 expect_equal(cc$items[[1]]$type, "value_box_row")
 expect_equal(length(cc$items[[1]]$boxes), 3)
})

test_that("end_value_box_row error without container", {
 expect_error(end_value_box_row("not_a_container"), "value_box_row_container")
})

# --- add_sidebar / end_sidebar ---

test_that("add_sidebar creates sidebar_container", {
 cc <- create_content()
 sc <- add_sidebar(cc)
 expect_true(inherits(sc, "sidebar_container"))
})

test_that("add_sidebar with options", {
 cc <- create_content()
 sc <- add_sidebar(cc, width = "300px", position = "right",
                   title = "Filters", background = "#f0f0f0",
                   padding = "1.5rem", border = FALSE, open = FALSE)
 expect_equal(sc$width, "300px")
 expect_equal(sc$position, "right")
 expect_equal(sc$title, "Filters")
})

test_that("sidebar pipeline with content blocks", {
 cc <- create_content() |>
   add_sidebar(width = "200px") |>
     add_text("### Filters") |>
     add_divider() |>
     add_spacer(height = "10px") |>
   end_sidebar()
 # After end_sidebar, we should have the parent collection back
 expect_true(inherits(cc, "content_collection") || inherits(cc, "viz_collection"))
})

# --- Complex pipelines ---

test_that("complex mixed content pipeline", {
 cc <- create_content() |>
   add_text("# Report Title") |>
   add_divider() |>
   add_text("## Introduction") |>
   add_image(src = "banner.png", alt = "Banner") |>
   add_callout("Important note", type = "warning") |>
   add_code("library(dashboardr)", language = "r") |>
   add_spacer() |>
   add_table(head(mtcars)) |>
   add_quote("Data is the new oil") |>
   add_divider(style = "dashed") |>
   add_accordion(title = "More Info", text = "Details here") |>
   add_card(text = "Summary card", title = "Summary") |>
   add_html("<hr/>")
 expect_equal(length(cc$items), 13)
})

test_that("content with tabgroups", {
 cc <- create_content() |>
   add_text("Tab 1 content", tabgroup = "Tab1") |>
   add_text("Tab 2 content", tabgroup = "Tab2") |>
   add_callout("Note", type = "note", tabgroup = "Tab1") |>
   add_divider(tabgroup = "Tab2")
 expect_equal(length(cc$items), 4)
})

test_that("add_text content_block wrapping", {
 # When first arg is a content_block, it should wrap in collection
 block <- add_text(text = "First")
 result <- add_text(block, "Second")
 expect_true(inherits(result, "viz_collection") || inherits(result, "content_collection"))
 expect_equal(length(result$items), 2)
})

# --- Sidebar with callout, accordion, card, html ---

test_that("sidebar with callout", {
 cc <- create_content()
 sc <- add_sidebar(cc)
 sc <- add_callout(sc, "Warning!", type = "warning")
 expect_equal(length(sc$blocks), 1)
 expect_equal(sc$blocks[[1]]$type, "callout")
})

test_that("sidebar with accordion", {
 cc <- create_content()
 sc <- add_sidebar(cc)
 sc <- add_accordion(sc, title = "FAQ", text = "Answer")
 expect_equal(sc$blocks[[1]]$type, "accordion")
})

test_that("sidebar with card", {
 cc <- create_content()
 sc <- add_sidebar(cc)
 sc <- add_card(sc, text = "Card", title = "Title")
 expect_equal(sc$blocks[[1]]$type, "card")
})

test_that("sidebar with html", {
 cc <- create_content()
 sc <- add_sidebar(cc)
 sc <- add_html(sc, "<b>Bold</b>")
 expect_equal(sc$blocks[[1]]$type, "html")
})

test_that("sidebar with image", {
 cc <- create_content()
 sc <- add_sidebar(cc)
 sc <- add_image(sc, src = "logo.png")
 expect_equal(sc$blocks[[1]]$type, "image")
})
