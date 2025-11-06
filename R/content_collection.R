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
#' @param tabgroup_labels Named vector/list mapping tabgroup IDs to display names
#' @param ... Default parameters to apply to all subsequent add_viz() calls
#' @return A content_collection (also a viz_collection for compatibility)
#' @export
#' @examples
#' \dontrun{
#' # These are equivalent:
#' content <- create_content() %>%
#'   add_text("# Title") %>%
#'   add_viz(type = "histogram", x_var = "age")
#'
#' content <- create_viz() %>%
#'   add_text("# Title") %>%
#'   add_viz(type = "histogram", x_var = "age")
#' }
create_content <- function(tabgroup_labels = NULL, ...) {
  create_viz(tabgroup_labels = tabgroup_labels, ...)
}


#' Add text to content collection (pipeable)
#'
#' Adds a text block to a content collection. Can be used standalone or in a pipe.
#' Supports viz_collection as first argument for seamless piping.
#'
#' @param content_collection A content_collection, viz_collection, or NULL
#' @param text Markdown text content (can be multi-line)
#' @param ... Additional text lines (will be combined with newlines)
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
#' # Pipe directly from viz
#' content <- create_viz() %>%
#'   add_viz(type = "histogram", x_var = "age") %>%
#'   add_text("Analysis complete")
#' }
add_text <- function(content_collection = NULL, text, ...) {
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
    stop("First argument must be a content collection, content_block, character string, or NULL")
  }
  
  # Combine all text arguments
  args <- list(text, ...)
  text_content <- character(0)
  
  for (arg in args) {
    if (is.character(arg)) {
      text_content <- c(text_content, arg)
    } else {
      text_content <- c(text_content, as.character(arg))
    }
  }
  
  # Join with newlines
  final_content <- paste(text_content, collapse = "\n")
  
  # Create text block
  text_block <- structure(
    list(
      type = "text",
      content = final_content
    ),
    class = "content_block"
  )
  
  # Return appropriate type
  if (was_null) {
    # Standalone mode - return just the content block
    return(text_block)
  } else {
    # Pipeable mode - add to collection and return it
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
#' # Pipe directly from viz
#' content <- create_viz() %>%
#'   add_viz(type = "bar", x_var = "category") %>%
#'   add_image(src = "logo.png", alt = "Logo")
#' }
add_image <- function(content_collection = NULL, src, alt = NULL, caption = NULL, 
                      width = NULL, height = NULL, align = c("center", "left", "right"), 
                      link = NULL, class = NULL) {
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
    stop("First argument must be a content collection, content_block, or NULL")
  }
  
  # Validate src
  if (is.null(src) || !is.character(src) || length(src) != 1 || nchar(src) == 0) {
    stop("src must be a non-empty character string")
  }
  
  # Validate and match align
  align <- match.arg(align)
  
  # Validate optional parameters
  if (!is.null(alt) && (!is.character(alt) || length(alt) != 1)) {
    stop("alt must be a character string or NULL")
  }
  if (!is.null(caption) && (!is.character(caption) || length(caption) != 1)) {
    stop("caption must be a character string or NULL")
  }
  if (!is.null(width) && (!is.character(width) || length(width) != 1)) {
    stop("width must be a character string or NULL")
  }
  if (!is.null(height) && (!is.character(height) || length(height) != 1)) {
    stop("height must be a character string or NULL")
  }
  if (!is.null(link) && (!is.character(link) || length(link) != 1)) {
    stop("link must be a character string or NULL")
  }
  if (!is.null(class) && (!is.character(class) || length(class) != 1)) {
    stop("class must be a character string or NULL")
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
      class = class
    ),
    class = "content_block"
  )
  
  # Return appropriate type
  if (was_null) {
    # Standalone mode - return just the content block
    return(image_block)
  } else {
    # Pipeable mode - add to collection and return it
    content_collection$items <- c(content_collection$items, list(image_block))
    return(content_collection)
  }
}

