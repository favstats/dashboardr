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
#' @param cross_tab_filter_vars Optional character vector of variable names to use for
#'   client-side cross-tab filtering when dashboard inputs are present.
#'
#' @param backend Rendering backend: "highcharter" (default), "plotly", "echarts4r", or "ggiraph".
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
#' @param legend_position Position of the legend ("top", "bottom", "left", "right", "none")
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
                        tooltip_suffix = "",
                        legend_position = NULL,
                        backend = "highcharter",
                        cross_tab_filter_vars = NULL) {
  
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
        stats = stats,
        raw_values = as.numeric(y_values)
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
        stats = stats,
        raw_values = as.numeric(df[[y_var]])
      )
    )
  }
  
  # Set default labels
  if (is.null(x_label)) x_label <- if (!is.null(x_var)) x_var else ""
  if (is.null(y_label)) y_label <- y_var

  # Build config for backend dispatch
  config <- list(
    title = title, subtitle = subtitle,
    x_label = x_label, y_label = y_label,
    color_palette = color_palette,
    show_outliers = show_outliers,
    horizontal = horizontal,
    x_var = x_var,
    categories = categories,
    tooltip = tooltip, tooltip_prefix = tooltip_prefix,
    tooltip_suffix = tooltip_suffix,
    legend_position = legend_position
  )

  # Prepare cross-tab data for client-side filtering (all backends)
  cross_tab_attrs <- NULL
  if (!is.null(cross_tab_filter_vars) && length(cross_tab_filter_vars) > 0) {
    valid_filter_vars <- cross_tab_filter_vars[cross_tab_filter_vars %in% names(df)]
    if (length(valid_filter_vars) > 0) {
      group_value <- if (!is.null(x_var)) NULL else as.character(categories[1])
      cross_tab <- df %>%
        dplyr::mutate(
          .dashboardr_group = if (!is.null(x_var)) as.character(.data[[x_var]]) else group_value,
          .dashboardr_value = as.numeric(.data[[y_var]])
        ) %>%
        dplyr::select(dplyr::all_of(valid_filter_vars), .dashboardr_group, .dashboardr_value)

      chart_id <- .next_crosstab_id()
      chart_config <- list(
        chartId = chart_id,
        chartType = "boxplot",
        xVar = ".dashboardr_group",
        yVar = ".dashboardr_value",
        filterVars = valid_filter_vars,
        xOrder = as.character(categories),
        horizontal = horizontal,
        showOutliers = show_outliers
      )
      if (!is.null(color_palette) && !is.null(names(color_palette))) {
        chart_config$colorMap <- as.list(color_palette)
      }
      if (!is.null(title) && grepl("\\{\\w+\\}", title)) {
        chart_config$titleTemplate <- title
      }
      cross_tab_attrs <- list(data = cross_tab, config = chart_config, id = chart_id)
    }
  }

  # Dispatch to backend renderer
  backend <- .normalize_backend(backend)
  backend <- match.arg(backend, c("highcharter", "plotly", "echarts4r", "ggiraph"))
  .assert_backend_supported("boxplot", backend)
  render_fn <- switch(backend,
    highcharter = .viz_boxplot_highcharter,
    plotly      = .viz_boxplot_plotly,
    echarts4r   = .viz_boxplot_echarts,
    ggiraph     = .viz_boxplot_ggiraph
  )
  result <- render_fn(boxplot_data, config)
  if (!is.null(cross_tab_attrs)) {
    attr(result, "cross_tab_data") <- cross_tab_attrs$data
    attr(result, "cross_tab_config") <- cross_tab_attrs$config
    attr(result, "cross_tab_id") <- cross_tab_attrs$id
    if (identical(backend, "highcharter")) {
      result <- highcharter::hc_chart(result, id = cross_tab_attrs$id)
    }
  }
  result <- .register_chart_widget(result, backend = backend)
  return(result)
}

# --- Highcharter backend (original implementation) ---
#' @keywords internal
.viz_boxplot_highcharter <- function(boxplot_data, config) {
  # Unpack config
  title <- config$title; subtitle <- config$subtitle
  x_label <- config$x_label; y_label <- config$y_label
  color_palette <- config$color_palette
  show_outliers <- config$show_outliers
  horizontal <- config$horizontal
  x_var <- config$x_var; categories <- config$categories
  tooltip <- config$tooltip; tooltip_prefix <- config$tooltip_prefix
  tooltip_suffix <- config$tooltip_suffix

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
  
  # --- Legend position ---
  hc <- .apply_legend_highcharter(hc, config$legend_position, default_show = FALSE)

  hc
}

