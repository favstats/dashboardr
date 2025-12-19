# =================================================================
# viz_generation
# =================================================================

#' Split visualization specs by pagination markers
#'
#' Internal function that splits a collection of visualization specifications
#' into sections based on pagination_break markers.
#'
#' @param viz_specs List of visualization specifications
#' @return List of sections, where each section is a list of viz specs
#' @keywords internal
.split_by_pagination <- function(viz_specs) {
  sections <- list()
  current_section <- list()
  
  for (i in seq_along(viz_specs)) {
    spec <- viz_specs[[i]]
    
    # Check if this is a pagination marker
    if (isTRUE(!is.null(spec$pagination_break) && isTRUE(spec$pagination_break))) {
      # Store pagination config in the marker
      pagination_marker <- spec
      
      # End current section if it has content
      if (length(current_section) > 0) {
        sections <- c(sections, list(list(
          items = current_section,
          pagination_after = pagination_marker
        )))
        current_section <- list()
      }
    } else {
      # Add regular viz to current section
      current_section <- c(current_section, list(spec))
    }
  }
  
  # Don't forget last section
  if (length(current_section) > 0) {
    sections <- c(sections, list(list(
      items = current_section,
      pagination_after = NULL  # No pagination after last section
    )))
  }
  
  sections
}

.generate_viz_from_specs <- function(viz_specs, lazy_load_charts = FALSE, lazy_load_tabs = FALSE) {
  lines <- character(0)

  for (i in seq_along(viz_specs)) {
    spec <- viz_specs[[i]]
    
    # Skip pagination markers - they're handled at page generation level
    if (isTRUE(!is.null(spec$pagination_break) && isTRUE(spec$pagination_break))) {
      next
    }
    
    spec_name <- if (isTRUE(!is.null(names(viz_specs)[i]) && names(viz_specs)[i] != "")) {
      names(viz_specs)[i]
    } else {
      paste0("viz_", i)
    }

    # Check if this is a content block (not a viz)
    is_content_block <- isTRUE(!is.null(spec$type) && spec$type %in% c(
      "text", "image", "video", "callout", "divider", "code", "spacer",
      "gt", "reactable", "table", "DT", "iframe", "accordion", "card",
      "html", "quote", "badge", "metric", "value_box", "value_box_row"
    ))
    
    if (is_content_block) {
      # Generate content block using page_generation helpers
      block_content <- .generate_content_block_inline(spec)
      if (!is.null(block_content)) {
        lines <- c(lines, block_content)
      }
    } else if (isTRUE(is.null(spec$type) || !isTRUE(spec$type == "tabgroup"))) {
      # For top-level single charts, apply lazy loading if enabled
      lines <- c(lines, .generate_single_viz(spec_name, spec, lazy_load = lazy_load_charts))
    } else {
      # Tabgroup
      lines <- c(lines, .generate_tabgroup_viz(spec, lazy_load_tabs = lazy_load_tabs))
    }
  }

  lines
}

# Helper to generate content blocks inline (when mixed with viz in tabgroups)
.generate_content_block_inline <- function(block) {
  block_type <- block$type
  
  # Dispatch to appropriate generator based on type
  block_content <- switch(block_type,
    "text" = c("", block$content, ""),
    "image" = .generate_image_block(block),
    "callout" = .generate_callout_block(block),
    "divider" = .generate_divider_block(block),
    "code" = .generate_code_block(block),
    "card" = .generate_card_block(block),
    "accordion" = .generate_accordion_block(block),
    "iframe" = .generate_iframe_block(block),
    "video" = .generate_video_block(block),
    "table" = .generate_table_block(block),
    "gt" = .generate_gt_block(block),
    "reactable" = .generate_reactable_block(block),
    "DT" = .generate_DT_block(block),
    "spacer" = .generate_spacer_block(block),
    "html" = .generate_html_block(block),
    "quote" = .generate_quote_block(block),
    "badge" = .generate_badge_block(block),
    "metric" = .generate_metric_block(block),
    "value_box" = .generate_value_box_block(block),
    "value_box_row" = .generate_value_box_row_block(block),
    NULL  # Unknown type - skip
  )
  
  block_content
}