#' Add callout box
#' @param content A content_collection or viz_collection object
#' @param text Callout content
#' @param type Callout type (note/tip/warning/caution/important)
#' @param title Optional title
#' @param icon Optional icon
#' @param collapse Whether callout is collapsible
#' @return Updated content_collection
#' @export
add_callout <- function(content, text, type = c("note", "tip", "warning", "caution", "important"),
                        title = NULL, icon = NULL, collapse = FALSE) {
  if (!is_content(content)) {
    stop("First argument must be a content collection")
  }
  
  type <- match.arg(type)
  
  callout_block <- structure(list(
    type = "callout",
    callout_type = type,
    content = text,
    title = title,
    icon = icon,
    collapse = collapse
  ), class = "content_block")
  
  content$items <- c(content$items, list(callout_block))
  content
}

#' Add horizontal divider
#' @param content A content_collection or viz_collection object
#' @param style Divider style ("default", "thick", "dashed", "dotted")
#' @return Updated content_collection
#' @export
add_divider <- function(content, style = "default") {
  if (!is_content(content)) {
    stop("First argument must be a content collection")
  }
  
  divider_block <- structure(list(
    type = "divider",
    style = style
  ), class = "content_block")
  
  content$items <- c(content$items, list(divider_block))
  content
}

#' Add code block
#' @param content A content_collection or viz_collection object
#' @param code Code content
#' @param language Programming language for syntax highlighting
#' @param caption Optional caption
#' @param filename Optional filename to display
#' @return Updated content_collection
#' @export
add_code <- function(content, code, language = "r", caption = NULL, filename = NULL) {
  if (!is_content(content)) {
    stop("First argument must be a content collection")
  }
  
  code_block <- structure(list(
    type = "code",
    code = code,
    language = language,
    caption = caption,
    filename = filename
  ), class = "content_block")
  
  content$items <- c(content$items, list(code_block))
  content
}

#' Add vertical spacer
#' @param content A content_collection or viz_collection object
#' @param height Height (CSS unit, e.g. "2rem", "50px")
#' @return Updated content_collection
#' @export
add_spacer <- function(content, height = "2rem") {
  if (!is_content(content)) {
    stop("First argument must be a content collection")
  }
  
  spacer_block <- structure(list(
    type = "spacer",
    height = height
  ), class = "content_block")
  
  content$items <- c(content$items, list(spacer_block))
  content
}

#' Add gt table
#' @param content A content_collection object
#' @param gt_object A gt table object (from gt::gt()) OR a data frame (will be auto-converted)
#' @param caption Optional caption
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
add_gt <- function(content, gt_object, caption = NULL) {
  if (!is_content(content)) {
    stop("First argument must be a content collection")
  }
  
  # Accept both gt tables and data frames
  # If it's a data frame, it will be converted to gt in rendering
  
  gt_block <- structure(list(
    type = "gt",
    gt_object = gt_object,
    caption = caption,
    is_dataframe = is.data.frame(gt_object)
  ), class = "content_block")
  
  content$items <- c(content$items, list(gt_block))
  content
}

#' Add reactable table
#' @param content A content_collection object
#' @param reactable_object A reactable object (from reactable::reactable()) OR a data frame (will be auto-converted)
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
add_reactable <- function(content, reactable_object) {
  if (!is_content(content)) {
    stop("First argument must be a content collection")
  }
  
  # Accept both reactable tables and data frames
  # If it's a data frame, it will be converted to reactable in rendering
  
  reactable_block <- structure(list(
    type = "reactable",
    reactable_object = reactable_object,
    is_dataframe = is.data.frame(reactable_object)
  ), class = "content_block")
  
  content$items <- c(content$items, list(reactable_block))
  content
}

#' Add generic table (data frame)
#' @param content A content_collection object
#' @param table_object A data frame or tibble
#' @param caption Optional caption
#' @return Updated content_collection
#' @export
add_table <- function(content, table_object, caption = NULL) {
  if (!is_content(content)) {
    stop("First argument must be a content collection")
  }
  
  table_block <- structure(list(
    type = "table",
    table_object = table_object,
    caption = caption
  ), class = "content_block")
  
  content$items <- c(content$items, list(table_block))
  content
}

