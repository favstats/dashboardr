# =================================================================
# Real Pagination Controls (Multi-Page Navigation)
# =================================================================

#' Generate pagination navigation controls
#'
#' Creates theme-aware navigation controls for multi-page dashboards.
#' Includes Previous/Next buttons and page indicator.
#'
#' @param page_num Current page number
#' @param total_pages Total number of pages
#' @param base_name Base filename (e.g., "analysis" for analysis.qmd)
#' @param theme Quarto theme name (for styling)
#' @param position Position of navigation: "top", "bottom" (default: "bottom")
#' @param separator_text Text to show between page number and total (default: "/", kept for backward compatibility)
#' @return Character vector of HTML/CSS lines
#' @keywords internal
.generate_pagination_nav <- function(page_num, total_pages, base_name, theme = NULL, position = "bottom", separator_text = "/") {
  nav_html <- character(0)
  
  # Only show navigation if there are multiple pages
  if (total_pages <= 1) {
    return(nav_html)
  }
  
  # Generate array of all page URLs for JavaScript
  page_urls <- character(total_pages)
  for (i in seq_len(total_pages)) {
    if (i == 1) {
      page_urls[i] <- paste0(base_name, ".html")
    } else {
      page_urls[i] <- paste0(base_name, "_p", i, ".html")
    }
  }
  page_urls_json <- jsonlite::toJSON(page_urls, auto_unbox = FALSE)
  
  # Add position-specific class
  nav_class <- paste0("pagination-nav pagination-", position)
  
  nav_html <- c(nav_html,
    "",
    "```{=html}"
  )
  
  # Add body class for top position (much faster than CSS :has())
  if (position == "top") {
    nav_html <- c(nav_html,
      "<script>document.body.classList.add('has-pagination-top');</script>"
    )
  }
  
  nav_html <- c(nav_html,
    paste0("<nav class='", nav_class, "' role='navigation' aria-label='Page navigation'>"),
    "  <div class='pagination-container'>"
  )
  
  # Previous button (disabled on first page)
  if (page_num > 1) {
    prev_link <- if (page_num == 2) {
      paste0(base_name, ".html")
    } else {
      paste0(base_name, "_p", page_num - 1, ".html")
    }
    nav_html <- c(nav_html,
      paste0("    <a href='", prev_link, "' class='pagination-btn pagination-prev' aria-label='Previous page'>"),
      "      <svg class='pagination-icon' width='18' height='18' viewBox='0 0 20 20' fill='none' xmlns='http://www.w3.org/2000/svg'>",
      "        <path d='M12 16L6 10L12 4' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'/>",
      "      </svg>",
      "    </a>"
    )
  } else {
    # Disabled previous button
    nav_html <- c(nav_html,
      "    <button class='pagination-btn pagination-prev pagination-disabled' disabled aria-label='Previous page'>",
      "      <svg class='pagination-icon' width='18' height='18' viewBox='0 0 20 20' fill='none' xmlns='http://www.w3.org/2000/svg'>",
      "        <path d='M12 16L6 10L12 4' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'/>",
      "      </svg>",
      "    </button>"
    )
  }
  
  # Page input with dropdown
  # Show "Page" prefix when at top for clarity, minimal at bottom
  page_prefix <- if (position == "top") "Page " else ""
  
  nav_html <- c(nav_html,
    "    <div class='pagination-info'>",
    paste0("      <span class='pagination-prefix'>", page_prefix, "</span>"),
    paste0("      <input type='number' class='pagination-input' id='page-input-", position, "' min='1' max='", total_pages, "' value='", page_num, "' aria-label='Current page'>"),
    paste0("      <span class='pagination-separator'> ", separator_text, " ", total_pages, "</span>"),
    "    </div>"
  )
  
  # Next button (disabled on last page)
  if (page_num < total_pages) {
    next_link <- paste0(base_name, "_p", page_num + 1, ".html")
    nav_html <- c(nav_html,
      paste0("    <a href='", next_link, "' class='pagination-btn pagination-next' aria-label='Next page'>"),
      "      <svg class='pagination-icon' width='18' height='18' viewBox='0 0 20 20' fill='none' xmlns='http://www.w3.org/2000/svg'>",
      "        <path d='M8 16L14 10L8 4' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'/>",
      "      </svg>",
      "    </a>"
    )
  } else {
    # Disabled next button
    nav_html <- c(nav_html,
      "    <button class='pagination-btn pagination-next pagination-disabled' disabled aria-label='Next page'>",
      "      <svg class='pagination-icon' width='18' height='18' viewBox='0 0 20 20' fill='none' xmlns='http://www.w3.org/2000/svg'>",
      "        <path d='M8 16L14 10L8 4' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'/>",
      "      </svg>",
      "    </button>"
    )
  }
  
  nav_html <- c(nav_html,
    "  </div>",
    "</nav>",
    "",
    "<!-- Pagination Navigation Script -->",
    "<script>",
    "(function() {",
    paste0("  const pageUrls = ", page_urls_json, ";"),
    paste0("  const pageInput = document.getElementById('page-input-", position, "');"),
    "  ",
    "  if (pageInput) {",
    "    pageInput.addEventListener('change', function() {",
    "      const pageNum = parseInt(this.value);",
    "      if (pageNum >= 1 && pageNum <= pageUrls.length) {",
    "        window.location.href = pageUrls[pageNum - 1];",
    "      } else {",
    "        this.value = this.getAttribute('value');",
    "      }",
    "    });",
    "    ",
    "    pageInput.addEventListener('keypress', function(e) {",
    "      if (e.key === 'Enter') {",
    "        this.blur();",
    "      }",
    "    });",
    "  }",
    "})();",
    "</script>",
    "```",
    ""
  )
  
  # Note: pagination.css is now loaded globally in _quarto.yml
  # No need to add per-page CSS link
  
  nav_html
}
