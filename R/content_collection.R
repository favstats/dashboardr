# =================================================================
# content_collection - Pipeable mixed content system
# =================================================================

#' Create a new content/visualization collection (alias for create_viz)
#'
#' This is an alias for \code{\link{create_viz}} - both functions are identical.
#' Use whichever name makes more sense for your use case. The returned collection
#' can be built up with any combination of add_viz(), add_text(), and add_image().
#'
#' Note: Both names return the same object with both "content_collection" and
#' "viz_collection" classes for backward compatibility.
#'
#' @param data Optional data frame to use for all visualizations in this collection.
#'   This data will be used by add_viz() calls and can be used with preview().
#' @param tabgroup_labels Named vector/list mapping tabgroup IDs to display names
#' @param shared_first_level Logical. When TRUE (default), multiple first-level
#'   tabgroups will share a single tabset. When FALSE, each first-level tabgroup
#'   is rendered as a separate section (stacked vertically).
#' @param ... Default parameters to apply to all subsequent add_viz() calls.
#'   Common defaults include: type, color_palette, stacked_type, horizontal, etc.
#'   Any parameter that can be passed to add_viz() can be set as a default here.
#' @return A content_collection (also a viz_collection for compatibility)
#' @export
#' @examples
#' \dontrun{
#' # Create content with inline data for preview
#' content <- create_content(data = mtcars) %>%
#'   add_text("# MPG Analysis") %>%
#'   add_viz(type = "histogram", x_var = "mpg") %>%
#'   preview()
#'
#' # Set shared defaults like type - all add_viz() calls inherit these
#' content <- create_content(
#'   data = survey_df,
#'   type = "stackedbar",
#'   stacked_type = "percent",
#'   horizontal = TRUE
#' ) %>%
#'   add_viz(x_var = "age", stack_var = "response", tabgroup = "Age") %>%
#'   add_viz(x_var = "gender", stack_var = "response", tabgroup = "Gender")
#'
#' # These are equivalent:
#' content <- create_content() %>%
#'   add_text("# Title") %>%
#'   add_viz(type = "histogram", x_var = "age")
#'
#' content <- create_viz() %>%
#'   add_text("# Title") %>%
#'   add_viz(type = "histogram", x_var = "age")
#' }
create_content <- function(data = NULL, tabgroup_labels = NULL, shared_first_level = TRUE, ...) {
  create_viz(
    data = data,
    tabgroup_labels = tabgroup_labels,
    shared_first_level = shared_first_level,
    ...
  )
}

#' Add text to content collection (pipeable)
#'
#' Adds a text block to a content collection. Can be used standalone or in a pipe.
#' Supports viz_collection as first argument for seamless piping.
#'
#' @param x A content_collection, viz_collection, sidebar_container, page_object, or NULL
#' @param text Markdown text content (can be multi-line)
#' @param tabgroup Optional tabgroup for organizing content (character vector for nested tabs)
#' @param ... Additional text lines (will be combined with newlines)
#' @param show_when One-sided formula controlling conditional display based on input values.
#' @return Updated content_collection object
#' @export
#' @examples
#' \dontrun{
#' # Standalone
#' text_block <- add_text("# Welcome")
#'
#' # Pipe with content
#' content <- create_content() %>%
#'   add_text("## Introduction")
#'
#' # With tabgroup
#' content <- create_content() %>%
#'   add_text("## Section 1", tabgroup = "Overview")
#'
#' # Pipe directly from viz
#' content <- create_viz() %>%
#'   add_viz(type = "histogram", x_var = "age") %>%
#'   add_text("Analysis complete")
#' }
add_text <- function(x = NULL, text, ..., tabgroup = NULL, show_when = NULL) {
  # Dispatch to page_object method if appropriate
  if (inherits(x, "page_object")) {
    return(add_text.page_object(x, text, ..., tabgroup = tabgroup, show_when = show_when))
  }
  
  # Handle sidebar_container - add text block to sidebar
  if (inherits(x, "sidebar_container")) {
    # Combine all text arguments
    extra_args <- list(...)
    if (length(extra_args) > 0) {
      all_text <- c(text, unlist(extra_args))
    } else {
      all_text <- text
    }
    final_content <- paste(all_text, collapse = "\n")
    
    text_block <- structure(list(type = "text", content = final_content, show_when = show_when), class = "content_block")
    x$blocks <- c(x$blocks, list(text_block))
    return(x)
  }
  
  content_collection <- x
  
  # Track if we're in pipeable mode or standalone mode
  is_pipeable <- FALSE
  was_null <- FALSE
  
  # If first argument is a string, treat it as text (standalone mode)
  if (is.character(content_collection) && missing(text)) {
    text <- content_collection
    was_null <- TRUE
    content_collection <- NULL
  }
  
  # If content_collection is NULL, we're in standalone mode
  if (is.null(content_collection)) {
    # Standalone mode - will return content_block
    was_null <- TRUE
  } else if (is_content(content_collection)) {
    # Pipeable mode - will return content_collection
    is_pipeable <- TRUE
  } else if (is_content_block(content_collection)) {
    # If it's a content block, wrap it in a collection
    old_block <- content_collection
    content_collection <- create_content()
    content_collection$items <- list(old_block)
    is_pipeable <- TRUE
  } else {
    stop("First argument must be a content collection, page_object, sidebar_container, content_block, character string, or NULL", call. = FALSE)
  }
  
  # Combine all text arguments from ...
  extra_args <- list(...)
  text_content <- character(0)
  
  if (length(extra_args) > 0) {
    all_text <- c(text, unlist(extra_args))
  } else {
    all_text <- text
  }
  
  for (arg in all_text) {
    if (is.character(arg)) {
      text_content <- c(text_content, arg)
    } else {
      text_content <- c(text_content, as.character(arg))
    }
  }
  
  # Join with newlines
  final_content <- paste(text_content, collapse = "\n")
  
  # Parse tabgroup (handles "hello/subtab" notation)
  parsed_tabgroup <- .parse_tabgroup(tabgroup)
  
  # Create text block
  text_block <- structure(
    list(
      type = "text",
      content = final_content,
      tabgroup = parsed_tabgroup,
      show_when = show_when
    ),
    class = "content_block"
  )
  
  # Return appropriate type
  if (was_null) {
    # Standalone mode - return just the content block
    return(text_block)
  } else {
    # Pipeable mode - add insertion index and add to collection
    insertion_idx <- length(content_collection$items) + 1
    text_block$.insertion_index <- insertion_idx
    content_collection$items <- c(content_collection$items, list(text_block))
    return(content_collection)
  }
}

#' Add image to content collection (pipeable)
#'
#' Adds an image block to a content collection. Can be used standalone or in a pipe.
#' Supports viz_collection as first argument for seamless piping.
#'
#' @param content_collection A content_collection, viz_collection, or NULL
#' @param src Image source path or URL
#' @param alt Alt text for the image
#' @param caption Optional caption text displayed below the image
#' @param width Optional width (e.g., "300px", "50%", "100%")
#' @param height Optional height (e.g., "200px")
#' @param align Image alignment: "left", "center", "right" (default: "center")
#' @param link Optional URL to link the image to
#' @param class Optional CSS class for custom styling
#' @param tabgroup Optional tabgroup for organizing content (character vector for nested tabs)
#' @param show_when One-sided formula controlling conditional display based on input values.
#' @return Updated content_collection object
#' @export
#' @examples
#' \dontrun{
#' # Standalone
#' img <- add_image(src = "logo.png", alt = "Logo")
#'
#' # Pipe with content
#' content <- create_content() %>%
#'   add_text("Welcome!") %>%
#'   add_image(src = "chart.png", alt = "Chart")
#'
#' # With tabgroup
#' content <- create_content() %>%
#'   add_image(src = "chart.png", alt = "Chart", tabgroup = "Gallery")
#'
#' # Pipe directly from viz
#' content <- create_viz() %>%
#'   add_viz(type = "bar", x_var = "category") %>%
#'   add_image(src = "logo.png", alt = "Logo")
#' }
add_image <- function(content_collection = NULL, src, alt = NULL, caption = NULL, 
                      width = NULL, height = NULL, align = c("center", "left", "right"), 
                      link = NULL, class = NULL, tabgroup = NULL, show_when = NULL) {
  .validate_show_when(show_when)
  # Handle sidebar_container
  if (inherits(content_collection, "sidebar_container")) {
    align <- match.arg(align)
    image_block <- structure(list(
      type = "image", src = src, alt = alt %||% "", caption = caption,
      width = width, height = height, align = align, link = link, class = class,
      show_when = show_when
    ), class = "content_block")
    content_collection$blocks <- c(content_collection$blocks, list(image_block))
    return(content_collection)
  }
  
  # Track if we're in pipeable mode or standalone mode
  is_pipeable <- FALSE
  was_null <- FALSE
  
  # If content_collection is NULL, we're in standalone mode
  if (is.null(content_collection)) {
    was_null <- TRUE
  } else if (is_content(content_collection)) {
    # Pipeable mode
    is_pipeable <- TRUE
  } else if (is_content_block(content_collection)) {
    # If it's a content block, wrap it in a collection
    old_block <- content_collection
    content_collection <- create_content()
    content_collection$items <- list(old_block)
    is_pipeable <- TRUE
  } else {
    stop("First argument must be a content collection, sidebar_container, content_block, or NULL", call. = FALSE)
  }
  
  # Validate src
  if (is.null(src) || !is.character(src) || length(src) != 1 || nchar(src) == 0) {
    stop("src must be a non-empty character string", call. = FALSE)
  }
  
  # Validate and match align
  align <- match.arg(align)
  
  # Validate optional parameters
  if (!is.null(alt) && (!is.character(alt) || length(alt) != 1)) {
    stop("alt must be a character string or NULL", call. = FALSE)
  }
  if (!is.null(caption) && (!is.character(caption) || length(caption) != 1)) {
    stop("caption must be a character string or NULL", call. = FALSE)
  }
  if (!is.null(width) && (!is.character(width) || length(width) != 1)) {
    stop("width must be a character string or NULL", call. = FALSE)
  }
  if (!is.null(height) && (!is.character(height) || length(height) != 1)) {
    stop("height must be a character string or NULL", call. = FALSE)
  }
  if (!is.null(link) && (!is.character(link) || length(link) != 1)) {
    stop("link must be a character string or NULL", call. = FALSE)
  }
  if (!is.null(class) && (!is.character(class) || length(class) != 1)) {
    stop("class must be a character string or NULL", call. = FALSE)
  }
  
  # Create image block
  image_block <- structure(
    list(
      type = "image",
      src = src,
      alt = alt %||% "",
      caption = caption,
      width = width,
      height = height,
      align = align,
      link = link,
      class = class,
      tabgroup = .parse_tabgroup(tabgroup),
      show_when = show_when
    ),
    class = "content_block"
  )
  
  # Return appropriate type
  if (was_null) {
    # Standalone mode - return just the content block
    return(image_block)
  } else {
    # Pipeable mode - add insertion index and add to collection
    insertion_idx <- length(content_collection$items) + 1
    image_block$.insertion_index <- insertion_idx
    content_collection$items <- c(content_collection$items, list(image_block))
    return(content_collection)
  }
}

#' Add callout box
#' @param x A content_collection, viz_collection, sidebar_container, or page_object
#' @param text Callout content
#' @param type Callout type (note/tip/warning/caution/important)
#' @param title Optional title
#' @param icon Optional icon
#' @param collapse Whether callout is collapsible
#' @param tabgroup Optional tabgroup for organizing content (character vector for nested tabs)
#' @param show_when One-sided formula controlling conditional display based on input values.
#' @return Updated content_collection
#' @export
add_callout <- function(x, text, type = c("note", "tip", "warning", "caution", "important"),
                        title = NULL, icon = NULL, collapse = FALSE, tabgroup = NULL, show_when = NULL) {
  .validate_show_when(show_when)
  # Dispatch to page_object method if appropriate
  if (inherits(x, "page_object")) {
    return(add_callout.page_object(x, text, type = type, title = title, tabgroup = tabgroup, show_when = show_when))
  }
  
  # Handle sidebar_container
  if (inherits(x, "sidebar_container")) {
    type <- match.arg(type)
    callout_block <- structure(list(
      type = "callout", callout_type = type, content = text,
      title = title, icon = icon, collapse = collapse,
      show_when = show_when
    ), class = "content_block")
    x$blocks <- c(x$blocks, list(callout_block))
    return(x)
  }
  
  content <- x
  if (!is_content(content)) {
    stop("First argument must be a content collection, sidebar_container, or page_object", call. = FALSE)
  }
  
  type <- match.arg(type)
  
  callout_block <- structure(list(
    type = "callout",
    callout_type = type,
    content = text,
    title = title,
    icon = icon,
    collapse = collapse,
    tabgroup = .parse_tabgroup(tabgroup),
    show_when = show_when
  ), class = "content_block")
  
  insertion_idx <- length(content$items) + 1
  callout_block$.insertion_index <- insertion_idx
  content$items <- c(content$items, list(callout_block))
  content
}

