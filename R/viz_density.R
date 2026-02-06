# --------------------------------------------------------------------------
# Function: viz_density
# --------------------------------------------------------------------------
#' @title Create a Density Plot
#' @description Creates an interactive kernel density estimate plot using 
#'   highcharter. Supports grouped densities, weighted kernel density 
#'   estimation, and customization options.
#'
#' @param data A data frame containing the variable to plot.
#' @param x_var String. Name of the numeric column for density estimation.
#' @param group_var Optional string. Name of a grouping variable for
#'   multiple overlaid densities.
#' @param title Optional string. Main chart title.
#' @param subtitle Optional string. Chart subtitle.
#' @param x_label Optional string. X-axis label. Defaults to `x_var`.
#' @param y_label Optional string. Y-axis label. Defaults to "Density".
#' @param color_palette Optional character vector of colors for the density curves.
#' @param fill_opacity Numeric between 0 and 1. Fill transparency. Default 0.3.
#' @param show_rug Logical. If TRUE, show rug marks at the bottom. Default FALSE.
#' @param bandwidth Optional numeric. Kernel bandwidth. If NULL (default),
#'   uses R's default bandwidth selection.
#' @param weight_var Optional string. Name of a weight variable for weighted
#'   density estimation.
#' @param group_order Optional character vector specifying the order of groups.
#' @param include_na Logical. If TRUE, include NA groups as explicit category.
#'   Default FALSE.
#' @param na_label String. Label for NA group when `include_na = TRUE`.
#'   Default "(Missing)".
#' @param tooltip A tooltip configuration created with \code{\link{tooltip}()}, 
#'   OR a format string with \{placeholders\}. Available placeholders: 
#'   \code{\{x\}}, \code{\{y\}}, \code{\{value\}}, \code{\{series\}}.
#'   See \code{\link{tooltip}} for full customization options.
#' @param tooltip_suffix Optional string appended to density values in tooltip (simple customization).
#'
#' @return A `highcharter` density plot object.
#'
#' @examples
#' \dontrun{
#' # Basic density plot
#' data(gss_panel20)
#' 
#' # Example 1: Simple density of age
#' plot1 <- viz_density(
#'   data = gss_panel20,
#'   x_var = "age",
#'   title = "Age Distribution",
#'   x_label = "Age (years)"
#' )
#' plot1
#'
#' # Example 2: Grouped densities by sex
#' plot2 <- viz_density(
#'   data = gss_panel20,
#'   x_var = "age",
#'   group_var = "sex",
#'   title = "Age Distribution by Sex",
#'   x_label = "Age (years)",
#'   color_palette = c("#3498DB", "#E74C3C")
#' )
#' plot2
#'
#' # Example 3: Customized density with rug marks
#' plot3 <- viz_density(
#'   data = gss_panel20,
#'   x_var = "age",
#'   title = "Age Distribution",
#'   fill_opacity = 0.5,
#'   show_rug = TRUE,
#'   bandwidth = 3
#' )
#' plot3
#' }
#'
#' @export
viz_density <- function(data,
                        x_var,
                        group_var = NULL,
                        title = NULL,
                        subtitle = NULL,
                        x_label = NULL,
                        y_label = NULL,
                        color_palette = NULL,
                        fill_opacity = 0.3,
                        show_rug = FALSE,
                        bandwidth = NULL,
                        weight_var = NULL,
                        group_order = NULL,
                        include_na = FALSE,
                        na_label = "(Missing)",
                        tooltip = NULL,
                        tooltip_suffix = "") {
  
  # Convert variable arguments to strings (supports both quoted and unquoted)
  x_var <- .as_var_string(rlang::enquo(x_var))
  group_var <- .as_var_string(rlang::enquo(group_var))
  weight_var <- .as_var_string(rlang::enquo(weight_var))
  
  # INPUT VALIDATION
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  
  if (is.null(x_var)) {
    .stop_with_hint("x_var", example = "viz_density(data, x_var = \"age\")")
  }
  
  if (!x_var %in% names(data)) {
    stop(paste0("Column '", x_var, "' not found in data."), call. = FALSE)
  }
  
  if (!is.null(group_var) && !group_var %in% names(data)) {
    stop(paste0("Column '", group_var, "' not found in data."), call. = FALSE)
  }
  
  if (!is.null(weight_var) && !weight_var %in% names(data)) {
    stop(paste0("Column '", weight_var, "' not found in data."), call. = FALSE)
  }
  
  # DATA PREP
  df <- tibble::as_tibble(data)
  
  # Recode haven_labelled if present
  if (inherits(df[[x_var]], "haven_labelled")) {
    df <- df |>
      dplyr::mutate(
        !!rlang::sym(x_var) := as.numeric(unclass(!!rlang::sym(x_var)))
      )
  }
  
  # Convert to numeric if needed
  if (!is.numeric(df[[x_var]])) {
    numeric_attempt <- suppressWarnings(as.numeric(df[[x_var]]))
    if (all(is.na(numeric_attempt[!is.na(df[[x_var]])]))) {
      stop("`x_var` must be numeric for density estimation.", call. = FALSE)
    }
    df[[x_var]] <- numeric_attempt
  }
  
  # Handle grouping variable
  if (!is.null(group_var)) {
    if (inherits(df[[group_var]], "haven_labelled")) {
      df[[group_var]] <- haven::as_factor(df[[group_var]])
    }
    df[[group_var]] <- as.character(df[[group_var]])
    
    # Handle NAs in group variable
    if (include_na) {
      df[[group_var]] <- ifelse(is.na(df[[group_var]]), na_label, df[[group_var]])
    } else {
      df <- df[!is.na(df[[group_var]]), ]
    }
    
    # Apply group order if provided
    if (!is.null(group_order)) {
      existing_levels <- unique(df[[group_var]])
      ordered_levels <- c(
        group_order[group_order %in% existing_levels],
        setdiff(existing_levels, group_order)
      )
      df[[group_var]] <- factor(df[[group_var]], levels = ordered_levels)
    } else {
      df[[group_var]] <- factor(df[[group_var]])
    }
  }
  
  # Remove NAs from x_var
  df <- df[!is.na(df[[x_var]]), ]
  
  # Compute kernel density
  compute_density <- function(x, weights = NULL, bw = NULL) {
    if (length(x) < 2) {
      return(data.frame(x = numeric(0), y = numeric(0)))
    }
    
    if (!is.null(weights)) {
      # Weighted density using weighted.mean for bandwidth if not specified
      if (is.null(bw)) {
        bw <- "nrd0"
      }
      dens <- density(x, weights = weights / sum(weights, na.rm = TRUE), bw = bw)
    } else {
      if (is.null(bw)) {
        dens <- density(x)
      } else {
        dens <- density(x, bw = bw)
      }
    }
    
    data.frame(x = dens$x, y = dens$y)
  }
  
  # Compute density data
  if (!is.null(group_var)) {
    groups <- levels(df[[group_var]])
    density_list <- lapply(groups, function(g) {
      subset_data <- df[df[[group_var]] == g, ]
      x_values <- subset_data[[x_var]]
      
      # Skip groups with insufficient data
      if (length(x_values[!is.na(x_values)]) < 2) {
        return(NULL)
      }
      
      if (!is.null(weight_var)) {
        weights <- subset_data[[weight_var]]
      } else {
        weights <- NULL
      }
      
      dens <- compute_density(x_values, weights, bandwidth)
      if (nrow(dens) == 0) return(NULL)
      dens$group <- g
      dens
    })
    # Remove NULL entries from groups with insufficient data
    density_list <- density_list[!vapply(density_list, is.null, logical(1))]
    density_data <- do.call(rbind, density_list)
  } else {
    if (!is.null(weight_var)) {
      weights <- df[[weight_var]]
    } else {
      weights <- NULL
    }
    density_data <- compute_density(df[[x_var]], weights, bandwidth)
    density_data$group <- if (!is.null(x_label)) x_label else x_var
  }
  
  # Set default labels
  if (is.null(x_label)) x_label <- x_var
  if (is.null(y_label)) y_label <- "Density"
  
  # Create the highcharter plot
  hc <- highcharter::highchart() |>
    highcharter::hc_chart(type = "areaspline") |>
    highcharter::hc_title(text = title) |>
    highcharter::hc_subtitle(text = subtitle) |>
    highcharter::hc_xAxis(
      title = list(text = x_label),
      crosshair = TRUE
    ) |>
    highcharter::hc_yAxis(
      title = list(text = y_label),
      min = 0
    ) |>
    highcharter::hc_plotOptions(
      areaspline = list(
        fillOpacity = fill_opacity,
        marker = list(enabled = FALSE),
        lineWidth = 2
      )
    )
  
  # Add series for each group
  if (!is.null(group_var)) {
    groups <- unique(density_data$group)
    for (g in groups) {
      group_data <- density_data[density_data$group == g, ]
      series_data <- lapply(seq_len(nrow(group_data)), function(i) {
        list(x = group_data$x[i], y = group_data$y[i])
      })
      hc <- hc |>
        highcharter::hc_add_series(
          name = as.character(g),
          data = series_data,
          type = "areaspline"
        )
    }
  } else {
    series_data <- lapply(seq_len(nrow(density_data)), function(i) {
      list(x = density_data$x[i], y = density_data$y[i])
    })
    hc <- hc |>
      highcharter::hc_add_series(
        name = x_label,
        data = series_data,
        type = "areaspline"
      )
  }
  
  # Add color palette if provided
  if (!is.null(color_palette)) {
    hc <- hc |>
      highcharter::hc_colors(color_palette)
  }
  
  # Add rug marks if requested
  if (show_rug && !is.null(group_var)) {
    for (g in unique(df[[group_var]])) {
      rug_x <- df[[x_var]][df[[group_var]] == g]
      rug_data <- lapply(rug_x, function(x) list(x = x, y = 0))
      hc <- hc |>
        highcharter::hc_add_series(
          name = paste0(g, " (rug)"),
          data = rug_data,
          type = "scatter",
          marker = list(
            symbol = "line",
            lineWidth = 1,
            radius = 4
          ),
          showInLegend = FALSE
        )
    }
  } else if (show_rug) {
    rug_data <- lapply(df[[x_var]], function(x) list(x = x, y = 0))
    hc <- hc |>
      highcharter::hc_add_series(
        name = "Rug",
        data = rug_data,
        type = "scatter",
        marker = list(
          symbol = "line",
          lineWidth = 1,
          radius = 4
        ),
        showInLegend = FALSE
      )
  }
  
  # \u2500\u2500\u2500 TOOLTIP \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
  if (!is.null(tooltip)) {
    # Use new unified tooltip system
    tooltip_result <- .process_tooltip_config(
      tooltip = tooltip,
      tooltip_prefix = NULL,
      tooltip_suffix = tooltip_suffix,
      x_tooltip_suffix = NULL,
      chart_type = "density",
      context = list(
        x_label = x_label,
        y_label = y_label
      )
    )
    hc <- .apply_tooltip_to_hc(hc, tooltip_result)
  } else {
    # Legacy tooltip
    tooltip_format_str <- paste0("{point.y:.4f}", tooltip_suffix)
    hc <- hc |>
      highcharter::hc_tooltip(
        headerFormat = "<b>{series.name}</b><br>",
        pointFormat = paste0(x_label, ": {point.x:.2f}<br>Density: ", tooltip_format_str)
      )
  }
  
  hc <- hc |>
    highcharter::hc_legend(enabled = !is.null(group_var))
  
  hc
}
