# =================================================================
# page_creation.R - Page object creation and manipulation
# =================================================================

#' Create a page object
#'
#' Creates a standalone page object that can be populated with content
#' and later added to a dashboard. Pages can have visualizations added
#' directly (without creating separate content objects), making this
#' the simplest way to build dashboards.
#'
#' @param name Page display name (required)
#' @param data Data frame for this page. All visualizations on this page
#'   will automatically use this data (no need to specify data separately).
#' @param data_path Path to existing data file (alternative to data parameter)
#' @param type Default visualization type for add_viz() calls (e.g., "bar", "histogram", "stackedbar")
#' @param color_palette Default color palette for all visualizations on this page
#' @param icon Optional iconify icon shortcode (e.g., "ph:users-three", "ph:chart-line")
#' @param is_landing_page Whether this should be the landing page (default: FALSE)
#' @param navbar_align Position of page in navbar: "left" (default) or "right"
#' @param tabset_theme Optional tabset theme for this page
#' @param tabset_colors Optional tabset colors for this page
#' @param overlay Whether to show a loading overlay on page load (default: FALSE)
#' @param overlay_theme Theme for loading overlay: "light", "glass", "dark", or "accent"
#' @param overlay_text Text to display in loading overlay (default: "Loading")
#' @param overlay_duration Duration in milliseconds for overlay (default: 2200)
#' @param lazy_load_charts Override dashboard-level lazy loading for this page
#' @param lazy_load_margin Override viewport margin for lazy loading
#' @param lazy_load_tabs Override tab-aware lazy loading for this page
#' @param lazy_debug Override debug mode for lazy loading
#' @param pagination_separator Text for pagination navigation (e.g., "of" -> "1 of 3")
#' @param time_var Name of the time/x-axis column for input filters
#' @param weight_var Name of weight variable for weighted visualizations (applies to all viz)
#' @param filter Filter expression for subsetting data (e.g., ~ year >= 2020)
#' @param drop_na_vars Default for dropping NA values in visualizations
#' @param shared_first_level Logical. When TRUE (default), multiple first-level
#'   tabgroups will share a single tabset. When FALSE, each first-level tabgroup
#'   is rendered as a separate section (stacked vertically).
#' @param ... Additional default parameters passed to all add_viz() calls
#'
#' @return A page_object that can be modified with add_viz(), add_text(), etc.
#' @export
#'
#' @examples
#' \dontrun{
#' # SIMPLE: Add visualizations directly to the page!
#' # No need to create separate content objects
#' analysis <- create_page("Analysis", data = gss, type = "bar") %>%
#'   add_viz(x_var = "degree", title = "Education") %>%
#'   add_viz(x_var = "race", title = "Race") %>%
#'   add_viz(x_var = "happy", title = "Happiness", type = "stackedbar", stack_var = "sex")
#'
#' # LANDING PAGE: Just add text
#' home <- create_page("Home", icon = "ph:house-fill", is_landing_page = TRUE) %>%
#'   add_text("# Welcome!", "", "Explore our data dashboard.") %>%
#'   add_callout("Data updated weekly", type = "tip")
#'
#' # MIXED: Combine direct viz with pre-built content
#' trends <- create_page("Trends", data = gss) %>%
#'   add_viz(x_var = "year", y_var = "happy", type = "timeline") %>%
#'   add_content(detailed_analysis)  # Add pre-built content too
#'
#' # PREVIEW: See what the page looks like before adding to dashboard
#' analysis %>% preview()
#'
#' # BUILD DASHBOARD
#' create_dashboard(title = "My Dashboard") %>%
#'   add_pages(home, analysis, trends) %>%
#'   generate_dashboard()
#' }
create_page <- function(name,
                        data = NULL,
                        data_path = NULL,
                        type = NULL,
                        color_palette = NULL,
                        icon = NULL,
                        is_landing_page = FALSE,
                        navbar_align = c("left", "right"),
                        tabset_theme = NULL,
                        tabset_colors = NULL,
                        overlay = FALSE,
                        overlay_theme = c("light", "glass", "dark", "accent"),
                        overlay_text = "Loading",
                        overlay_duration = 2200,
                        lazy_load_charts = NULL,
                        lazy_load_margin = NULL,
                        lazy_load_tabs = NULL,
                        lazy_debug = NULL,
                        pagination_separator = NULL,
                        time_var = NULL,
                        weight_var = NULL,
                        filter = NULL,
                        drop_na_vars = NULL,
                        shared_first_level = TRUE,
                        ...) {

  # Capture the calling environment for proper evaluation of symbols
  call_env <- parent.frame()
  
  # Convert variable arguments to strings (supports both quoted and unquoted)
  time_var <- .as_var_string(rlang::enquo(time_var))
  weight_var <- .as_var_string(rlang::enquo(weight_var))

  if (missing(name) || is.null(name) || !is.character(name) || nchar(name) == 0) {
    stop("'name' is required and must be a non-empty string")
  }

  navbar_align <- match.arg(navbar_align)
  overlay_theme <- match.arg(overlay_theme)

  # Capture additional defaults for visualizations (with NSE support)
  call_args <- as.list(match.call(expand.dots = FALSE))
  dot_args_raw <- call_args[["..."]]
  if (is.null(dot_args_raw)) dot_args_raw <- list()
  
  var_params <- c("x_var", "y_var", "group_var", "stack_var", 
                  "region_var", "value_var", "color_var", "size_var",
                  "join_var", "click_var", "subgroup_var")
  var_vector_params <- c("x_vars", "tooltip_vars")
  
  extra_defaults <- lapply(names(dot_args_raw), function(nm) {
    val <- dot_args_raw[[nm]]
    if (nm %in% var_params && is.symbol(val)) {
      as.character(val)
    } else if (nm %in% var_vector_params) {
      if (is.call(val) && identical(val[[1]], as.symbol("c"))) {
        vapply(as.list(val)[-1], function(x) {
          if (is.symbol(x)) as.character(x) else if (is.character(x)) x else eval(x, envir = call_env)
        }, character(1))
      } else {
        eval(val, envir = call_env)
      }
    } else {
      eval(val, envir = call_env)
    }
  })
  names(extra_defaults) <- names(dot_args_raw)

  structure(
    list(
      name = name,
      data = data,
      data_path = data_path,
      icon = icon,
      is_landing_page = is_landing_page,
      navbar_align = navbar_align,
      tabset_theme = tabset_theme,
      tabset_colors = tabset_colors,
      overlay = overlay,
      overlay_theme = overlay_theme,
      overlay_text = overlay_text,
      overlay_duration = overlay_duration,
      lazy_load_charts = lazy_load_charts,
      lazy_load_margin = lazy_load_margin,
      lazy_load_tabs = lazy_load_tabs,
      lazy_debug = lazy_debug,
      pagination_separator = pagination_separator,
      time_var = time_var,
      weight_var = weight_var,
      filter = filter,
      # Visualization defaults
      viz_defaults = c(
        list(type = type, color_palette = color_palette, 
             weight_var = weight_var, drop_na_vars = drop_na_vars),
        extra_defaults
      ),
      # Internal content collection for direct viz additions
      .items = list(),
      .tabgroup_labels = list(),
      .shared_first_level = shared_first_level,
      # External content collections (from add_content)
      content = list(),
      text = NULL
    ),
    class = c("page_object", "list")
  )
}


