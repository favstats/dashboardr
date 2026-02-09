# Feature matrix helpers for deterministic cross-feature tests.

fm_get_matrix <- local({
  cache <- NULL
  function() {
    if (!is.null(cache)) return(cache)
    if (!requireNamespace("yaml", quietly = TRUE)) {
      stop("Package 'yaml' is required for feature matrix tests.", call. = FALSE)
    }
    path <- test_path("fixtures", "feature_matrix.yml")
    cache <<- yaml::read_yaml(path)
    cache
  }
})

fm_matrix_level <- function() {
  level <- Sys.getenv("DASHBOARDR_MATRIX_LEVEL", unset = "pr")
  if (!level %in% c("pr", "nightly")) "pr" else level
}

fm_content_types <- function() {
  names(fm_get_matrix()$content_types)
}

fm_is_type_supported <- function(type, flag) {
  matrix <- fm_get_matrix()
  info <- matrix$content_types[[type]]
  isTRUE(info[[flag]])
}

fm_unsupported_expectation <- function(id) {
  entries <- fm_get_matrix()$unsupported_combinations
  if (is.null(entries) || length(entries) == 0L) {
    stop("No unsupported combinations declared in feature matrix.", call. = FALSE)
  }
  idx <- which(vapply(entries, function(x) identical(x$id, id), logical(1)))
  if (length(idx) == 0L) {
    stop("Unsupported combination id not found: ", id, call. = FALSE)
  }
  entries[[idx[[1]]]]$expectation
}

fm_required_packages <- function(type, backend = "highcharter") {
  switch(type,
    "gt" = "gt",
    "reactable" = "reactable",
    "DT" = "DT",
    "hc" = "highcharter",
    "widget" = switch(
      backend,
      "plotly" = "plotly",
      "echarts4r" = "echarts4r",
      "ggiraph" = c("ggiraph", "ggplot2"),
      "highcharter" = "highcharter",
      character(0)
    ),
    character(0)
  )
}

fm_have_packages <- function(pkgs) {
  if (length(pkgs) == 0) return(TRUE)
  all(vapply(pkgs, function(pkg) {
    isTRUE(tryCatch(
      suppressWarnings(requireNamespace(pkg, quietly = TRUE)),
      error = function(...) FALSE
    ))
  }, FUN.VALUE = logical(1)))
}

fm_hash_order <- function(ids) {
  hashes <- vapply(ids, digest::digest, FUN.VALUE = character(1), algo = "xxhash64")
  order(hashes)
}

fm_candidate_content_types <- function(level = fm_matrix_level()) {
  all_types <- fm_content_types()
  if (identical(level, "nightly")) {
    return(all_types)
  }

  pr_priority <- c(
    "text", "table", "DT", "reactable", "widget", "hc",
    "input", "input_row", "layout_column", "layout_row",
    "value_box", "modal"
  )
  out <- intersect(pr_priority, all_types)
  if (length(out) == 0L) {
    out <- all_types
  }
  out
}

fm_scenario_dimensions <- function() {
  c(
    "content_type",
    "backend",
    "show_when",
    "tabgroup",
    "filter_vars",
    "sidebar",
    "input_dependency"
  )
}

fm_is_valid_combo <- function(type, show_when, tabgroup, filter_vars, sidebar, input_dependency) {
  if (isTRUE(show_when) && !fm_is_type_supported(type, "supports_show_when")) return(FALSE)
  if (isTRUE(tabgroup) && !fm_is_type_supported(type, "supports_tabgroup")) return(FALSE)
  if (isTRUE(filter_vars) && !fm_is_type_supported(type, "supports_filter_vars")) return(FALSE)
  if (isTRUE(sidebar) && !fm_is_type_supported(type, "supports_sidebar")) return(FALSE)
  if (isTRUE(input_dependency) && !fm_is_type_supported(type, "supports_input_dependency")) return(FALSE)
  TRUE
}

fm_row_pair_tokens <- function(row, dims = fm_scenario_dimensions()) {
  tokens <- character(0)
  if (length(dims) < 2L) return(tokens)
  for (i in seq_len(length(dims) - 1L)) {
    for (j in seq.int(i + 1L, length(dims))) {
      di <- dims[[i]]
      dj <- dims[[j]]
      vi <- as.character(row[[di]])
      vj <- as.character(row[[dj]])
      tokens <- c(tokens, paste0(di, "=", vi, "||", dj, "=", vj))
    }
  }
  unique(tokens)
}

fm_all_pair_tokens <- function(grid, dims = fm_scenario_dimensions()) {
  if (nrow(grid) == 0L) return(character(0))
  unique(unlist(lapply(seq_len(nrow(grid)), function(i) fm_row_pair_tokens(grid[i, , drop = FALSE], dims))))
}

