# =================================================================
# dashboard_generation
# =================================================================


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
#' }
generate_dashboard <- function(proj, render = TRUE, open = "browser", incremental = FALSE, preview = NULL, 
                              show_progress = TRUE, quiet = FALSE) {
  # Check Quarto version (>= 1.4 required) only if rendering
  quarto_available <- TRUE
  if (render) {
    quarto_available <- check_quarto_version()
    if (!quarto_available) {
      render <- FALSE
      if (!quiet) {
        message("Skipping render step (Quarto not available). QMD files will still be generated.")
      }
    }
  }
  
  # Start timing
  start_time <- Sys.time()
  
  # Quiet mode overrides show_progress
  if (quiet) {
    show_progress <- FALSE
  }
  
  if (!inherits(proj, "dashboard_project")) {
    stop("proj must be a dashboard_project object")
  }
  
  # Validate preview parameter
  preview_pages <- NULL
  if (!is.null(preview)) {
    # Normalize preview page names (case-insensitive)
    preview <- tolower(preview)
    available_pages <- tolower(names(proj$pages))
    
    # Check each preview page exists
    for (p in preview) {
      if (!p %in% available_pages) {
        # Try to suggest alternatives
        suggestion <- .suggest_alternative(p, names(proj$pages))
        if (!is.null(suggestion)) {
          stop("Page '", preview[1], "' not found in dashboard. Did you mean '", suggestion, "'?\n",
               "Available pages: ", paste(names(proj$pages), collapse = ", "))
        } else {
          stop("Page '", preview[1], "' not found in dashboard.\n",
               "Available pages: ", paste(names(proj$pages), collapse = ", "))
        }
      }
    }
    
    # Map preview names to actual page names
    preview_pages <- names(proj$pages)[tolower(names(proj$pages)) %in% preview]
    
    if (!quiet) {
      message("📄 Preview mode: Generating only ", length(preview_pages), " page(s): ", 
              paste(preview_pages, collapse = ", "))
    }
  }
  
  # Show progress header
  .progress_header(paste0("🚀 Generating Dashboard: ", proj$title), show_progress)
  
  # Reset chunk label tracker for new generation
  if (exists(".chunk_label_tracker", envir = .GlobalEnv)) {
    rm(".chunk_label_tracker", envir = .GlobalEnv)
  }

  output_dir <- .resolve_output_dir(proj$output_dir, proj$allow_inside_pkg)
  .progress_msg("Output directory:", "📁", show_progress)
  if (show_progress) cat("   ", output_dir, "\n")

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # Save any pending data files (deferred from add_page)
  if (!is.null(proj$pending_data) && length(proj$pending_data) > 0) {
    for (data_path in names(proj$pending_data)) {
      saveRDS(proj$pending_data[[data_path]], file.path(output_dir, basename(data_path)))
    }
    if (!quiet) {
      message("Saved ", length(proj$pending_data), " data file(s)")
    }
  }
  
  # Load previous build manifest for incremental builds
  manifest <- if (incremental) .load_manifest(output_dir) else NULL
  new_manifest <- list(
    timestamp = Sys.time(),
    pages = list()
  )
  
  # Track which pages were regenerated vs skipped
  build_info <- list(
    regenerated = character(),
    skipped = character(),
    preview_mode = !is.null(preview_pages),
    qmd_files = character()  # Track generated .qmd files for targeted rendering
  )

  tryCatch({
    # Setup phase
    .progress_section("⚙️  Setup", show_progress)
    setup_start <- Sys.time()
    
    # Check if icons are used and install iconify extension if needed
    if (.check_for_icons(proj)) {
      # Check if iconify extension is already installed
      iconify_dir <- file.path(output_dir, "_extensions", "mcanouil", "iconify")
      if (!dir.exists(iconify_dir) || !file.exists(file.path(iconify_dir, "_extension.yml"))) {
        if (!quiet) message("Icons detected in dashboard. Installing iconify extension...")

        # Attempt to install iconify extension with proper error handling
        install_success <- .install_iconify_extension(output_dir)
        if (!install_success) {
          warning("Failed to install iconify extension automatically. Icons may not display correctly.")
          if (!quiet) {
            message("To fix this manually:")
            message("  cd ", output_dir)
            message("  quarto add mcanouil/quarto-iconify")
            message("\nOr remove icons from your dashboard to render without them")
          }
        }
      } else {
        if (!quiet) message("Iconify extension already installed")
      }
    }

    # Copy logo and favicon if provided
    if (!is.null(proj$logo) && file.exists(proj$logo)) {
      file.copy(proj$logo, file.path(output_dir, basename(proj$logo)), overwrite = TRUE)
    }
    if (!is.null(proj$favicon) && file.exists(proj$favicon)) {
      file.copy(proj$favicon, file.path(output_dir, basename(proj$favicon)), overwrite = TRUE)
    }
    
    # Copy modal and pagination assets (CSS and JS) to assets directory
    assets_dir <- file.path(output_dir, "assets")
    if (!dir.exists(assets_dir)) {
      dir.create(assets_dir, recursive = TRUE)
    }
    
    modal_css <- system.file("assets", "modal.css", package = "dashboardr")
    modal_js <- system.file("assets", "modal.js", package = "dashboardr")
    pagination_css <- system.file("assets", "pagination.css", package = "dashboardr")
    input_filter_css <- system.file("assets", "input_filter.css", package = "dashboardr")
    input_filter_js <- system.file("assets", "input_filter.js", package = "dashboardr")
    filter_hook_js <- system.file("assets", "filter_hook.js", package = "dashboardr")
    choices_css <- system.file("assets", "choices.min.css", package = "dashboardr")
    choices_js <- system.file("assets", "choices.min.js", package = "dashboardr")
    tab_scroll_fix_js <- system.file("assets", "tab-scroll-fix.js", package = "dashboardr")
    sidebar_css <- system.file("assets", "sidebar.css", package = "dashboardr")
    
    if (file.exists(modal_css)) {
      file.copy(modal_css, file.path(assets_dir, "modal.css"), overwrite = TRUE)
    }
    if (file.exists(modal_js)) {
      file.copy(modal_js, file.path(assets_dir, "modal.js"), overwrite = TRUE)
    }
    if (file.exists(pagination_css)) {
      file.copy(pagination_css, file.path(assets_dir, "pagination.css"), overwrite = TRUE)
    }
    if (file.exists(input_filter_css)) {
      file.copy(input_filter_css, file.path(assets_dir, "input_filter.css"), overwrite = TRUE)
    }
    if (file.exists(input_filter_js)) {
      file.copy(input_filter_js, file.path(assets_dir, "input_filter.js"), overwrite = TRUE)
    }
    if (file.exists(filter_hook_js)) {
      file.copy(filter_hook_js, file.path(assets_dir, "filter_hook.js"), overwrite = TRUE)
    }
    if (file.exists(choices_css)) {
      file.copy(choices_css, file.path(assets_dir, "choices.min.css"), overwrite = TRUE)
    }
    if (file.exists(choices_js)) {
      file.copy(choices_js, file.path(assets_dir, "choices.min.js"), overwrite = TRUE)
    }
    if (file.exists(tab_scroll_fix_js)) {
      file.copy(tab_scroll_fix_js, file.path(assets_dir, "tab-scroll-fix.js"), overwrite = TRUE)
    }
    if (file.exists(sidebar_css)) {
      file.copy(sidebar_css, file.path(assets_dir, "sidebar.css"), overwrite = TRUE)
    }

    # Copy tabset theme SCSS file if using a built-in theme
    if (!is.null(proj$tabset_theme) && proj$tabset_theme != "none") {
      theme_scss_name <- paste0("tabset_", proj$tabset_theme, ".scss")
      theme_scss_path <- system.file("extdata", "themes", theme_scss_name, package = "dashboardr")
      
      if (file.exists(theme_scss_path)) {
        target_path <- file.path(output_dir, paste0("_tabset_", proj$tabset_theme, ".scss"))
        file.copy(theme_scss_path, target_path, overwrite = TRUE)
        if (!quiet) message("Using tabset theme: ", proj$tabset_theme)
      } else {
        warning("Tabset theme file not found: ", theme_scss_name)
      }
    }
    
    # Generate color override SCSS if tabset_colors are specified
    if (!is.null(proj$tabset_colors) && length(proj$tabset_colors) > 0) {
      color_scss <- .generate_tabset_color_scss(proj$tabset_colors)
      writeLines(color_scss, file.path(output_dir, "_tabset_colors.scss"))
      if (!quiet) message("Applied custom tabset colors")
    }
    
    # Generate theme customization SCSS if navbar colors are specified
    if (!is.null(proj$navbar_bg_color) || !is.null(proj$navbar_text_color) || !is.null(proj$navbar_text_hover_color)) {
      theme_scss <- .generate_theme_custom_scss(proj)
      writeLines(theme_scss, file.path(output_dir, "_theme_custom.scss"))
      custom_items <- c()
      if (!is.null(proj$navbar_bg_color)) custom_items <- c(custom_items, "navbar bg")
      if (!is.null(proj$navbar_text_color)) custom_items <- c(custom_items, "navbar text")
      if (!is.null(proj$navbar_text_hover_color)) custom_items <- c(custom_items, "navbar hover")
      if (!quiet) message("Applied custom theme settings (", paste(custom_items, collapse = ", "), ")")
    }

    # Generate _quarto.yml
    yaml_content <- .generate_quarto_yml(proj)
    writeLines(yaml_content, file.path(output_dir, "_quarto.yml"))
    
    setup_elapsed <- as.numeric(difftime(Sys.time(), setup_start, units = "secs"))
    .progress_step("Configuration files ready", setup_elapsed, show_progress)

    # Page generation
    if (show_progress) {
      cat("\n")
      cat("║\n")
      cat("║ 📄 GENERATING PAGES:\n")
    }
    
    # Calculate total pages to generate
    pages_to_generate <- names(proj$pages)
    if (!is.null(proj$landing_page)) {
      # Exclude landing page from count as it's handled separately
      pages_to_generate <- setdiff(pages_to_generate, proj$landing_page)
    }
    if (!is.null(preview_pages)) {
      pages_to_generate <- intersect(pages_to_generate, preview_pages)
    }
    
    total_pages <- length(pages_to_generate)
    current_page <- 0
    
    # Determine if we'll also show landing page for last detection
    will_show_landing <- !is.null(proj$landing_page) && 
                         (is.null(preview_pages) || proj$landing_page %in% preview_pages)
    
    # Generate each page
    for (page_name in names(proj$pages)) {
      tryCatch({
        page <- proj$pages[[page_name]]

        # Skip landing page in regular pages loop - it's handled separately
        if (!is.null(proj$landing_page) && page_name == proj$landing_page) {
          next
        }
      
      # Skip if in preview mode and page is not in preview list
      if (!is.null(preview_pages) && !page_name %in% preview_pages) {
        next
      }

      # Track progress (no progress bar - page generation is fast)
      current_page <- current_page + 1
      page_start <- Sys.time()
      
      # Check if this is the last page (only if no landing page will be shown after)
      is_last_page <- (current_page == total_pages && !will_show_landing)

      # Use lowercase with underscores for filenames
      filename <- tolower(gsub("[^a-zA-Z0-9]", "_", page_name))
      page_file <- file.path(output_dir, paste0(filename, ".qmd"))

      # Check if page needs rebuild
      needs_rebuild <- .needs_rebuild(page_name, page, manifest)
      
      if (incremental && !needs_rebuild) {
        # Skip this page - it hasn't changed
        build_info$skipped <- c(build_info$skipped, page_name)
        # Store hash in new manifest
        new_manifest$pages[[page_name]] <- list(hash = .compute_hash(page))
        
        page_elapsed <- as.numeric(difftime(Sys.time(), page_start, units = "secs"))
        .progress_step(paste0(page_name, " (skipped)"), page_elapsed, show_progress, is_last_page, use_page_style = TRUE)
        next
      }
      
      # Mark as regenerated
      build_info$regenerated <- c(build_info$regenerated, page_name)

      # Save table objects (entire styled objects for direct rendering)
      if (!is.null(page$content_blocks)) {
        table_counter <- 0
        hc_counter <- 0
        for (i in seq_along(page$content_blocks)) {
          block <- page$content_blocks[[i]]
          if (!inherits(block, "content_block")) next
          
          # Handle table types
          if (isTRUE(block$type %in% c("table", "gt", "reactable", "DT"))) {
            table_counter <- table_counter + 1
            
            # Get the table object to save
            table_obj <- NULL
            if (block$type == "table" && !is.null(block$table_object)) {
              table_obj <- block$table_object
            } else if (block$type == "gt" && !is.null(block$gt_object)) {
              table_obj <- block$gt_object
            } else if (block$type == "reactable" && !is.null(block$reactable_object)) {
              table_obj <- block$reactable_object
            } else if (block$type == "DT" && !is.null(block$table_data)) {
              table_obj <- block$table_data
            }
            
            # Save the ENTIRE styled object (preserves all styling!)
            if (!is.null(table_obj)) {
              obj_filename <- paste0("table_obj_", table_counter, ".rds")
              obj_filepath <- file.path(output_dir, obj_filename)
              saveRDS(table_obj, obj_filepath)
              page$content_blocks[[i]]$table_file <- obj_filename
              page$content_blocks[[i]]$table_var <- paste0("table_obj_", table_counter)
            }
          }
          
          # Handle highcharter objects
          if (isTRUE(block$type == "hc") && !is.null(block$hc_object)) {
            hc_counter <- hc_counter + 1
            hc_filename <- paste0("hc_obj_", hc_counter, ".rds")
            hc_filepath <- file.path(output_dir, hc_filename)
            saveRDS(block$hc_object, hc_filepath)
            page$content_blocks[[i]]$hc_file <- hc_filename
            page$content_blocks[[i]]$hc_var <- paste0("hc_obj_", hc_counter)
          }
        }
      }
      
      # Now generate the page content with updated blocks
      if (!is.null(page$template)) {
        # Custom template
        content <- .process_template(page$template, page$params, output_dir)
        if (!is.null(page$visualizations)) {
          content <- .process_viz_specs(content, page$visualizations)
        }
        writeLines(content, page_file)
        # Track this .qmd file for targeted rendering
        build_info$qmd_files <- c(build_info$qmd_files, basename(page_file))
      } else {
        # Default page generation - check for pagination
        has_pagination <- .has_pagination_markers(page)

        if (has_pagination) {
          # Generate multiple QMD files for paginated page
          paginated_files <- .generate_paginated_page_files(page, page_name, page_file, output_dir, proj$theme, proj$pagination_position)
          # Track all paginated .qmd files for targeted rendering
          build_info$qmd_files <- c(build_info$qmd_files, paginated_files)
        } else {
          # Single page generation
          content <- .generate_default_page_content(page)
          writeLines(content, page_file)
          # Track this .qmd file for targeted rendering
          build_info$qmd_files <- c(build_info$qmd_files, basename(page_file))
        }
      }
      
      # Store hash in new manifest
      new_manifest$pages[[page_name]] <- list(hash = .compute_hash(page))
      
      page_elapsed <- as.numeric(difftime(Sys.time(), page_start, units = "secs"))
      .progress_step(page_name, page_elapsed, show_progress, is_last_page, use_page_style = TRUE)
      
      # Copy data file(s) if needed
      if (!is.null(page$data_path)) {
        if (is.list(page$data_path)) {
          # Multiple datasets - copy each one
          for (dataset_name in names(page$data_path)) {
            data_file <- page$data_path[[dataset_name]]
            data_file_path <- file.path(output_dir, basename(data_file))
            target_path <- file.path(output_dir, basename(data_file))
            
            # Only copy if source and target are different
            if (normalizePath(data_file_path, mustWork = FALSE) != normalizePath(target_path, mustWork = FALSE)) {
              if (file.exists(data_file_path) && !file.copy(data_file_path, target_path, overwrite = TRUE)) {
                warning("Failed to copy data file for ", dataset_name, ": ", basename(data_file))
              }
            }
          }
        } else {
          # Single dataset
          data_file_path <- file.path(output_dir, basename(page$data_path))
          target_path <- file.path(output_dir, basename(page$data_path))

          # Only copy if source and target are different
          if (normalizePath(data_file_path, mustWork = FALSE) != normalizePath(target_path, mustWork = FALSE)) {
            if (file.exists(data_file_path) && !file.copy(data_file_path, target_path, overwrite = TRUE)) {
              warning("Failed to copy data file: ", basename(page$data_path))
            }
          }
        }
      }
      })
    }

    # Generate landing page as index.qmd if specified
    if (!is.null(proj$landing_page)) {
      landing_page_name <- proj$landing_page
      
      # Skip landing page if in preview mode and not in preview list
      if (is.null(preview_pages) || landing_page_name %in% preview_pages) {
        landing_start <- Sys.time()
        landing_page <- proj$pages[[landing_page_name]]
        index_file <- file.path(output_dir, "index.qmd")

        # Check if landing page needs rebuild
        needs_rebuild <- .needs_rebuild(landing_page_name, landing_page, manifest)
        
        if (incremental && !needs_rebuild) {
          build_info$skipped <- c(build_info$skipped, landing_page_name)
          new_manifest$pages[[landing_page_name]] <- list(hash = .compute_hash(landing_page))
          
          landing_elapsed <- as.numeric(difftime(Sys.time(), landing_start, units = "secs"))
          .progress_step(paste0(landing_page_name, " [🏠 Landing] (skipped)"), landing_elapsed, show_progress, is_last = TRUE, use_page_style = TRUE)
        } else {
          build_info$regenerated <- c(build_info$regenerated, landing_page_name)
          
          # Save table/hc objects for landing page (same as regular pages)
          if (!is.null(landing_page$content_blocks)) {
            table_counter <- 0
            hc_counter <- 0
            for (i in seq_along(landing_page$content_blocks)) {
              block <- landing_page$content_blocks[[i]]
              if (!inherits(block, "content_block")) next
              
              # Handle table types
              if (isTRUE(block$type %in% c("table", "gt", "reactable", "DT"))) {
                table_counter <- table_counter + 1
                table_obj <- NULL
                if (block$type == "table" && !is.null(block$table_object)) {
                  table_obj <- block$table_object
                } else if (block$type == "gt" && !is.null(block$gt_object)) {
                  table_obj <- block$gt_object
                } else if (block$type == "reactable" && !is.null(block$reactable_object)) {
                  table_obj <- block$reactable_object
                } else if (block$type == "DT" && !is.null(block$table_data)) {
                  table_obj <- block$table_data
                }
                if (!is.null(table_obj)) {
                  obj_filename <- paste0("table_obj_", table_counter, ".rds")
                  obj_filepath <- file.path(output_dir, obj_filename)
                  saveRDS(table_obj, obj_filepath)
                  landing_page$content_blocks[[i]]$table_file <- obj_filename
                  landing_page$content_blocks[[i]]$table_var <- paste0("table_obj_", table_counter)
                }
              }
              
              # Handle highcharter objects
              if (isTRUE(block$type == "hc") && !is.null(block$hc_object)) {
                hc_counter <- hc_counter + 1
                hc_filename <- paste0("hc_obj_", hc_counter, ".rds")
                hc_filepath <- file.path(output_dir, hc_filename)
                saveRDS(block$hc_object, hc_filepath)
                landing_page$content_blocks[[i]]$hc_file <- hc_filename
                landing_page$content_blocks[[i]]$hc_var <- paste0("hc_obj_", hc_counter)
              }
            }
          }
          
          if (!is.null(landing_page$template)) {
            # Custom template
            content <- .process_template(landing_page$template, landing_page$params, output_dir)
            if (!is.null(landing_page$visualizations)) {
              viz_content <- .generate_viz_from_specs(landing_page$visualizations)
              content <- c(content, "", viz_content)
            }
          } else {
            # Default content
            content <- .generate_default_page_content(landing_page)
          }

          writeLines(content, index_file)
          new_manifest$pages[[landing_page_name]] <- list(hash = .compute_hash(landing_page))
          # Track the landing page .qmd file for targeted rendering
          build_info$qmd_files <- c(build_info$qmd_files, "index.qmd")
          
          landing_elapsed <- as.numeric(difftime(Sys.time(), landing_start, units = "secs"))
          .progress_step(paste0(landing_page_name, " [🏠 Landing]"), landing_elapsed, show_progress, is_last = TRUE, use_page_style = TRUE)
        }
      }
    }
    
    # Delete pages that no longer exist
    if (incremental && !is.null(manifest)) {
      old_pages <- names(manifest$pages)
      new_pages <- names(proj$pages)
      deleted_pages <- setdiff(old_pages, new_pages)
      
      for (deleted_name in deleted_pages) {
        filename <- tolower(gsub("[^a-zA-Z0-9]", "_", deleted_name))
        page_file <- file.path(output_dir, paste0(filename, ".qmd"))
        if (file.exists(page_file)) {
          file.remove(page_file)
          message("Removed deleted page: ", deleted_name)
        }
      }
    }
    
    # Save manifest for next incremental build
    if (incremental) {
      .save_manifest(new_manifest, output_dir)
    }

    # Show build summary
    if (incremental && !quiet) {
      if (length(build_info$skipped) > 0) {
        message("Skipped ", length(build_info$skipped), " unchanged page(s): ",
                paste(head(build_info$skipped, 3), collapse = ", "),
                if (length(build_info$skipped) > 3) "..." else "")
      }
      if (length(build_info$regenerated) > 0) {
        message("Regenerated ", length(build_info$regenerated), " page(s): ",
                paste(head(build_info$regenerated, 3), collapse = ", "),
                if (length(build_info$regenerated) > 3) "..." else "")
      }
    }
    
    if (!quiet) message("Dashboard files generated successfully")

    # Render to HTML if requested
    render_success <- FALSE
    render_was_skipped <- FALSE
    if (render) {
      # Skip rendering if incremental and nothing changed
      if (incremental && length(build_info$regenerated) == 0) {
        if (!quiet) {
          message("✓ All pages unchanged - skipping Quarto rendering (incremental mode)")
          message("  Use render = TRUE, incremental = FALSE to force re-render")
          if (open == "browser") {
            message("  Note: Opening existing HTML (if available)")
          }
        }
        render_success <- TRUE  # Consider it successful since nothing needed rendering
        render_was_skipped <- TRUE
      } else {
        .progress_section("🎨 Rendering Dashboard", show_progress)
        render_start <- Sys.time()
        render_success <- .render_dashboard(output_dir, open, quiet, show_progress, proj$publish_dir, build_info$qmd_files)
        render_elapsed <- as.numeric(difftime(Sys.time(), render_start, units = "secs"))
        
        if (render_success) {
          .progress_step("Rendering complete", render_elapsed, show_progress)
        } else {
          if (!quiet) {
            message("\n❌ Rendering FAILED")
            message("   QMD files were generated successfully, but Quarto rendering failed")
            message("   Check the error/warning messages above for details")
          }
        }
      }
    }

    # Open browser if rendering was skipped but user requested it
    if (render_was_skipped && open == "browser") {
      output_dir_abs <- normalizePath(output_dir, mustWork = FALSE)
      publish_dir <- proj$publish_dir %||% "docs"
      # Resolve publish_dir relative to output_dir if it's a relative path
      if (!grepl("^(/|[A-Za-z]:)", publish_dir)) {
        publish_dir_abs <- normalizePath(file.path(output_dir_abs, publish_dir), mustWork = FALSE)
      } else {
        publish_dir_abs <- normalizePath(publish_dir, mustWork = FALSE)
      }
      index_file <- file.path(publish_dir_abs, "index.html")
      if (file.exists(index_file)) {
        if (!quiet) message("Opening existing dashboard in browser...")
        utils::browseURL(index_file)
      } else {
        if (!quiet) {
          warning("Cannot open browser - no HTML files exist yet. Run with render = TRUE to create them.")
        }
      }
    }
    
    # Calculate elapsed time
    elapsed_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    
    # Show beautiful CLI output after rendering (only if successful or not rendering)
    if (!quiet && (render_success || !render)) {
      .show_dashboard_summary(proj, output_dir, elapsed_time, build_info, show_progress)
    }

  }, error = function(e) {
    cat("\n=== DETAILED ERROR DEBUG ===\n")
    cat("Error message:", e$message, "\n\n")
    cat("Call stack with details:\n")
    calls <- sys.calls()
    for(i in seq_along(calls)) {
      cat(sprintf("%d: %s\n", i, deparse(calls[[i]])[1]))
    }
    cat("\n=== END DEBUG ===\n\n")
    stop("Failed to generate dashboard: ", e$message, call. = FALSE)
  })

  # Return project with build info and output directory
  result <- proj
  result$build_info <- build_info
  result$output_dir <- output_dir
  invisible(result)
}


