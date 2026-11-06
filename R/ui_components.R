# =================================================================
# ui_components
# =================================================================



#' Create iconify icon shortcode
#'
#' Helper function to generate iconify icon shortcodes for use in pages and visualizations.
#'
#' @param icon_name Icon name in format "collection:name" (e.g., "ph:users-three")
#' @return Iconify shortcode string
#' @export
#' @examples
#' \dontrun{
#' icon("ph:users-three")  # Returns iconify shortcode
#' icon("emojione:flag-for-united-states")  # Returns iconify shortcode
#' }
icon <- function(icon_name) {
  # Convert "collection:name" to "{{< iconify collection name >}}"
  parts <- strsplit(icon_name, ":", fixed = TRUE)[[1]]
  if (length(parts) != 2) {
    stop("Icon name must be in format 'collection:name' (e.g., 'ph:users-three')")
  }
  paste0("{{< iconify ", parts[1], " ", parts[2], " >}}")
}

#' Create a Bootstrap card component
#'
#' Helper function to create Bootstrap card components for displaying content in a structured way.
#' Useful for author profiles, feature highlights, or any content that benefits from card layout.
#'
#' @param content Card content (text, HTML, or other elements)
#' @param title Optional card title
#' @param image Optional image URL or path
#' @param image_alt Alt text for the image
#' @param footer Optional card footer content
#' @param class Additional CSS classes for the card
#' @param style Additional inline styles for the card
#' @return HTML div element with Bootstrap card classes
#' @export
#' @examples
#' \dontrun{
#' # Simple text card
#' card("This is a simple card with just text content")
#'
#' # Card with title and image
#' card(
#'   content = "This is the card body content",
#'   title = "Card Title",
#'   image = "https://example.com/image.jpg",
#'   image_alt = "Description of image"
#' )
#'
#' # Author card
#' card(
#'   content = "Dr. Jane Smith is a researcher specializing in data science and visualization.",
#'   title = "Dr. Jane Smith",
#'   image = "https://example.com/jane.jpg",
#'   footer = "Website: janesmith.com"
#' )
#' }
card <- function(content, title = NULL, image = NULL, image_alt = NULL,
                footer = NULL, class = NULL, style = NULL) {

  # Start building the card
  card_classes <- c("card", class)
  card_style <- style

  # Create the card structure
  card_div <- htmltools::div(
    class = paste(card_classes, collapse = " "),
    style = card_style
  )

  # Add image if provided
  if (!is.null(image)) {
    image_div <- htmltools::div(
      class = "card-img-top",
      htmltools::img(
        src = image,
        alt = image_alt %||% "",
        class = "img-fluid",
        style = "width: 100%; height: auto;"
      )
    )
    card_div <- htmltools::tagAppendChild(card_div, image_div)
  }

  # Create card body
  card_body <- htmltools::div(class = "card-body")

  # Add title if provided
  if (!is.null(title)) {
    title_div <- htmltools::div(
      class = "card-title",
      htmltools::h5(title)
    )
    card_body <- htmltools::tagAppendChild(card_body, title_div)
  }

  # Add content
  content_div <- htmltools::div(
    class = "card-text",
    content
  )
  card_body <- htmltools::tagAppendChild(card_body, content_div)

  # Add card body to card
  card_div <- htmltools::tagAppendChild(card_div, card_body)

  # Add footer if provided
  if (!is.null(footer)) {
    footer_div <- htmltools::div(
      class = "card-footer text-muted",
      footer
    )
    card_div <- htmltools::tagAppendChild(card_div, footer_div)
  }

  return(card_div)
}

#' Display cards in a Bootstrap row
#'
#' Helper function to display multiple cards in a responsive Bootstrap row layout.
#'
#' @param ... Card objects to display
#' @param cols Number of columns per row (default: 2)
#' @param class Additional CSS classes for the row
#' @return HTML div element with Bootstrap row classes containing the cards
#' @export
#' @examples
#' \dontrun{
#' # Display two cards in a row
#' card_row(card1, card2)
#'
#' # Display three cards in a row (3 columns)
#' card_row(card1, card2, card3, cols = 3)
#' }
card_row <- function(..., cols = 2, class = NULL) {
  cards <- list(...)

  # Calculate Bootstrap column class
  col_class <- paste0("col-md-", 12 %/% cols)

  # Create row with cards
  row_div <- htmltools::div(
    class = paste(c("row", class), collapse = " "),
    lapply(cards, function(card) {
      htmltools::div(class = col_class, card)
    })
  )

  return(row_div)
}