.generate_single_viz <- function(spec_name, spec, skip_header = FALSE, lazy_load = FALSE, is_first_tab = TRUE) {
  lines <- character(0)

  # Remove nested_children from spec - it's only for structure, not for visualization generation
  spec <- spec[names(spec) != "nested_children"]

  # Add section header with icon if provided (skip if in tabgroup)
  if (isTRUE(!skip_header && !is.null(spec$title))) {
    header_text <- spec$title
    if (!is.null(spec$icon)) {
      icon_shortcode <- if (grepl("{{< iconify", spec$icon, fixed = TRUE)) {
        spec$icon
      } else {
        icon(spec$icon)
      }
      header_text <- paste0(icon_shortcode, " ", spec$title)
    }
    lines <- c(lines, paste0("## ", header_text), "")
  }

  # Add text_before_viz if provided
  if (isTRUE(!is.null(spec$text_before_viz) && nzchar(spec$text_before_viz))) {
    lines <- c(lines, "", spec$text_before_viz, "")
  }
  
  # Backward compatibility: handle old text parameter
  if (isTRUE(!is.null(spec$text) && nzchar(spec$text))) {
    text_position <- spec$text_position %||% "above"
    if (isTRUE(text_position == "above" && is.null(spec$text_before_viz))) {
      lines <- c(lines, "", spec$text, "")
    }
  }

  # Generate meaningful chunk label
  chunk_label <- .generate_chunk_label(spec, spec_name)
  
  # Generate unique ID for lazy loading
  chart_id <- paste0("chart-", gsub("[^a-z0-9]", "-", tolower(chunk_label)))
  
  # If lazy loading is enabled, wrap chart in Quarto div container
  if (lazy_load) {
    lines <- c(lines,
      "",
      paste0("::: {#", chart_id, " .chart-lazy data-loaded='false'}"),
      ""
    )
  }
  
  # Simple R chunk - caching enabled for performance
  lines <- c(lines,
    paste0("```{r ", chunk_label, "}"),
    paste0("# ", spec$title %||% paste(spec$viz_type, "visualization"))
  )

  # Dispatch to appropriate generator
  if ("viz_type" %in% names(spec) && !is.null(spec$viz_type)) {
    lines <- c(lines, .generate_typed_viz(spec))
  } else if ("fn" %in% names(spec)) {
    lines <- c(lines, .generate_function_viz(spec))
  } else {
    lines <- c(lines, .generate_auto_viz(spec_name, spec))
  }

  lines <- c(lines, "```")
  
  # Close lazy load container if enabled
  if (lazy_load) {
    lines <- c(lines,
      "",
      ":::",
      ""
    )
  }

  # Add text_after_viz if provided
  if (isTRUE(!is.null(spec$text_after_viz) && nzchar(spec$text_after_viz))) {
    lines <- c(lines, "", spec$text_after_viz, "")
  }
  
  # Backward compatibility: handle old text parameter with text_position = "below"
  if (isTRUE(!is.null(spec$text) && nzchar(spec$text))) {
    text_position <- spec$text_position %||% "above"
    if (isTRUE(text_position == "below" && is.null(spec$text_after_viz))) {
      lines <- c(lines, "", spec$text, "")
    }
  }

  lines <- c(lines, "")
  lines
}

#' Generate R code for typed visualizations
#'
#' Internal function that generates R code for specific visualization types
#' (stackedbar, heatmap, histogram, timeline, scatter, bar) by mapping type names to
#' function names and serializing parameters.
#'
#' @param spec Visualization specification list containing type and parameters
#' @return Character vector of R code lines for the visualization
#' @keywords internal
#' @details
#' This function:
#' - Maps visualization types to function names (e.g., "stackedbar" → "create_stackedbar")
#' - Excludes internal parameters (type, data_path, tabgroup, text, icon, text_position)
#' - Serializes all other parameters using .serialize_arg()


