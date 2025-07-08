# Load dependencies
library(highcharter)
library(tidyverse)
library(timetk)
library(dplyr)
library(rlang)
library(roxygen2)

# Helper function (from rlang or magrittr, but defining here for self-containment)
`%||%` <- function(x, y) {
  if (is.null(x)) y else y
}

# create_stackedbars calls create_stackedbar
create_stackedbar <- function(data,
                              x_var,
                              y_var = NULL,
                              stack_var,
                              title = NULL,
                              subtitle = NULL,
                              x_label = NULL,
                              y_label = NULL,
                              stack_label = NULL,
                              stacked_type = c("normal", "percent"),
                              tooltip_prefix = "",
                              tooltip_suffix = "",
                              x_tooltip_suffix = "",
                              color_palette = NULL,
                              stack_order = NULL,
                              x_order = NULL,
                              include_na = FALSE,
                              x_breaks = NULL,
                              x_bin_labels = NULL,
                              x_map_values = NULL,
                              stack_breaks = NULL,
                              stack_bin_labels = NULL,
                              stack_map_values = NULL) {
  
  # INPUT VALIDATION
  if (!is.data.frame(data)) {
    stop("Input 'data' must be a data frame.", call. = FALSE)
  }
  if (!x_var %in% names(data)) {
    stop(paste0("Column '", x_var, "' not found in data."), call. = FALSE)
  }
  if (!stack_var %in% names(data)) {
    stop(paste0("Column '", stack_var, "' not found in data."), call. = FALSE)
  }
  
  stacked_type <- match.arg(stacked_type)
  
  # Create a mutable copy of the data
  plot_data_temp <- tibble::as_tibble(data)
  
  # DATA HANDLING (BASIC)
  # Handle 'haven_labelled' columns
  # This is for SPSS data. TODO ask Fleur what other file types ppl use
  if (requireNamespace("haven", quietly = TRUE)) {
    if (inherits(plot_data_temp[[x_var]], "haven_labelled")) {
      plot_data_temp <- plot_data_temp |>
        dplyr::mutate(!!rlang::sym(x_var) := haven::as_factor(!!rlang::sym(x_var), levels = "values"))
      message(paste0("Note: Column '", x_var, "' was 'haven_labelled' and converted to factor (levels = values)."))
    }
    if (inherits(plot_data_temp[[stack_var]], "haven_labelled")) {
      plot_data_temp <- plot_data_temp |>
        dplyr::mutate(!!rlang::sym(stack_var) := haven::as_factor(!!rlang::sym(stack_var), levels = "values"))
      message(paste0("Note: Column '", stack_var, "' was 'haven_labelled' and converted to factor (levels = values)."))
    }
  }
  
  # X VAR VALUE MAPPING
  # We need to map when values are numeric
  if (!is.null(x_map_values)) {
    if (!is.list(x_map_values) || is.null(names(x_map_values))) {
      stop("'x_map_values' must be a named list (e.g., list('1'='Male', '2'='Female')).", call. = FALSE)
    }
    # Convert to character if it's a factor. Recode works on characters best.
    if (is.factor(plot_data_temp[[x_var]])) {
      plot_data_temp <- plot_data_temp |>
        dplyr::mutate(!!rlang::sym(x_var) := as.character(!!rlang::sym(x_var)))
    }
    plot_data_temp <- plot_data_temp |>
      dplyr::mutate(!!rlang::sym(x_var) := dplyr::recode(!!rlang::sym(x_var), !!!x_map_values))
    if (!is.null(x_order)) {
      warning("x_order provided with x_map_values. Ensure x_order refers to the *new* mapped labels.", call. = FALSE)
    }
  }
  
  # STACK VAR VALUE MAPPING
  if (!is.null(stack_map_values)) {
    if (!is.list(stack_map_values) || is.null(names(stack_map_values))) {
      stop("'stack_map_values' must be a named list (e.g., list('1'='Strongly Disagree', '7'='Strongly Agree')).", call. = FALSE)
    }
    # Convert to character if it's a factor
    if (is.factor(plot_data_temp[[stack_var]])) {
      plot_data_temp <- plot_data_temp |>
        dplyr::mutate(!!rlang::sym(stack_var) := as.character(!!rlang::sym(stack_var)))
    }
    plot_data_temp <- plot_data_temp |>
      dplyr::mutate(!!rlang::sym(stack_var) := dplyr::recode(!!rlang::sym(stack_var), !!!stack_map_values))
    if (!is.null(stack_order)) {
      warning("stack_order provided with stack_map_values. Ensure stack_order refers to the *new* mapped labels.", call. = FALSE)
    }
  }
  
  # X_VAR BINNING
  # Binning is useful if you have a lot of entries (like age)
  x_var_for_plot <- x_var # Default to original x_var
  if (!is.null(x_breaks)) {
    if (!is.numeric(plot_data_temp[[x_var]])) {
      warning(paste0("'", x_var, "' is not a numeric column. 'x_breaks' will be ignored."), call. = FALSE)
      x_breaks <- NULL
      x_bin_labels <- NULL
    } else {
      if (!is.numeric(x_breaks) || length(x_breaks) < 2) {
        stop("When provided, 'x_breaks' must be a numeric vector with at least two values.", call. = FALSE)
      }
      if (!is.null(x_bin_labels) && length(x_bin_labels) != (length(x_breaks) - 1)) {
        stop("The length of 'x_bin_labels' must be one less than the length of 'x_breaks'.", call. = FALSE)
      }
      plot_data_temp <- plot_data_temp |>
        dplyr::mutate(
          .x_var_binned = cut(
            !!rlang::sym(x_var),
            breaks = x_breaks,
            labels = x_bin_labels,
            include.lowest = TRUE,
            right = FALSE
          )
        )
      x_var_for_plot <- ".x_var_binned" # Now use the binned column for plotting
      if (!is.null(x_order) && (is.null(x_bin_labels) || !all(x_order %in% x_bin_labels))) {
        warning("x_order provided with x_breaks. Ensure x_order refers to the *correct* bin labels (either auto-generated or custom 'x_bin_labels').", call.=FALSE)
      }
    }
  }
  
  # STACK_VAR BINNING
  # Same as x_vars, depends what user wants
  stack_var_for_plot <- stack_var # Default to original stack_var
  if (!is.null(stack_breaks)) {
    if (!is.numeric(plot_data_temp[[stack_var]])) {
      warning(paste0("'", stack_var, "' is not a numeric column. 'stack_breaks' will be ignored."), call. = FALSE)
      stack_breaks <- NULL # Invalidate breaks if not numeric
      stack_bin_labels <- NULL
    } else {
      if (!is.numeric(stack_breaks) || length(stack_breaks) < 2) {
        stop("When provided, 'stack_breaks' must be a numeric vector with at least two values.", call. = FALSE)
      }
      if (!is.null(stack_bin_labels) && length(stack_bin_labels) != (length(stack_breaks) - 1)) {
        stop("The length of 'stack_bin_labels' must be one less than the length of 'stack_breaks'.", call. = FALSE)
      }
      plot_data_temp <- plot_data_temp |>
        dplyr::mutate(
          .stack_var_binned = cut(
            !!rlang::sym(stack_var),
            breaks = stack_breaks,
            labels = stack_bin_labels,
            include.lowest = TRUE,
            right = FALSE
          )
        )
      stack_var_for_plot <- ".stack_var_binned" # Now use the binned column for plotting
      if (!is.null(stack_order) && (is.null(stack_bin_labels) || !all(stack_order %in% stack_bin_labels))) {
        warning("stack_order provided with stack_breaks. Ensure stack_order refers to the *correct* bin labels (either auto-generated or custom 'stack_bin_labels').", call.=FALSE)
      }
    }
  }
  
  # DATA AGGREGATION
  # Use x_var_for_plot and stack_var_for_plot after all mutations (mapping, binning)
  plot_data <- plot_data_temp |>
    dplyr::mutate(
      .x_var_col = if (include_na) {
        as.factor(addNA(!!rlang::sym(x_var_for_plot), ifany = TRUE))
      } else {
        as.factor(!!rlang::sym(x_var_for_plot))
      },
      .stack_var_col = if (include_na) {
        as.factor(addNA(!!rlang::sym(stack_var_for_plot), ifany = TRUE))
      } else {
        as.factor(!!rlang::sym(stack_var_for_plot))
      }
    )
  
  # Apply custom ordering for stack_var
  if (!is.null(stack_order)) {
    actual_stack_levels <- levels(plot_data$.stack_var_col)
    filtered_stack_order <- stack_order[stack_order %in% actual_stack_levels]
    remaining_levels <- setdiff(actual_stack_levels, filtered_stack_order)
    final_stack_order <- c(filtered_stack_order, remaining_levels)
    
    plot_data <- plot_data |>
      dplyr::mutate(
        .stack_var_col = factor(.stack_var_col, levels = final_stack_order, ordered = TRUE)
      )
  }
  
  # Apply custom ordering for x_var
  if (!is.null(x_order)) {
    actual_x_levels <- levels(plot_data$.x_var_col)
    filtered_x_order <- x_order[x_order %in% actual_x_levels]
    remaining_x_levels <- setdiff(actual_x_levels, filtered_x_order)
    final_x_order <- c(filtered_x_order, remaining_x_levels)
    
    plot_data <- plot_data |>
      dplyr::mutate(
        .x_var_col = factor(.x_var_col, levels = final_x_order, ordered = TRUE) # Simplified to always be ordered = TRUE if a custom order is applied
      )
  }
  
  if (is.null(y_var)) {
    # Perform the aggregation
    plot_data <- plot_data |>
      dplyr::count(.x_var_col, .stack_var_col, name = "n") |>
      dplyr::ungroup()
  } else {
    plot_data <- plot_data |>
      dplyr::rename(n := !!rlang::sym(y_var))
  }
  
  # HIGHCHARTER
  hchart_obj <- highcharter::hchart(
    object = plot_data,
    type = "column",
    highcharter::hcaes(x = .x_var_col, y = n, group = .stack_var_col)
  )
  
  # titles and subtitles
  if (!is.null(title)) {
    hchart_obj <- highcharter::hc_title(hchart_obj, text = title)
  }
  if (!is.null(subtitle)) {
    hchart_obj <- highcharter::hc_subtitle(hchart_obj, text = subtitle)
  }
  
  # Axes labels
  # X-axis Title Logic:
  final_x_label <- x_label
  if (is.null(final_x_label)) {
    if (!is.null(x_breaks)) {
      final_x_label <- paste0(x_var, " (Binned)")
    } else {
      final_x_label <- x_var
    }
  }
  
  # Y-axis Title Logic:
  final_y_label <- y_label
  if (is.null(final_y_label)) {
    if (stacked_type == "percent") {
      final_y_label <- "Percentage of Respondents"
    } else {
      final_y_label <- "Number of Respondents"
    }
  }
  
  # Apply axis titles
  hchart_obj <- highcharter::hc_xAxis(hchart_obj, title = list(text = final_x_label))
  hchart_obj <- highcharter::hc_yAxis(hchart_obj, title = list(text = final_y_label))
  
  # Stacking and data labels
  data_label_format <- if (stacked_type == "percent") '{point.percentage:.1f}%' else '{point.y}'
  stacking_type_hc <- if (stacked_type == "percent") "percent" else "normal"
  
  hchart_obj <- highcharter::hc_plotOptions(
    hchart_obj,
    column = list(
      stacking = stacking_type_hc,
      dataLabels = list(
        enabled = TRUE,
        format = data_label_format, # Show percentage or count
        style = list(textOutline = "none", fontSize = "10px")
      )
    )
  )
  
  # Legend
  # Stack label logic for legend:
  final_stack_label <- stack_label
  if (is.null(final_stack_label)) {
    if (!is.null(stack_breaks)) {
      final_stack_label <- paste0(stack_var, " (Binned)")
    } else {
      final_stack_label <- stack_var
    }
  }
  hchart_obj <- highcharter::hc_legend(hchart_obj, title = list(text = final_stack_label))
  
  # Tooltips
  # defines the content and formatting of the interactive pop-up box that
  # appears when a user hovers their mouse over a data point
  # Pre-process R variables to ensure they are valid JS strings (empty if NULL/empty)
  tooltip_prefix_js <- if(is.null(tooltip_prefix) || tooltip_prefix == "") "" else tooltip_prefix
  tooltip_suffix_js <- if(is.null(tooltip_suffix) || tooltip_suffix == "") "" else tooltip_suffix
  x_tooltip_suffix_js <- if(is.null(x_tooltip_suffix) || x_tooltip_suffix == "") "" else x_tooltip_suffix
  
  hchart_obj <- highcharter::hc_tooltip(
    hchart_obj,
    formatter = highcharter::JS(
      paste0(
        "function() {
        var value = ", if(stacked_type == "percent") "this.percentage.toFixed(1)" else "this.y", ";
        return '<b>' + this.x + '", x_tooltip_suffix_js, "</b><br/>' +
               this.series.name + ': ", tooltip_prefix_js, "' + value + '", tooltip_suffix_js, "<br/>' +
               'Total: ' + ", if(stacked_type == "percent") "100" else "this.point.stackTotal", ";
      }"
      )
    )
  )
  
  # colors and custom color palette
  if (!is.null(color_palette)) {
    hchart_obj <- highcharter::hc_colors(hchart_obj, colors = color_palette)
  }
  
  return(hchart_obj)
}