.render_dashboard <- function(output_dir, open = FALSE, quiet = FALSE, show_progress = TRUE, publish_dir = NULL, qmd_files = NULL) {
  if (!requireNamespace("quarto", quietly = TRUE)) {
    if (!quiet) {
      message("quarto package not available. Skipping render.")
      message("Install with: install.packages('quarto')")
    }
    return(FALSE)
  }

  # Use provided publish_dir or default to "docs"
  publish_dir <- publish_dir %||% "docs"
  
  # Resolve publish_dir relative to output_dir if it's a relative path
  output_dir_abs <- normalizePath(output_dir, mustWork = FALSE)
  if (!grepl("^(/|[A-Za-z]:)", publish_dir)) {
    # Relative path - resolve relative to output_dir
    publish_dir_abs <- normalizePath(file.path(output_dir_abs, publish_dir), mustWork = FALSE)
  } else {
    # Absolute path - use as is
    publish_dir_abs <- normalizePath(publish_dir, mustWork = FALSE)
  }
  
  # Create publish folder even if rendering fails
  if (!dir.exists(publish_dir_abs)) {
    dir.create(publish_dir_abs, recursive = TRUE)
    if (!quiet) message("Created publish folder: ", publish_dir)
  }

  owd <- setwd(normalizePath(output_dir))
  on.exit(setwd(owd), add = TRUE)
  
  # Check for remnant .rmarkdown files that cause cryptic errors
  rmarkdown_files <- list.files(output_dir, pattern = "\\.rmarkdown$", recursive = TRUE)
  if (length(rmarkdown_files) > 0) {
    stop(
      "\n❌ REMNANT .rmarkdown FILE DETECTED\n\n",
      "Found .rmarkdown file(s) in output directory:\n",
      paste("  •", rmarkdown_files, collapse = "\n"), "\n\n",
      "These files cause Quarto rendering to fail with cryptic errors.\n\n",
      "To fix:\n",
      "  1. Delete the .rmarkdown file(s)\n",
      "  2. Make sure you're using .qmd files (not .Rmd or .rmarkdown)\n",
      "  3. Try rendering again\n\n",
      "Command to remove: rm ", rmarkdown_files[1], "\n"
    )
  }

  tryCatch({
    # Render with Quarto - only the specific files for this dashboard
    # If qmd_files is provided, render only those files; otherwise render all (fallback)
    if (!is.null(qmd_files) && length(qmd_files) > 0) {
      # Remove duplicates and ensure unique files
      qmd_files <- unique(qmd_files)
      
      if (!quiet) {
        message("Rendering ", length(qmd_files), " .qmd file(s)...")
      }
      
      # Render each file individually to avoid rendering files from other dashboards
      for (qmd_file in qmd_files) {
        if (quiet) {
          invisible(capture.output(quarto::quarto_render(qmd_file, as_job = FALSE), type = "message"))
        } else {
          quarto::quarto_render(qmd_file, as_job = FALSE)
        }
      }
    } else {
      # Fallback: render entire project (original behavior)
      if (!quiet) {
        message("Rendering entire project...")
      }
      if (quiet) {
        # Completely silent
        invisible(capture.output(quarto::quarto_render(".", as_job = FALSE), type = "message"))
      } else {
        # Show Quarto's normal output
        quarto::quarto_render(".", as_job = FALSE)
      }
    }
    
    if (!quiet) message("Dashboard rendered successfully")

    # Open in browser if requested and render succeeded
    if (open == "browser") {
      # Use the resolved publish_dir_abs from earlier
      index_file <- file.path(publish_dir_abs, "index.html")
      
      if (file.exists(index_file)) {
        if (!quiet) message("Opening dashboard in browser...")
        utils::browseURL(index_file)
      } else {
        # Check what files exist in publish_dir for helpful error message
        if (dir.exists(publish_dir_abs)) {
          html_files <- list.files(publish_dir_abs, pattern = "\\.html$", full.names = FALSE)
        } else {
          html_files <- character(0)
        }
        
        if (!quiet) {
          warning(
            "Could not find index.html to open in browser\n",
            "  Expected: ", index_file, "\n",
            "  publish_dir (", publish_dir, ") exists: ", dir.exists(publish_dir_abs), "\n",
            "  HTML files in publish_dir: ", if (length(html_files) > 0) paste(html_files, collapse = ", ") else "(none)", "\n",
            "\n",
            "  Possible reasons:\n",
            "  1. Rendering failed (check error messages above)\n",
            "  2. Quarto output directory mismatch\n",
            "  3. Landing page has different name\n",
            "\n",
            "  Try:\n",
            "  • Check for errors in Quarto output above\n",
            "  • Look in: ", publish_dir_abs
          )
        }
      }
    }
    return(TRUE)
  }, error = function(e) {
    warning("Failed to render dashboard: ", e$message)

    # Check if it's an iconify extension error
    # if (grepl("iconify", e$message, ignore.case = TRUE)) {
    #   message("\n=== ICONIFY EXTENSION ERROR ===")
    #   message("The iconify extension is not installed. To fix this:")
    #   message("1. Install Quarto CLI: https://quarto.org/docs/get-started/")
    #   message("2. Run in your dashboard directory: quarto add mcanouil/quarto-iconify")
    #   message("3. Or run the provided script: ./install_iconify_manual.sh")
    #   message("\nAlternative: Remove icons from your dashboard calls to render without icons")
    # } else {
    #   message("To fix this issue:")
    #   message("1. Install Quarto command-line tools from: https://quarto.org/docs/get-started/")
    #   message("2. Or run 'quarto install' in R to install via the quarto package")
    # }
    # message("3. The QMD files are ready for manual rendering with: quarto render")
    return(FALSE)
  })
}