#' Generate R code for typed visualizations
#'
#' Internal function that generates R code for specific visualization types
#' (stackedbar, heatmap, histogram, timeline, scatter, bar) by mapping type names to
#' function names and serializing parameters.
#'
#' @param spec Visualization specification list containing type and parameters
#' @return Character vector of R code lines for the visualization
#' @keywords internal
#' @details
#' This function:
#' - Maps visualization types to function names (e.g., "stackedbar" → "create_stackedbar")
#' - Excludes internal parameters (type, data_path, tabgroup, text, icon, text_position)
#' - Serializes all other parameters using .serialize_arg()
#' - Formats the function call with proper indentation
.generate_typed_viz <- function(spec) {
  lines <- character(0)

  ## TODO: this needs to create from some list of available visualizations (maybe!)
  # Map type to function name
  viz_function <- switch(spec$viz_type,
                         "map" = "create_map",
                         "treemap" = "create_treemap",
                         "stackedbars" = "create_stackedbars",
                         "stackedbar" = "create_stackedbar",
                         "histogram" = "create_histogram",
                         "heatmap" = "create_heatmap",
                         "timeline" = "create_timeline",
                         "bar" = "create_bar",
                         "scatter" = "create_scatter",
                         spec$viz_type
  )

  # Determine which dataset to use
  source_dataset <- spec[["data"]] %||% "data"  # Check if viz specifies a dataset (use [[ to avoid partial matching)
  
  if (!is.null(spec$filter)) {
    # Use pre-filtered dataset created in setup chunk
    filter_expr <- deparse(spec$filter[[2]], width.cutoff = 500L)
    filter_key <- paste(filter_expr, collapse = " ")
    filter_hash <- substr(digest::digest(filter_key), 1, 8)
    data_var <- paste0(source_dataset, "_filtered_", filter_hash)
  } else {
    # Use the source dataset (named dataset or default "data")
    data_var <- source_dataset
  }

  # Build argument list (exclude internal params)
  args <- list()

  # Add data argument if page has data (either single or multi-dataset)
  if (("data_path" %in% names(spec) && !is.null(spec[["data_path"]])) || 
      ("has_data" %in% names(spec) && isTRUE(spec$has_data))) {
    
    # Check if we should drop NAs for relevant variables
    if (isTRUE(spec$drop_na_vars)) {
      # Determine which variables are used in this visualization
      vars_to_clean <- character(0)
      
      if (spec$viz_type == "stackedbar") {
        if (!is.null(spec$x_var)) vars_to_clean <- c(vars_to_clean, spec$x_var)
        if (!is.null(spec$stack_var)) vars_to_clean <- c(vars_to_clean, spec$stack_var)
      } else if (spec$viz_type == "stackedbars") {
        if (!is.null(spec$questions)) vars_to_clean <- c(vars_to_clean, spec$questions)
      } else if (spec$viz_type == "timeline") {
        if (!is.null(spec$response_var)) vars_to_clean <- c(vars_to_clean, spec$response_var)
        if (!is.null(spec$group_var)) vars_to_clean <- c(vars_to_clean, spec$group_var)
        if (!is.null(spec$time_var)) vars_to_clean <- c(vars_to_clean, spec$time_var)
      } else if (spec$viz_type == "histogram") {
        if (!is.null(spec$x_var)) vars_to_clean <- c(vars_to_clean, spec$x_var)
        if (!is.null(spec$group_var)) vars_to_clean <- c(vars_to_clean, spec$group_var)
      } else if (spec$viz_type == "bar") {
        if (!is.null(spec$x_var)) vars_to_clean <- c(vars_to_clean, spec$x_var)
        if (!is.null(spec$group_var)) vars_to_clean <- c(vars_to_clean, spec$group_var)
      } else if (spec$viz_type == "heatmap") {
        if (!is.null(spec$x_var)) vars_to_clean <- c(vars_to_clean, spec$x_var)
        if (!is.null(spec$y_var)) vars_to_clean <- c(vars_to_clean, spec$y_var)
        if (!is.null(spec$fill_var)) vars_to_clean <- c(vars_to_clean, spec$fill_var)
      } else if (spec$viz_type == "scatter") {
        if (!is.null(spec$x_var)) vars_to_clean <- c(vars_to_clean, spec$x_var)
        if (!is.null(spec$y_var)) vars_to_clean <- c(vars_to_clean, spec$y_var)
        if (!is.null(spec$color_var)) vars_to_clean <- c(vars_to_clean, spec$color_var)
        if (!is.null(spec$size_var)) vars_to_clean <- c(vars_to_clean, spec$size_var)
      }
      
      # Build data pipeline with drop_na if we have variables
      if (length(vars_to_clean) > 0) {
        vars_str <- paste(vars_to_clean, collapse = ", ")
        args[["data"]] <- paste0(data_var, " %>% tidyr::drop_na(", vars_str, ")")
      } else {
        args[["data"]] <- data_var
      }
    } else {
      args[["data"]] <- data_var  # Reference filtered or named dataset
    }
  }

  for (param in names(spec)) {
    if (!param %in% c("type", "viz_type", "data_path", "tabgroup", "text", "icon", "text_position", "text_before_tabset", "text_after_tabset", "text_before_viz", "text_after_viz", "height", "filter", "data", "has_data", "multi_dataset", "title_tabset", "nested_children", "drop_na_vars", ".insertion_index", ".min_index")) { # Exclude internal parameters
      args[[param]] <- .serialize_arg(spec[[param]])
    }
  }

  # Format function call with proper indentation
  if (length(args) == 0) {
    call_str <- paste0("result <- ", viz_function, "()")
  } else {
    arg_lines <- character(0)
    arg_lines <- c(arg_lines, paste0("result <- ", viz_function, "("))

    for (i in seq_along(args)) {
      arg_name <- names(args)[i]
      arg_value <- args[[i]]
      comma <- if (i < length(args)) "," else ""
      arg_lines <- c(arg_lines, paste0("  ", arg_name, " = ", arg_value, comma))
    }

    arg_lines <- c(arg_lines, ")")
    call_str <- arg_lines
  }

  # Add height support - wrap in explicit height container 
  if (!is.null(spec$height)) {
    height_lines <- c(
      "",
      "# Force container height with explicit wrapper",
      paste0("if (inherits(result, 'highchart')) {"),
      paste0("  result <- highcharter::hc_size(result, height = ", spec$height, ")"),
      paste0("}"),
      paste0("result <- htmltools::div("),
      paste0("  style = 'height: ", spec$height, "px !important; min-height: ", spec$height, "px !important; width: 100%; overflow: visible;',"),
      paste0("  result"),
      paste0(")")
    )
    call_str <- c(call_str, height_lines)
  }

  # Always print the result
  call_str <- c(call_str, "", "result")

  c(lines, call_str)
}


.generate_function_viz <- function(spec) {
  lines <- character(0)

  # Determine which dataset to use
  source_dataset <- spec[["data"]] %||% "data"  # Check if viz specifies a dataset (use [[ to avoid partial matching)
  
  if (!is.null(spec$filter)) {
    # Use pre-filtered dataset created in setup chunk
    filter_expr <- deparse(spec$filter[[2]], width.cutoff = 500L)
    filter_key <- paste(filter_expr, collapse = " ")
    filter_hash <- substr(digest::digest(filter_key), 1, 8)
    data_var <- paste0(source_dataset, "_filtered_", filter_hash)
  } else {
    # Use the source dataset (named dataset or default "data")
    data_var <- source_dataset
  }

  # Load data if needed (shouldn't happen in normal flow, but kept for compatibility)
  if ("data_path" %in% names(spec) && !is.null(spec[["data_path"]]) && data_var == source_dataset && source_dataset == "data") {
    data_file <- basename(spec[["data_path"]])
    lines <- c(lines, paste0("data <- readRDS('", data_file, "')"))
  }

  fn_name <- spec$fn
  args <- spec$args %||% list()

  # Add data argument if page has data (either single or multi-dataset)
  if ("data" %in% names(args) && 
      (("data_path" %in% names(spec) && !is.null(spec[["data_path"]])) || 
       ("has_data" %in% names(spec) && isTRUE(spec$has_data)))) {
    args[["data"]] <- data_var
  }

  if (length(args) == 0) {
    call_str <- paste0("result <- ", fn_name, "()")
  } else {
    serialized_args <- character(0)
    for (arg_name in names(args)) {
      serialized_args <- c(serialized_args,
                           paste0(arg_name, " = ", .serialize_arg(args[[arg_name]])))
    }
    args_str <- paste(serialized_args, collapse = ", ")
    call_str <- paste0("result <- ", fn_name, "(", args_str, ")")
  }

  # Add height support - wrap in explicit height container 
  if (!is.null(spec$height)) {
    height_lines <- c(
      "",
      "# Force container height with explicit wrapper",
      paste0("if (inherits(result, 'highchart')) {"),
      paste0("  result <- highcharter::hc_size(result, height = ", spec$height, ")"),
      paste0("}"),
      paste0("result <- htmltools::div("),
      paste0("  style = 'height: ", spec$height, "px !important; min-height: ", spec$height, "px !important; width: 100%; overflow: visible;',"),
      paste0("  result"),
      paste0(")")
    )
    call_str <- c(call_str, height_lines)
  }

  # Always print the result
  call_str <- c(call_str, "", "result")

  c(lines, call_str)
}


