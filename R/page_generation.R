# =================================================================
# page_generation
# =================================================================


.generate_default_page_content <- function(page) {
  # Build title with icon if provided
  title_content <- page$name
  if (!is.null(page$icon)) {
    icon_shortcode <- if (grepl("{{< iconify", page$icon, fixed = TRUE)) {
      page$icon
    } else {
      icon(page$icon)
    }
    title_content <- paste0(icon_shortcode, " ", page$name)
  }

  content <- c(
    "---",
    paste0("title: \"", title_content, "\""),
    "format: html",
    "---",
    "",
    "```{r}",
    "#| include: false",
    "library(dashboardr)",
    "```",
    ""
  )

  # Add custom text content if provided
  if (isTRUE(!is.null(page$text) && nzchar(page$text))) {
    content <- c(content, page$text, "")
  }
  
  # Auto-enable modals if needed (flag set by add_modal())
  if (isTRUE(page$needs_modals)) {
    content <- c(content,
      "```{r, echo=FALSE, results='asis'}",
      "dashboardr::enable_modals()",
      "```",
      ""
    )
  }

  # Add global setup chunk with libraries, data, and settings
  if (!is.null(page$data_path) || !is.null(page$visualizations) || !is.null(page$content_blocks)) {
    content <- c(content, .generate_global_setup_chunk(page))
  }
  
  # Add loading overlay chunk if enabled
  if (isTRUE(!is.null(page$overlay) && page$overlay)) {
    # Get overlay settings with explicit defaults
    if (is.null(page$overlay_theme)) {
      overlay_theme <- "light"
    } else {
      overlay_theme <- page$overlay_theme
    }
    
    if (is.null(page$overlay_text)) {
      overlay_text <- "Loading"
    } else {
      overlay_text <- page$overlay_text
    }
    
    if (is.null(page$overlay_duration)) {
      overlay_duration <- 2200
    } else {
      overlay_duration <- page$overlay_duration
    }
    
    content <- c(content, .generate_loading_overlay_chunk(overlay_theme, overlay_text, overlay_duration))
  }
  
  # Add lazy loading script if enabled
  if (isTRUE(!is.null(page$lazy_load_charts) && page$lazy_load_charts)) {
    lazy_load_margin <- page$lazy_load_margin %||% "200px"
    lazy_load_tabs <- page$lazy_load_tabs %||% TRUE
    lazy_debug <- page$lazy_debug %||% FALSE
    
    # Get theme from overlay if enabled, otherwise default to "light"
    lazy_load_theme <- if (isTRUE(!is.null(page$overlay) && page$overlay)) {
      page$overlay_theme %||% "light"
    } else {
      "light"
    }
    
    content <- c(content, .generate_lazy_load_script(lazy_load_margin, lazy_load_tabs, lazy_load_theme, lazy_debug))
  }

  # Add content blocks (text, images, and other content types) before visualizations
  if (!is.null(page$content_blocks)) {
    for (block in page$content_blocks) {
      # Skip NULL blocks
      if (is.null(block)) next
      
      # Skip non-list blocks
      if (!is.list(block)) next
      
      # Check for content collection first (may contain visualizations)
      is_coll <- is_content(block)
      is_block <- is_content_block(block)
      
      # Skip if neither
      if (!is_coll && !is_block) next
      
      # If it's a content collection, handle it differently
      if (is_coll) {
        # Generate viz content for this collection
        viz_content <- .generate_viz_from_specs(block, 
                                                  page$lazy_load_charts %||% FALSE, 
                                                  page$lazy_load_tabs %||% FALSE)
        content <- c(content, viz_content)
        next
      }
      
      # Get block type safely
      block_type <- if (!is.null(block$type)) as.character(block$type)[1] else NULL
      if (is.null(block_type)) next
      
      # Dispatch to appropriate generator based on type
      block_content <- switch(block_type,
        "text" = c("", block$content, ""),
        "image" = .generate_image_block(block),
        "callout" = .generate_callout_block(block),
        "divider" = .generate_divider_block(block),
        "code" = .generate_code_block(block),
        "card" = .generate_card_block(block),
        "accordion" = .generate_accordion_block(block),
        "iframe" = .generate_iframe_block(block),
        "video" = .generate_video_block(block),
        "table" = .generate_table_block(block),
        "gt" = .generate_gt_block(block),
        "reactable" = .generate_reactable_block(block),
        "DT" = .generate_DT_block(block),
        "spacer" = .generate_spacer_block(block),
        "html" = .generate_html_block(block),
        "quote" = .generate_quote_block(block),
        "badge" = .generate_badge_block(block),
        "metric" = .generate_metric_block(block),
        "value_box" = .generate_value_box_block(block),
        "value_box_row" = .generate_value_box_row_block(block),
        NULL  # Unknown type - skip
      )
      
      if (!is.null(block_content)) {
        content <- c(content, block_content)
      }
    }
  }

  # Add visualizations
  if (!is.null(page$visualizations)) {
    # Get lazy load settings
    lazy_load_charts <- page$lazy_load_charts %||% FALSE
    lazy_load_tabs <- page$lazy_load_tabs %||% FALSE
    viz_content <- .generate_viz_from_specs(page$visualizations, lazy_load_charts, lazy_load_tabs)
    content <- c(content, viz_content)
  } else if (isTRUE(is.null(page$text) || !nzchar(page$text))) {
    if (isTRUE(is.null(page$content_blocks) || length(page$content_blocks) == 0)) {
      content <- c(content, "This page was generated without a template.")
    }
  }

  content
}

