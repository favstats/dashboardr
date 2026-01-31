#' Create a Tooltip Configuration
#'
#' Creates a tooltip configuration object for use with dashboardr visualization
#' functions. This provides a unified way to customize tooltips across all chart
#' types with full access to Highcharts tooltip options.
#'
#' @param format Character. Format string with \{placeholders\}. Available placeholders
#'   vary by chart type:
#'   \itemize{
#'     \item \code{\{value\}} - Primary value (all charts)
#'     \item \code{\{category\}} - X-axis category (bar, histogram, stackedbar)
#'     \item \code{\{x\}} - X value (scatter, heatmap)
#'     \item \code{\{y\}} - Y value (scatter, heatmap)
#'     \item \code{\{name\}} - Point/series name (all charts)
#'     \item \code{\{series\}} - Series name (grouped charts)
#'     \item \code{\{percent\}} - Percentage (percent-type charts)
#'   }
#' @param prefix Character. Text prepended to the value. Shortcut for simple customization.
#' @param suffix Character. Text appended to the value. Shortcut for simple customization.
#' @param header Character or FALSE. Header format string, or FALSE to hide the header.
#' @param shared Logical. If TRUE, shows a shared tooltip for all series at the same x-value.
#'   Default is FALSE.
#' @param style Named list. CSS styles for the tooltip text, e.g.,
#'   \code{list(fontSize = "14px", fontWeight = "bold")}.
#' @param backgroundColor Character. Background color for the tooltip (e.g., "#f5f5f5").
#' @param borderColor Character. Border color for the tooltip.
#' @param borderRadius Numeric. Corner radius in pixels.
#' @param borderWidth Numeric. Border width in pixels.
#' @param shadow Logical. Whether to show a shadow behind the tooltip. Default is TRUE.
#' @param enabled Logical. Whether tooltips are enabled. Default is TRUE.
#' @param followPointer Logical. Whether the tooltip should follow the mouse pointer.
#' @param outside Logical. Whether to render the tooltip outside the chart SVG.
#' @param ... Additional Highcharts tooltip options passed directly to hc_tooltip().
#'
#' @return A \code{dashboardr_tooltip} object that can be passed to any viz_* function's
#'   \code{tooltip} parameter.
#'
#' @examples
#' # Simple suffix
#' tooltip(suffix = "%")
#'
#' # Custom format string
#' tooltip(format = "{category}: {value} respondents")
#'
#' # Full styling
#' tooltip(
#'   format = "<b>{category}</b><br/>Count: {value}",
#'   backgroundColor = "#f5f5f5",
#'   borderColor = "#999",
#'   borderRadius = 8,
#'   style = list(fontSize = "14px")
#' )
#'
#' # Shared tooltip for grouped charts
#' tooltip(shared = TRUE, format = "{series}: {value}")
#'
#' @seealso \code{\link{viz_bar}}, \code{\link{viz_scatter}}, \code{\link{viz_histogram}}
#' @export
tooltip <- function(
    format = NULL,
    prefix = NULL,
    suffix = NULL,
    header = NULL,
    shared = FALSE,
    style = NULL,
    backgroundColor = NULL,
    borderColor = NULL,
    borderRadius = NULL,
    borderWidth = NULL,
    shadow = TRUE,
    enabled = TRUE,
    followPointer = NULL,
    outside = NULL,
    ...
) {
  structure(
    list(
      format = format,
      prefix = prefix,
      suffix = suffix,
      header = header,
      shared = shared,
      style = style,
      backgroundColor = backgroundColor,
      borderColor = borderColor,
      borderRadius = borderRadius,
      borderWidth = borderWidth,
      shadow = shadow,
      enabled = enabled,
      followPointer = followPointer,
      outside = outside,
      extra = list(...)
    ),
    class = "dashboardr_tooltip"
  )
}

#' Check if object is a tooltip configuration
#' @param x Object to test
#' @return Logical
#' @keywords internal
is_tooltip <- function(x) {
  inherits(x, "dashboardr_tooltip")
}

