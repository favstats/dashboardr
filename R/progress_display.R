# =================================================================
# progress_display
# =================================================================

# Show custom progress message (internal)
# @param msg Message to display
# @param icon Emoji or symbol to prefix
# @param show_progress Whether to show progress
.progress_msg <- function(msg, icon = "\u25aa", show_progress = TRUE) {
  if (show_progress) {
    cat(icon, msg, "\n")
  }
}

# Show custom progress step (internal)
# @param msg Step message
# @param elapsed Optional elapsed time in seconds
# @param show_progress Whether to show progress
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
      prefix <- if (is_last) "\u2551 \u2514\u2500 \U0001f4c4 " else "\u2551 \u251c\u2500 \U0001f4c4 "
      cat(prefix, msg, time_str, "\n", sep = "")
    } else {
      # Use regular style for setup/config steps
      cat("  \u2713", msg, time_str, "\n")
    }
  }
}

# Show progress header (internal)
# @param title Header title
# @param show_progress Whether to show progress
.progress_header <- function(title, show_progress = TRUE) {
  if (show_progress) {
    cat("\n")
    cat("\u2554\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2557\n")
    cat("\u2551  ", title, sprintf("%*s", max(0, 45 - nchar(title)), ""), "\u2551\n")
    cat("\u255a\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u255d\n")
  }
}

# Show progress section (internal)
# @param title Section title
# @param show_progress Whether to show progress
.progress_section <- function(title, show_progress = TRUE) {
  if (show_progress) {
    cat("\n")
    cat("\u250c\u2500", title, "\n")
  }
}

# Show progress bar (internal)
# @param current Current step
# @param total Total steps
# @param label Optional label
# @param show_progress Whether to show progress
.progress_bar <- function(current, total, label = "", show_progress = TRUE) {
  if (show_progress) {
    pct <- round((current / total) * 100)
    filled <- round(pct / 5)  # 20 chars total
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
    if (current == total) cat("\n")
  }
}
