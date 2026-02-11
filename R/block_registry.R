# =================================================================
# block_registry
# =================================================================

# Single source of truth for content block type classification.
.content_block_types <- function() {
  c(
    "text", "image", "video", "callout", "divider", "code", "spacer",
    "gt", "reactable", "table", "DT", "iframe", "accordion", "card",
    "html", "quote", "badge", "metric", "value_box", "value_box_row",
    "sparkline_card", "sparkline_card_row",
    "hc", "widget", "ggplot", "layout_column", "layout_row", "input", "input_row", "modal"
  )
}

.is_content_block_type <- function(type) {
  isTRUE(!is.null(type) && type %in% .content_block_types())
}

.required_content_fields <- function(type) {
  switch(type,
    "image" = c("src"),
    # Historical compatibility: some builders persist `url`, others `src`.
    "video" = c("url|src"),
    "iframe" = c("url|src"),
    "code" = c("code"),
    character(0)
  )
}

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