#' Generate image block markdown
#'
#' Internal function to generate markdown for image content blocks
#'
#' @param block Image content block
#' @return Character vector of markdown lines
#' @keywords internal
.generate_image_block <- function(block) {
  lines <- character(0)
  
  # Build image tag
  img_tag <- "!["
  img_tag <- paste0(img_tag, block$alt %||% "")
  img_tag <- paste0(img_tag, "](")
  img_tag <- paste0(img_tag, block$src)
  img_tag <- paste0(img_tag, ")")
  
  # Add optional attributes via HTML if needed
  if (!is.null(block$width) || !is.null(block$height) || !is.null(block$align) || !is.null(block$class)) {
    # Use HTML img tag for advanced styling
    html_tag <- "<img"
    html_tag <- paste0(html_tag, " src=\"", block$src, "\"")
    html_tag <- paste0(html_tag, " alt=\"", block$alt %||% "", "\"")
    
    if (!is.null(block$width)) {
      html_tag <- paste0(html_tag, " width=\"", block$width, "\"")
    }
    if (!is.null(block$height)) {
      html_tag <- paste0(html_tag, " height=\"", block$height, "\"")
    }
    if (!is.null(block$align)) {
      style <- paste0("text-align: ", block$align, ";")
      if (block$align == "center") {
        style <- paste0(style, " display: block; margin-left: auto; margin-right: auto;")
      }
      html_tag <- paste0(html_tag, " style=\"", style, "\"")
    }
    if (!is.null(block$class)) {
      html_tag <- paste0(html_tag, " class=\"", block$class, "\"")
    }
    
    html_tag <- paste0(html_tag, " />")
    
    # Wrap in link if provided
    if (!is.null(block$link)) {
      html_tag <- paste0("<a href=\"", block$link, "\">", html_tag, "</a>")
    }
    
    img_tag <- html_tag
  } else if (!is.null(block$link)) {
    # Simple markdown link
    img_tag <- paste0("[", img_tag, "](", block$link, ")")
  }
  
  lines <- c(lines, "", img_tag, "")
  
  # Add caption if provided
  if (isTRUE(!is.null(block$caption) && nzchar(block$caption))) {
    lines <- c(lines, paste0("*", block$caption, "*"), "")
  }
  
  lines
}