#' Add text to a page
#'
#' Add markdown text content directly to a page object.
#'
#' @param page A page_object created by create_page()
#' @param text First line of text
#' @param ... Additional text lines
#' @param tabgroup Optional tabgroup for the text
#'
#' @return The updated page_object
#' @export
add_text.page_object <- function(page, text, ..., tabgroup = NULL) {
  if (!inherits(page, "page_object")) {
    stop("First argument must be a page_object created by create_page()")
  }

  # Combine text and ... into lines
  all_text <- c(text, unlist(list(...)))
  
  text_spec <- structure(
    list(
      type = "text",
      content = paste(all_text, collapse = "\n\n"),  # Use 'content' for consistency with add_text()
      tabgroup = tabgroup
    ),
    class = "content_block"
  )

  page$.items <- c(page$.items, list(text_spec))
  page
}


#' Add a callout to a page
#'
#' Add callout boxes directly to a page object.
#'
#' @param page A page_object created by create_page()
#' @param text Callout text content
#' @param type Callout type: "note", "tip", "warning", "important", "caution"
#' @param title Optional callout title
#' @param tabgroup Optional tabgroup
#'
#' @return The updated page_object
#' @export
add_callout.page_object <- function(page, text, type = "note", title = NULL, tabgroup = NULL) {
  if (!inherits(page, "page_object")) {
    stop("First argument must be a page_object created by create_page()")
  }

  callout_spec <- structure(
    list(
      type = "callout",
      callout_type = type,
      text = text,
      title = title,
      tabgroup = tabgroup
    ),
    class = "content_block"
  )

  page$.items <- c(page$.items, list(callout_spec))
  page
}