# --- Plotly backend ---
#' @keywords internal
.viz_boxplot_plotly <- function(boxplot_data, config) {
  rlang::check_installed("plotly", reason = "to use backend = 'plotly'")

  title <- config$title
  x_label <- config$x_label; y_label <- config$y_label
  color_palette <- config$color_palette
  horizontal <- config$horizontal
  show_outliers <- config$show_outliers
  x_var <- config$x_var; categories <- config$categories

  p <- plotly::plot_ly()

  for (i in seq_along(boxplot_data)) {
    bp <- boxplot_data[[i]]
    stats <- bp$stats
    category_label <- as.character(bp$category)
    raw_values <- bp$raw_values %||% numeric(0)
    raw_values <- as.numeric(raw_values)
    raw_values <- raw_values[is.finite(raw_values)]

    trace_args <- list(
      p = p,
      type = "box",
      name = category_label,
      boxpoints = if (isTRUE(show_outliers)) "outliers" else FALSE
    )

    # Prefer raw samples so Plotly computes box stats correctly.
    # Fall back to pre-computed statistics only if raw values are unavailable.
    if (length(raw_values) > 0) {
      if (horizontal) {
        trace_args$orientation <- "h"
        trace_args$x <- raw_values
        trace_args$y <- rep(category_label, length(raw_values))
      } else {
        trace_args$orientation <- "v"
        trace_args$x <- rep(category_label, length(raw_values))
        trace_args$y <- raw_values
      }
    } else {
      trace_args$lowerfence <- list(stats$low)
      trace_args$q1 <- list(stats$q1)
      trace_args$median <- list(stats$median)
      trace_args$q3 <- list(stats$q3)
      trace_args$upperfence <- list(stats$high)
      if (horizontal) {
        trace_args$orientation <- "h"
        trace_args$x <- list(category_label)
      } else {
        trace_args$orientation <- "v"
        trace_args$x <- list(category_label)
      }
    }

    if (!is.null(color_palette) && i <= length(color_palette)) {
      trace_args$marker <- list(color = color_palette[i])
      trace_args$line <- list(color = color_palette[i])
    }

    p <- do.call(plotly::add_trace, trace_args)
  }

  layout_args <- list(p = p, showlegend = FALSE)
  if (!is.null(title)) layout_args$title <- title
  if (horizontal) {
    layout_args$xaxis <- list(title = y_label)
    layout_args$yaxis <- list(title = x_label, type = "category")
  } else {
    layout_args$xaxis <- list(title = x_label, type = "category")
    layout_args$yaxis <- list(title = y_label)
  }

  p <- do.call(plotly::layout, layout_args)

  # --- Legend position ---
  p <- .apply_legend_plotly(p, config$legend_position, default_show = FALSE)

  p
}

# --- echarts4r backend ---
#' @keywords internal
.viz_boxplot_echarts <- function(boxplot_data, config) {
  rlang::check_installed("echarts4r", reason = "to use backend = 'echarts4r'")

  title <- config$title; subtitle <- config$subtitle
  x_label <- config$x_label; y_label <- config$y_label
  color_palette <- config$color_palette
  horizontal <- config$horizontal
  categories <- config$categories
  show_outliers <- config$show_outliers

  # echarts4r's e_boxplot() computes stats internally from raw values,
  # but we already have pre-computed stats. Build a data frame with a
  # raw-values column per category so e_boxplot can recompute them.
  # Alternatively, construct the chart via e_list for pre-computed data.

  # Build pre-computed boxplot data as list of [low, q1, median, q3, high]
  # Each item gets an itemStyle.color for per-box coloring
  box_series_data <- lapply(seq_along(boxplot_data), function(i) {
    bp <- boxplot_data[[i]]
    item <- list(
      value = c(bp$stats$low, bp$stats$q1, bp$stats$median, bp$stats$q3, bp$stats$high)
    )
    if (!is.null(color_palette) && i <= length(color_palette)) {
      # Use palette color for fill, darken it for borders/lines so median is visible
      fill_col <- color_palette[i]
      border_col <- .darken_color(fill_col, 0.35)
      item$itemStyle <- list(
        color = fill_col,
        borderColor = border_col,
        borderWidth = 2
      )
    }
    item
  })

  cat_names <- vapply(boxplot_data, function(bp) as.character(bp$category), character(1))

  # Build chart using e_list for full control
  opts <- list(
    xAxis = list(
      type = "category",
      data = as.list(cat_names),
      name = x_label
    ),
    yAxis = list(
      type = "value",
      name = y_label
    ),
    series = list(
      list(
        name = y_label %||% "Value",
        type = "boxplot",
        data = box_series_data
      )
    ),
    tooltip = list(trigger = "item")
  )

  if (!is.null(title) || !is.null(subtitle)) {
    opts$title <- list(text = title %||% "", subtext = subtitle %||% "")
  }

  if (!is.null(color_palette)) {
    opts$color <- as.list(color_palette)
  }

  if (horizontal) {
    # Swap axes for horizontal boxplot
    tmp <- opts$xAxis
    opts$xAxis <- opts$yAxis
    opts$yAxis <- tmp
  }

  e <- echarts4r::e_charts() |>
    echarts4r::e_list(opts)

  # --- Legend position ---
  e <- .apply_legend_echarts(e, config$legend_position, default_show = FALSE)

  e
}