#' Generate callout block markdown
#'
#' Internal function to generate markdown for callout content blocks using Quarto callout syntax
#'
#' @param block Callout content block
#' @return Character vector of markdown lines
#' @keywords internal
.generate_callout_block <- function(block) {
  # Quarto callout syntax: ::: {.callout-type}
  # Types: note, warning, important, tip, caution
  type <- block$callout_type %||% "note"
  
  lines <- c("", paste0("::: {.callout-", type, "}"))
  
  # Add title if provided
  if (isTRUE(!is.null(block$title) && nzchar(block$title))) {
    lines <- c(lines, paste0("## ", block$title))
  }
  
  # Add content
  lines <- c(lines, block$content, ":::", "")
  
  lines
}

#' Generate divider block markdown
#'
#' Internal function to generate markdown for divider content blocks
#'
#' @param block Divider content block
#' @return Character vector of markdown lines
#' @keywords internal
.generate_divider_block <- function(block) {
  # Use Quarto horizontal rule or custom HTML
  style <- block$style %||% "default"
  
  if (style == "thick") {
    c("", "<hr style='border: 3px solid #333;' />", "")
  } else if (style == "dashed") {
    c("", "<hr style='border-top: 2px dashed #ccc;' />", "")
  } else if (style == "dotted") {
    c("", "<hr style='border-top: 2px dotted #ccc;' />", "")
  } else {
    # Default markdown horizontal rule
    c("", "---", "")
  }
}

#' Generate code block markdown
#'
#' Internal function to generate markdown for code content blocks
#'
#' @param block Code content block
#' @return Character vector of markdown lines
#' @keywords internal
.generate_code_block <- function(block) {
  lang <- block$language %||% ""
  
  lines <- c("", paste0("```", lang))
  lines <- c(lines, block$code)
  lines <- c(lines, "```", "")
  
  lines
}

#' Generate card block markdown
#'
#' Internal function to generate markdown for card content blocks
#'
#' @param block Card content block
#' @return Character vector of markdown lines
#' @keywords internal
.generate_card_block <- function(block) {
  # Use Bootstrap card or custom div
  lines <- c("", "<div class='card'>")
  
  if (isTRUE(!is.null(block$title) && nzchar(block$title))) {
    lines <- c(lines, paste0("<div class='card-header'>", block$title, "</div>"))
  }
  
  lines <- c(lines, "<div class='card-body'>")
  lines <- c(lines, block$text)
  lines <- c(lines, "</div>", "</div>", "")
  
  lines
}

#' Generate accordion block markdown
#'
#' Internal function to generate markdown for accordion content blocks
#'
#' @param block Accordion content block
#' @return Character vector of markdown lines
#' @keywords internal
.generate_accordion_block <- function(block) {
  # Use HTML details/summary for collapsible content
  lines <- c("", "<details>")
  lines <- c(lines, paste0("<summary>", block$title %||% "Details", "</summary>"))
  lines <- c(lines, "", block$text, "", "</details>", "")
  
  lines
}

#' Generate iframe block markdown
#'
#' Internal function to generate markdown for iframe content blocks
#'
#' @param block Iframe content block
#' @return Character vector of markdown lines
#' @keywords internal
.generate_iframe_block <- function(block) {
  height <- block$height %||% "500px"
  width <- block$width %||% "100%"
  
  iframe_tag <- paste0(
    "<iframe src='", block$url, "'",
    " width='", width, "'",
    " height='", height, "'",
    " frameborder='0'",
    " allowfullscreen",
    "></iframe>"
  )
  
  c("", iframe_tag, "")
}

#' Generate video block markdown
#'
#' Internal function to generate markdown for video content blocks
#'
#' @param block Video content block
#' @return Character vector of markdown lines
#' @keywords internal
.generate_video_block <- function(block) {
  # Use Quarto's native video shortcode for better compatibility
  url <- block$url
  
  if (grepl("youtube\\.com|youtu\\.be", url)) {
    # Extract YouTube video ID
    video_id <- sub(".*(?:youtube\\.com/watch\\?v=|youtu\\.be/)([^&?]+).*", "\\1", url)
    
    # Use Quarto video shortcode for YouTube
    c(
      "",
      paste0("{{< video https://www.youtube.com/embed/", video_id, " >}}"),
      ""
    )
  } else if (grepl("vimeo\\.com", url)) {
    # Extract Vimeo video ID
    video_id <- sub(".*vimeo\\.com/([0-9]+).*", "\\1", url)
    
    # Use Quarto video shortcode for Vimeo
    c(
      "",
      paste0("{{< video https://vimeo.com/", video_id, " >}}"),
      ""
    )
  } else {
    # For other videos, use direct video tag
    c("", paste0("<video controls src='", url, "' width='100%'></video>"), "")
  }
}

