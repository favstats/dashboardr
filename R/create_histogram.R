
# Load dependencies
library(highcharter)
library(tidyverse)
library(dplyr)
library(rlang)
library(roxygen2)

# Helper function (from rlang or magrittr)
`%||%` <- function(x, y) {
  if (is.null(x)) y else y
}

# --------------------------------------------------------------------------
# Function: create_histogram
# --------------------------------------------------------------------------
#' @title Create an Histogram
#' @description This function creates a histogram for survey data. It handles raw
#'              (unaggregated) data, counting the occurences of categories, supporting
#'              ordered factors, allowing numerical x-axis variables to be binned
#'              into custom groups, and enables renaming of categorical values for
#'              display. It can also handle SPSS (.sav) columns automatically.
#'
#' @param data A data frame containing the variable to plot.
#' @param x_var String. Name of the numeric column to histogram.
#' @param y_var Optional string. Name of a pre-computed count column.
#'   If supplied, the function skips counting and uses this column as y.
#' @param title Optional string. Main chart title.
#' @param subtitle Optional string. Chart subtitle.
#' @param x_label Optional string. X-axis label. Defaults to `x_var`.
#' @param y_label Optional string. Y-axis label. Defaults to "Count" or
#'   "Percentage".
#' @param histogram_type One of "count" or "percent". Default "count".
#' @param tooltip_prefix Optional string prepended in the tooltip.
#' @param tooltip_suffix Optional string appended in the tooltip.
#' @param x_tooltip_suffix Optional string appended to x value in tooltip.
#' @param bins Optional integer. Number of bins to compute via `hist()`.
#' @param bin_breaks Optional numeric vector of cut points.
#' @param bin_labels Optional character vector of labels for the bins.
#'   Must be length `length(breaks)-1`.
#' @param include_na Logical. If TRUE, treats NA as explicit "(NA)" bin.
#' @param color Optional string or vector of colors for the bars.
#' @param x_map_values Optional named list to recode raw `x_var` values
#'   before binning.
#' @param x_order Optional character vector to order the factor levels
#'   of the binned variable.
#'
#' @return A `highcharter` histogram (column) plot object.
#' 
#' #' @examples
#' library(dplyr)
#' # Simulate iris as survey data with some NAs
#' iris_data <- as_tibble(iris) %>%
#'   mutate(
#'     Petal.Length = if_else(row_number() %% 12 == 0,
#'                            NA_real_, Petal.Length)
#'   )
#'
#' # 1. Basic count histogram of Petal.Length
#' create_histogram(
#'   data          = iris_data,
#'   x_var         = "Petal.Length",
#'   title         = "Distribution of Petal Length",
#'   x_label       = "Petal Length (cm)",
#'   y_label       = "Count of Flowers",
#'   histogram_type = "count",
#'   color         = "#2b83ba"
#' )
#'
#' # 2. Percentage histogram with custom tooltip suffix
#' create_histogram(
#'   data            = iris_data,
#'   x_var           = "Petal.Length",
#'   histogram_type  = "percent",
#'   tooltip_suffix  = "%",
#'   x_tooltip_suffix= " cm",
#'   title           = "Petal Length (%) Distribution",
#'   color           = c("#d7191c", "#fdae61", "#abdda4", "#2b83ba")
#' )
#'
#' # 3. Manual binning into 5 categories with labels
#' breaks <- c(0, 1.5, 3.0, 4.5, 6.0, Inf)
#' labels <- c("Very Short", "Short", "Medium", "Long", "Very Long")
#' create_histogram(
#'   data        = iris_data,
#'   x_var       = "Petal.Length",
#'   bin_breaks  = breaks,
#'   bin_labels  = labels,
#'   include_na  = TRUE,
#'   title       = "Binned Petal Length with (NA)",
#'   color       = "#ffffbf"
#' )
#'
#' # 4. Using pre-aggregated counts
#' agg <- iris_data %>%
#'   filter(!is.na(Petal.Length)) %>%
#'   cut(Petal.Length, breaks = breaks, labels = labels,
#'       include.lowest = TRUE, right = FALSE) %>%
#'   table() %>%
#'   as.data.frame()
#' colnames(agg) <- c("Petal_Bin", "n")
#' create_histogram(
#'   data   = agg,
#'   x_var  = "Petal_Bin",
#'   y_var  = "n",
#'   title  = "Aggregated Petal Length Counts",
#'   color  = "#fdae61"
#' )
#' 
#' @details
#' This function performs the following steps:
#' \enumerate{
#'    \item **Input validation:** Checks that `data` is a data frame and
#'    `x_var` (and `y_var` if given) exist.
#'    \item **Haven-labelled handling:** If `x_var` is of class
#'    `"haven_labelled"`, converts it to numeric.
#'    \item **Value mapping:** If `x_map_values` is provided, recodes raw values
#'    before any binning.
#'    \item**Binning:**
#'      \itemize{  
  #'      \item If `bins` is set (and `bin_breaks` is `NULL`), computes breaks via
  #'      `hist()`.  
  #'      \item If `bin_breaks` is provided, cuts `x_var` into categories, using
  #'      `bin_labels` if supplied.  
  #'      \item Otherwise uses the raw `x_var` values.