################################

# --------------------------------------------------------------------------
# Function: create_stackedbars
# --------------------------------------------------------------------------
#' @export
#' @title Arrange Stacked Bar Charts Vertically
#'
#' @description Takes a list of highcharter objects (created with `create_stackedbar`)
#'              and arranges them vertically in a single output, each taking full width.
#'
#' @param chart_list A list of highcharter chart objects created with `create_stackedbar`.
#' @param container_id An optional ID for the container div (for CSS styling).
#'
#' @return An HTML object containing the input charts arranged vertically. This is meant to be rendered via Quarto.
#'
#' @details
#' This function simplifies the process of displaying multiple `highcharter` bar charts in a single output. 
#' It vertically arranges the charts, ensuring each one takes up the full available width. 
#' The function returns a standard HTML object that you can directly insert into your R Markdown or Quarto documents, enabling you to create interactive and well-organized dashboards.
#'
#' @examples
#' # Load necessary libraries
#' library(highcharter)
#' library(dplyr)
#' library(htmltools)
#'
#' # Assuming you have a data frame 'survey_data' and 'create_stackedbar' function defined
#' # chart1 <- create_stackedbar(survey_data, x_var = "group", stack_var = "response", title = "Chart 1")
#' # chart2 <- create_stackedbar(survey_data, x_var = "group", stack_var = "response", title = "Chart 2")
#' # chart_list <- list(chart1, chart2)
#' # stacked_charts <- create_stackedbars(chart_list)
#' # stacked_charts # Display in Quarto