# ===================================================================
# Custom Print Methods for Better User Experience
# ===================================================================

#' Print Dashboard Project
#'
#' Displays a comprehensive summary of a dashboard project, including metadata,
#' features, pages, visualizations, and integrations.
#'
#' @param x A dashboard_project object created by \code{\link{create_dashboard}}.
#' @param ... Additional arguments (currently ignored).
#'
#' @return Invisibly returns the input object \code{x}.
#'
#' @details
#' The print method displays:
#' \itemize{
#'   \item Project metadata (title, author, description)
#'   \item Output directory
#'   \item Enabled features (sidebar, search, themes, Shiny, Observable)
#'   \item Integrations (GitHub, Twitter, LinkedIn, Analytics)
#'   \item Page structure with properties:
#'     \itemize{
#'       \item 🏠 Landing page indicator
#'       \item ⏳ Loading overlay indicator
#'       \item → Right-aligned navbar indicator
#'       \item 💾 Associated datasets
#'       \item Nested visualization hierarchies
#'     }
#' }
#'


#' Show beautiful dashboard summary
#'
#' Internal function that displays a comprehensive summary of the generated
#' dashboard files and provides helpful guidance to users.
#'
#' @param proj A dashboard_project object
#' @param output_dir Path to the output directory
#' @return Invisible NULL
#' @keywords internal
.show_dashboard_summary <- function(proj, output_dir, elapsed_time = NULL, build_info = NULL, show_progress = TRUE) {
  if (!show_progress) return(invisible(NULL))
  
  cat("\n")
  cat("╔═══════════════════════════════════════════════════╗\n")
  cat("║     🎉 DASHBOARD GENERATED SUCCESSFULLY! 🎉      ║\n")
  cat("╚═══════════════════════════════════════════════════╝\n")
  cat("\n")

  # Dashboard info with enhanced formatting
  cat("📊 Dashboard:", proj$title, "\n")
  cat("📁 Location:", output_dir, "\n")
  cat("📄 Pages:", length(proj$pages), "\n")

  # Count visualizations
  total_viz <- 0
  for (page in proj$pages) {
    if (!is.null(page$visualizations)) {
      total_viz <- total_viz + length(page$visualizations)
    }
  }
  cat("📈 Visualizations:", total_viz, "\n")
  
  # Show build info if available (incremental builds)
  if (!is.null(build_info)) {
    if (length(build_info$regenerated) > 0) {
      cat("🔄 Regenerated:", length(build_info$regenerated), "page(s)\n")
    }
    if (length(build_info$skipped) > 0) {
      cat("⏭️  Skipped:", length(build_info$skipped), "unchanged page(s)\n")
    }
  }
  
  # Display generation time if available
  if (!is.null(elapsed_time)) {
    time_str <- if (elapsed_time < 1) {
      paste0(round(elapsed_time * 1000, 1), " ms")
    } else if (elapsed_time < 60) {
      paste0(round(elapsed_time, 2), " seconds")
    } else {
      mins <- floor(elapsed_time / 60)
      secs <- round(elapsed_time %% 60, 1)
      paste0(mins, " min ", secs, " sec")
    }
    cat("⏱️  Total time:", time_str, "\n")
  }

  cat("\n")
  cat("📁 GENERATED FILES:\n")
  cat(paste(rep("─", 30), collapse = ""), "\n")

  # List all generated files (exclude site_libs and hidden files)
  files <- list.files(output_dir, recursive = TRUE, full.names = FALSE)
  files <- files[!grepl("^\\.", files)] # Exclude hidden files
  files <- files[!grepl("^docs/site_libs/", files)] # Exclude site_libs files

  # Group files by type
  qmd_files <- files[grepl("\\.qmd$", files)]
  rds_files <- files[grepl("\\.rds$", files)]
  yml_files <- files[grepl("\\.yml$", files)]
  other_files <- files[!grepl("\\.(qmd|rds|yml)$", files)]

  # Display QMD files (pages)
  if (length(qmd_files) > 0) {
    cat("📄 Pages (QMD files):\n")
    for (file in sort(qmd_files)) {
      page_name <- gsub("\\.qmd$", "", file)
      page_name <- gsub("_", " ", page_name)
      page_name <- tools::toTitleCase(page_name)
      cat("   • ", file, " → ", page_name, "\n", sep = "")
    }
    cat("\n")
  }

  # Display data files with page mapping
  if (length(rds_files) > 0) {
    cat("💾 Data files:\n")
    
    # Build mapping from data files to pages
    data_to_pages <- list()
    for (page_name in names(proj$pages)) {
      page <- proj$pages[[page_name]]
      if (!is.null(page$data_path)) {
        if (is.list(page$data_path)) {
          # Multiple datasets
          for (dataset_name in names(page$data_path)) {
            data_file <- basename(page$data_path[[dataset_name]])
            if (is.null(data_to_pages[[data_file]])) {
              data_to_pages[[data_file]] <- list(pages = c(), dataset_name = dataset_name)
            }
            data_to_pages[[data_file]]$pages <- c(data_to_pages[[data_file]]$pages, page_name)
          }
        } else {
          # Single dataset
          data_file <- basename(page$data_path)
          if (is.null(data_to_pages[[data_file]])) {
            data_to_pages[[data_file]] <- list(pages = c(), dataset_name = NULL)
          }
          data_to_pages[[data_file]]$pages <- c(data_to_pages[[data_file]]$pages, page_name)
        }
      }
    }
    
    for (file in sort(rds_files)) {
      file_size <- file.size(file.path(output_dir, file))
      size_str <- if (file_size > 1024*1024) {
        paste0(round(file_size/(1024*1024), 1), " MB")
      } else if (file_size > 1024) {
        paste0(round(file_size/1024, 1), " KB")
      } else {
        paste0(file_size, " B")
      }
      
      # Show which pages use this data
      if (!is.null(data_to_pages[[file]]) && length(data_to_pages[[file]]$pages) > 0) {
        pages_str <- paste(data_to_pages[[file]]$pages, collapse = ", ")
        cat("   • ", file, " (", size_str, ") → Used by: ", pages_str, "\n", sep = "")
      } else {
        cat("   • ", file, " (", size_str, ")\n", sep = "")
      }
    }
    cat("\n")
  }

  # Display configuration files
  if (length(yml_files) > 0) {
    cat("⚙️  Configuration:\n")
    for (file in sort(yml_files)) {
      cat("   • ", file, "\n", sep = "")
    }
    cat("\n")
  }

  # Display other files
  if (length(other_files) > 0) {
    cat("📎 Other files:\n")
    for (file in sort(other_files)) {
      cat("   • ", file, "\n", sep = "")
    }
    cat("\n")
  }

  # Next steps
  cat("🚀 NEXT STEPS:\n")
  cat(paste(rep("─", 30), collapse = ""), "\n")
  cat("1. Edit your dashboard:\n")
  cat("   • Modify QMD files to customize content and styling\n")
  cat("   • Add more visualizations using add_viz() with height parameters\n")
  cat("   • Customize the _quarto.yml configuration file\n")
  cat("\n")
  cat("2. Generate a new dashboard:\n")
  cat("   • Use create_dashboard() %>% add_page() %>% generate_dashboard()\n")
  cat("   • Try different themes, layouts, and features\n")
  cat("   • Experiment with height parameters for better proportions\n")
  cat("\n")
  cat("3. Deploy your dashboard:\n")
  cat("   • Use Quarto's publishing features (GitHub Pages, Netlify, etc.)\n")
  cat("   • Share the docs/ folder contents\n")
  cat("\n")


  cat("🎯 Happy dashing!\n")
  cat(paste(rep("═", 50), collapse = ""), "\n")
  cat("\n")

  invisible(NULL)
}