#' Add horizontal divider
#' @param content A content_collection, viz_collection, or page_object
#' @param style Divider style ("default", "thick", "dashed", "dotted")
#' @param tabgroup Optional tabgroup for organizing content (character vector for nested tabs)
#' @param show_when One-sided formula controlling conditional display based on input values.
#' @return Updated object (same type as input)
#' @export
add_divider <- function(content, style = "default", tabgroup = NULL, show_when = NULL) {
  divider_block <- structure(list(
    type = "divider",
    style = style,
    tabgroup = .parse_tabgroup(tabgroup),
    show_when = show_when
  ), class = "content_block")
  
  # Handle page_object
  if (inherits(content, "page_object")) {
    content$.items <- c(content$.items, list(divider_block))
    return(content)
  }
  
  # Handle sidebar_container
  if (inherits(content, "sidebar_container")) {
    content$blocks <- c(content$blocks, list(divider_block))
    return(content)
  }
  
  if (!is_content(content)) {
    stop("First argument must be a content collection, sidebar_container, or page_object", call. = FALSE)
  }
  
  insertion_idx <- length(content$items) + 1
  divider_block$.insertion_index <- insertion_idx
  content$items <- c(content$items, list(divider_block))
  content
}

#' Add code block
#' @param content A content_collection, viz_collection, or page_object
#' @param code Code content
#' @param language Programming language for syntax highlighting
#' @param caption Optional caption
#' @param filename Optional filename to display
#' @param tabgroup Optional tabgroup for organizing content (character vector for nested tabs)
#' @param show_when One-sided formula controlling conditional display based on input values.
#' @return Updated object (same type as input)
#' @export
add_code <- function(content, code, language = "r", caption = NULL, filename = NULL, tabgroup = NULL, show_when = NULL) {
  code_block <- structure(list(
    type = "code",
    code = code,
    language = language,
    caption = caption,
    filename = filename,
    tabgroup = .parse_tabgroup(tabgroup),
    show_when = show_when
  ), class = "content_block")
  
  # Handle page_object
  if (inherits(content, "page_object")) {
    content$.items <- c(content$.items, list(code_block))
    return(content)
  }
  
  if (!is_content(content)) {
    stop("First argument must be a content collection or page_object", call. = FALSE)
  }
  
  insertion_idx <- length(content$items) + 1
  code_block$.insertion_index <- insertion_idx
  content$items <- c(content$items, list(code_block))
  content
}

#' Add vertical spacer
#' @param content A content_collection, viz_collection, or page_object
#' @param height Height (CSS unit, e.g. "2rem", "50px")
#' @param tabgroup Optional tabgroup for organizing content (character vector for nested tabs)
#' @param show_when One-sided formula controlling conditional display based on input values.
#' @return Updated object (same type as input)
#' @export
add_spacer <- function(content, height = "2rem", tabgroup = NULL, show_when = NULL) {
  spacer_block <- structure(list(
    type = "spacer",
    height = height,
    tabgroup = .parse_tabgroup(tabgroup),
    show_when = show_when
  ), class = "content_block")
  
  # Handle page_object
  if (inherits(content, "page_object")) {
    content$.items <- c(content$.items, list(spacer_block))
    return(content)
  }
  
  # Handle sidebar_container
  if (inherits(content, "sidebar_container")) {
    content$blocks <- c(content$blocks, list(spacer_block))
    return(content)
  }
  
  if (!is_content(content)) {
    stop("First argument must be a content collection, sidebar_container, or page_object", call. = FALSE)
  }
  
  insertion_idx <- length(content$items) + 1
  spacer_block$.insertion_index <- insertion_idx
  content$items <- c(content$items, list(spacer_block))
  content
}

#' Add gt table
#' @param content A content_collection object
#' @param gt_object A gt table object (from gt::gt()) OR a data frame (will be auto-converted)
#' @param caption Optional caption
#' @param tabgroup Optional tabgroup for organizing content (character vector for nested tabs)
#' @param show_when One-sided formula controlling conditional display based on input values.
#' @return Updated content_collection
#' @export
#' @examples
#' \dontrun{
#' # Option 1: Pass a styled gt object
#' my_table <- gt::gt(mtcars) %>%
#'   gt::tab_header(title = "Cars") %>%
#'   gt::fmt_number(columns = everything(), decimals = 1)
#' 
#' content <- create_content() %>%
#'   add_gt(my_table)
#'   
#' # Option 2: Pass a data frame (auto-converted)
#' content <- create_content() %>%
#'   add_gt(mtcars, caption = "Motor Trend Cars")
#' }
add_gt <- function(content, gt_object, caption = NULL, tabgroup = NULL, show_when = NULL) {
  # Accept both gt tables and data frames
  gt_block <- structure(list(
    type = "gt",
    gt_object = gt_object,
    caption = caption,
    is_dataframe = is.data.frame(gt_object),
    tabgroup = .parse_tabgroup(tabgroup),
    show_when = show_when
  ), class = "content_block")
  
  if (inherits(content, "page_object")) {
    content$.items <- c(content$.items, list(gt_block))
    return(content)
  }
  
  if (!is_content(content)) {
    stop("First argument must be a content collection or page_object", call. = FALSE)
  }
  
  insertion_idx <- length(content$items) + 1
  gt_block$.insertion_index <- insertion_idx
  content$items <- c(content$items, list(gt_block))
  content
}

#' Add reactable table
#' @param content A content_collection object
#' @param reactable_object A reactable object (from reactable::reactable()) OR a data frame (will be auto-converted)
#' @param tabgroup Optional tabgroup for organizing content (character vector for nested tabs)
#' @param filter_vars Optional character vector of input filter variables to apply to this block.
#' @param show_when One-sided formula controlling conditional display based on input values.
#' @return Updated content_collection
#' @export
#' @examples
#' \dontrun{
#' # Option 1: Pass a styled reactable object
#' my_table <- reactable::reactable(
#'   mtcars,
#'   columns = list(mpg = reactable::colDef(name = "MPG")),
#'   searchable = TRUE,
#'   striped = TRUE
#' )
#' 
#' content <- create_content() %>%
#'   add_reactable(my_table)
#'   
#' # Option 2: Pass a data frame (auto-converted with defaults)
#' content <- create_content() %>%
#'   add_reactable(mtcars)
#' }
add_reactable <- function(content, reactable_object, tabgroup = NULL, filter_vars = NULL, show_when = NULL) {
  filter_vars <- .normalize_filter_vars(filter_vars)
  is_dataframe <- is.data.frame(reactable_object)
  if (!is.null(filter_vars) && !is_dataframe) {
    stop("filter_vars requires reactable_object to be a data frame", call. = FALSE)
  }
  if (is_dataframe) {
    rlang::check_installed("reactable", reason = "to use add_reactable")
    reactable_obj <- reactable::reactable(reactable_object)
  } else {
    reactable_obj <- reactable_object
  }
  reactable_block <- structure(list(
    type = "reactable",
    reactable_object = reactable_obj,
    reactable_data = if (is_dataframe) reactable_object else NULL,
    is_dataframe = is_dataframe,
    filter_vars = filter_vars,
    tabgroup = .parse_tabgroup(tabgroup),
    show_when = show_when
  ), class = "content_block")
  
  if (inherits(content, "page_object")) {
    content$.items <- c(content$.items, list(reactable_block))
    return(content)
  }
  
  if (!is_content(content)) {
    stop("First argument must be a content collection or page_object", call. = FALSE)
  }
  
  insertion_idx <- length(content$items) + 1
  reactable_block$.insertion_index <- insertion_idx
  content$items <- c(content$items, list(reactable_block))
  content
}

#' Add a custom highcharter chart
#' 
#' Add a pre-built highcharter chart to your dashboard. This allows you to
#' create complex, customized highcharter visualizations and include them
#' directly without using dashboardr's viz_* functions.
#' 
#' @param content A content_collection, page_object, or dashboard object
#' @param hc_object A highcharter object created with highcharter::highchart() or hchart()
#' @param height Optional height for the chart (e.g., "400px", "50vh"). If NULL (default), no height is set and highcharter handles its own sizing
#' @param tabgroup Optional tabgroup for organizing content (character vector for nested tabs)
#' @param filter_vars Optional character vector of input filter variables to apply to this block.
#' @param show_when One-sided formula controlling conditional display based on input values.
#' @return Updated content object
#' @export
#' @examples
#' \dontrun{
#' library(highcharter)
#' 
#' # Create a custom highcharter chart
#' my_chart <- hchart(mtcars, "scatter", hcaes(x = wt, y = mpg, group = cyl)) %>%
#'   hc_title(text = "Custom Scatter Plot") %>%
#'   hc_subtitle(text = "Made with highcharter") %>%
#'   hc_add_theme(hc_theme_smpl())
#' 
#' # Add it to a page
#' page <- create_page("Charts") %>%
#'   add_hc(my_chart) %>%
#'   add_hc(another_chart, height = "500px", tabgroup = "My Charts")
#' }
add_hc <- function(content, hc_object, height = NULL, tabgroup = NULL, filter_vars = NULL, show_when = NULL) {
  filter_vars <- .normalize_filter_vars(filter_vars)
  # Validate it's a highcharter object
  if (!inherits(hc_object, "highchart")) {
    stop("hc_object must be a highcharter object (created with highchart() or hchart())", call. = FALSE)
  }
  
  hc_block <- structure(list(
    type = "hc",
    hc_object = hc_object,
    height = height,
    filter_vars = filter_vars,
    tabgroup = .parse_tabgroup(tabgroup),
    show_when = show_when
  ), class = "content_block")
  
  # Handle dashboard_project - add to last page's content_blocks
  if (inherits(content, "dashboard_project")) {
    if (length(content$pages) == 0) {
      stop("Dashboard has no pages. Add a page first with add_page().", call. = FALSE)
    }
    last_page_name <- names(content$pages)[length(content$pages)]
    if (is.null(content$pages[[last_page_name]]$content_blocks)) {
      content$pages[[last_page_name]]$content_blocks <- list()
    }
    content$pages[[last_page_name]]$content_blocks <- c(
      content$pages[[last_page_name]]$content_blocks, 
      list(hc_block)
    )
    return(content)
  }
  
  if (inherits(content, "page_object")) {
    content$.items <- c(content$.items, list(hc_block))
    return(content)
  }
  
  if (!is_content(content)) {
    stop("First argument must be a content collection, page_object, or dashboard_project", call. = FALSE)
  }
  
  insertion_idx <- length(content$items) + 1
  hc_block$.insertion_index <- insertion_idx
  content$items <- c(content$items, list(hc_block))
  content
}

