#!/usr/bin/env Rscript

parse_args <- function(args) {
  out <- list(
    output_dir = NULL,
    mode = "smoke",
    manifest_out = NULL
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

  if (is.null(out$output_dir) || !nzchar(out$output_dir)) {
    stop("--output_dir is required", call. = FALSE)
  }
  if (is.null(out$manifest_out) || !nzchar(out$manifest_out)) {
    stop("--manifest_out is required", call. = FALSE)
  }
  if (!out$mode %in% c("smoke", "full")) {
    stop("--mode must be 'smoke' or 'full'", call. = FALSE)
  }

  out
}

get_script_dir <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- "--file="
  idx <- grep(file_arg, args)
  if (!length(idx)) {
    return(normalizePath(getwd(), winslash = "/", mustWork = TRUE))
  }
  normalizePath(dirname(sub(file_arg, "", args[[idx[[1]]]])), winslash = "/", mustWork = TRUE)
}

ensure_quarto <- function() {
  if (!requireNamespace("quarto", quietly = TRUE)) {
    stop("Package 'quarto' is required for generated matrix pages.", call. = FALSE)
  }
  if (is.null(quarto::quarto_path())) {
    stop(
      paste(
        "Quarto is required to generate HTML matrix pages.",
        "Install Quarto from https://quarto.org/docs/download/",
        "or run pipeline with --include-generated false."
      ),
      call. = FALSE
    )
  }
}

load_dashboardr <- function(repo_root) {
  if (requireNamespace("devtools", quietly = TRUE)) {
    suppressPackageStartupMessages(
      devtools::load_all(path = repo_root, quiet = TRUE, export_all = TRUE)
    )
    return(invisible(TRUE))
  }

  if (requireNamespace("dashboardr", quietly = TRUE)) {
    suppressPackageStartupMessages(library(dashboardr))
    return(invisible(TRUE))
  }

  stop("Could not load dashboardr: devtools not installed and package not available.", call. = FALSE)
}

build_demo_data <- function() {
  df <- mtcars
  df$cyl <- as.character(df$cyl)
  df$gear <- as.character(df$gear)
  df$mode <- ifelse(seq_len(nrow(df)) %% 2L == 0L, "All", "Focus")
  df
}

build_linked_options <- function(df) {
  by_cyl <- split(df$gear, df$cyl)
  lapply(by_cyl, function(x) sort(unique(as.character(x))))
}

build_content <- function(df, backend, include_layout_variant = FALSE) {
  linked_map <- build_linked_options(df)

  content <- create_content(data = df) |>
    add_sidebar(position = "left", title = paste("Controls:", backend)) |>
    add_filter(filter_var = "cyl", type = "checkbox") |>
    add_input(
      input_id = "mode_selector",
      label = "Mode",
      type = "radio",
      filter_var = "mode",
      options = c("All", "Focus"),
      default_selected = "All",
      inline = TRUE
    ) |>
    add_linked_inputs(
      parent = list(
        id = "parent_cyl",
        label = "Parent Cyl",
        options = sort(unique(df$cyl)),
        filter_var = "cyl"
      ),
      child = list(
        id = "child_gear",
        label = "Child Gear",
        options_by_parent = linked_map,
        filter_var = "gear"
      ),
      type = "select"
    ) |>
    end_sidebar() |>
    add_html(sprintf("<div id=\"pw-marker-%s\" data-pw-backend=\"%s\"></div>", backend, backend)) |>
    add_text("Visible when mode is All", show_when = ~ mode == "All") |>
    add_text("Visible when mode is Focus", show_when = ~ mode == "Focus") |>
    add_viz(
      type = "bar",
      x_var = "gear",
      group_var = "cyl",
      title = paste("Distribution (", backend, ")"),
      tabgroup = "Main/Distribution"
    ) |>
    add_viz(
      type = "scatter",
      x_var = "wt",
      y_var = "mpg",
      group_var = "cyl",
      title = paste("Scatter (", backend, ")"),
      tabgroup = "Main/Scatter"
    )

  if (isTRUE(include_layout_variant)) {
    content <- content |>
      add_layout_column(class = "pw-layout-col") |>
      add_layout_row(class = "pw-layout-row", show_when = ~ mode == "All") |>
      add_table(head(df, 10), filter_vars = "cyl") |>
      end_layout_row() |>
      end_layout_column()
  }

  content
}

build_project <- function(output_dir, backend, include_layout_variant = FALSE) {
  df <- build_demo_data()
  content <- build_content(df, backend, include_layout_variant = include_layout_variant)

  proj <- create_dashboard(
    output_dir = output_dir,
    title = paste("Playwright Matrix:", backend),
    allow_inside_pkg = TRUE,
    backend = backend
  ) |>
    add_page(
      name = "Index",
      data = df,
      content = content,
      is_landing_page = TRUE
    )

  generate_dashboard(
    proj,
    render = TRUE,
    open = FALSE,
    quiet = TRUE
  )

  invisible(TRUE)
}

