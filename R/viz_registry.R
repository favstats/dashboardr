# ===================================================================
# Viz Type Registry
# ===================================================================
# Single source of truth for mapping viz type names to function names.
# Follows the same pattern as R/block_registry.R.

#' Viz type registry
#'
#' Returns the canonical mapping from viz type names to their function names,
#' including aliases (e.g., "donut" -> "viz_pie").
#'
#' @return Named list where each element has `fn` (function name string).
#' @keywords internal
.viz_type_registry <- function() {
  list(
    bar        = list(fn = "viz_bar"),
    stackedbar = list(fn = "viz_stackedbar"),
    stackedbars = list(fn = "viz_stackedbars"),
    scatter    = list(fn = "viz_scatter"),
    heatmap    = list(fn = "viz_heatmap"),
    histogram  = list(fn = "viz_histogram"),
    density    = list(fn = "viz_density"),
    timeline   = list(fn = "viz_timeline"),
    treemap    = list(fn = "viz_treemap"),
    boxplot    = list(fn = "viz_boxplot"),
    map        = list(fn = "viz_map"),
    lollipop   = list(fn = "viz_lollipop"),
    funnel     = list(fn = "viz_funnel"),
    pie        = list(fn = "viz_pie"),
    waffle     = list(fn = "viz_waffle"),
    dumbbell   = list(fn = "viz_dumbbell"),
    gauge      = list(fn = "viz_gauge"),
    sankey     = list(fn = "viz_sankey"),
    # Aliases
    donut      = list(fn = "viz_pie"),
    pyramid    = list(fn = "viz_funnel")
  )
}

#' Look up viz function name from type
#'
#' @param type Character string, the viz type name (e.g., "bar", "donut").
#' @return Character string, the function name (e.g., "viz_bar").
#' @keywords internal
.viz_type_to_function <- function(type) {
  reg <- .viz_type_registry()
  if (!type %in% names(reg)) {
    available <- .available_viz_types()
    stop(sprintf(
      "Unknown viz type '%s'. Available types: %s",
      type, paste(available, collapse = ", ")
    ))
  }
  reg[[type]]$fn
}

#' List available viz types (excluding aliases)
#'
#' @return Character vector of canonical viz type names.
#' @keywords internal
.available_viz_types <- function() {
  aliases <- c("donut", "pyramid")
  setdiff(names(.viz_type_registry()), aliases)
}