#' Add a generic htmlwidget to the dashboard
#'
#' Embed any htmlwidget object (plotly, leaflet, echarts4r, DT, etc.)
#' directly into a dashboard page. The widget will be rendered as-is.
#'
#' @param content A content_collection, page_object, or dashboard_project
#' @param widget An htmlwidget object
#' @param title Optional title displayed above the widget
#' @param height Optional CSS height (e.g., "400px", "50vh")
#' @param tabgroup Optional tabgroup for organizing content
#' @param filter_vars Optional character vector of input filter variables to apply to this block.
#' @param show_when One-sided formula controlling conditional display based on input values.
#' @return Updated content object
#' @export
add_widget <- function(content, widget, title = NULL, height = NULL, tabgroup = NULL, filter_vars = NULL, show_when = NULL) {
  filter_vars <- .normalize_filter_vars(filter_vars)
  if (!inherits(widget, "htmlwidget")) {
    stop("widget must be an htmlwidget object", call. = FALSE)
  }
  widget_class <- class(widget)[1]
  if (!is.null(filter_vars) && !widget_class %in% c("plotly", "echarts4r", "highchart", "girafe")) {
    stop("filter_vars is only supported for plotly, echarts4r, highcharter, or ggiraph widgets", call. = FALSE)
  }
  if (!is.null(filter_vars) && widget_class == "girafe") {
    stop("filter_vars is not supported for ggiraph widgets (girafe)", call. = FALSE)
  }

  widget_block <- structure(list(
    type = "widget",
    widget_object = widget,
    widget_class = widget_class,
    title = title,
    height = height,
    filter_vars = filter_vars,
    tabgroup = .parse_tabgroup(tabgroup),
    show_when = show_when
  ), class = "content_block")

  if (inherits(content, "dashboard_project")) {
    if (length(content$pages) == 0) {
      stop("Dashboard has no pages. Add a page first with add_page().", call. = FALSE)
    }
    last_page_name <- names(content$pages)[length(content$pages)]
    if (is.null(content$pages[[last_page_name]]$content_blocks)) {
      content$pages[[last_page_name]]$content_blocks <- list()
    }
    content$pages[[last_page_name]]$content_blocks <- c(
      content$pages[[last_page_name]]$content_blocks,
      list(widget_block)
    )
    return(content)
  }

  if (inherits(content, "page_object")) {
    content$.items <- c(content$.items, list(widget_block))
    return(content)
  }

  if (!is_content(content)) {
    stop("First argument must be a content collection, page_object, or dashboard_project", call. = FALSE)
  }

  insertion_idx <- length(content$items) + 1
  widget_block$.insertion_index <- insertion_idx
  content$items <- c(content$items, list(widget_block))
  content
}

#' Add a plotly chart to the dashboard
#'
#' Convenience wrapper around \code{\link{add_widget}} for plotly objects.
#'
#' @param content A content_collection, page_object, or dashboard_project
#' @param plot A plotly object (created with \code{plotly::plot_ly()} or \code{plotly::ggplotly()})
#' @param title Optional title displayed above the chart
#' @param height Optional CSS height
#' @param tabgroup Optional tabgroup for organizing content
#' @param filter_vars Optional character vector of input filter variables to apply to this block.
#' @param show_when One-sided formula controlling conditional display based on input values.
#' @return Updated content object
#' @export
add_plotly <- function(content, plot, title = NULL, height = NULL, tabgroup = NULL, filter_vars = NULL, show_when = NULL) {
  if (!inherits(plot, "plotly")) {
    stop("plot must be a plotly object (created with plot_ly() or ggplotly())", call. = FALSE)
  }
  add_widget(content, plot, title = title, height = height, tabgroup = tabgroup, filter_vars = filter_vars, show_when = show_when)
}

#' Add a leaflet map to the dashboard
#'
#' Convenience wrapper around \code{\link{add_widget}} for leaflet objects.
#'
#' @param content A content_collection, page_object, or dashboard_project
#' @param map A leaflet object (created with \code{leaflet::leaflet()})
#' @param title Optional title displayed above the map
#' @param height Optional CSS height
#' @param tabgroup Optional tabgroup for organizing content
#' @param filter_vars Optional character vector of input filter variables to apply to this block.
#' @param show_when One-sided formula controlling conditional display based on input values.
#' @return Updated content object
#' @export
add_leaflet <- function(content, map, title = NULL, height = NULL, tabgroup = NULL, filter_vars = NULL, show_when = NULL) {
  if (!inherits(map, "leaflet")) {
    stop("map must be a leaflet object (created with leaflet())", call. = FALSE)
  }
  add_widget(content, map, title = title, height = height, tabgroup = tabgroup, filter_vars = filter_vars, show_when = show_when)
}

#' Add an echarts4r chart to the dashboard
#'
#' Convenience wrapper around \code{\link{add_widget}} for echarts4r objects.
#'
#' @param content A content_collection, page_object, or dashboard_project
#' @param chart An echarts4r object (created with \code{echarts4r::e_charts()})
#' @param title Optional title displayed above the chart
#' @param height Optional CSS height
#' @param tabgroup Optional tabgroup for organizing content
#' @param filter_vars Optional character vector of input filter variables to apply to this block.
#' @param show_when One-sided formula controlling conditional display based on input values.
#' @return Updated content object
#' @export
add_echarts <- function(content, chart, title = NULL, height = NULL,
                        tabgroup = NULL, filter_vars = NULL, show_when = NULL) {
  if (!inherits(chart, "echarts4r")) {
    stop("chart must be an echarts4r object (created with e_charts())", call. = FALSE)
  }
  add_widget(content, chart, title = title, height = height,
             tabgroup = tabgroup, filter_vars = filter_vars, show_when = show_when)
}

#' Add a ggiraph interactive plot to the dashboard
#'
#' Convenience wrapper around \code{\link{add_widget}} for ggiraph objects.
#'
#' @param content A content_collection, page_object, or dashboard_project
#' @param plot A girafe object (created with \code{ggiraph::girafe()})
#' @param title Optional title displayed above the plot
#' @param height Optional CSS height
#' @param tabgroup Optional tabgroup for organizing content
#' @param filter_vars Not supported for ggiraph widgets.
#' @param show_when One-sided formula controlling conditional display based on input values.
#' @return Updated content object
#' @export
add_ggiraph <- function(content, plot, title = NULL, height = NULL,
                        tabgroup = NULL, filter_vars = NULL, show_when = NULL) {
  if (!inherits(plot, "girafe")) {
    stop("plot must be a girafe object (created with ggiraph::girafe())", call. = FALSE)
  }
  add_widget(content, plot, title = title, height = height,
             tabgroup = tabgroup, filter_vars = filter_vars, show_when = show_when)
}

#' Add a static ggplot2 plot to the dashboard
#'
#' Embed a ggplot2 object directly into a dashboard page. The plot is rendered
#' as a static image via Quarto's built-in knitr graphics device.
#'
#' @param content A content_collection, page_object, or dashboard_project
#' @param plot A ggplot2 object (created with \code{ggplot2::ggplot()})
#' @param title Optional title displayed above the plot
#' @param height Optional figure height in inches (passed to knitr fig.height)
#' @param width Optional figure width in inches (passed to knitr fig.width)
#' @param tabgroup Optional tabgroup for organizing content
#' @param show_when One-sided formula controlling conditional display based on input values.
#' @return Updated content object
#' @export
add_ggplot <- function(content, plot, title = NULL, height = NULL, width = NULL,
                       tabgroup = NULL, show_when = NULL) {
  if (!inherits(plot, "gg")) {
    stop("plot must be a ggplot2 object (created with ggplot())", call. = FALSE)
  }

  ggplot_block <- structure(list(
    type = "ggplot",
    ggplot_object = plot,
    title = title,
    height = height,
    width = width,
    tabgroup = .parse_tabgroup(tabgroup),
    show_when = show_when
  ), class = "content_block")

  # Handle dashboard_project - add to last page's content_blocks
  if (inherits(content, "dashboard_project")) {
    if (length(content$pages) == 0) {
      stop("Dashboard has no pages. Add a page first with add_page().", call. = FALSE)
    }
    last_page_name <- names(content$pages)[length(content$pages)]
    if (is.null(content$pages[[last_page_name]]$content_blocks)) {
      content$pages[[last_page_name]]$content_blocks <- list()
    }
    content$pages[[last_page_name]]$content_blocks <- c(
      content$pages[[last_page_name]]$content_blocks,
      list(ggplot_block)
    )
    return(content)
  }

  if (inherits(content, "page_object")) {
    content$.items <- c(content$.items, list(ggplot_block))
    return(content)
  }

  if (!is_content(content)) {
    stop("First argument must be a content collection, page_object, or dashboard_project", call. = FALSE)
  }

  insertion_idx <- length(content$items) + 1
  ggplot_block$.insertion_index <- insertion_idx
  content$items <- c(content$items, list(ggplot_block))
  content
}

#' Add generic table (data frame)
#' @param content A content_collection object
#' @param table_object A data frame or tibble
#' @param caption Optional caption
#' @param tabgroup Optional tabgroup for organizing content (character vector for nested tabs)
#' @param filter_vars Optional character vector of input filter variables to apply to this block.
#' @param show_when One-sided formula controlling conditional display based on input values.
#' @return Updated content_collection
#' @export
add_table <- function(content, table_object, caption = NULL, tabgroup = NULL, filter_vars = NULL, show_when = NULL) {
  filter_vars <- .normalize_filter_vars(filter_vars)
  if (!is.null(filter_vars) && !is.data.frame(table_object)) {
    stop("filter_vars requires table_object to be a data frame", call. = FALSE)
  }
  table_block <- structure(list(
    type = "table",
    table_object = table_object,
    caption = caption,
    filter_vars = filter_vars,
    tabgroup = .parse_tabgroup(tabgroup),
    show_when = show_when
  ), class = "content_block")
  
  if (inherits(content, "page_object")) {
    content$.items <- c(content$.items, list(table_block))
    return(content)
  }
  
  if (!is_content(content)) {
    stop("First argument must be a content collection or page_object", call. = FALSE)
  }
  
  insertion_idx <- length(content$items) + 1
  table_block$.insertion_index <- insertion_idx
  content$items <- c(content$items, list(table_block))
  content
}

#' Add DT datatable
#' @param content A content_collection object
#' @param table_data A DT datatable object (from DT::datatable()) OR a data frame/matrix (will be auto-converted)
#' @param options List of DT options (only used if passing a data frame)
#' @param tabgroup Optional tabgroup for organizing content (character vector for nested tabs)
#' @param ... Additional arguments passed to DT::datatable() (only used if passing a data frame)
#' @param filter_vars Optional character vector of input filter variables to apply to this block.
#' @param show_when One-sided formula controlling conditional display based on input values.
#' @return Updated content_collection
#' @export
#' @examples
#' \dontrun{
#' # Option 1: Pass a styled DT object
#' my_dt <- DT::datatable(
#'   mtcars,
#'   options = list(pageLength = 10),
#'   filter = 'top',
#'   rownames = FALSE
#' )
#' 
#' content <- create_content() %>%
#'   add_DT(my_dt)
#'   
#' # Option 2: Pass a data frame with options
#' content <- create_content() %>%
#'   add_DT(mtcars, options = list(pageLength = 5, scrollX = TRUE))
#' }
add_DT <- function(content, table_data, options = NULL, tabgroup = NULL, filter_vars = NULL, show_when = NULL, ...) {
  filter_vars <- .normalize_filter_vars(filter_vars)
  is_dataframe <- is.data.frame(table_data) || is.matrix(table_data)
  if (!is.null(filter_vars) && !is_dataframe) {
    stop("filter_vars requires table_data to be a data frame or matrix", call. = FALSE)
  }
  if (is_dataframe) {
    rlang::check_installed("DT", reason = "to use add_DT")
    dt_obj <- DT::datatable(table_data, options = options %||% list(), ..., rownames = FALSE)
  } else {
    dt_obj <- table_data
  }
  dt_block <- structure(list(
    type = "DT",
    table_data = dt_obj,
    table_raw = if (is_dataframe) as.data.frame(table_data) else NULL,
    options = options,
    extra_args = list(...),
    filter_vars = filter_vars,
    tabgroup = .parse_tabgroup(tabgroup),
    show_when = show_when
  ), class = "content_block")
  
  if (inherits(content, "page_object")) {
    content$.items <- c(content$.items, list(dt_block))
    return(content)
  }
  
  if (!is_content(content)) {
    stop("First argument must be a content collection or page_object", call. = FALSE)
  }
  
  insertion_idx <- length(content$items) + 1
  dt_block$.insertion_index <- insertion_idx
  content$items <- c(content$items, list(dt_block))
  content
}

