# =================================================================
# page_generation
# =================================================================


# Helper function to generate data loading code based on file type and location
# Supports: local RDS, local parquet, remote RDS (URL), remote parquet (URL)
.generate_data_load_code <- function(data_path, var_name = "data") {
  is_url <- grepl("^https?://", data_path)
  is_parquet <- grepl("\\.parquet$", data_path, ignore.case = TRUE)
  
  if (is_url && is_parquet) {
    # Remote parquet - arrow can read directly from URL
    paste0(var_name, " <- arrow::read_parquet('", data_path, "')")
  } else if (is_url) {
    # Remote RDS - use gzcon + url for compressed RDS files
    paste0(var_name, " <- readRDS(gzcon(url('", data_path, "')))")
  } else if (is_parquet) {
    # Local parquet
    paste0(var_name, " <- arrow::read_parquet('", basename(data_path), "')")
  } else {
    # Local RDS (original behavior)
    paste0(var_name, " <- readRDS('", basename(data_path), "')")
  }
}


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

  # Check if page has a sidebar - if so, use dashboard format
  has_page_sidebar <- !is.null(page$sidebar)
  if (!has_page_sidebar && !is.null(page$content_blocks)) {
    for (block in page$content_blocks) {
      if (is_content(block) && !is.null(block$sidebar)) {
        has_page_sidebar <- TRUE
        break
      }
    }
  }
  
  # Use dashboard format when sidebar is present, otherwise html
  page_format <- if (has_page_sidebar) "dashboard" else "html"

  content <- c(
    "---",
    paste0("title: \"", title_content, "\""),
    paste0("format: ", page_format),
    "---",
    "",
    "```{r, include=FALSE}",
    "# Initialize dashboardr page configuration (CSS/JS for charts)",
    "dashboardr::.page_config()",
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
  
  # Auto-enable inputs if needed (flag set by add_input())
  if (isTRUE(page$needs_inputs)) {
    args <- character(0)
    if (isTRUE(page$needs_linked_inputs)) args <- c(args, "linked = TRUE")
    if (isTRUE(page$needs_show_when)) args <- c(args, "show_when = TRUE")
    enable_call <- paste0("dashboardr::enable_inputs(", paste(args, collapse = ", "), ")")
    content <- c(content,
      "```{r, echo=FALSE, results='asis'}",
      enable_call,
      "```",
      ""
    )
  }
  # Show_when without inputs (e.g. conditional viz only)
  if (!isTRUE(page$needs_inputs) && isTRUE(page$needs_show_when)) {
    content <- c(content,
      "```{r, echo=FALSE, results='asis'}",
      "dashboardr::enable_show_when()",
      "```",
      ""
    )
  }

  # Enable chart export buttons if requested
  if (isTRUE(page$chart_export)) {
    content <- c(content,
      "```{r, echo=FALSE, results='asis'}",
      "# Enable chart export buttons (download as PNG/SVG/PDF/CSV)",
      "dashboardr::enable_chart_export()",
      "```",
      ""
    )
  }
  
  # Auto-enable sidebar styling if page has a sidebar
  # Check both page$sidebar and content_blocks for sidebar
  page_has_sidebar <- !is.null(page$sidebar)
  if (!page_has_sidebar && !is.null(page$content_blocks)) {
    for (block in page$content_blocks) {
      if (is_content(block) && !is.null(block$sidebar)) {
        page_has_sidebar <- TRUE
        break
      }
    }
  }
  
  if (page_has_sidebar) {
    content <- c(content,
      "```{r, echo=FALSE, results='asis'}",
      "dashboardr::enable_sidebar()",
      "```",
      ""
    )
  }

  # Add global setup chunk with libraries, data, and settings
  if (!is.null(page$data_path) || !is.null(page$visualizations) || !is.null(page$content_blocks)) {
    content <- c(content, .generate_global_setup_chunk(page))
  }
  
  # Embed full data for metric switching (AFTER setup chunk loads data)
  if (isTRUE(page$needs_metric_data) && !is.null(page$data_path)) {
    # Build time_var config if specified
    time_var_line <- ""
    if (!is.null(page$time_var) && nzchar(page$time_var)) {
      time_var_line <- paste0("cat(\"<script>window.dashboardrTimeVar = '", page$time_var, "';\")")
    } else {
      time_var_line <- "cat('<script>')"
    }
    
    content <- c(content,
      "```{r, echo=FALSE, results='asis'}",
      "# Embed full data for metric switching",
      time_var_line,
      "cat('window.dashboardrMetricData = ')",
      "cat(jsonlite::toJSON(data, dataframe = 'rows'))",
      "cat(';</script>')",
      "```",
      ""
    )
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


  # Check for sidebar content (from page, or from content_blocks list)
  sidebar <- page$sidebar
  
  # If not on page directly, check content_blocks (which is a list of content collections)
  if (is.null(sidebar) && !is.null(page$content_blocks)) {
    for (block in page$content_blocks) {
      if (is_content(block) && !is.null(block$sidebar)) {
        sidebar <- block$sidebar
        break
      }
    }
  }
  
  has_sidebar <- !is.null(sidebar)
  sidebar_position <- if (has_sidebar) (sidebar$position %||% "left") else "left"
  
  # Extract filter_vars from sidebar and content for cross-tab filtering
  page_filter_vars <- character(0)
  if (has_sidebar && !is.null(sidebar$blocks)) {
    for (block in sidebar$blocks) {
      if (!is.null(block$type) && block$type == "input" && !is.null(block$filter_var)) {
        page_filter_vars <- c(page_filter_vars, block$filter_var)
      }
    }
  }
  # Also check content_blocks for filter_vars
  if (!is.null(page$content_blocks)) {
    for (block in page$content_blocks) {
      if (is_content(block)) {
        block_filter_vars <- .extract_filter_vars(block)
        page_filter_vars <- c(page_filter_vars, block_filter_vars)
      }
    }
  }
  page_filter_vars <- unique(page_filter_vars)

  # In dashboard format (with sidebar), viz titles should use ### instead of ##
  # to stay within the Column
  viz_heading_level <- if (has_sidebar) 3 else 2
  
  # For left sidebar: output sidebar first, then ## Column marker
  if (has_sidebar && sidebar_position == "left") {
    content <- c(content, .generate_sidebar_block(sidebar, page))
    content <- c(content, "", "## Column", "")
  }
  
  # For right sidebar: output ## Column marker first (sidebar added at end)
  if (has_sidebar && sidebar_position == "right") {
    content <- c(content, "", "## Column", "")
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
      
      # If it's a content collection, handle it by processing each item IN ORDER
      if (is_coll) {
        # Process mixed collections (content + viz combined via + operator)
        # IMPORTANT: Preserve the order from the + operator!
        
        # Sort items by insertion index to preserve order
        items_with_idx <- block$items
        if (length(items_with_idx) > 1) {
          indices <- sapply(items_with_idx, function(x) x$.insertion_index %||% 999)
          items_with_idx <- items_with_idx[order(indices)]
        }
        
        # Group consecutive viz items together for proper tabgroup handling
        # but maintain overall order relative to other content
        i <- 1
        while (i <= length(items_with_idx)) {
          item <- items_with_idx[[i]]
          if (is.null(item)) {
            i <- i + 1
            next
          }
          
          item_type <- item$type %||% ""
          
          if (item_type == "viz" || item_type == "pagination") {
            # Collect consecutive viz/pagination items
            viz_items <- list(item)
            j <- i + 1
            while (j <= length(items_with_idx)) {
              next_item <- items_with_idx[[j]]
              if (is.null(next_item)) {
                j <- j + 1
                next
              }
              next_type <- next_item$type %||% ""
              if (next_type == "viz" || next_type == "pagination") {
                viz_items <- c(viz_items, list(next_item))
                j <- j + 1
              } else {
                break
              }
            }
            
            # Process this group of visualizations
            # Create a viz_collection for proper processing with tabgroups
            viz_coll <- structure(list(
              items = viz_items,
              defaults = block$defaults,
              tabgroup_labels = block$tabgroup_labels,
              shared_first_level = block$shared_first_level
            ), class = c("content_collection", "viz_collection"))
            
            # First process through viz_processing to handle tabgroup hierarchy
            # Pass page_filter_vars for cross-tab filtering support
            processed_specs <- .process_visualizations(viz_coll, page$data_path, 
                                                        filter_vars = page_filter_vars)
            
            # Then generate the markdown
            if (!is.null(processed_specs) && length(processed_specs) > 0) {
              viz_content <- .generate_viz_from_specs(processed_specs, 
                                                        page$lazy_load_charts %||% FALSE, 
                                                        page$lazy_load_tabs %||% FALSE,
                                                        heading_level = viz_heading_level)
              content <- c(content, viz_content)
            }
            i <- j
          } else {
            # Process single content item
            item_content <- switch(item_type,
              "text" = c("", item$content %||% item$text, ""),
              "image" = .generate_image_block(item),
              "callout" = .generate_callout_block(item),
              "divider" = .generate_divider_block(item),
              "code" = .generate_code_block(item),
              "card" = .generate_card_block(item),
              "accordion" = .generate_accordion_block(item),
              "iframe" = .generate_iframe_block(item),
              "video" = .generate_video_block(item),
              "table" = .generate_table_block(item),
              "gt" = .generate_gt_block(item),
              "reactable" = .generate_reactable_block(item),
              "DT" = .generate_DT_block(item),
              "hc" = .generate_hc_block(item),
              "spacer" = .generate_spacer_block(item),
              "html" = .generate_html_block(item),
              "quote" = .generate_quote_block(item),
              "badge" = .generate_badge_block(item),
              "metric" = .generate_metric_block(item),
              "value_box" = .generate_value_box_block(item),
              "value_box_row" = .generate_value_box_row_block(item),
              "input" = .generate_input_block(item, page),
              "input_row" = .generate_input_row_block(item, page),
              "modal" = .generate_modal_block(item),
              NULL
            )
            if (!is.null(item_content)) {
              content <- c(content, item_content)
            }
            i <- i + 1
          }
        }
        next
      }
      
      # Get block type safely
      block_type <- if (!is.null(block$type)) as.character(block$type)[1] else NULL
      if (is.null(block_type)) next
      
      # Dispatch to appropriate generator based on type
      block_content <- switch(block_type,
        "text" = c("", block$content %||% block$text, ""),
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
        "hc" = .generate_hc_block(block),
        "spacer" = .generate_spacer_block(block),
        "html" = .generate_html_block(block),
        "quote" = .generate_quote_block(block),
        "badge" = .generate_badge_block(block),
        "metric" = .generate_metric_block(block),
        "value_box" = .generate_value_box_block(block),
        "value_box_row" = .generate_value_box_row_block(block),
        "input" = .generate_input_block(block, page),
        "input_row" = .generate_input_row_block(block, page),
        "modal" = .generate_modal_block(block),
        NULL  # Unknown type - skip
      )
      
      if (!is.null(block_content)) {
        content <- c(content, block_content)
      }
    }
  }
  
  # Handle page$.items (from add_text.page_object, add_callout.page_object, etc.)
  # These are items added directly to a page_object via piping
  if (!is.null(page$.items) && length(page$.items) > 0) {
    for (item in page$.items) {
      if (is.null(item)) next
      if (!is.list(item)) next
      
      item_type <- item$type %||% ""
      
      item_content <- switch(item_type,
        "text" = c("", item$content %||% item$text, ""),  # Handle both $content and legacy $text
        "callout" = {
          # Convert add_callout format to content_block format
          callout_block <- list(
            type = "callout",
            callout_type = item$callout_type %||% "note",
            text = item$text,
            title = item$title
          )
          .generate_callout_block(callout_block)
        },
        "image" = .generate_image_block(item),
        "divider" = .generate_divider_block(item),
        "code" = .generate_code_block(item),
        "card" = .generate_card_block(item),
        "accordion" = .generate_accordion_block(item),
        "iframe" = .generate_iframe_block(item),
        "video" = .generate_video_block(item),
        "table" = .generate_table_block(item),
        "gt" = .generate_gt_block(item),
        "reactable" = .generate_reactable_block(item),
        "DT" = .generate_DT_block(item),
        "hc" = .generate_hc_block(item),
        "spacer" = .generate_spacer_block(item),
        "html" = .generate_html_block(item),
        "quote" = .generate_quote_block(item),
        "badge" = .generate_badge_block(item),
        "metric" = .generate_metric_block(item),
        "value_box" = .generate_value_box_block(item),
        "value_box_row" = .generate_value_box_row_block(item),
        "input" = .generate_input_block(item, page),
        "input_row" = .generate_input_row_block(item, page),
        "modal" = .generate_modal_block(item),
        NULL
      )
      
      if (!is.null(item_content)) {
        content <- c(content, item_content)
      }
    }
  }

  # Add visualizations (unless they're already embedded in content_blocks from + operator)
  if (!is.null(page$visualizations) && !isTRUE(page$viz_embedded_in_content)) {
    # Get lazy load settings
    lazy_load_charts <- page$lazy_load_charts %||% FALSE
    lazy_load_tabs <- page$lazy_load_tabs %||% FALSE
    
    # Add cross_tab_filter_vars to visualizations if filter_vars are available
    viz_specs <- page$visualizations
    if (length(page_filter_vars) > 0) {
      viz_specs <- lapply(viz_specs, function(spec) {
        if (is.null(spec$cross_tab_filter_vars)) {
          spec$cross_tab_filter_vars <- page_filter_vars
        }
        spec
      })
    }
    
    viz_content <- .generate_viz_from_specs(viz_specs, lazy_load_charts, lazy_load_tabs, heading_level = viz_heading_level)
    content <- c(content, viz_content)
  } else if (isTRUE(is.null(page$text) || !nzchar(page$text))) {
    # Check if there's any content from various sources
    has_content_blocks <- !is.null(page$content_blocks) && length(page$content_blocks) > 0
    has_page_items <- !is.null(page$.items) && length(page$.items) > 0
    if (!has_content_blocks && !has_page_items) {
      content <- c(content, "This page was generated without a template.")
    }
  }

  # For right sidebar: add sidebar at the end after all main content
  if (has_sidebar && sidebar_position == "right") {
    content <- c(content, .generate_sidebar_block(sidebar, page))
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
  style <- block$style

  iframe_tag <- paste0(
    "<iframe src='", block$url, "'",
    " width='", width, "'",
    " height='", height, "'",
    " frameborder='0'",
    " allowfullscreen",
    if (!is.null(style) && nzchar(style)) paste0(" style='", style, "'") else "",
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

#' Generate highcharter block markdown
#'
#' Internal function to generate markdown for custom highcharter content blocks
#'
#' @param block Highcharter content block
#' @return Character vector of markdown lines
#' @keywords internal
.generate_hc_block <- function(block) {
  # Render the saved highcharter object
  hc_var <- if (!is.null(block$hc_var)) block$hc_var else "hc_obj"
  
  # Only add fig-height if explicitly provided
  if (!is.null(block$height) && nzchar(block$height)) {
    height_line <- paste0("#| fig-height: ", gsub("px", "", block$height))
    lines <- c(
      "",
      "```{r}",
      "#| echo: false",
      height_line,
      "",
      hc_var,
      "```",
      ""
    )
  } else {
    # No height specified - let highcharter handle its own sizing
    lines <- c(
      "",
      "```{r}",
      "#| echo: false",
      "",
      hc_var,
      "```",
      ""
    )
  }
  
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
      lines <- c(lines, paste0("> \u2014 [", block$attribution, "](", block$cite, ")"))
    } else {
      lines <- c(lines, paste0("> \u2014 ", block$attribution))
    }
  }
  
  c(lines, "", "")
}

#' Generate modal block markdown
#'
#' Internal function to generate markdown for modal content blocks
#'
#' @param block Modal content block with modal_id and html_content
#' @return Character vector of markdown lines
#' @keywords internal
.generate_modal_block <- function(block) {
  modal_id <- block$modal_id
  html_content <- block$html_content
  
  # Escape single quotes in HTML content
  escaped_html <- gsub("'", "\\\\'", html_content)
  
  c(
    "",
    "```{r, echo=FALSE, results='asis'}",
    paste0("dashboardr::modal_content("),
    paste0("  modal_id = '", modal_id, "',"),
    paste0("  text = '", escaped_html, "'"),
    ")",
    "```",
    ""
  )
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
  
  # Wrap HTML in Quarto HTML block so it renders properly
  c("", "```{=html}", metric_html, "```", "")
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
      "    <span class='expand-icon' style='font-size: 0.8rem; opacity: 0.5; transition: transform 0.3s ease, opacity 0.3s ease; transform: rotate(0deg);'>\u25bc</span>",
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

#' Generate input block markdown
#'
#' Internal function to generate markdown for input filter widgets
#'
#' @param block Input content block
#' @param page Page object (for data access)
#' @return Character vector of markdown lines
#' @keywords internal
.generate_input_block <- function(block, page = NULL, next_block = NULL) {
  # Generate R chunk that renders the input widget
  # Note: margin parameters (mt, mr, mb, ml) are only used in render_input_row, not render_input
  # Use input_type if available (sidebar inputs), otherwise fall back to type
  input_widget_type <- block$input_type %||% block$type

  # Linked inputs: if next block is a linked child of this block, pass linked_child_id and options_by_parent
  linked_child_id <- NULL
  options_by_parent <- NULL
  if (!is.null(next_block) &&
      identical(next_block$type, "input") &&
      identical(next_block$.linked_parent_id, block$input_id) &&
      !is.null(next_block$.options_by_parent)) {
    linked_child_id <- next_block$input_id
    options_by_parent <- next_block$.options_by_parent
  }

  lines <- c(
    "",
    "```{r}",
    "#| echo: false",
    "#| results: 'asis'",
    "dashboardr::render_input(",
    paste0("  input_id = ", .serialize_arg(block$input_id), ","),
    paste0("  label = ", .serialize_arg(block$label), ","),
    paste0("  type = ", .serialize_arg(input_widget_type), ","),
    paste0("  filter_var = ", .serialize_arg(block$filter_var), ","),
    paste0("  options = ", .serialize_arg(block$options), ","),
    paste0("  options_from = ", .serialize_arg(block$options_from), ","),
    paste0("  default_selected = ", .serialize_arg(block$default_selected), ","),
    paste0("  placeholder = ", .serialize_arg(block$placeholder), ","),
    paste0("  width = ", .serialize_arg(block$width), ","),
    paste0("  min = ", .serialize_arg(block$min %||% 0), ","),
    paste0("  max = ", .serialize_arg(block$max %||% 100), ","),
    paste0("  step = ", .serialize_arg(block$step %||% 1), ","),
    paste0("  value = ", .serialize_arg(block$value), ","),
    paste0("  show_value = ", .serialize_arg(block$show_value %||% TRUE), ","),
    paste0("  inline = ", .serialize_arg(block$inline %||% TRUE), ","),
    paste0("  stacked = ", .serialize_arg(block$stacked %||% FALSE), ","),
    paste0("  stacked_align = ", .serialize_arg(block$stacked_align %||% "center"), ","),
    paste0("  group_align = ", .serialize_arg(block$group_align %||% "left"), ","),
    paste0("  ncol = ", .serialize_arg(block$ncol), ","),
    paste0("  nrow = ", .serialize_arg(block$nrow), ","),
    paste0("  toggle_series = ", .serialize_arg(block$toggle_series), ","),
    paste0("  override = ", .serialize_arg(block$override %||% FALSE), ","),
    paste0("  labels = ", .serialize_arg(block$labels), ","),
    paste0("  size = ", .serialize_arg(block$size %||% "md"), ","),
    paste0("  help = ", .serialize_arg(block$help), ","),
    paste0("  disabled = ", .serialize_arg(block$disabled %||% FALSE))
  )
  if (!is.null(linked_child_id) && !is.null(options_by_parent)) {
    lines <- c(lines,
      paste0("  , linked_child_id = ", .serialize_arg(linked_child_id)),
      paste0("  , options_by_parent = ", .serialize_arg(options_by_parent))
    )
  }
  lines <- c(lines,
    ")",
    "```",
    ""
  )

  lines
}

#' Generate input row block markdown
#'
#' Internal function to generate markdown for a row of input widgets
#'
#' @param block Input row content block
#' @param page Page object (for data access)
#' @return Character vector of markdown lines
#' @keywords internal
.generate_input_row_block <- function(block, page = NULL) {
  # Get style and align parameters
  style <- block$style %||% "boxed"
  align <- block$align %||% "center"
  
  # Generate R chunk that renders a row of inputs
  lines <- c(
    "",
    "```{r}",
    "#| echo: false",
    "#| results: 'asis'",
    paste0("dashboardr::render_input_row(list(")
  )
  
  # Add each input as a list element
  for (i in seq_along(block$inputs)) {
    input <- block$inputs[[i]]
    input_lines <- c(
      "  list(",
      paste0("    input_id = ", .serialize_arg(input$input_id), ","),
      paste0("    label = ", .serialize_arg(input$label), ","),
      paste0("    type = ", .serialize_arg(input$type), ","),
      paste0("    filter_var = ", .serialize_arg(input$filter_var), ","),
      paste0("    options = ", .serialize_arg(input$options), ","),
      paste0("    options_from = ", .serialize_arg(input$options_from), ","),
      paste0("    default_selected = ", .serialize_arg(input$default_selected), ","),
      paste0("    placeholder = ", .serialize_arg(input$placeholder), ","),
      paste0("    width = ", .serialize_arg(input$width), ","),
      paste0("    min = ", .serialize_arg(input$min %||% 0), ","),
      paste0("    max = ", .serialize_arg(input$max %||% 100), ","),
      paste0("    step = ", .serialize_arg(input$step %||% 1), ","),
      paste0("    value = ", .serialize_arg(input$value), ","),
      paste0("    show_value = ", .serialize_arg(input$show_value %||% TRUE), ","),
      paste0("    inline = ", .serialize_arg(input$inline %||% TRUE), ","),
      paste0("    stacked = ", .serialize_arg(input$stacked %||% FALSE), ","),
      paste0("    stacked_align = ", .serialize_arg(input$stacked_align %||% "center"), ","),
      paste0("    group_align = ", .serialize_arg(input$group_align %||% "left"), ","),
      paste0("    ncol = ", .serialize_arg(input$ncol), ","),
      paste0("    nrow = ", .serialize_arg(input$nrow), ","),
      paste0("    toggle_series = ", .serialize_arg(input$toggle_series), ","),
      paste0("    override = ", .serialize_arg(input$override %||% FALSE), ","),
      paste0("    labels = ", .serialize_arg(input$labels), ","),
      paste0("    size = ", .serialize_arg(input$size %||% "md"), ","),
      paste0("    help = ", .serialize_arg(input$help), ","),
      paste0("    disabled = ", .serialize_arg(input$disabled %||% FALSE), ","),
      paste0("    mt = ", .serialize_arg(input$mt), ","),
      paste0("    mr = ", .serialize_arg(input$mr), ","),
      paste0("    mb = ", .serialize_arg(input$mb), ","),
      paste0("    ml = ", .serialize_arg(input$ml)),
      if (i < length(block$inputs)) "  )," else "  )"
    )
    lines <- c(lines, input_lines)
  }
  
  # Close the list and add style/align parameters
  lines <- c(lines, 
    paste0("), style = \"", style, "\", align = \"", align, "\")"),
    "```", 
    ""
  )
  lines
}

#' Internal function to generate markdown for a sidebar
#'
#' @param sidebar Sidebar content block with blocks, width, position, title, and styling
#' @param page Page object (for data access)
#' @return Character vector of markdown lines
#' @keywords internal
.generate_sidebar_block <- function(sidebar, page = NULL) {
  lines <- c()
  
  # Build sidebar header with attributes
  attrs <- c(".sidebar")
  
  # Width
  if (!is.null(sidebar$width) && nzchar(sidebar$width)) {
    attrs <- c(attrs, paste0('width="', sidebar$width, '"'))
  }
  
  # Open state (Quarto uses 'open' attribute)
  if (isFALSE(sidebar$open)) {
    attrs <- c(attrs, 'open="false"')
  }
  
  # Additional classes
  if (!is.null(sidebar$class) && nzchar(sidebar$class)) {
    attrs <- c(attrs, paste0('.', gsub(" ", " .", sidebar$class)))
  }
  
  # Build the header line
  header_line <- paste0("## {", paste(attrs, collapse = " "), "}")
  lines <- c(lines, "", header_line, "")
  

  # Build custom inline styles only if user specified custom values
  custom_styles <- c()
  
  if (!is.null(sidebar$background) && nzchar(sidebar$background)) {
    custom_styles <- c(custom_styles, paste0("background-color: ", sidebar$background))
  }
  if (!is.null(sidebar$padding) && nzchar(sidebar$padding)) {
    custom_styles <- c(custom_styles, paste0("padding: ", sidebar$padding))
  }
  if (!is.null(sidebar$border)) {
    if (isFALSE(sidebar$border)) {
      custom_styles <- c(custom_styles, "border-right: none", "box-shadow: none")
    } else if (is.character(sidebar$border)) {
      custom_styles <- c(custom_styles, paste0("border-right: ", sidebar$border))
    }
  }
  
  # Only add inline style block if user specified custom styles
  if (length(custom_styles) > 0) {
    style_css <- paste(custom_styles, collapse = "; ")
    lines <- c(lines,
      "",
      "```{r, echo=FALSE, results='asis'}",
      paste0("cat('<style>.sidebar { ", style_css, "; }</style>')"),
      "```",
      ""
    )
  }
  
  # Add title if provided
  if (!is.null(sidebar$title) && nzchar(sidebar$title)) {
    lines <- c(lines, paste0("### ", sidebar$title), "")
  }
  
  # Generate content for each block in the sidebar
  for (i in seq_along(sidebar$blocks)) {
    block <- sidebar$blocks[[i]]
    next_block <- if (i < length(sidebar$blocks)) sidebar$blocks[[i + 1]] else NULL
    block_type <- block$type %||% ""
    
    block_content <- switch(block_type,
      "text" = c("", block$content, ""),
      "input" = .generate_input_block(block, page, next_block = next_block),
      "input_row" = .generate_input_row_block(block, page),
      "image" = .generate_image_block(block),
      "badge" = .generate_badge_block(block),
      "metric" = .generate_metric_block(block),
      "divider" = .generate_divider_block(block),
      "spacer" = .generate_spacer_block(block),
      "html" = .generate_html_block(block),
      "callout" = .generate_callout_block(block),
      "accordion" = .generate_accordion_block(block),
      "card" = .generate_card_block(block),
      NULL
    )
    
    if (!is.null(block_content)) {
      lines <- c(lines, block_content)
    }
  }
  
  lines
}

#' Parse show_when formula into JSON condition for data-show-when attribute
#' @param formula A one-sided formula (e.g. ~ time_period == "Over Time")
#' @return JSON string, or NULL if formula is NULL
#' @keywords internal
.parse_show_when <- function(formula) {
  if (is.null(formula)) return(NULL)
  if (!inherits(formula, "formula")) {
    stop("show_when must be a formula (use ~ prefix)", call. = FALSE)
  }
  expr <- rlang::f_rhs(formula)
  condition <- .expr_to_condition(expr)
  jsonlite::toJSON(condition, auto_unbox = TRUE)
}

#' Convert R expression to condition list for show_when (eq, neq, in, and, or)
#' @param expr Unevaluated expression from formula RHS
#' @return List structure for JSON serialization
#' @keywords internal
.expr_to_condition <- function(expr) {
  if (!is.call(expr)) {
    stop("Invalid show_when expression", call. = FALSE)
  }
  op <- as.character(expr[[1]])
  if (op == "==") {
    list(var = as.character(expr[[2]]), op = "eq", val = eval(expr[[3]], envir = baseenv()))
  } else if (op == "!=") {
    list(var = as.character(expr[[2]]), op = "neq", val = eval(expr[[3]], envir = baseenv()))
  } else if (op == "%in%") {
    list(var = as.character(expr[[2]]), op = "in", val = eval(expr[[3]], envir = baseenv()))
  } else if (op == "&" || identical(op, "&&")) {
    list(op = "and", conditions = list(
      .expr_to_condition(expr[[2]]),
      .expr_to_condition(expr[[3]])
    ))
  } else if (op == "|" || identical(op, "||")) {
    list(op = "or", conditions = list(
      .expr_to_condition(expr[[2]]),
      .expr_to_condition(expr[[3]])
    ))
  } else if (op == ">") {
    list(var = as.character(expr[[2]]), op = "gt", val = eval(expr[[3]], envir = baseenv()))
  } else if (op == "<") {
    list(var = as.character(expr[[2]]), op = "lt", val = eval(expr[[3]], envir = baseenv()))
  } else if (op == ">=") {
    list(var = as.character(expr[[2]]), op = "gte", val = eval(expr[[3]], envir = baseenv()))
  } else if (op == "<=") {
    list(var = as.character(expr[[2]]), op = "lte", val = eval(expr[[3]], envir = baseenv()))
  } else if (op == "!") {
    # Negate the inner condition
    inner <- .expr_to_condition(expr[[2]])
    if (inner$op == "eq") {
      inner$op <- "neq"
    } else if (inner$op == "neq") {
      inner$op <- "eq"
    } else {
      # Wrap in a NOT-like construct using the "not" operator
      inner <- list(op = "not", condition = inner)
    }
    inner
  } else {
    stop("Unsupported operator in show_when: ", op, call. = FALSE)
  }
}

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
    "# Load dashboardr (includes dplyr, highcharter as dependencies)",
    "library(dashboardr)",
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

  # Ensure show_when helpers are available even if installed package version
  # predates their addition (Quarto renders in a fresh R process)
  if (isTRUE(page$needs_show_when)) {
    lines <- c(lines,
      "# Conditional-visibility helpers (fallback for older package versions)",
      "if (!exists('show_when_open', mode = 'function')) {",
      "  show_when_open  <- function(j) cat(paste0('<div class=\"viz-show-when\" data-show-when=\\'', j, '\\'>\\n'))",
      "  show_when_close <- function()  cat('</div>\\n')",
      "}",
      ""
    )
  }

  # Add data loading if data_path is present
  if (!is.null(page$data_path)) {
    # Check if data_path is a list (multi-dataset) regardless of is_multi_dataset flag
    if (is.list(page$data_path)) {
      # Multiple datasets
      lines <- c(lines, "# Load multiple datasets", "")
      
      for (dataset_name in names(page$data_path)) {
        data_path <- page$data_path[[dataset_name]]
        load_code <- .generate_data_load_code(data_path, dataset_name)
        lines <- c(lines,
          paste0("# Load ", dataset_name),
          load_code,
          paste0("cat('", dataset_name, " loaded:', nrow(", dataset_name, "), 'rows,', ncol(", dataset_name, "), 'columns\\n')"),
          ""
        )
      }
    } else {
      # Single dataset (data_path is a string)
      load_code <- .generate_data_load_code(page$data_path, "data")
      lines <- c(lines,
        "# Load data",
        load_code,
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
        
        # Apply haven conversion before filtering using dashboardr's internal function
        lines <- c(lines,
          paste0(filter_info$name, " <- dashboardr::.convert_haven(", source_dataset, ") %>% dplyr::filter(", filter_expr, ")")
        )
      }
      
      lines <- c(lines, "")
    }
  }
  
  # Load table objects from content blocks
  # This handles both direct content_block items and items nested inside content collections
  if (!is.null(page$content_blocks)) {
    # Helper to collect all blocks (direct and nested in content collections)
    collect_blocks <- function(blocks, filter_fn) {
      result <- list()
      for (block in blocks) {
        if (is_content(block) && !is.null(block$items)) {
          # Content collection - check items
          for (item in block$items) {
            if (filter_fn(item)) {
              result <- c(result, list(item))
            }
          }
        } else if (filter_fn(block)) {
          result <- c(result, list(block))
        }
      }
      result
    }
    
    table_blocks <- collect_blocks(page$content_blocks, function(b) {
      isTRUE(b$type %in% c("table", "gt", "reactable", "DT")) && !is.null(b$table_file)
    })
    if (length(table_blocks) > 0) {
      lines <- c(lines, "# Load styled table objects", "")
      for (block in table_blocks) {
        if (isTRUE(!is.null(block$table_var) && !is.null(block$table_file))) {
          lines <- c(lines, paste0(block$table_var, " <- readRDS('", block$table_file, "')"))
        }
      }
      lines <- c(lines, "")
    }
    
    # Load highcharter objects from content blocks
    hc_blocks <- collect_blocks(page$content_blocks, function(b) {
      isTRUE(b$type == "hc") && !is.null(b$hc_file)
    })
    if (length(hc_blocks) > 0) {
      lines <- c(lines, "# Load custom highcharter charts", "")
      for (block in hc_blocks) {
        if (isTRUE(!is.null(block$hc_var) && !is.null(block$hc_file))) {
          lines <- c(lines, paste0(block$hc_var, " <- readRDS('", block$hc_file, "')"))
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


