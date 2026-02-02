# =================================================================
# Input Filter Helpers for dashboardr
# =================================================================

#' Enable Sidebar Styling
#'
#' Adds modern CSS styling for sidebar panels. Called automatically
#' when a page includes a sidebar via add_sidebar().
#'
#' @return HTML tags to include sidebar CSS
#' @export
#'
#' @examples
#' \dontrun{
#' # Usually called automatically, but can be added manually:
#' enable_sidebar()
#' }
enable_sidebar <- function() {
  # Add version parameter to bust cache
  version <- format(Sys.time(), "%Y%m%d%H%M%S")
  
  htmltools::tagList(
    htmltools::tags$link(
      rel = "stylesheet",
      href = paste0("assets/sidebar.css?v=", version)
    )
  )
}

#' Enable Input Filter Functionality
#'
#' Adds input filter CSS and JavaScript to enable interactive filtering
#' of Highcharts visualizations via multi-select dropdowns.
#' Uses Choices.js for a polished multi-select experience.
#'
#' @return HTML tags to include input filter functionality
#' @export
#'
#' @examples
#' \dontrun{
#' # In your dashboard page content:
#' enable_inputs()
#' }
enable_inputs <- function() {
  # Add version parameter to bust cache
  version <- format(Sys.time(), "%Y%m%d%H%M%S")
  
  htmltools::tagList(
    # Choices.js from CDN
    htmltools::tags$link(
      rel = "stylesheet",
      href = "https://cdn.jsdelivr.net/npm/choices.js@10.2.0/public/assets/styles/choices.min.css"
    ),
    htmltools::tags$script(
      src = "https://cdn.jsdelivr.net/npm/choices.js@10.2.0/public/assets/scripts/choices.min.js"
    ),
    # Our custom CSS
    htmltools::tags$link(
      rel = "stylesheet",
      href = paste0("assets/input_filter.css?v=", version)
    ),
    # Our custom JS
    htmltools::tags$script(
      src = paste0("assets/filter_hook.js?v=", version)
    ),
    htmltools::tags$script(
      src = paste0("assets/input_filter.js?v=", version)
    )
  )
}

# =================================================================
# OPTIONS LOOKUP HELPER
# =================================================================

#' Look up options from data
#' @keywords internal
.get_options_from_data <- function(options_from) {
  if (is.null(options_from)) return(NULL)
  
  found_data <- NULL
  
  # Try global environment
  if (exists("data", envir = globalenv())) {
    found_data <- get("data", envir = globalenv())
  }
  
  # Try parent frames
  if (is.null(found_data)) {
    for (i in 1:10) {
      env <- tryCatch(parent.frame(i + 1), error = function(e) NULL)
      if (is.null(env)) break
      if (exists("data", envir = env, inherits = FALSE)) {
        found_data <- get("data", envir = env)
        break
      }
    }
  }
  
  # Try knitr environment
  if (is.null(found_data) && requireNamespace("knitr", quietly = TRUE)) {
    knit_env <- knitr::knit_global()
    if (exists("data", envir = knit_env)) {
      found_data <- get("data", envir = knit_env)
    }
  }
  
  if (!is.null(found_data) && is.data.frame(found_data)) {
    if (options_from %in% names(found_data)) {
      return(sort(unique(as.character(found_data[[options_from]]))))
    }
  }
  
  NULL
}

# =================================================================
# MARGIN STYLE HELPER
# =================================================================

#' Build CSS margin style string from individual margin parameters
#' @keywords internal
.build_margin_style <- function(mt = NULL, mr = NULL, mb = NULL, ml = NULL) {
  parts <- c()
  if (!is.null(mt) && nzchar(mt)) parts <- c(parts, paste0("margin-top: ", mt, ";"))
  if (!is.null(mr) && nzchar(mr)) parts <- c(parts, paste0("margin-right: ", mr, ";"))
  if (!is.null(mb) && nzchar(mb)) parts <- c(parts, paste0("margin-bottom: ", mb, ";"))
  if (!is.null(ml) && nzchar(ml)) parts <- c(parts, paste0("margin-left: ", ml, ";"))
  paste(parts, collapse = " ")
}

# =================================================================
# CORE HTML GENERATORS (Single Source of Truth)
# =================================================================