#' Add DT datatable
#' @param content A content_collection object
#' @param table_data A DT datatable object (from DT::datatable()) OR a data frame/matrix (will be auto-converted)
#' @param options List of DT options (only used if passing a data frame)
#' @param ... Additional arguments passed to DT::datatable() (only used if passing a data frame)
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
add_DT <- function(content, table_data, options = NULL, ...) {
  if (!is_content(content)) {
    stop("First argument must be a content collection")
  }
  
  dt_block <- structure(list(
    type = "DT",
    table_data = table_data,
    options = options,
    extra_args = list(...)
  ), class = "content_block")
  
  content$items <- c(content$items, list(dt_block))
  content
}

#' Add video
#' @param content A content_collection object
#' @param src Video source URL or path
#' @param caption Optional caption
#' @param width Optional width
#' @param height Optional height
#' @return Updated content_collection
#' @export
add_video <- function(content, src, caption = NULL, width = NULL, height = NULL) {
  if (!is_content(content)) {
    stop("First argument must be a content collection")
  }
  
  video_block <- structure(list(
    type = "video",
    url = src,
    caption = caption,
    width = width,
    height = height
  ), class = "content_block")
  
  content$items <- c(content$items, list(video_block))
  content
}

#' Add iframe
#' @param content A content_collection object
#' @param src iframe source URL
#' @param height iframe height (default: "500px")
#' @param width iframe width (default: "100%")
#' @return Updated content_collection
#' @export
add_iframe <- function(content, src, height = "500px", width = "100%") {
  if (!is_content(content)) {
    stop("First argument must be a content collection")
  }
  
  iframe_block <- structure(list(
    type = "iframe",
    url = src,
    height = height,
    width = width
  ), class = "content_block")
  
  content$items <- c(content$items, list(iframe_block))
  content
}

#' Add collapsible accordion/details section
#' @param content A content_collection or viz_collection object
#' @param title Section title
#' @param text Section content
#' @param open Whether section starts open (default: FALSE)
#' @return Updated content_collection
#' @export
add_accordion <- function(content, title, text, open = FALSE) {
  if (!is_content(content)) {
    stop("First argument must be a content collection")
  }
  
  accordion_block <- structure(list(
    type = "accordion",
    title = title,
    text = text,
    open = open
  ), class = "content_block")
  
  content$items <- c(content$items, list(accordion_block))
  content
}

#' Add card
#' @param content A content_collection or viz_collection object
#' @param title Card title
#' @param text Card content
#' @param footer Optional card footer
#' @return Updated content_collection
#' @export
add_card <- function(content, text, title = NULL, footer = NULL) {
  if (!is_content(content)) {
    stop("First argument must be a content collection")
  }
  
  card_block <- structure(list(
    type = "card",
    title = title,
    text = text,
    footer = footer
  ), class = "content_block")
  
  content$items <- c(content$items, list(card_block))
  content
}

#' Add raw HTML content
#'
#' @param content Content collection object
#' @param html Raw HTML string
#' @export
add_html <- function(content, html) {
  if (!is_content(content)) {
    stop("First argument must be a content collection")
  }
  html_block <- structure(list(
    type = "html",
    html = html
  ), class = "content_block")
  content$items <- c(content$items, list(html_block))
  content
}

#' Add a blockquote
#'
#' @param content Content collection object
#' @param quote Quote text
#' @param attribution Optional attribution/source
#' @param cite Optional citation URL
#' @export
add_quote <- function(content, quote, attribution = NULL, cite = NULL) {
  if (!is_content(content)) {
    stop("First argument must be a content collection")
  }
  quote_block <- structure(list(
    type = "quote",
    quote = quote,
    attribution = attribution,
    cite = cite
  ), class = "content_block")
  content$items <- c(content$items, list(quote_block))
  content
}