fm_pairwise_select <- function(grid, dims = fm_scenario_dimensions(), max_n = Inf) {
  n <- nrow(grid)
  if (n == 0L) return(integer(0))

  ids <- apply(grid, 1, function(x) {
    paste(
      x[["content_type"]], x[["backend"]], x[["show_when"]], x[["tabgroup"]],
      x[["filter_vars"]], x[["sidebar"]], x[["input_dependency"]],
      sep = "-"
    )
  })
  order_idx <- fm_hash_order(ids)
  row_tokens <- lapply(seq_len(n), function(i) fm_row_pair_tokens(grid[i, , drop = FALSE], dims))
  uncovered <- fm_all_pair_tokens(grid, dims)

  max_n <- as.integer(max_n)
  if (is.na(max_n) || max_n <= 0L) {
    max_n <- n
  }
  max_n <- min(max_n, n)

  selected <- integer(0)
  selected_flag <- rep(FALSE, n)

  while (length(uncovered) > 0L && length(selected) < max_n) {
    best_idx <- NA_integer_
    best_gain <- -1L

    for (idx in order_idx) {
      if (selected_flag[[idx]]) next
      gain <- sum(row_tokens[[idx]] %in% uncovered)
      if (gain > best_gain) {
        best_gain <- gain
        best_idx <- idx
      }
    }

    if (is.na(best_idx) || best_gain <= 0L) {
      break
    }

    selected <- c(selected, best_idx)
    selected_flag[[best_idx]] <- TRUE
    uncovered <- setdiff(uncovered, row_tokens[[best_idx]])
  }

  if (length(selected) < max_n) {
    remaining <- order_idx[!selected_flag[order_idx]]
    need <- min(length(remaining), max_n - length(selected))
    if (need > 0L) {
      selected <- c(selected, remaining[seq_len(need)])
    }
  }

  selected
}

fm_generate_scenarios <- function(level = fm_matrix_level()) {
  matrix <- fm_get_matrix()
  types <- names(matrix$content_types)
  backends <- matrix$backends

  base <- lapply(types, function(type) {
    list(
      id = paste0("base-", type),
      kind = "content",
      content_type = type,
      backend = "highcharter",
      show_when = FALSE,
      tabgroup = FALSE,
      filter_vars = FALSE,
      sidebar = FALSE,
      input_dependency = FALSE
    )
  })

  candidate_types <- fm_candidate_content_types(level = level)
  grid <- expand.grid(
    content_type = candidate_types,
    backend = backends,
    show_when = c(FALSE, TRUE),
    tabgroup = c(FALSE, TRUE),
    filter_vars = c(FALSE, TRUE),
    sidebar = c(FALSE, TRUE),
    input_dependency = c(FALSE, TRUE),
    stringsAsFactors = FALSE
  )

  grid <- grid[vapply(seq_len(nrow(grid)), function(i) {
    row <- grid[i, ]
    fm_is_valid_combo(
      type = row$content_type,
      show_when = isTRUE(row$show_when),
      tabgroup = isTRUE(row$tabgroup),
      filter_vars = isTRUE(row$filter_vars),
      sidebar = isTRUE(row$sidebar),
      input_dependency = isTRUE(row$input_dependency)
    )
  }, logical(1)), , drop = FALSE]

  selected_idx <- integer(0)
  if (nrow(grid) > 0) {
    keep_n <- if (identical(level, "nightly")) 220L else 64L
    selected_idx <- fm_pairwise_select(
      grid = grid,
      dims = fm_scenario_dimensions(),
      max_n = keep_n
    )
    grid <- grid[selected_idx, , drop = FALSE]
  }

  sampled <- lapply(seq_len(nrow(grid)), function(i) {
    row <- grid[i, ]
    list(
      id = paste0(
        "combo-", row$content_type, "-", row$backend,
        "-sw", as.integer(row$show_when),
        "-tg", as.integer(row$tabgroup),
        "-fv", as.integer(row$filter_vars),
        "-sb", as.integer(row$sidebar),
        "-id", as.integer(row$input_dependency)
      ),
      kind = "content",
      content_type = row$content_type,
      backend = row$backend,
      show_when = isTRUE(row$show_when),
      tabgroup = isTRUE(row$tabgroup),
      filter_vars = isTRUE(row$filter_vars),
      sidebar = isTRUE(row$sidebar),
      input_dependency = isTRUE(row$input_dependency)
    )
  })

  out <- c(base, sampled)

  full_candidates <- expand.grid(
    content_type = candidate_types,
    backend = backends,
    show_when = c(FALSE, TRUE),
    tabgroup = c(FALSE, TRUE),
    filter_vars = c(FALSE, TRUE),
    sidebar = c(FALSE, TRUE),
    input_dependency = c(FALSE, TRUE),
    stringsAsFactors = FALSE
  )
  full_candidates <- full_candidates[vapply(seq_len(nrow(full_candidates)), function(i) {
    row <- full_candidates[i, ]
    fm_is_valid_combo(
      type = row$content_type,
      show_when = isTRUE(row$show_when),
      tabgroup = isTRUE(row$tabgroup),
      filter_vars = isTRUE(row$filter_vars),
      sidebar = isTRUE(row$sidebar),
      input_dependency = isTRUE(row$input_dependency)
    )
  }, logical(1)), , drop = FALSE]

  total_pairs <- fm_all_pair_tokens(full_candidates, dims = fm_scenario_dimensions())
  covered_pairs <- if (length(selected_idx) > 0L) {
    fm_all_pair_tokens(full_candidates[selected_idx, , drop = FALSE], dims = fm_scenario_dimensions())
  } else {
    character(0)
  }

  attr(out, "pairwise_meta") <- list(
    level = level,
    candidate_content_types = candidate_types,
    total_candidates = nrow(full_candidates),
    selected_candidates = length(selected_idx),
    total_pair_tokens = length(total_pairs),
    covered_pair_tokens = length(covered_pairs),
    uncovered_pair_tokens = length(setdiff(total_pairs, covered_pairs))
  )

  out
}

