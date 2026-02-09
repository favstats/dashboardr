#!/usr/bin/env Rscript

parse_args <- function(args) {
  out <- list(
    results = NULL,
    status_json = NULL,
    status_md = NULL,
    status_html = NULL
  )

  i <- 1
  while (i <= length(args)) {
    key <- args[[i]]
    if (!startsWith(key, "--")) {
      stop("Unexpected argument: ", key, call. = FALSE)
    }
    key <- sub("^--", "", key)
    if (i == length(args)) {
      stop("Missing value for --", key, call. = FALSE)
    }
    value <- args[[i + 1]]
    i <- i + 2

    if (!key %in% names(out)) {
      stop("Unknown argument: --", key, call. = FALSE)
    }
    out[[key]] <- value
  }

  required <- c("results", "status_json", "status_md", "status_html")
  missing <- required[!nzchar(unlist(out[required]))]
  if (length(missing)) {
    stop("Missing required args: ", paste(missing, collapse = ", "), call. = FALSE)
  }

  out
}

`%||%` <- function(x, y) if (is.null(x)) y else x

ensure_pkgs <- function() {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Package 'jsonlite' is required.", call. = FALSE)
  }
}

as_char <- function(x, default = "") {
  if (is.null(x) || length(x) == 0L) return(default)
  as.character(x[[1]])
}

sanitize_id <- function(x) {
  out <- gsub("[^A-Za-z0-9._-]+", "_", as_char(x))
  if (!nzchar(out)) out <- "scenario"
  out
}

escape_html <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x
}

read_json_or_default <- function(path, default) {
  if (!file.exists(path)) return(default)
  tryCatch(
    jsonlite::fromJSON(path, simplifyVector = FALSE),
    error = function(e) default
  )
}

rel_link <- function(run_id, rel_path) {
  run <- as_char(run_id)
  rel <- as_char(rel_path)
  if (!nzchar(run) || !nzchar(rel)) return("")
  paste0("./", run, "/", rel)
}

md_link <- function(label, href) {
  if (!nzchar(as_char(href))) return("")
  sprintf("[%s](%s)", label, href)
}

merge_status <- function(prev, run_results) {
  now_utc <- format(Sys.time(), tz = "UTC", usetz = TRUE)
  run_id <- as_char(run_results$run_id, default = "unknown-run")
  mode <- as_char(run_results$mode, default = "unknown-mode")
  finished_at <- as_char(run_results$finished_at, default = now_utc)

  prev_entries <- prev$scenarios %||% list()
  entry_map <- setNames(prev_entries, vapply(prev_entries, function(x) as_char(x$id), FUN.VALUE = character(1)))

  if (length(entry_map)) {
    for (nm in names(entry_map)) {
      entry_map[[nm]]$seen_in_latest_run <- FALSE
    }
  }

  run_items <- run_results$results %||% list()
  for (res in run_items) {
    id <- as_char(res$id, default = "")
    if (!nzchar(id)) next

    current <- entry_map[[id]] %||% list(id = id)
    status <- if (identical(as_char(res$status), "pass")) "pass" else "fail"
    tested_at <- as_char(res$ended_at, default = finished_at)
    safe_id <- sanitize_id(id)

    screenshot_rel <- as_char(res$screenshot)
    if (!nzchar(screenshot_rel)) {
      screenshot_rel <- paste0("screenshots/", safe_id, ".png")
    }

    console_rel <- as_char(res$console_log)
    run_log_rel <- as_char(res$run_log)
    failures <- res$failures %||% list()
    failures_chr <- unlist(failures, use.names = FALSE)
    failures_chr <- failures_chr[nzchar(failures_chr)]

    current$id <- id
    current$backend <- as_char(res$backend, default = as_char(current$backend))
    current$source_type <- as_char(res$source_type, default = as_char(current$source_type))
    current$url <- as_char(res$url, default = as_char(current$url))
    current$local_file_url <- as_char(res$local_file_url, default = as_char(current$local_file_url))
    current$local_file_path <- as_char(res$local_file_path, default = as_char(current$local_file_path))
    current$current_status <- status
    current$current_failures <- as.list(failures_chr)
    current$latest_failure_count <- as.integer(length(failures_chr))
    current$latest_interaction_count <- as.integer(length(res$interaction_results %||% list()))
    current$last_tested_at <- tested_at
    current$last_tested_run_id <- run_id
    current$last_duration_ms <- as.integer(res$duration_ms %||% NA_integer_)
    current$seen_in_latest_run <- TRUE
    current$total_runs <- as.integer(current$total_runs %||% 0L) + 1L

    current$last_artifacts <- list(
      screenshot_rel = screenshot_rel,
      console_rel = console_rel,
      run_log_rel = run_log_rel,
      report_rel = "report.html",
      results_rel = "results.json"
    )

    if (identical(status, "pass")) {
      current$last_passed_at <- tested_at
      current$last_passed_run_id <- run_id
      current$total_pass <- as.integer(current$total_pass %||% 0L) + 1L
      current$total_fail <- as.integer(current$total_fail %||% 0L)
    } else {
      current$last_failed_at <- tested_at
      current$last_failed_run_id <- run_id
      current$last_failed_failures <- as.list(failures_chr)
      current$total_fail <- as.integer(current$total_fail %||% 0L) + 1L
      current$total_pass <- as.integer(current$total_pass %||% 0L)
    }

    entry_map[[id]] <- current
  }

  entries <- unname(entry_map)
  entries <- entries[order(vapply(entries, function(x) as_char(x$id), FUN.VALUE = character(1)))]

  pass_count <- sum(vapply(run_items, function(x) identical(as_char(x$status), "pass"), FUN.VALUE = logical(1)))
  fail_count <- length(run_items) - pass_count

  list(
    generated_at = now_utc,
    latest_run = list(
      run_id = run_id,
      mode = mode,
      finished_at = finished_at,
      total = length(run_items),
      pass = pass_count,
      fail = fail_count
    ),
    scenarios = entries
  )
}