#' Generate table block markdown
#'
#' Internal function to generate markdown for table content blocks (data frames using knitr::kable)
#'
#' @param block Table content block
#' @return Character vector of markdown lines
#' @keywords internal
.generate_table_block <- function(block) {
  # Render the loaded table object directly
  table_var <- if (!is.null(block$table_var)) block$table_var else "data"
  
  lines <- c(
    "",
    "```{r}",
    "#| echo: false"
  )
  
  if (isTRUE(!is.null(block$caption) && nzchar(block$caption))) {
    lines <- c(lines, paste0("#| tbl-cap: \"", block$caption, "\""))
  }
  
  lines <- c(
    lines,
    "",
    paste0("knitr::kable(", table_var, ")"),
    "```",
    ""
  )
  
  lines
}

#' Generate gt table block markdown
#'
#' Internal function to generate markdown for gt table content blocks
#'
#' @param block GT table content block
#' @return Character vector of markdown lines
#' @keywords internal
.generate_gt_block <- function(block) {
  # Render the loaded gt object directly - ALL styling preserved!
  table_var <- if (!is.null(block$table_var)) block$table_var else "data"
  
  lines <- c(
    "",
    "```{r}",
    "#| echo: false",
    "#| results: asis"
  )
  
  if (isTRUE(!is.null(block$caption) && nzchar(block$caption))) {
    lines <- c(lines, paste0("#| tbl-cap: \"", block$caption, "\""))
  }
  
  lines <- c(
    lines,
    "",
    # Convert gt object to HTML and output directly
    paste0("cat(as.character(gt::as_raw_html(", table_var, ")))"),
    "```",
    ""
  )
  
  lines
}

#' Generate reactable block markdown
#'
#' Internal function to generate markdown for reactable content blocks
#'
#' @param block Reactable content block
#' @return Character vector of markdown lines
#' @keywords internal
.generate_reactable_block <- function(block) {
  # Render the loaded reactable object directly - ALL styling preserved!
  table_var <- if (!is.null(block$table_var)) block$table_var else "data"
  
  lines <- c(
    "",
    "```{r}",
    "#| echo: false",
    "",
    # Just output the htmlwidget object - it will render automatically
    table_var,
    "```",
    ""
  )
  
  lines
}

#' Generate DT datatable block markdown
#'
#' Internal function to generate markdown for DT::datatable content blocks
#'
#' @param block DT content block
#' @return Character vector of markdown lines
#' @keywords internal
.generate_DT_block <- function(block) {
  # Render the loaded DT object directly - ALL styling preserved!
  table_var <- if (!is.null(block$table_var)) block$table_var else "data"
  
  lines <- c(
    "",
    "```{r}",
    "#| echo: false",
    "",
    # Just output the htmlwidget object - it will render automatically
    table_var,
    "```",
    ""
  )
  
  lines
}

#' Generate spacer block markdown
#'
#' Internal function to generate markdown for spacer content blocks
#'
#' @param block Spacer content block
#' @return Character vector of markdown lines
#' @keywords internal
.generate_spacer_block <- function(block) {
  height <- block$height %||% "1rem"
  c("", paste0("<div style='height: ", height, ";'></div>"), "")
}

#' Generate HTML block markdown
#'
#' Internal function to generate markdown for raw HTML content blocks
#'
#' @param block HTML content block
#' @return Character vector of markdown lines
#' @keywords internal
.generate_html_block <- function(block) {
  c("", block$html, "")
}