#' Add content collection(s) to a page
#'
#' Add one or more pre-built content collections (from create_viz/create_content) to a page.
#' Use this when you have complex content built separately.
#'
#' @param page A page_object created by create_page()
#' @param ... One or more content collections (from create_viz/create_content)
#'
#' @return The updated page_object
#' @export
#' @examples
#' \dontrun{
#' # Add a single collection
#' page %>% add_content(my_viz)
#'
#' # Add multiple collections at once
#' page %>% add_content(viz1, viz2, viz3)
#' }
add_content <- function(page, ...) {
  if (!inherits(page, "page_object")) {
    stop("'page' must be a page_object created by create_page()")
  }

  contents <- list(...)
  
  if (length(contents) == 0) {
    warning("No content provided to add_content()")
    return(page)
  }
  
  for (i in seq_along(contents)) {
    content <- contents[[i]]
    if (!is_content(content)) {
      stop("Argument ", i + 1, " must be a content collection (from create_viz/create_content)")
    }
    page$content <- c(page$content, list(content))
  }
  
  page
}


#' Set tabgroup labels for a page
#'
#' Customize tab labels with icons or different text.
#'
#' @param page A page_object
#' @param ... Named arguments where names are tabgroup IDs and values are display labels
#'
#' @return The updated page_object
#' @export
#'
#' @examples
#' \dontrun{
#' create_page("Analysis", data = gss, type = "bar") %>%
#'   add_viz(x_var = "degree", tabgroup = "demographics") %>%
#'   add_viz(x_var = "happy", tabgroup = "wellbeing") %>%
#'   set_tabgroup_labels(
#'     demographics = "{{< iconify ph:users-fill >}} Demographics",
#'     wellbeing = "{{< iconify ph:heart-fill >}} Wellbeing"
#'   )
#' }
set_tabgroup_labels.page_object <- function(page, ...) {
  if (!inherits(page, "page_object")) {
    stop("First argument must be a page_object")
  }
  
  labels <- list(...)
  page$.tabgroup_labels <- c(page$.tabgroup_labels, labels)
  page
}


#' Add multiple pages to a dashboard
#'
#' Adds one or more page objects to a dashboard.
#'
#' @param proj A dashboard_project object
#' @param ... One or more page_objects to add
#'
#' @return The updated dashboard_project object
#' @export
#'
#' @examples
#' \dontrun{
#' home <- create_page("Home", is_landing_page = TRUE) %>%
#'   add_text("# Welcome!")
#'
#' analysis <- create_page("Analysis", data = gss, type = "bar") %>%
#'   add_viz(x_var = "degree", title = "Education") %>%
#'   add_viz(x_var = "race", title = "Race")
#'
#' create_dashboard(title = "My Dashboard") %>%
#'   add_pages(home, analysis) %>%
#'   generate_dashboard()
#' }
add_pages <- function(proj, ...) {
  if (!inherits(proj, "dashboard_project")) {
    stop("'proj' must be a dashboard_project object")
  }

  pages <- list(...)

  # Handle case where a list of pages is passed
  if (length(pages) == 1 && is.list(pages[[1]]) && !inherits(pages[[1]], "page_object")) {
    pages <- pages[[1]]
  }

  for (page in pages) {
    if (!inherits(page, "page_object")) {
      stop("All arguments must be page_objects created by create_page()")
    }

    proj <- .add_page_from_object(proj, page)
  }

  proj
}


