# =================================================================
# utils.R — tiny package-level utilities
# =================================================================
#
# NOTE ON `%||%`:
# The null-coalescing operator is defined in THREE places:
#   1. rlang::`%||%`   — imported via imports.R (authoritative)
#   2. utils_core.R    — local copy for internal helpers that load
#                        before rlang is attached
#   3. This file       — kept as a safety net
#
# All three must have identical semantics:
#   if x is NULL → return y, otherwise return x.
#
# If you ever need to change the operator, update ALL copies.
# =================================================================

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
