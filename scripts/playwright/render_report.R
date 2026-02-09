#!/usr/bin/env Rscript

parse_args <- function(args) {
  out <- list(results = NULL, output = NULL, run_id = NULL)
  i <- 1
  while (i <= length(args)) {
    key <- args[[i]]
    if (!startsWith(key, "--")) {
      stop("Unexpected argument: ", key, call. = FALSE)
    }
    key <- sub("^--", "", key)
    if (i == length(args)) stop("Missing value for --", key, call. = FALSE)
    value <- args[[i + 1]]
    i <- i + 2

    if (!key %in% names(out)) {
      stop("Unknown argument: --", key, call. = FALSE)
    }
    out[[key]] <- value
  }

  if (is.null(out$results) || !nzchar(out$results)) stop("--results is required", call. = FALSE)
  if (is.null(out$output) || !nzchar(out$output)) stop("--output is required", call. = FALSE)
  out
}

html_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x
}

link_or_dash <- function(path, label = NULL) {
  if (is.null(path) || !nzchar(path)) return("-")
  lab <- if (is.null(label)) basename(path) else label
  sprintf("<a href=\"%s\">%s</a>", html_escape(path), html_escape(lab))
}

collapse_failures <- function(x) {
  if (is.null(x) || !length(x)) return("-")
  paste(vapply(x, html_escape, character(1)), collapse = "<br>")
}

as_df <- function(results) {
  if (!length(results)) {
    return(data.frame(
      id = character(0),
      status = character(0),
      backend = character(0),
      source_type = character(0),
      url = character(0),
      local_file_url = character(0),
      local_file_path = character(0),
      duration_ms = numeric(0),
      screenshot = character(0),
      console_log = character(0),
      stringsAsFactors = FALSE
    ))
  }

  rows <- lapply(results, function(x) {
    list(
      id = x$id %||% "",
      status = x$status %||% "fail",
      backend = x$backend %||% "",
      source_type = x$source_type %||% "",
      url = x$url %||% "",
      local_file_url = x$local_file_url %||% "",
      local_file_path = x$local_file_path %||% "",
      duration_ms = x$duration_ms %||% NA_real_,
      screenshot = x$screenshot %||% "",
      console_log = x$console_log %||% "",
      failures = x$failures %||% list()
    )
  })

  data.frame(
    id = vapply(rows, `[[`, character(1), "id"),
    status = vapply(rows, `[[`, character(1), "status"),
    backend = vapply(rows, `[[`, character(1), "backend"),
    source_type = vapply(rows, `[[`, character(1), "source_type"),
    url = vapply(rows, `[[`, character(1), "url"),
    local_file_url = vapply(rows, `[[`, character(1), "local_file_url"),
    local_file_path = vapply(rows, `[[`, character(1), "local_file_path"),
    duration_ms = as.numeric(vapply(rows, `[[`, numeric(1), "duration_ms")),
    screenshot = vapply(rows, `[[`, character(1), "screenshot"),
    console_log = vapply(rows, `[[`, character(1), "console_log"),
    stringsAsFactors = FALSE
  )
}

`%||%` <- function(x, y) if (is.null(x)) y else x

