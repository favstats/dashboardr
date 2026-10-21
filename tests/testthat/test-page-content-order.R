# Direct page items (add_text/add_callout) must keep their position relative
# to collections added with add_content()

.page_qmd <- function(page) {
  out <- tempfile("dash_order_")
  on.exit(unlink(out, recursive = TRUE), add = TRUE)
  d <- create_dashboard(title = "t", output_dir = out) |> add_pages(page)
  suppressMessages(invisible(capture.output(generate_dashboard(d, render = FALSE))))
  readLines(file.path(out, "test.qmd"))
}

test_that("callout added to a page after add_content() appears after the content", {
  df <- data.frame(a = c("x", "y", "z"), b = c("p", "q", "r"))
  cc <- create_content(data = df, type = "bar") |>
    add_viz(x_var = "a", tabgroup = "A") |>
    add_viz(x_var = "b", tabgroup = "B")

  page <- create_page("Test", data = df) |>
    add_text("HEADER_TEXT") |>
    add_content(cc) |>
    add_callout("BOTTOM_NOTE", type = "tip")

  q <- .page_qmd(page)
  header <- grep("HEADER_TEXT", q)[1]
  tabset <- grep("panel-tabset", q)[1]
  note <- grep("BOTTOM_NOTE", q)[1]
  expect_true(header < tabset)
  expect_true(tabset < note)
})

test_that("page items interleave with multiple content collections", {
  df <- data.frame(a = c("x", "y", "z"), b = c("p", "q", "r"))
  c1 <- create_content(data = df, type = "bar") |> add_viz(x_var = "a", tabgroup = "A")
  c2 <- create_content(data = df, type = "bar") |> add_viz(x_var = "b", tabgroup = "B")

  page <- create_page("Test", data = df) |>
    add_text("FIRST_TEXT") |>
    add_content(c1) |>
    add_text("MIDDLE_TEXT") |>
    add_content(c2) |>
    add_text("LAST_TEXT")

  q <- .page_qmd(page)
  pos <- c(
    grep("FIRST_TEXT", q)[1],
    grep('x_var = "a"', q)[1],
    grep("MIDDLE_TEXT", q)[1],
    grep('x_var = "b"', q)[1],
    grep("LAST_TEXT", q)[1]
  )
  expect_false(anyNA(pos))
  expect_equal(order(pos), seq_along(pos))
})

test_that("add_callout() on a page without type uses a single default type", {
  page <- create_page("Test") |> add_callout("NOTE_TEXT")
  q <- .page_qmd(page)
  expect_length(grep("^::: \\{\\.callout-", q), 1)
  expect_true(any(grepl("callout-note", q, fixed = TRUE)))
})