#' Add a status badge
#'
#' @param content Content collection object
#' @param text Badge text
#' @param color Badge color (success, warning, danger, info, primary, secondary)
#' @export
add_badge <- function(content, text, color = "primary") {
  if (!is_content(content)) {
    stop("First argument must be a content collection")
  }
  badge_block <- structure(list(
    type = "badge",
    text = text,
    color = color
  ), class = "content_block")
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
#' @param subtitle Optional subtitle text
#' @export
add_metric <- function(content, value, title, icon = NULL, color = NULL, subtitle = NULL) {
  if (!is_content(content)) {
    stop("First argument must be a content collection")
  }
  metric_block <- structure(list(
    type = "metric",
    value = value,
    title = title,
    icon = icon,
    color = color,
    subtitle = subtitle
  ), class = "content_block")
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
#' @export
#' @examples
#' \dontrun{
#' # Standalone value box
#' content <- create_content() %>%
#'   add_value_box(
#'     title = "Total Revenue",
#'     value = "€1,234,567",
#'     logo_text = "💰",
#'     bg_color = "#2E86AB"
#'   )
#'   
#' # Row of value boxes (pipeable!)
#' content <- create_content() %>%
#'   add_value_box_row() %>%
#'     add_value_box(title = "Users", value = "1,234") %>%
#'     add_value_box(title = "Revenue", value = "€56K")
#' }
add_value_box <- function(content, title, value, logo_url = NULL, logo_text = NULL, 
                          bg_color = "#2c3e50", description = NULL, 
                          description_title = "About this source") {
  
  # Create the box specification
  box_spec <- list(
    title = title,
    value = value,
    logo_url = logo_url,
    logo_text = logo_text,
    bg_color = bg_color,
    description = description,
    description_title = description_title
  )
  
  # Check if we're adding to a row container
  if (inherits(content, "value_box_row_container")) {
    # Add to the row's boxes
    content$boxes <- c(content$boxes, list(box_spec))
    return(content)
  }
  
  # Otherwise, add as a standalone value box
  if (!inherits(content, "content_collection")) {
    stop("First argument must be a content_collection object or value_box_row_container")
  }
  
  value_box_block <- structure(c(list(type = "value_box"), box_spec), class = "content_block")
  
  content$items <- c(content$items, list(value_box_block))
  content
}

#' Start a value box row
#'
#' Creates a container for value boxes that will be displayed in a horizontal row.
#' The boxes will wrap responsively on smaller screens. Use pipeable syntax with end_value_box_row():
#'
#' @param content Content collection object
#' @export
#' @examples
#' \dontrun{
#' content <- create_content() %>%
#'   add_value_box_row() %>%
#'     add_value_box(title = "Users", value = "1,234", bg_color = "#2E86AB") %>%
#'     add_value_box(title = "Revenue", value = "€56K", bg_color = "#F18F01") %>%
#'     add_value_box(title = "Growth", value = "+23%", bg_color = "#A23B72") %>%
#'   end_value_box_row()
#' }
add_value_box_row <- function(content) {
  if (!is_content(content)) {
    stop("First argument must be a content collection")
  }
  
  # Create a special row container that add_value_box will detect
  row_container <- structure(list(
    type = "value_box_row",
    boxes = list(),
    parent_content = content
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
#'     add_value_box(title = "Revenue", value = "€56K") %>%
#'   end_value_box_row() %>%
#'   add_text("More content after the row...")
#' }
end_value_box_row <- function(row_container) {
  if (!inherits(row_container, "value_box_row_container")) {
    stop("end_value_box_row() must be called on a value_box_row_container (created by add_value_box_row())")
  }
  
  # Get the parent content collection
  parent_content <- row_container$parent_content
  
  # Create the final value_box_row block with all collected boxes
  value_box_row_block <- structure(list(
    type = "value_box_row",
    boxes = row_container$boxes
  ), class = "content_block")
  
  # Add it to the parent content collection
  parent_content$items <- c(parent_content$items, list(value_box_row_block))
  
  # Return the parent content collection for further piping
  parent_content
}