# ===================================================================
# Pagination Helper Functions
# ===================================================================

#' Check if page has pagination markers
#'
#' Internal function to detect if a page contains pagination markers
#'
#' @param page Page object
#' @return Logical indicating if page has pagination
#' @keywords internal
.has_pagination_markers <- function(page) {
  if (is.null(page$visualizations) || length(page$visualizations) == 0) {
    return(FALSE)
  }
  
  any(sapply(page$visualizations, function(x) {
    !is.null(x$pagination_break) && isTRUE(x$pagination_break)
  }))
}

#' Generate multiple QMD files for a paginated page
#'
#' Internal function that splits a paginated page into multiple QMD files
#' and writes them with appropriate navigation controls.
#'
#' @param page Page object
#' @param page_name Name of the page
#' @param base_page_file Path to the main page file (e.g., "analysis.qmd")
#' @param output_dir Output directory
#' @param theme Quarto theme name
#' @param default_position Default pagination position from dashboard config (default: "bottom")
#' @return Character vector of generated .qmd filenames (basenames only)
#' @keywords internal
.generate_paginated_page_files <- function(page, page_name, base_page_file, output_dir, theme, default_position = "bottom") {
  # Split visualizations by pagination markers
  sections <- .split_by_pagination(page$visualizations)
  
  if (length(sections) == 0) {
    stop("Page marked for pagination but no sections found")
  }
  
  # Get base name for files (without .qmd extension)
  base_name <- sub("\\.qmd$", "", basename(base_page_file))
  
  # Track generated files
  generated_files <- character()
  
  # Determine pagination position - use per-page setting if specified, otherwise use dashboard default
  pagination_position <- default_position  # Start with dashboard default
  for (sect in sections) {
    if (!is.null(sect$pagination_after$pagination_position)) {
      pagination_position <- sect$pagination_after$pagination_position
      break  # Use first per-page override found
    }
  }
  
  # Generate each page
  for (i in seq_along(sections)) {
    section <- sections[[i]]
    
    # Determine file name
    page_file <- if (i == 1) {
      base_page_file  # First section uses main page name
    } else {
      file.path(output_dir, paste0(base_name, "_p", i, ".qmd"))
    }
    
    # Create modified page object for this section
    section_page <- page
    section_page$visualizations <- section$items  # Only include this section's visualizations
    
    # Generate base content
    content <- .generate_default_page_content(section_page)
    
    # Generate pagination navigation (position determined above for all pages)
    nav_content_bottom <- NULL
    nav_content_top <- NULL
    
    if (pagination_position %in% c("bottom", "both")) {
      nav_content_bottom <- .generate_pagination_nav(
        page_num = i,
        total_pages = length(sections),
        base_name = base_name,
        theme = theme,
        position = "bottom",
        separator_text = page$pagination_separator %||% "/"
      )
    }
    
    if (pagination_position %in% c("top", "both")) {
      nav_content_top <- .generate_pagination_nav(
        page_num = i,
        total_pages = length(sections),
        base_name = base_name,
        theme = theme,
        position = "top",
        separator_text = page$pagination_separator %||% "/"
      )
    }
    
    # Combine content with navigation(s)
    # Need to insert top nav AFTER YAML frontmatter, not before
    if (!is.null(nav_content_top)) {
      # Find where YAML ends (second "---")
      yaml_end <- which(content == "---")[2]
      if (!is.na(yaml_end) && yaml_end > 0) {
        # Insert top nav after YAML
        full_content <- c(
          content[1:yaml_end],  # YAML frontmatter
          "",
          nav_content_top,      # Top navigation
          "",
          content[(yaml_end+1):length(content)],  # Rest of content
          "",
          nav_content_bottom    # Bottom navigation
        )
      } else {
        # No YAML found, prepend as before
        full_content <- c(nav_content_top, "", content, "", nav_content_bottom)
      }
    } else {
      # No top nav, just append bottom nav
      full_content <- c(content, "", nav_content_bottom)
    }
    
    # Write file
    writeLines(full_content, page_file)
    
    # Track this generated file
    generated_files <- c(generated_files, basename(page_file))
  }
  
  # Return list of generated filenames for targeted rendering
  generated_files
}