#' Create multi-line markdown text content
#'
#' Helper function to create readable multi-line markdown text content for pages.
#' Automatically handles line breaks and formatting for better readability.
#'
#' @param ... Text content as separate arguments or character vectors
#' @param sep Separator to use when joining text (default: "\\n" for newlines). Use "" for no separator.
#' @return Single character string with proper line breaks
#' @export
#' @examples
#' \dontrun{
#' # Method 1: Separate arguments (default: newlines between)
#' text_content <- md_text(
#'   "# Welcome",
#'   "",
#'   "This is a multi-line text block.",
#'   "",
#'   "## Features",
#'   "- Feature 1",
#'   "- Feature 2"
#' )
#'
#' # Method 2: Character vectors
#' lines <- c("# About", "", "This is about our study.")
#' text_content <- md_text(lines)
#'
#' # Method 3: Combine without newlines
#' combined <- md_text(text1, text2, text3, sep = "")
#'
#' # Use in add_page
#' add_page("About", text = text_content)
#' }
md_text <- function(..., sep = "\n") {
  # Combine all arguments into a single character vector
  args <- list(...)
  content <- character(0)

  for (arg in args) {
    if (is.character(arg)) {
      content <- c(content, arg)
    } else {
      content <- c(content, as.character(arg))
    }
  }

  # Join with specified separator (default: newlines)
  paste(content, collapse = sep)
}

#' Create text content from a character vector
#'
#' Alternative helper for creating text content from existing character vectors.
#'
#' @param lines Character vector of text lines
#' @return Single character string with proper line breaks
#' @export
#' @examples
#' \dontrun{
#' lines <- c("# Title", "", "Content here")
#' text_content <- text_lines(lines)
#' add_page("Page", text = text_content)
#' }
text_lines <- function(lines) {
  paste(lines, collapse = "\n")
}

#' Convert inline Markdown (**bold**, *italic*, `code`) safely for HTML blocks
#' @keywords internal
.md_inline_to_html <- function(x) {
  if (is.null(x) || !nzchar(x)) return("")
  out <- gsub("\\*\\*(.*?)\\*\\*", "<strong>\\1</strong>", x)
  out <- gsub("`([^`]+)`", "<code>\\1</code>", out)
  out
}

