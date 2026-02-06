# =================================================================
# Waffle Chart Visualization
# =================================================================

#' Create a Waffle Chart
#'
#' Creates an interactive waffle (square pie) chart using highcharter.
#' Waffle charts display proportional data as a grid of colored squares,
#' providing an intuitive alternative to pie charts.
#'
#' @param data A data frame containing the data.
#' @param x_var Character string. Name of the categorical variable (category labels).
#' @param y_var Optional character string. Name of a numeric column with pre-aggregated
#'   values (counts or percentages). If NULL, counts are computed from the data.
#' @param title Optional main title for the chart.
#' @param subtitle Optional subtitle for the chart.
#' @param total Numeric. Total number of squares in the waffle grid. Default 100.
#'   Each square represents \code{total_value / total} of the data.
#' @param rows Numeric. Number of rows in the waffle grid. Default 10.
#' @param color_palette Optional character vector of colors for the categories.
#' @param x_order Optional character vector specifying the order of categories.
#' @param data_labels_enabled Logical. If TRUE, show category labels. Default FALSE
#'   (legend is shown instead).
#' @param show_in_legend Logical. If TRUE (default), show a legend.
#' @param weight_var Optional character string. Name of weight variable.
#' @param border_color Character string. Color of the square borders. Default "white".
#' @param border_width Numeric. Width of square borders in pixels. Default 1.
#' @param tooltip A tooltip configuration created with \code{\link{tooltip}()}.
#' @param tooltip_prefix Optional string prepended to tooltip values.
#' @param tooltip_suffix Optional string appended to tooltip values.
#' @param height Numeric. Chart height in pixels. Default 400.
#'
#' @return A highcharter plot object.
#'
#' @examples
#' \dontrun{
#' df <- data.frame(
#'   category = c("Agree", "Neutral", "Disagree"),
#'   count = c(45, 30, 25)
#' )
#' viz_waffle(df, x_var = "category", y_var = "count",
#'            title = "Survey Responses", total = 100)
#' }
#' @export
viz_waffle <- function(data,
                       x_var,
                       y_var = NULL,
                       title = NULL,
                       subtitle = NULL,
                       total = 100,
                       rows = 10,
                       color_palette = NULL,
                       x_order = NULL,
                       data_labels_enabled = FALSE,
                       show_in_legend = TRUE,
                       weight_var = NULL,
                       border_color = "white",
                       border_width = 1,
                       tooltip = NULL,
                       tooltip_prefix = "",
                       tooltip_suffix = "",
                       height = 400) {

  # Convert variable arguments to strings
  x_var <- .as_var_string(rlang::enquo(x_var))
  y_var <- .as_var_string(rlang::enquo(y_var))
  weight_var <- .as_var_string(rlang::enquo(weight_var))

  # Input validation
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }

  if (is.null(x_var)) {
    .stop_with_hint("x_var", example = 'viz_waffle(data, x_var = "category")')
  }

  if (!x_var %in% names(data)) {
    stop(paste0("Column '", x_var, "' not found in data."), call. = FALSE)
  }

  if (!is.null(y_var) && !y_var %in% names(data)) {
    stop(paste0("Column '", y_var, "' not found in data."), call. = FALSE)
  }

  # Prepare & aggregate data
  plot_data <- data %>%
    dplyr::select(dplyr::all_of(c(x_var, y_var, weight_var))) %>%
    dplyr::filter(!is.na(!!rlang::sym(x_var)))

  # Handle haven_labelled
  if (requireNamespace("haven", quietly = TRUE)) {
    if (inherits(plot_data[[x_var]], "haven_labelled")) {
      plot_data <- plot_data %>%
        dplyr::mutate(!!rlang::sym(x_var) := haven::as_factor(!!rlang::sym(x_var), levels = "labels"))
    }
  }

  # Aggregate
  if (!is.null(y_var)) {
    agg_data <- plot_data %>%
      dplyr::mutate(name = as.character(!!rlang::sym(x_var)),
                    value = !!rlang::sym(y_var))
  } else if (!is.null(weight_var)) {
    agg_data <- plot_data %>%
      dplyr::count(!!rlang::sym(x_var), wt = !!rlang::sym(weight_var), name = "value") %>%
      dplyr::mutate(name = as.character(!!rlang::sym(x_var)))
  } else {
    agg_data <- plot_data %>%
      dplyr::count(!!rlang::sym(x_var), name = "value") %>%
      dplyr::mutate(name = as.character(!!rlang::sym(x_var)))
  }

  # Apply ordering
  if (!is.null(x_order)) {
    agg_data <- agg_data %>%
      dplyr::mutate(name = factor(name, levels = x_order)) %>%
      dplyr::arrange(name) %>%
      dplyr::mutate(name = as.character(name))
  }

  # Compute proportions and number of squares per category
  total_value <- sum(agg_data$value, na.rm = TRUE)
  agg_data <- agg_data %>%
    dplyr::mutate(
      proportion = value / total_value,
      squares = round(proportion * total)
    )

  # Adjust rounding to ensure squares sum to total
  diff <- total - sum(agg_data$squares)
  if (diff != 0) {
    # Add/subtract from the largest category
    idx <- which.max(agg_data$squares)
    agg_data$squares[idx] <- agg_data$squares[idx] + diff
  }

  # Compute grid dimensions
  cols <- ceiling(total / rows)

  # Build waffle using Highcharts heatmap
  # Each square is a cell in a rows x cols grid
  waffle_data <- list()
  square_idx <- 0
  for (cat_i in seq_len(nrow(agg_data))) {
    n_squares <- agg_data$squares[cat_i]
    for (s in seq_len(n_squares)) {
      col_pos <- square_idx %% cols
      row_pos <- rows - 1 - (square_idx %/% cols)
      waffle_data[[length(waffle_data) + 1]] <- list(
        x = col_pos,
        y = row_pos,
        value = cat_i,
        name = agg_data$name[cat_i],
        count = agg_data$value[cat_i],
        pct = round(agg_data$proportion[cat_i] * 100, 1)
      )
      square_idx <- square_idx + 1
    }
  }

  # Build color stops
  categories <- agg_data$name
  n_cats <- length(categories)

  if (!is.null(color_palette)) {
    colors <- color_palette
  } else {
    # Default Highcharts-like palette
    colors <- c("#4E79A7", "#F28E2B", "#E15759", "#76B7B2", "#59A14F",
                "#EDC948", "#B07AA1", "#FF9DA7", "#9C755F", "#BAB0AC")
  }

  # Build colorAxis stops (one color per category)
  color_stops <- lapply(seq_len(n_cats), function(i) {
    list((i - 0.5) / n_cats, colors[((i - 1) %% length(colors)) + 1])
  })

  hc <- highcharter::highchart() %>%
    highcharter::hc_chart(type = "heatmap", height = height) %>%
    highcharter::hc_add_series(
      data = waffle_data,
      borderColor = border_color,
      borderWidth = border_width,
      dataLabels = list(enabled = FALSE),
      colsize = 1,
      rowsize = 1
    ) %>%
    highcharter::hc_xAxis(
      visible = FALSE,
      min = -0.5,
      max = cols - 0.5
    ) %>%
    highcharter::hc_yAxis(
      visible = FALSE,
      min = -0.5,
      max = rows - 0.5
    ) %>%
    highcharter::hc_colorAxis(
      min = 0.5,
      max = n_cats + 0.5,
      dataClasses = lapply(seq_len(n_cats), function(i) {
        list(
          from = i - 0.5,
          to = i + 0.5,
          color = colors[((i - 1) %% length(colors)) + 1],
          name = categories[i]
        )
      })
    ) %>%
    highcharter::hc_legend(
      enabled = show_in_legend,
      layout = "horizontal",
      align = "center",
      verticalAlign = "bottom"
    ) %>%
    highcharter::hc_plotOptions(
      heatmap = list(
        borderRadius = 2,
        pointPadding = 1
      )
    )

  # Title & subtitle
  if (!is.null(title)) hc <- hc %>% highcharter::hc_title(text = title)
  if (!is.null(subtitle)) hc <- hc %>% highcharter::hc_subtitle(text = subtitle)

  # Tooltip
  if (!is.null(tooltip)) {
    tooltip_result <- .process_tooltip_config(
      tooltip = tooltip,
      tooltip_prefix = tooltip_prefix,
      tooltip_suffix = tooltip_suffix,
      x_tooltip_suffix = NULL,
      chart_type = "waffle",
      context = list()
    )
    hc <- .apply_tooltip_to_hc(hc, tooltip_result)
  } else {
    pre <- if (is.null(tooltip_prefix) || tooltip_prefix == "") "" else tooltip_prefix
    suf <- if (is.null(tooltip_suffix) || tooltip_suffix == "") "" else tooltip_suffix

    tooltip_fn <- sprintf(
      "function() {
         return '<b>' + this.point.name + '</b><br/>' +
                '%s' + this.point.count.toLocaleString() + '%s<br/>' +
                '<span style=\"color:#666;font-size:0.9em\">' +
                this.point.pct + '%% of total</span>';
       }",
      pre, suf
    )
    hc <- hc %>% highcharter::hc_tooltip(
      formatter = highcharter::JS(tooltip_fn),
      useHTML = TRUE
    )
  }

  # Credits
  hc <- hc %>% highcharter::hc_credits(enabled = FALSE)

  return(hc)
}