#' Generate HTML for select input
#' @keywords internal
.generate_select_html <- function(input_id, label, type, filter_var, options,
                                   default_selected, placeholder, width, align,
                                   size = "md", help = NULL, disabled = FALSE) {
  if (is.null(default_selected)) default_selected <- options
  is_multiple <- type == "select_multiple"
  
  size_class <- paste0(" size-", size)
  disabled_attr <- if (disabled) ' disabled' else ''
  

  html_lines <- c()
  html_lines <- c(html_lines, paste0('<div class="dashboardr-input-group align-', align, size_class, '" style="width: ', width, ';">'))
  
  if (!is.null(label) && nzchar(label)) {
    html_lines <- c(html_lines, paste0('  <label class="dashboardr-input-label" for="', input_id, '">', label, '</label>'))
  }
  
  multiple_attr <- if (is_multiple) ' multiple' else ''
  html_lines <- c(html_lines, paste0('  <select id="', input_id, '" class="dashboardr-input" data-filter-var="', filter_var, '" data-input-type="select" data-placeholder="', placeholder, '"', multiple_attr, disabled_attr, '>'))
  
  # Handle grouped options (named list) vs flat options (vector)
  if (is.list(options) && !is.null(names(options))) {
    for (group_name in names(options)) {
      html_lines <- c(html_lines, paste0('    <optgroup label="', htmltools::htmlEscape(group_name), '">'))
      for (opt in options[[group_name]]) {
        selected <- if (opt %in% default_selected) ' selected' else ''
        html_lines <- c(html_lines, paste0('      <option value="', htmltools::htmlEscape(opt), '"', selected, '>', htmltools::htmlEscape(opt), '</option>'))
      }
      html_lines <- c(html_lines, '    </optgroup>')
    }
  } else {
    for (opt in options) {
      selected <- if (opt %in% default_selected) ' selected' else ''
      html_lines <- c(html_lines, paste0('    <option value="', htmltools::htmlEscape(opt), '"', selected, '>', htmltools::htmlEscape(opt), '</option>'))
    }
  }
  
  html_lines <- c(html_lines, '  </select>')
  
  # Help text
  if (!is.null(help) && nzchar(help)) {
    html_lines <- c(html_lines, paste0('  <span class="dashboardr-input-help">', htmltools::htmlEscape(help), '</span>'))
  }
  
  html_lines <- c(html_lines, paste0('<script>if(typeof dashboardrFilterHook!=="undefined")dashboardrFilterHook("', input_id, '","', filter_var, '");</script>'))
  html_lines <- c(html_lines, '</div>')
  
  paste(html_lines, collapse = "\n")
}

#' Generate HTML for checkbox input
#' @keywords internal
.generate_checkbox_html <- function(input_id, label, filter_var, options,
                                     default_selected, width, align, inline,
                                     size = "md", help = NULL, disabled = FALSE,
                                     columns = NULL, stacked = FALSE,
                                     stacked_align = "center",
                                     group_align = "left",
                                     ncol = NULL, nrow = NULL) {
  if (is.null(default_selected)) default_selected <- options
  
 # Build layout class: stacked takes priority, then inline, then columns, then default (vertical)
  layout_class <- ""
  grid_style <- ""
  if (stacked) {
    layout_class <- paste0(" stacked align-", stacked_align, " group-", group_align)
    # If ncol or nrow specified, use CSS grid
    if (!is.null(ncol) && ncol > 0) {
      layout_class <- paste0(layout_class, " stacked-grid")
      grid_style <- sprintf("grid-template-columns: repeat(%d, 1fr);", ncol)
    } else if (!is.null(nrow) && nrow > 0) {
      # Calculate ncol from nrow and number of options
      n_opts <- length(options)
      calc_ncol <- ceiling(n_opts / nrow)
      layout_class <- paste0(layout_class, " stacked-grid")
      grid_style <- sprintf("grid-template-columns: repeat(%d, 1fr);", calc_ncol)
    }
  } else if (inline) {
    layout_class <- " inline"
  } else if (!is.null(columns) && columns %in% c(2, 3, 4)) {
    layout_class <- paste0(" grid-", columns)
  }
  
  size_class <- paste0(" size-", size)
  disabled_attr <- if (disabled) ' disabled' else ''
  
  html_lines <- c()
  html_lines <- c(html_lines, paste0('<div class="dashboardr-input-group align-', align, size_class, '" style="width: ', width, ';">'))
  
  if (!is.null(label) && nzchar(label)) {
    html_lines <- c(html_lines, paste0('  <label class="dashboardr-input-label">', label, '</label>'))
  }
  
  style_attr <- if (nchar(grid_style) > 0) paste0(' style="', grid_style, '"') else ""
  html_lines <- c(html_lines, paste0('  <div id="', input_id, '" class="dashboardr-checkbox-group', layout_class, '"', style_attr, ' data-filter-var="', filter_var, '" data-input-type="checkbox">'))
  
  for (i in seq_along(options)) {
    opt <- options[i]
    checked <- if (opt %in% default_selected) ' checked' else ''
    opt_id <- paste0(input_id, '_', i)
    html_lines <- c(html_lines,
      paste0('    <label class="dashboardr-checkbox">'),
      paste0('      <input type="checkbox" id="', opt_id, '" name="', input_id, '" value="', htmltools::htmlEscape(opt), '"', checked, disabled_attr, '>'),
      paste0('      <span class="dashboardr-checkbox-mark"></span>'),
      paste0('      <span class="dashboardr-checkbox-text">', htmltools::htmlEscape(opt), '</span>'),
      paste0('    </label>'))
  }
  
  html_lines <- c(html_lines, '  </div>')
  
  if (!is.null(help) && nzchar(help)) {
    html_lines <- c(html_lines, paste0('  <span class="dashboardr-input-help">', htmltools::htmlEscape(help), '</span>'))
  }
  
  html_lines <- c(html_lines, paste0('<script>if(typeof dashboardrFilterHook!=="undefined")dashboardrFilterHook("', input_id, '","', filter_var, '");</script>'))
  html_lines <- c(html_lines, '</div>')
  
  paste(html_lines, collapse = "\n")
}