#' Add an Editorial Observatory Hero banner to a content collection or page
#'
#' Creates a styled hero header with an optional eyebrow badge, title, Markdown-formatted
#' lead paragraphs (automatically converting `**bold**` to `<strong>`), and a responsive
#' row of icon + metric cards.
#'
#' @param content A `content_collection`, `page_object`, or `NULL` (returns raw HTML string)
#' @param title Main hero heading
#' @param eyebrow Optional uppercase eyebrow badge text above the title
#' @param lead Optional character vector or paragraph string (supports `**bold**` and `\n\n` paragraphs)
#' @param metrics Optional list of metric items, each a list with `icon`, `value`, and `sub`
#' @param primary_color Brand primary hex color (default: `"#3D7271"`)
#' @param accent_color Brand accent hex color (default: `"#E28D50"`)
#' @param tabgroup Optional tabgroup
#' @param show_when Optional conditional formula
#' @return Updated `content_collection` / `page_object` (or HTML string if `content` is `NULL`)
#' @export
add_hero <- function(content = NULL,
                     title,
                     eyebrow = NULL,
                     lead = NULL,
                     metrics = NULL,
                     primary_color = "#3D7271",
                     accent_color = "#E28D50",
                     tabgroup = NULL,
                     show_when = NULL) {
  eyebrow_html <- if (!is.null(eyebrow) && nzchar(eyebrow)) {
    paste0(
      "<div class='dashboardr-hero-eyebrow' style='display:inline-flex;align-items:center;gap:0.45rem;font-size:0.78rem;font-weight:700;text-transform:uppercase;letter-spacing:0.08em;color:", primary_color, ";background:#eef6f4;border:1px solid #cce0dd;padding:0.28rem 0.75rem;border-radius:999px;margin-bottom:0.85rem;'>",
      "<span style='width:7px;height:7px;border-radius:50%;background:", accent_color, ";display:inline-block;'></span> ",
      eyebrow,
      "</div>"
    )
  } else ""

  lead_html <- ""
  if (!is.null(lead) && length(lead) > 0) {
    lead_joined <- paste(lead, collapse = "\n\n")
    paras <- unlist(strsplit(lead_joined, "\n\n", fixed = TRUE))
    paras <- paras[nzchar(trimws(paras))]
    if (length(paras) > 0) {
      p_tags <- vapply(seq_along(paras), function(i) {
        style_str <- if (i == 1L) {
          "font-size:1.05rem;line-height:1.65;color:#1c3b39;font-weight:600;max-width:880px;margin:0 0 0.55rem 0;"
        } else {
          "font-size:1.05rem;line-height:1.65;color:#364f4d;max-width:880px;margin:0 0 0.55rem 0;"
        }
        paste0("<p style='", style_str, "'>", .md_inline_to_html(paras[i]), "</p>")
      }, character(1))
      lead_html <- paste0("<div class='dashboardr-hero-lead'>", paste(p_tags, collapse = ""), "</div>")
    }
  }

  metrics_html <- ""
  if (!is.null(metrics) && length(metrics) > 0) {
    m_items <- vapply(metrics, function(m) {
      ic <- if (!is.null(m$icon)) {
        paste0(
          "<div style='width:36px;height:36px;border-radius:8px;background:#eef6f4;color:", primary_color, ";display:inline-flex;align-items:center;justify-content:center;font-size:1.2rem;flex-shrink:0;'>",
          "<iconify-icon icon='", m$icon, "'></iconify-icon></div>"
        )
      } else ""
      paste0(
        "<div style='display:flex;align-items:center;gap:0.75rem;padding:0.65rem 0.9rem;background:rgba(255,255,255,0.85);border:1px solid #e2ecea;border-radius:10px;'>",
        ic,
        "<div><div style='font-size:0.98rem;font-weight:700;color:#142d2c;line-height:1.2;'>", .md_inline_to_html(m$value %||% ""), "</div>",
        "<div style='font-size:0.78rem;color:#5b7472;margin-top:0.1rem;'>", .md_inline_to_html(m$sub %||% ""), "</div></div></div>"
      )
    }, character(1))
    metrics_html <- paste0(
      "<div style='display:grid;grid-template-columns:repeat(auto-fit,minmax(195px,1fr));gap:0.9rem;margin-top:1.45rem;padding-top:1.25rem;border-top:1px solid #e1ecea;'>",
      paste(m_items, collapse = ""),
      "</div>"
    )
  }

  hero_block <- paste0(
    "<div class='dashboardr-observatory-hero' style='position:relative;overflow:hidden;background:linear-gradient(135deg,#ffffff 0%,#f4f9f8 58%,#eef6f5 100%);border:1px solid #d4e3e1;border-top:4px solid ", primary_color, ";border-radius:16px;padding:2.1rem 2.3rem 1.75rem 2.3rem;margin:0.5rem 0 1.6rem 0;box-shadow:0 12px 32px -10px rgba(20,52,50,0.08);'>",
    eyebrow_html,
    "<h1 style='font-size:2.05rem;font-weight:800;color:#132a29;letter-spacing:-0.02em;margin:0 0 0.7rem 0;line-height:1.2;'>", .md_inline_to_html(title), "</h1>",
    lead_html,
    metrics_html,
    "</div>"
  )

  if (is.null(content)) return(hero_block)
  add_html(content, hero_block, tabgroup = tabgroup, show_when = show_when)
}