.generate_auto_viz <- function(spec_name, spec) {
  lines <- character(0)

  # Determine which dataset to use
  source_dataset <- spec[["data"]] %||% "data"  # Check if viz specifies a dataset (use [[ to avoid partial matching)
  
  if (!is.null(spec$filter)) {
    # Use pre-filtered dataset created in setup chunk
    filter_expr <- deparse(spec$filter[[2]], width.cutoff = 500L)
    filter_key <- paste(filter_expr, collapse = " ")
    filter_hash <- substr(digest::digest(filter_key), 1, 8)
    data_var <- paste0(source_dataset, "_filtered_", filter_hash)
  } else {
    # Use the source dataset (named dataset or default "data")
    data_var <- source_dataset
  }

  # Load data if specified (shouldn't happen in normal flow, but kept for compatibility)
  if ("data_path" %in% names(spec) && !is.null(spec[["data_path"]]) && data_var == source_dataset && source_dataset == "data") {
    data_file <- basename(spec[["data_path"]])
    lines <- c(lines, paste0("data <- readRDS('", data_file, "')"))
  }

  # Infer function name from parameters
  if ("questions" %in% names(spec)) {
    fn_name <- "create_stackedbars"
  } else if ("x_var" %in% names(spec) && "stack_var" %in% names(spec)) {
    fn_name <- "create_stackedbar"
  } else if ("x_var" %in% names(spec) && "y_var" %in% names(spec) && "value_var" %in% names(spec)) {
    fn_name <- "create_heatmap"
  } else if ("time_var" %in% names(spec)) {
    fn_name <- "create_timeline"
  } else if ("x_var" %in% names(spec)) {
    fn_name <- "create_histogram"
  } else {
    fn_name <- spec_name
  }

  # Clean up arguments
  args <- spec
  
  # Add or replace data argument if page has data
  if (("data_path" %in% names(args) && !is.null(args$data_path)) || 
      ("has_data" %in% names(args) && isTRUE(args$has_data))) {
    args[["data"]] <- data_var  # Use filtered or named dataset
  }
  
  # Remove internal parameters
  args$data_path <- NULL
  args$tabgroup <- NULL
  args$text <- NULL
  args$icon <- NULL
  args$text_position <- NULL
  args$height <- NULL
  args$filter <- NULL
  args$has_data <- NULL
  args$multi_dataset <- NULL
  args$title_tabset <- NULL
  
  # Remove the data argument if it's the source dataset name (internal param that was passed to add_viz)
  if ("data" %in% names(args) && is.character(args[["data"]]) && !is.null(spec[["data"]]) && args[["data"]] == spec[["data"]]) {
    # This was the source dataset name parameter, not actual data
    # It will be added back as data_var above
  }

  # Format function call
  if (length(args) == 0) {
    call_str <- paste0("result <- ", fn_name, "()")
  } else {
    arg_lines <- character(0)
    arg_lines <- c(arg_lines, paste0("result <- ", fn_name, "("))

    for (i in seq_along(args)) {
      arg_name <- names(args)[i]
      arg_value <- .serialize_arg(args[[arg_name]])
      comma <- if (i < length(args)) "," else ""
      arg_lines <- c(arg_lines, paste0("  ", arg_name, " = ", arg_value, comma))
    }

    arg_lines <- c(arg_lines, ")")
    call_str <- arg_lines
  }

  # Add height support - wrap in explicit height container 
  if (!is.null(spec$height)) {
    height_lines <- c(
      "",
      "# Force container height with explicit wrapper",
      paste0("if (inherits(result, 'highchart')) {"),
      paste0("  result <- highcharter::hc_size(result, height = ", spec$height, ")"),
      paste0("}"),
      paste0("result <- htmltools::div("),
      paste0("  style = 'height: ", spec$height, "px !important; min-height: ", spec$height, "px !important; width: 100%; overflow: visible;',"),
      paste0("  result"),
      paste0(")")
    )
    call_str <- c(call_str, height_lines)
  }

  # Always print the result
  call_str <- c(call_str, "", "result")

  c(lines, call_str)
}