#' Generate HTML for radio input
#' @keywords internal
.generate_radio_html <- function(input_id, label, filter_var, options,
                                  default_selected, width, align, inline,
                                  size = "md", help = NULL, disabled = FALSE,
                                  columns = NULL, stacked = FALSE, 
                                  stacked_align = "center",
                                  group_align = "left",
                                  ncol = NULL, nrow = NULL) {
  if (is.null(default_selected) && length(options) > 0) default_selected <- options[1]
  
  # Build layout class: stacked takes priority, then inline, then columns, then default (vertical)
  layout_class <- ""
  grid_style <- ""
  if (stacked) {
    layout_class <- paste0(" stacked align-", stacked_align, " group-", group_align)
    # If ncol or nrow specified, use CSS grid
    if (!is.null(ncol) && ncol > 0) {
      layout_class <- paste0(layout_class, " stacked-grid")
      grid_style <- sprintf("grid-template-columns: repeat(%d, 1fr);", ncol)
    } else if (!is.null(nrow) && nrow > 0) {
      # Calculate ncol from nrow and number of options
      n_opts <- length(options)
      calc_ncol <- ceiling(n_opts / nrow)
      layout_class <- paste0(layout_class, " stacked-grid")
      grid_style <- sprintf("grid-template-columns: repeat(%d, 1fr);", calc_ncol)
    }
  } else if (inline) {
    layout_class <- " inline"
  } else if (!is.null(columns) && columns %in% c(2, 3, 4)) {
    layout_class <- paste0(" grid-", columns)
  }
  
  size_class <- paste0(" size-", size)
  disabled_attr <- if (disabled) ' disabled' else ''
  
  html_lines <- c()
  html_lines <- c(html_lines, paste0('<div class="dashboardr-input-group align-', align, size_class, '" style="width: ', width, ';">'))
  
  if (!is.null(label) && nzchar(label)) {
    html_lines <- c(html_lines, paste0('  <label class="dashboardr-input-label">', label, '</label>'))
  }
  
  style_attr <- if (nchar(grid_style) > 0) paste0(' style="', grid_style, '"') else ""
  html_lines <- c(html_lines, paste0('  <div id="', input_id, '" class="dashboardr-radio-group', layout_class, '"', style_attr, ' data-filter-var="', filter_var, '" data-input-type="radio">'))
  
  for (i in seq_along(options)) {
    opt <- options[i]
    checked <- if (opt %in% default_selected) ' checked' else ''
    opt_id <- paste0(input_id, '_', i)
    html_lines <- c(html_lines,
      paste0('    <label class="dashboardr-radio">'),
      paste0('      <input type="radio" id="', opt_id, '" name="', input_id, '" value="', htmltools::htmlEscape(opt), '"', checked, disabled_attr, '>'),
      paste0('      <span class="dashboardr-radio-mark"></span>'),
      paste0('      <span class="dashboardr-radio-text">', htmltools::htmlEscape(opt), '</span>'),
      paste0('    </label>'))
  }
  
  html_lines <- c(html_lines, '  </div>')
  
  if (!is.null(help) && nzchar(help)) {
    html_lines <- c(html_lines, paste0('  <span class="dashboardr-input-help">', htmltools::htmlEscape(help), '</span>'))
  }
  
  html_lines <- c(html_lines, paste0('<script>if(typeof dashboardrFilterHook!=="undefined")dashboardrFilterHook("', input_id, '","', filter_var, '");</script>'))
  html_lines <- c(html_lines, '</div>')
  
  paste(html_lines, collapse = "\n")
}