#' Add video
#' @param content A content_collection object
#' @param src Video source URL or path
#' @param caption Optional caption
#' @param width Optional width
#' @param height Optional height
#' @param tabgroup Optional tabgroup for organizing content (character vector for nested tabs)
#' @param show_when One-sided formula controlling conditional display based on input values.
#' @return Updated content_collection
#' @export
add_video <- function(content, src, caption = NULL, width = NULL, height = NULL, tabgroup = NULL, show_when = NULL) {
  video_block <- structure(list(
    type = "video",
    url = src,
    caption = caption,
    width = width,
    height = height,
    tabgroup = .parse_tabgroup(tabgroup),
    show_when = show_when
  ), class = "content_block")
  
  if (inherits(content, "page_object")) {
    content$.items <- c(content$.items, list(video_block))
    return(content)
  }
  
  if (!is_content(content)) {
    stop("First argument must be a content collection or page_object", call. = FALSE)
  }
  
  insertion_idx <- length(content$items) + 1
  video_block$.insertion_index <- insertion_idx
  content$items <- c(content$items, list(video_block))
  content
}

#' Add iframe
#' @param content A content_collection object
#' @param src iframe source URL
#' @param height iframe height (default: "500px")
#' @param width iframe width (default: "100%")
#' @param style Optional inline CSS style string applied to the iframe element
#'   (e.g., `"border: none; border-radius: 8px;"`). Useful for removing borders,
#'   adding shadows, or any custom styling.
#' @param tabgroup Optional tabgroup for organizing content (character vector for nested tabs)
#' @param show_when One-sided formula controlling conditional display based on input values.
#' @return Updated content_collection
#' @export
add_iframe <- function(content, src, height = "500px", width = "100%", style = NULL, tabgroup = NULL, show_when = NULL) {
  iframe_block <- structure(list(
    type = "iframe",
    url = src,
    height = height,
    width = width,
    style = style,
    tabgroup = .parse_tabgroup(tabgroup),
    show_when = show_when
  ), class = "content_block")
  
  if (inherits(content, "page_object")) {
    content$.items <- c(content$.items, list(iframe_block))
    return(content)
  }
  
  if (!is_content(content)) {
    stop("First argument must be a content collection or page_object", call. = FALSE)
  }
  
  insertion_idx <- length(content$items) + 1
  iframe_block$.insertion_index <- insertion_idx
  content$items <- c(content$items, list(iframe_block))
  content
}

#' Add collapsible accordion/details section
#' @param content A content_collection or viz_collection object
#' @param title Section title
#' @param text Section content
#' @param open Whether section starts open (default: FALSE)
#' @param tabgroup Optional tabgroup for organizing content (character vector for nested tabs)
#' @param show_when One-sided formula controlling conditional display based on input values.
#' @return Updated content_collection
#' @export
add_accordion <- function(content, title, text, open = FALSE, tabgroup = NULL, show_when = NULL) {
  accordion_block <- structure(list(
    type = "accordion",
    title = title,
    text = text,
    open = open,
    tabgroup = .parse_tabgroup(tabgroup),
    show_when = show_when
  ), class = "content_block")
  
  if (inherits(content, "page_object")) {
    content$.items <- c(content$.items, list(accordion_block))
    return(content)
  }
  
  # Handle sidebar_container
  if (inherits(content, "sidebar_container")) {
    content$blocks <- c(content$blocks, list(accordion_block))
    return(content)
  }
  
  if (!is_content(content)) {
    stop("First argument must be a content collection, sidebar_container, or page_object", call. = FALSE)
  }
  
  insertion_idx <- length(content$items) + 1
  accordion_block$.insertion_index <- insertion_idx
  content$items <- c(content$items, list(accordion_block))
  content
}

#' Add card
#' @param content A content_collection or viz_collection object
#' @param title Card title
#' @param text Card content
#' @param footer Optional card footer
#' @param tabgroup Optional tabgroup for organizing content (character vector for nested tabs)
#' @param show_when One-sided formula controlling conditional display based on input values.
#' @return Updated content_collection
#' @export
add_card <- function(content, text, title = NULL, footer = NULL, tabgroup = NULL, show_when = NULL) {
  card_block <- structure(list(
    type = "card",
    title = title,
    text = text,
    footer = footer,
    tabgroup = .parse_tabgroup(tabgroup),
    show_when = show_when
  ), class = "content_block")
  
  if (inherits(content, "page_object")) {
    content$.items <- c(content$.items, list(card_block))
    return(content)
  }
  
  # Handle sidebar_container
  if (inherits(content, "sidebar_container")) {
    content$blocks <- c(content$blocks, list(card_block))
    return(content)
  }
  
  if (!is_content(content)) {
    stop("First argument must be a content collection, sidebar_container, or page_object", call. = FALSE)
  }
  
  insertion_idx <- length(content$items) + 1
  card_block$.insertion_index <- insertion_idx
  content$items <- c(content$items, list(card_block))
  content
}

#' Add raw HTML content
#'
#' @param content Content collection object
#' @param html Raw HTML string
#' @param tabgroup Optional tabgroup for organizing content (character vector for nested tabs)
#' @param show_when One-sided formula controlling conditional display based on input values.
#' @export
add_html <- function(content, html, tabgroup = NULL, show_when = NULL) {
  html_block <- structure(list(
    type = "html",
    html = html,
    tabgroup = .parse_tabgroup(tabgroup),
    show_when = show_when
  ), class = "content_block")
  
  if (inherits(content, "page_object")) {
    content$.items <- c(content$.items, list(html_block))
    return(content)
  }
  
  # Handle sidebar_container
  if (inherits(content, "sidebar_container")) {
    content$blocks <- c(content$blocks, list(html_block))
    return(content)
  }
  
  if (!is_content(content)) {
    stop("First argument must be a content collection, sidebar_container, or page_object", call. = FALSE)
  }
  
  insertion_idx <- length(content$items) + 1
  html_block$.insertion_index <- insertion_idx
  content$items <- c(content$items, list(html_block))
  content
}

#' Add a blockquote
#'
#' @param content Content collection object
#' @param quote Quote text
#' @param attribution Optional attribution/source
#' @param cite Optional citation URL
#' @param tabgroup Optional tabgroup for organizing content (character vector for nested tabs)
#' @param show_when One-sided formula controlling conditional display based on input values.
#' @export
add_quote <- function(content, quote, attribution = NULL, cite = NULL, tabgroup = NULL, show_when = NULL) {
  quote_block <- structure(list(
    type = "quote",
    quote = quote,
    attribution = attribution,
    cite = cite,
    tabgroup = .parse_tabgroup(tabgroup),
    show_when = show_when
  ), class = "content_block")
  
  if (inherits(content, "page_object")) {
    content$.items <- c(content$.items, list(quote_block))
    return(content)
  }
  
  if (!is_content(content)) {
    stop("First argument must be a content collection or page_object", call. = FALSE)
  }
  
  insertion_idx <- length(content$items) + 1
  quote_block$.insertion_index <- insertion_idx
  content$items <- c(content$items, list(quote_block))
  content
}

#' Add a status badge
#'
#' @param content Content collection object
#' @param text Badge text
#' @param color Badge color (success, warning, danger, info, primary, secondary)
#' @param tabgroup Optional tabgroup for organizing content (character vector for nested tabs)
#' @param show_when One-sided formula controlling conditional display based on input values.
#' @export
add_badge <- function(content, text, color = "primary", tabgroup = NULL, show_when = NULL) {
  badge_block <- structure(list(
    type = "badge",
    text = text,
    color = color,
    tabgroup = .parse_tabgroup(tabgroup),
    show_when = show_when
  ), class = "content_block")
  
  if (inherits(content, "page_object")) {
    content$.items <- c(content$.items, list(badge_block))
    return(content)
  }
  
  # Handle sidebar_container
  if (inherits(content, "sidebar_container")) {
    content$blocks <- c(content$blocks, list(badge_block))
    return(content)
  }
  
  if (!is_content(content)) {
    stop("First argument must be a content collection, sidebar_container, or page_object", call. = FALSE)
  }
  
  insertion_idx <- length(content$items) + 1
  badge_block$.insertion_index <- insertion_idx
  content$items <- c(content$items, list(badge_block))
  content
}

#' Add a metric/value box
#'
#' @param content Content collection object
#' @param value The metric value
#' @param title Metric title
#' @param icon Optional icon
#' @param color Optional color theme
#' @param bg_color Optional background color (e.g. "#3498db").
#' @param text_color Optional text color (e.g. "#ffffff").
#' @param value_prefix Optional string prepended to the displayed value.
#' @param value_suffix Optional string appended to the displayed value.
#' @param border_radius Optional CSS border-radius (e.g. "12px", "0").
#' @param subtitle Optional subtitle text
#' @param tabgroup Optional tabgroup for organizing content (character vector for nested tabs)
#' @param show_when One-sided formula controlling conditional display based on input values.
#' @param aria_label Optional ARIA label for accessibility.
#' @export
add_metric <- function(content, value, title, icon = NULL, color = NULL,
                       bg_color = NULL, text_color = NULL,
                       value_prefix = NULL, value_suffix = NULL,
                       border_radius = NULL,
                       subtitle = NULL, tabgroup = NULL, show_when = NULL, aria_label = NULL) {
  metric_block <- structure(list(
    type = "metric",
    value = value,
    title = title,
    icon = icon,
    color = color,
    bg_color = bg_color,
    text_color = text_color,
    value_prefix = value_prefix,
    value_suffix = value_suffix,
    border_radius = border_radius,
    subtitle = subtitle,
    tabgroup = .parse_tabgroup(tabgroup),
    show_when = show_when,
    aria_label = aria_label
  ), class = "content_block")
  
  if (inherits(content, "page_object")) {
    content$.items <- c(content$.items, list(metric_block))
    return(content)
  }
  
  # Handle sidebar_container
  if (inherits(content, "sidebar_container")) {
    content$blocks <- c(content$blocks, list(metric_block))
    return(content)
  }
  
  if (!is_content(content)) {
    stop("First argument must be a content collection, sidebar_container, or page_object", call. = FALSE)
  }
  
  insertion_idx <- length(content$items) + 1
  metric_block$.insertion_index <- insertion_idx
  content$items <- c(content$items, list(metric_block))
  content
}

#' Add a custom styled value box
#'
#' Creates a modern value box with optional logo, custom background color,
#' and optional collapsible description. Perfect for displaying KPIs and metrics
#' with additional context.
#'
#' Can be used standalone or within a value box row:
#' - Standalone: create_content() %>% add_value_box(...)
#' - In row: create_content() %>% add_value_box_row() %>% add_value_box(...) %>% add_value_box(...)
#'
#' @param content Content collection object or value_box_row_container
#' @param title Box title (small text above value)
#' @param value Main value to display (large text)
#' @param logo_url Optional URL or path to logo image
#' @param logo_text Optional text to display as logo (if no logo_url)
#' @param bg_color Background color (hex code), default "#2c3e50"
#' @param description Optional collapsible description text (markdown supported)
#' @param description_title Title for collapsible section, default "About this source"
#' @param tabgroup Optional tabgroup for organizing content (character vector for nested tabs)
#' @param show_when One-sided formula controlling conditional display based on input values.
#' @param aria_label Optional ARIA label for accessibility.
#' @export
#' @examples
#' \dontrun{
#' # Standalone value box
#' content <- create_content() %>%
#'   add_value_box(
#'     title = "Total Revenue",
#'     value = "EUR 1,234,567",
#'     logo_text = "$",
#'     bg_color = "#2E86AB"
#'   )
#'
#' # Row of value boxes (pipeable!)
#' content <- create_content() %>%
#'   add_value_box_row() %>%
#'     add_value_box(title = "Users", value = "1,234") %>%
#'     add_value_box(title = "Revenue", value = "EUR 56K")
#' }
add_value_box <- function(content, title, value, logo_url = NULL, logo_text = NULL,
                          bg_color = "#2c3e50", description = NULL,
                          description_title = "About this source", tabgroup = NULL, show_when = NULL, aria_label = NULL) {
  .validate_show_when(show_when)

  # Create the box specification
  box_spec <- list(
    title = title,
    value = value,
    logo_url = logo_url,
    logo_text = logo_text,
    bg_color = bg_color,
    description = description,
    description_title = description_title,
    aria_label = aria_label
  )
  
  # Check if we're adding to a row container
  if (inherits(content, "value_box_row_container")) {
    if (!is.null(show_when)) {
      stop("show_when is not supported for value_box items inside a value_box_row. Apply show_when to the row instead.", call. = FALSE)
    }
    # Add to the row's boxes
    content$boxes <- c(content$boxes, list(box_spec))
    return(content)
  }
  
  # Otherwise, add as a standalone value box
  if (!inherits(content, "content_collection")) {
    stop("First argument must be a content_collection object or value_box_row_container", call. = FALSE)
  }
  
  value_box_block <- structure(c(list(type = "value_box", tabgroup = tabgroup, show_when = show_when), box_spec), class = "content_block")
  
  insertion_idx <- length(content$items) + 1
  value_box_block$.insertion_index <- insertion_idx
  content$items <- c(content$items, list(value_box_block))
  content
}

