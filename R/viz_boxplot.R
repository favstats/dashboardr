# --------------------------------------------------------------------------
# Function: viz_boxplot
# --------------------------------------------------------------------------
#' @title Create a Box Plot
#' @description Creates an interactive box plot using highcharter. Supports
#'   grouped boxplots, horizontal orientation, outlier display, and
#'   weighted percentile calculations.
#'
#' @param data A data frame containing the variable to plot.
#' @param y_var String. Name of the numeric column for the boxplot.
#' @param x_var Optional string. Name of a grouping variable for multiple boxes.
#' @param title Optional string. Main chart title.
#' @param subtitle Optional string. Chart subtitle.
#' @param x_label Optional string. X-axis label. Defaults to `x_var`.
#' @param y_label Optional string. Y-axis label. Defaults to `y_var`.
#' @param color_palette Optional character vector of colors for the boxes.
#' @param show_outliers Logical. If TRUE, show outlier points. Default TRUE.
#' @param horizontal Logical. If TRUE, flip chart orientation. Default FALSE.
#' @param weight_var Optional string. Name of a weight variable for weighted
#'   percentile calculations.
#' @param x_order Optional character vector specifying the order of x categories.
#' @param x_map_values Optional named list to recode `x_var` values
#'   (e.g., `list("1" = "Male", "2" = "Female")`).
#' @param include_na Logical. If TRUE, include NA groups as explicit category.
#'   Default FALSE.
#' @param na_label String. Label for NA group when `include_na = TRUE`.
#'   Default "(Missing)".
#' @param tooltip A tooltip configuration created with \code{\link{tooltip}()}, 
#'   OR a format string with \{placeholders\}. Boxplot-specific placeholders: 
#'   \code{\{category\}}, \code{\{high\}}, \code{\{q3\}}, \code{\{median\}}, 
#'   \code{\{q1\}}, \code{\{low\}}.
#'   See \code{\link{tooltip}} for full customization options.
#' @param tooltip_prefix Optional string prepended to values in tooltip.
#' @param tooltip_suffix Optional string appended to values in tooltip.
#'
#' @return A `highcharter` boxplot object.
#'
#' @examples
#' \dontrun{
#' # Basic boxplot
#' data(gss_panel20)
#'
#' # Example 1: Simple boxplot of age
#' plot1 <- viz_boxplot(
#'   data = gss_panel20,
#'   y_var = "age",
#'   title = "Age Distribution"
#' )
#' plot1
#'
#' # Example 2: Boxplot by education level
#' plot2 <- viz_boxplot(
#'   data = gss_panel20,
#'   y_var = "age",
#'   x_var = "degree",
#'   title = "Age Distribution by Education",
#'   x_label = "Highest Degree",
#'   y_label = "Age (years)"
#' )
#' plot2
#'
#' # Example 3: Horizontal boxplot without outliers
#' plot3 <- viz_boxplot(
#'   data = gss_panel20,
#'   y_var = "age",
#'   x_var = "sex",
#'   title = "Age by Sex",
#'   horizontal = TRUE,
#'   show_outliers = FALSE
#' )
#' plot3
#' }
#'
#' @export
viz_boxplot <- function(data,
                        y_var,
                        x_var = NULL,
                        title = NULL,
                        subtitle = NULL,
                        x_label = NULL,
                        y_label = NULL,
                        color_palette = NULL,
                        show_outliers = TRUE,
                        horizontal = FALSE,
                        weight_var = NULL,
                        x_order = NULL,
                        x_map_values = NULL,
                        include_na = FALSE,
                        na_label = "(Missing)",
                        tooltip = NULL,
                        tooltip_prefix = "",
                        tooltip_suffix = "") {
  
  # Convert variable arguments to strings (supports both quoted and unquoted)
  y_var <- .as_var_string(rlang::enquo(y_var))
  x_var <- .as_var_string(rlang::enquo(x_var))
  weight_var <- .as_var_string(rlang::enquo(weight_var))
  
  # INPUT VALIDATION
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  
  if (is.null(y_var)) {
    .stop_with_hint("y_var", example = "viz_boxplot(data, y_var = \"age\")")
  }
  
  if (!y_var %in% names(data)) {
    stop(paste0("Column '", y_var, "' not found in data."), call. = FALSE)
  }
  
  if (!is.null(x_var) && !x_var %in% names(data)) {
    stop(paste0("Column '", x_var, "' not found in data."), call. = FALSE)
  }
  
  if (!is.null(weight_var) && !weight_var %in% names(data)) {
    stop(paste0("Column '", weight_var, "' not found in data."), call. = FALSE)
  }
  
  # DATA PREP
  df <- tibble::as_tibble(data)
  
  # Recode haven_labelled for y_var
  if (inherits(df[[y_var]], "haven_labelled")) {
    df <- df |>
      dplyr::mutate(
        !!rlang::sym(y_var) := as.numeric(unclass(!!rlang::sym(y_var)))
      )
  }
  
  # Convert y_var to numeric if needed
  if (!is.numeric(df[[y_var]])) {
    numeric_attempt <- suppressWarnings(as.numeric(df[[y_var]]))
    if (all(is.na(numeric_attempt[!is.na(df[[y_var]])]))) {
      stop("`y_var` must be numeric for boxplot.", call. = FALSE)
    }
    df[[y_var]] <- numeric_attempt
  }
  
  # Handle x_var grouping
  if (!is.null(x_var)) {
    if (inherits(df[[x_var]], "haven_labelled")) {
      df[[x_var]] <- haven::as_factor(df[[x_var]])
    }
    df[[x_var]] <- as.character(df[[x_var]])
    
    # Apply value mapping if provided
    if (!is.null(x_map_values)) {
      if (!is.list(x_map_values) || is.null(names(x_map_values))) {
        stop("`x_map_values` must be a named list.", call. = FALSE)
      }
      df <- df |>
        dplyr::mutate(
          !!rlang::sym(x_var) := dplyr::recode(
            !!rlang::sym(x_var),
            !!!x_map_values
          )
        )
    }
    
    # Handle NAs in x variable
    if (include_na) {
      df[[x_var]] <- ifelse(is.na(df[[x_var]]), na_label, df[[x_var]])
    } else {
      df <- df[!is.na(df[[x_var]]), ]
    }
    
    # Apply x order if provided
    if (!is.null(x_order)) {
      existing_levels <- unique(df[[x_var]])
      ordered_levels <- c(
        x_order[x_order %in% existing_levels],
        setdiff(existing_levels, x_order)
      )
      df[[x_var]] <- factor(df[[x_var]], levels = ordered_levels)
    } else {
      df[[x_var]] <- factor(df[[x_var]])
    }
  }
  
  # Remove NAs from y_var
  df <- df[!is.na(df[[y_var]]), ]
  
  # Helper function to compute boxplot statistics
  compute_boxplot_stats <- function(x, weights = NULL) {
    if (length(x) == 0) {
      return(list(
        low = NA, q1 = NA, median = NA, q3 = NA, high = NA,
        outliers = numeric(0)
      ))
    }
    
    if (!is.null(weights)) {
      # Weighted quantiles using Hmisc-style approach
      ord <- order(x)
      x <- x[ord]
      weights <- weights[ord]
      cum_weights <- cumsum(weights) / sum(weights)
      
      q1 <- x[which(cum_weights >= 0.25)[1]]
      median_val <- x[which(cum_weights >= 0.5)[1]]
      q3 <- x[which(cum_weights >= 0.75)[1]]
    } else {
      q1 <- quantile(x, 0.25, na.rm = TRUE)
      median_val <- quantile(x, 0.5, na.rm = TRUE)
      q3 <- quantile(x, 0.75, na.rm = TRUE)
    }
    
    iqr <- q3 - q1
    lower_fence <- q1 - 1.5 * iqr
    upper_fence <- q3 + 1.5 * iqr
    
    # Outliers are points outside the fences
    outliers <- x[x < lower_fence | x > upper_fence]
    
    # Whiskers extend to most extreme non-outlier points
    non_outliers <- x[x >= lower_fence & x <= upper_fence]
    low <- if (length(non_outliers) > 0) min(non_outliers) else q1
    high <- if (length(non_outliers) > 0) max(non_outliers) else q3
    
    list(
      low = as.numeric(low),
      q1 = as.numeric(q1),
      median = as.numeric(median_val),
      q3 = as.numeric(q3),
      high = as.numeric(high),
      outliers = as.numeric(outliers)
    )
  }
  
  # Compute statistics for each group
  if (!is.null(x_var)) {
    categories <- levels(df[[x_var]])
    boxplot_data <- lapply(seq_along(categories), function(i) {
      cat <- categories[i]
      subset_data <- df[df[[x_var]] == cat, ]
      y_values <- subset_data[[y_var]]
      
      if (!is.null(weight_var)) {
        weights <- subset_data[[weight_var]]
      } else {
        weights <- NULL
      }
      
      stats <- compute_boxplot_stats(y_values, weights)
      list(
        category = cat,
        index = i - 1,  # 0-indexed for highcharter
        stats = stats
      )
    })
  } else {
    categories <- if (!is.null(y_label)) y_label else y_var
    
    if (!is.null(weight_var)) {
      weights <- df[[weight_var]]
    } else {
      weights <- NULL
    }
    
    stats <- compute_boxplot_stats(df[[y_var]], weights)
    boxplot_data <- list(
      list(
        category = categories,
        index = 0,
        stats = stats
      )
    )
  }
  
  # Set default labels
  if (is.null(x_label)) x_label <- if (!is.null(x_var)) x_var else ""
  if (is.null(y_label)) y_label <- y_var
  
  # Prepare series data for highcharter boxplot format
  # Highcharter expects: [low, q1, median, q3, high]
  series_data <- lapply(boxplot_data, function(bp) {
    c(bp$stats$low, bp$stats$q1, bp$stats$median, bp$stats$q3, bp$stats$high)
  })
  
  # Create the highcharter plot
  inverted <- horizontal
  
  hc <- highcharter::highchart() |>
    highcharter::hc_chart(type = "boxplot", inverted = inverted) |>
    highcharter::hc_title(text = title) |>
    highcharter::hc_subtitle(text = subtitle) |>
    highcharter::hc_xAxis(
      categories = if (!is.null(x_var)) categories else list(y_label),
      title = list(text = x_label)
    ) |>
    highcharter::hc_yAxis(
      title = list(text = y_label)
    ) |>
    highcharter::hc_add_series(
      name = if (!is.null(x_var)) y_label else "Values",
      data = series_data,
      type = "boxplot"
    )
  
  # Add outliers if requested
  if (show_outliers) {
    outlier_data <- list()
    for (bp in boxplot_data) {
      if (length(bp$stats$outliers) > 0) {
        for (outlier in bp$stats$outliers) {
          outlier_data <- c(outlier_data, list(list(x = bp$index, y = outlier)))
        }
      }
    }
    
    if (length(outlier_data) > 0) {
      hc <- hc |>
        highcharter::hc_add_series(
          name = "Outliers",
          data = outlier_data,
          type = "scatter",
          marker = list(
            fillColor = "white",
            lineWidth = 1,
            lineColor = "black",
            symbol = "circle"
          ),
          tooltip = list(
            pointFormat = "Outlier: {point.y:.2f}"
          )
        )
    }
  }
  
  # Add color palette if provided
  if (!is.null(color_palette)) {
    hc <- hc |>
      highcharter::hc_colors(color_palette)
  }
  
  # \u2500\u2500\u2500 TOOLTIP \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
  if (!is.null(tooltip)) {
    # Use new unified tooltip system
    tooltip_result <- .process_tooltip_config(
      tooltip = tooltip,
      tooltip_prefix = tooltip_prefix,
      tooltip_suffix = tooltip_suffix,
      x_tooltip_suffix = NULL,
      chart_type = "boxplot",
      context = list(
        x_label = x_label,
        y_label = y_label
      )
    )
    hc <- .apply_tooltip_to_hc(hc, tooltip_result)
  } else {
    # Default tooltip with prefix/suffix
    pre <- if (is.null(tooltip_prefix) || tooltip_prefix == "") "" else tooltip_prefix
    suf <- if (is.null(tooltip_suffix) || tooltip_suffix == "") "" else tooltip_suffix
    
    hc <- hc |>
      highcharter::hc_tooltip(
        headerFormat = "<b>{point.key}</b><br>",
        pointFormat = paste0(
          "Max: ", pre, "{point.high:.2f}", suf, "<br>",
          "Q3: ", pre, "{point.q3:.2f}", suf, "<br>",
          "Median: ", pre, "{point.median:.2f}", suf, "<br>",
          "Q1: ", pre, "{point.q1:.2f}", suf, "<br>",
          "Min: ", pre, "{point.low:.2f}", suf
        )
      )
  }
  
  hc <- hc |>
    highcharter::hc_legend(enabled = FALSE)
  
  hc
}
