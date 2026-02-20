# =================================================================
# Content Block Type Registry
# =================================================================
#
# Single source of truth for every content block type that dashboardr
# can render. When a new block type is added to the package, it must
# be registered here so that:
#
#   1. `.is_content_block_type()` recognises it during collection
#      building (content_collection.R, viz_collection.R).
#   2. `.required_content_fields()` can enforce mandatory fields
#      before the QMD generation stage.
#   3. `.validate_content_block_for_generation()` catches
#      configuration errors early — before Quarto rendering.
#
# Block types fall into several families:
#   - **Text/Media**: text, image, video, iframe, code, html, quote
#   - **Layout**:     layout_column, layout_row, spacer, divider
#   - **Tables**:     gt, reactable, DT, table
#   - **Charts**:     hc (Highcharts), ggplot, widget
#   - **UI**:         badge, metric, value_box, value_box_row,
#                     sparkline_card, sparkline_card_row,
#                     input, input_row, modal, accordion, card,
#                     callout
#
# Called from: content_collection.R, page_generation.R
# =================================================================

#' List all recognised content block types
#'
#' @return Character vector of type strings.
#' @keywords internal
.content_block_types <- function() {
  c(
    # Text & media
    "text", "image", "video", "callout", "divider", "code", "spacer",
    # Tables
    "gt", "reactable", "table", "DT",
    # Embeds
    "iframe",
    # UI components
    "accordion", "card", "html", "quote", "badge", "metric",
    "value_box", "value_box_row",
    "sparkline_card", "sparkline_card_row",
    # Charts & widgets
    "hc", "widget", "ggplot",
    # Layout wrappers
    "layout_column", "layout_row",
    # Inputs & interaction
    "input", "input_row", "modal"
  )
}

#' Check whether a string is a known content block type
#'
#' @param type Character scalar to check.
#' @return Logical.
#' @keywords internal
.is_content_block_type <- function(type) {
  isTRUE(!is.null(type) && type %in% .content_block_types())
}

#' Return the required fields for a given block type
#'
#' Most block types have no mandatory fields beyond `type` itself.
#' Media-oriented types need a source path or URL.
#'
#' Pipe-separated alternatives (e.g. `"url|src"`) mean that at least
#' one of the listed fields must be present.
#'
#' @param type Character scalar — the block type.
#' @return Character vector of required field names (possibly empty).
#' @keywords internal
.required_content_fields <- function(type) {
  switch(type,
    "image" = c("src"),
    # `video` and `iframe` historically accept either `url` or `src`
    "video" = c("url|src"),
    "iframe" = c("url|src"),
    "code" = c("code"),
    character(0)
  )
}

#' Validate a content block before QMD generation
#'
#' Checks that all required fields are present and non-empty. Stops
#' with an informative error message on failure. Silently returns for
#' unknown or NULL blocks so callers don't need to pre-filter.
#'
#' @param block    A content block list (must have a `type` element).
#' @param context  Human-readable label for error messages (e.g.
#'   `"page 'Home', block 3"`).
#' @return Invisible NULL.
#' @keywords internal
.validate_content_block_for_generation <- function(block, context = "content block") {
  if (is.null(block) || !is.list(block)) return(invisible(NULL))

  block_type <- block$type %||% ""
  if (!nzchar(block_type) || !.is_content_block_type(block_type)) {
    return(invisible(NULL))
  }

  required <- .required_content_fields(block_type)
  if (length(required) == 0) {
    return(invisible(NULL))
  }

  # For each required field (which may be "url|src" alternatives),
  # check that at least one alternative is present and non-empty.
  missing_fields <- required[vapply(required, function(field) {
    field_options <- strsplit(field, "\\|", fixed = FALSE)[[1]]
    option_ok <- vapply(field_options, function(opt) {
      val <- block[[opt]]
      !is.null(val) && !(is.character(val) && !nzchar(val))
    }, logical(1))
    !any(option_ok)
  }, logical(1))]

  if (length(missing_fields) > 0) {
    stop(
      paste0(
        "Invalid ", block_type, " block in ", context,
        ": missing required field(s): ", paste(missing_fields, collapse = ", "),
        "."
      ),
      call. = FALSE
    )
  }

  invisible(NULL)
}