#' Start a value box row
#'
#' Creates a container for value boxes that will be displayed in a horizontal row.
#' The boxes will wrap responsively on smaller screens. Use pipeable syntax with end_value_box_row():
#'
#' @param content Content collection object
#' @param tabgroup Optional tabgroup for organizing content (character vector for nested tabs)
#' @param show_when One-sided formula controlling conditional display based on input values.
#' @export
#' @examples
#' \dontrun{
#' content <- create_content() %>%
#'   add_value_box_row() %>%
#'     add_value_box(title = "Users", value = "1,234", bg_color = "#2E86AB") %>%
#'     add_value_box(title = "Revenue", value = "EUR 56K", bg_color = "#F18F01") %>%
#'     add_value_box(title = "Growth", value = "+23%", bg_color = "#A23B72") %>%
#'   end_value_box_row()
#' }
add_value_box_row <- function(content, tabgroup = NULL, show_when = NULL) {
  # Handle page_object - store reference for end_value_box_row to use
  if (inherits(content, "page_object")) {
    row_container <- structure(list(
      type = "value_box_row",
      boxes = list(),
      parent_page = content,
      parent_content = NULL,
      tabgroup = .parse_tabgroup(tabgroup),
      show_when = show_when
    ), class = c("value_box_row_container", "content_block"))
    return(row_container)
  }
  
  if (!is_content(content)) {
    stop("First argument must be a content collection or page_object", call. = FALSE)
  }
  
  # Create a special row container that add_value_box will detect
  row_container <- structure(list(
    type = "value_box_row",
    boxes = list(),
    parent_content = content,
    parent_page = NULL,
    tabgroup = .parse_tabgroup(tabgroup),
    show_when = show_when
  ), class = c("value_box_row_container", "content_block"))
  
  row_container
}

#' End a value box row
#'
#' Closes a value box row and returns to the parent content collection.
#' Must be called after add_value_box_row() and all add_value_box() calls.
#'
#' @param row_container Value box row container object
#' @export
#' @examples
#' \dontrun{
#' content <- create_content() %>%
#'   add_value_box_row() %>%
#'     add_value_box(title = "Users", value = "1,234") %>%
#'     add_value_box(title = "Revenue", value = "EUR 56K") %>%
#'   end_value_box_row() %>%
#'   add_text("More content after the row...")
#' }
end_value_box_row <- function(row_container) {
  if (!inherits(row_container, "value_box_row_container")) {
    stop("end_value_box_row() must be called on a value_box_row_container (created by add_value_box_row())", call. = FALSE)
  }
  
  # Create the final value_box_row block with all collected boxes
  value_box_row_block <- structure(list(
    type = "value_box_row",
    boxes = row_container$boxes,
    tabgroup = row_container$tabgroup,
    show_when = row_container$show_when
  ), class = "content_block")
  
  # Handle page_object parent
  if (!is.null(row_container$parent_page)) {
    parent_page <- row_container$parent_page
    parent_page$.items <- c(parent_page$.items, list(value_box_row_block))
    return(parent_page)
  }
  
  # Handle content collection parent
  parent_content <- row_container$parent_content
  
  # Add insertion index to preserve order
  insertion_idx <- length(parent_content$items) + 1
  value_box_row_block$.insertion_index <- insertion_idx
  
  # Add it to the parent content collection
  parent_content$items <- c(parent_content$items, list(value_box_row_block))
  
  # Return the parent content collection for further piping
  parent_content
}

#' Start a manual layout column
#'
#' Creates a column container for explicit Quarto dashboard layout control.
#' Use with \code{add_layout_row()} and \code{end_layout_column()}.
#'
#' @param content A content_collection or page_object.
#' @param width Optional Quarto column width value.
#' @param class Optional CSS class for the column.
#' @param tabgroup Optional tabgroup metadata (reserved for future use).
#' @param show_when Optional one-sided formula controlling visibility.
#' @return A layout_column_container for piping.
#' @export
#' @examples
#' \dontrun{
#' content <- create_content() %>%
#'   add_layout_column(width = 60) %>%
#'   add_layout_row() %>%
#'     add_text("### Row content") %>%
#'   end_layout_row() %>%
#' end_layout_column()
#' }
add_layout_column <- function(content, width = NULL, class = NULL, tabgroup = NULL, show_when = NULL) {
  .validate_show_when(show_when)

  if (!inherits(content, "page_object") && !is_content(content)) {
    stop("add_layout_column() must be called on a content_collection or page_object", call. = FALSE)
  }

  if (!is.null(width) && length(width) != 1) {
    stop("width must be NULL or a single value", call. = FALSE)
  }
  if (!is.null(class) && (!is.character(class) || length(class) != 1)) {
    stop("class must be NULL or a single character string", call. = FALSE)
  }

  structure(list(
    type = "layout_column",
    width = width,
    class = class,
    tabgroup = .parse_tabgroup(tabgroup),
    show_when = show_when,
    items = list(),
    defaults = content$defaults %||% list(),
    data = content$data %||% NULL,
    tabgroup_labels = content$tabgroup_labels %||% NULL,
    shared_first_level = content$shared_first_level %||% TRUE,
    needs_inputs = FALSE,
    needs_metric_data = FALSE,
    parent_content = if (is_content(content)) content else NULL,
    parent_page = if (inherits(content, "page_object")) content else NULL,
    parent_column = NULL,
    .active_layout_row_id = NULL,
    .layout_closed = FALSE
  ), class = c("layout_column_container", "content_collection", "viz_collection", "content_block"))
}

#' Start a manual layout row inside a layout column
#'
#' @param column_container A layout_column_container created by \code{add_layout_column()}.
#' @param class Optional CSS class for the row.
#' @param style Optional inline CSS style string applied to the row wrapper.
#'   In non-dashboard mode this is added to the \code{layout-ncol} div;
#'   in dashboard mode it is added to the \code{### Row} attributes.
#' @param tabgroup Optional tabgroup metadata (reserved for future use).
#' @param show_when Optional one-sided formula controlling visibility.
#' @return A layout_row_container for piping.
#' @export
add_layout_row <- function(column_container, class = NULL, style = NULL, tabgroup = NULL, show_when = NULL) {
  .validate_show_when(show_when)

  if (!inherits(column_container, "layout_column_container")) {
    stop("add_layout_row() must be called on a layout_column_container (created by add_layout_column())", call. = FALSE)
  }
  if (isTRUE(column_container$.layout_closed)) {
    stop("Cannot add a row to a closed layout column", call. = FALSE)
  }
  if (!is.null(column_container$.active_layout_row_id)) {
    stop("A layout row is already open. Call end_layout_row() before starting another row.", call. = FALSE)
  }
  if (!is.null(class) && (!is.character(class) || length(class) != 1)) {
    stop("class must be NULL or a single character string", call. = FALSE)
  }
  if (!is.null(style) && (!is.character(style) || length(style) != 1)) {
    stop("style must be NULL or a single character string", call. = FALSE)
  }

  row_id <- paste0("layout_row_", as.integer(stats::runif(1, min = 1, max = 1e9)))
  column_container$.active_layout_row_id <- row_id

  structure(list(
    type = "layout_row",
    class = class,
    style = style,
    tabgroup = .parse_tabgroup(tabgroup),
    show_when = show_when,
    items = list(),
    defaults = column_container$defaults %||% list(),
    data = column_container$data %||% NULL,
    tabgroup_labels = column_container$tabgroup_labels %||% NULL,
    shared_first_level = column_container$shared_first_level %||% TRUE,
    needs_inputs = FALSE,
    needs_metric_data = FALSE,
    parent_content = NULL,
    parent_page = NULL,
    parent_column = column_container,
    .layout_row_id = row_id,
    .layout_closed = FALSE
  ), class = c("layout_row_container", "content_collection", "viz_collection", "content_block"))
}

#' End a manual layout row
#'
#' @param row_container A layout_row_container created by \code{add_layout_row()}.
#' @return The parent layout_column_container.
#' @export
end_layout_row <- function(row_container) {
  if (!inherits(row_container, "layout_row_container")) {
    stop("end_layout_row() must be called on a layout_row_container (created by add_layout_row())", call. = FALSE)
  }
  if (isTRUE(row_container$.layout_closed)) {
    stop("This layout row is already closed", call. = FALSE)
  }

  parent_column <- row_container$parent_column
  if (!inherits(parent_column, "layout_column_container")) {
    stop("Invalid layout nesting: row container has no active layout column parent", call. = FALSE)
  }
  if (!identical(parent_column$.active_layout_row_id, row_container$.layout_row_id)) {
    stop("Invalid layout order: end the currently active row before closing this row", call. = FALSE)
  }

  layout_row_block <- structure(list(
    type = "layout_row",
    items = row_container$items,
    class = row_container$class,
    tabgroup = row_container$tabgroup,
    show_when = row_container$show_when
  ), class = "content_block")

  insertion_idx <- length(parent_column$items) + 1
  layout_row_block$.insertion_index <- insertion_idx
  parent_column$items <- c(parent_column$items, list(layout_row_block))
  parent_column$.active_layout_row_id <- NULL
  parent_column$needs_inputs <- isTRUE(parent_column$needs_inputs) || isTRUE(row_container$needs_inputs)
  parent_column$needs_metric_data <- isTRUE(parent_column$needs_metric_data) || isTRUE(row_container$needs_metric_data)
  row_container$.layout_closed <- TRUE
  parent_column
}

#' End a manual layout column
#'
#' @param column_container A layout_column_container created by \code{add_layout_column()}.
#' @return The parent content_collection or page_object.
#' @export
end_layout_column <- function(column_container) {
  if (!inherits(column_container, "layout_column_container")) {
    stop("end_layout_column() must be called on a layout_column_container (created by add_layout_column())", call. = FALSE)
  }
  if (isTRUE(column_container$.layout_closed)) {
    stop("This layout column is already closed", call. = FALSE)
  }
  if (!is.null(column_container$.active_layout_row_id)) {
    stop("Cannot close layout column while a layout row is still open. Call end_layout_row() first.", call. = FALSE)
  }

  layout_column_block <- structure(list(
    type = "layout_column",
    items = column_container$items,
    width = column_container$width,
    class = column_container$class,
    tabgroup = column_container$tabgroup,
    show_when = column_container$show_when
  ), class = "content_block")

  if (!is.null(column_container$parent_page)) {
    parent_page <- column_container$parent_page
    parent_page$.items <- c(parent_page$.items, list(layout_column_block))
    parent_page$needs_inputs <- isTRUE(parent_page$needs_inputs) || isTRUE(column_container$needs_inputs)
    parent_page$needs_metric_data <- isTRUE(parent_page$needs_metric_data) || isTRUE(column_container$needs_metric_data)
    column_container$.layout_closed <- TRUE
    return(parent_page)
  }

  parent_content <- column_container$parent_content
  if (!is_content(parent_content)) {
    stop("Invalid layout nesting: column container has no valid content_collection parent", call. = FALSE)
  }

  insertion_idx <- length(parent_content$items) + 1
  layout_column_block$.insertion_index <- insertion_idx
  parent_content$items <- c(parent_content$items, list(layout_column_block))
  parent_content$needs_inputs <- isTRUE(parent_content$needs_inputs) || isTRUE(column_container$needs_inputs)
  parent_content$needs_metric_data <- isTRUE(parent_content$needs_metric_data) || isTRUE(column_container$needs_metric_data)
  column_container$.layout_closed <- TRUE
  parent_content
}

# ============================================
# SIDEBAR SYSTEM
# ============================================