#' Print method for tooltip configurations
#' @param x A dashboardr_tooltip object
#' @param ... Ignored
#' @export
print.dashboardr_tooltip <- function(x, ...) {
  cat("<dashboardr_tooltip>\n")
  if (!is.null(x$format)) cat("  format:", x$format, "\n")
  if (!is.null(x$prefix)) cat("  prefix:", x$prefix, "\n")
  if (!is.null(x$suffix)) cat("  suffix:", x$suffix, "\n")
  if (!is.null(x$header)) cat("  header:", if (isFALSE(x$header)) "(hidden)" else x$header, "\n")
  if (x$shared) cat("  shared: TRUE\n")
  if (!is.null(x$style)) cat("  style:", paste(names(x$style), "=", unlist(x$style), collapse = ", "), "\n
")
  if (!is.null(x$backgroundColor)) cat("  backgroundColor:", x$backgroundColor, "\n")
  if (!is.null(x$borderColor)) cat("  borderColor:", x$borderColor, "\n")
  if (!is.null(x$borderRadius)) cat("  borderRadius:", x$borderRadius, "px\n")
  if (!x$enabled) cat("  enabled: FALSE\n")
  if (length(x$extra) > 0) cat("  + ", length(x$extra), " additional options\n")
  invisible(x)
}


# ============================================================================
# INTERNAL TOOLTIP PROCESSING
# ============================================================================

#' Process tooltip configuration for a chart
#'
#' Internal function that converts tooltip parameters into the appropriate
#' Highcharts tooltip configuration. Handles the 3-tier priority system.
#'
#' @param tooltip A dashboardr_tooltip object, a format string, or NULL
#' @param tooltip_prefix Legacy prefix parameter
#' @param tooltip_suffix Legacy suffix parameter
#' @param x_tooltip_suffix Legacy x suffix parameter
#' @param chart_type Character identifying the chart type
#' @param context Named list with chart-specific context (labels, data info, etc.)
#'
#' @return A list with 'formatter_js' (JavaScript function string) and 
#'   'options' (list of hc_tooltip options)
#' @keywords internal
.process_tooltip_config <- function(
    tooltip = NULL,
    tooltip_prefix = NULL,
    tooltip_suffix = NULL,
    x_tooltip_suffix = NULL,
    chart_type = "bar",
    context = list()
) {
  # Initialize result
  result <- list(
    formatter_js = NULL,
    options = list(useHTML = TRUE)
  )
 
 # Determine which tier we're using
  if (!is.null(tooltip)) {
    # Tier 2 or 3: tooltip parameter provided
    if (is.character(tooltip)) {
      # Tier 2: Format string provided directly
      tooltip_config <- tooltip(format = tooltip)
    } else if (is_tooltip(tooltip)) {
      # Tier 3: Full tooltip() configuration
      tooltip_config <- tooltip
    } else {
      warning("tooltip must be a character string or tooltip() object. Using defaults.")
      tooltip_config <- NULL
    }
    
    if (!is.null(tooltip_config)) {
      result <- .build_tooltip_from_config(tooltip_config, chart_type, context)
    }
  } else {
    # Tier 1: Use legacy prefix/suffix parameters
    result <- .build_tooltip_from_legacy(
      prefix = tooltip_prefix,
      suffix = tooltip_suffix,
      x_suffix = x_tooltip_suffix,
      chart_type = chart_type,
      context = context
    )
  }
  
  result
}

#' Build tooltip from a tooltip() configuration object
#' @keywords internal
.build_tooltip_from_config <- function(config, chart_type, context) {
  result <- list(
    formatter_js = NULL,
    options = list(useHTML = TRUE)
  )
  
  # Apply styling options
  if (!is.null(config$backgroundColor)) {
    result$options$backgroundColor <- config$backgroundColor
  }
  if (!is.null(config$borderColor)) {
    result$options$borderColor <- config$borderColor
  }
  if (!is.null(config$borderRadius)) {
    result$options$borderRadius <- config$borderRadius
  }
  if (!is.null(config$borderWidth)) {
    result$options$borderWidth <- config$borderWidth
  }
  if (!isTRUE(config$shadow)) {
    result$options$shadow <- config$shadow
  }
  if (!isTRUE(config$enabled)) {
    result$options$enabled <- config$enabled
  }
  if (isTRUE(config$shared)) {
    result$options$shared <- TRUE
  }
  if (!is.null(config$followPointer)) {
    result$options$followPointer <- config$followPointer
  }
  if (!is.null(config$outside)) {
    result$options$outside <- config$outside
  }
  if (!is.null(config$style)) {
    result$options$style <- config$style
  }
  
  # Handle header
  if (isFALSE(config$header)) {
    result$options$headerFormat <- ""
  } else if (!is.null(config$header)) {
    result$options$headerFormat <- config$header
  }
  
  # Add any extra options
  if (length(config$extra) > 0) {
    result$options <- c(result$options, config$extra)
  }
  
  # Build formatter from format string or prefix/suffix
  if (!is.null(config$format)) {
    result$formatter_js <- .build_formatter_from_format(config$format, chart_type, context)
  } else if (!is.null(config$prefix) || !is.null(config$suffix)) {
    # Use prefix/suffix from tooltip() config
    result <- .build_tooltip_from_legacy(
      prefix = config$prefix,
      suffix = config$suffix,
      x_suffix = NULL,
      chart_type = chart_type,
      context = context
    )
    # Merge styling options if present
    if (!is.null(config$backgroundColor)) {
      result$options$backgroundColor <- config$backgroundColor
    }
    if (!is.null(config$borderColor)) {
      result$options$borderColor <- config$borderColor
    }
  }
  
  result
}

#' Build formatter JavaScript from a format string with placeholders
#' @keywords internal
.build_formatter_from_format <- function(format_string, chart_type, context) {
  # Escape special characters for JavaScript
  js_format <- gsub("'", "\\'", format_string, fixed = TRUE)
  
  # Build placeholder replacements based on chart type
  # We'll create a JavaScript function that replaces placeholders
  
  sprintf(
    "function() {
      var format = '%s';
      var cat = this.point.category || (this.series.chart.xAxis[0].categories ? this.series.chart.xAxis[0].categories[this.point.x] : this.x) || '';
      var val = typeof this.y === 'number' ? this.y.toLocaleString('en-US', {maximumFractionDigits: 2}) : this.y;
      var rawVal = this.point.rawValue || this.point.options.rawValue || val;
      var pct = this.percentage !== undefined ? this.percentage.toFixed(1) : (this.point.percentage || '');
      var seriesName = this.series.name || '';
      var pointName = this.point.name || '';
      var xVal = this.x !== undefined ? this.x : '';
      var yVal = this.y !== undefined ? this.y : '';
      
      // Replace placeholders
      format = format.replace(/\\{value\\}/g, val);
      format = format.replace(/\\{category\\}/g, cat);
      format = format.replace(/\\{x\\}/g, xVal);
      format = format.replace(/\\{y\\}/g, yVal);
      format = format.replace(/\\{name\\}/g, pointName);
      format = format.replace(/\\{series\\}/g, seriesName);
      format = format.replace(/\\{percent\\}/g, pct + '%%');
      format = format.replace(/\\{raw\\}/g, rawVal);
      
      return format;
    }",
    js_format
  )
}

