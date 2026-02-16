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
                        value_prefix = NULL, value_suffix = NULL,
                        border_radius = NULL,
                        subtitle = NULL, aria_label = NULL) {
  icon_el <- if (!is.null(icon)) {
    htmltools::HTML(paste0('<iconify-icon icon="', htmltools::htmlEscape(icon),
                           '" style="font-size: 2em;"></iconify-icon>'))
  }

  # Build combined style string
  styles <- character(0)
  if (!is.null(color)) {
    styles <- c(styles, paste0("border-left: 4px solid ", color, ";"))
  }
  if (!is.null(bg_color)) {
    styles <- c(styles, paste0("background-color: ", bg_color, ";"))
  }
  if (!is.null(text_color)) {
    styles <- c(styles, paste0("color: ", text_color, ";"))
  }
  if (!is.null(border_radius)) {
    styles <- c(styles, paste0("border-radius: ", border_radius, ";"))
  }
  combined_style <- if (length(styles) > 0) paste(styles, collapse = " ") else NULL

  # Display value with optional prefix/suffix
  display_value <- paste0(value_prefix %||% "", value, value_suffix %||% "")

  # When text_color is set, drop text-muted so the color inherits properly
  title_class <- if (!is.null(text_color)) "card-subtitle mb-2" else "card-subtitle mb-2 text-muted"
  subtitle_class <- if (!is.null(text_color)) "small" else "text-muted small"

  subtitle_el <- if (!is.null(subtitle)) {
    htmltools::tags$p(class = subtitle_class, subtitle)
  }

  aria_args <- list()
  if (!is.null(aria_label) && nzchar(aria_label)) {
    aria_args <- list(role = "region", `aria-label` = aria_label)
  }

  # Icon wrapper: use text_color inline style if set, otherwise text-primary class
  icon_wrapper <- if (!is.null(text_color)) {
    htmltools::div(style = paste0("color: ", text_color, ";"), icon_el)
  } else {
    htmltools::div(class = "text-primary", icon_el)
  }

  do.call(htmltools::div, c(
    list(class = "card mb-3", style = combined_style),
    aria_args,
    list(
      htmltools::div(class = "card-body",
        htmltools::div(class = "d-flex justify-content-between align-items-start",
          htmltools::div(
            htmltools::tags$h6(class = title_class, title),
            htmltools::tags$h2(class = "card-title mb-1", display_value),
            subtitle_el
          ),
          icon_wrapper
        )
      )
    )
  ))
}