#' Generate quote block markdown
#'
#' Internal function to generate markdown for blockquote content blocks
#'
#' @param block Quote content block
#' @return Character vector of markdown lines
#' @keywords internal
.generate_quote_block <- function(block) {
  lines <- c("", "> ", "> ")
  quote_lines <- strsplit(block$quote, "\n")[[1]]
  for (line in quote_lines) {
    lines <- c(lines, paste0("> ", line))
  }
  
  if (!is.null(block$attribution)) {
    lines <- c(lines, ">")
    if (!is.null(block$cite)) {
      lines <- c(lines, paste0("> — [", block$attribution, "](", block$cite, ")"))
    } else {
      lines <- c(lines, paste0("> — ", block$attribution))
    }
  }
  
  c(lines, "", "")
}

#' Generate badge block markdown
#'
#' Internal function to generate markdown for badge content blocks
#'
#' @param block Badge content block
#' @return Character vector of markdown lines
#' @keywords internal
.generate_badge_block <- function(block) {
  color_class <- switch(block$color,
    "success" = "badge-success",
    "warning" = "badge-warning",
    "danger" = "badge-danger",
    "info" = "badge-info",
    "primary" = "badge-primary",
    "secondary" = "badge-secondary",
    "badge-primary"  # default
  )
  
  badge_html <- paste0(
    "<span class='badge ", color_class, "'>",
    block$text,
    "</span>"
  )
  
  c("", badge_html, "")
}

#' Generate metric block markdown
#'
#' Internal function to generate markdown for metric/value box content blocks
#'
#' @param block Metric content block
#' @return Character vector of markdown lines
#' @keywords internal
.generate_metric_block <- function(block) {
  icon_html <- ""
  if (!is.null(block$icon)) {
    icon_html <- paste0("{{< iconify ", block$icon, " size=2em >}}")
  }
  
  color_style <- ""
  if (!is.null(block$color)) {
    color_style <- paste0(" style='border-left: 4px solid ", block$color, ";'")
  }
  
  subtitle_html <- ""
  if (!is.null(block$subtitle)) {
    subtitle_html <- paste0("<p class='text-muted small'>", block$subtitle, "</p>")
  }
  
  metric_html <- paste0(
    "<div class='card mb-3'", color_style, ">",
    "  <div class='card-body'>",
    "    <div class='d-flex justify-content-between align-items-start'>",
    "      <div>",
    "        <h6 class='card-subtitle mb-2 text-muted'>", block$title, "</h6>",
    "        <h2 class='card-title mb-1'>", block$value, "</h2>",
    "        ", subtitle_html, "  ",
    "      </div>",
    "      <div class='text-primary'>", icon_html, "</div>",
    "    </div>",
    "  </div>",
    "</div>"
  )
  
  c("", metric_html, "")
}

#' Generate value box block markdown
#'
#' Internal function to generate markdown for custom styled value boxes
#'
#' @param block Value box content block
#' @return Character vector of markdown lines
#' @keywords internal
.generate_value_box_block <- function(block) {
  # Generate R chunk that calls the render function
  lines <- c(
    "",
    "```{r}",
    "#| echo: false",
    "#| results: 'asis'",
    paste0("dashboardr::render_value_box("),
    paste0("  title = ", .serialize_arg(block$title), ","),
    paste0("  value = ", .serialize_arg(block$value), ","),
    paste0("  bg_color = ", .serialize_arg(block$bg_color), ","),
    paste0("  logo_url = ", .serialize_arg(block$logo_url), ","),
    paste0("  logo_text = ", .serialize_arg(block$logo_text)),
    ")",
    "```"
  )
  
  # Add collapsible description if provided
  if (isTRUE(!is.null(block$description) && nzchar(block$description))) {
    # Convert markdown to HTML using pandoc via commonmark
    description_text <- block$description
    
    # Simple markdown conversion for common patterns
    # Convert [text](url) to <a href="url">text</a>
    description_text <- gsub("\\[([^]]+)\\]\\(([^)]+)\\)", "<a href='\\2' target='_blank' rel='noopener'>\\1</a>", description_text)
    # Convert **text** to <strong>text</strong>
    description_text <- gsub("\\*\\*([^*]+)\\*\\*", "<strong>\\1</strong>", description_text)
    # Convert *text* to <em>text</em>
    description_text <- gsub("\\*([^*]+)\\*", "<em>\\1</em>", description_text)
    # Convert line breaks to <br>
    description_text <- gsub("\n", "<br>", description_text)
    
    description_html <- paste0(
      "<details style='background-color: #f8f9fa; border: 1px solid rgba(0, 0, 0, 0.08); border-radius: 8px; padding: 1rem; margin-top: 1rem;'>",
      "  <summary style='cursor: pointer; font-weight: 600; font-size: 0.9rem; user-select: none; list-style: none; display: flex; justify-content: space-between; align-items: center;'>",
      "    <span>", block$description_title, "</span>",
      "    <span class='expand-icon' style='font-size: 0.8rem; opacity: 0.5; transition: transform 0.3s ease, opacity 0.3s ease; transform: rotate(0deg);'>▼</span>",
      "  </summary>",
      "  <div style='margin-top: 0.75rem; padding-top: 0.75rem; border-top: 1px solid rgba(0, 0, 0, 0.1); font-size: 0.85rem;'>",
      "    ", description_text,
      "  </div>",
      "</details>"
    )
    lines <- c(lines, "", "```{=html}", description_html, "```")
  }
  
  c(lines, "")
}