#' Build tooltip from legacy prefix/suffix parameters
#' @keywords internal
.build_tooltip_from_legacy <- function(prefix, suffix, x_suffix, chart_type, context) {
  result <- list(
    formatter_js = NULL,
    options = list(useHTML = TRUE)
  )
  
  pre <- if (is.null(prefix) || prefix == "") "" else prefix
  suf <- if (is.null(suffix) || suffix == "") "" else suffix
  xsuf <- if (is.null(x_suffix) || x_suffix == "") "" else x_suffix
  
  # Build chart-type specific formatter
  formatter_js <- switch(chart_type,
    "bar" = .build_bar_formatter(pre, suf, xsuf, context),
    "histogram" = .build_histogram_formatter(pre, suf, xsuf, context),
    "scatter" = .build_scatter_formatter(pre, suf, context),
    "heatmap" = .build_heatmap_formatter(pre, suf, context),
    "stackedbar" = .build_stackedbar_formatter(pre, suf, xsuf, context),
    "treemap" = .build_treemap_formatter(pre, suf, context),
    "map" = .build_map_formatter(pre, suf, context),
    "density" = .build_density_formatter(pre, suf, context),
    "boxplot" = .build_boxplot_formatter(pre, suf, context),
    "timeline" = .build_timeline_formatter(pre, suf, context),
    # Default fallback
    .build_default_formatter(pre, suf, context)
  )
  
  result$formatter_js <- formatter_js
  result
}

