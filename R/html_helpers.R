# --------------------------------------------------------------------------
# HTML Helper Functions
# Small htmltools-based helpers for generating clean R calls in QMD output
# instead of raw HTML strings.
# --------------------------------------------------------------------------

#' Create a vertical spacer
#'
#' Returns an htmltools div with the specified height. Use in dashboards
#' to add vertical spacing between content blocks.
#'
#' @param height CSS height value (e.g. "1rem", "20px"). Default "1rem".
#' @return An htmltools tag object.
#' @export
html_spacer <- function(height = "1rem") {
  htmltools::div(style = paste0("height: ", height, ";"))
}

#' Create a horizontal divider
#'
#' Returns a styled \code{<hr>} tag. For the default style, prefer
#' markdown \code{---} instead.
#'
#' @param style Divider style: "thick", "dashed", or "dotted".
#' @return An htmltools tag object.
#' @export
html_divider <- function(style = "thick") {
  css <- switch(style,
    "thick"  = "border: 3px solid #333;",
    "dashed" = "border-top: 2px dashed #ccc;",
    "dotted" = "border-top: 2px dotted #ccc;",
    "border: 3px solid #333;"
  )
  htmltools::tags$hr(style = css)
}

#' Create a Bootstrap-style card
#'
#' @param body Card body content (character string).
#' @param title Optional card header title.
#' @return An htmltools tag object.
#' @export
html_card <- function(body, title = NULL) {
  header <- if (!is.null(title) && nzchar(title)) {
    htmltools::div(class = "card-header", title)
  }
  htmltools::div(class = "card",
    header,
    htmltools::div(class = "card-body", htmltools::HTML(body))
  )
}

#' Create a collapsible accordion section
#'
#' @param body Accordion body content (character string).
#' @param title Summary/header text. Default "Details".
#' @return An htmltools tag object.
#' @export
html_accordion <- function(body, title = "Details") {
  htmltools::tags$details(
    htmltools::tags$summary(title),
    htmltools::HTML(body)
  )
}

#' Create an iframe embed
#'
#' @param url URL to embed.
#' @param height CSS height value. Default "500px".
#' @param width CSS width value. Default "100%".
#' @param style Optional additional CSS styles.
#' @return An htmltools tag object.
#' @export
html_iframe <- function(url, height = "500px", width = "100%", style = NULL) {
  style_parts <- c(
    paste0("width: ", width, ";"),
    paste0("height: ", height, ";")
  )
  if (!is.null(style) && nzchar(style)) {
    style_parts <- c(style_parts, style)
  }
  htmltools::tags$iframe(
    src = url,
    frameborder = "0",
    allowfullscreen = NA,
    style = paste(style_parts, collapse = " ")
  )
}

#' Create a status badge
#'
#' @param text Badge text.
#' @param color Badge color class: "success", "warning", "danger", "info",
#'   "primary" (default), or "secondary".
#' @return An htmltools tag object.
#' @export
html_badge <- function(text, color = "primary") {
  color_class <- switch(color,
    "success"   = "badge-success",
    "warning"   = "badge-warning",
    "danger"    = "badge-danger",
    "info"      = "badge-info",
    "primary"   = "badge-primary",
    "secondary" = "badge-secondary",
    "badge-primary"
  )
  htmltools::tags$span(class = paste("badge", color_class), text)
}

