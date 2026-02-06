# --------------------------------------------------------------------------
# Value Box Rendering Functions
# --------------------------------------------------------------------------

#' Render a single value box
#'
#' @param title Box title (small text above value)
#' @param value Main value to display (large text)
#' @param bg_color Background color (hex code), default "#2c3e50"
#' @param logo_url Optional URL or path to logo image
#' @param logo_text Optional text to display as logo (if no logo_url)
#' @export
render_value_box <- function(title, value, bg_color = "#2c3e50", logo_url = NULL, logo_text = NULL) {
  # Determine logo element
  logo_html <- if (!is.null(logo_url)) {
    paste0("<img src='", logo_url, "' style='width: 80px; height: 80px; object-fit: contain;' />")
  } else if (!is.null(logo_text)) {
    paste0("<div style='font-size: 3rem; font-weight: 700; opacity: 0.3;'>", logo_text, "</div>")
  } else {
    "<div style='font-size: 3rem; opacity: 0.3;'>\U0001f4ca</div>"
  }
  
  # Build the value box HTML
  value_box_html <- paste0(
    "<div class='custom-value-box' style='",
    "background: ", bg_color, "; ",
    "border-radius: 12px; ",
    "padding: 2rem; ",
    "color: white; ",
    "box-shadow: 0 4px 6px rgba(0,0,0,0.1); ",
    "transition: transform 0.3s ease, box-shadow 0.3s ease; ",
    "display: flex; ",
    "align-items: center; ",
    "gap: 1.5rem; ",
    "min-width: 300px; ",
    "position: relative; ",
    "overflow: hidden;",
    "'>",
    "  <div style='flex-shrink: 0; display: flex; align-items: center; justify-content: center; width: 80px;'>",
    "    ", logo_html, "  ",
    "  </div>",
    "  <div style='flex: 1;'>",
    "    <div style='font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.05em; opacity: 0.9; margin-bottom: 0.5rem; font-weight: 600;'>",
    "      ", title,
    "    </div>",
    "    <div style='font-size: 1.75rem; font-weight: 800; letter-spacing: -0.02em; white-space: nowrap;'>",
    "      ", value,
    "    </div>",
    "  </div>",
    "</div>"
  )
  
  # Output as raw HTML wrapped in markdown
  cat("\n```{=html}\n")
  cat(value_box_html)
  cat("\n```\n")
  invisible(value_box_html)
}

#' Render a row of value boxes
#'
#' @param boxes List of value box specifications, each containing title, value, bg_color, logo_url, logo_text
#' @export
render_value_box_row <- function(boxes) {
  # Start container
  html <- "<div style='display: flex; gap: 1.5rem; flex-wrap: wrap; margin-bottom: 2rem;'>"
  
  for (box in boxes) {
    # Determine logo element
    logo_html <- if (!is.null(box$logo_url)) {
      paste0("<img src='", box$logo_url, "' style='width: 80px; height: 80px; object-fit: contain;' />")
    } else if (!is.null(box$logo_text)) {
      paste0("<div style='font-size: 3rem; font-weight: 700; opacity: 0.3;'>", box$logo_text, "</div>")
    } else {
      "<div style='font-size: 3rem; opacity: 0.3;'>\U0001f4ca</div>"
    }
    
    # Build individual value box
    value_box_html <- paste0(
      "  <div style='flex: 1; min-width: 300px;'>",
      "    <div class='custom-value-box' style='",
      "    background: ", box$bg_color, "; ",
      "    border-radius: 12px; ",
      "    padding: 2rem; ",
      "    color: white; ",
      "    box-shadow: 0 4px 6px rgba(0,0,0,0.1); ",
      "    transition: transform 0.3s ease, box-shadow 0.3s ease; ",
      "    display: flex; ",
      "    align-items: center; ",
      "    gap: 1.5rem; ",
      "    position: relative; ",
      "    overflow: hidden;",
      "    '>",
      "      <div style='flex-shrink: 0; display: flex; align-items: center; justify-content: center; width: 80px;'>",
      "        ", logo_html, "      ",
      "      </div>",
      "      <div style='flex: 1;'>",
      "        <div style='font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.05em; opacity: 0.9; margin-bottom: 0.5rem; font-weight: 600;'>",
      "          ", box$title,
      "        </div>",
      "        <div style='font-size: 1.75rem; font-weight: 800; letter-spacing: -0.02em; white-space: nowrap;'>",
      "          ", box$value,
      "        </div>",
      "      </div>",
      "    </div>",
      "  </div>"
    )
    
    html <- paste0(html, value_box_html)
  }
  
  # Close container
  html <- paste0(html, "</div>")
  
  # Output as raw HTML wrapped in markdown
  cat("\n```{=html}\n")
  cat(html)
  cat("\n```\n")
  invisible(html)
}

