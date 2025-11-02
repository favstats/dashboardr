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
    ""
  )

  # Add custom text content if provided
  if (!is.null(page$text) && nzchar(page$text)) {
    content <- c(content, page$text, "")
  }

  # Add global setup chunk with libraries, data, and settings
  if (!is.null(page$data_path) || !is.null(page$visualizations)) {
    content <- c(content, .generate_global_setup_chunk(page))
  }
  
  # Add loading overlay chunk if enabled
  if (!is.null(page$overlay) && page$overlay) {
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
    
    content <- c(content, .generate_loading_overlay_chunk(overlay_theme, overlay_text))
  }

  # Add visualizations
  if (!is.null(page$visualizations)) {
    viz_content <- .generate_viz_from_specs(page$visualizations)
    content <- c(content, viz_content)
  } else if (is.null(page$text) || !nzchar(page$text)) {
    content <- c(content, "This page was generated without a template.")
  }

  content
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
  if (!is.null(page$visualizations) && !is.null(page$data_path)) {
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
        if (!is.null(filter_info$source_dataset) && nzchar(filter_info$source_dataset)) {
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


