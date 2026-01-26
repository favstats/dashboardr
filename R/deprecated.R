#' @title Deprecated Visualization Functions
#' @description
#' These functions have been renamed to use the `viz_*` prefix for clarity.
#' Please use the new names:
#' - `create_histogram()` → `viz_histogram()`
#' - `create_bar()` → `viz_bar()`
#' - `create_stackedbar()` → `viz_stackedbar()`
#' - `create_stackedbars()` → `viz_stackedbars()`
#' - `create_timeline()` → `viz_timeline()`
#' - `create_heatmap()` → `viz_heatmap()`
#' - `create_scatter()` → `viz_scatter()`
#' - `create_map()` → `viz_map()`
#' - `create_treemap()` → `viz_treemap()`
#'
#' The old names will continue to work but are deprecated and will be
#' removed in a future version.
#'
#' @name deprecated-viz
#' @keywords internal
NULL

#' @rdname deprecated-viz
#' @export
create_histogram <- function(...) {

.Deprecated("viz_histogram", package = "dashboardr",
              msg = "create_histogram() is deprecated. Please use viz_histogram() instead.")
  viz_histogram(...)
}

#' @rdname deprecated-viz
#' @export
create_bar <- function(...) {
  .Deprecated("viz_bar", package = "dashboardr",
              msg = "create_bar() is deprecated. Please use viz_bar() instead.")
  viz_bar(...)
}

#' @rdname deprecated-viz
#' @export
create_stackedbar <- function(...) {
  .Deprecated("viz_stackedbar", package = "dashboardr",
              msg = "create_stackedbar() is deprecated. Please use viz_stackedbar() instead.")
  viz_stackedbar(...)
}

#' @rdname deprecated-viz
#' @export
create_stackedbars <- function(...) {
  .Deprecated("viz_stackedbars", package = "dashboardr",
              msg = "create_stackedbars() is deprecated. Please use viz_stackedbars() instead.")
  viz_stackedbars(...)
}

#' @rdname deprecated-viz
#' @export
create_timeline <- function(...) {
  .Deprecated("viz_timeline", package = "dashboardr",
              msg = "create_timeline() is deprecated. Please use viz_timeline() instead.")
  viz_timeline(...)
}

#' @rdname deprecated-viz
#' @export
create_heatmap <- function(...) {
  .Deprecated("viz_heatmap", package = "dashboardr",
              msg = "create_heatmap() is deprecated. Please use viz_heatmap() instead.")
  viz_heatmap(...)
}

#' @rdname deprecated-viz
#' @export
create_scatter <- function(...) {
  .Deprecated("viz_scatter", package = "dashboardr",
              msg = "create_scatter() is deprecated. Please use viz_scatter() instead.")
  viz_scatter(...)
}

#' @rdname deprecated-viz
#' @export
create_map <- function(...) {
  .Deprecated("viz_map", package = "dashboardr",
              msg = "create_map() is deprecated. Please use viz_map() instead.")
  viz_map(...)
}

#' @rdname deprecated-viz
#' @export
create_treemap <- function(...) {
  .Deprecated("viz_treemap", package = "dashboardr",
              msg = "create_treemap() is deprecated. Please use viz_treemap() instead.")
  viz_treemap(...)
}