#' Generate HTML for switch input
#' @keywords internal
.generate_switch_html <- function(input_id, label, filter_var, value, width, align,
                                   toggle_series = NULL, override = FALSE,
                                   size = "md", help = NULL, disabled = FALSE) {
  checked <- if (isTRUE(value)) ' checked' else ''
  size_class <- paste0(" size-", size)
  disabled_attr <- if (disabled) ' disabled' else ''
  
  # Build toggle_series attribute if specified
  toggle_attr <- if (!is.null(toggle_series) && nzchar(toggle_series)) {
    paste0('data-toggle-series="', htmltools::htmlEscape(toggle_series), '" ')
  } else {
    ''
  }
  
  # Build override attribute if TRUE
  override_attr <- if (isTRUE(override)) 'data-override="true" ' else ''
  
  html_lines <- c()
  html_lines <- c(html_lines, paste0('<div class="dashboardr-input-group align-', align, size_class, '" style="width: ', width, ';">'))
  html_lines <- c(html_lines, '  <label class="dashboardr-switch-container">')
  
  if (!is.null(label) && nzchar(label)) {
    html_lines <- c(html_lines, paste0('    <span class="dashboardr-switch-label">', label, '</span>'))
  }
  
  html_lines <- c(html_lines,
    '    <div class="dashboardr-switch">',
    paste0('      <input type="checkbox" id="', input_id, '" data-filter-var="', filter_var, '" data-input-type="switch" ', toggle_attr, override_attr, checked, disabled_attr, '>'),
    '      <span class="dashboardr-switch-slider"></span>',
    '    </div>',
    '  </label>')
  
  if (!is.null(help) && nzchar(help)) {
    html_lines <- c(html_lines, paste0('  <span class="dashboardr-input-help">', htmltools::htmlEscape(help), '</span>'))
  }
  
  html_lines <- c(html_lines, paste0('<script>if(typeof dashboardrFilterHook!=="undefined")dashboardrFilterHook("', input_id, '","', filter_var, '");</script>'))
  html_lines <- c(html_lines, '</div>')
  
  paste(html_lines, collapse = "\n")
}