#' Add a Bento Navigation Grid of interactive cards to a content collection or page
#'
#' @param content A `content_collection`, `page_object`, or `NULL` (returns raw HTML string)
#' @param cards A list of card specifications (or data frame with columns `href`, `title`, `description`, `icon`, `badges`)
#' @param cta_label Call-to-action footer text on each card (default: `"Explore"`)
#' @param primary_color Brand primary hex color (default: `"#3D7271"`)
#' @param accent_color Brand accent hex color (default: `"#E28D50"`)
#' @param tabgroup Optional tabgroup
#' @param show_when Optional conditional formula
#' @return Updated `content_collection` / `page_object` (or HTML string if `content` is `NULL`)
#' @export
add_bento_grid <- function(content = NULL,
                           cards,
                           cta_label = "Explore",
                           primary_color = "#3D7271",
                           accent_color = "#E28D50",
                           tabgroup = NULL,
                           show_when = NULL) {
  if (is.data.frame(cards)) {
    cards <- lapply(seq_len(nrow(cards)), function(i) as.list(cards[i, , drop = FALSE]))
  }

  cards_html <- vapply(seq_along(cards), function(idx) {
    c_item <- cards[[idx]]
    num_str <- sprintf("%02d", idx)
    ic <- c_item$icon %||% "ph:squares-four-fill"
    href <- c_item$href %||% "#"
    title <- .md_inline_to_html(c_item$title %||% "")
    desc <- .md_inline_to_html(c_item$description %||% c_item$text %||% "")
    paste0(
      "<a class='dashboardr-bento-card' href='", href, "' style='position:relative;overflow:hidden;display:flex;flex-direction:column;justify-content:space-between;padding:1.35rem 1.4rem 1.15rem 1.4rem;border-radius:13px;border:1px solid #dce7e5;border-left:4px solid ", primary_color, ";background:#ffffff;color:inherit !important;text-decoration:none !important;box-shadow:0 6px 18px -4px rgba(15,40,38,0.05);transition:transform 0.2s ease,box-shadow 0.2s ease;'>",
      "<div>",
      "<div style='display:flex;align-items:flex-start;justify-content:space-between;gap:0.75rem;margin-bottom:0.65rem;'>",
      "<div style='display:flex;align-items:center;gap:0.75rem;'>",
      "<span style='width:40px;height:40px;border-radius:10px;background:#eef6f4;border:1px solid #d5e6e3;color:", primary_color, ";display:inline-flex;align-items:center;justify-content:center;font-size:1.3rem;flex-shrink:0;'><iconify-icon icon='", ic, "'></iconify-icon></span>",
      "<span style='font-weight:700;font-size:1.08rem;color:#142d2c;line-height:1.25;'>", title, "</span>",
      "</div>",
      "<span style='font-family:monospace;font-size:0.74rem;font-weight:600;color:#6c8886;background:#f3f8f7;border:1px solid #e0ecea;padding:0.15rem 0.48rem;border-radius:6px;flex-shrink:0;'>", num_str, "</span>",
      "</div>",
      "<div style='font-size:0.9rem;line-height:1.52;color:#4a6361;margin-bottom:1rem;'>", desc, "</div>",
      "</div>",
      "<div style='display:flex;align-items:center;justify-content:space-between;padding-top:0.7rem;border-top:1px solid #edf3f2;font-size:0.8rem;font-weight:600;color:", primary_color, ";'>",
      "<span>", cta_label, "</span>",
      "<span><iconify-icon inline icon='ph:arrow-right-bold'></iconify-icon></span>",
      "</div></a>"
    )
  }, character(1))

  grid_html <- paste0(
    "<div class='dashboardr-bento-grid' style='display:grid;grid-template-columns:repeat(auto-fit,minmax(285px,1fr));gap:1.15rem;margin:1.25rem 0 2.25rem 0;'>",
    paste(cards_html, collapse = "\n"),
    "</div>"
  )

  if (is.null(content)) return(grid_html)
  add_html(content, grid_html, tabgroup = tabgroup, show_when = show_when)
}

#' Add a Smooth-Scroll Section Jump Navigation bar to a content collection or page
#'
#' @param content A `content_collection`, `page_object`, or `NULL` (returns raw HTML string)
#' @param links Named character vector (`c("Skills" = "#skills", "Knowledge" = "#knowledge")`) or list of `list(label, href, icon)`
#' @param intro_text Optional introductory text paragraph above the jump links
#' @param label Optional prefix label before the jump pills (e.g., `"Jump to section:"`)
#' @param primary_color Brand primary hex color (default: `"#3D7271"`)
#' @param tabgroup Optional tabgroup
#' @param show_when Optional conditional formula
#' @return Updated `content_collection` / `page_object` (or HTML string if `content` is `NULL`)
#' @export
add_jump_nav <- function(content = NULL,
                         links,
                         intro_text = NULL,
                         label = NULL,
                         primary_color = "#3D7271",
                         tabgroup = NULL,
                         show_when = NULL) {
  if (is.character(links) && !is.null(names(links))) {
    links <- lapply(names(links), function(nm) list(label = nm, href = links[[nm]]))
  }

  pills <- vapply(links, function(lk) {
    ic_html <- if (!is.null(lk$icon)) paste0("<iconify-icon inline icon='", lk$icon, "'></iconify-icon> ") else ""
    paste0(
      "<a href='", lk$href, "' style='display:inline-flex;align-items:center;gap:0.35rem;padding:0.24rem 0.7rem;border-radius:7px;background:#f3f8f7;border:1px solid #cde0dd;color:", primary_color, ";font-size:0.86rem;font-weight:600;text-decoration:none;'>",
      ic_html, "<span>", .md_inline_to_html(lk$label), "</span> &#8595;</a>"
    )
  }, character(1))

  intro_p <- if (!is.null(intro_text) && nzchar(intro_text)) {
    paste0("<p style='font-size:1.01rem;line-height:1.65;color:#213736;margin:0 0 0.8rem 0;'>", .md_inline_to_html(intro_text), "</p>")
  } else ""

  lbl_span <- if (!is.null(label) && nzchar(label)) {
    paste0("<span style='font-weight:600;color:#1b3332;margin-right:0.25rem;'>", .md_inline_to_html(label), "</span> ")
  } else ""

  nav_html <- paste0(
    "<div class='dashboardr-jump-nav' style='background:#ffffff;border:1px solid #d8e4e2;border-left:5px solid ", primary_color, ";border-radius:12px;padding:1.2rem 1.45rem;margin:0.65rem 0 1.65rem 0;box-shadow:0 2px 12px rgba(15,45,43,0.04);'>",
    intro_p,
    "<div style='display:flex;flex-wrap:wrap;align-items:center;gap:0.45rem;padding-top:0.5rem;border-top:1px solid #e7f0ee;font-size:0.92rem;'>",
    lbl_span,
    paste(pills, collapse = " "),
    "</div></div>"
  )

  if (is.null(content)) return(nav_html)
  add_html(content, nav_html, tabgroup = tabgroup, show_when = show_when)
}

