#' Enable Modal Functionality
#'
#' Adds modal CSS and JavaScript to enable clickable links that open content
#' in a centered modal overlay instead of navigating to a new page.
#'
#' @return HTML tags to include modal functionality
#' @export
#'
#' @examples
#' \dontrun{
#' # In your dashboard page content:
#' enable_modals()
#' }
enable_modals <- function() {
  # Add version parameter to bust cache
  version <- format(Sys.time(), "%Y%m%d%H%M%S")
  
  htmltools::tagList(
    htmltools::tags$link(
      rel = "stylesheet",
      href = paste0("assets/modal.css?v=", version)
    ),
    htmltools::tags$script(
      src = paste0("assets/modal.js?v=", version)
    )
  )
}

#' Create Modal Link
#'
#' Creates a hyperlink that opens content in a modal dialog instead of
#' navigating to a new page. You can also use regular markdown syntax:
#' `[Link Text](#modal-id)` and it will automatically open as a modal.
#'
#' @param text Link text to display
#' @param modal_id ID of the modal content div
#' @param class Additional CSS classes for the link
#'
#' @return HTML link element
#' @export
#'
#' @examples
#' \dontrun{
#' modal_link("View Details", "details-modal")
#' modal_link("See Chart", "chart1", class = "btn btn-primary")
#' 
#' # Or in markdown:
#' # [View Details](#details-modal)
#' }
modal_link <- function(text, modal_id, class = NULL) {
  htmltools::tags$a(
    href = paste0("#", modal_id),
    class = class,
    text
  )
}

#' Create Modal Content Container
#'
#' Creates a hidden div that contains the content to be displayed in a modal.
#' The content will be shown when a link with matching modal_id is clicked.
#'
#' @param modal_id Unique ID for this modal content
#' @param ... Content to display in modal (images, text, HTML)
#' @param title Optional title to display at top of modal
#' @param image Optional image path or URL to display
#' @param text Optional text/HTML content to display below image
#'
#' @return HTML div element
#' @export
#'
#' @examples
#' \dontrun{
#' # Simple text modal
#' modal_content(
#'   modal_id = "info",
#'   title = "Information",
#'   text = "This is some important information."
#' )
#' 
#' # Modal with image and text
#' modal_content(
#'   modal_id = "chart1",
#'   title = "Sales Chart",
#'   image = "charts/sales.png",
#'   text = "This chart shows sales trends over the past year."
#' )
#' 
#' # Custom content
#' modal_content(
#'   modal_id = "custom",
#'   htmltools::tags$h2("Custom Title"),
#'   htmltools::tags$img(src = "image.jpg"),
#'   htmltools::tags$p("Description text"),
#'   htmltools::tags$ul(
#'     htmltools::tags$li("Point 1"),
#'     htmltools::tags$li("Point 2")
#'   )
#' )
#' }
modal_content <- function(modal_id, ..., title = NULL, image = NULL, text = NULL) {
  
  # Build content from provided arguments
  content_parts <- list()
  
  # Add title if provided
  if (!is.null(title)) {
    content_parts <- c(content_parts, list(htmltools::tags$h2(title)))
  }
  
  # Add image if provided
  if (!is.null(image)) {
    content_parts <- c(content_parts, list(htmltools::tags$img(src = image, alt = title %||% "")))
  }
  
  # Add text if provided (can be HTML or plain text)
  if (!is.null(text)) {
    if (is.character(text)) {
      content_parts <- c(content_parts, list(htmltools::HTML(text)))
    } else {
      content_parts <- c(content_parts, list(text))
    }
  }
  
  # Add any additional content from ...
  dots <- list(...)
  if (length(dots) > 0) {
    content_parts <- c(content_parts, dots)
  }
  
  htmltools::tags$div(
    id = modal_id,
    class = "modal-content",
    style = "display:none;",
    content_parts
  )
}




#' Add Modal to Content Collection (Pipeable)
#'
#' Adds a modal definition to your content collection. Use markdown links
#' with \{.modal-link\} class to trigger the modal.
#'
#' @param x A content_collection, viz_collection, or page_object to add modal to
#' @param modal_id Unique ID for this modal (used in markdown link)
#' @param title Modal title (optional)
#' @param modal_content Text content - can be plain text, HTML, or data.frame
#' @param image Optional image URL or path
#' @param image_width Width of the image (default "100%"). Can be percentage ("70%") or pixels ("500px")
#' @param ... Additional content (data.frames will be converted to tables)
#'
#' @return Updated content_collection with modal added
#' @export
#'
#' @examples
#' \dontrun{
#' # Pipeable syntax (RECOMMENDED)
#' content <- create_content() %>%
#'   add_text("## Results") %>%
#'   add_text("[View details](#details){.modal-link}") %>%
#'   add_modal(
#'     modal_id = "details",
#'     title = "Full Results",
#'     modal_content = "Detailed analysis here..."
#'   )
#' 
#' # With image (custom width)
#' content <- create_viz() %>%
#'   add_viz(type = "column", x_var = "x", y_var = "y") %>%
#'   add_modal(
#'     modal_id = "chart-details",
#'     title = "Chart Details",
#'     image = "chart.png",
#'     image_width = "70%",  # Control image width
#'     modal_content = "This chart shows..."
#'   )
#' 
#' # With data.frame (auto-converts to table)
#' content <- create_content() %>%
#'   add_text("[View data](#data){.modal-link}") %>%
#'   add_modal(
#'     modal_id = "data",
#'     title = "Raw Data",
#'     modal_content = head(mtcars, 10)
#'   )
#' 
#' # Works with page objects too
#' page <- create_page("Results", data = my_data, type = "bar") %>%
#'   add_text("[View details](#info){.modal-link}") %>%
#'   add_modal(
#'     modal_id = "info",
#'     title = "More Info",
#'     modal_content = "Additional details..."
#'   )
#' }
add_modal <- function(x, modal_id, title = NULL, 
                      modal_content = NULL, image = NULL, image_width = "100%", ...) {
  UseMethod("add_modal")
}