# ===================================================================
# Internal Visualization Processing
# ===================================================================

#' Process visualizations into organized specs with tab groups
#'
#' Unified internal function that handles both viz_collection and plain list inputs,
#' organizing visualizations into standalone items and tab groups based on their
#' tabgroup parameter.
#'
#' @param viz_input Either a viz_collection object or a plain list of visualization specs
#' @param data_path Path to the data file for this page (will be attached to each viz)
#' @param tabgroup_labels Optional named list/vector of custom display labels for tab groups
#' @return List of processed visualization specs, with standalone visualizations first,
#'         followed by tab group objects
#' @details
#' Build a hierarchy key from a tabgroup vector


# ===================================================================
# Batch Dashboard Generation
# ===================================================================

#' Generate multiple dashboards
#'
#' Generates a list of dashboard projects in batch, with progress tracking
#' and error handling. Useful for generating many related dashboards
#' (e.g., one per country, per topic, etc.) in a single workflow.
#'
#' @param dashboards Named list of dashboard_project objects created with create_dashboard().
#'   When \code{linked = TRUE}, the first dashboard is the main/parent and others are
#'   sub-dashboards that will be output into subdirectories of the main's docs folder.
#' @param render Whether to render each dashboard to HTML (default TRUE)
#' @param open Whether to open the main dashboard after generation (default FALSE)
#' @param continue_on_error Continue generating remaining dashboards if one fails (default TRUE)
#' @param show_progress Whether to show progress for each dashboard (default TRUE)
#' @param quiet Whether to suppress output (default FALSE)
#' @param linked Whether dashboards are linked (default FALSE). When TRUE:
#'   \itemize{
#'     \item First dashboard is treated as the main/parent dashboard
#'     \item Other dashboards are output to subdirectories of main's docs folder
#'     \item Use list names as subdirectory names (e.g., list(main = ..., US = ..., DE = ...))
#'     \item Click navigation like \code{click_url_template = "\{iso2c\}/index.html"} will work
#'   }
#' @return Invisibly returns a list of results, one per dashboard, containing:
#'   \itemize{
#'     \item \code{success}: logical, whether generation succeeded
#'     \item \code{title}: dashboard title
#'     \item \code{output_dir}: output directory path
#'     \item \code{error}: error message if failed (only present on failure)
#'     \item \code{duration}: generation time in seconds
#'   }
#' @export
#' @examples
#' \dontrun{
#' # Linked dashboards with map navigation
#' main_db <- create_dashboard("Main", output_dir = "project") %>%
#'   add_page("Map", data = summary_data, 
#'            visualizations = create_viz() %>% 
#'              add_viz(type = "map", click_url_template = "{iso2c}/index.html"))
#' 
#' us_db <- create_dashboard("US Details", output_dir = "project/US") %>%
#'   add_page("Analysis", data = us_data)
#' 
#' de_db <- create_dashboard("DE Details", output_dir = "project/DE") %>%
#'   add_page("Analysis", data = de_data)
#' 
#' # Generate with linked = TRUE - outputs go to project/docs/, project/docs/US/, etc.
#' generate_dashboards(
#'   list(main = main_db, US = us_db, DE = de_db),
#'   linked = TRUE
#' )
#' }
generate_dashboards <- function(
    dashboards,
    render = TRUE,
    open = FALSE,
    continue_on_error = TRUE,
    show_progress = TRUE,
    quiet = FALSE,
    linked = FALSE
) {
  # Validate input
  if (!is.list(dashboards) || length(dashboards) == 0) {
    stop("dashboards must be a non-empty list of dashboard_project objects")
  }
  
  n <- length(dashboards)
  results <- vector("list", n)
  
  # Handle linked dashboards - set publish_dir so sub-dashboards output into main's docs folder
  if (linked && n > 1) {
    # First dashboard is the main/parent
    main_db <- dashboards[[1]]
    main_output_dir <- main_db$output_dir
    main_publish_dir <- main_db$publish_dir %||% "docs"
    
    # Get names for subdirectories
    db_names <- names(dashboards)
    if (is.null(db_names) || db_names[1] == "") {
      db_names <- c("main", paste0("sub_", seq_len(n - 1)))
    }
    
    # Set publish_dir for sub-dashboards to go into main's docs folder
    # Sub-dashboard at OUTPUT_DIR/{name}/ publishes to OUTPUT_DIR/docs/{name}/
    for (i in 2:n) {
      sub_name <- db_names[i]
      if (is.null(sub_name) || sub_name == "") {
        sub_name <- paste0("sub_", i - 1)
      }
      
      # publish_dir is relative to the sub's output_dir
      # From OUTPUT_DIR/{name}/, we want to go to OUTPUT_DIR/docs/{name}/
      dashboards[[i]]$publish_dir <- file.path("..", main_publish_dir, sub_name)
    }
    
    if (!quiet) {
      cli::cli_alert_info("Linked mode: sub-dashboards output to {main_output_dir}/{main_publish_dir}/{{name}}/")
    }
  }
  
  # Get dashboard names/titles for display
  get_title <- function(db) {
    if (inherits(db, "dashboard_project")) {
      db$title %||% db$output_dir %||% "Unnamed"
    } else {
      "Invalid"
    }
  }
  
  if (!quiet) {
    cli::cli_h1("Generating {n} dashboard{?s}")
  }
  
  for (i in seq_len(n)) {
    db <- dashboards[[i]]
    title <- get_title(db)
    start_time <- Sys.time()
    
    if (!quiet && show_progress) {
      cli::cli_alert_info("[{i}/{n}] {title}")
    }
    
    # Validate it's a dashboard project
    if (!inherits(db, "dashboard_project")) {
      results[[i]] <- list(
        success = FALSE,
        title = title,
        error = "Not a dashboard_project object",
        duration = 0
      )
      if (!quiet) {
        cli::cli_alert_danger("  Skipped: not a dashboard_project")
      }
      next
    }
    
    # Generate the dashboard
    results[[i]] <- tryCatch({
      generate_dashboard(
        db,
        render = render,
        open = FALSE,  # Don't open individual dashboards in batch mode
        quiet = quiet || !show_progress
      )
      
      duration <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
      
      if (!quiet && show_progress) {
        cli::cli_alert_success("  Done in {round(duration, 1)}s")
      }
      
      list(
        success = TRUE,
        title = title,
        output_dir = db$output_dir,
        duration = duration
      )
    }, error = function(e) {
      duration <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
      
      if (!quiet) {
        cli::cli_alert_danger("  Failed: {conditionMessage(e)}")
      }
      
      if (!continue_on_error) {
        stop(e)
      }
      
      list(
        success = FALSE,
        title = title,
        output_dir = db$output_dir,
        error = conditionMessage(e),
        duration = duration
      )
    })
  }
  
  # Summary
  ok <- sum(vapply(results, function(r) isTRUE(r$success), logical(1)))
  total_time <- sum(vapply(results, function(r) r$duration %||% 0, numeric(1)))
  
  if (!quiet) {
    cli::cli_rule()
    if (ok == n) {
      cli::cli_alert_success("Generated {ok}/{n} dashboards in {round(total_time, 1)}s")
    } else {
      cli::cli_alert_warning("Generated {ok}/{n} dashboards ({n - ok} failed) in {round(total_time, 1)}s")
    }
  }
  
  # Open main dashboard if requested
  if (open && ok > 0) {
    # For linked dashboards, open the main (first) dashboard's docs folder
    main_db <- dashboards[[1]]
    main_output_dir <- main_db$output_dir
    main_publish_dir <- main_db$publish_dir %||% "docs"
    
    # Try docs folder first, then root
    index_path <- file.path(main_output_dir, main_publish_dir, "index.html")
    if (!file.exists(index_path)) {
      index_path <- file.path(main_output_dir, "index.html")
    }
    
    if (file.exists(index_path)) {
      if (!quiet) {
        cli::cli_alert_info("Opening {index_path}")
      }
      utils::browseURL(index_path)
    }
  }
  
  invisible(results)
}