#' Generate HTML for slider input
#' @keywords internal
.generate_slider_html <- function(input_id, label, filter_var, min, max, step,
                                   value, show_value, width, align,
                                   labels = NULL, size = "md", help = NULL, disabled = FALSE) {
  if (is.null(value)) value <- min
  size_class <- paste0(" size-", size)
  disabled_attr <- if (disabled) ' disabled' else ''
  
  # Build labels data attribute if custom labels provided
  # Use single quotes for the JSON string to avoid HTML attribute quote conflicts
  labels_attr <- if (!is.null(labels) && length(labels) > 0) {
    # Encode as JSON and escape single quotes if any
    json_str <- as.character(jsonlite::toJSON(labels))
    # Replace double quotes with escaped HTML entities
    json_escaped <- gsub('"', '&quot;', json_str)
    paste0('data-labels="', json_escaped, '" ')
  } else {
    ''
  }
  
  # Determine display value (use label if available)
  display_value <- value
  if (!is.null(labels) && length(labels) > 0) {
    # Calculate which label to show
    idx <- round((value - min) / step) + 1
    if (idx >= 1 && idx <= length(labels)) {
      display_value <- labels[idx]
    }
  }
  
  # Determine tick labels
  min_label <- min
  max_label <- max
  if (!is.null(labels) && length(labels) >= 2) {
    min_label <- labels[1]
    max_label <- labels[length(labels)]
  }
  
  html_lines <- c()
  html_lines <- c(html_lines, paste0('<div class="dashboardr-input-group align-', align, size_class, '" style="width: ', width, ';">'))
  
  if (!is.null(label) && nzchar(label)) {
    html_lines <- c(html_lines, '  <div class="dashboardr-slider-header">')
    html_lines <- c(html_lines, paste0('    <label class="dashboardr-input-label" for="', input_id, '">', label, '</label>'))
    if (show_value) {
      html_lines <- c(html_lines, paste0('    <span class="dashboardr-slider-value" id="', input_id, '_value">', display_value, '</span>'))
    }
    html_lines <- c(html_lines, '  </div>')
  }
  
  html_lines <- c(html_lines,
    '  <div class="dashboardr-slider-container">',
    paste0('    <input type="range" id="', input_id, '" class="dashboardr-slider" data-filter-var="', filter_var, '" data-input-type="slider" ', labels_attr, 'min="', min, '" max="', max, '" step="', step, '" value="', value, '"', disabled_attr, '>'),
    '    <div class="dashboardr-slider-ticks">',
    paste0('      <span>', min_label, '</span>'),
    paste0('      <span>', max_label, '</span>'),
    '    </div>',
    '  </div>')
  
  if (!is.null(help) && nzchar(help)) {
    html_lines <- c(html_lines, paste0('  <span class="dashboardr-input-help">', htmltools::htmlEscape(help), '</span>'))
  }
  
  html_lines <- c(html_lines, paste0('<script>if(typeof dashboardrFilterHook!=="undefined")dashboardrFilterHook("', input_id, '","', filter_var, '");</script>'))
  html_lines <- c(html_lines, '</div>')
  
  paste(html_lines, collapse = "\n")
}

#' Generate HTML for text input
#' @keywords internal
.generate_text_html <- function(input_id, label, filter_var, value, placeholder,
                                 width, align, size = "md", help = NULL, disabled = FALSE) {
  if (is.null(value)) value <- ""
  size_class <- paste0(" size-", size)
  disabled_attr <- if (disabled) ' disabled' else ''
  
  html_lines <- c()
  html_lines <- c(html_lines, paste0('<div class="dashboardr-input-group align-', align, size_class, '" style="width: ', width, ';">'))
  
  if (!is.null(label) && nzchar(label)) {
    html_lines <- c(html_lines, paste0('  <label class="dashboardr-input-label" for="', input_id, '">', label, '</label>'))
  }
  
  html_lines <- c(html_lines, paste0('  <input type="text" id="', input_id, '" class="dashboardr-text-input" data-filter-var="', filter_var, '" data-input-type="text" placeholder="', htmltools::htmlEscape(placeholder), '" value="', htmltools::htmlEscape(value), '"', disabled_attr, '>'))
  
  if (!is.null(help) && nzchar(help)) {
    html_lines <- c(html_lines, paste0('  <span class="dashboardr-input-help">', htmltools::htmlEscape(help), '</span>'))
  }
  
  html_lines <- c(html_lines, paste0('<script>if(typeof dashboardrFilterHook!=="undefined")dashboardrFilterHook("', input_id, '","', filter_var, '");</script>'))
  html_lines <- c(html_lines, '</div>')
  
  paste(html_lines, collapse = "\n")
}

#' Generate HTML for number input
#' @keywords internal
.generate_number_html <- function(input_id, label, filter_var, min, max, step,
                                   value, width, align, size = "md", help = NULL, disabled = FALSE) {
  if (is.null(value)) value <- min
  size_class <- paste0(" size-", size)
  disabled_attr <- if (disabled) ' disabled' else ''
  
  html_lines <- c()
  html_lines <- c(html_lines, paste0('<div class="dashboardr-input-group align-', align, size_class, '" style="width: ', width, ';">'))
  
  if (!is.null(label) && nzchar(label)) {
    html_lines <- c(html_lines, paste0('  <label class="dashboardr-input-label" for="', input_id, '">', label, '</label>'))
  }
  
  html_lines <- c(html_lines, paste0('  <input type="number" id="', input_id, '" class="dashboardr-number-input" data-filter-var="', filter_var, '" data-input-type="number" min="', min, '" max="', max, '" step="', step, '" value="', value, '"', disabled_attr, '>'))
  
  if (!is.null(help) && nzchar(help)) {
    html_lines <- c(html_lines, paste0('  <span class="dashboardr-input-help">', htmltools::htmlEscape(help), '</span>'))
  }
  
  html_lines <- c(html_lines, paste0('<script>if(typeof dashboardrFilterHook!=="undefined")dashboardrFilterHook("', input_id, '","', filter_var, '");</script>'))
  html_lines <- c(html_lines, '</div>')
  
  paste(html_lines, collapse = "\n")
}