#' Add a sidebar to a page
#'
#' Creates a sidebar container that can hold inputs, text, images, and other content.
#' Use with end_sidebar() to close the sidebar and return to main content.
#'
#' Sidebars are collapsible vertical panels that appear alongside the main content.
#' They're ideal for placing filter controls, navigation, or supplementary information.
#'
#' @section Important - Heading Levels:
#' When using a sidebar, the page is rendered in Quarto dashboard format where
#' heading levels have special meaning:
#' \itemize{
#'   \item \code{##} creates new rows/columns (avoid in main content)
#'   \item \code{###} creates cards/sections (safe to use)
#' }
#' To avoid layout issues, use \code{###} headings or plain text in the main
#' content area after the sidebar. For advanced layouts, prefer explicit
#' \code{add_layout_column()} / \code{add_layout_row()} APIs instead of
#' heading-based layout shaping.
#'
#' @param content Content collection or page_object
#' @param width CSS width for sidebar (default "250px")
#' @param position Sidebar position: "left" (default) or "right"
#' @param title Optional title displayed at top of sidebar
#' @param background Background color (CSS color value, e.g., "#f8f9fa", "white", "transparent")
#' @param padding Padding inside the sidebar (CSS value, e.g., "1rem", "20px")
#' @param border Show border on sidebar edge. TRUE (default), FALSE, or CSS border value
#' @param open Whether sidebar starts open (default TRUE). Set FALSE to start collapsed.
#' @param class Additional CSS class(es) to add to the sidebar
#' @return A sidebar_container for piping
#' @export
#' @examples
#' \dontrun{
#' # Basic sidebar with filters
#' content <- create_content() %>%
#'   add_sidebar(width = "300px") %>%
#'     add_text("### Filters") %>%
#'     add_input(input_id = "country", filter_var = "country", options = countries) %>%
#'     add_divider() %>%
#'     add_image(src = "logo.png") %>%
#'   end_sidebar() %>%
#'   add_viz(viz_bar(...))
#'
#' # Right-positioned sidebar
#' content <- create_content() %>%
#'   add_sidebar(position = "right", title = "Options") %>%
#'     add_input(input_id = "metric", filter_var = "metric", type = "radio",
#'               options = c("Revenue", "Users", "Growth")) %>%
#'   end_sidebar() %>%
#'   add_viz(viz_timeline(...))
#'
#' # Styled sidebar with custom background and no border
#' content <- create_content() %>%
#'   add_sidebar(width = "300px", background = "#f8f9fa", 
#'               padding = "1.5rem", border = FALSE) %>%
#'     add_text("### Settings") %>%
#'   end_sidebar()
#' }
add_sidebar <- function(content, 
                        width = "250px", 
                        position = c("left", "right"),
                        title = NULL,
                        background = NULL,
                        padding = NULL,
                        border = TRUE,
                        open = TRUE,
                        class = NULL) {
  position <- match.arg(position)
  
  # Handle page_object
  if (inherits(content, "page_object")) {
    sidebar_container <- structure(list(
      type = "sidebar",
      blocks = list(),
      parent_page = content,
      parent_content = NULL,
      width = width,
      position = position,
      title = title,
      background = background,
      padding = padding,
      border = border,
      open = open,
      class = class,
      needs_inputs = FALSE
    ), class = c("sidebar_container", "content_block"))
    return(sidebar_container)
  }
  
  if (!is_content(content)) {
    stop("First argument must be a content collection or page_object", call. = FALSE)
  }
  
  sidebar_container <- structure(list(
    type = "sidebar",
    blocks = list(),
    parent_content = content,
    parent_page = NULL,
    width = width,
    position = position,
    title = title,
    background = background,
    padding = padding,
    border = border,
    open = open,
    class = class,
    needs_inputs = FALSE
  ), class = c("sidebar_container", "content_block"))
  
  sidebar_container
}

#' End a sidebar
#'
#' Closes a sidebar container and returns to the parent content collection.
#' Must be called after add_sidebar() and all content additions.
#'
#' @param sidebar_container Sidebar container object created by add_sidebar()
#' @return The parent content_collection or page_object for further piping
#' @export
#' @examples
#' \dontrun{
#' content <- create_content() %>%
#'   add_sidebar() %>%
#'     add_text("## Filters") %>%
#'     add_input(input_id = "filter1", filter_var = "var1", options = c("A", "B")) %>%
#'   end_sidebar() %>%
#'   add_text("Content after the sidebar...")
#' }
end_sidebar <- function(sidebar_container) {
  if (!inherits(sidebar_container, "sidebar_container")) {
    stop("end_sidebar() must be called on a sidebar_container (created by add_sidebar())", call. = FALSE)
  }
  
  needs_linked_inputs <- isTRUE(sidebar_container$needs_linked_inputs)
  if (!needs_linked_inputs && !is.null(sidebar_container$blocks)) {
    for (b in sidebar_container$blocks) {
      if (!is.null(b$.linked_parent_id)) {
        needs_linked_inputs <- TRUE
        break
      }
    }
  }

  # Create the final sidebar block with all styling options
  sidebar_block <- structure(list(
    type = "sidebar",
    blocks = sidebar_container$blocks,
    width = sidebar_container$width,
    position = sidebar_container$position,
    title = sidebar_container$title,
    background = sidebar_container$background,
    padding = sidebar_container$padding,
    border = sidebar_container$border,
    open = sidebar_container$open,
    class = sidebar_container$class,
    needs_inputs = sidebar_container$needs_inputs %||% FALSE,
    needs_metric_data = sidebar_container$needs_metric_data %||% FALSE,
    needs_linked_inputs = needs_linked_inputs
  ), class = "content_block")

  # Handle page_object parent
  if (!is.null(sidebar_container$parent_page)) {
    parent_page <- sidebar_container$parent_page
    parent_page$sidebar <- sidebar_block
    # Propagate needs_inputs flag
    if (isTRUE(sidebar_container$needs_inputs)) {
      parent_page$needs_inputs <- TRUE
    }
    # Propagate needs_metric_data flag
    if (isTRUE(sidebar_container$needs_metric_data)) {
      parent_page$needs_metric_data <- TRUE
    }
    if (isTRUE(needs_linked_inputs)) {
      parent_page$needs_linked_inputs <- TRUE
    }
    return(parent_page)
  }

  # Handle content collection parent
  parent_content <- sidebar_container$parent_content
  parent_content$sidebar <- sidebar_block

  # Propagate needs_inputs flag
  if (isTRUE(sidebar_container$needs_inputs)) {
    parent_content$needs_inputs <- TRUE
  }

  # Propagate needs_metric_data flag
  if (isTRUE(sidebar_container$needs_metric_data)) {
    parent_content$needs_metric_data <- TRUE
  }

  if (isTRUE(needs_linked_inputs)) {
    parent_content$needs_linked_inputs <- TRUE
  }

  parent_content
}

#' Normalize linked option values for a parent value
#'
#' Validates and coerces child option values for a given parent value
#' in a linked input configuration.
#'
#' @param values Character vector of child options for one parent value.
#' @param parent_value The parent value these options belong to.
#' @return Character vector of cleaned, unique child option values.
#' @keywords internal
#' @export
.normalize_linked_option_values <- function(values, parent_value) {
  if (is.null(values)) {
    stop(
      "options_by_parent entry for parent value '", parent_value,
      "' must contain at least one child option.",
      call. = FALSE
    )
  }

  values_chr <- as.character(values)
  values_chr <- values_chr[!is.na(values_chr) & nzchar(values_chr)]
  values_chr <- unique(values_chr)

  if (length(values_chr) == 0) {
    stop(
      "options_by_parent entry for parent value '", parent_value,
      "' must contain at least one non-empty child option.",
      call. = FALSE
    )
  }

  values_chr
}

.normalize_options_by_parent <- function(options_by_parent, parent_options) {
  if (!is.list(options_by_parent) || is.null(names(options_by_parent))) {
    stop("child$options_by_parent must be a named list", call. = FALSE)
  }

  mapped <- list()
  for (parent_value in parent_options) {
    if (!parent_value %in% names(options_by_parent)) {
      stop(
        "options_by_parent must contain a key for parent value: ",
        parent_value,
        call. = FALSE
      )
    }
    mapped[[parent_value]] <- .normalize_linked_option_values(
      options_by_parent[[parent_value]],
      parent_value
    )
  }

  mapped
}

#' Add linked parent-child inputs (cascading dropdowns)
#'
#' Creates two linked select inputs where the child's available options depend on
#' the parent's current selection. Use inside a sidebar (after \code{add_sidebar()}).
#'
#' @param x A sidebar_container (from \code{add_sidebar()}).
#' @param parent List with: \code{id}, \code{label}, \code{options}; optionally
#'   \code{default_selected}, \code{filter_var}.
#' @param child List with: \code{id}, \code{label}, \code{options_by_parent}
#'   (named list mapping each parent value to a character vector of child options);
#'   optionally \code{filter_var}.
#' @param type Input type for parent: \code{"select"} (default) or \code{"radio"}.
#' @return The modified sidebar_container for piping.
#' @export
#' @examples
#' \dontrun{
#' add_sidebar() %>%
#'   add_linked_inputs(
#'     parent = list(id = "dimension", label = "Dimension",
#'                   options = c("AI", "Safety", "Digital Health")),
#'     child = list(id = "question", label = "Question",
#'                  options_by_parent = list(
#'                    "AI" = c("Overall", "Using AI Tools"),
#'                    "Safety" = c("Overall", "Passwords", "Phishing"),
#'                    "Digital Health" = c("Overall", "Screen Time")
#'                  ))
#'   ) %>%
#'   end_sidebar()
#' }
add_linked_inputs <- function(x, parent, child, type = "select") {
  if (!inherits(x, "sidebar_container")) {
    stop("add_linked_inputs() must be used inside add_sidebar()", call. = FALSE)
  }
  stopifnot(is.list(parent), is.list(child))
  if (is.null(parent$id) || is.null(parent$label) || is.null(parent$options)) {
    stop("parent must have id, label, and options", call. = FALSE)
  }
  if (is.null(child$id) || is.null(child$label) || is.null(child$options_by_parent)) {
    stop("child must have id, label, and options_by_parent", call. = FALSE)
  }

  parent_options <- as.character(parent$options)
  parent_options <- parent_options[!is.na(parent_options) & nzchar(parent_options)]
  if (length(parent_options) == 0) {
    stop("parent$options must include at least one non-empty option", call. = FALSE)
  }

  options_by_parent <- .normalize_options_by_parent(child$options_by_parent, parent_options)

  parent_type <- if (type == "select") "select_single" else "radio"
  parent_filter <- parent$filter_var %||% parent$id
  child_filter <- child$filter_var %||% child$id
  default_parent <- as.character(parent$default_selected %||% parent_options[1])[1]
  if (!default_parent %in% parent_options) {
    stop("default_selected must be one of parent$options", call. = FALSE)
  }
  initial_child_options <- options_by_parent[[default_parent]]

  x <- add_input(x,
    input_id = parent$id,
    label = parent$label,
    type = parent_type,
    filter_var = parent_filter,
    options = parent_options,
    default_selected = default_parent
  )
  x <- add_input(x,
    input_id = child$id,
    label = child$label,
    type = "select_single",
    filter_var = child_filter,
    options = initial_child_options,
    default_selected = initial_child_options[1],
    .linked_parent_id = parent$id,
    .options_by_parent = options_by_parent
  )
  x$needs_linked_inputs <- TRUE
  x
}

# ============================================
# INPUT FILTERING SYSTEM
# ============================================