#' @export
add_modal.default <- function(x, modal_id, title = NULL,
                              modal_content = NULL, image = NULL, image_width = "100%", ...) {
  # Build HTML content using helper
  html_content <- .build_modal_html(title, image, image_width, modal_content, ...)
  
  # Create md_text with modal content
  modal_text <- md_text(
    "```{r, echo=FALSE, results='asis'}",
    paste0("dashboardr::modal_content("),
    paste0("  modal_id = '", modal_id, "',"),
    paste0("  text = '", gsub("'", "\\\\'", html_content), "'"),
    ")",
    "```"
  )
  
  # Convert viz_collection to content_collection if needed
  if (inherits(x, "viz_collection") && 
      !inherits(x, "content_collection")) {
    class(x) <- c("content_collection", "viz_collection")
  }
  
  # Mark that this collection needs modals enabled
  x$needs_modals <- TRUE
  
  # Add modal text to the collection
  add_text(x, modal_text)
}

#' @export
add_modal.page_object <- function(x, modal_id, title = NULL,
                                   modal_content = NULL, image = NULL, image_width = "100%", ...) {
  page <- x
  
  # Build HTML content using helper
  html_content <- .build_modal_html(title, image, image_width, modal_content, ...)
  
  # Create a modal content block
  modal_block <- structure(
    list(
      type = "modal",
      modal_id = modal_id,
      html_content = html_content
    ),
    class = "content_block"
  )
  
  # Add to page items
  page$.items <- c(page$.items, list(modal_block))
  
  # Mark that this page needs modals enabled
  page$needs_modals <- TRUE
  
  page
}

# Helper function to build modal HTML content
.build_modal_html <- function(title = NULL, image = NULL, image_width = "100%", 
                               modal_content = NULL, ...) {
  html_parts <- c()
  
  # Add title
  if (!is.null(title)) {
    html_parts <- c(html_parts, paste0("<h2>", title, "</h2>"))
  }
  
  # Add image
  if (!is.null(image)) {
    html_parts <- c(html_parts, paste0('<img src="', image, '" style="max-width:', image_width, '; height:auto;">'))
  }
  
  # Add content
  if (!is.null(modal_content)) {
    if (is.data.frame(modal_content)) {
      # Convert data.frame to HTML table
      html_parts <- c(html_parts, .df_to_html_table(modal_content))
    } else if (is.character(modal_content)) {
      # Wrap in paragraph if it doesn't contain HTML tags
      if (!grepl("<[^>]+>", modal_content)) {
        html_parts <- c(html_parts, paste0("<p>", modal_content, "</p>"))
      } else {
        html_parts <- c(html_parts, modal_content)
      }
    }
  }
  
  # Add any additional content from ...
  dots <- list(...)
  for (item in dots) {
    if (is.data.frame(item)) {
      html_parts <- c(html_parts, .df_to_html_table(item))
    } else if (is.character(item)) {
      html_parts <- c(html_parts, item)
    }
  }
  
  paste(html_parts, collapse = "\n")
}

# Helper to convert data.frame to HTML table
.df_to_html_table <- function(df, max_rows = 100) {
  if (nrow(df) > max_rows) {
    df <- head(df, max_rows)
    truncated <- TRUE
  } else {
    truncated <- FALSE
  }
  
  html <- '<table style="width:100%; border-collapse:collapse; margin:10px 0;">\n'
  
  # Header
  html <- paste0(html, '<thead><tr style="background:#f0f0f0;">\n')
  for (col in names(df)) {
    html <- paste0(html, '<th style="border:1px solid #ddd; padding:8px; text-align:left;">', col, '</th>\n')
  }
  html <- paste0(html, '</tr></thead>\n<tbody>\n')
  
  # Rows
  for (i in seq_len(nrow(df))) {
    html <- paste0(html, '<tr>\n')
    for (col in names(df)) {
      html <- paste0(html, '<td style="border:1px solid #ddd; padding:8px;">', df[i, col], '</td>\n')
    }
    html <- paste0(html, '</tr>\n')
  }
  html <- paste0(html, '</tbody></table>\n')
  
  if (truncated) {
    html <- paste0(html, '<p style="color:#666; font-style:italic;">Showing first ', max_rows, ' rows</p>')
  }
  
  html
}

