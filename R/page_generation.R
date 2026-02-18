# =================================================================
# page_generation
# =================================================================


# Helper function to generate data loading code based on file type and location
# Supports: local RDS, local parquet, remote RDS (URL), remote parquet (URL)
.generate_data_load_code <- function(data_path, var_name = "data") {
  bundle_ref <- .parse_rds_bundle_ref(data_path)
  if (!is.null(bundle_ref)) {
    bundle_file <- gsub("'", "\\\\'", basename(bundle_ref$bundle_file), fixed = TRUE)
    bundle_key <- gsub("'", "\\\\'", bundle_ref$bundle_key, fixed = TRUE)
    return(c(
      "if (!exists('.dashboardr_bundle_cache', inherits = FALSE)) .dashboardr_bundle_cache <- list()",
      paste0("if (is.null(.dashboardr_bundle_cache[['", bundle_file, "']])) .dashboardr_bundle_cache[['", bundle_file, "']] <- readRDS('", bundle_file, "')"),
      paste0("if (!('", bundle_key, "' %in% names(.dashboardr_bundle_cache[['", bundle_file, "']]))) stop(\"Bundle key '", bundle_key, "' not found in ", bundle_file, "\", call. = FALSE)"),
      paste0(var_name, " <- .dashboardr_bundle_cache[['", bundle_file, "']][['", bundle_key, "']]")
    ))
  }

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
  # For pageless dashboards (name = ".pageless"), use empty title
  display_name <- if (isFALSE(page$show_in_nav)) "" else page$name
  title_content <- display_name
  if (!is.null(page$icon) && nzchar(display_name)) {
    icon_shortcode <- if (grepl("{{< iconify", page$icon, fixed = TRUE)) {
      page$icon
    } else {
      icon(page$icon)
    }
    title_content <- paste0(icon_shortcode, " ", display_name)
  }

  # Check if page has a sidebar
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
  # (Sidebar pages need dashboard format for proper layout with ## Column markers)
  page_format <- if (has_page_sidebar) "dashboard" else "html"

  # Detect sidebar early so we can include it in .page_config()
  page_has_sidebar <- !is.null(page$sidebar)
  if (!page_has_sidebar && !is.null(page$content_blocks)) {
    for (block in page$content_blocks) {
      if (is_content(block) && !is.null(block$sidebar)) {
        page_has_sidebar <- TRUE
        break
      }
    }
  }

  # Build .page_config() arguments — one call for setup + all dependencies
  cfg_args <- "accessibility = TRUE"
  if (isTRUE(page$needs_modals))         cfg_args <- c(cfg_args, "modals = TRUE")
  if (isTRUE(page$needs_inputs)) {
    cfg_args <- c(cfg_args, "inputs = TRUE")
    if (isTRUE(page$needs_linked_inputs)) cfg_args <- c(cfg_args, "linked = TRUE")
    if (isTRUE(page$needs_show_when))     cfg_args <- c(cfg_args, "show_when = TRUE")
    if (isTRUE(page$url_params))          cfg_args <- c(cfg_args, "url_params = TRUE")
  } else if (isTRUE(page$needs_show_when)) {
    cfg_args <- c(cfg_args, "show_when = TRUE")
  }
  if (isTRUE(page$chart_export))          cfg_args <- c(cfg_args, "chart_export = TRUE")
  if (page_has_sidebar)                   cfg_args <- c(cfg_args, "sidebar = TRUE")
  if (isTRUE(.dashboardr_pkg_env$deferred_charts)) cfg_args <- c(cfg_args, "deferred_charts = TRUE")

  # Pass optimization settings so they're available in the Quarto child R process
  ct_mode <- .dashboardr_pkg_env$cross_tab_data_mode %||% "inline"
  if (!identical(ct_mode, "inline")) {
    cfg_args <- c(cfg_args, paste0("cross_tab_data_mode = \"", ct_mode, "\""))
    ct_dir <- .dashboardr_pkg_env$cross_tab_output_dir
    if (!is.null(ct_dir)) {
      cfg_args <- c(cfg_args, paste0("cross_tab_output_dir = \"", gsub("\\\\", "/", ct_dir), "\""))
    }
  }
  mcs <- .dashboardr_pkg_env$min_cell_size %||% 0L
  if (mcs > 0L) {
    cfg_args <- c(cfg_args, paste0("min_cell_size = ", mcs, "L"))
  }
  if (isTRUE(.dashboardr_pkg_env$deferred_charts)) {
    ch_dir <- .dashboardr_pkg_env$charts_output_dir
    if (!is.null(ch_dir)) {
      cfg_args <- c(cfg_args, paste0("charts_output_dir = \"", gsub("\\\\", "/", ch_dir), "\""))
    }
  }

  # Add page-specific cross-tab prefix to prevent ID collisions across pages
  page_slug <- page$slug %||% tolower(gsub("[^a-zA-Z0-9]+", "_", page$name %||% "page"))
  page_slug <- gsub("^_|_$", "", page_slug)  # trim leading/trailing underscores
  if (nzchar(page_slug) && page_slug != "_pageless") {
    cfg_args <- c(cfg_args, paste0("crosstab_prefix = \"", page_slug, "\""))
  }

  config_call <- paste0("dashboardr::.page_config(", paste(cfg_args, collapse = ", "), ")")

  content <- c(
    "---",
    paste0("title: \"", title_content, "\""),
    paste0("format: ", page_format),
    "---",
    "",
    "```{r, echo=FALSE, results='asis', message=FALSE, warning=FALSE}",
    config_call,
    "```",
    ""
  )

  # Add custom text content if provided
  if (isTRUE(!is.null(page$text) && nzchar(page$text))) {
    content <- c(content, page$text, "")
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

  # Enable runtime debug hooks for input/show_when/chart auditing when lazy_debug is set.
  # This is intentionally independent of lazy loading so maintainers can inspect
  # input/filter state transitions on any page.
  if (isTRUE(page$lazy_debug)) {
    content <- c(
      content,
      "```{r, echo=FALSE, results='asis'}",
      "cat(\"<script>window.DASHBOARDR_DEBUG = true; window.dashboardrDebug = true;</script>\")",
      "```",
      ""
    )
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
    page_name <- page$name %||% page$title %||% "<unnamed page>"
    for (i in seq_along(page$content_blocks)) {
      block <- page$content_blocks[[i]]
      if (is_content(block)) {
        block_filter_vars <- tryCatch(
          .extract_filter_vars(block),
          error = function(e) {
            stop(
              "Failed to extract filter variables on page '", page_name,
              "' from content block #", i, ": ", conditionMessage(e),
              call. = FALSE
            )
          }
        )
        page_filter_vars <- c(page_filter_vars, block_filter_vars)
      }
    }
  }
  page_filter_vars <- unique(page_filter_vars)

  # In dashboard format (with sidebar), we use ### Row containers and
  # viz titles use #### to stay within the Row/Column hierarchy:
  #   ## Column (main content)  →  ### Row  →  #### Card Title
  # Without sidebar (html format), viz titles use ## as before.
  viz_heading_level <- if (has_sidebar) 4 else 2
  use_dashboard_layout <- has_sidebar
  has_manual_layout <- .page_has_manual_layout(page)
  needs_auto_main_column <- has_sidebar && !has_manual_layout
  
  # For left sidebar: output sidebar first, then ## Column marker
  if (has_sidebar && sidebar_position == "left") {
    content <- c(content, .generate_sidebar_block(sidebar, page))
    if (needs_auto_main_column) {
      content <- c(content, "", "## Column", "")
    }
  }

  # For right sidebar: output ## Column marker first (sidebar added at end)
  if (needs_auto_main_column && sidebar_position == "right") {
    content <- c(content, "", "## Column", "")
  }

  # Main content landmark (id + role="main") is added by accessibility.js at runtime
  # to avoid a wrapping div that breaks Quarto's dashboard grid structure.

  # Track content length after ## Column so we can wrap loose content in ### Row
  # when in dashboard layout mode (prevents Quarto from creating implicit grid cells
  # that squish the layout)
  content_len_after_column <- length(content)

  # Add content blocks (text, images, and other content types) before visualizations
  if (!is.null(page$content_blocks)) {
    # Pre-process: group consecutive standalone content_blocks with tabgroups
    # This enables tabgroup support for standalone blocks (not inside a collection)
    content_blocks_processed <- .preprocess_content_blocks_tabgroups(
      page$content_blocks, page, page_filter_vars, viz_heading_level,
      use_dashboard_layout
    )

    for (block in content_blocks_processed) {
      # Skip NULL blocks
      if (is.null(block)) next

      # Skip non-list blocks
      if (!is.list(block)) next

      # Check if this is a pre-processed tabset container
      if (!is.null(block$type) && block$type == "content_tabset") {
        ctx_label <- paste0("page '", page$name %||% "<unnamed>", "'")
        tab_content <- .generate_content_tabset(
          tabset_spec = block,
          page = page,
          page_filter_vars = page_filter_vars,
          viz_heading_level = viz_heading_level,
          dashboard_layout = use_dashboard_layout,
          context_label = ctx_label
        )
        if (!is.null(tab_content)) {
          content <- c(content, tab_content)
        }
        next
      }

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
            page_name <- page$name %||% page$title %||% "<unnamed page>"
            processed_specs <- .process_visualizations(viz_coll, page$data_path, 
                                                        filter_vars = page_filter_vars,
                                                        context_label = paste0("page '", page_name, "'"))
            
            # Inject page-level backend into processed specs
            page_backend <- page$backend %||% "highcharter"
            if (page_backend != "highcharter" && !is.null(processed_specs)) {
              processed_specs <- lapply(processed_specs, function(spec) {
                if (is.null(spec$backend)) spec$backend <- page_backend
                # Also inject into nested_children if present
                if (!is.null(spec$nested_children)) {
                  spec$nested_children <- lapply(spec$nested_children, function(child) {
                    if (is.null(child$backend)) child$backend <- page_backend
                    child
                  })
                }
                spec
              })
            }

            # Then generate the markdown
            if (!is.null(processed_specs) && length(processed_specs) > 0) {
              viz_content <- .generate_viz_from_specs(processed_specs,
                                                        page$lazy_load_charts %||% FALSE,
                                                        page$lazy_load_tabs %||% FALSE,
                                                        heading_level = viz_heading_level,
                                                        dashboard_layout = use_dashboard_layout,
                                                        contextual_viz_errors = page$contextual_viz_errors %||% FALSE)
              content <- c(content, viz_content)
            }
            i <- j
          } else {
            # Collect consecutive non-viz content items for tabgroup processing
            content_items <- list(item)
            j <- i + 1
            while (j <= length(items_with_idx)) {
              next_item <- items_with_idx[[j]]
              if (is.null(next_item)) {
                j <- j + 1
                next
              }
              next_type <- next_item$type %||% ""
              if (next_type != "viz" && next_type != "pagination") {
                content_items <- c(content_items, list(next_item))
                j <- j + 1
              } else {
                break
              }
            }

            # In dashboard layout, check if viz items follow these content items.
            # If so, wrap content in ### Row to prevent Quarto creating implicit
            # grid cells that squish the layout.
            has_following_viz <- FALSE
            if (use_dashboard_layout && j <= length(items_with_idx)) {
              for (k in j:length(items_with_idx)) {
                fv_item <- items_with_idx[[k]]
                if (!is.null(fv_item)) {
                  fv_type <- fv_item$type %||% ""
                  if (fv_type == "viz" || fv_type == "pagination") {
                    has_following_viz <- TRUE
                    break
                  }
                }
              }
            }
            # Skip row wrapper when content items include layout containers
            # (layout_column/layout_row) that already manage their own grid structure.
            has_layout_container <- any(vapply(content_items, function(ci) {
              (ci$type %||% "") %in% c("layout_column", "layout_row")
            }, logical(1)))
            if (has_following_viz && !has_layout_container) {
              content <- c(content, "", "### Row {height=\"auto\"}", "")
            }

            # Process through content tabgroup handler
            ctx_label <- paste0("page '", page$name %||% "<unnamed>", "'")
            processed_content <- .process_content_tabgroups(content_items)
            for (proc_item in processed_content) {
              if (!is.null(proc_item$type) && proc_item$type == "content_tabset") {
                tab_content <- .generate_content_tabset(
                  tabset_spec = proc_item,
                  page = page,
                  page_filter_vars = page_filter_vars,
                  viz_heading_level = viz_heading_level,
                  dashboard_layout = use_dashboard_layout,
                  context_label = ctx_label
                )
                if (!is.null(tab_content)) {
                  content <- c(content, tab_content)
                }
              } else {
                item_content <- .generate_page_item_content(
                  item = proc_item,
                  page = page,
                  page_filter_vars = page_filter_vars,
                  viz_heading_level = viz_heading_level,
                  dashboard_layout = use_dashboard_layout,
                  context_label = ctx_label
                )
                if (!is.null(item_content)) {
                  content <- c(content, item_content)
                }
              }
            }
            i <- j
          }
        }
        next
      }
      
      # Get block type safely
      block_type <- if (!is.null(block$type)) as.character(block$type)[1] else NULL
      if (is.null(block_type)) next
      
      block_content <- .generate_page_item_content(
        item = block,
        page = page,
        page_filter_vars = page_filter_vars,
        viz_heading_level = viz_heading_level,
        dashboard_layout = use_dashboard_layout,
        context_label = paste0("page '", page$name %||% "<unnamed>", "'")
      )
      if (!is.null(block_content)) {
        content <- c(content, block_content)
      }
    }
  }
  
  # Handle page$.items (from add_text.page_object, add_callout.page_object, etc.)
  # These are items added directly to a page_object via piping
  # Pre-process to group items with tabgroups into tabset containers
  if (!is.null(page$.items) && length(page$.items) > 0) {
    processed_items <- .process_content_tabgroups(page$.items)
    ctx_label <- paste0("page '", page$name %||% "<unnamed>", "'")

    for (item in processed_items) {
      if (is.null(item)) next
      if (!is.list(item)) next

      if (!is.null(item$type) && item$type == "content_tabset") {
        # Render tabset
        tab_content <- .generate_content_tabset(
          tabset_spec = item,
          page = page,
          page_filter_vars = page_filter_vars,
          viz_heading_level = viz_heading_level,
          dashboard_layout = use_dashboard_layout,
          context_label = ctx_label
        )
        if (!is.null(tab_content)) {
          content <- c(content, tab_content)
        }
      } else {
        # Regular item
        item_content <- .generate_page_item_content(
          item = item,
          page = page,
          page_filter_vars = page_filter_vars,
          viz_heading_level = viz_heading_level,
          dashboard_layout = use_dashboard_layout,
          context_label = ctx_label
        )
        if (!is.null(item_content)) {
          content <- c(content, item_content)
        }
      }
    }
  }

  # In dashboard layout, wrap any loose content blocks in ### Row so they don't
  # create implicit grid cells that squish the layout alongside viz ### Row containers.
  # Only wrap when there are subsequent visualizations that will add their own ### Row.
  # Skip wrapping when the loose content already contains its own ## Column markers
  # (e.g. from add_layout_column) since those manage their own grid structure.
  has_upcoming_viz <- !is.null(page$visualizations) && !isTRUE(page$viz_embedded_in_content)
  loose_content_added <- length(content) > content_len_after_column
  if (use_dashboard_layout && loose_content_added && has_upcoming_viz) {
    loose_lines <- content[(content_len_after_column + 1):length(content)]
    has_own_column <- any(grepl("^## Column", loose_lines))
    if (!has_own_column) {
      # Replace them with a ### Row wrapper
      content <- content[seq_len(content_len_after_column)]
      content <- c(content, "", "### Row {height=\"auto\"}", "")
      content <- c(content, loose_lines)
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

    # Inject page-level backend into viz specs that don't override it
    page_backend <- page$backend %||% "highcharter"
    if (page_backend != "highcharter") {
      viz_specs <- lapply(viz_specs, function(spec) {
        if (is.null(spec$backend)) {
          spec$backend <- page_backend
        }
        spec
      })
    }

    viz_content <- .generate_viz_from_specs(
      viz_specs,
      lazy_load_charts,
      lazy_load_tabs,
      heading_level = viz_heading_level,
      dashboard_layout = use_dashboard_layout,
      contextual_viz_errors = page$contextual_viz_errors %||% FALSE
    )
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

  # (main content landmark is added by accessibility.js — no closing div needed)

  content
}

.generate_page_item_content <- function(item,
                                        page,
                                        page_filter_vars,
                                        viz_heading_level,
                                        dashboard_layout,
                                        context_label = "page") {
  if (is.null(item) || !is.list(item)) {
    return(NULL)
  }

  item_type <- item$type %||% ""
  .validate_content_block_for_generation(
    item,
    context = paste0(context_label, " item type '", item_type, "'")
  )

  item_content <- switch(item_type,
    "text" = c("", item$content %||% item$text, ""),
    "callout" = {
      callout_block <- list(
        type = "callout",
        callout_type = item$callout_type %||% "note",
        content = item$content %||% item$text,
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
    "widget" = .generate_widget_block(item),
    "ggplot" = .generate_ggplot_block(item),
    "spacer" = .generate_spacer_block(item),
    "html" = .generate_html_block(item),
    "quote" = .generate_quote_block(item),
    "badge" = .generate_badge_block(item),
    "metric" = .generate_metric_block(item),
    "value_box" = .generate_value_box_block(item),
    "value_box_row" = .generate_value_box_row_block(item),
    "sparkline_card" = .generate_sparkline_card_block(item, page$backend %||% "highcharter"),
    "sparkline_card_row" = .generate_sparkline_card_row_block(item, page$backend %||% "highcharter"),
    "layout_column" = .generate_layout_column_block(item, page, page_filter_vars, viz_heading_level, dashboard_layout),
    "layout_row" = .generate_layout_row_block(item, page, page_filter_vars, viz_heading_level, dashboard_layout),
    "input" = .generate_input_block(item, page),
    "input_row" = .generate_input_row_block(item, page),
    "modal" = .generate_modal_block(item),
    NULL
  )

  .wrap_show_when_block(item_content, item$show_when)
}

# ---- Content tabgroup processing ----
# These helpers enable tabgroup support for ALL content block types,
# reusing .insert_into_hierarchy() from viz_processing.R for the tree structure.

#' Pre-process page$content_blocks to group consecutive standalone content_blocks
#' that have tabgroups. Returns a new list where groups of standalone blocks with
#' tabgroups have been replaced by content_tabset containers.
#' Content collections (is_content) are passed through as-is.
#' @noRd
.preprocess_content_blocks_tabgroups <- function(blocks, page, page_filter_vars,
                                                  viz_heading_level, dashboard_layout) {
  if (is.null(blocks) || length(blocks) == 0) return(blocks)

  # Check if any standalone block has tabgroup — fast path
  has_any <- FALSE
  for (block in blocks) {
    if (is_content_block(block) && !is.null(block$tabgroup)) {
      has_any <- TRUE
      break
    }
  }
  if (!has_any) return(blocks)

  # Group consecutive standalone content_blocks, process groups with tabgroups

  result <- list()
  i <- 1
  while (i <= length(blocks)) {
    block <- blocks[[i]]

    if (is.null(block) || !is.list(block)) {
      result <- c(result, list(block))
      i <- i + 1
      next
    }

    # If it's a content_collection, pass through
    if (is_content(block)) {
      result <- c(result, list(block))
      i <- i + 1
      next
    }

    # If it's a standalone content_block, collect consecutive ones
    if (is_content_block(block)) {
      group <- list(block)
      j <- i + 1
      while (j <= length(blocks)) {
        next_block <- blocks[[j]]
        if (!is.null(next_block) && is.list(next_block) && is_content_block(next_block)) {
          group <- c(group, list(next_block))
          j <- j + 1
        } else {
          break
        }
      }

      # Check if any in this group have tabgroup
      group_has_tabgroup <- any(sapply(group, function(b) !is.null(b$tabgroup)))
      if (group_has_tabgroup) {
        # Process through tabgroup handler
        processed <- .process_content_tabgroups(group)
        result <- c(result, processed)
      } else {
        # No tabgroups — pass through individually
        result <- c(result, group)
      }
      i <- j
    } else {
      # Unknown type — pass through
      result <- c(result, list(block))
      i <- i + 1
    }
  }

  result
}

#' Process a list of content items, grouping those with tabgroup into tabgroup containers
#' @param items List of content block items (may or may not have tabgroup)
#' @return Flat list mixing standalone items and content_tabgroup container specs, in insertion order
#' @noRd
.process_content_tabgroups <- function(items) {
  if (is.null(items) || length(items) == 0) return(list())

  # Check if any items have tabgroup — fast path if none do

  has_any_tabgroup <- FALSE
  for (item in items) {
    if (!is.null(item$tabgroup)) {
      has_any_tabgroup <- TRUE
      break
    }
  }
  if (!has_any_tabgroup) return(items)

  # Build hierarchy tree
  tree <- list(visualizations = list(), children = list())

  for (i in seq_along(items)) {
    item <- items[[i]]
    if (is.null(item)) next

    # Ensure insertion index
    item$.insertion_index <- item$.insertion_index %||% i

    # Parse tabgroup if needed (page_object items may store raw string)
    tg <- item$tabgroup
    if (is.character(tg) && length(tg) == 1 && grepl("/", tg, fixed = TRUE)) {
      tg <- .parse_tabgroup(tg)
    }

    if (!is.null(tg)) {
      # Ensure tg is a character vector for .insert_into_hierarchy
      if (!is.character(tg)) tg <- as.character(tg)
      tree <- .insert_into_hierarchy(tree, tg, item)
    } else {
      # No tabgroup — standalone item
      tree$visualizations <- c(tree$visualizations, list(item))
    }
  }

  # Convert tree to flat output list
  .content_tree_to_list(tree)
}

#' Convert a hierarchy tree to a flat list of standalone items and content_tabgroup specs
#' @param tree Hierarchy tree (from .insert_into_hierarchy)
#' @return Flat list sorted by insertion order. Children at the same level
#'   are wrapped in a single content_tabset container (which renders as one
#'   `::: {.panel-tabset}` block). Each child within becomes a tab.
#' @noRd
.content_tree_to_list <- function(tree) {
  result <- list()

  # Add standalone items (those without tabgroup)
  if (!is.null(tree$visualizations) && length(tree$visualizations) > 0) {
    for (item in tree$visualizations) {
      result <- c(result, list(item))
    }
  }

  # Wrap all children at this level into a single content_tabset container
  if (!is.null(tree$children) && length(tree$children) > 0) {
    # Sort children by insertion order
    child_names <- names(tree$children)
    child_indices <- sapply(child_names, function(nm) {
      tree$children[[nm]]$.min_index %||% Inf
    })
    child_names_sorted <- child_names[order(child_indices)]

    tabs <- list()
    min_idx <- Inf
    for (child_name in child_names_sorted) {
      child_node <- tree$children[[child_name]]
      child_min <- child_node$.min_index %||% Inf
      if (child_min < min_idx) min_idx <- child_min

      # Recursively convert child items
      child_items <- .content_tree_to_list(child_node)

      tabs <- c(tabs, list(list(
        name = child_name,
        items = child_items
      )))
    }

    tabset_spec <- list(
      type = "content_tabset",
      tabs = tabs,
      .insertion_index = min_idx
    )
    result <- c(result, list(tabset_spec))
  }

  # Sort by insertion index to preserve original order
  if (length(result) > 1) {
    indices <- sapply(result, function(x) {
      x$.insertion_index %||% Inf
    })
    result <- result[order(indices)]
  }

  result
}

#' Generate Quarto markdown for a content_tabset (wraps tabs in panel-tabset)
#'
#' A content_tabset has $tabs — a list where each tab has $name and $items.
#' Each tab's items may include nested content_tabset specs (for nested tabs).
#'
#' @param tabset_spec A content_tabset spec with $tabs
#' @param page The page object
#' @param page_filter_vars Filter variables
#' @param viz_heading_level Heading level for viz items
#' @param dashboard_layout Whether in dashboard layout mode
#' @param context_label Context label for error messages
#' @param depth Nesting depth (0 = top level)
#' @return Character vector of markdown lines
#' @noRd
.generate_content_tabset <- function(tabset_spec,
                                     page,
                                     page_filter_vars,
                                     viz_heading_level,
                                     dashboard_layout,
                                     context_label,
                                     depth = 0) {
  lines <- character(0)

  tabs <- tabset_spec$tabs
  if (is.null(tabs) || length(tabs) == 0) return(lines)

  # Open tabset
  lines <- c(lines, "", "::: {.panel-tabset}", "")

  tab_header <- paste0(rep("#", 3 + depth), collapse = "")

  for (tab in tabs) {
    tab_title <- tab$name %||% "Tab"
    lines <- c(lines, paste0(tab_header, " ", tab_title), "")

    # Render each item in this tab
    for (item in tab$items) {
      if (!is.null(item$type) && item$type == "content_tabset") {
        # Nested tabset — recurse
        nested_lines <- .generate_content_tabset(
          tabset_spec = item,
          page = page,
          page_filter_vars = page_filter_vars,
          viz_heading_level = viz_heading_level,
          dashboard_layout = dashboard_layout,
          context_label = context_label,
          depth = depth + 1
        )
        lines <- c(lines, nested_lines)
      } else {
        # Regular content item
        item_content <- .generate_page_item_content(
          item = item,
          page = page,
          page_filter_vars = page_filter_vars,
          viz_heading_level = viz_heading_level,
          dashboard_layout = dashboard_layout,
          context_label = context_label
        )
        if (!is.null(item_content)) {
          lines <- c(lines, item_content)
        }
      }
    }
  }

  # Close tabset
  lines <- c(lines, "", ":::", "")

  lines
}

.node_has_manual_layout <- function(node) {
  if (is.null(node) || !is.list(node)) return(FALSE)

  node_type <- node$type %||% ""
  if (node_type %in% c("layout_column", "layout_row")) {
    return(TRUE)
  }

  if (!is.null(node$items) && is.list(node$items)) {
    for (child in node$items) {
      if (.node_has_manual_layout(child)) {
        return(TRUE)
      }
    }
  }

  FALSE
}

.list_has_manual_layout <- function(nodes) {
  if (is.null(nodes) || length(nodes) == 0) return(FALSE)

  for (node in nodes) {
    if (.node_has_manual_layout(node)) {
      return(TRUE)
    }
  }

  FALSE
}

.page_has_manual_layout <- function(page) {
  .list_has_manual_layout(page$content_blocks) ||
    .list_has_manual_layout(page$.items)
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

.build_layout_header <- function(level, label, class = NULL, width = NULL, style = NULL) {
  attrs <- character(0)
  if (isTRUE(!is.null(class) && nzchar(class))) {
    class_tokens <- unlist(strsplit(class, "\\s+"))
    class_tokens <- class_tokens[nzchar(class_tokens)]
    attrs <- c(attrs, paste0(".", class_tokens))
  }

  if (!is.null(width) && nzchar(as.character(width))) {
    attrs <- c(attrs, paste0("width=", as.character(width)))
  }
  if (!is.null(style) && nzchar(style)) {
    attrs <- c(attrs, paste0("style=\"", style, "\""))
  }
  attr_suffix <- if (length(attrs) > 0) paste0(" {", paste(attrs, collapse = " "), "}") else ""
  paste0(paste(rep("#", level), collapse = ""), " ", label, attr_suffix)
}

.layout_items_in_order <- function(items) {
  if (is.null(items) || length(items) == 0) return(list())
  ordered_items <- items
  if (length(ordered_items) > 1) {
    indices <- sapply(ordered_items, function(x) x$.insertion_index %||% 999999L)
    ordered_items <- ordered_items[order(indices)]
  }
  ordered_items
}

.validate_manual_layout_row_items <- function(items, page_name) {
  if (is.null(items) || length(items) == 0) return(invisible(NULL))

  for (idx in seq_along(items)) {
    item <- items[[idx]]
    if (is.null(item) || !is.list(item)) next
    item_type <- item$type %||% "<unknown>"

    if (identical(item_type, "pagination") || isTRUE(item$pagination_break)) {
      stop(
        "Manual layout rows do not support pagination markers (page '", page_name,
        "', row item #", idx, ").",
        call. = FALSE
      )
    }

    if (!is.null(item$tabgroup)) {
      stop(
        "Manual layout rows do not support tabgroup markers on child blocks (page '", page_name,
        "', row item #", idx, ").",
        call. = FALSE
      )
    }
  }

  invisible(NULL)
}

.generate_layout_row_block <- function(block, page, page_filter_vars, viz_heading_level, dashboard_layout) {
  page_name <- page$name %||% page$title %||% "<unnamed page>"
  row_items <- .layout_items_in_order(block$items)
  .validate_manual_layout_row_items(row_items, page_name)

  # In dashboard mode (has sidebar), use ### Row heading for Quarto dashboard grid.
  # In non-dashboard mode (html format), use layout-ncol divs for side-by-side layout.
  row_style <- block$style
  if (dashboard_layout) {
    lines <- c("", .build_layout_header(3, "Row", class = block$class, style = row_style), "")
  } else {
    lines <- character(0)
  }

  i <- 1

  while (i <= length(row_items)) {
    item <- row_items[[i]]
    if (is.null(item) || !is.list(item)) {
      i <- i + 1
      next
    }

    item_type <- item$type %||% ""
    if (item_type == "viz") {
      viz_items <- list(item)
      j <- i + 1
      while (j <= length(row_items)) {
        next_item <- row_items[[j]]
        if (!is.list(next_item) || !identical(next_item$type %||% "", "viz")) break
        viz_items <- c(viz_items, list(next_item))
        j <- j + 1
      }

      viz_coll <- structure(list(
        items = viz_items,
        defaults = block$defaults,
        tabgroup_labels = block$tabgroup_labels,
        shared_first_level = block$shared_first_level
      ), class = c("content_collection", "viz_collection"))

      processed_specs <- .process_visualizations(
        viz_coll,
        page$data_path,
        filter_vars = page_filter_vars,
        context_label = paste0("layout row in page '", page_name, "'")
      )

      if (!is.null(processed_specs) && length(processed_specs) > 0) {
        page_backend <- page$backend %||% "highcharter"
        if (page_backend != "highcharter") {
          processed_specs <- lapply(processed_specs, function(spec) {
            if (is.null(spec$backend)) spec$backend <- page_backend
            if (!is.null(spec$nested_children)) {
              spec$nested_children <- lapply(spec$nested_children, function(child) {
                if (is.null(child$backend)) child$backend <- page_backend
                child
              })
            }
            spec
          })
        }

        # In non-dashboard mode with multiple vizzes, generate each viz
        # separately and wrap in layout-ncol with individual div children.
        # This avoids ## headings breaking out of the layout-ncol context.
        n_viz <- length(viz_items)
        if (!dashboard_layout && n_viz > 1) {
          per_viz_lines <- character(0)
          for (vi in seq_along(processed_specs)) {
            single_lines <- .generate_viz_from_specs(
              processed_specs[vi],
              lazy_load_charts = page$lazy_load_charts %||% FALSE,
              lazy_load_tabs = page$lazy_load_tabs %||% FALSE,
              heading_level = viz_heading_level,
              dashboard_layout = FALSE,
              contextual_viz_errors = page$contextual_viz_errors %||% FALSE
            )
            per_viz_lines <- c(per_viz_lines, "", ":::: {}", single_lines, "", "::::")
          }
          ncol_attrs <- paste0("layout-ncol=", n_viz)
          if (!is.null(row_style) && nzchar(row_style)) {
            ncol_attrs <- paste0(ncol_attrs, " style=\"", row_style, "\"")
          }
          lines <- c(lines, "", paste0("::: {", ncol_attrs, "}"), per_viz_lines, "", ":::", "")
        } else {
          viz_lines <- .generate_viz_from_specs(
            processed_specs,
            lazy_load_charts = page$lazy_load_charts %||% FALSE,
            lazy_load_tabs = page$lazy_load_tabs %||% FALSE,
            heading_level = viz_heading_level,
            dashboard_layout = FALSE,
            contextual_viz_errors = page$contextual_viz_errors %||% FALSE
          )
          lines <- c(lines, viz_lines)
        }
      }
      i <- j
      next
    }

    # Non-viz item: in non-dashboard mode, group consecutive non-viz items
    # for layout-ncol wrapping
    if (!dashboard_layout) {
      non_viz_items <- list(item)
      j <- i + 1
      while (j <= length(row_items)) {
        next_item <- row_items[[j]]
        if (!is.list(next_item) || identical(next_item$type %||% "", "viz")) break
        non_viz_items <- c(non_viz_items, list(next_item))
        j <- j + 1
      }

      # Generate content for each non-viz item
      group_lines <- character(0)
      for (nv_item in non_viz_items) {
        if (is.null(nv_item) || !is.list(nv_item)) next
        item_lines <- .generate_page_item_content(
          item = nv_item,
          page = page,
          page_filter_vars = page_filter_vars,
          viz_heading_level = viz_heading_level,
          dashboard_layout = dashboard_layout,
          context_label = paste0("layout row in page '", page_name, "'")
        )
        if (!is.null(item_lines)) group_lines <- c(group_lines, item_lines)
      }

      n_items <- length(non_viz_items)
      if (n_items > 1 && length(group_lines) > 0) {
        # Wrap in layout-ncol div for side-by-side rendering
        ncol_attrs <- paste0("layout-ncol=", n_items)
        if (!is.null(row_style) && nzchar(row_style)) {
          ncol_attrs <- paste0(ncol_attrs, " style=\"", row_style, "\"")
        }
        lines <- c(lines, "", paste0("::: {", ncol_attrs, "}"), group_lines, ":::", "")
      } else if (length(group_lines) > 0) {
        lines <- c(lines, group_lines)
      }

      i <- j
      next
    }

    # Dashboard mode: emit items individually (### Row handles layout)
    item_lines <- .generate_page_item_content(
      item = item,
      page = page,
      page_filter_vars = page_filter_vars,
      viz_heading_level = viz_heading_level,
      dashboard_layout = dashboard_layout,
      context_label = paste0("layout row in page '", page_name, "'")
    )
    if (!is.null(item_lines)) lines <- c(lines, item_lines)
    i <- i + 1
  }

  .wrap_show_when_block(lines, block$show_when)
}

.generate_layout_column_block <- function(block, page, page_filter_vars, viz_heading_level, dashboard_layout) {
  # In dashboard mode (has sidebar), use ## Column heading for Quarto dashboard grid.
  # In non-dashboard mode (html format), suppress heading; use width div only when needed.
  if (dashboard_layout) {
    column_lines <- c("", .build_layout_header(2, "Column", class = block$class, width = block$width), "")
  } else {
    width <- block$width
    if (!is.null(width) && nzchar(as.character(width))) {
      column_lines <- c("", paste0(":::{style=\"width:", width, "%\"}"), "")
    } else {
      column_lines <- character(0)
    }
  }
  column_items <- .layout_items_in_order(block$items)

  for (idx in seq_along(column_items)) {
    item <- column_items[[idx]]
    if (is.null(item) || !is.list(item)) next
    item_type <- item$type %||% ""

    item_lines <- if (identical(item_type, "viz")) {
      row_block <- list(type = "layout_row", items = list(item), class = NULL, show_when = NULL)
      .generate_layout_row_block(row_block, page, page_filter_vars, viz_heading_level, dashboard_layout)
    } else {
      .generate_page_item_content(
        item = item,
        page = page,
        page_filter_vars = page_filter_vars,
        viz_heading_level = viz_heading_level,
        dashboard_layout = dashboard_layout,
        context_label = paste0("layout column in page '", page$name %||% "<unnamed>", "'")
      )
    }
    if (!is.null(item_lines)) column_lines <- c(column_lines, item_lines)
  }

  # Close width div in non-dashboard mode
  if (!dashboard_layout && !is.null(block$width) && nzchar(as.character(block$width))) {
    column_lines <- c(column_lines, ":::", "")
  }

  .wrap_show_when_block(column_lines, block$show_when)
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

  if (style %in% c("thick", "dashed", "dotted")) {
    c("",
      "```{r}",
      "#| echo: false",
      paste0("dashboardr::html_divider(", .serialize_arg(style), ")"),
      "```",
      "")
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
  c("",
    "```{r}",
    "#| echo: false",
    paste0("dashboardr::html_card(",
           "body = ", .serialize_arg(block$text), ", ",
           "title = ", .serialize_arg(block$title), ")"),
    "```",
    "")
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
  extra_style <- block$style

  c("",
    "```{r}",
    "#| echo: false",
    paste0("dashboardr::html_iframe(",
           "url = ", .serialize_arg(block$url), ", ",
           "height = ", .serialize_arg(height), ", ",
           "width = ", .serialize_arg(width), ", ",
           "style = ", .serialize_arg(extra_style), ")"),
    "```",
    "")
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
  
  # Filterable table (client-side)
  if (!is.null(block$filter_vars)) {
    lines <- c(
      "",
      "```{r}",
      "#| echo: false",
      "#| results: 'asis'",
      paste0(
        "dashboardr:::.render_filterable_table(",
        table_var, ", ",
        "table_id = '", table_var, "', ",
        "caption = ", .serialize_arg(block$caption), ", ",
        "filter_vars = ", .serialize_arg(block$filter_vars),
        ")"
      ),
      "```",
      ""
    )
    return(lines)
  }
  
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
  if (!is.null(block$filter_vars)) {
    data_expr <- block$table_filter_data_var %||% .serialize_arg(block$reactable_data)
    lines <- c(
      "",
      "```{r}",
      "#| echo: false",
      "",
      paste0(
        table_var, " <- dashboardr:::.register_reactable_widget(",
        table_var, ", ",
        "table_id = '", table_var, "', ",
        "filter_vars = ", .serialize_arg(block$filter_vars), ", ",
        "data = ", data_expr,
        ")"
      ),
      table_var,
      "```",
      ""
    )
    return(lines)
  }
  
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
      paste0(
        hc_var, " <- dashboardr:::.register_chart_widget(",
        hc_var, ", backend = \"highcharter\", ",
        "filter_vars = ", .serialize_arg(block$filter_vars),
        ")"
      ),
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
      paste0(
        hc_var, " <- dashboardr:::.register_chart_widget(",
        hc_var, ", backend = \"highcharter\", ",
        "filter_vars = ", .serialize_arg(block$filter_vars),
        ")"
      ),
      hc_var,
      "```",
      ""
    )
  }
  
  lines
}

#' Generate widget block markdown
#'
#' Internal function to generate markdown for generic htmlwidget content blocks
#' (plotly, leaflet, echarts4r, ggiraph, etc.)
#'
#' @param block Widget content block
#' @return Character vector of markdown lines
#' @keywords internal
.generate_widget_block <- function(block) {
  widget_var <- if (!is.null(block$widget_var)) block$widget_var else "widget_obj"

  title_lines <- character(0)
  if (!is.null(block$title) && nzchar(block$title)) {
    title_lines <- c("", paste0("### ", block$title), "")
  }

  if (!is.null(block$height) && nzchar(block$height)) {
    height_line <- paste0("#| fig-height: ", gsub("px", "", block$height))
    lines <- c(
      title_lines,
      "",
      "```{r}",
      "#| echo: false",
      height_line,
      "",
      paste0(
        widget_var, " <- dashboardr:::.register_chart_widget(",
        widget_var, ", backend = dashboardr:::.detect_widget_backend(", widget_var, "), ",
        "filter_vars = ", .serialize_arg(block$filter_vars),
        ")"
      ),
      widget_var,
      "```",
      ""
    )
  } else {
    lines <- c(
      title_lines,
      "",
      "```{r}",
      "#| echo: false",
      "",
      paste0(
        widget_var, " <- dashboardr:::.register_chart_widget(",
        widget_var, ", backend = dashboardr:::.detect_widget_backend(", widget_var, "), ",
        "filter_vars = ", .serialize_arg(block$filter_vars),
        ")"
      ),
      widget_var,
      "```",
      ""
    )
  }

  lines
}

.generate_ggplot_block <- function(block) {
  gg_var <- block$ggplot_var %||% "gg_obj"

  title_lines <- character(0)
  if (!is.null(block$title) && nzchar(block$title)) {
    title_lines <- c("", paste0("### ", block$title), "")
  }

  # Build chunk options
  chunk_opts <- c("#| echo: false")
  if (!is.null(block$height)) {
    chunk_opts <- c(chunk_opts, paste0("#| fig-height: ", block$height))
  }
  if (!is.null(block$width)) {
    chunk_opts <- c(chunk_opts, paste0("#| fig-width: ", block$width))
  }

  lines <- c(
    title_lines,
    "",
    "```{r}",
    chunk_opts,
    "",
    gg_var,
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
  if (!is.null(block$filter_vars)) {
    data_expr <- block$table_filter_data_var %||% .serialize_arg(block$table_raw)
    lines <- c(
      "",
      "```{r}",
      "#| echo: false",
      "",
      paste0(
        table_var, " <- dashboardr:::.register_dt_widget(",
        table_var, ", ",
        "table_id = '", table_var, "', ",
        "filter_vars = ", .serialize_arg(block$filter_vars), ", ",
        "data = ", data_expr,
        ")"
      ),
      table_var,
      "```",
      ""
    )
    return(lines)
  }
  
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
  c("",
    "```{r}",
    "#| echo: false",
    paste0("dashboardr::html_spacer(", .serialize_arg(height), ")"),
    "```",
    "")
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
  c("",
    "```{r}",
    "#| echo: false",
    paste0("dashboardr::html_badge(",
           "text = ", .serialize_arg(block$text), ", ",
           "color = ", .serialize_arg(block$color %||% "primary"), ")"),
    "```",
    "")
}

#' Generate metric block markdown
#'
#' Internal function to generate markdown for metric/value box content blocks
#'
#' @param block Metric content block
#' @return Character vector of markdown lines
#' @keywords internal
.generate_metric_block <- function(block) {
  c("",
    "```{r}",
    "#| echo: false",
    paste0("dashboardr::html_metric(",
           "value = ", .serialize_arg(block$value), ", ",
           "title = ", .serialize_arg(block$title), ", ",
           "icon = ", .serialize_arg(block$icon), ", ",
           "color = ", .serialize_arg(block$color), ", ",
           "bg_color = ", .serialize_arg(block$bg_color), ", ",
           "text_color = ", .serialize_arg(block$text_color), ", ",
           "value_prefix = ", .serialize_arg(block$value_prefix), ", ",
           "value_suffix = ", .serialize_arg(block$value_suffix), ", ",
           "border_radius = ", .serialize_arg(block$border_radius), ", ",
           "subtitle = ", .serialize_arg(block$subtitle), ", ",
           "aria_label = ", .serialize_arg(block$aria_label), ")"),
    "```",
    "")
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
    paste0("dashboardr::render_value_box("),
    paste0("  title = ", .serialize_arg(block$title), ","),
    paste0("  value = ", .serialize_arg(block$value), ","),
    paste0("  bg_color = ", .serialize_arg(block$bg_color), ","),
    paste0("  logo_url = ", .serialize_arg(block$logo_url), ","),
    paste0("  logo_text = ", .serialize_arg(block$logo_text), ","),
    paste0("  aria_label = ", .serialize_arg(block$aria_label)),
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

    # Build the description accordion as raw HTML
    lines <- c(lines, "",
      "<details>",
      paste0("<summary>", block$description_title %||% "Details", "</summary>"),
      "",
      description_text,
      "",
      "</details>")
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

#' Generate sparkline card block markdown
#' @param block Sparkline card content block
#' @return Character vector of markdown lines
#' @keywords internal
.generate_sparkline_card_block <- function(block, backend = NULL) {
  be <- backend %||% block$backend %||% "echarts4r"
  lines <- c(
    "",
    "```{r}",
    "#| echo: false",
    "dashboardr::render_sparkline_card(",
    "  data = data,",
    paste0("  x_var = ", .serialize_arg(block$x_var), ","),
    paste0("  y_var = ", .serialize_arg(block$y_var), ","),
    paste0("  value = ", .serialize_arg(block$value), ","),
    paste0("  subtitle = ", .serialize_arg(block$subtitle %||% ""), ","),
    paste0("  agg = ", .serialize_arg(block$agg %||% "count"), ","),
    paste0("  line_color = ", .serialize_arg(block$line_color %||% "#2b74ff"), ","),
    paste0("  bg_color = ", .serialize_arg(block$bg_color %||% "#ffffff"), ","),
    paste0("  text_color = ", .serialize_arg(block$text_color %||% "#111827"), ","),
    paste0("  height = ", block$height %||% 130, ","),
    paste0("  smooth = ", block$smooth %||% 0.6, ","),
    paste0("  area_opacity = ", block$area_opacity %||% 0.18, ","),
    paste0("  filter_expr = ", .serialize_arg(block$filter_expr), ","),
    paste0("  value_prefix = ", .serialize_arg(block$value_prefix %||% ""), ","),
    paste0("  value_suffix = ", .serialize_arg(block$value_suffix %||% ""), ","),
    paste0("  connect_group = ", .serialize_arg(block$connect_group), ","),
    paste0("  backend = ", .serialize_arg(be)),
    ")",
    "```",
    ""
  )
  lines
}

#' Generate sparkline card row block markdown
#' @param block Sparkline card row content block
#' @return Character vector of markdown lines
#' @keywords internal
.generate_sparkline_card_row_block <- function(block, backend = NULL) {
  be <- backend %||% block$backend %||% "echarts4r"
  lines <- c(
    "",
    "```{r}",
    "#| echo: false",
    paste0("dashboardr::render_sparkline_card_row(data = data, list(")
  )

  for (i in seq_along(block$cards)) {
    card <- block$cards[[i]]
    card_lines <- c(
      "  list(",
      paste0("    x_var = ", .serialize_arg(card$x_var), ","),
      paste0("    y_var = ", .serialize_arg(card$y_var), ","),
      paste0("    value = ", .serialize_arg(card$value), ","),
      paste0("    subtitle = ", .serialize_arg(card$subtitle %||% ""), ","),
      paste0("    agg = ", .serialize_arg(card$agg %||% "count"), ","),
      paste0("    line_color = ", .serialize_arg(card$line_color %||% "#2b74ff"), ","),
      paste0("    bg_color = ", .serialize_arg(card$bg_color %||% "#ffffff"), ","),
      paste0("    text_color = ", .serialize_arg(card$text_color %||% "#111827"), ","),
      paste0("    height = ", card$height %||% 130, ","),
      paste0("    smooth = ", card$smooth %||% 0.6, ","),
      paste0("    area_opacity = ", card$area_opacity %||% 0.18, ","),
      paste0("    filter_expr = ", .serialize_arg(card$filter_expr), ","),
      paste0("    value_prefix = ", .serialize_arg(card$value_prefix %||% ""), ","),
      paste0("    value_suffix = ", .serialize_arg(card$value_suffix %||% ""), ","),
      paste0("    connect_group = ", .serialize_arg(card$connect_group)),
      if (i < length(block$cards)) "  )," else "  )"
    )
    lines <- c(lines, card_lines)
  }

  lines <- c(lines, paste0("), backend = ", .serialize_arg(be), ")"), "```", "")
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
  if (!is.null(block$icons)) {
    lines <- c(lines,
      paste0("  , icons = ", .serialize_arg(block$icons))
    )
  }
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
      paste0("    ml = ", .serialize_arg(input$ml), ","),
      paste0("    icons = ", .serialize_arg(input$icons)),
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
      "sparkline_card" = .generate_sparkline_card_block(block, (page$backend %||% "highcharter")),
      "sparkline_card_row" = .generate_sparkline_card_row_block(block, (page$backend %||% "highcharter")),
      NULL
    )

    if (!is.null(block_content)) {
      block_content <- .wrap_show_when_block(block_content, block$show_when)
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

#' Wrap block markdown with show_when helpers
#'
#' @param lines Character vector of markdown lines
#' @param show_when Optional show_when formula
#' @keywords internal
.wrap_show_when_block <- function(lines, show_when) {
  if (is.null(lines) || is.null(show_when)) return(lines)
  show_when_json <- .parse_show_when(show_when)
  c(
    "",
    "```{r}",
    "#| echo: false",
    "#| results: 'asis'",
    paste0("show_when_open('", show_when_json, "')"),
    "```",
    lines,
    "```{r}",
    "#| echo: false",
    "#| results: 'asis'",
    "show_when_close()",
    "```",
    ""
  )
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
  } else if (op == "(") {
    # Parenthesized expression — just unwrap
    .expr_to_condition(expr[[2]])
  } else {
    stop("Unsupported operator in show_when: ", op, call. = FALSE)
  }
}

.collect_blocks_recursive_node <- function(node, filter_fn) {
  if (is.null(node) || !is.list(node)) return(list())

  collected <- list()
  if (filter_fn(node)) {
    collected <- c(collected, list(node))
  }

  if (!is.null(node$items) && is.list(node$items)) {
    for (child in node$items) {
      collected <- c(collected, .collect_blocks_recursive_node(child, filter_fn))
    }
  }

  collected
}

.collect_blocks_recursive <- function(blocks, filter_fn) {
  if (is.null(blocks) || length(blocks) == 0) return(list())

  collected <- list()
  for (block in blocks) {
    if (is_content(block) || is_content_block(block)) {
      collected <- c(collected, .collect_blocks_recursive_node(block, filter_fn))
    }
  }

  collected
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
    table_blocks <- .collect_blocks_recursive(page$content_blocks, function(b) {
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

    table_filter_data_blocks <- .collect_blocks_recursive(page$content_blocks, function(b) {
      isTRUE(b$type %in% c("reactable", "DT")) &&
        !is.null(b$table_filter_data_file) &&
        !is.null(b$table_filter_data_var)
    })
    if (length(table_filter_data_blocks) > 0) {
      lines <- c(lines, "# Load table filter datasets", "")
      for (block in table_filter_data_blocks) {
        lines <- c(lines, paste0(block$table_filter_data_var, " <- readRDS('", block$table_filter_data_file, "')"))
      }
      lines <- c(lines, "")
    }
    
    # Load highcharter objects from content blocks
    hc_blocks <- .collect_blocks_recursive(page$content_blocks, function(b) {
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

    # Load widget objects (plotly, leaflet, etc.) from content blocks
    widget_blocks <- .collect_blocks_recursive(page$content_blocks, function(b) {
      isTRUE(b$type == "widget") && !is.null(b$widget_file)
    })
    if (length(widget_blocks) > 0) {
      lines <- c(lines, "# Load widget objects (plotly, leaflet, etc.)", "")
      for (block in widget_blocks) {
        if (isTRUE(!is.null(block$widget_var) && !is.null(block$widget_file))) {
          lines <- c(lines, paste0(block$widget_var, " <- readRDS('", block$widget_file, "')"))
        }
      }
      lines <- c(lines, "")
    }

    # Load ggplot objects from content blocks
    ggplot_blocks <- .collect_blocks_recursive(page$content_blocks, function(b) {
      isTRUE(b$type == "ggplot") && !is.null(b$ggplot_file)
    })
    if (length(ggplot_blocks) > 0) {
      lines <- c(lines, "# Load ggplot2 objects", "")
      for (block in ggplot_blocks) {
        if (isTRUE(!is.null(block$ggplot_var) && !is.null(block$ggplot_file))) {
          lines <- c(lines, paste0(block$ggplot_var, " <- readRDS('", block$ggplot_file, "')"))
        }
      }
      lines <- c(lines, "")
    }
  }

  # Also load objects from page$.items (piped items)
  if (!is.null(page$.items) && length(page$.items) > 0) {
    for (item in page$.items) {
      if (is.null(item) || !is.list(item)) next
      if (isTRUE(item$type == "hc") && !is.null(item$hc_var) && !is.null(item$hc_file)) {
        lines <- c(lines, paste0(item$hc_var, " <- readRDS('", item$hc_file, "')"))
      }
      if (isTRUE(item$type == "widget") && !is.null(item$widget_var) && !is.null(item$widget_file)) {
        lines <- c(lines, paste0(item$widget_var, " <- readRDS('", item$widget_file, "')"))
      }
      if (isTRUE(item$type == "ggplot") && !is.null(item$ggplot_var) && !is.null(item$ggplot_file)) {
        lines <- c(lines, paste0(item$ggplot_var, " <- readRDS('", item$ggplot_file, "')"))
      }
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


.process_viz_specs <- function(content, viz_specs, contextual_viz_errors = FALSE) {
  if (is.null(viz_specs) || length(viz_specs) == 0) {
    return(content)
  }

  viz_placeholder <- "{{visualizations}}"

  if (any(grepl(viz_placeholder, content, fixed = TRUE))) {
    viz_content <- .generate_viz_from_specs(
      viz_specs,
      contextual_viz_errors = contextual_viz_errors
    )
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