#' Generate HTML for button group input
#' @keywords internal
.generate_button_group_html <- function(input_id, label, filter_var, options,
                                         default_selected, width, align,
                                         size = "md", help = NULL, disabled = FALSE) {
  if (is.null(default_selected) && length(options) > 0) default_selected <- options[1]
  size_class <- paste0(" size-", size)
  disabled_attr <- if (disabled) ' disabled' else ''
  
  html_lines <- c()
  html_lines <- c(html_lines, paste0('<div class="dashboardr-input-group align-', align, size_class, '" style="width: ', width, ';">'))
  
  if (!is.null(label) && nzchar(label)) {
    html_lines <- c(html_lines, paste0('  <label class="dashboardr-input-label">', label, '</label>'))
  }
  
  html_lines <- c(html_lines, paste0('  <div id="', input_id, '" class="dashboardr-button-group" data-filter-var="', filter_var, '" data-input-type="button_group">'))
  
  for (i in seq_along(options)) {
    opt <- options[i]
    active_class <- if (opt %in% default_selected) ' active' else ''
    opt_id <- paste0(input_id, '_', i)
    html_lines <- c(html_lines,
      paste0('    <button type="button" id="', opt_id, '" class="dashboardr-button-option', active_class, '" data-value="', htmltools::htmlEscape(opt), '"', disabled_attr, '>', htmltools::htmlEscape(opt), '</button>'))
  }
  
  html_lines <- c(html_lines, '  </div>')
  
  if (!is.null(help) && nzchar(help)) {
    html_lines <- c(html_lines, paste0('  <span class="dashboardr-input-help">', htmltools::htmlEscape(help), '</span>'))
  }
  
  html_lines <- c(html_lines, paste0('<script>if(typeof dashboardrFilterHook!=="undefined")dashboardrFilterHook("', input_id, '","', filter_var, '");</script>'))
  html_lines <- c(html_lines, '</div>')
  
  paste(html_lines, collapse = "\n")
}

# =================================================================
# PUBLIC API: render_input
# =================================================================

