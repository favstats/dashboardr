# =================================================================
# ui_components
# =================================================================



#' Create iconify icon shortcode
#'
#' Helper function to generate iconify icon shortcodes for use in pages and visualizations.
#'
#' @param icon_name Icon name in format "collection:name" (e.g., "ph:users-three")
#' @return Iconify shortcode string
#' @export
#' @examples
#' \dontrun{
#' icon("ph:users-three")  # Returns iconify shortcode
#' icon("emojione:flag-for-united-states")  # Returns iconify shortcode
#' }
icon <- function(icon_name) {
  # Convert "collection:name" to "{{< iconify collection name >}}"
  parts <- strsplit(icon_name, ":", fixed = TRUE)[[1]]
  if (length(parts) != 2) {
    stop("Icon name must be in format 'collection:name' (e.g., 'ph:users-three')")
  }
  paste0("{{< iconify ", parts[1], " ", parts[2], " >}}")
}

#' Create a Bootstrap card component
#'
#' Helper function to create Bootstrap card components for displaying content in a structured way.
#' Useful for author profiles, feature highlights, or any content that benefits from card layout.
#'
#' @param content Card content (text, HTML, or other elements)
#' @param title Optional card title
#' @param image Optional image URL or path
#' @param image_alt Alt text for the image
#' @param footer Optional card footer content
#' @param class Additional CSS classes for the card
#' @param style Additional inline styles for the card
#' @return HTML div element with Bootstrap card classes
#' @export
#' @examples
#' \dontrun{
#' # Simple text card
#' card("This is a simple card with just text content")
#'
#' # Card with title and image
#' card(
#'   content = "This is the card body content",
#'   title = "Card Title",
#'   image = "https://example.com/image.jpg",
#'   image_alt = "Description of image"
#' )
#'
#' # Author card
#' card(
#'   content = "Dr. Jane Smith is a researcher specializing in data science and visualization.",
#'   title = "Dr. Jane Smith",
#'   image = "https://example.com/jane.jpg",
#'   footer = "Website: janesmith.com"
#' )
#' }
card <- function(content, title = NULL, image = NULL, image_alt = NULL,
                footer = NULL, class = NULL, style = NULL) {

  # Start building the card
  card_classes <- c("card", class)
  card_style <- style

  # Create the card structure
  card_div <- htmltools::div(
    class = paste(card_classes, collapse = " "),
    style = card_style
  )

  # Add image if provided
  if (!is.null(image)) {
    image_div <- htmltools::div(
      class = "card-img-top",
      htmltools::img(
        src = image,
        alt = image_alt %||% "",
        class = "img-fluid",
        style = "width: 100%; height: auto;"
      )
    )
    card_div <- htmltools::tagAppendChild(card_div, image_div)
  }

  # Create card body
  card_body <- htmltools::div(class = "card-body")

  # Add title if provided
  if (!is.null(title)) {
    title_div <- htmltools::div(
      class = "card-title",
      htmltools::h5(title)
    )
    card_body <- htmltools::tagAppendChild(card_body, title_div)
  }

  # Add content
  content_div <- htmltools::div(
    class = "card-text",
    content
  )
  card_body <- htmltools::tagAppendChild(card_body, content_div)

  # Add card body to card
  card_div <- htmltools::tagAppendChild(card_div, card_body)

  # Add footer if provided
  if (!is.null(footer)) {
    footer_div <- htmltools::div(
      class = "card-footer text-muted",
      footer
    )
    card_div <- htmltools::tagAppendChild(card_div, footer_div)
  }

  return(card_div)
}

#' Display cards in a Bootstrap row
#'
#' Helper function to display multiple cards in a responsive Bootstrap row layout.
#'
#' @param ... Card objects to display
#' @param cols Number of columns per row (default: 2)
#' @param class Additional CSS classes for the row
#' @return HTML div element with Bootstrap row classes containing the cards
#' @export
#' @examples
#' \dontrun{
#' # Display two cards in a row
#' card_row(card1, card2)
#'
#' # Display three cards in a row (3 columns)
#' card_row(card1, card2, card3, cols = 3)
#' }
card_row <- function(..., cols = 2, class = NULL) {
  cards <- list(...)

  # Calculate Bootstrap column class
  col_class <- paste0("col-md-", 12 %/% cols)

  # Create row with cards
  row_div <- htmltools::div(
    class = paste(c("row", class), collapse = " "),
    lapply(cards, function(card) {
      htmltools::div(class = col_class, card)
    })
  )

  return(row_div)
}

#' Create multi-line markdown text content
#'
#' Helper function to create readable multi-line markdown text content for pages.
#' Automatically handles line breaks and formatting for better readability.
#'
#' @param ... Text content as separate arguments or character vectors
#' @param sep Separator to use when joining text (default: "\\n" for newlines). Use "" for no separator.
#' @return Single character string with proper line breaks
#' @export
#' @examples
#' \dontrun{
#' # Method 1: Separate arguments (default: newlines between)
#' text_content <- md_text(
#'   "# Welcome",
#'   "",
#'   "This is a multi-line text block.",
#'   "",
#'   "## Features",
#'   "- Feature 1",
#'   "- Feature 2"
#' )
#'
#' # Method 2: Character vectors
#' lines <- c("# About", "", "This is about our study.")
#' text_content <- md_text(lines)
#'
#' # Method 3: Combine without newlines
#' combined <- md_text(text1, text2, text3, sep = "")
#'
#' # Use in add_page
#' add_page("About", text = text_content)
#' }
md_text <- function(..., sep = "\n") {
  # Combine all arguments into a single character vector
  args <- list(...)
  content <- character(0)

  for (arg in args) {
    if (is.character(arg)) {
      content <- c(content, arg)
    } else {
      content <- c(content, as.character(arg))
    }
  }

  # Join with specified separator (default: newlines)
  paste(content, collapse = sep)
}

#' Create text content from a character vector
#'
#' Alternative helper for creating text content from existing character vectors.
#'
#' @param lines Character vector of text lines
#' @return Single character string with proper line breaks
#' @export
#' @examples
#' \dontrun{
#' lines <- c("# Title", "", "Content here")
#' text_content <- text_lines(lines)
#' add_page("Page", text = text_content)
#' }
text_lines <- function(lines) {
  paste(lines, collapse = "\n")
}

# NOTE: add_text() is now in R/content_collection.R for pipeable syntax
# Keeping this comment for reference

# NOTE: add_image() is now in R/content_collection.R for pipeable syntax
# Keeping this comment for reference