#' Add a Survey Demographic Frequency Table (`reactable`) with Inline Percentage Bars
#'
#' Computes a frequency and percentage breakdown for a categorical or discrete variable
#' in `data` and adds a styled `reactable` table with visual percentage bars.
#'
#' @param content A `content_collection` or `page_object`
#' @param data A data frame containing `var_name`
#' @param var_name Column name (string) to tabulate
#' @param labels_map Optional named character vector mapping raw codes to display labels (preserving order)
#' @param exclude_vals Optional vector of values (e.g. `c("66", "99")`) to exclude before computing percentages
#' @param category_label Column header for the category column (default: `"Category"`)
#' @param bar_color Hex color for inline percentage bars (default: `"#E28D50"`)
#' @param header_bg Hex color for the table header background (default: `"#3D7271"`)
#' @param tabgroup Optional tabgroup
#' @param show_when Optional conditional formula
#' @return Updated `content_collection` or `page_object`
#' @export
add_freq_table <- function(content,
                           data,
                           var_name,
                           labels_map = NULL,
                           exclude_vals = NULL,
                           category_label = "Category",
                           bar_color = "#E28D50",
                           header_bg = "#3D7271",
                           tabgroup = NULL,
                           show_when = NULL) {
  rlang::check_installed("reactable", reason = "to use add_freq_table()")
  vals <- data[[var_name]]
  if (!is.null(exclude_vals)) {
    vals[as.character(vals) %in% as.character(exclude_vals)] <- NA
  }
  if (!is.null(labels_map)) {
    vals <- as.character(vals)
    for (k in names(labels_map)) vals[vals == k] <- labels_map[[k]]
  }
  tbl <- table(vals, useNA = "no")
  df <- data.frame(Category = names(tbl), N = as.integer(tbl), stringsAsFactors = FALSE)
  df$Pct <- if (sum(df$N) > 0) round(100 * df$N / sum(df$N), 1) else 0
  if (!is.null(labels_map)) {
    df$Category <- factor(df$Category, levels = unname(labels_map))
    df <- df[order(df$Category), ]
  }

  max_pct <- max(c(df$Pct, 1), na.rm = TRUE)
  rt <- reactable::reactable(
    df,
    compact = TRUE, borderless = TRUE, striped = TRUE,
    defaultPageSize = nrow(df), pagination = FALSE,
    theme = reactable::reactableTheme(
      headerStyle = list(background = header_bg, color = "white", fontWeight = "bold", fontSize = "13px"),
      cellStyle = list(fontSize = "13px")
    ),
    columns = list(
      Category = reactable::colDef(name = category_label, minWidth = 180),
      N = reactable::colDef(name = "N", align = "right", minWidth = 60),
      Pct = reactable::colDef(
        name = "%", align = "left", minWidth = 200,
        cell = function(value) {
          if (is.na(value)) return(htmltools::span("—"))
          bar_width <- paste0(round(value / max_pct * 100), "%")
          htmltools::div(
            style = "display: flex; align-items: center;",
            htmltools::div(style = paste0("background: ", bar_color, "; height: 16px; width: ", bar_width, "; border-radius: 3px; margin-right: 8px;")),
            htmltools::span(paste0(value, "%"))
          )
        }
      )
    )
  )

  add_reactable(content, rt, tabgroup = tabgroup, show_when = show_when)
}



