# =================================================================
# Quarto YAML Helpers
# =================================================================
#
# Small utilities used by quarto_yml.R when building the _quarto.yml
# configuration file. These handle Iconify icon shortcodes and
# navbar text formatting.
#
# Called from: quarto_yml.R
# =================================================================

#' Convert an icon identifier to an Iconify Quarto shortcode
#'
#' If the value already contains the `{{< iconify ...` shortcode syntax
#' it is returned as-is. Otherwise, it is passed through `icon()` which
#' converts `"collection:name"` format to the shortcode.
#'
#' @param icon_value Character string — either a shortcode or
#'   `"collection:name"` format (e.g. `"ph:users-three"`).
#' @return The Iconify shortcode string, or NULL if input is empty.
#' @keywords internal
.quarto_icon_shortcode <- function(icon_value) {
  if (is.null(icon_value) || !nzchar(icon_value)) {
    return(NULL)
  }

  # Already a shortcode? Return unchanged.
  if (grepl("{{< iconify", icon_value, fixed = TRUE)) {
    return(icon_value)
  }

  # Convert collection:name -> {{< iconify collection name >}}
  icon(icon_value)
}

#' Build a quoted navbar text string with optional icon prefix
#'
#' Used when generating YAML entries for navbar items. The result is
#' double-quoted so Quarto interprets the Iconify shortcode correctly.
#'
#' @param text       Display text for the navbar item.
#' @param icon_value Optional icon identifier (see `.quarto_icon_shortcode()`).
#' @return A double-quoted string suitable for `_quarto.yml`, e.g.
#'   `"{{< iconify ph users-three >}} My Page"`.
#' @keywords internal
.quarto_nav_text <- function(text, icon_value = NULL) {
  text <- text %||% ""
  icon_shortcode <- .quarto_icon_shortcode(icon_value)

  if (is.null(icon_shortcode)) {
    return(paste0('"', text, '"'))
  }

  if (!nzchar(text)) {
    return(paste0('"', icon_shortcode, '"'))
  }

  paste0('"', icon_shortcode, " ", text, '"')
}