#' Render an input widget
#'
#' Creates HTML for various input widgets that filter Highcharts visualizations.
#'
#' @param input_id Unique ID for this input widget
#' @param label Optional label displayed above the input
#' @param type Input type: "select_multiple", "select_single", "checkbox", 
#'   "radio", "switch", "slider", "text", "number", or "button_group"
#' @param filter_var The variable name to filter by (matches Highcharts series names)
#' @param options Character vector of options to display (for select/checkbox/radio/button_group).
#'   Can also be a named list for grouped options in selects.
#' @param options_from Column name in page data to auto-populate options from
#' @param default_selected Character vector of initially selected values
#' @param placeholder Placeholder text when nothing is selected (for selects/text)
#' @param width CSS width for the input
#' @param align Alignment: "center", "left", or "right"
#' @param min Minimum value (for slider/number)
#' @param max Maximum value (for slider/number)
#' @param step Step increment (for slider/number)
#' @param value Initial value (for slider/switch/text/number)
#' @param show_value Whether to show the current value (for slider)
#' @param inline Whether to display options inline (for checkbox/radio)
#' @param toggle_series For switch type: name of the series to toggle on/off
#' @param override For switch type: if TRUE, switch overrides other filters for this series
#' @param labels Custom labels for slider ticks (character vector)
#' @param size Size variant: "sm", "md" (default), or "lg"
#' @param help Help text displayed below the input
#' @param disabled Whether the input is disabled
#' @return HTML output (invisible)
#' @export
render_input <- function(input_id,
                         label = NULL,
                         type = c("select_multiple", "select_single", "checkbox", 
                                  "radio", "switch", "slider", "text", "number", "button_group"),
                         filter_var,
                         options = NULL,
                         options_from = NULL,
                         default_selected = NULL,
                         placeholder = "Select...",
                         width = "300px",
                         align = c("center", "left", "right"),
                         min = 0,
                         max = 100,
                         step = 1,
                         value = NULL,
                         show_value = TRUE,
                         inline = TRUE,
                         stacked = FALSE,
                         stacked_align = c("center", "left", "right"),
                         group_align = c("left", "center", "right"),
                         ncol = NULL,
                         nrow = NULL,
                         columns = NULL,
                         toggle_series = NULL,
                         override = FALSE,
                         labels = NULL,
                         size = c("md", "sm", "lg"),
                         help = NULL,
                         disabled = FALSE) {
  
  # Convert variable arguments to strings (supports both quoted and unquoted)
  filter_var <- .as_var_string(rlang::enquo(filter_var))
  options_from <- .as_var_string(rlang::enquo(options_from))
  
  type <- match.arg(type)
  align <- match.arg(align)
  size <- match.arg(size)
  stacked_align <- match.arg(stacked_align)
  group_align <- match.arg(group_align)
  
  # If options_from is specified, try to get options from the data
  if (is.null(options) && !is.null(options_from)) {
    options <- .get_options_from_data(options_from)
    if (is.null(options)) {
      warning("Could not find 'data' object or column. Please provide 'options' explicitly.")
      options <- c()
    }
  }
  
  # Route to appropriate generator
  html <- switch(type,
    "select_multiple" = ,
    "select_single" = .generate_select_html(input_id, label, type, filter_var, options,
                                             default_selected, placeholder, width, align,
                                             size, help, disabled),
    "checkbox" = .generate_checkbox_html(input_id, label, filter_var, options,
                                          default_selected, width, align, inline,
                                          size, help, disabled, columns, stacked, stacked_align, group_align, ncol, nrow),
    "radio" = .generate_radio_html(input_id, label, filter_var, options,
                                    default_selected, width, align, inline,
                                    size, help, disabled, columns, stacked, stacked_align, group_align, ncol, nrow),
    "switch" = .generate_switch_html(input_id, label, filter_var, value, width, align,
                                      toggle_series, override, size, help, disabled),
    "slider" = .generate_slider_html(input_id, label, filter_var, min, max, step,
                                      value, show_value, width, align, labels,
                                      size, help, disabled),
    "text" = .generate_text_html(input_id, label, filter_var, value, placeholder,
                                  width, align, size, help, disabled),
    "number" = .generate_number_html(input_id, label, filter_var, min, max, step,
                                      value, width, align, size, help, disabled),
    "button_group" = .generate_button_group_html(input_id, label, filter_var, options,
                                                  default_selected, width, align,
                                                  size, help, disabled),
    {
      warning(paste0("Unknown input type: ", type))
      ""
    }
  )
  
  knitr::asis_output(html)
}

# =================================================================
# PUBLIC API: render_input_row
# =================================================================