# --- ggiraph backend ---
#' @keywords internal
.viz_boxplot_ggiraph <- function(boxplot_data, config) {
  rlang::check_installed("ggiraph", reason = "to use backend = 'ggiraph'")
  rlang::check_installed("ggplot2", reason = "to use backend = 'ggiraph'")

  title <- config$title; subtitle <- config$subtitle
  x_label <- config$x_label; y_label <- config$y_label
  color_palette <- config$color_palette
  horizontal <- config$horizontal
  show_outliers <- config$show_outliers

  # Build summary data frame
  box_df <- data.frame(
    category = vapply(boxplot_data, function(bp) as.character(bp$category), character(1)),
    low = vapply(boxplot_data, function(bp) bp$stats$low, numeric(1)),
    q1 = vapply(boxplot_data, function(bp) bp$stats$q1, numeric(1)),
    median = vapply(boxplot_data, function(bp) bp$stats$median, numeric(1)),
    q3 = vapply(boxplot_data, function(bp) bp$stats$q3, numeric(1)),
    high = vapply(boxplot_data, function(bp) bp$stats$high, numeric(1)),
    stringsAsFactors = FALSE
  )

  box_df$.tooltip <- paste0(
    box_df$category, "<br>",
    "Max: ", round(box_df$high, 2), "<br>",
    "Q3: ", round(box_df$q3, 2), "<br>",
    "Median: ", round(box_df$median, 2), "<br>",
    "Q1: ", round(box_df$q1, 2), "<br>",
    "Min: ", round(box_df$low, 2)
  )

  p <- ggplot2::ggplot(box_df, ggplot2::aes(x = .data$category)) +
    ggiraph::geom_boxplot_interactive(
      ggplot2::aes(
        lower = .data$q1, upper = .data$q3, middle = .data$median,
        ymin = .data$low, ymax = .data$high,
        fill = .data$category,
        tooltip = .data$.tooltip, data_id = .data$category
      ),
      stat = "identity"
    ) +
    ggplot2::labs(title = title, subtitle = subtitle,
                  x = x_label, y = y_label) +
    ggplot2::theme_minimal()

  if (!is.null(color_palette)) {
    p <- p + ggplot2::scale_fill_manual(values = color_palette)
  }

  if (horizontal) {
    p <- p + ggplot2::coord_flip()
  }

  # Add outlier points
  if (show_outliers) {
    outlier_rows <- lapply(boxplot_data, function(bp) {
      if (length(bp$stats$outliers) > 0) {
        data.frame(
          category = as.character(bp$category),
          y = bp$stats$outliers,
          stringsAsFactors = FALSE
        )
      }
    })
    outlier_df <- do.call(rbind, outlier_rows)
    if (!is.null(outlier_df) && nrow(outlier_df) > 0) {
      p <- p + ggplot2::geom_point(
        data = outlier_df,
        ggplot2::aes(x = .data$category, y = .data$y),
        shape = 1, size = 2
      )
    }
  }

  # --- Legend position ---
  p <- .apply_legend_ggplot(p, config$legend_position, default_show = FALSE)

  ggiraph::girafe(ggobj = p)
}
