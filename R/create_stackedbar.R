# --------------------------------------------------------------------------
# Function: create_stackedbar
# --------------------------------------------------------------------------
#' @export
#' @title Create a Stacked Bar Chart
#'
#' @description This function creates a stacked barchart for survey data. It
#'              handles raw (unaggregated) data, counting the occurrences of
#'              categories, supporting ordered factors, allowing numerical x-axis
#'              and stacked variables to be binned into custom groups, and
#'              enables renaming of categorical values for display. It can also
#'              handle SPSS (.sav) columns automatically.
#'
#' @param data A data frame containing the raw survey data (one row per respondent).
#' @param x_var String. Name of the column for the X-axis categories.
#' @param y_var Optional string. Name of a pre-computed count column. If NULL (default),
#'   the function counts occurrences.
#' @param stack_var String. Name of the column whose values define the stacks.
#' @param title Optional string. Main chart title.
#' @param subtitle Optional string. Chart subtitle.
#' @param x_label Optional string. X-axis label. Defaults to `x_var`.
#' @param y_label Optional string. Y-axis label. Defaults to "Number of Respondents"
#'   or "Percentage of Respondents".
#' @param stack_label Optional string. Title for the stack legend. Defaults to `stack_var`.
#' @param stacked_type One of "normal" (counts) or "percent" (100% stacked). Default "normal".
#' @param tooltip_prefix Optional string prepended to tooltip values.
#' @param tooltip_suffix Optional string appended to tooltip values.
#' @param x_tooltip_suffix Optional string appended to x-axis values in tooltips.
#' @param color_palette Optional character vector of colors for the stacks.
#' @param stack_order Optional character vector specifying order of `stack_var` levels.
#' @param x_order Optional character vector specifying order of `x_var` levels.
#' @param include_na Logical. If TRUE, NA values in both `x_var` and `stack_var` are
#'   shown as explicit categories. If FALSE (default), rows with NA in either variable
#'   are excluded. Default FALSE.
#' @param na_label_x String. Label for NA values in `x_var` when `include_na = TRUE`.
#'   Default "(Missing)".
#' @param na_label_stack String. Label for NA values in `stack_var` when `include_na = TRUE`.
#'   Default "(Missing)".
#' @param x_breaks Optional numeric vector of cut points for binning `x_var`.
#' @param x_bin_labels Optional character vector of labels for `x_breaks` bins.
#' @param x_map_values Optional named list to remap `x_var` values for display.
#' @param stack_breaks Optional numeric vector of cut points for binning `stack_var`.
#' @param stack_bin_labels Optional character vector of labels for `stack_breaks` bins.
#' @param stack_map_values Optional named list to remap `stack_var` values for display.
#'
#' @return An interactive `highcharter` bar chart plot object.
#'
#' @examples
#' # Load GSS data
#' library(gssr)
#' data(gss_panel20)
#'
#' gss_recent <- gss_panel20 %>%
#'   filter(year >= 2010) %>%
#'   select(age, degree, happy, sex, race, year, polviews, attend)
#'
#' # Example 1: Basic stacked bar (excluding NAs)
#' plot1 <- create_stackedbar(
#'   data = gss_panel20,
#'   x_var = "degree_1a",
#'   stack_var = "sex_1a",
#'   title = "Educational Attainment by Gender",
#'   subtitle = "GSS respondents 2010-present (NAs excluded)",
#'   x_label = "Highest Degree Completed",
#'   y_label = "Number of Respondents",
#'   stack_label = "Gender",
#'   include_na = FALSE  # Exclude missing values
#' )
#' plot1
#'
#' # Example 2: Including NA values with custom labels
#' plot2 <- create_stackedbar(
#'   data = gss_panel20,
#'   x_var = "degree_1a",
#'   x_label = "Degree"
#'   stack_var = "sex_1a",
#'   title = "Educational Attainment by Gender (Including Missing Data)",
#'   subtitle = "GSS respondents 2010-present",
#'   x_order = education_order,
#'   include_na = TRUE,
#'   na_label_x = "Education Not Reported",
#'   na_label_stack = "Gender Not Reported"
#' )
#' plot2
#'
#' # Example 3: Percentage stacked with NA handling
#' plot3 <- create_stackedbar(
#'   data = gss_panel20,
#'   x_var = "degree",
#'   stack_var = "happy",
#'   title = "Happiness Distribution by Education Level",
#'   subtitle = "Percentage within each education category",
#'   x_label = "Education Level",
#'   y_label = "Percentage",
#'   stack_label = "Happiness Level",
#'   stacked_type = "percent",
#'   x_order = education_order,
#'   stack_order = c("Very Happy", "Pretty Happy", "Not Too Happy"),
#'   tooltip_suffix = "%",
#'   color_palette = c("#2E8B57", "#FFD700", "#CD5C5C"),
#'   include_na = TRUE,
#'   na_label_x = "Missing",
#'   na_label_stack = "No Answer"
#' )
#' plot3
#'
#' # Example 4: Age binning with political views
#' age_breaks <- c(18, 30, 45, 60, 75, Inf)
#' age_labels <- c("18-29", "30-44", "45-59", "60-74", "75+")
#' gss_panel20$age_1a_numeric <- as.numeric(gss_panel20$age_1a)
#'
#' plot4 <- create_stackedbar(
#'   data = gss_panel20,
#'   x_var = "age_1a_numeric",
#'   stack_var = "polviews_1a",
#'   title = "Political Views by Age Group",
#'   subtitle = "Distribution across age cohorts",
#'   x_label = "Age Group",
#'   stack_label = "Political Views",
#'   x_breaks = age_breaks,
#'   x_bin_labels = age_labels,
#'   stacked_type = "percent",
#'   tooltip_suffix = "%",
#'   include_na = FALSE  # Exclude NAs for cleaner visualization
#' )
#' plot4
#'
#' # Example 5: Custom value mapping with NA inclusion
#' sex_map <- list("Male" = "Men", "Female" = "Women")
#'
#' plot5 <- create_stackedbar(
#'   data = gss_recent,
#'   x_var = "happy",
#'   stack_var = "sex",
#'   title = "Gender Distribution Across Happiness Levels",
#'   x_order = c("Very Happy", "Pretty Happy", "Not Too Happy"),
#'   stack_map_values = sex_map,
#'   stack_order = c("Women", "Men"),
#'   stacked_type = "normal",
#'   tooltip_prefix = "Count: ",
#'   include_na = TRUE,
#'   na_label_x = "Happiness Not Reported",
#'   na_label_stack = "Gender Not Specified"
#' )
#' plot5
#'
#'
#' @details This function performs the following steps:
#' \enumerate{
#'   \item **Input Validation:** Checks if the provided `data` is a data frame and if `x_var` and `stack_var` columns exist.
#'   \item **Data Copy:** Creates a mutable copy of the input `data` to perform transformations without affecting the original.
#'   \item **Handle 'haven_labelled' Columns:** If `haven` package is available, it detects if `x_var` or `stack_var` are of class `haven_labelled` (common for data imported from SPSS/Stata/SAS). If so, it converts them to standard R factors, using their underlying numeric values as levels (e.g., a '1' that was labeled "Male" will become a factor level "1"). This ensures `recode` can operate correctly.
#'   \item **Apply Value Mapping (`x_map_values`, `stack_map_values`):** If provided, `x_map_values` and `stack_map_values` (named lists, e.g., `list("1"="Male")`) are used to rename the values in `x_var` and `stack_var` respectively. This is useful for converting numeric codes or abbreviations into descriptive labels. If the column is a factor, it's temporarily converted to character to ensure `dplyr::recode` works reliably on the values.
#'   \item **Handle Binning (`x_breaks`, `x_bin_labels`, `stack_breaks`, `stack_bin_labels`):**
#'     \itemize{
#'       \item If `x_var` (or `stack_var`) is numeric and corresponding `_breaks` are provided, the function uses `base::cut()` to discretize the numeric variable into bins.
#'       \item `_bin_labels` can be supplied to give custom names to these bins (e.g., "18-24" instead of "(17,25]"). If not provided, `cut()` generates default labels.
#'       \item A temporary column (e.g., `.x_var_binned`) is created to hold the binned values, and this temporary column is then used for plotting.
#'     }
#'   \item **Data Aggregation and Final Factor Handling:**
#'     \itemize{
#'       \item The data is transformed using `dplyr::mutate` to ensure `x_var` and `stack_var` (or their binned versions) are treated as factors. If `include_na = TRUE`, missing values are converted into an explicit "(NA)" factor level.
#'       \item `dplyr::count()` is then used to aggregate the data, counting occurrences for each unique combination of `x_var` and `stack_var`. This creates the `n` column required for `highcharter`.
#'     }
#'   \item **Apply Custom Ordering (`x_order`, `stack_order`):** If provided, `x_order` and `stack_order` are used to set the display order of the factor levels for the X-axis and stack categories, respectively. This is essential for ordinal scales (e.g., Likert scales) or custom desired sorting. Levels not found in the order vector are appended at the end.
#'   \item **Highcharter Chart Generation:** The aggregated `plot_data` is passed to `highcharter::hchart()` to create the base stacked column chart.
#'   \item **Chart Customization:** Titles, subtitles, axis labels, stacking type (counts vs. percent), data labels, legend titles, tooltips, and custom color palettes are applied based on the function's arguments.
#'   \item **Return Value:** The function returns a `highcharter` plot object, which can be printed directly to display the interactive chart.
#' }
#'