main <- function() {
  opts <- parse_args(commandArgs(trailingOnly = TRUE))
  payload <- jsonlite::fromJSON(opts$results, simplifyVector = FALSE)

  results <- payload$results %||% list()
  df <- as_df(results)

  run_id <- opts$run_id %||% payload$run_id %||% "playwright-run"
  started_at <- payload$started_at %||% ""
  finished_at <- payload$finished_at %||% ""
  mode <- payload$mode %||% ""

  total_n <- nrow(df)
  pass_n <- sum(df$status == "pass", na.rm = TRUE)
  fail_n <- sum(df$status != "pass", na.rm = TRUE)

  by_backend <- if (total_n) {
    aggregate(list(total = df$id, failed = df$status != "pass"), by = list(backend = df$backend), FUN = function(x) {
      if (is.logical(x)) sum(x, na.rm = TRUE) else length(x)
    })
  } else {
    data.frame(backend = character(0), total = integer(0), failed = integer(0), stringsAsFactors = FALSE)
  }

  failure_categories <- unlist(lapply(results, function(x) {
    f <- x$failures %||% character(0)
    if (!length(f)) return(character(0))
    sub(":.*$", "", as.character(f))
  }))
  failure_table <- if (length(failure_categories)) {
    tab <- sort(table(failure_categories), decreasing = TRUE)
    data.frame(
      category = names(tab),
      count = as.integer(tab),
      stringsAsFactors = FALSE
    )
  } else {
    data.frame(category = character(0), count = integer(0), stringsAsFactors = FALSE)
  }

  detail_rows <- character(0)
  if (length(results)) {
    for (r in results) {
      detail_rows <- c(detail_rows, sprintf(
        paste0(
          "<tr>",
          "<td>%s</td>",
          "<td>%s</td>",
          "<td>%s</td>",
          "<td>%s</td>",
          "<td>%s</td>",
          "<td>%s</td>",
          "<td>%s</td>",
          "<td>%s</td>",
          "<td>%s</td>",
          "</tr>"
        ),
        html_escape(r$id %||% ""),
        html_escape(r$status %||% "fail"),
        html_escape(r$backend %||% ""),
        html_escape(r$source_type %||% ""),
        html_escape(as.character(r$duration_ms %||% "")),
        link_or_dash(r$screenshot, "screenshot"),
        link_or_dash(r$console_log, "console"),
        link_or_dash(if (!is.null(r$local_file_url) && nzchar(r$local_file_url)) r$local_file_url else (r$url %||% ""), "scenario"),
        collapse_failures(r$failures)
      ))
    }
  }

  backend_rows <- character(0)
  if (nrow(by_backend)) {
    backend_rows <- vapply(seq_len(nrow(by_backend)), function(i) {
      row <- by_backend[i, , drop = FALSE]
      sprintf(
        "<tr><td>%s</td><td>%s</td><td>%s</td></tr>",
        html_escape(as.character(row$backend[[1]])),
        html_escape(as.character(row$total[[1]])),
        html_escape(as.character(row$failed[[1]]))
      )
    }, character(1))
  }

  failure_rows <- character(0)
  if (nrow(failure_table)) {
    failure_rows <- vapply(seq_len(nrow(failure_table)), function(i) {
      row <- failure_table[i, , drop = FALSE]
      sprintf(
        "<tr><td>%s</td><td>%s</td></tr>",
        html_escape(as.character(row$category[[1]])),
        html_escape(as.character(row$count[[1]]))
      )
    }, character(1))
  }

  html <- c(
    "<!doctype html>",
    "<html>",
    "<head>",
    "<meta charset='utf-8'>",
    "<title>Dashboardr Playwright Report</title>",
    "<style>",
    "body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; margin: 24px; color: #111827; }",
    "h1, h2 { margin: 0 0 10px 0; }",
    "h2 { margin-top: 24px; }",
    ".meta { color: #4b5563; margin-bottom: 16px; }",
    ".stats { display: flex; gap: 12px; margin-bottom: 16px; }",
    ".card { border: 1px solid #e5e7eb; border-radius: 8px; padding: 12px 14px; min-width: 120px; }",
    ".ok { border-color: #10b981; }",
    ".bad { border-color: #ef4444; }",
    "table { border-collapse: collapse; width: 100%; margin-top: 8px; }",
    "th, td { border: 1px solid #e5e7eb; padding: 8px; vertical-align: top; font-size: 13px; }",
    "th { background: #f9fafb; text-align: left; }",
    "code { background: #f3f4f6; padding: 2px 4px; border-radius: 4px; }",
    "</style>",
    "</head>",
    "<body>",
    sprintf("<h1>Dashboardr Playwright Report: %s</h1>", html_escape(run_id)),
    sprintf("<div class='meta'>Mode: <code>%s</code> | Started: <code>%s</code> | Finished: <code>%s</code></div>",
            html_escape(mode), html_escape(started_at), html_escape(finished_at)),
    "<div class='stats'>",
    sprintf("<div class='card'>Total<br><strong>%s</strong></div>", total_n),
    sprintf("<div class='card ok'>Passed<br><strong>%s</strong></div>", pass_n),
    sprintf("<div class='card %s'>Failed<br><strong>%s</strong></div>", if (fail_n > 0) "bad" else "ok", fail_n),
    "</div>",
    "<h2>By Backend</h2>",
    "<table><thead><tr><th>Backend</th><th>Total</th><th>Failed</th></tr></thead><tbody>",
    if (length(backend_rows)) backend_rows else "<tr><td colspan='3'>No scenarios</td></tr>",
    "</tbody></table>",
    "<h2>Failure Categories</h2>",
    "<table><thead><tr><th>Category</th><th>Count</th></tr></thead><tbody>",
    if (length(failure_rows)) failure_rows else "<tr><td colspan='2'>No failures</td></tr>",
    "</tbody></table>",
    "<h2>Scenario Details</h2>",
    "<table><thead><tr><th>ID</th><th>Status</th><th>Backend</th><th>Source</th><th>Duration (ms)</th><th>Screenshot</th><th>Console</th><th>Scenario URL</th><th>Failures</th></tr></thead><tbody>",
    if (length(detail_rows)) detail_rows else "<tr><td colspan='9'>No scenario results</td></tr>",
    "</tbody></table>",
    "</body>",
    "</html>"
  )

  dir.create(dirname(opts$output), recursive = TRUE, showWarnings = FALSE)
  writeLines(html, opts$output, useBytes = TRUE)
}

main()