.generate_tabgroup_viz <- function(tabgroup_spec, lazy_load_tabs = FALSE) {
  lines <- character(0)

  # Add section header if a label is provided
  if (isTRUE(!is.null(tabgroup_spec$label) && nzchar(tabgroup_spec$label))) {
    lines <- c(lines, paste0("## ", tabgroup_spec$label), "")
  } else if (isTRUE(!is.null(tabgroup_spec$name) && nzchar(tabgroup_spec$name))) {
    lines <- c(lines, paste0("## ", tabgroup_spec$name), "")
  }

  # Check if any viz in this tabgroup has text_before_tabset
  # This should appear right after the section header, before the tabset opens
  # Need to search recursively through nested tabgroups
  text_before_tabset <- NULL
  text_after_tabset <- NULL
  
  # Helper function to recursively find text in nested structures
  find_text_recursive <- function(items) {
    for (item in items) {
      # Check the item itself
      if (isTRUE(!is.null(item$text_before_tabset) && nzchar(item$text_before_tabset))) {
        return(list(before = item$text_before_tabset, after = item$text_after_tabset))
      }
      # If it's a nested tabgroup, search its visualizations
      if (isTRUE(!is.null(item$visualizations) && length(item$visualizations) > 0)) {
        result <- find_text_recursive(item$visualizations)
        if (!is.null(result$before)) {
          return(result)
        }
      }
    }
    return(list(before = NULL, after = NULL))
  }
  
  # Search for text recursively
  text_result <- find_text_recursive(tabgroup_spec$visualizations)
  text_before_tabset <- text_result$before
  text_after_tabset <- text_result$after

  # Add text_before_tabset if provided (RIGHT after header, BEFORE tabset opens)
  if (!is.null(text_before_tabset)) {
    lines <- c(lines, "", text_before_tabset, "")
  }

  # Start tabset (only shows tabs if >1 viz)
  lines <- c(lines, "", "::: {.panel-tabset}", "")

  # Generate each tab
  # First, collect all nested_children tabgroup names to avoid double-rendering
  nested_children_names <- character(0)
  for (viz_item in tabgroup_spec$visualizations) {
    if (isTRUE(!is.null(viz_item$nested_children))) {
      for (nc in viz_item$nested_children) {
        if (isTRUE(!is.null(nc$type) && nc$type == "tabgroup" && !is.null(nc$name))) {
          nested_children_names <- c(nested_children_names, nc$name)
        }
      }
    }
  }
  
  for (i in seq_along(tabgroup_spec$visualizations)) {
    viz <- tabgroup_spec$visualizations[[i]]
    is_first_tab <- (i == 1)

    # Check if this is a nested tabgroup
    # Skip if this tabgroup is already rendered as a nested_child (to avoid duplicate headers)
    if (isTRUE(!is.null(viz$type) && viz$type == "tabgroup")) {
      if (isTRUE(!is.null(viz$name) && viz$name %in% nested_children_names)) {
        # This tabgroup is already rendered as nested_child, skip it here
        next
      }
      
      # This is a nested tabgroup - recursively generate it
      # Tab header: use label or name
      tab_title <- if (isTRUE(!is.null(viz$label) && nzchar(viz$label))) {
        viz$label
      } else if (isTRUE(!is.null(viz$name) && nzchar(viz$name))) {
        viz$name
      } else {
        paste0("Section ", i)
      }
      
      lines <- c(lines, paste0("### ", tab_title), "")
      
      # Apply lazy loading to nested tabgroups if this is not the first tab
      should_lazy_load_nested <- isTRUE(lazy_load_tabs && !is_first_tab)
      if (isTRUE(should_lazy_load_nested)) {
        # Generate unique ID for this nested tabgroup
        chart_id <- paste0("chart-nested-", gsub("[^a-z0-9]", "-", tolower(viz$name %||% paste0("tab-", i))))
        lines <- c(lines,
          "",
          paste0("::: {#", chart_id, " .chart-lazy data-loaded='false'}"),
          ""
        )
      }
      
      # Recursively generate nested tabset (without the ## header, since we have ### tab)
      # Temporarily remove label so it doesn't add ## header
      nested_spec <- viz
      nested_spec$label <- NULL
      nested_spec$name <- NULL
      
      # Generate nested content
      nested_lines <- .generate_tabgroup_viz_content(nested_spec, depth = 1, lazy_load_tabs = lazy_load_tabs)
      lines <- c(lines, nested_lines)
      
      # Close lazy load container if enabled
      if (isTRUE(should_lazy_load_nested)) {
        lines <- c(lines,
          "",
          ":::",
          ""
        )
      }
      
    } else {
      # Regular visualization
      # Tab header: use title_tabset if provided, otherwise fall back to title
      # Safely determine viz_title
      viz_title <- paste0("Chart ", i)  # Default
      
      # Check title
      if (!is.null(viz$title)) {
        title_char <- as.character(viz$title)[1]
        if (!is.na(title_char) && nchar(title_char) > 0) {
          viz_title <- title_char
        }
      }
      
      # Check title_tabset (takes precedence)
      if (!is.null(viz$title_tabset)) {
        title_tabset_char <- as.character(viz$title_tabset)[1]
        if (!is.na(title_tabset_char) && nchar(title_tabset_char) > 0) {
          viz_title <- title_tabset_char
        }
      }

      # Add icon to tab header if provided
      if (isTRUE(!is.null(viz$icon) && !is.na(viz$icon))) {
        if (grepl("{{< iconify", as.character(viz$icon), fixed = TRUE)) {
          icon_shortcode <- viz$icon
        } else {
          icon_shortcode <- icon(viz$icon)
        }
        viz_title <- paste0(icon_shortcode, " ", viz_title)
      }

      lines <- c(lines, paste0("### ", viz_title), "")

      # Check if this visualization has nested children
      has_nested <- isTRUE(!is.null(viz$nested_children) && length(viz$nested_children) > 0)
      
      # Generate visualization code ONLY if:
      # 1. It's not a placeholder type, AND
      # 2. It doesn't have nested children (if it has nested children, it's just a container tab)
      
      # Safely check if should generate viz
      should_generate <- FALSE
      if (!has_nested) {
        is_placeholder <- isTRUE(!is.null(viz$type) && viz$type == "placeholder")
        if (!is_placeholder) {
          should_generate <- TRUE
        }
      }
      
      if (should_generate) {
        # Check if this is a content block or a visualization
        is_content <- isTRUE(!is.null(viz$type) && viz$type %in% c("text", "image", "video", "callout", "code", "divider", "spacer", "gt", "reactable", "table", "DT", "iframe", "accordion", "card", "html", "quote", "badge", "metric", "value_box", "value_box_row"))
        
        if (is_content) {
          # For content blocks, use the content block generator
          viz_lines <- .generate_content_block_inline(viz)
        } else {
          # For visualizations, use the standard viz generator
          should_lazy_load <- isTRUE(lazy_load_tabs && !is_first_tab)
          viz_lines <- .generate_single_viz(paste0("tab_", i), viz, skip_header = TRUE, lazy_load = should_lazy_load, is_first_tab = is_first_tab)
        }
        
        lines <- c(lines, viz_lines)
      }
      
      # Check if this visualization has nested children (nested tabgroups that should appear inside this tab)
      if (isTRUE(has_nested)) {
        # Check if we have tabgroups as nested children - these should become tabs, not headers
        nested_tabgroups <- Filter(function(x) isTRUE(!is.null(x$type) && x$type == "tabgroup"), viz$nested_children)
        
        if (length(nested_tabgroups) > 0) {
          # Create a tabset where each nested tabgroup becomes a TAB
          # This makes "Age" and "Gender" appear as clickable tabs, not static headers
          lines <- c(lines, "", "::: {.panel-tabset}", "")
          
          for (j in seq_along(nested_tabgroups)) {
            nested_tabgroup <- nested_tabgroups[[j]]
            is_first_nested_tab <- (j == 1)
            
            # Tab title for the nested tabgroup (e.g., "Age", "Gender")
            tab_title <- if (isTRUE(!is.null(nested_tabgroup$label) && nzchar(nested_tabgroup$label))) {
              nested_tabgroup$label
            } else if (isTRUE(!is.null(nested_tabgroup$name) && nzchar(nested_tabgroup$name))) {
              nested_tabgroup$name
            } else {
              paste0("Section ", j)
            }
            
            # Add icon if provided in tabgroup label
            if (isTRUE(!is.null(nested_tabgroup$label) && grepl("{{< iconify", nested_tabgroup$label, fixed = TRUE))) {
              # Label already has icon
            } else if (!is.null(nested_tabgroup$icon)) {
              icon_shortcode <- if (grepl("{{< iconify", nested_tabgroup$icon, fixed = TRUE)) {
                nested_tabgroup$icon
              } else {
                icon(nested_tabgroup$icon)
              }
              tab_title <- paste0(icon_shortcode, " ", tab_title)
            }
            
            # Create the tab
            lines <- c(lines, paste0("#### ", tab_title), "")
            
            # Apply lazy loading to nested tabs if this is not the first nested tab
            should_lazy_load_nested_child <- isTRUE(lazy_load_tabs && !is_first_nested_tab)
            if (isTRUE(should_lazy_load_nested_child)) {
              chart_id <- paste0("chart-nested-child-", gsub("[^a-z0-9]", "-", tolower(nested_tabgroup$name %||% paste0("tab-", j))))
              lines <- c(lines,
                "",
                paste0("::: {#", chart_id, " .chart-lazy data-loaded='false'}"),
                ""
              )
            }
            
            # Generate the content of this nested tabgroup (this will contain the Question tabs)
            # Don't add header since we already have the tab header
            nested_content <- .generate_tabgroup_viz_content(nested_tabgroup, depth = 1, skip_header = TRUE, lazy_load_tabs = lazy_load_tabs)
            lines <- c(lines, nested_content)
            
            # Close lazy load container if enabled
            if (isTRUE(should_lazy_load_nested_child)) {
              lines <- c(lines,
                "",
                ":::",
                ""
              )
            }
            
            if (j < length(nested_tabgroups)) {
              lines <- c(lines, "")
            }
          }
          
          # Close the nested tabset
          lines <- c(lines, "", ":::", "")
        }
      }
    }

    if (i < length(tabgroup_spec$visualizations)) {
      lines <- c(lines, "")
    }
  }

  # Close tabset
  lines <- c(lines, "", ":::", "")

  # Add text_after_tabset if provided
  if (!is.null(text_after_tabset)) {
    lines <- c(lines, "", text_after_tabset, "")
  }

  lines
}

