# Helper function (from rlang or magrittr)
`%||%` <- function(x, y) {
  if (is.null(x)) y else y
}