#' Generate value box row block markdown
#'
#' Internal function to generate markdown for a row of value boxes
#'
#' @param block Value box row content block
#' @return Character vector of markdown lines
#' @keywords internal
.generate_value_box_row_block <- function(block) {
  # Generate R chunk that calls the render function with a list of boxes
  lines <- c(
    "",
    "```{r}",
    "#| echo: false",
    "#| results: 'asis'",
    "dashboardr::render_value_box_row(list("
  )
  
  # Add each box as a list element
  for (i in seq_along(block$boxes)) {
    box <- block$boxes[[i]]
    box_lines <- c(
      "  list(",
      paste0("    title = ", .serialize_arg(box$title), ","),
      paste0("    value = ", .serialize_arg(box$value), ","),
      paste0("    bg_color = ", .serialize_arg(box$bg_color), ","),
      paste0("    logo_url = ", .serialize_arg(box$logo_url), ","),
      paste0("    logo_text = ", .serialize_arg(box$logo_text)),
      if (i < length(block$boxes)) "  )," else "  )"
    )
    lines <- c(lines, box_lines)
  }
  
  lines <- c(lines, "))", "```", "")
  lines
}

#' Collect unique filters from all visualizations
#'
#' @param visualizations List of visualization specifications
#' @return List of unique filter formulas with generated names, including source dataset