#' Render a row of input widgets
#'
#' Creates HTML for a horizontal row of input widgets.
#'
#' @param inputs List of input specifications (each should have the same
#'   parameters as render_input)
#' @param style Visual style: "boxed" (default) or "inline" (compact)
#' @param align Alignment: "center" (default), "left", or "right"
#' @return HTML output
#' @export
render_input_row <- function(inputs, style = "boxed", align = "center") {
  # Build class list
  classes <- c("dashboardr-input-row")
  if (style == "inline") {
    classes <- c(classes, "inline")
  }
  classes <- c(classes, paste0("align-", align))
  
  # Collect all HTML parts
  html_parts <- c()
  html_parts <- c(html_parts, paste0('<div class="', paste(classes, collapse = " "), '">'))
  
  # Render each input
  for (input in inputs) {
    # Resolve options_from if needed
    options <- input$options
    if (is.null(options) && !is.null(input$options_from)) {
      options <- .get_options_from_data(input$options_from)
    }

    type <- input$type %||% "select_multiple"

    input_html <- switch(type,
      "select_multiple" = ,
      "select_single" = .generate_select_html(
        input$input_id, input$label, type, input$filter_var, options,
        input$default_selected, input$placeholder %||% "Select...",
        input$width %||% "300px", "center",
        input$size %||% "md", input$help, input$disabled %||% FALSE
      ),
      "checkbox" = .generate_checkbox_html(
        input$input_id, input$label, input$filter_var, options,
        input$default_selected, input$width %||% "300px", "center",
        input$inline %||% TRUE, input$size %||% "md", input$help,
        input$disabled %||% FALSE, input$columns, input$stacked %||% FALSE,
        input$stacked_align %||% "center", input$group_align %||% "left",
        input$ncol, input$nrow
      ),
      "radio" = .generate_radio_html(
        input$input_id, input$label, input$filter_var, options,
        input$default_selected, input$width %||% "300px", "center",
        input$inline %||% TRUE, input$size %||% "md", input$help,
        input$disabled %||% FALSE, input$columns, input$stacked %||% FALSE,
        input$stacked_align %||% "center", input$group_align %||% "left",
        input$ncol, input$nrow
      ),
      "switch" = .generate_switch_html(
        input$input_id, input$label, input$filter_var, input$value,
        input$width %||% "300px", "center",
        input$toggle_series %||% (if (!is.null(options) && length(options) == 1) options[1] else NULL),
        input$override %||% FALSE, input$size %||% "md", input$help,
        input$disabled %||% FALSE
      ),
      "slider" = .generate_slider_html(
        input$input_id, input$label, input$filter_var,
        input$min %||% 0, input$max %||% 100, input$step %||% 1,
        input$value, input$show_value %||% TRUE, input$width %||% "300px", "center",
        input$labels, input$size %||% "md", input$help, input$disabled %||% FALSE
      ),
      "text" = .generate_text_html(
        input$input_id, input$label, input$filter_var, input$value,
        input$placeholder %||% "Search...", input$width %||% "300px", "center",
        input$size %||% "md", input$help, input$disabled %||% FALSE
      ),
      "number" = .generate_number_html(
        input$input_id, input$label, input$filter_var,
        input$min %||% 0, input$max %||% 100, input$step %||% 1,
        input$value, input$width %||% "300px", "center",
        input$size %||% "md", input$help, input$disabled %||% FALSE
      ),
      "button_group" = .generate_button_group_html(
        input$input_id, input$label, input$filter_var, options,
        input$default_selected, input$width %||% "300px", "center",
        input$size %||% "md", input$help, input$disabled %||% FALSE
      ),
      ""
    )
    
    # Apply margin wrapper if any margin is specified
    margin_style <- .build_margin_style(input$mt, input$mr, input$mb, input$ml)
    if (nzchar(margin_style)) {
      input_html <- paste0('<div style="', margin_style, '">', input_html, '</div>')
    }
    
    html_parts <- c(html_parts, input_html)
  }
  
  html_parts <- c(html_parts, '</div>')
  
  knitr::asis_output(paste(html_parts, collapse = "\n"))
}

# =================================================================
# PUBLIC API: add_reset_button
# =================================================================

#' Add a reset button to reset filters
#'
#' Creates a button that resets specified inputs to their default values.
#'
#' @param targets Character vector of input IDs to reset, or NULL for all
#' @param label Button label
#' @param size Size variant: "sm", "md", or "lg"
#' @return HTML output
#' @export
add_reset_button <- function(targets = NULL, label = "Reset Filters", size = "md") {
  targets_attr <- if (!is.null(targets)) {
    paste0('data-targets="', paste(targets, collapse = ","), '" ')
  } else {
    'data-targets="all" '
  }
  
  html <- paste0(
    '<button type="button" class="dashboardr-reset-button size-', size, '" ',
    targets_attr,
    'onclick="dashboardrInputs.resetFilters(this)">', 
    htmltools::htmlEscape(label), 
    '</button>'
  )
  
  knitr::asis_output(html)
}

# =================================================================
# BACKWARD COMPATIBILITY ALIASES
# These call the consolidated generators for backward compatibility
# =================================================================

# These are kept for any code that might call them directly
.render_select_input <- function(...) knitr::asis_output(.generate_select_html(...))
.render_checkbox_input <- function(...) knitr::asis_output(.generate_checkbox_html(...))
.render_radio_input <- function(...) knitr::asis_output(.generate_radio_html(...))
.render_switch_input <- function(...) knitr::asis_output(.generate_switch_html(...))
.render_slider_input <- function(...) knitr::asis_output(.generate_slider_html(...))

# Also keep the .get_* aliases for backward compatibility
.get_select_html <- .generate_select_html
.get_checkbox_html <- .generate_checkbox_html
.get_radio_html <- .generate_radio_html
.get_switch_html <- .generate_switch_html
.get_slider_html <- .generate_slider_html