#' Create a metric card
#'
#' @param value The metric value to display.
#' @param title Metric title.
#' @param icon Optional icon name (e.g. "mdi:account"). Uses the iconify
#'   web component.
#' @param color Optional accent color for left border.
#' @param bg_color Optional background color (e.g. "#3498db").
#' @param text_color Optional text color applied to the card (e.g. "#ffffff").
#'   Also sets the icon color instead of the default \code{text-primary} class.
#' @param value_prefix Optional string prepended to the displayed value.
#' @param value_suffix Optional string appended to the displayed value.
#' @param border_radius Optional CSS border-radius (e.g. "12px", "0").
#' @param subtitle Optional subtitle text.
#' @param aria_label Optional ARIA label for accessibility.
#' @return An htmltools tag object.
#' @export
html_metric <- function(value, title, icon = NULL, color = NULL,
                        bg_color = NULL, text_color = NULL,
                        gradient = TRUE, gradient_intensity = 0.45,
                        value_prefix = NULL, value_suffix = NULL,
                        border_radius = NULL,
                        subtitle = NULL, aria_label = NULL) {
  # Display value with optional prefix/suffix
  display_value <- paste0(value_prefix %||% "", value, value_suffix %||% "")

  # gradient_intensity: 0 = no shift (flat), 1 = maximum shift.
  # Controls how far the second stop lightens/darkens from the base color.
  intensity <- max(0, min(1, gradient_intensity))

  # Determine background based on gradient + color arguments:
  #   gradient = TRUE  + no color -> default purple gradient, white text
  #   gradient = TRUE  + color    -> auto-gradient from that color, white text
  #   gradient = "red"            -> auto-gradient from "red", white text
  #   gradient = FALSE + color    -> solid color background
  #   gradient = FALSE + no color -> plain light card, dark text
  #   bg_color always overrides everything (explicit background)
  #
  # For auto-gradients: dark colors go light->dark, light colors go base->darker.
  has_gradient <- !isFALSE(gradient)

  # Resolve the base color for gradient generation
  grad_color <- if (is.character(gradient)) gradient else color

  if (has_gradient && !is.null(grad_color)) {
    # Generate gradient from the base color
    base_rgb <- tryCatch(grDevices::col2rgb(grad_color)[, 1],
                         error = function(e) NULL)
    if (!is.null(base_rgb)) {
      luminance <- 0.299 * base_rgb[1] + 0.587 * base_rgb[2] + 0.114 * base_rgb[3]
      if (luminance <= 140) {
        # Dark color: gradient from lighter version -> base
        light_hex <- sprintf("#%02x%02x%02x",
                             min(255, round(base_rgb[1] + (255 - base_rgb[1]) * intensity)),
                             min(255, round(base_rgb[2] + (255 - base_rgb[2]) * intensity)),
                             min(255, round(base_rgb[3] + (255 - base_rgb[3]) * intensity)))
        base_hex <- sprintf("#%02x%02x%02x", base_rgb[1], base_rgb[2], base_rgb[3])
        default_bg <- paste0("linear-gradient(135deg, ", light_hex, " 0%, ", base_hex, " 100%)")
      } else {
        # Light color: gradient from base -> darker version
        base_hex <- sprintf("#%02x%02x%02x", base_rgb[1], base_rgb[2], base_rgb[3])
        darken <- 1 - intensity
        dark_hex <- sprintf("#%02x%02x%02x",
                            round(base_rgb[1] * darken),
                            round(base_rgb[2] * darken),
                            round(base_rgb[3] * darken))
        default_bg <- paste0("linear-gradient(135deg, ", base_hex, " 0%, ", dark_hex, " 100%)")
      }
    } else {
      default_bg <- grad_color
    }
  } else if (has_gradient) {
    # gradient = TRUE, no color specified -> default purple gradient
    default_bg <- "linear-gradient(135deg, #667eea 0%, #764ba2 100%)"
  } else if (!is.null(color)) {
    # gradient = FALSE, color specified -> solid color
    default_bg <- color
  } else {
    # gradient = FALSE, no color -> plain light card
    default_bg <- "#f8f9fa"
  }

  bg <- bg_color %||% default_bg
  fg <- text_color %||% if (has_gradient) "white" else "#212529"
  radius <- border_radius %||% "12px"

  # Build container style
  container_style <- paste0(
    "background: ", bg, "; ",
    "color: ", fg, "; ",
    "padding: 20px; ",
    "border-radius: ", radius, "; ",
    "text-align: center; ",
    "box-shadow: 0 4px 15px rgba(0,0,0,0.1);"
  )

  # Icon element
  icon_el <- if (!is.null(icon)) {
    htmltools::HTML(paste0(
      '<iconify-icon icon="', htmltools::htmlEscape(icon),
      '" style="font-size: 2em; margin-bottom: 10px;"></iconify-icon>'
    ))
  }

  # Subtitle element
  subtitle_el <- if (!is.null(subtitle)) {
    htmltools::div(style = "font-size: 0.85em; opacity: 0.7; margin-top: 5px;", subtitle)
  }

  aria_args <- list()
  if (!is.null(aria_label) && nzchar(aria_label)) {
    aria_args <- list(role = "region", `aria-label` = aria_label)
  }

  do.call(htmltools::div, c(
    list(class = "metric mb-3", style = container_style),
    aria_args,
    list(
      icon_el,
      htmltools::div(style = "font-size: 2.5em; font-weight: bold;", display_value),
      htmltools::div(style = "font-size: 1em; opacity: 0.9; margin-top: 5px;", title),
      subtitle_el
    )
  ))
}