fm_make_widget <- function(backend) {
  switch(
    backend,
    "highcharter" = {
      highcharter::hchart(head(mtcars), "scatter", highcharter::hcaes(wt, mpg))
    },
    "plotly" = {
      plotly::plot_ly(mtcars, x = ~wt, y = ~mpg, type = "scatter", mode = "markers")
    },
    "echarts4r" = {
      echarts4r::e_charts(mtcars, wt) |>
        echarts4r::e_scatter(mpg)
    },
    "ggiraph" = {
      p <- ggplot2::ggplot(
        mtcars,
        ggplot2::aes(wt, mpg, tooltip = rownames(mtcars), data_id = rownames(mtcars))
      ) + ggplot2::geom_point()
      ggiraph::girafe(ggobj = p)
    },
    stop("Unsupported backend: ", backend, call. = FALSE)
  )
}

fm_make_content_for_type <- function(type,
                                     backend = "highcharter",
                                     show_when = FALSE,
                                     tabgroup = FALSE,
                                     filter_vars = FALSE,
                                     sidebar = FALSE,
                                     input_dependency = FALSE) {
  tg <- if (isTRUE(tabgroup)) "matrix/group" else NULL
  sw <- if (isTRUE(show_when)) ~ cyl == 6 else NULL
  fv <- if (isTRUE(filter_vars)) "cyl" else NULL

  content <- create_content(data = mtcars)

  if (isTRUE(sidebar)) {
    content <- content |>
      add_sidebar(title = "Filters", position = "left") |>
      add_filter(filter_var = "cyl", type = "checkbox") |>
      end_sidebar()
  }

  if (isTRUE(input_dependency)) {
    content <- content |>
      add_input(input_id = "dep_filter", filter_var = "cyl", options = sort(unique(mtcars$cyl)))
  }

  switch(
    type,
    "text" = content |> add_text("Matrix text", tabgroup = tg, show_when = sw),
    "image" = content |> add_image(src = "https://example.com/example.png", alt = "example", tabgroup = tg, show_when = sw),
    "video" = content |> add_video(src = "https://example.com/example.mp4", tabgroup = tg, show_when = sw),
    "callout" = content |> add_callout("Matrix callout", tabgroup = tg, show_when = sw),
    "divider" = content |> add_divider(tabgroup = tg, show_when = sw),
    "code" = content |> add_code(code = "1 + 1", tabgroup = tg, show_when = sw),
    "spacer" = content |> add_spacer(tabgroup = tg, show_when = sw),
    "gt" = content |> add_gt(gt::gt(head(mtcars)), tabgroup = tg, show_when = sw),
    "reactable" = content |>
      add_reactable(
        if (is.null(fv)) reactable::reactable(head(mtcars)) else head(mtcars),
        tabgroup = tg,
        filter_vars = fv,
        show_when = sw
      ),
    "table" = content |> add_table(head(mtcars), tabgroup = tg, filter_vars = fv, show_when = sw),
    "DT" = content |> add_DT(head(mtcars), tabgroup = tg, filter_vars = fv, show_when = sw),
    "iframe" = content |> add_iframe(src = "https://example.com", tabgroup = tg, show_when = sw),
    "accordion" = content |> add_accordion(title = "Section", text = "Accordion body", tabgroup = tg, show_when = sw),
    "card" = content |> add_card(text = "Card body", title = "Card", tabgroup = tg, show_when = sw),
    "html" = content |> add_html("<p>Custom html</p>", tabgroup = tg, show_when = sw),
    "quote" = content |> add_quote("A quote", tabgroup = tg, show_when = sw),
    "badge" = content |> add_badge("Status", tabgroup = tg, show_when = sw),
    "metric" = content |> add_metric(value = "42", title = "Metric", tabgroup = tg, show_when = sw),
    "value_box" = content |>
      add_value_box_row(tabgroup = tg, show_when = sw) |>
      add_value_box(title = "Value", value = "42") |>
      end_value_box_row(),
    "value_box_row" = content |>
      add_value_box_row(tabgroup = tg, show_when = sw) |>
      add_value_box(title = "Value", value = "42") |>
      end_value_box_row(),
    "hc" = content |>
      add_hc(
        highcharter::hchart(head(mtcars), "scatter", highcharter::hcaes(wt, mpg)),
        tabgroup = tg,
        filter_vars = fv,
        show_when = sw
      ),
    "widget" = content |>
      add_widget(
        fm_make_widget(backend),
        title = "Widget",
        tabgroup = tg,
        filter_vars = fv,
        show_when = sw
      ),
    "layout_column" = content |>
      add_layout_column(class = "matrix-col", tabgroup = tg, show_when = sw) |>
      add_text("Inside column") |>
      end_layout_column(),
    "layout_row" = content |>
      add_layout_column(class = "matrix-col") |>
      add_layout_row(class = "matrix-row", tabgroup = tg, show_when = sw) |>
      add_text("Inside row") |>
      end_layout_row() |>
      end_layout_column(),
    "input" = content |>
      add_input(
        input_id = "matrix_input",
        filter_var = "cyl",
        options = sort(unique(mtcars$cyl)),
        tabgroup = tg
      ),
    "input_row" = content |>
      add_input_row(tabgroup = tg, style = "inline") |>
      add_input(
        input_id = "matrix_row_input",
        filter_var = "cyl",
        options = sort(unique(mtcars$cyl))
      ) |>
      end_input_row(),
    "modal" = content |>
      add_text("[details](#matrix-details){.modal-link}") |>
      add_modal(modal_id = "matrix-details", title = "Details", modal_content = "Modal body"),
    stop("Unsupported content type in helper: ", type, call. = FALSE)
  )
}