build_mixed_project <- function(output_dir) {
  if (!requireNamespace("plotly", quietly = TRUE)) {
    stop("Package 'plotly' is required for mixed generated scenario.", call. = FALSE)
  }
  if (!requireNamespace("leaflet", quietly = TRUE)) {
    stop("Package 'leaflet' is required for mixed generated scenario.", call. = FALSE)
  }

  df <- build_demo_data()

  plot_obj <- plotly::plot_ly(df, x = ~wt, y = ~mpg, color = ~cyl, type = "scatter", mode = "markers")
  map_obj <- leaflet::leaflet(data.frame(lng = c(-73, -122), lat = c(40.7, 37.8))) |>
    leaflet::addCircleMarkers(~lng, ~lat)

  content <- create_content(data = df) |>
    add_sidebar(position = "left", title = "Mixed Controls") |>
    add_filter(filter_var = "cyl", type = "checkbox") |>
    add_input(
      input_id = "mode_selector",
      label = "Mode",
      type = "radio",
      filter_var = "mode",
      options = c("All", "Focus"),
      default_selected = "All"
    ) |>
    end_sidebar() |>
    add_html("<div id=\"pw-marker-mixed\" data-pw-backend=\"mixed\"></div>") |>
    add_plotly(
      plot = plot_obj,
      title = "Plotly Widget",
      tabgroup = "Widgets/Plotly",
      filter_vars = "cyl",
      show_when = ~ mode == "All"
    ) |>
    add_leaflet(
      map = map_obj,
      title = "Leaflet Widget",
      tabgroup = "Widgets/Leaflet",
      show_when = ~ mode == "Focus"
    )

  proj <- create_dashboard(
    output_dir = output_dir,
    title = "Playwright Matrix: mixed",
    allow_inside_pkg = TRUE,
    backend = "highcharter"
  ) |>
    add_page(
      name = "Index",
      data = df,
      content = content,
      is_landing_page = TRUE
    )

  generate_dashboard(
    proj,
    render = TRUE,
    open = FALSE,
    quiet = TRUE
  )

  invisible(TRUE)
}

scenario_for_backend <- function(backend, mode) {
  expect_filter <- !identical(backend, "ggiraph")
  list(
    id = paste0("generated-", backend, "-core"),
    source_type = "generated",
    backend = backend,
    url_path = paste0("/backend-", backend, "/index.html"),
    expect_chart_backend = c(backend),
    interaction_plan = c("filter", "linked_inputs", "tab_click", "sidebar_toggle", "show_when_toggle"),
    expect_filter_effect = expect_filter,
    required_selectors = c(
      paste0("#pw-marker-", backend),
      ".dashboardr-input",
      ".panel-tabset .nav-link",
      "[data-show-when]"
    ),
    forbidden_console_patterns = character(0),
    modes = c("smoke", "full")
  )
}

main <- function() {
  args <- parse_args(commandArgs(trailingOnly = TRUE))
  script_dir <- get_script_dir()
  repo_root <- normalizePath(file.path(script_dir, "..", ".."), winslash = "/", mustWork = TRUE)

  ensure_quarto()
  load_dashboardr(repo_root)

  output_dir <- normalizePath(args$output_dir, winslash = "/", mustWork = FALSE)
  manifest_out <- normalizePath(args$manifest_out, winslash = "/", mustWork = FALSE)

  if (dir.exists(output_dir)) {
    unlink(output_dir, recursive = TRUE, force = TRUE)
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  backends <- c("highcharter", "plotly", "echarts4r", "ggiraph")
  scenarios <- list()
  skipped <- list()

  for (backend in backends) {
    target <- file.path(output_dir, paste0("backend-", backend))
    ok <- tryCatch({
      build_project(target, backend, include_layout_variant = identical(args$mode, "full"))
      TRUE
    }, error = function(e) {
      skipped[[length(skipped) + 1L]] <<- list(
        id = paste0("generated-", backend, "-core"),
        reason = conditionMessage(e)
      )
      FALSE
    })

    if (ok) {
      scenarios[[length(scenarios) + 1L]] <- scenario_for_backend(backend, args$mode)
    }
  }

  if (identical(args$mode, "full")) {
    mixed_target <- file.path(output_dir, "backend-mixed")
    mixed_ok <- tryCatch({
      build_mixed_project(mixed_target)
      TRUE
    }, error = function(e) {
      skipped[[length(skipped) + 1L]] <<- list(
        id = "generated-mixed-widgets",
        reason = conditionMessage(e)
      )
      FALSE
    })

    if (mixed_ok) {
      scenarios[[length(scenarios) + 1L]] <- list(
        id = "generated-mixed-widgets",
        source_type = "generated",
        backend = "mixed",
        url_path = "/backend-mixed/index.html",
        expect_chart_backend = c("plotly", "leaflet"),
        interaction_plan = c("filter", "tab_click", "sidebar_toggle", "show_when_toggle"),
        expect_filter_effect = FALSE,
        required_selectors = c(
          "#pw-marker-mixed",
          ".dashboardr-input",
          ".panel-tabset .nav-link",
          ".js-plotly-plot"
        ),
        forbidden_console_patterns = character(0),
        modes = c("full")
      )
    }
  }

  if (!length(scenarios)) {
    stop(
      paste(
        "No generated scenarios were produced.",
        "Confirm Quarto and optional backend packages are installed."
      ),
      call. = FALSE
    )
  }

  payload <- list(
    generated_at = format(Sys.time(), tz = "UTC", usetz = TRUE),
    mode = args$mode,
    scenarios = scenarios,
    skipped = skipped
  )

  dir.create(dirname(manifest_out), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(payload, manifest_out, auto_unbox = TRUE, pretty = TRUE)

  message("Generated ", length(scenarios), " scenario page(s) into: ", output_dir)
  if (length(skipped)) {
    message("Skipped ", length(skipped), " generated scenario(s).")
  }
}

main()