# Helper function to generate tabset content without the ## header

.generate_tabgroup_viz_content <- function(tabgroup_spec, depth = 0, skip_header = FALSE, lazy_load_tabs = FALSE) {
  lines <- character(0)
  
  # Add header for this tabgroup if it has a label (for nested tabgroups like "Age")
  # This makes the tabgroup label visible before the tabs
  # Skip header if skip_header is TRUE (when we're creating this as a tab, not a header)
  if (isTRUE(!skip_header && !is.null(tabgroup_spec$label) && nzchar(tabgroup_spec$label) && depth > 0)) {
    header_level <- paste0(rep("#", 4 + depth - 1), collapse = "")
    lines <- c(lines, "", paste0(header_level, " ", tabgroup_spec$label), "")
  }
  
  # Check if this tabgroup only contains a single visualization (no nested tabgroups)
  # If so, render the visualization directly without wrapping in a tabset
  has_nested_tabgroups <- any(sapply(tabgroup_spec$visualizations, function(v) {
    isTRUE(!is.null(v$type) && v$type == "tabgroup")
  }))
  
  single_viz_only <- isTRUE(length(tabgroup_spec$visualizations) == 1 && !has_nested_tabgroups)
  
  if (isTRUE(single_viz_only)) {
    # Single visualization or content block - render it directly without tabset wrapper
    viz <- tabgroup_spec$visualizations[[1]]
    
    # Check if this is a content block
    is_content_block <- isTRUE(!is.null(viz$type) && viz$type %in% c(
      "text", "image", "video", "callout", "divider", "code", "spacer",
      "gt", "reactable", "table", "DT", "iframe", "accordion", "card",
      "html", "quote", "badge", "metric", "value_box", "value_box_row"
    ))
    
    if (is_content_block) {
      # Generate content block
      block_content <- .generate_content_block_inline(viz)
      if (!is.null(block_content)) {
        lines <- c(lines, "", block_content)
      }
    } else {
      # First (and only) viz in tabgroup, no lazy load needed
      viz_lines <- .generate_single_viz(paste0("viz_", depth), viz, skip_header = TRUE, lazy_load = FALSE, is_first_tab = TRUE)
      lines <- c(lines, "", viz_lines)
    }
    return(lines)
  }
  
  # Check if any viz in this tabgroup has text_before_tabset or text_after_tabset
  # NOTE: For nested tabgroups, text_before_tabset should be handled by the parent
  # Only add it here if we're at the root level (depth == 0)
  text_before_tabset <- NULL
  text_after_tabset <- NULL
  
  # Only check for text positioning at root level to avoid duplication
  if (depth == 0) {
    for (viz_item in tabgroup_spec$visualizations) {
      if (isTRUE(!is.null(viz_item$text_before_tabset) && nzchar(viz_item$text_before_tabset))) {
        text_before_tabset <- viz_item$text_before_tabset
        break  # Use the first one found
      }
      if (isTRUE(!is.null(viz_item$text_after_tabset) && nzchar(viz_item$text_after_tabset))) {
        text_after_tabset <- viz_item$text_after_tabset
      }
    }
  
    # Add text_before_tabset if provided
    if (!is.null(text_before_tabset)) {
      lines <- c(lines, "", text_before_tabset, "")
    }
  }

  # Multiple items or contains nested tabgroups - create tabset
  lines <- c(lines, "", "::: {.panel-tabset}", "")

  # Generate each tab
  for (i in seq_along(tabgroup_spec$visualizations)) {
    viz <- tabgroup_spec$visualizations[[i]]
    is_first_tab <- (i == 1)

    # Check if this is a nested tabgroup
    if (isTRUE(!is.null(viz$type) && viz$type == "tabgroup")) {
      # This is a nested tabgroup - recursively generate it
      tab_title <- if (isTRUE(!is.null(viz$label) && nzchar(viz$label))) {
        viz$label
      } else if (isTRUE(!is.null(viz$name) && nzchar(viz$name))) {
        viz$name
      } else {
        paste0("Section ", i)
      }
      
      # Use appropriate header level based on depth
      header_level <- paste0(rep("#", 4 + depth), collapse = "")
      lines <- c(lines, paste0(header_level, " ", tab_title), "")
      
      # Recursively generate nested tabset
      nested_spec <- viz
      nested_spec$label <- NULL
      nested_spec$name <- NULL
      
      nested_lines <- .generate_tabgroup_viz_content(nested_spec, depth = depth + 1, lazy_load_tabs = lazy_load_tabs)
      lines <- c(lines, nested_lines)
      
    } else {
      # Check if this is a content block or a visualization
      is_content_block <- isTRUE(!is.null(viz$type) && viz$type %in% c(
        "text", "image", "video", "callout", "divider", "code", "spacer",
        "gt", "reactable", "table", "DT", "iframe", "accordion", "card",
        "html", "quote", "badge", "metric", "value_box", "value_box_row"
      ))
      
      if (is_content_block) {
        # Content block in a tab
        # Get a display title for the tab
        viz_title <- if (isTRUE(!is.null(viz$title) && nzchar(viz$title))) {
          viz$title
        } else if (isTRUE(viz$type == "text")) {
          paste0("Content ", i)
        } else {
          paste0(tools::toTitleCase(viz$type), " ", i)
        }
        
        # Use appropriate header level based on depth
        header_level <- paste0(rep("#", 4 + depth), collapse = "")
        lines <- c(lines, paste0(header_level, " ", viz_title), "")
        
        # Generate content block
        block_content <- .generate_content_block_inline(viz)
        if (!is.null(block_content)) {
          lines <- c(lines, block_content)
        }
      } else {
        # Regular visualization
        # Inside a tabset, ALWAYS add tab headers for each visualization
        # Otherwise Quarto won't render them as separate tabs
        
        viz_title <- if (isTRUE(!is.null(viz$title_tabset) && nzchar(viz$title_tabset))) {
          viz$title_tabset
        } else if (isTRUE(!is.null(viz$title) && length(viz$title)) > 0 && nzchar(viz$title)) {
          viz$title
        } else {
          paste0("Chart ", i)
        }

        # Add icon to tab header if provided
        if (!is.null(viz$icon)) {
          icon_shortcode <- if (grepl("{{< iconify", viz$icon, fixed = TRUE)) {
            viz$icon
          } else {
            icon(viz$icon)
          }
          viz_title <- paste0(icon_shortcode, " ", viz_title)
        }

        # Use appropriate header level based on depth
        header_level <- paste0(rep("#", 4 + depth), collapse = "")
        lines <- c(lines, paste0(header_level, " ", viz_title), "")

        # Generate visualization code
        # Apply lazy loading to non-first tabs if enabled
        should_lazy_load <- isTRUE(lazy_load_tabs && !is_first_tab)
        viz_lines <- .generate_single_viz(paste0("tab_", depth, "_", i), viz, skip_header = TRUE, lazy_load = should_lazy_load, is_first_tab = is_first_tab)
        lines <- c(lines, viz_lines)
      }
    }

    if (i < length(tabgroup_spec$visualizations)) {
      lines <- c(lines, "")
    }
  }

  # Close tabset
  lines <- c(lines, "", ":::", "")

  # Add text_after_tabset if provided (only at root level to avoid duplication)
  if (isTRUE(depth == 0 && !is.null(text_after_tabset))) {
    lines <- c(lines, "", text_after_tabset, "")
  }

  lines
}