#'      }
#'    \item **Factor and NA handling:** Converts the plotting variable to a factor;
#'    if `include_na = TRUE`, adds an explicit "(NA)" level.
#'    Applies `x_order` if given.
#'    \item **Aggregation:**
#'      \itemize{  
#'        \item If `y_var` is `NULL`, counts occurrences of each factor level.  
#'        \item Otherwise renames `y_var` to `n` and skips counting.
#'        }
#'    \item **Chart construction:** Builds a `highcharter` column chart of `n`
#'    vs. the factor levels.
#'    \item **Customization:**
#'      \itemize{  
#'        \item Applies `title`, `subtitle`, axis labels.  
#'        \item Sets stacking mode (for percent vs. count), data labels format.  
#'        \item Defines a JS `tooltip.formatter` using `tooltip_prefix`,
#'      `tooltip_suffix`, and `x_tooltip_suffix`.  
#'        \item Applies custom `color` if provided.
#'        }
#'    }
#' 
#' @export

########################################################################

# the function

create_histogram <- function(data,
                             x_var,
                             y_var               = NULL,
                             title               = NULL,
                             subtitle            = NULL,
                             x_label             = NULL,
                             y_label             = NULL,
                             histogram_type      = c("count", "percent"),
                             tooltip_prefix      = "",
                             tooltip_suffix      = "",
                             x_tooltip_suffix    = "",
                             bins                = NULL,
                             bin_breaks          = NULL,
                             bin_labels          = NULL,
                             include_na          = FALSE,
                             color               = NULL,
                             x_map_values        = NULL,
                             x_order             = NULL) {
  histogram_type <- match.arg(histogram_type)
  
  # INPUT VALIDATION
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  if (!x_var %in% names(data)) {
    stop(paste0("Column '", x_var, "' not found in data."), call. = FALSE)
  }
  
  # DATA PREP
  df <- tibble::as_tibble(data)
  # Recode haven_labelled if present
  if (requireNamespace("haven", quietly = TRUE) &&
      inherits(df[[x_var]], "haven_labelled")) {
    df <- df |> dplyr::mutate(
      !!rlang::sym(x_var) := haven::as_numeric(!!rlang::sym(x_var))
    )
  }
  # Map raw values if requested (before binning)
  if (!is.null(x_map_values)) {
    if (!is.list(x_map_values) || is.null(names(x_map_values))) {
      stop("`x_map_values` must be a named list.", call. = FALSE)
    }
    df <- df |>
      dplyr::mutate(!!rlang::sym(x_var) := dplyr::recode(
        as.character(!!rlang::sym(x_var)), !!!x_map_values
      ))
    warning("Applied x_map_values before binning.", call. = FALSE)
  }
  # BINNING
  # Compute breaks if only bins provided
  if (is.null(bin_breaks) && !is.null(bins)) {
    if (!is.numeric(df[[x_var]])) {
      stop("`x_var` must be numeric to compute `bins`.", call. = FALSE)
    }
    bin_breaks <- hist(
      df[[x_var]], plot = FALSE, breaks = bins
    )$breaks
  }
  # Use cut() if breaks available
  if (!is.null(bin_breaks)) {
    if (!is.numeric(df[[x_var]])) {
      warning("`x_var` not numeric; ignoring bin_breaks.", call. = FALSE)
      bin_breaks <- NULL
      bin_labels <- NULL
    } else {
      if (!is.null(bin_labels) &&
          length(bin_labels) != (length(bin_breaks) - 1)) {
        stop("Length of `bin_labels` must be `length(bin_breaks)-1`.",
             call. = FALSE)
      }
      df <- df |>
        dplyr::mutate(
          .x_binned = cut(
            !!rlang::sym(x_var),
            breaks = bin_breaks,
            labels = bin_labels,
            include.lowest = TRUE,
            right = FALSE
          )
        )
      x_plot_var <- ".x_binned"
    }
  } else {
    x_plot_var <- x_var
  }
  # Factor & NA handling
  df <- df |>
    dplyr::mutate(
      .x_factor = if (include_na) {
        addNA(!!rlang::sym(x_plot_var), ifany = TRUE)
      } else {
        !!rlang::sym(x_plot_var)
      } |> as.factor()
    )
  # Apply custom ordering
  if (!is.null(x_order)) {
    levs <- levels(df$.x_factor)
    kept <- x_order[x_order %in% levs]
    other <- setdiff(levs, kept)
    df <- df |>
      dplyr::mutate(
        .x_factor = factor(.x_factor, levels = c(kept, other))
      )
  }
  # AGGREGATION
  if (is.null(y_var)) {
    df <- df |> dplyr::count(.x_factor, name = "n")
  } else {
    if (!y_var %in% names(df)) {
      stop("`y_var` not found in data.", call. = FALSE)
    }
    df <- df |> dplyr::rename(n = !!rlang::sym(y_var))
  }
  # HIGHCHARTER
  hc <- highcharter::hchart(
    df, type = "column",
    highcharter::hcaes(x = .x_factor, y = n)
  )
  # Titles
  if (!is.null(title))    hc <- hc %>% highcharter::hc_title(text = title)
  if (!is.null(subtitle)) hc <- hc %>% highcharter::hc_subtitle(text = subtitle)
  # Axis labels
  final_x <- x_label %||% x_var
  default_y <- if (histogram_type == "percent") "Percentage" else "Count"
  final_y <- y_label %||% default_y
  hc <- hc %>%
    highcharter::hc_xAxis(title = list(text = final_x)) %>%
    highcharter::hc_yAxis(title = list(text = final_y))
  # Plot options: percent vs count
  fmt       <- if (histogram_type == "percent") "{point.percentage:.1f}%" else "{point.y}"
  stacking  <- if (histogram_type == "percent") "percent" else "normal"
  hc <- hc %>% highcharter::hc_plotOptions(
    column = list(
      stacking = stacking,
      dataLabels = list(enabled = TRUE, format = fmt,
                        style = list(textOutline = "none"))
    )
  )
  # Tooltip
  pre  <- tooltip_prefix %||% ""
  suf  <- tooltip_suffix %||% ""
  xsuf <- x_tooltip_suffix %||% ""
  tooltip_fn <- sprintf(
    "function() {
      var val = %s;
      return '<b>' + this.x + '%s</b><br/>%s' +
             val + '%s';
     }",
    if (histogram_type == "percent") "this.percentage.toFixed(1) + '%'" else "this.y",
    xsuf, pre, suf
  )
  hc <- hc %>% highcharter::hc_tooltip(formatter = highcharter::JS(tooltip_fn))
  # Color palette 
  if (!is.null(color)) hc <- hc %>% highcharter::hc_colors(color)
  return(hc)
}