list_to_df <- function(entries) {
  if (!length(entries)) {
    return(data.frame(
      id = character(0),
      backend = character(0),
      source_type = character(0),
      current_status = character(0),
      last_tested_at = character(0),
      last_tested_run_id = character(0),
      last_passed_at = character(0),
      last_failed_at = character(0),
      last_failed_failures_text = character(0),
      url = character(0),
      local_file_url = character(0),
      local_file_path = character(0),
      scenario_href = character(0),
      failures_text = character(0),
      latest_failure_count = integer(0),
      latest_interaction_count = integer(0),
      screenshot_href = character(0),
      report_href = character(0),
      results_href = character(0),
      console_href = character(0),
      run_log_href = character(0),
      seen_in_latest_run = logical(0),
      total_runs = integer(0),
      total_pass = integer(0),
      total_fail = integer(0),
      stringsAsFactors = FALSE
    ))
  }

  rows <- lapply(entries, function(x) {
    run_id <- as_char(x$last_tested_run_id)
    artifacts <- x$last_artifacts %||% list()
    fail_vec <- unlist(x$current_failures %||% list(), use.names = FALSE)
    fail_vec <- fail_vec[nzchar(fail_vec)]
    last_fail_vec <- unlist(x$last_failed_failures %||% list(), use.names = FALSE)
    last_fail_vec <- last_fail_vec[nzchar(last_fail_vec)]

    data.frame(
      id = as_char(x$id),
      backend = as_char(x$backend),
      source_type = as_char(x$source_type),
      current_status = as_char(x$current_status),
      last_tested_at = as_char(x$last_tested_at),
      last_tested_run_id = run_id,
      last_passed_at = as_char(x$last_passed_at),
      last_failed_at = as_char(x$last_failed_at),
      last_failed_failures_text = paste(last_fail_vec, collapse = " | "),
      url = as_char(x$url),
      local_file_url = as_char(x$local_file_url),
      local_file_path = as_char(x$local_file_path),
      scenario_href = if (nzchar(as_char(x$local_file_url))) as_char(x$local_file_url) else as_char(x$url),
      failures_text = paste(fail_vec, collapse = " | "),
      latest_failure_count = as.integer(x$latest_failure_count %||% 0L),
      latest_interaction_count = as.integer(x$latest_interaction_count %||% 0L),
      screenshot_href = rel_link(run_id, as_char(artifacts$screenshot_rel)),
      report_href = rel_link(run_id, as_char(artifacts$report_rel)),
      results_href = rel_link(run_id, as_char(artifacts$results_rel)),
      console_href = rel_link(run_id, as_char(artifacts$console_rel)),
      run_log_href = rel_link(run_id, as_char(artifacts$run_log_rel)),
      seen_in_latest_run = isTRUE(x$seen_in_latest_run),
      total_runs = as.integer(x$total_runs %||% 0L),
      total_pass = as.integer(x$total_pass %||% 0L),
      total_fail = as.integer(x$total_fail %||% 0L),
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, rows)
  rank <- ifelse(out$current_status == "pass", 0L, 1L)
  out[order(rank, out$backend, out$id), , drop = FALSE]
}

render_markdown <- function(status, path) {
  df <- list_to_df(status$scenarios %||% list())
  passing <- df[df$current_status == "pass", , drop = FALSE]
  failing <- df[df$current_status != "pass", , drop = FALSE]

  lines <- c(
    "# Playwright Running Status",
    "",
    sprintf("- Last updated: `%s`", as_char(status$generated_at)),
    sprintf(
      "- Latest run: `%s` (mode `%s`) | total `%s` | pass `%s` | fail `%s`",
      as_char(status$latest_run$run_id),
      as_char(status$latest_run$mode),
      as_char(status$latest_run$total),
      as_char(status$latest_run$pass),
      as_char(status$latest_run$fail)
    ),
    "- Quick links:",
    "  - [Latest Report](./latest/report.html)",
    "  - [Latest Results JSON](./latest/results.json)",
    "  - [Latest Running Status HTML](./running-status.html)",
    ""
  )

  block <- function(title, data) {
    out <- c(title, "")
    if (!nrow(data)) {
      out <- c(out, "_No scenarios._", "")
      return(out)
    }
    out <- c(
      out,
      "| Scenario | Backend | Last Tested (UTC) | Screenshot | Report | Console | Page |",
      "| --- | --- | --- | --- | --- | --- | --- |"
    )
    for (i in seq_len(nrow(data))) {
      row <- data[i, , drop = FALSE]
      out <- c(
        out,
        sprintf(
          "| `%s` | `%s` | `%s` | %s | %s | %s | %s |",
          row$id,
          row$backend,
          row$last_tested_at,
          md_link("image", row$screenshot_href),
          md_link("report", row$report_href),
          md_link("console", row$console_href),
          md_link("page", row$scenario_href)
        )
      )
    }
    c(out, "")
  }

  lines <- c(lines, block("## Currently Passing", passing), block("## Currently Failing", failing))
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, con = path, useBytes = TRUE)
}

render_html <- function(status, path) {
  df <- list_to_df(status$scenarios %||% list())
  backends <- sort(unique(df$backend))
  sources <- sort(unique(df$source_type))

  option_html <- function(values) {
    if (!length(values)) return("")
    paste(vapply(values, function(v) sprintf("<option value='%s'>%s</option>", escape_html(v), escape_html(v)), FUN.VALUE = character(1)), collapse = "")
  }

  card_html <- function(row) {
    display_status <- if (identical(row$current_status, "pass")) "pass" else "fail"
    status_class <- display_status
    status_label <- if (identical(display_status, "pass")) "PASS" else "FAIL"
    fail_block <- ""
    if (identical(display_status, "fail") && nzchar(row$failures_text)) {
      fail_block <- sprintf("<div class='fail-reason'>%s</div>", escape_html(row$failures_text))
    }

    screenshot_block <- if (nzchar(row$screenshot_href)) {
      sprintf(
        "<a class='thumb' href='%s' target='_blank'><img src='%s' alt='%s screenshot' loading='lazy'></a>",
        escape_html(row$screenshot_href),
        escape_html(row$screenshot_href),
        escape_html(row$id)
      )
    } else {
      "<div class='thumb missing'>No screenshot</div>"
    }

    link_btn <- function(label, href) {
      if (!nzchar(href)) return("")
      sprintf("<a class='btn' href='%s' target='_blank'>%s</a>", escape_html(href), escape_html(label))
    }

    links <- paste(
      link_btn("Screenshot", row$screenshot_href),
      link_btn("Run Report", row$report_href),
      link_btn("Run Results", row$results_href),
      link_btn("Console", row$console_href),
      link_btn("Run Log", row$run_log_href),
      link_btn("Scenario URL", row$scenario_href),
      collapse = ""
    )

    sprintf(
      paste0(
        "<article class='card %s' data-id='%s' data-status='%s' data-backend='%s' data-source='%s' data-latest='%s' data-fail='%s'>",
        "<div class='card-head'><span class='badge %s'>%s</span><code class='scenario-id'>%s</code></div>",
        "%s",
        "<div class='meta'><span><strong>Backend:</strong> <code>%s</code></span><span><strong>Source:</strong> <code>%s</code></span></div>",
        "<div class='meta'><span><strong>Latest result:</strong> <code>%s</code></span></div>",
        "<div class='meta'><span><strong>Last tested:</strong> <code>%s</code></span><span><strong>Run:</strong> <a href='%s' target='_blank'><code>%s</code></a></span></div>",
        "<div class='meta'><span><strong>Latest interactions:</strong> <code>%d</code></span><span><strong>Latest failures:</strong> <code>%d</code></span></div>",
        "%s",
        "<div class='actions'>%s</div>",
        "</article>"
      ),
      status_class,
      escape_html(row$id),
      escape_html(display_status),
      escape_html(row$backend),
      escape_html(row$source_type),
      if (isTRUE(row$seen_in_latest_run)) "true" else "false",
      escape_html(row$failures_text),
      status_class,
      status_label,
      escape_html(row$id),
      screenshot_block,
      escape_html(row$backend),
      escape_html(row$source_type),
      escape_html(toupper(as.character(row$current_status))),
      escape_html(row$last_tested_at),
      escape_html(row$report_href),
      escape_html(row$last_tested_run_id),
      as.integer(row$latest_interaction_count),
      as.integer(row$latest_failure_count),
      fail_block,
      links
    )
  }

  cards <- if (nrow(df)) {
    paste(vapply(seq_len(nrow(df)), function(i) card_html(df[i, , drop = FALSE]), FUN.VALUE = character(1)), collapse = "\n")
  } else {
    "<p>No scenarios recorded yet.</p>"
  }

  html <- sprintf(
    paste0(
      "<!doctype html><html><head><meta charset='utf-8'><title>Playwright Running Status</title>",
      "<meta name='viewport' content='width=device-width,initial-scale=1'>",
      "<style>",
      ":root{--bg:#f6f8fb;--card:#ffffff;--ink:#1a2433;--muted:#586174;--line:#d9e0ea;--ok:#0f8a4b;--bad:#b02323;--accent:#0d6efd;}",
      "body{margin:0;background:linear-gradient(180deg,#eef3fa 0%%,#f9fbff 30%%,#f6f8fb 100%%);color:var(--ink);font-family:ui-sans-serif,system-ui,-apple-system,Segoe UI,Roboto,sans-serif;}",
      ".wrap{max-width:1300px;margin:0 auto;padding:20px 16px 40px;}",
      "h1{margin:0 0 8px 0;font-size:30px;} .sub{color:var(--muted);margin:0 0 16px 0;}",
      ".summary{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:10px;margin:14px 0 16px;}",
      ".tile{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:10px 12px;box-shadow:0 2px 12px rgba(19,37,67,.05);}",
      ".tile .k{font-size:12px;color:var(--muted);text-transform:uppercase;letter-spacing:.04em;} .tile .v{font-size:20px;font-weight:700;}",
      ".quick{display:flex;flex-wrap:wrap;gap:8px;margin:10px 0 16px;} .quick a{background:#fff;border:1px solid var(--line);border-radius:999px;padding:6px 10px;color:var(--ink);text-decoration:none;font-size:13px;}",
      ".controls{position:sticky;top:0;z-index:5;background:rgba(246,248,251,.95);backdrop-filter:blur(4px);padding:10px 0 12px;margin-bottom:12px;border-bottom:1px solid var(--line);display:grid;grid-template-columns:2fr 1fr 1fr 1fr auto;gap:8px;}",
      ".controls input,.controls select{border:1px solid var(--line);border-radius:10px;padding:8px 10px;background:#fff;color:var(--ink);} .toggle{display:flex;align-items:center;gap:6px;font-size:13px;color:var(--muted);}",
      ".grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(320px,1fr));gap:12px;}",
      ".card{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:10px;box-shadow:0 4px 18px rgba(19,37,67,.06);}",
      ".card.pass{border-left:4px solid var(--ok);} .card.fail{border-left:4px solid var(--bad);} .card.hidden{display:none;}",
      ".card-head{display:flex;align-items:center;gap:8px;flex-wrap:wrap;margin-bottom:8px;} .badge{font-size:11px;font-weight:700;letter-spacing:.05em;border-radius:999px;padding:3px 8px;} .badge.pass{background:#ddf7ea;color:#095f34;} .badge.fail{background:#fde6e6;color:#8e1d1d;}",
      ".scenario-id{font-size:12px;}",
      ".thumb{display:block;border:1px solid var(--line);border-radius:10px;overflow:hidden;background:#fff;margin-bottom:8px;} .thumb img{display:block;width:100%%;height:170px;object-fit:cover;background:#f1f5fb;}",
      ".thumb.missing{display:flex;align-items:center;justify-content:center;height:120px;background:#f3f6fb;color:var(--muted);border:1px dashed var(--line);border-radius:10px;margin-bottom:8px;}",
      ".meta{display:flex;flex-wrap:wrap;gap:8px 12px;font-size:12px;color:var(--muted);margin:6px 0;}",
      ".meta code{font-size:11px;} .meta a{color:var(--accent);text-decoration:none;}",
      ".fail-reason{margin-top:6px;border:1px solid #f3c9c9;background:#fff3f3;color:#8e1d1d;border-radius:8px;padding:7px;font-size:12px;}",
      ".actions{display:flex;flex-wrap:wrap;gap:6px;margin-top:8px;} .btn{border:1px solid var(--line);border-radius:8px;padding:5px 8px;font-size:12px;text-decoration:none;color:var(--ink);background:#fff;}",
      "@media (max-width:900px){.controls{grid-template-columns:1fr 1fr;}.toggle{grid-column:1 / -1;}}",
      "</style></head><body><div class='wrap'>",
      "<h1>Playwright Running Status</h1>",
      "<p class='sub'>Live inventory of what currently works, when it was last tested, and direct links to screenshots/logs/artifacts.</p>",
      "<div class='summary'>",
      "<div class='tile'><div class='k'>Last Updated</div><div class='v'><code>%s</code></div></div>",
      "<div class='tile'><div class='k'>Latest Run</div><div class='v'><code>%s</code></div></div>",
      "<div class='tile'><div class='k'>Mode</div><div class='v'><code>%s</code></div></div>",
      "<div class='tile'><div class='k'>Passing</div><div class='v'>%s</div></div>",
      "<div class='tile'><div class='k'>Failing</div><div class='v'>%s</div></div>",
      "<div class='tile'><div class='k'>Total</div><div class='v'>%s</div></div>",
      "</div>",
      "<div class='quick'>",
      "<a href='./latest/report.html' target='_blank'>Latest Report</a>",
      "<a href='./latest/results.json' target='_blank'>Latest Results JSON</a>",
      "<a href='./latest/' target='_blank'>Latest Run Folder</a>",
      "<a href='./running-status.md' target='_blank'>Status Markdown</a>",
      "<a href='./running-status.json' target='_blank'>Status JSON</a>",
      "</div>",
      "<div class='controls'>",
      "<input id='q' type='search' placeholder='Search scenario id, backend, or failure text'>",
      "<select id='status'><option value='all'>All Statuses</option><option value='pass'>Pass</option><option value='fail'>Fail</option></select>",
      "<select id='backend'><option value='all'>All Backends</option>%s</select>",
      "<select id='source'><option value='all'>All Sources</option>%s</select>",
      "<label class='toggle'><input id='latestOnly' type='checkbox'>Latest-run only</label>",
      "</div>",
      "<section class='grid' id='cards'>%s</section>",
      "</div>",
      "<script>",
      "const cards=[...document.querySelectorAll('.card')];",
      "const q=document.getElementById('q');const s=document.getElementById('status');const b=document.getElementById('backend');",
      "const src=document.getElementById('source');const latest=document.getElementById('latestOnly');",
      "function apply(){const query=(q.value||'').toLowerCase().trim();const sv=s.value;const bv=b.value;const cv=src.value;const lv=latest.checked;",
      "cards.forEach(card=>{const id=card.dataset.id||'';const backend=card.dataset.backend||'';const source=card.dataset.source||'';const status=card.dataset.status||'';const fail=card.dataset.fail||'';",
      "const hay=(id+' '+backend+' '+source+' '+fail).toLowerCase();",
      "const okQ=!query||hay.includes(query);const okS=sv==='all'||status===sv;const okB=bv==='all'||backend===bv;const okC=cv==='all'||source===cv;const okL=!lv||card.dataset.latest==='true';",
      "card.classList.toggle('hidden',!(okQ&&okS&&okB&&okC&&okL));});}",
      "[q,s,b,src,latest].forEach(el=>el.addEventListener('input',apply));apply();",
      "</script></body></html>"
    ),
    escape_html(as_char(status$generated_at)),
    escape_html(as_char(status$latest_run$run_id)),
    escape_html(as_char(status$latest_run$mode)),
    escape_html(as_char(status$latest_run$pass)),
    escape_html(as_char(status$latest_run$fail)),
    escape_html(as_char(status$latest_run$total)),
    option_html(backends),
    option_html(sources),
    cards
  )

  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(html, con = path, useBytes = TRUE)
}

main <- function() {
  ensure_pkgs()
  args <- parse_args(commandArgs(trailingOnly = TRUE))

  run_results <- jsonlite::fromJSON(args$results, simplifyVector = FALSE)
  prev <- read_json_or_default(args$status_json, default = list(scenarios = list()))
  merged <- merge_status(prev, run_results)

  dir.create(dirname(args$status_json), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(merged, args$status_json, auto_unbox = TRUE, pretty = TRUE)
  render_markdown(merged, args$status_md)
  render_html(merged, args$status_html)

  message("Updated running status: ", args$status_html)
}

main()
