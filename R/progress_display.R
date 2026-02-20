# =================================================================
# Progress Display Utilities
# =================================================================
#
# Pretty-printed progress output for the dashboard build pipeline.
# All functions accept a `show_progress` flag so progress output can
# be silenced when dashboardr is called programmatically.
#
# Visual hierarchy (from broadest to narrowest):
#   .progress_header()   — top-level banner (double-line box)
#   .progress_section()  — named section heading
#   .progress_step()     — individual step with optional elapsed time
#   .progress_bar()      — percentage bar for multi-step operations
#   .progress_msg()      — simple one-line status message
#
# Unicode box-drawing characters are used throughout:
#   Header:  ╔═══╗ / ╚═══╝   Section: ┌─   Step: ✓ / ║ ├─ / ║ └─
#   Bar:     █ (filled) / ░ (empty)
#
# Called from: dashboard_generation.R
# =================================================================

#' Print a simple progress message
#'
#' @param msg  Character message to display.
#' @param icon Prefix symbol (default: small black square).
#' @param show_progress Logical; if FALSE, output is suppressed.
#' @keywords internal
.progress_msg <- function(msg, icon = "\u25aa", show_progress = TRUE) {
  if (show_progress) {
    cat(icon, msg, "\n")
  }
}

#' Print a progress step (with optional timing)
#'
#' Two visual styles are available:
#' - **Default** (setup/config steps): indented with a checkmark.
#' - **Page style** (`use_page_style = TRUE`): tree-drawing characters
#'   matching the print method for dashboard_project objects.
#'
#' @param msg           Step description.
#' @param elapsed       Optional elapsed time in seconds (shown as ms).
#' @param show_progress Logical; if FALSE, output is suppressed.
#' @param is_last       If TRUE and `use_page_style`, draws a └─ instead of ├─.
#' @param use_page_style If TRUE, uses the page-tree visual style.
#' @keywords internal
.progress_step <- function(msg, elapsed = NULL, show_progress = TRUE, is_last = FALSE, use_page_style = FALSE) {
  if (show_progress) {
    # Format elapsed time (always shown in milliseconds for consistency)
    time_str <- if (!is.null(elapsed)) {
      sprintf("  (%.0f ms)", elapsed * 1000)
    } else {
      ""
    }

    if (use_page_style) {
      # Tree-style prefix: ║ ├─ 📄 (middle) or ║ └─ 📄 (last)
      prefix <- if (is_last) "\u2551 \u2514\u2500 \U0001f4c4 " else "\u2551 \u251c\u2500 \U0001f4c4 "
      cat(prefix, msg, time_str, "\n", sep = "")
    } else {
      # Simple checkmark prefix for setup steps
      cat("  \u2713", msg, time_str, "\n")
    }
  }
}

#' Print a section header (double-line box)
#'
#' Draws a prominent banner used at the top of major build phases:
#' ```
#' ╔═══════════════════════════════════════════════════╗
#' ║  Building Dashboard                               ║
#' ╚═══════════════════════════════════════════════════╝
#' ```
#'
#' @param title Header text.
#' @param show_progress Logical; if FALSE, output is suppressed.
#' @keywords internal
.progress_header <- function(title, show_progress = TRUE) {
  if (show_progress) {
    cat("\n")
    cat("\u2554\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2557\n")
    cat("\u2551  ", title, sprintf("%*s", max(0, 45 - nchar(title)), ""), "\u2551\n")
    cat("\u255a\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u255d\n")
  }
}

#' Print a named section divider
#'
#' Lighter than a header — used to separate logical groups of steps:
#' ```
#' ┌─ Rendering pages
#' ```
#'
#' @param title Section name.
#' @param show_progress Logical; if FALSE, output is suppressed.
#' @keywords internal
.progress_section <- function(title, show_progress = TRUE) {
  if (show_progress) {
    cat("\n")
    cat("\u250c\u2500", title, "\n")
  }
}

#' Print an in-place progress bar
#'
#' Overwrites the current line with `\r` to create an animated bar:
#' ```
#' [████████████░░░░░░░░]  60% - Rendering page 3/5
#' ```
#'
#' @param current Current step number (1-based).
#' @param total   Total number of steps.
#' @param label   Optional label shown after the percentage.
#' @param show_progress Logical; if FALSE, output is suppressed.
#' @keywords internal
.progress_bar <- function(current, total, label = "", show_progress = TRUE) {
  if (show_progress) {
    pct <- round((current / total) * 100)
    filled <- round(pct / 5)  # 20 chars total width
    empty <- 20 - filled

    bar <- paste0(
      "[",
      paste(rep("\u2588", filled), collapse = ""),
      paste(rep("\u2591", empty), collapse = ""),
      "] ",
      sprintf("%3d%%", pct),
      if (nzchar(label)) paste0(" - ", label) else ""
    )

    cat("\r", bar)
    if (current == total) cat("\n")  # newline when complete
  }
}
