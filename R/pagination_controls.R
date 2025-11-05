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
#' @param separator_text Text to show between page number and total (default: "of")
#' @return Character vector of HTML/CSS lines
#' @keywords internal
.generate_pagination_nav <- function(page_num, total_pages, base_name, theme = NULL, separator_text = "of") {
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
  
  nav_html <- c(nav_html,
    "",
    "```{=html}",
    "<nav class='pagination-nav' role='navigation' aria-label='Page navigation'>",
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
  nav_html <- c(nav_html,
    "    <div class='pagination-info'>",
    paste0("      <input type='number' class='pagination-input' id='page-input' min='1' max='", total_pages, "' value='", page_num, "' aria-label='Current page'>"),
    paste0("      <span class='pagination-separator'>", separator_text, " ", total_pages, "</span>"),
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
    "  const pageInput = document.getElementById('page-input');",
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
  
  # Add theme-aware CSS
  nav_html <- c(nav_html, .generate_pagination_css(theme))
  
  nav_html
}

#' Generate theme-aware pagination CSS
#'
#' Creates CSS that adapts to Quarto Bootstrap themes using CSS variables.
#'
#' @param theme Quarto theme name (optional)
#' @return Character vector of CSS lines
#' @keywords internal
.generate_pagination_css <- function(theme = NULL) {
  c(
    "",
    "```{=html}",
    "<style>",
    "/* Ultra-Minimal Pagination Navigation */",
    ".pagination-nav {",
    "  position: sticky;",
    "  bottom: 2rem;",
    "  margin: 3rem auto 2rem auto;",
    "  max-width: 240px;",
    "  z-index: 100;",
    "}",
    "",
    ".pagination-container {",
    "  display: flex;",
    "  align-items: center;",
    "  justify-content: center;",
    "  gap: 1rem;",
    "  padding: 0.5rem 1rem;",
    "  background: transparent;",
    "}",
    "",
    ".pagination-btn {",
    "  display: flex;",
    "  align-items: center;",
    "  justify-content: center;",
    "  width: 32px;",
    "  height: 32px;",
    "  padding: 0;",
    "  background: transparent;",
    "  color: var(--bs-secondary, #6c757d);",
    "  text-decoration: none;",
    "  border-radius: 0.375rem;",
    "  transition: all 0.15s ease;",
    "  border: none;",
    "  cursor: pointer;",
    "}",
    "",
    ".pagination-btn:hover:not(.pagination-disabled) {",
    "  background: var(--bs-light, #f8f9fa);",
    "  color: var(--bs-body-color, #212529);",
    "}",
    "",
    ".pagination-btn:active:not(.pagination-disabled) {",
    "  background: var(--bs-gray-200, #e9ecef);",
    "}",
    "",
    ".pagination-btn.pagination-disabled {",
    "  color: var(--bs-gray-300, #dee2e6);",
    "  cursor: default;",
    "}",
    "",
    ".pagination-icon {",
    "  flex-shrink: 0;",
    "  opacity: 0.7;",
    "}",
    "",
    ".pagination-btn:hover:not(.pagination-disabled) .pagination-icon {",
    "  opacity: 1;",
    "}",
    "",
    ".pagination-info {",
    "  display: flex;",
    "  align-items: center;",
    "  gap: 0.5rem;",
    "  font-size: 0.875rem;",
    "  color: var(--bs-secondary, #6c757d);",
    "}",
    "",
    ".pagination-input {",
    "  width: 2.5rem;",
    "  padding: 0.25rem 0.5rem;",
    "  text-align: center;",
    "  border: 1px solid transparent;",
    "  border-radius: 0.25rem;",
    "  font-size: 0.875rem;",
    "  font-weight: 500;",
    "  color: var(--bs-body-color, #212529);",
    "  background: transparent;",
    "  transition: all 0.15s ease;",
    "}",
    "",
    ".pagination-input:hover {",
    "  background: var(--bs-light, #f8f9fa);",
    "  border-color: var(--bs-border-color, #dee2e6);",
    "}",
    "",
    ".pagination-input:focus {",
    "  outline: none;",
    "  background: var(--bs-body-bg, #fff);",
    "  border-color: var(--bs-primary, #0d6efd);",
    "  box-shadow: 0 0 0 2px rgba(13, 110, 253, 0.1);",
    "}",
    "",
    ".pagination-input::-webkit-inner-spin-button,",
    ".pagination-input::-webkit-outer-spin-button {",
    "  opacity: 0;",
    "}",
    "",
    ".pagination-separator {",
    "  color: var(--bs-secondary, #6c757d);",
    "  font-weight: 400;",
    "  font-size: 0.875rem;",
    "}",
    "",
    "/* Responsive */",
    "@media (max-width: 768px) {",
    "  .pagination-nav {",
    "    max-width: 220px;",
    "    bottom: 1.5rem;",
    "  }",
    "  ",
    "  .pagination-container {",
    "    gap: 0.75rem;",
    "    padding: 0.4rem 0.75rem;",
    "  }",
    "  ",
    "  .pagination-btn {",
    "    width: 30px;",
    "    height: 30px;",
    "  }",
    "  ",
    "  .pagination-icon {",
    "    width: 16px;",
    "    height: 16px;",
    "  }",
    "  ",
    "  .pagination-info {",
    "    font-size: 0.8rem;",
    "  }",
    "  ",
    "  .pagination-input {",
    "    width: 2.25rem;",
    "    font-size: 0.8rem;",
    "  }",
    "}",
    "",
    "@media (max-width: 480px) {",
    "  .pagination-nav {",
    "    max-width: 200px;",
    "  }",
    "  ",
    "  .pagination-btn {",
    "    width: 28px;",
    "    height: 28px;",
    "  }",
    "}",
    "",
    "/* Dark mode support */",
    "@media (prefers-color-scheme: dark) {",
    "  .pagination-btn:hover:not(.pagination-disabled) {",
    "    background: rgba(255, 255, 255, 0.05);",
    "  }",
    "  ",
    "  .pagination-btn:active:not(.pagination-disabled) {",
    "    background: rgba(255, 255, 255, 0.1);",
    "  }",
    "  ",
    "  .pagination-input:hover {",
    "    background: rgba(255, 255, 255, 0.05);",
    "  }",
    "}",
    "",
    "/* Override Quarto's back-to-top button position */",
    ".back-to-top {",
    "  right: 2rem !important;",
    "  left: auto !important;",
    "}",
    "",
    "@media (max-width: 768px) {",
    "  .back-to-top {",
    "    right: 1rem !important;",
    "  }",
    "}",
    "</style>",
    "```",
    ""
  )
}