#' Generate global setup chunk for QMD files
#'
#' Creates a comprehensive setup chunk that includes libraries, data loading,
#' filtered datasets, and global settings to avoid repetition in individual visualizations.
#'
#' @param page Page object containing data_path and visualizations
#' @return Character vector of setup chunk lines
#' @keywords internal
.generate_global_setup_chunk <- function(page) {
  lines <- c(
    "```{r setup}",
    "#| echo: false",
    "#| warning: false",
    "#| message: false",
    "#| error: false",
    "#| results: 'hide'",
    "",
    "# Load required libraries",
    "library(dashboardr)",
    "library(dplyr)",
    "library(highcharter)",
    "",
    "# Global chunk options",
    "knitr::opts_chunk$set(",
    "  echo = FALSE,",
    "  warning = FALSE,",
    "  message = FALSE,",
    "  error = FALSE,",
    "  fig.width = 12,",
    "  fig.height = 8,",
    "  dpi = 300",
    ")",
    ""
  )

  # Add data loading if data_path is present
  if (!is.null(page$data_path)) {
    # Check if data_path is a list (multi-dataset) regardless of is_multi_dataset flag
    if (is.list(page$data_path)) {
      # Multiple datasets
      lines <- c(lines, "# Load multiple datasets", "")
      
      for (dataset_name in names(page$data_path)) {
        data_file <- basename(page$data_path[[dataset_name]])
        lines <- c(lines,
          paste0("# Load ", dataset_name, " from ", data_file),
          paste0(dataset_name, " <- readRDS('", data_file, "')"),
          paste0("cat('", dataset_name, " loaded:', nrow(", dataset_name, "), 'rows,', ncol(", dataset_name, "), 'columns\\n')"),
          ""
        )
      }
    } else {
      # Single dataset (data_path is a string)
      data_file <- basename(page$data_path)
      lines <- c(lines,
        paste0("# Load data from ", data_file),
        paste0("data <- readRDS('", data_file, "')"),
        "",
        "# Data summary",
        "cat('Dataset loaded:', nrow(data), 'rows,', ncol(data), 'columns\\n')",
        ""
      )
    }
  }

  # Collect and create all filtered datasets
  if (isTRUE(!is.null(page$visualizations) && !is.null(page$data_path))) {
    filter_map <- .collect_unique_filters(page$visualizations)
    
    if (length(filter_map) > 0) {
      lines <- c(lines,
        "# Create filtered datasets",
        "# Each filter is applied once and reused across visualizations",
        ""
      )
      
      for (filter_info in filter_map) {
        filter_expr <- paste(filter_info$expr, collapse = " ")
        
        # Get source dataset - default to "data" if not specified
        if (isTRUE(!is.null(filter_info$source_dataset) && nzchar(filter_info$source_dataset))) {
          source_dataset <- filter_info$source_dataset
        } else {
          source_dataset <- "data"
        }
        
        lines <- c(lines,
          paste0(filter_info$name, " <- ", source_dataset, " %>% dplyr::filter(", filter_expr, ")")
        )
      }
      
      lines <- c(lines, "")
    }
  }
  
  # Load table objects from content blocks
  if (!is.null(page$content_blocks)) {
    table_blocks <- Filter(function(b) isTRUE(b$type %in% c("table", "gt", "reactable", "DT")) && !is.null(b$table_file), page$content_blocks)
    if (length(table_blocks) > 0) {
      lines <- c(lines, "# Load styled table objects", "")
      for (block in table_blocks) {
        if (isTRUE(!is.null(block$table_var) && !is.null(block$table_file))) {
          lines <- c(lines, paste0(block$table_var, " <- readRDS('", block$table_file, "')"))
        }
      }
      lines <- c(lines, "")
    }
  }

  lines <- c(lines, "```", "")
  lines
}

# ===================================================================
# Template Processing
# ===================================================================

#' Process template file with variable substitution
#'
#' Internal function that reads a template file and substitutes template variables
#' with provided parameter values.
#'
#' @param template_path Path to the template file
#' @param params Named list of parameters for substitution
#' @param output_dir Output directory (not used but kept for compatibility)
#' @return Character vector of processed template lines, or NULL if template not found
#' @keywords internal
.process_template <- function(template_path, params, output_dir) {
  if (is.null(template_path) || !file.exists(template_path)) {
    return(NULL)
  }

  content <- readLines(template_path, warn = FALSE)

  # Substitute template variables
  content <- .substitute_template_vars(content, params)

  content
}


.substitute_template_vars <- function(content, params) {
  for (param_name in names(params)) {
    pattern <- paste0("\\{\\{", param_name, "\\}\\}")
    replacement <- as.character(params[[param_name]])
    content <- gsub(pattern, replacement, content)
  }
  content
}


.process_viz_specs <- function(content, viz_specs) {
  if (is.null(viz_specs) || length(viz_specs) == 0) {
    return(content)
  }

  viz_placeholder <- "{{visualizations}}"

  if (any(grepl(viz_placeholder, content, fixed = TRUE))) {
    viz_content <- .generate_viz_from_specs(viz_specs)
    new_content <- character(0)
    for (line in content) {
      if (grepl(viz_placeholder, line, fixed = TRUE)) {
        new_content <- c(new_content, viz_content)
      } else {
        new_content <- c(new_content, line)
      }
    }
    content <- new_content
  }

  content
}

# ===================================================================
# Code Generation for Visualizations
# ===================================================================