#' Build bar chart formatter
#' @keywords internal
.build_bar_formatter <- function(pre, suf, xsuf, context) {
  bar_type <- context$bar_type %||% "count"
  is_grouped <- isTRUE(context$is_grouped)
  total_value <- context$total_value %||% 100
  
  if (!is_grouped) {
    if (bar_type == "percent") {
      sprintf(
        "function() {
           var cat = this.point.category || this.series.chart.xAxis[0].categories[this.point.x] || this.x;
           var pct = this.y.toFixed(1);
           var rawVal = this.point.rawValue || this.point.options.rawValue;
           var tooltipText = '<b>' + cat + '%s</b><br/>';
           if (rawVal !== undefined && rawVal !== null) {
             tooltipText += '%s' + rawVal.toLocaleString('en-US', {maximumFractionDigits: 1}) + '%s<br/>';
             tooltipText += '<span style=\"color:#666;font-size:0.9em\">' + pct + '%% of total</span>';
           } else {
             tooltipText += '%s' + pct + '%%' + '%s';
           }
           return tooltipText;
         }",
        xsuf, pre, suf, pre, suf
      )
    } else {
      sprintf(
        "function() {
           var cat = this.point.category || this.series.chart.xAxis[0].categories[this.point.x] || this.x;
           var val = this.y;
           var total = %s;
           var pct = total > 0 ? (val / total * 100).toFixed(1) : 0;
           return '<b>' + cat + '%s</b><br/>' +
                  '%s' + val.toLocaleString() + '%s<br/>' +
                  '<span style=\"color:#666;font-size:0.9em\">' + pct + '%% of total</span>';
         }",
        total_value, xsuf, pre, suf
      )
    }
  } else {
    sprintf(
      "function() {
         var cat = this.point.category || this.series.chart.xAxis[0].categories[this.point.x] || this.x;
         var val = %s;
         return '<b>' + cat + '%s</b><br/>' +
                this.series.name + ': %s' + val + '%s';
       }",
      if (bar_type == "percent") "this.y.toFixed(1)" else "this.y",
      xsuf, pre, suf
    )
  }
}

#' Build histogram formatter
#' @keywords internal
.build_histogram_formatter <- function(pre, suf, xsuf, context) {
  histogram_type <- context$histogram_type %||% "count"
  
  sprintf(
    "function() {
       var cat = this.point.category;
       var val = %s;
       return '<b>' + cat + '%s</b><br/>' +
              '%s' + val + '%s';
     }",
    if (histogram_type == "percent") "this.percentage.toFixed(1) + '%'" else "this.y",
    xsuf, pre, suf
  )
}

#' Build scatter formatter
#' @keywords internal
.build_scatter_formatter <- function(pre, suf, context) {
  x_label <- context$x_label %||% "X"
  y_label <- context$y_label %||% "Y"
  
  sprintf(
    "function() {
       var tooltipText = '<b>%s:</b> ' + this.x + '<br/>' +
                         '<b>%s:</b> %s' + this.y + '%s';
       if (this.series.name && this.series.name !== '%s') {
         tooltipText += '<br/><b>Group:</b> ' + this.series.name;
       }
       return tooltipText;
     }",
    x_label, y_label, pre, suf, y_label
  )
}

#' Build heatmap formatter
#' @keywords internal
.build_heatmap_formatter <- function(pre, suf, context) {
  x_label <- context$x_label %||% "X"
  y_label <- context$y_label %||% "Y"
  value_label <- context$value_label %||% "Value"
  
  sprintf(
    "function() {
       var xCat = this.series.xAxis.categories ? this.series.xAxis.categories[this.point.x] : this.point.x;
       var yCat = this.series.yAxis.categories ? this.series.yAxis.categories[this.point.y] : this.point.y;
       return '<b>%s:</b> ' + xCat + '<br/>' +
              '<b>%s:</b> ' + yCat + '<br/>' +
              '<b>%s:</b> %s' + this.point.value.toLocaleString() + '%s';
     }",
    x_label, y_label, value_label, pre, suf
  )
}

#' Build stacked bar formatter
#' @keywords internal
.build_stackedbar_formatter <- function(pre, suf, xsuf, context) {
  stacked_type <- context$stacked_type %||% "counts"
  is_percent <- stacked_type == "percent"
  
  sprintf(
    "function() {
       var cat = this.point.category || this.series.chart.xAxis[0].categories[this.point.x] || this.x;
       var value = %s;
       return '<b>' + cat + '%s</b><br/>' +
              this.series.name + ': %s' + value + '%s<br/>' +
              'Total: ' + %s;
     }",
    if (is_percent) "this.percentage.toFixed(1)" else "this.y",
    xsuf, pre, suf,
    if (is_percent) "100" else "this.point.stackTotal"
  )
}

