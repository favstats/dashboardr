#' Create a Styled Blockquote
#'
#' @description
#' Creates a custom-styled blockquote with customizable colors, borders, and styling.
#' Useful for highlighting questions, quotes, or important text in dashboards.
#'
#' @param text Character string. The text content to display in the blockquote.
#' @param preset Either a character string for built-in presets ("question", "info", 
#'   "warning", "success", "error", "note") OR a named list with custom styling parameters
#'   (e.g., list(border_color = "#0056b3", background_color = "#e3f2fd")).
#'   Default is NULL (uses default styling).
#' @param class_name Character string. CSS class name for the blockquote. Default is "custom-blockquote".
#' @param font_size Character string. Font size (e.g., "1em", "16px"). Default is "1em".
#' @param text_color Character string. Text color (hex, rgb, or named color). Default is "#333".
#' @param border_width Character string. Left border width (e.g., "5px", "3px"). Default is "5px".
#' @param border_color Character string. Left border color. Default is "#0056b3".
#' @param background_color Character string. Background color. Default is "#f0f8ff".
#' @param padding Character string. Padding inside the blockquote. Default is "10px 20px".
#' @param margin Character string. Margin around the blockquote. Default is "20px 0".
#' @param line_height Character string. Line height for text. Default is "1.6".
#' @param return_css Logical. If TRUE, returns only the CSS. If FALSE (default), returns HTML with inline CSS.
#' @param use_class Logical. If TRUE, returns HTML with class reference and separate CSS block.
#'   If FALSE (default), uses inline styles.
#'
#' @return If `use_class = FALSE`: HTML blockquote with inline styles.
#'   If `use_class = TRUE`: List with `html` and `css` elements.
#'   If `return_css = TRUE`: Only the CSS string.
#'
#' @examples
#' # Basic usage with defaults
#' create_blockquote("This is an important question about data quality.")
#'
#' # Using built-in presets (as strings)
#' create_blockquote("How do you rate our service?", preset = "question")
#' create_blockquote("Please check your input.", preset = "warning")
#' create_blockquote("Operation completed!", preset = "success")
#'
#' # Using custom presets (as lists) - pass directly!
#' algosoc_style <- list(
#'   border_color = "#0056b3",
#'   background_color = "#e3f2fd",
#'   text_color = "#1565c0"
#' )
#' create_blockquote("AlgoSoc question here", preset = algosoc_style)
#'
#' # Define multiple custom styles and reuse
#' survey_style <- list(border_color = "#6f42c1", background_color = "#f8f5ff")
#' important_style <- list(
#'   border_color = "#e74c3c",
#'   background_color = "#ffebee",
#'   border_width = "8px"
#' )
#'
#' create_blockquote("Survey question 1", preset = survey_style)
#' create_blockquote("Survey question 2", preset = survey_style)
#' create_blockquote("IMPORTANT!", preset = important_style)
#'
#' # Custom styling (overriding preset)
#' create_blockquote(
#'   "Warning: Please review the data before proceeding.",
#'   preset = "warning",
#'   border_width = "8px",  # Override preset border width
#'   font_size = "1.2em"     # Override preset font size
#' )
#'
#' # Fully custom (no preset)
#' create_blockquote(
#'   "How satisfied are you with our service?",
#'   border_color = "#6f42c1",
#'   background_color = "#f8f5ff",
#'   font_size = "1.1em",
#'   padding = "15px 25px"
#' )
#'
#' # Using class-based approach (for multiple blockquotes)
#' result <- create_blockquote(
#'   "Question 1: What is your opinion?",
#'   preset = "question",
#'   use_class = TRUE
#' )
#' # View the CSS component (an htmltools tag)
#' result$css
#' # View the HTML component
#' result$html
#'
#' @export
create_blockquote <- function(text,
                               preset = NULL,
                               class_name = "custom-blockquote",
                               font_size = "1em",
                               text_color = "#333",
                               border_width = "5px",
                               border_color = "#0056b3",
                               background_color = "#f0f8ff",
                               padding = "10px 20px",
                               margin = "20px 0",
                               line_height = "1.6",
                               return_css = FALSE,
                               use_class = FALSE) {
  
  # Apply preset if specified
  if (!is.null(preset)) {
    preset_values <- NULL
    
    # Check if preset is a string (built-in preset) or a list (custom preset)
    if (is.character(preset)) {
      # Built-in preset - look it up
      builtin_presets <- list(
        question = list(
          border_color = "#0056b3",
          background_color = "#f0f8ff",
          text_color = "#333",
          class_name = "question-text"
        ),
        info = list(
          border_color = "#17a2b8",
          background_color = "#d1ecf1",
          text_color = "#0c5460",
          class_name = "info-text"
        ),
        warning = list(
          border_color = "#ffc107",
          background_color = "#fff3cd",
          text_color = "#856404",
          class_name = "warning-text"
        ),
        success = list(
          border_color = "#28a745",
          background_color = "#d4edda",
          text_color = "#155724",
          class_name = "success-text"
        ),
        error = list(
          border_color = "#dc3545",
          background_color = "#f8d7da",
          text_color = "#721c24",
          class_name = "error-text"
        ),
        note = list(
          border_color = "#6c757d",
          background_color = "#e9ecef",
          text_color = "#383d41",
          class_name = "note-text"
        )
      )
      
      # Check if preset exists
      if (!preset %in% names(builtin_presets)) {
        available <- paste(names(builtin_presets), collapse = ", ")
        stop("Unknown preset: '", preset, "'\nAvailable built-in presets: ", available)
      }
      
      preset_values <- builtin_presets[[preset]]
      
    } else if (is.list(preset)) {
      # Custom preset passed directly as a list
      preset_values <- preset
      
    } else {
      stop("preset must be either a character string (built-in preset name) or a named list (custom styling)")
    }
    
    # Apply preset values only if user hasn't provided custom values
    # Check if each parameter was explicitly provided (not using default)
    call_args <- as.list(match.call())[-1]
    
    # Apply all available preset values
    if (!is.null(preset_values$border_color) && !"border_color" %in% names(call_args)) {
      border_color <- preset_values$border_color
    }
    if (!is.null(preset_values$background_color) && !"background_color" %in% names(call_args)) {
      background_color <- preset_values$background_color
    }
    if (!is.null(preset_values$text_color) && !"text_color" %in% names(call_args)) {
      text_color <- preset_values$text_color
    }
    if (!is.null(preset_values$class_name) && !"class_name" %in% names(call_args)) {
      class_name <- preset_values$class_name
    }
    if (!is.null(preset_values$font_size) && !"font_size" %in% names(call_args)) {
      font_size <- preset_values$font_size
    }
    if (!is.null(preset_values$border_width) && !"border_width" %in% names(call_args)) {
      border_width <- preset_values$border_width
    }
    if (!is.null(preset_values$padding) && !"padding" %in% names(call_args)) {
      padding <- preset_values$padding
    }
    if (!is.null(preset_values$margin) && !"margin" %in% names(call_args)) {
      margin <- preset_values$margin
    }
    if (!is.null(preset_values$line_height) && !"line_height" %in% names(call_args)) {
      line_height <- preset_values$line_height
    }
  }
  
  # Generate CSS
  css <- sprintf(
    "blockquote.%s {
  font-size: %s;
  color: %s;
  border-left: %s solid %s;
  background-color: %s;
  padding: %s;
  margin: %s;
  line-height: %s;
  position: relative;
}",
    class_name,
    font_size,
    text_color,
    border_width,
    border_color,
    background_color,
    padding,
    margin,
    line_height
  )
  
  # If only CSS is requested
  if (return_css) {
    return(css)
  }
  
  # Generate HTML
  if (use_class) {
    # Use class reference
    html <- sprintf('<blockquote class="%s">\n%s\n</blockquote>', class_name, text)
    
    # Return both HTML and CSS
    return(list(
      html = htmltools::HTML(html),
      css = htmltools::tags$style(htmltools::HTML(css))
    ))
  } else {
    # Use inline styles
    inline_style <- sprintf(
      "font-size: %s; color: %s; border-left: %s solid %s; background-color: %s; padding: %s; margin: %s; line-height: %s; position: relative;",
      font_size, text_color, border_width, border_color, 
      background_color, padding, margin, line_height
    )
    
    html <- sprintf('<blockquote style="%s">\n%s\n</blockquote>', inline_style, text)
    
    return(htmltools::HTML(html))
  }
}