#' Add an interactive input filter
#'
#' Adds an input widget that filters Highcharts visualizations on the page.
#' Supports various input types: dropdowns, checkboxes, radio buttons, switches, 
#' sliders, text search, number inputs, and button groups.
#'
#' @param content Content collection object or input_row_container
#' @param input_id Unique ID for this input widget
#' @param label Optional label displayed above the input
#' @param type Input type: "select_multiple" (default), "select_single", 
#'   "checkbox", "radio", "switch", "slider", "text", "number", or "button_group"
#' @param filter_var The variable name to filter by (matches Highcharts series names).
#'   This should match the `group_var` used in your visualization.
#' @param options Character vector of options to display. If NULL, uses `options_from`.
#'   Required for select, checkbox, radio, and button_group types.
#'   Can also be a named list for grouped options in selects (e.g., 
#'   `list("Europe" = c("Germany", "France"), "Asia" = c("China", "Japan"))`).
#' @param options_from Column name in page data to auto-populate options from.
#'   Only used if `options` is NULL.
#' @param default_selected Character vector of initially selected values.
#'   If NULL, all options are selected by default (for select/checkbox) or
#'   first option (for radio/button_group).
#' @param placeholder Placeholder text when nothing is selected (for selects/text)
#' @param width CSS width for the input (default: "300px")
#' @param min Minimum value (for slider/number types)
#' @param max Maximum value (for slider/number types)
#' @param step Step increment (for slider/number types)
#' @param value Initial value (for slider/switch/text/number types)
#' @param show_value Whether to show current value (for slider, default TRUE)
#' @param inline Whether to display options inline (for checkbox/radio, default TRUE)
#' @param toggle_series For switch type: name of the series to toggle visibility on/off
#' @param override For switch type: if TRUE, the switch overrides other filters for this series
#' @param labels Custom labels for slider ticks (character vector). The first and last
#'   labels are shown at the min/max positions.
#' @param size Size variant: "sm" (small), "md" (medium, default), or "lg" (large)
#' @param help Help text displayed below the input
#' @param stacked Whether to stack options vertically (for checkbox/radio). Default FALSE.
#' @param stacked_align Alignment when stacked: "center" (default), "left", or "right"
#' @param group_align Alignment for option groups: "left" (default), "center", or "right"
#' @param ncol Number of columns for grid layout of options
#' @param nrow Number of rows for grid layout of options
#' @param columns Column configuration for grid layout
#' @param disabled Whether the input is disabled (default FALSE)
#' @param add_all Whether to add an "All" option (default FALSE)
#' @param add_all_label Label for the "All" option (default "All")
#' @param mt Margin top (CSS value, e.g., "10px")
#' @param mr Margin right (CSS value)
#' @param mb Margin bottom (CSS value)
#' @param ml Margin left (CSS value)
#' @param default_value Default value for the input (alias for value, used for reset)
#' @param tabgroup Optional tabgroup for organizing content
#' @param .linked_parent_id Internal. ID of linked parent input for cascading inputs
#' @param .options_by_parent Internal. Named list mapping parent values to child options
#' @return Updated content_collection or input_row_container
#' @export
#' @examples
#' \dontrun{
#' # Dropdown (multi-select)
#' content <- create_content() %>%
#'   add_input(
#'     input_id = "country_filter",
#'     label = "Select Countries:",
#'     type = "select_multiple",
#'     filter_var = "country",
#'     options_from = "country",
#'     help = "Select one or more countries to compare"
#'   )
#'
#' # Grouped select options
#' content <- create_content() %>%
#'   add_input(
#'     input_id = "country_filter",
#'     label = "Select Countries:",
#'     type = "select_multiple",
#'     filter_var = "country",
#'     options = list(
#'       "Europe" = c("Germany", "France", "UK"),
#'       "Asia" = c("China", "Japan", "India")
#'     )
#'   )
#'
#' # Checkbox group
#' content <- create_content() %>%
#'   add_input(
#'     input_id = "metrics",
#'     label = "Metrics:",
#'     type = "checkbox",
#'     filter_var = "metric",
#'     options = c("Revenue", "Users", "Growth"),
#'     inline = TRUE
#'   )
#'
#' # Radio buttons
#' content <- create_content() %>%
#'   add_input(
#'     input_id = "chart_type",
#'     label = "Chart Type:",
#'     type = "radio",
#'     filter_var = "chart_type",
#'     options = c("Line", "Bar", "Area")
#'   )
#'
#' # Switch/toggle to show/hide a specific series
#' content <- create_content() %>%
#'   add_input(
#'     input_id = "show_average",
#'     label = "Show Global Average",
#'     type = "switch",
#'     filter_var = "country",
#'     toggle_series = "Global Average",  # Name of the series to toggle
#'     override = TRUE,                   # Don't let other filters hide this series
#'     value = TRUE                       # Start with switch ON
#'   )
#'
#' # Slider with custom labels
#' content <- create_content() %>%
#'   add_input(
#'     input_id = "decade_filter",
#'     label = "Decade:",
#'     type = "slider",
#'     filter_var = "decade",
#'     min = 1,
#'     max = 6,
#'     step = 1,
#'     value = 1,
#'     labels = c("1970s", "1980s", "1990s", "2000s", "2010s", "2020s")
#'   )
#'
#' # Text search input
#' content <- create_content() %>%
#'   add_input(
#'     input_id = "search",
#'     label = "Search:",
#'     type = "text",
#'     filter_var = "name",
#'     placeholder = "Type to search...",
#'     size = "lg"
#'   )
#'
#' # Button group (segmented control)
#' content <- create_content() %>%
#'   add_input(
#'     input_id = "period",
#'     label = "Time Period:",
#'     type = "button_group",
#'     filter_var = "period",
#'     options = c("Day", "Week", "Month", "Year")
#'   )
#' }
add_input <- function(content,
                      input_id,
                      label = NULL,
                      type = c("select_multiple", "select_single", "checkbox",
                               "radio", "switch", "slider", "text", "number", "button_group",
                               "date", "daterange"),
                      filter_var,
                      options = NULL,
                      options_from = NULL,
                      default_selected = NULL,
                      placeholder = "Select...",
                      width = "300px",
                      min = 0,
                      max = 100,
                      step = 1,
                      value = NULL,
                      default_value = NULL,
                      show_value = TRUE,
                      inline = TRUE,
                      stacked = FALSE,
                      stacked_align = c("center", "left", "right"),
                      group_align = c("left", "center", "right"),
                      ncol = NULL,
                      nrow = NULL,
                      columns = NULL,
                      toggle_series = NULL,
                      override = FALSE,
                      labels = NULL,
                      size = c("md", "sm", "lg"),
                      help = NULL,
                      disabled = FALSE,
                      add_all = FALSE,
                      add_all_label = "All",
                      mt = NULL,
                      mr = NULL,
                      mb = NULL,
                      ml = NULL,
                      tabgroup = NULL,
                      .linked_parent_id = NULL,
                      .options_by_parent = NULL) {
  
  # Convert variable arguments to strings (supports both quoted and unquoted)
  filter_var <- .as_var_string(rlang::enquo(filter_var))
  options_from <- .as_var_string(rlang::enquo(options_from))
  
  type <- match.arg(type)
  size <- match.arg(size)
  stacked_align <- match.arg(stacked_align)
  group_align <- match.arg(group_align)
  
  # Validate required args
  if (missing(input_id) || is.null(input_id)) {
    stop("input_id is required for add_input()", call. = FALSE)
  }
  if (missing(filter_var) || is.null(filter_var)) {
    stop("filter_var is required for add_input() - this should match the group_var in your visualization", call. = FALSE)
  }

  # Backward-compatible alias for slider-like inputs
  if (!is.null(default_value)) {
    if (!is.null(value)) {
      warning("Both 'value' and deprecated 'default_value' were provided. Using 'value'.", call. = FALSE)
    } else {
      value <- default_value
    }
  }
  
  # Get parent data for auto-deriving options
  parent_data <- NULL
  if (inherits(content, "sidebar_container") && !is.null(content$parent_content)) {
    parent_data <- content$parent_content$data
  } else if (is_content(content)) {
    parent_data <- content$data
  }
  
  # AUTO-DERIVE OPTIONS from data when not provided
  # This is the R-first approach: user just says filter_var="column" and we figure out the rest
  if (type %in% c("select_multiple", "select_single", "checkbox", "radio", "button_group")) {
    if (is.null(options) && is.null(options_from)) {
      # Try to auto-derive from data
      if (!is.null(parent_data) && filter_var %in% names(parent_data)) {
        data_values <- unique(as.character(parent_data[[filter_var]]))
        data_values <- data_values[!is.na(data_values)]
        data_values <- sort(data_values)
        
        if (length(data_values) > 0) {
          options <- data_values
          message("add_input(): Auto-derived ", length(options), " options from data column '", filter_var, "'")
        } else {
          stop("add_input(): Column '", filter_var, "' exists but has no non-NA values", call. = FALSE)
        }
      } else if (!is.null(parent_data) && !filter_var %in% names(parent_data)) {
        stop("add_input(): Column '", filter_var, "' not found in data. ",
             "Available columns: ", paste(names(parent_data), collapse = ", "), call. = FALSE)
      } else {
        stop("Either 'options' or 'options_from' must be provided for ", type, " input type ",
             "(or ensure data is available for auto-derivation)", call. = FALSE)
      }
    }
  }
  
  # ADD "All" OPTION for radio/select_single if requested
  # This prepends an "All" option that represents selecting all values
  if (add_all && type %in% c("radio", "select_single", "button_group")) {
    options <- c(add_all_label, options)
    # Default to "All" if no default specified
    if (is.null(default_selected)) {
      default_selected <- add_all_label
    }
  }
  
  # AUTO-SET default_selected to all options if not specified (for multi-select types)
  if (is.null(default_selected) && type %in% c("select_multiple", "checkbox")) {
    default_selected <- options
  }
  
  # Validate filter options against data if data is available
  # This catches mismatches early (e.g., "Male" vs "male")
  if (!is.null(parent_data) && !is.null(options) && filter_var %in% names(parent_data)) {
    data_values <- unique(as.character(parent_data[[filter_var]]))
    data_values <- data_values[!is.na(data_values)]
    
    # Check if options match data values
    # Exclude add_all_label from mismatch check (it's a special "All" option, not a data value)
    options_to_check <- options
    if (add_all) {
      options_to_check <- setdiff(options, add_all_label)
    }
    mismatched <- setdiff(options_to_check, data_values)
    if (length(mismatched) > 0) {
      warning(
        "add_input(): Some options don't match values in data column '", filter_var, "':\n",
        "  Options not in data: ", paste(mismatched, collapse = ", "), "\n",
        "  Actual data values: ", paste(sort(data_values), collapse = ", "), "\n",
        "  This may result in empty charts or non-functional filters.",
        call. = FALSE
      )
    }
  }
  
  # Create the input specification
  input_spec <- list(
    input_id = input_id,
    label = label,
    type = type,
    filter_var = filter_var,
    options = options,
    options_from = options_from,
    default_selected = default_selected,
    placeholder = placeholder,
    width = width,
    min = min,
    max = max,
    step = step,
    value = value,
    show_value = show_value,
    inline = inline,
    stacked = stacked,
    stacked_align = stacked_align,
    group_align = group_align,
    ncol = ncol,
    nrow = nrow,
    columns = columns,
    toggle_series = toggle_series,
    override = override,
    labels = labels,
    size = size,
    help = help,
    disabled = disabled,
    mt = mt,
    mr = mr,
    mb = mb,
    ml = ml
  )
  
  # Check if we're adding to a row container
  if (inherits(content, "input_row_container")) {
    # Add to the row's inputs
    content$inputs <- c(content$inputs, list(input_spec))
    
    # If filter_var is "metric", mark on the row container (propagated in end_input_row)
    if (!is.null(filter_var) && filter_var == "metric") {
      content$needs_metric_data <- TRUE
    }
    
    return(content)
  }
  
  # Check if we're adding to a sidebar container
  if (inherits(content, "sidebar_container")) {
    # Store input_type separately to avoid conflict with content block type
    input_block <- structure(list(
      type = "input",
      input_type = type,  # Store the actual input widget type separately
      input_id = input_id,
      label = label,
      filter_var = filter_var,
      options = options,
      options_from = options_from,
      default_selected = default_selected,
      placeholder = placeholder,
      width = width,
      min = min,
      max = max,
      step = step,
      value = value,
      show_value = show_value,
      inline = inline,
      stacked = stacked,
      stacked_align = stacked_align,
      group_align = group_align,
      ncol = ncol,
      nrow = nrow,
      toggle_series = toggle_series,
      override = override,
      labels = labels,
      size = size,
      help = help,
      disabled = disabled,
      .linked_parent_id = .linked_parent_id,
      .options_by_parent = .options_by_parent
    ), class = "content_block")
    content$blocks <- c(content$blocks, list(input_block))
    content$needs_inputs <- TRUE
    
    # If filter_var is "metric", mark on the sidebar container
    if (!is.null(filter_var) && filter_var == "metric") {
      content$needs_metric_data <- TRUE
    }
    
    return(content)
  }
  
  # Otherwise, add as a standalone input
  if (!is_content(content)) {
    stop("First argument must be a content_collection object, input_row_container, or sidebar_container", call. = FALSE)
  }
  
  # Mark that this collection needs inputs enabled
  content$needs_inputs <- TRUE
  
  # If filter_var is "metric", mark that we need full data embedded for JS
  if (!is.null(filter_var) && filter_var == "metric") {
    content$needs_metric_data <- TRUE
  }
  
  # Store input_type separately to avoid conflict with content block type
  input_block <- structure(list(
    type = "input",
    input_type = type,  # Store the actual input widget type separately
    tabgroup = .parse_tabgroup(tabgroup),
    input_id = input_id,
    label = label,
    filter_var = filter_var,
    options = options,
    options_from = options_from,
    default_selected = default_selected,
    placeholder = placeholder,
    width = width,
    min = min,
    max = max,
    step = step,
    value = value,
    show_value = show_value,
    inline = inline,
    stacked = stacked,
    stacked_align = stacked_align,
    group_align = group_align,
    ncol = ncol,
    nrow = nrow,
    toggle_series = toggle_series,
    override = override,
    labels = labels,
    size = size,
    help = help,
    disabled = disabled,
    mt = mt,
    mr = mr,
    mb = mb,
    ml = ml
  ), class = "content_block")
  
  insertion_idx <- length(content$items) + 1
  input_block$.insertion_index <- insertion_idx
  content$items <- c(content$items, list(input_block))
  content
}


