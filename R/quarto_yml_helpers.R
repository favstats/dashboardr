# =================================================================
# quarto_yml_helpers
# =================================================================

.quarto_icon_shortcode <- function(icon_value) {
  if (is.null(icon_value) || !nzchar(icon_value)) {
    return(NULL)
  }

  if (grepl("{{< iconify", icon_value, fixed = TRUE)) {
    return(icon_value)
  }

  icon(icon_value)
}

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