# ===================================================================
# Quarto File Generation
# ===================================================================

#' Generate _quarto.yml configuration file
#'
#' Internal function that generates the complete Quarto website configuration
#' file based on the dashboard project settings. Handles all Quarto website
#' features including navigation, styling, analytics, and deployment options.
#'
#' @param proj A dashboard_project object containing all configuration settings
#' @return Character vector of YAML lines for the _quarto.yml file
#' @details
#' This function generates a comprehensive Quarto configuration including:
#' - Project type and output directory
#' - Website title, favicon, and branding
#' - Navbar with social media links and search
#' - Sidebar with auto-generated navigation
#' - Format settings (theme, CSS, math, code features)
#' - Analytics (Google Analytics, Plausible, GTag)
#' - Deployment settings (GitHub Pages, Netlify)
#' - Iconify filter for icon support

#' Generate unique R chunk label for a visualization
#'
#' Internal function that creates a unique, descriptive R chunk label based on
#' the visualization specification. Uses tabgroup, variable names, title, or type
#' to create meaningful labels.
#'
#' @param spec Visualization specification object
#' @param spec_name Optional name for the specification
#' @return Character string with sanitized chunk label
#' @keywords internal
.generate_chunk_label <- function(spec, spec_name = NULL) {
  label <- NULL
  
  # Priority 1: Use tabgroup (most specific context)
  if (isTRUE(!is.null(spec$tabgroup) && length(spec$tabgroup)) > 0) {
    # Collapse tabgroup vector into single path
    tabgroup_path <- if (is.character(spec$tabgroup) && length(spec$tabgroup) > 1) {
      paste(spec$tabgroup, collapse = "/")
    } else {
      as.character(spec$tabgroup)
    }
    label <- tabgroup_path
  }
  
  # Priority 2: Use relevant variable names
  if (is.null(label)) {
    vars <- character(0)
    
    viz_type <- spec$viz_type %||% spec$type  # Support both new and old field names
    
    if (!is.null(viz_type)) {
      # Type-specific variable extraction
      if (isTRUE(viz_type == "stackedbar" || viz_type == "bar")) {
        if (!is.null(spec$x_var)) vars <- c(vars, spec$x_var)
        if (!is.null(spec$stack_var)) vars <- c(vars, spec$stack_var)
        if (!is.null(spec$group_var)) vars <- c(vars, spec$group_var)
      } else if (viz_type == "stackedbars") {
        if (isTRUE(!is.null(spec$questions) && length(spec$questions)) > 0) {
          vars <- c(vars, spec$questions[1])  # Use first question
        }
      } else if (viz_type == "timeline") {
        if (!is.null(spec$response_var)) vars <- c(vars, spec$response_var)
        if (!is.null(spec$group_var)) vars <- c(vars, spec$group_var)
      } else if (viz_type == "histogram") {
        if (!is.null(spec$x_var)) vars <- c(vars, spec$x_var)
      } else if (viz_type == "heatmap") {
        if (!is.null(spec$x_var)) vars <- c(vars, spec$x_var)
        if (!is.null(spec$y_var)) vars <- c(vars, spec$y_var)
        if (!is.null(spec$value_var)) vars <- c(vars, spec$value_var)
      }
      
      # Construct label from type + variables
      if (length(vars) > 0) {
        # Limit to first 2 variables to keep reasonable length
        vars_label <- paste(head(vars, 2), collapse = "-")
        label <- paste(viz_type, vars_label, sep = "-")
      }
    }
  }
  
  # Priority 3: Use title
  if (is.null(label) && !is.null(spec$title)) {
    label <- spec$title
  }
  
  # Priority 4: Use type or fallback
  if (is.null(label)) {
    viz_type <- spec$viz_type %||% spec$type
    if (!is.null(viz_type)) {
      label <- viz_type
    } else if (!is.null(spec_name)) {
      label <- spec_name
    } else {
      label <- "viz"
    }
  }
  
  # Sanitize label
  label <- tolower(label)
  # Replace slashes with dashes (for tabgroup hierarchy)
  label <- gsub("/", "-", label, fixed = TRUE)
  # Replace underscores, dots, hashes, spaces with dashes
  label <- gsub("[_. #]", "-", label)
  # Replace any other non-alphanumeric with dash
  label <- gsub("[^a-z0-9-]", "-", label)
  # Remove consecutive dashes
  label <- gsub("-+", "-", label)
  # Remove leading/trailing dashes
  label <- gsub("^-|-$", "", label)
  
  # Limit length
  if (nchar(label) > 50) {
    label <- substr(label, 1, 50)
    # Remove trailing dash if any
    label <- gsub("-$", "", label)
  }
  
  # Ensure uniqueness by tracking used labels
  # Store in a package environment to persist across function calls within a generation
  if (!exists(".chunk_label_tracker", envir = .GlobalEnv)) {
    assign(".chunk_label_tracker", list(), envir = .GlobalEnv)
  }
  
  tracker <- get(".chunk_label_tracker", envir = .GlobalEnv)
  
  # Check if label already used
  if (label %in% names(tracker)) {
    # Increment counter
    tracker[[label]] <- tracker[[label]] + 1
    label <- paste0(label, "-", tracker[[label]])
  } else {
    # First use of this label
    tracker[[label]] <- 1
  }
  
  # Update tracker
  assign(".chunk_label_tracker", tracker, envir = .GlobalEnv)
  
  label
}