#' Convert page_object to content collection
#' @noRd
.page_to_content <- function(page) {
  # Start with page's direct items
  content <- create_viz(data = page$data)
  content$items <- page$.items
  content$tabgroup_labels <- page$.tabgroup_labels
  content$defaults <- page$viz_defaults
  
  # Add external content collections
  for (ext_content in page$content) {
    content <- combine_content(content, ext_content)
    
    # Propagate sidebar from external content
    if (!is.null(ext_content$sidebar)) {
      content$sidebar <- ext_content$sidebar
    }
  }
  
  # Also propagate sidebar from page itself if set
  if (!is.null(page$sidebar)) {
    content$sidebar <- page$sidebar
  }
  
  content
}


#' Internal: Convert page_object to add_page call
#' @noRd
.add_page_from_object <- function(proj, page) {
  # Convert page content to content collection
  combined_content <- .page_to_content(page)
  
  # If no items AND no sidebar, set to NULL
  if (length(combined_content$items) == 0 && is.null(combined_content$sidebar)) {
    combined_content <- NULL
  }

  # Build text from text field if present
  text_content <- page$text

  # Call add_page with all the page's parameters
  add_dashboard_page(
    proj = proj,
    name = page$name,
    data = page$data,
    data_path = page$data_path,
    content = combined_content,
    text = text_content,
    icon = page$icon,
    is_landing_page = page$is_landing_page,
    navbar_align = page$navbar_align,
    tabset_theme = page$tabset_theme,
    tabset_colors = page$tabset_colors,
    overlay = page$overlay,
    overlay_theme = page$overlay_theme,
    overlay_text = page$overlay_text,
    overlay_duration = page$overlay_duration,
    lazy_load_charts = page$lazy_load_charts,
    lazy_load_margin = page$lazy_load_margin,
    lazy_load_tabs = page$lazy_load_tabs,
    lazy_debug = page$lazy_debug,
    pagination_separator = page$pagination_separator,
    time_var = page$time_var
  )
}


#' Print method for page objects
#' @export
print.page_object <- function(x, ...) {
  rule_char <- cli::symbol$line
  cat("-- ", cli::style_bold("Page:"), " ", x$name, " ", 
      strrep(rule_char, max(0, 55 - nchar(x$name))), "\n", sep = "")

  # Page info line
  info_parts <- c()
  if (x$is_landing_page) info_parts <- c(info_parts, cli::col_green("landing page"))
  if (!is.null(x$data)) {
    if (is.data.frame(x$data)) {
      info_parts <- c(info_parts, paste0(cli::col_green(cli::symbol$tick), " data: ", nrow(x$data), " rows x ", ncol(x$data), " cols"))
    } else {
      info_parts <- c(info_parts, paste0(cli::col_green(cli::symbol$tick), " data attached"))
    }
  }
  if (!is.null(x$viz_defaults$type)) {
    info_parts <- c(info_parts, paste0("default: ", x$viz_defaults$type))
  }

  if (length(info_parts) > 0) {
    cat(paste(info_parts, collapse = " | "), "\n")
  }

  # Collect all items from direct items and content collections
  all_items <- list()
  
  # Add direct items
  if (length(x$.items) > 0) {
    all_items <- c(all_items, x$.items)
  }
  
  # Add items from content collections
  if (length(x$content) > 0) {
    for (cc in x$content) {
      if (is.list(cc) && !is.null(cc$items)) {
        all_items <- c(all_items, cc$items)
      }
    }
  }
  
  total <- length(all_items)

  if (total > 0) {
    cat(cli::col_cyan(total), " items\n\n", sep = "")
    
    # Build and print the tree structure (same as content collections)
    tree <- .build_print_tree(all_items)
    .print_cli_tree(tree, all_items)
  } else {
    cat("\n", cli::col_silver("No content added yet"), "\n", sep = "")
    cat(cli::col_silver("  Tip: Use add_viz(), add_text(), or add_content()"), "\n", sep = "")
  }

  invisible(x)
}