#' Build treemap formatter
#' @keywords internal
.build_treemap_formatter <- function(pre, suf, context) {
  sprintf(
    "function() {
       return '<b>' + this.point.name + '</b><br/>' +
              '%s' + this.point.value.toLocaleString() + '%s';
     }",
    pre, suf
  )
}

#' Build map formatter
#' @keywords internal
.build_map_formatter <- function(pre, suf, context) {
  sprintf(
    "function() {
       return '<b>' + this.point.name + '</b><br/>' +
              '%s' + this.point.value.toLocaleString() + '%s';
     }",
    pre, suf
  )
}

#' Build density formatter
#' @keywords internal
.build_density_formatter <- function(pre, suf, context) {
  sprintf(
    "function() {
       return '<b>Value:</b> ' + this.x.toFixed(2) + '<br/>' +
              '<b>Density:</b> %s' + this.y.toFixed(4) + '%s';
     }",
    pre, suf
  )
}

#' Build boxplot formatter
#' @keywords internal
.build_boxplot_formatter <- function(pre, suf, context) {
  sprintf(
    "function() {
       var cat = this.point.category || this.series.chart.xAxis[0].categories[this.point.x] || '';
       return '<b>' + cat + '</b><br/>' +
              'Maximum: %s' + this.point.high + '%s<br/>' +
              'Upper Quartile: %s' + this.point.q3 + '%s<br/>' +
              'Median: %s' + this.point.median + '%s<br/>' +
              'Lower Quartile: %s' + this.point.q1 + '%s<br/>' +
              'Minimum: %s' + this.point.low + '%s';
     }",
    pre, suf, pre, suf, pre, suf, pre, suf, pre, suf
  )
}

#' Build timeline formatter
#' @keywords internal
.build_timeline_formatter <- function(pre, suf, context) {
  sprintf(
    "function() {
       var date = Highcharts.dateFormat('%%Y-%%m-%%d', this.x);
       return '<b>' + date + '</b><br/>' +
              (this.point.name ? this.point.name : '%s' + this.y + '%s');
     }",
    pre, suf
  )
}

#' Build default formatter
#' @keywords internal
.build_default_formatter <- function(pre, suf, context) {
  sprintf(
    "function() {
       var name = this.point.name || this.series.name || '';
       return (name ? '<b>' + name + '</b><br/>' : '') +
              '%s' + this.y + '%s';
     }",
    pre, suf
  )
}

#' Apply processed tooltip configuration to a highchart
#'
#' @param hc A highchart object
#' @param tooltip_result Result from .process_tooltip_config()
#' @return Modified highchart object
#' @keywords internal
.apply_tooltip_to_hc <- function(hc, tooltip_result) {
  # Build tooltip options - only include non-NULL values
  tooltip_args <- list(useHTML = TRUE)
  
  # Add formatter if we have one
  if (!is.null(tooltip_result$formatter_js)) {
    tooltip_args$formatter <- highcharter::JS(tooltip_result$formatter_js)
  }
  
  # Add optional styling parameters only if specified
  opts <- tooltip_result$options
  if (!is.null(opts$headerFormat)) tooltip_args$headerFormat <- opts$headerFormat
  if (!is.null(opts$shared) && opts$shared) tooltip_args$shared <- opts$shared
  if (!is.null(opts$backgroundColor)) tooltip_args$backgroundColor <- opts$backgroundColor
  if (!is.null(opts$borderColor)) tooltip_args$borderColor <- opts$borderColor
  if (!is.null(opts$borderRadius)) tooltip_args$borderRadius <- opts$borderRadius
  if (!is.null(opts$borderWidth)) tooltip_args$borderWidth <- opts$borderWidth
  if (!is.null(opts$shadow) && !opts$shadow) tooltip_args$shadow <- opts$shadow
  if (!is.null(opts$enabled) && !opts$enabled) tooltip_args$enabled <- opts$enabled
  if (!is.null(opts$followPointer)) tooltip_args$followPointer <- opts$followPointer
  if (!is.null(opts$outside)) tooltip_args$outside <- opts$outside
  if (!is.null(opts$style)) tooltip_args$style <- opts$style
  
  # Apply to highchart using do.call
  do.call(highcharter::hc_tooltip, c(list(hc = hc), tooltip_args))
}

# Null-coalescing operator if not already defined
`%||%` <- function(x, y) if (is.null(x)) y else x