########################################################################

# General function
create_stackedbar <- function(data,
                              x_var,
                              y_var = NULL,
                              stack_var,
                              title = NULL,
                              subtitle = NULL,
                              x_label = NULL,
                              y_label = NULL,
                              stack_label = NULL,
                              stacked_type = c("counts", "percent"),
                              tooltip_prefix = "",
                              tooltip_suffix = "",
                              x_tooltip_suffix = "",
                              color_palette = NULL,
                              stack_order = NULL,
                              x_order = NULL,
                              include_na = FALSE,
                              na_label_x = "(Missing)",
                              na_label_stack = "(Missing)",
                              x_breaks = NULL,
                              x_bin_labels = NULL,
                              x_map_values = NULL,
                              stack_breaks = NULL,
                              stack_bin_labels = NULL,
                              stack_map_values = NULL,
                              horizontal = FALSE,
                              weight_var = NULL) {

  # INPUT VALIDATION
  if (!is.data.frame(data)) {
    stop("Input 'data' must be a data frame.", call. = FALSE)
  }
  if (missing(x_var) || is.null(x_var)) {
    dashboardr:::.stop_with_hint("x_var", example = "create_stackedbar(data, x_var = \"question\", stack_var = \"response\")")
  }
  if (missing(stack_var) || is.null(stack_var)) {
    dashboardr:::.stop_with_hint("stack_var", example = "create_stackedbar(data, x_var = \"question\", stack_var = \"response\")")
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
        dplyr::mutate(!!rlang::sym(x_var) := haven::as_factor(!!rlang::sym(x_var), levels = "labels"))
      message(paste0("Note: Column '", x_var, "' was 'haven_labelled' and converted to factor (levels = values)."))
    }
    if (inherits(plot_data_temp[[stack_var]], "haven_labelled")) {
      plot_data_temp <- plot_data_temp |>

        dplyr::mutate(!!rlang::sym(stack_var) := haven::as_factor(!!rlang::sym(stack_var), levels = "labels"))
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

  # FILTER OUT NAs if include_na = FALSE
  if (!include_na) {
    plot_data_temp <- plot_data_temp |>
      dplyr::filter(
        !is.na(!!rlang::sym(x_var_for_plot)) &
          !is.na(!!rlang::sym(stack_var_for_plot))
      )
  }

  # CREATE FACTORS using helper function
  plot_data <- plot_data_temp |>
    dplyr::mutate(
      .x_var_col = handle_na_for_plotting(
        data = plot_data_temp,
        var_name = x_var_for_plot,
        include_na = include_na,
        na_label = na_label_x,
        custom_order = x_order
      ),
      .stack_var_col = handle_na_for_plotting(
        data = plot_data_temp,
        var_name = stack_var_for_plot,
        include_na = include_na,
        na_label = na_label_stack,
        custom_order = stack_order
      )
    )

  # AGGREGATION
  if (is.null(y_var)) {
    plot_data <- plot_data |>
      dplyr::count(.x_var_col, .stack_var_col, name = "n") |>
      dplyr::ungroup()
  } else {
    plot_data <- plot_data |>
      dplyr::rename(n = !!rlang::sym(y_var))
  }

  # HIGHCHARTER
  # Determine chart type based on horizontal parameter
  chart_type <- if (horizontal) "bar" else "column"

  hchart_obj <- highcharter::hchart(
    object = plot_data,
    type = chart_type,
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
  stacking_type_hc <- if (stacked_type == "percent") "percent" else "counts"

  # Use appropriate series type for plotOptions (bar or column)
  series_type <- if (horizontal) "bar" else "column"

  plot_options <- list()
  plot_options[[series_type]] <- list(
      stacking = stacking_type_hc,
      dataLabels = list(
        enabled = TRUE,
        format = data_label_format, # Show percentage or count
        style = list(textOutline = "none", fontSize = "10px")
    )
  )

  hchart_obj <- do.call(highcharter::hc_plotOptions, c(list(hchart_obj), plot_options))

  # Legend
  # Stack label logic for legend:
  # Allow stack_label to be NULL, NA, FALSE, or "" to hide the title
  if (is.null(stack_label) || (length(stack_label) == 1 && (is.na(stack_label) || isFALSE(stack_label) || stack_label == ""))) {
    # Hide legend title
    hchart_obj <- highcharter::hc_legend(hchart_obj, title = list(text = NULL))
    } else {
    # Use custom label
    hchart_obj <- highcharter::hc_legend(hchart_obj, title = list(text = stack_label))
    }

  # Reverse legend order for horizontal charts to match visual stacking order
  if (horizontal) {
    hchart_obj <- highcharter::hc_legend(hchart_obj, reversed = TRUE)
  }

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