fm_make_viz_content <- function(backend = "highcharter", tabgroup = FALSE, show_when = FALSE) {
  tg <- if (isTRUE(tabgroup)) "viz/group" else NULL
  sw <- if (isTRUE(show_when)) ~ cyl == 6 else NULL

  create_content(data = mtcars, type = "bar") |>
    add_viz(type = "bar", x_var = "cyl", title = "Cylinders", tabgroup = tg, show_when = sw) |>
    add_viz(type = "histogram", x_var = "mpg", title = "MPG")
}

fm_generate_dashboard_files <- function(content, backend = "highcharter", page_name = "Matrix") {
  out_dir <- tempfile("feature-matrix-")

  proj <- create_dashboard(
    title = "Feature Matrix",
    output_dir = out_dir,
    allow_inside_pkg = TRUE,
    backend = backend
  )

  page <- create_page(page_name, data = mtcars) |>
    add_content(content)

  proj <- proj |> add_pages(page)
  generate_dashboard(proj, render = FALSE, open = FALSE, quiet = TRUE)

  page_file <- paste0(tolower(gsub("[^A-Za-z0-9]+", "_", page_name)), ".qmd")
  qmd_path <- file.path(out_dir, page_file)
  yml_path <- file.path(out_dir, "_quarto.yml")

  list(
    output_dir = out_dir,
    qmd_path = qmd_path,
    yml_path = yml_path,
    qmd_lines = readLines(qmd_path, warn = FALSE),
    yml_lines = readLines(yml_path, warn = FALSE)
  )
}

fm_normalize_lines <- function(lines) {
  out <- gsub("\\r", "", lines)
  out <- sub("[[:space:]]+$", "", out)
  out
}

fm_extract_qmd_fragments <- function(lines) {
  lines <- fm_normalize_lines(lines)
  keep <- grepl("^(## Column|### Row|#### )", lines) |
    grepl("show_when_open\\(", lines, fixed = FALSE) |
    grepl("show_when_close\\(", lines, fixed = FALSE) |
    grepl("filter_vars\\s*=", lines) |
    grepl("backend\\s*=", lines)
  lines[keep]
}

fm_extract_yml_fragments <- function(lines) {
  lines <- fm_normalize_lines(lines)
  keep <- grepl("^(project:|website:|format:|theme:|title:|navbar:)", lines)
  lines[keep]
}