create_stackedbars <- function(chart_list, container_id = "stacked_charts_container") {
  
  # --- INPUT VALIDATION ---
  if (!is.list(chart_list) || !all(sapply(chart_list, inherits, "highchart"))) {
    stop("Input 'chart_list' must be a list of highcharter chart objects.", call. = FALSE)
  }
  
  # --- CREATE CONTAINER ---
  container_div <- htmltools::tags$div(
    id = container_id,
    style = "display: flex; flex-direction: column; align-items: stretch;"
  )
  
  # --- ADD CHARTS TO CONTAINER ---
  for (i in seq_along(chart_list)) {
    chart <- chart_list[[i]]
    container_div$children[[i]] <- htmltools::tags$div(
      chart, #embed chart itself
      style = "width: 100%;"  # Ensure each chart takes full width
    )
  }
  
  # --- RETURN AS HTML ---
  container_div
}



# --- Data Preparation (as in your example) ---
set.seed(123)
mtcars_survey <- mtcars %>%
  mutate(
    car_type = case_when(
      cyl == 4 ~ "Economy",
      cyl == 6 ~ "Mid-range",
      cyl == 8 ~ "Performance"
    ),
    satisfaction_mpg = case_when(
      mpg >= 25 ~ 5,
      mpg >= 20 ~ 4,
      mpg >= 15 ~ 3,
      mpg >= 10 ~ 2,
      TRUE ~ 1
    ),
    satisfaction_hp = case_when(
      hp >= 200 ~ 5,
      hp >= 150 ~ 4,
      hp >= 100 ~ 3,
      hp >= 75 ~ 2,
      TRUE ~ 1
    ),
    satisfaction_qsec = case_when(
      qsec <= 15 ~ 5,
      qsec <= 16 ~ 4,
      qsec <= 17 ~ 3,
      qsec <= 18 ~ 2,
      TRUE ~ 1
    ),
    satisfaction_wt = case_when(
      wt <= 2.5 ~ 5,
      wt <= 3.0 ~ 4,
      wt <= 3.5 ~ 3,
      wt <= 4.0 ~ 2,
      TRUE ~ 1
    )
  )

# --- Create Individual Highcharter Charts ---
survey_items <- c("satisfaction_mpg", "satisfaction_hp", "satisfaction_qsec", "satisfaction_wt")
item_labels <- list(
  "satisfaction_mpg" = "Fuel Efficiency",
  "satisfaction_hp" = "Engine Power",
  "satisfaction_qsec" = "Acceleration",
  "satisfaction_wt" = "Weight/Handling"
)

chart_list <- lapply(survey_items, function(item) {
  create_stackedbar(
    data = mtcars_survey,
    x_var = "car_type",
    stack_var = item,
    title = item_labels[[item]],
    stacked_type = "percent"
  )
})

# --- Stack the Charts Vertically ---
stacked_charts <- create_stackedbars(chart_list, container_id = "my_stacked_charts")

# --- Display the result in Quarto or R Markdown ---
stacked_charts
