# --------------------------------------------------------------------------
# Value Box Rendering Functions
# --------------------------------------------------------------------------

# Convert Quarto iconify shortcodes to <iconify-icon> HTML elements.
# e.g. "{{< iconify ph smiley >}}" -> <iconify-icon icon="ph:smiley" ...>
.resolve_iconify_logo <- function(logo_text, style = "font-size: 3rem; opacity: 0.3;") {
  if (is.null(logo_text)) return(NULL)
  m <- regmatches(logo_text, regexec("\\{\\{<\\s*iconify\\s+(\\S+)\\s+(\\S+)\\s*>\\}\\}", logo_text))[[1]]
  if (length(m) == 3) {
    icon_name <- paste0(m[2], ":", m[3])
    return(htmltools::div(
      style = style,
      htmltools::HTML(sprintf('<iconify-icon icon="%s"></iconify-icon>', htmltools::htmlEscape(icon_name)))
    ))
  }
  NULL
}

#' Render a single value box
#'
#' @param title Box title (small text above value)
#' @param value Main value to display (large text)
#' @param bg_color Background color (hex code), default "#2c3e50"
#' @param logo_url Optional URL or path to logo image
#' @param logo_text Optional text to display as logo (if no logo_url)
#' @param aria_label Optional ARIA label for accessibility.
#' @return An htmltools tag object.
#' @export
render_value_box <- function(title, value, bg_color = "#2c3e50", logo_url = NULL, logo_text = NULL, aria_label = NULL) {
  # Determine logo element
  logo_el <- if (!is.null(logo_url)) {
    htmltools::tags$img(
      src = logo_url,
      style = "width: 80px; height: 80px; object-fit: contain;"
    )
  } else if (!is.null(logo_text)) {
    .resolve_iconify_logo(logo_text, style = "font-size: 3rem; font-weight: 700; opacity: 0.3;") %||%
      htmltools::div(style = "font-size: 3rem; font-weight: 700; opacity: 0.3;", logo_text)
  } else {
    htmltools::div(style = "font-size: 3rem; opacity: 0.3;", "\U0001f4ca")
  }

  # ARIA attributes for accessibility
  aria_args <- list()
  if (!is.null(aria_label) && nzchar(aria_label)) {
    aria_args <- list(role = "region", `aria-label` = aria_label)
  }

  box_style <- paste0(
    "background: ", bg_color, "; ",
    "border-radius: 12px; ",
    "padding: 2rem; ",
    "color: white; ",
    "box-shadow: 0 4px 6px rgba(0,0,0,0.1); ",
    "transition: transform 0.3s ease, box-shadow 0.3s ease; ",
    "display: flex; ",
    "align-items: center; ",
    "gap: 1.5rem; ",
    "min-width: 300px; ",
    "position: relative; ",
    "overflow: hidden;"
  )

  do.call(htmltools::div, c(
    list(class = "custom-value-box", style = box_style),
    aria_args,
    list(
      htmltools::div(
        style = "flex-shrink: 0; display: flex; align-items: center; justify-content: center; width: 80px;",
        logo_el
      ),
      htmltools::div(style = "flex: 1;",
        htmltools::div(
          style = "font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.05em; opacity: 0.9; margin-bottom: 0.5rem; font-weight: 600;",
          title
        ),
        htmltools::div(
          style = "font-size: 1.75rem; font-weight: 800; letter-spacing: -0.02em; white-space: nowrap;",
          value
        )
      )
    )
  ))
}

#' Render a row of value boxes
#'
#' @param boxes List of value box specifications, each containing title, value, bg_color, logo_url, logo_text
#' @return An htmltools tag object.
#' @export
render_value_box_row <- function(boxes) {
  box_tags <- lapply(boxes, function(box) {
    # Determine logo element
    logo_el <- if (!is.null(box$logo_url)) {
      htmltools::tags$img(
        src = box$logo_url,
        style = "width: 80px; height: 80px; object-fit: contain;"
      )
    } else if (!is.null(box$logo_text)) {
      .resolve_iconify_logo(box$logo_text, style = "font-size: 3rem; font-weight: 700; opacity: 0.3;") %||%
        htmltools::div(style = "font-size: 3rem; font-weight: 700; opacity: 0.3;", box$logo_text)
    } else {
      htmltools::div(style = "font-size: 3rem; opacity: 0.3;", "\U0001f4ca")
    }

    htmltools::div(style = "flex: 1; min-width: 300px;",
      htmltools::div(
        class = "custom-value-box",
        style = paste0(
          "background: ", box$bg_color, "; ",
          "border-radius: 12px; ",
          "padding: 2rem; ",
          "color: white; ",
          "box-shadow: 0 4px 6px rgba(0,0,0,0.1); ",
          "transition: transform 0.3s ease, box-shadow 0.3s ease; ",
          "display: flex; ",
          "align-items: center; ",
          "gap: 1.5rem; ",
          "position: relative; ",
          "overflow: hidden;"
        ),
        htmltools::div(
          style = "flex-shrink: 0; display: flex; align-items: center; justify-content: center; width: 80px;",
          logo_el
        ),
        htmltools::div(style = "flex: 1;",
          htmltools::div(
            style = "font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.05em; opacity: 0.9; margin-bottom: 0.5rem; font-weight: 600;",
            box$title
          ),
          htmltools::div(
            style = "font-size: 1.75rem; font-weight: 800; letter-spacing: -0.02em; white-space: nowrap;",
            box$value
          )
        )
      )
    )
  })

  do.call(htmltools::div, c(
    list(style = "display: flex; gap: 1.5rem; flex-wrap: wrap; margin-bottom: 2rem;"),
    box_tags
  ))
}
