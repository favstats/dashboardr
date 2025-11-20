# =================================================================
# Real Pagination Controls (Multi-Page Navigation)
# =================================================================

#' Add pagination navigation controls to a dashboard page
#'
#' Creates navigation controls for multi-page dashboards with Previous/Next buttons
#' and page indicator. Use this in your QMD file to add clean pagination without
#' embedding HTML directly.
#'
#' @param page_num Current page number
#' @param total_pages Total number of pages
#' @param base_name Base filename (e.g., "knowledge" for knowledge.qmd, knowledge_p2.qmd, etc.)
#' @param position Position of navigation: "top", "bottom", or "both" (default: "top")
#'
#' @return An htmltools tag object containing the pagination HTML and JavaScript
#'
#' @examples
#' \dontrun{
#' # In a Quarto document R chunk with results='asis':
#' dashboardr::add_pagination_nav(1, 3, "knowledge", "top")
#' 
#' # For both top and bottom:
#' dashboardr::add_pagination_nav(1, 3, "knowledge", "both")
#' }
#'
#' @export
add_pagination_nav <- function(page_num, total_pages, base_name, position = "top") {
  # Validate inputs
  if (total_pages <= 1) {
    return(htmltools::tags$div())  # Return empty div if only one page
  }
  
  # Handle "both" position
  if (position == "both") {
    return(htmltools::tagList(
      .create_pagination_nav_html(page_num, total_pages, base_name, "top"),
      .create_pagination_nav_html(page_num, total_pages, base_name, "bottom")
    ))
  }
  
  .create_pagination_nav_html(page_num, total_pages, base_name, position)
}

#' Internal function to create pagination navigation HTML
#' @keywords internal
.create_pagination_nav_html <- function(page_num, total_pages, base_name, position) {
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
  
  # Add body class for top position
  body_class_script <- if (position == "top") {
    htmltools::tags$script(htmltools::HTML("document.body.classList.add('has-pagination-top');"))
  } else {
    NULL
  }
  
  # Previous button
  prev_button <- if (page_num > 1) {
    prev_link <- if (page_num == 2) {
      paste0(base_name, ".html")
    } else {
      paste0(base_name, "_p", page_num - 1, ".html")
    }
    htmltools::tags$a(
      href = prev_link,
      class = "pagination-btn pagination-prev",
      `aria-label` = "Previous page",
      htmltools::HTML("<svg class='pagination-icon' width='18' height='18' viewBox='0 0 20 20' fill='none' xmlns='http://www.w3.org/2000/svg'><path d='M12 16L6 10L12 4' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'/></svg>")
    )
  } else {
    htmltools::tags$button(
      class = "pagination-btn pagination-prev pagination-disabled",
      disabled = NA,
      `aria-label` = "Previous page",
      htmltools::HTML("<svg class='pagination-icon' width='18' height='18' viewBox='0 0 20 20' fill='none' xmlns='http://www.w3.org/2000/svg'><path d='M12 16L6 10L12 4' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'/></svg>")
    )
  }
  
  # Page input
  page_prefix <- if (position == "top") "Page " else ""
  page_info <- htmltools::tags$div(
    class = "pagination-info",
    htmltools::tags$span(class = "pagination-prefix", page_prefix),
    htmltools::tags$input(
      type = "number",
      class = "pagination-input",
      id = paste0("page-input-", position),
      min = "1",
      max = as.character(total_pages),
      value = as.character(page_num),
      `aria-label` = "Current page"
    ),
    htmltools::tags$span(class = "pagination-separator", paste0(" / ", total_pages))
  )
  
  # Next button
  next_button <- if (page_num < total_pages) {
    next_link <- paste0(base_name, "_p", page_num + 1, ".html")
    htmltools::tags$a(
      href = next_link,
      class = "pagination-btn pagination-next",
      `aria-label` = "Next page",
      htmltools::HTML("<svg class='pagination-icon' width='18' height='18' viewBox='0 0 20 20' fill='none' xmlns='http://www.w3.org/2000/svg'><path d='M8 16L14 10L8 4' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'/></svg>")
    )
  } else {
    htmltools::tags$button(
      class = "pagination-btn pagination-next pagination-disabled",
      disabled = NA,
      `aria-label` = "Next page",
      htmltools::HTML("<svg class='pagination-icon' width='18' height='18' viewBox='0 0 20 20' fill='none' xmlns='http://www.w3.org/2000/svg'><path d='M8 16L14 10L8 4' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'/></svg>")
    )
  }
  
  # JavaScript for navigation
  nav_script <- htmltools::tags$script(htmltools::HTML(sprintf("
(function() {
  const pageUrls = %s;
  const pageInput = document.getElementById('page-input-%s');
  
  if (pageInput) {
    pageInput.addEventListener('change', function() {
      const pageNum = parseInt(this.value);
      if (pageNum >= 1 && pageNum <= pageUrls.length) {
        window.location.href = pageUrls[pageNum - 1];
      } else {
        this.value = this.getAttribute('value');
      }
    });
    
    pageInput.addEventListener('keypress', function(e) {
      if (e.key === 'Enter') {
        this.blur();
      }
    });
  }
})();
  ", page_urls_json, position)))
  
  # Combine everything
  htmltools::tagList(
    body_class_script,
    htmltools::tags$nav(
      class = paste0("pagination-nav pagination-", position),
      role = "navigation",
      `aria-label` = "Page navigation",
      htmltools::tags$div(
        class = "pagination-container",
        prev_button,
        page_info,
        next_button
      )
    ),
    nav_script
  )
}

#' Generate pagination navigation controls (internal function for dashboard creation)
#'
#' Creates theme-aware navigation controls for multi-page dashboards.
#' Now generates clean R code chunks instead of raw HTML.
#'
#' @param page_num Current page number
#' @param total_pages Total number of pages
#' @param base_name Base filename (e.g., "analysis" for analysis.qmd)
#' @param theme Quarto theme name (for styling, currently unused but kept for compatibility)
#' @param position Position of navigation: "top", "bottom" (default: "bottom")
#' @param separator_text Text to show between page number and total (default: "/", kept for backward compatibility)
#' @return Character vector of R code chunk lines
#' @keywords internal
.generate_pagination_nav <- function(page_num, total_pages, base_name, theme = NULL, position = "bottom", separator_text = "/") {
  nav_code <- character(0)
  
  # Only show navigation if there are multiple pages
  if (total_pages <= 1) {
    return(nav_code)
  }
  
  # Generate R code chunk that calls add_pagination_nav()
  # This keeps the generated QMD files clean and maintainable
  nav_code <- c(
    "",
    "```{r, echo=FALSE, message=FALSE, warning=FALSE, results='asis'}",
    sprintf("dashboardr::add_pagination_nav(%d, %d, \"%s\", \"%s\")", 
            page_num, total_pages, base_name, position),
    "```",
    ""
  )
  
  nav_code
}
