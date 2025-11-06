# =================================================================
# content_helpers - Unified content type checking
# =================================================================

#' Check if object is a content collection
#' 
#' @description
#' Internal helper to check if an object is a content collection.
#' This includes both viz_collection and content_collection classes
#' since they are always present together.
#' 
#' @param x Object to check
#' @return Logical indicating if x is a content collection
#' @keywords internal
is_content <- function(x) {
  inherits(x, "content_collection") || inherits(x, "viz_collection")
}

#' Check if object is a content block
#' 
#' @description
#' Internal helper to check if an object is a content block.
#' Content blocks represent individual pieces of content like text,
#' images, callouts, etc.
#' 
#' @param x Object to check
#' @return Logical indicating if x is a content block
#' @keywords internal
is_content_block <- function(x) {
  inherits(x, "content_block")
}

#' Check if object is any content type
#' 
#' @description
#' Internal helper to check if an object is any type of content,
#' including both content collections and individual content blocks.
#' 
#' @param x Object to check
#' @return Logical indicating if x is any content type
#' @keywords internal
is_any_content <- function(x) {
  is_content(x) || is_content_block(x)
}

