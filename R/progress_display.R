# =================================================================
# progress_display
# =================================================================


#' Show custom progress message
#'
#' @param msg Message to display
#' @param icon Emoji or symbol to prefix
#' @param show_progress Whether to show progress
#' @keywords internal
.progress_msg <- function(msg, icon = "▪", show_progress = TRUE) {
  if (show_progress) {
    cat(icon, msg, "\n")
  }
}

#' Show custom progress step
#'
#' @param msg Step message
#' @param elapsed Optional elapsed time in seconds
#' @param show_progress Whether to show progress


#' Show custom progress step
#'
#' @param msg Step message
#' @param elapsed Optional elapsed time in seconds
#' @param show_progress Whether to show progress
#' @keywords internal
.progress_step <- function(msg, elapsed = NULL, show_progress = TRUE, is_last = FALSE, use_page_style = FALSE) {
  if (show_progress) {
    time_str <- if (!is.null(elapsed)) {
      if (elapsed < 1) {
        sprintf("  (%.0f ms)", elapsed * 1000)
      } else {
        sprintf("  (%.0f ms)", elapsed * 1000)
      }
    } else {
      ""
    }
    
    if (use_page_style) {
      # Use print method style for pages
      prefix <- if (is_last) "║ └─ 📄 " else "║ ├─ 📄 "
      cat(prefix, msg, time_str, "\n", sep = "")
    } else {
      # Use regular style for setup/config steps
      cat("  ✓", msg, time_str, "\n")
    }
  }
}

#' Show progress header
#'
#' @param title Header title
#' @param show_progress Whether to show progress


#' Show progress header
#'
#' @param title Header title
#' @param show_progress Whether to show progress
#' @keywords internal
.progress_header <- function(title, show_progress = TRUE) {
  if (show_progress) {
    cat("\n")
    cat("╔═══════════════════════════════════════════════════╗\n")
    cat("║  ", title, sprintf("%*s", max(0, 45 - nchar(title)), ""), "║\n")
    cat("╚═══════════════════════════════════════════════════╝\n")
  }
}

#' Show progress section
#'
#' @param title Section title
#' @param show_progress Whether to show progress


#' Show progress section
#'
#' @param title Section title
#' @param show_progress Whether to show progress
#' @keywords internal
.progress_section <- function(title, show_progress = TRUE) {
  if (show_progress) {
    cat("\n")
    cat("┌─", title, "\n")
  }
}

#' Show progress bar
#'
#' @param current Current step
#' @param total Total steps
#' @param label Optional label
#' @param show_progress Whether to show progress


#' Show progress bar
#'
#' @param current Current step
#' @param total Total steps
#' @param label Optional label
#' @param show_progress Whether to show progress
#' @keywords internal
.progress_bar <- function(current, total, label = "", show_progress = TRUE) {
  if (show_progress) {
    pct <- round((current / total) * 100)
    filled <- round(pct / 5)  # 20 chars total
    empty <- 20 - filled
    
    bar <- paste0(
      "[",
      paste(rep("█", filled), collapse = ""),
      paste(rep("░", empty), collapse = ""),
      "] ",
      sprintf("%3d%%", pct),
      if (nzchar(label)) paste0(" - ", label) else ""
    )
    
    cat("\r", bar)
    if (current == total) cat("\n")
  }
}

# ===================================================================
# Dashboard Generation and Rendering
# ===================================================================

#' Generate all dashboard files
#'
#' Writes out all .qmd files, _quarto.yml, and optionally renders the dashboard
#' to HTML using Quarto. Supports incremental builds to skip unchanged pages and
#' preview mode to generate only specific pages.
#'
#' @param proj A dashboard_project object
#' @param render Whether to render to HTML (requires Quarto CLI)
#' @param open How to open the result: "browser", "viewer", or FALSE
#' @param incremental Whether to use incremental builds (default: FALSE). When TRUE, skips 
#'   regenerating QMD files for unchanged pages and skips Quarto rendering if nothing changed.
#'   Uses MD5 hashing to detect changes.
#' @param preview Optional character vector of page names to generate. When specified, only
#'   the listed pages will be generated, skipping all others. Useful for quick testing of
#'   specific pages without waiting for the entire dashboard to generate. Page names are
#'   case-insensitive. If a page name doesn't exist, the function will suggest alternatives
#'   based on typo detection. Default: NULL (generates all pages).
#' @param show_progress Whether to display custom progress indicators (default: TRUE). When
#'   TRUE, shows a beautiful progress display with timing information, progress bars, and
#'   visual indicators for each generation stage. Set to FALSE for minimal output.
#' @param quiet Whether to suppress all output (default: FALSE). When TRUE, completely
#'   silences all messages, progress indicators, and Quarto rendering output. Useful for
#'   scripts and automated workflows. Overrides show_progress.
#' @return Invisibly returns the project object with build_info attached
#' @export
#' @examples
#' \dontrun{
#' # Generate and render dashboard
#' dashboard %>% generate_dashboard(render = TRUE, open = "browser")
#' 
#' # Generate without rendering (faster for quick iterations)
#' dashboard %>% generate_dashboard(render = FALSE)
#' 
#' # Incremental builds (skip unchanged pages)
#' dashboard %>% generate_dashboard(render = TRUE, incremental = TRUE)
#' 
#' # Preview specific page
#' dashboard %>% generate_dashboard(preview = "Analysis")
#' 
#' # Quiet mode for scripts
#' dashboard %>% generate_dashboard(render = FALSE, quiet = TRUE)