#' Add a filter control (simplified interface)
#'
#' A convenience wrapper around \code{\link{add_input}} for common filtering use cases.
#' Options are automatically derived from the data column specified by \code{filter_var}.
#' All values are selected by default.
#'
#' @param content A content_collection object
#' @param filter_var The column name in your data to filter by (quoted or unquoted)
#' @param label Optional label for the filter (defaults to the column name)
#' @param type Filter type: "checkbox" (default), "select", or "radio"
#' @param ... Additional arguments passed to \code{\link{add_input}}
#' @return Updated content_collection
#' @export
#' @examples
#' \dontrun{
#' # Simplest usage - just specify the column!
#' content <- create_content(data = mydata) %>%
#'   add_sidebar() %>%
#'     add_filter(filter_var = "education") %>%
#'     add_filter(filter_var = "gender") %>%
#'   end_sidebar() %>%
#'   add_viz(type = "stackedbar", x_var = "region", stack_var = "outcome")
#' }
add_filter <- function(content,
                       filter_var,
                       label = NULL,
                       type = c("checkbox", "select", "radio"),
                       ...) {
  
  filter_var_str <- .as_var_string(rlang::enquo(filter_var))
  type <- match.arg(type)
  
  # Map simplified type names to add_input types
  input_type <- switch(type,
    "checkbox" = "checkbox",
    "select" = "select_multiple",
    "radio" = "radio"
  )
  
  # Generate input_id from filter_var
  input_id <- paste0(filter_var_str, "_filter")
  
  # Use column name as label if not provided
  if (is.null(label)) {
    # Convert snake_case or camelCase to Title Case
    label <- gsub("_", " ", filter_var_str)
    label <- gsub("([a-z])([A-Z])", "\\1 \\2", label)
    label <- paste0(toupper(substr(label, 1, 1)), substr(label, 2, nchar(label)), ":")
  }
  
  add_input(
    content = content,
    input_id = input_id,
    label = label,
    type = input_type,
    filter_var = filter_var_str,
    ...
  )
}

#' Start an input row
#'
#' Creates a container for input widgets that will be displayed in a horizontal row.
#' The inputs will wrap responsively on smaller screens. Use with end_input_row().
#'
#' @param content Content collection object
#' @param tabgroup Optional tabgroup for organizing content. Use this to place
#'   the input row inside a specific tab (e.g., "trends" or "trends/Female Authorship")
#' @param style Visual style: "boxed" (default, with background and border) or
#'   "inline" (compact, transparent background)
#' @param align Alignment: "center" (default), "left", or "right"
#' @return An input_row_container for piping
#' @export
#' @examples
#' \dontrun{
#' content <- create_content() %>%
#'   add_input_row() %>%
#'     add_input(input_id = "country", filter_var = "country", options_from = "country") %>%
#'     add_input(input_id = "metric", filter_var = "metric", options_from = "metric") %>%
#'   end_input_row()
#'
#' # Place inputs inside a tabgroup
#' content <- create_content() %>%
#'   add_input_row(tabgroup = "trends", style = "inline") %>%
#'     add_input(input_id = "country", filter_var = "country", options = c("A", "B")) %>%
#'   end_input_row()
#' }
add_input_row <- function(content, tabgroup = NULL, style = c("boxed", "inline"), 
                          align = c("center", "left", "right")) {
  style <- match.arg(style)
  align <- match.arg(align)
  
  # Handle page_object
  if (inherits(content, "page_object")) {
    row_container <- structure(list(
      type = "input_row",
      inputs = list(),
      parent_page = content,
      parent_content = NULL,
      tabgroup = .parse_tabgroup(tabgroup),
      style = style,
      align = align
    ), class = c("input_row_container", "content_block"))
    return(row_container)
  }
  
  if (!is_content(content)) {
    stop("First argument must be a content collection or page_object", call. = FALSE)
  }
  
  # Mark that this collection needs inputs enabled
  content$needs_inputs <- TRUE
  
  # Create a special row container that add_input will detect
  row_container <- structure(list(
    type = "input_row",
    inputs = list(),
    parent_content = content,
    parent_page = NULL,
    tabgroup = .parse_tabgroup(tabgroup),
    style = style,
    align = align
  ), class = c("input_row_container", "content_block"))
  
  row_container
}

#' End an input row
#'
#' Closes an input row and returns to the parent content collection.
#' Must be called after add_input_row() and all add_input() calls.
#'
#' @param row_container Input row container object
#' @return The parent content_collection for further piping
#' @export
#' @examples
#' \dontrun{
#' content <- create_content() %>%
#'   add_input_row() %>%
#'     add_input(input_id = "filter1", filter_var = "var1", options = c("A", "B")) %>%
#'     add_input(input_id = "filter2", filter_var = "var2", options = c("X", "Y")) %>%
#'   end_input_row() %>%
#'   add_text("Content after the input row...")
#' }
end_input_row <- function(row_container) {
  if (!inherits(row_container, "input_row_container")) {
    stop("end_input_row() must be called on an input_row_container (created by add_input_row())", call. = FALSE)
  }
  
  # Create the final input_row block with all collected inputs
  input_row_block <- structure(list(
    type = "input_row",
    inputs = row_container$inputs,
    tabgroup = row_container$tabgroup,
    style = row_container$style %||% "boxed",
    align = row_container$align %||% "center"
  ), class = "content_block")
  
  # Handle page_object parent
  if (!is.null(row_container$parent_page)) {
    parent_page <- row_container$parent_page
    parent_page$.items <- c(parent_page$.items, list(input_row_block))
    parent_page$needs_inputs <- TRUE
    return(parent_page)
  }
  
  # Handle content collection parent
  parent_content <- row_container$parent_content
  
  # Add insertion index to preserve order
  insertion_idx <- length(parent_content$items) + 1
  input_row_block$.insertion_index <- insertion_idx
  
  # Add it to the parent content collection
  parent_content$items <- c(parent_content$items, list(input_row_block))
  
  # Propagate needs_metric_data flag from row container to parent
  if (isTRUE(row_container$needs_metric_data)) {
    parent_content$needs_metric_data <- TRUE
  }
  
  # Return the parent content collection for further piping
  parent_content
}

# ============================================
# OPERATOR OVERLOADING FOR + SYNTAX
# ============================================
# Note: +.viz_collection is defined in viz_collection.R to avoid duplication

#' Merge two content/viz collections
#'
#' Internal function to merge two collections into one.
#'
#' @param c1 First collection
#' @param c2 Second collection
#' @return Merged content_collection
#' @export
merge_collections <- function(c1, c2) {
  if (!is_content(c1) && !is_content_block(c1)) {
    stop("Left operand must be a content_collection, viz_collection, or content_block", call. = FALSE)
  }
  if (!is_content(c2) && !is_content_block(c2)) {
    stop("Right operand must be a content_collection, viz_collection, or content_block", call. = FALSE)
  }
  
  # Handle content blocks (single items)
  if (is_content_block(c1) && !is_content(c1)) {
    temp <- create_content()
    temp$items <- list(c1)
    c1 <- temp
  }
  if (is_content_block(c2) && !is_content(c2)) {
    temp <- create_content()
    temp$items <- list(c2)
    c2 <- temp
  }
  
  # Create new collection
  result <- create_content()
  
  # Merge items from both collections
  # Items from c1 first, then c2
  all_items <- c(c1$items, c2$items)
  
  # Re-index insertion indices
  for (i in seq_along(all_items)) {
    all_items[[i]]$.insertion_index <- i
  }
  
  result$items <- all_items
  
  # Merge tabgroup labels if present
  if (!is.null(c1$tabgroup_labels) || !is.null(c2$tabgroup_labels)) {
    result$tabgroup_labels <- c(c1$tabgroup_labels, c2$tabgroup_labels)
  }
  
  # Merge defaults if present
  if (!is.null(c1$defaults) || !is.null(c2$defaults)) {
    result$defaults <- modifyList(
      c1$defaults %||% list(),
      c2$defaults %||% list()
    )
  }
  
  # Propagate needs_inputs flag
  if (isTRUE(c1$needs_inputs) || isTRUE(c2$needs_inputs)) {
    result$needs_inputs <- TRUE
  }
  
  # Propagate needs_metric_data flag
  if (isTRUE(c1$needs_metric_data) || isTRUE(c2$needs_metric_data)) {
    result$needs_metric_data <- TRUE
  }
  
  result
}

#' Normalize a filter_var value to a character vector
#' 
#' Internal helper to coerce various filter_var representations
#' (character, factor, symbol, language) to a character vector.
#' 
#' @param x A filter_var value (character, factor, symbol, or language object)
#' @return Character vector of unique filter_var values
#' @keywords internal
.normalize_filter_var_value <- function(x) {
  if (is.null(x)) return(character(0))
  if (is.character(x)) return(x[nzchar(x)])
  if (is.factor(x)) return(as.character(x[nzchar(as.character(x))]))
  if (is.symbol(x)) return(as.character(x))
  if (is.language(x)) {
    out <- tryCatch(as.character(x), error = function(e) character(0))
    return(out[nzchar(out)])
  }
  character(0)
}

.collect_filter_vars_from_item <- function(item) {
  if (is.null(item) || !is.list(item)) return(character(0))

  vars <- character(0)
  if (!is.null(item$type) && item$type == "input" && !is.null(item$filter_var)) {
    vars <- c(vars, .normalize_filter_var_value(item$filter_var))
  }

  if (!is.null(item$type) && item$type == "input_row" && !is.null(item$inputs)) {
    for (inp in item$inputs) {
      if (!is.null(inp$filter_var)) {
        vars <- c(vars, .normalize_filter_var_value(inp$filter_var))
      }
    }
  }

  if (!is.null(item$items) && is.list(item$items)) {
    for (child in item$items) {
      vars <- c(vars, .collect_filter_vars_from_item(child))
    }
  }

  vars
}

.extract_filter_vars <- function(content) {
  filter_vars <- character(0)

  # Check sidebar blocks
  if (!is.null(content$sidebar) && !is.null(content$sidebar$blocks)) {
    for (block in content$sidebar$blocks) {
      if (!is.null(block$type) && block$type == "input" && !is.null(block$filter_var)) {
        filter_vars <- c(filter_vars, .normalize_filter_var_value(block$filter_var))
      }
    }
  }
  
  # Check content items (for input_row or standalone inputs)
  if (!is.null(content$items)) {
    for (item in content$items) {
      filter_vars <- c(filter_vars, .collect_filter_vars_from_item(item))
    }
  }
  
  # page_object-style inline items (defensive)
  if (!is.null(content$.items)) {
    for (item in content$.items) {
      filter_vars <- c(filter_vars, .collect_filter_vars_from_item(item))
    }
  }
  
  # Return unique filter_vars
  unique(filter_vars)
}
