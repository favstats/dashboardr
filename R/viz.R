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
#'#' @details This function performs the following steps
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
#'   \item **Chart Customization:** Titles, subtitles, axis labels, stacking type (normal vs. percent), data labels, legend titles, tooltips, and custom color palettes are applied based on the function's arguments.
#'   \item **Return Value:** The function returns a `highcharter` plot object, which can be printed directly to display the interactive chart.
#' }
#'
#'
#' @param data A data frame containing the raw survey data (e.g., one row per respondent).
#' @param x_var The name of the column to be plotted on the X-axis (as a string).
#'              This typically represents a demographic variable or a question.
#' @param stack_var The name of the column whose unique values will define the
#'                stacks within each bar (as a string). This is often a
#'                Likert scale, an agreement level, or another categorical response.
#' @param title Optional. The main title of the chart (as a string).
#' @param subtitle Optional. A subtitle for the chart (as a string).
#' @param x_label Optional. The label for the X-axis (as a string). Defaults
#'                to `x_var` or `x_var (Binned)`.
#' @param y_label Optional. The label for the Y-axis (as a string). Defaults
#'                to "Number of Respondents" or "Percentage of Respondents".
#' @param stack_label Optional. The title for the stack legend (as a string).
#'                   Defaults to `stack_var` or `stack_var (Binned)`.
#' @param stacked_type Optional. The type of stacking. Can be "normal" (counts)
#'                   or "percent" (100% stacked). Defaults to "normal".
#' @param tooltip_prefix Optional. A string to prepend to values in tooltips.
#' @param tooltip_suffix Optional. A string to append to values in tooltips.
#' @param color_palette Optional. A character vector of colors to use for the
#'                    stacks. If NULL, highcharter's default palette is used.
#'                    Consider ordering colors to match `stack_order`.
#' @param stack_order Optional. A character vector specifying the desired order
#'                    of the `stack_var` levels. This is crucial for ordinal
#'                    scales (e.g., Likert 1-7). If NULL, default factor order
#'                    or alphabetical will be used. Levels not found in data
#'                    will be ignored.
#' @param x_order Optional. A character vector specifying the desired order
#'                    of the `x_var` levels. If NULL, default factor order
#'                    or alphabetical will be used.
#' @param include_na Logical. If TRUE, explicit "(NA)" categories will be shown
#'                   in counts for `x_var` and `stack_var`. If FALSE (default),
#'                   rows with NA in `x_var` or `stack_var` are dropped.
#' @param x_breaks Optional. A numeric vector of cut points for `x_var` if
#'                 it is a continuous variable and you want to bin it.
#'                 e.g., `c(16, 24, 33, 42, 51, 60, Inf)`.
#' @param x_bin_labels Optional. A character vector of labels for the bins
#'                     created by `x_breaks`. Must be one less than the number
#'                     of breaks (or same if Inf is last break).
#' @param x_map_values Optional. A named list (e.g., `list("1" = "Female", "2" = "Male")`)
#'                     to rename values within `x_var` for display. Original values
#'                     should be names, new labels should be values.
#' @param stack_breaks Optional. A numeric vector of cut points for `stack_var` if
#'                     it is a continuous variable and you want to bin it.
#' @param stack_bin_labels Optional. A character vector of labels for the bins
#'                         created by `stack_breaks`. Must be one less than the number
#'                         of breaks (or same if Inf is last break).
#' @param stack_map_values Optional. A named list (e.g., `list("1" = "Strongly Disagree", "7" = "Strongly Agree")`)
#'                         to rename values within `stack_var` for display.
#'
#' @return An interactive `highcharter` bar chart plot object.
#'
#' @examples
#'
#' TODO: actually make sure the dummy data is available. I also removed the library loading as it typically is assumed that you have your package (and all its dependencies) loaded in when using it.
#' # Using the provided dummy data R file
#' dummy1 <- create_stackedbar(
#' data = survey_data,
#' x_var = "satisfaction_likert",
#' stack_var = "socioeconomic_status",
#' title = "Satisfaction by socioeconomic status",
#' subtitle = "",
#' x_label = "Satisfaction with treatment",
#' y_label = "Total responses",
#' stack_label = "SE status",
#' stacked_type = "normal",
#' include_na = TRUE
#' )
#' print(dummy1)
#'
#' # Example 2: Using more complex data + binning
#' # Goal: Show the proportional distribution of familiarity with chatbots across different age groups.
#' # We are going to bin the stacked variable (age)
#' Note: we need to define mappings and orders in the environment
#' familiarity_mapping <- list(
#'  "1" = "Not at all familiar with", "2" = "unfamiliar", "3" = "Slightly unfamiliar",
#'  "4" = "Neutral", "5" = "Slightly familiar", "6" = "Familiar", "7" = "Very familiar with"
#'  )
#' familiarity_order <- c(
#'  "Not at all familiar with", "unfamiliar", "Slightly unfamiliar",
#'  "Neutral", "Slightly familiar", "Familiar", "Very familiar with"
#'  )

#' # Define breaks, bin labels, and order for the stack_var
#' age_numeric_breaks <- c(-Inf, 25, 35, 45, 55, 65, Inf) # Define your income ranges
#' age_bins <- c("Under 25", "25 to 34", "35 to 44", "45 to 54", "55 to 64", "65+") # Custom labels for these ranges
#' age_order <- age_bins # Order should follow the labels


#' # Call the function
#' algosoc_kai5 <- create_stackedbar(
#'  data = algosoc,
#'  x_var = "KAI5", # X-axis will be familiarity with chatbots
#'  stack_var = "leeftijd",   # Age to be stacked and binned
#'  title = "Familiarity with chatbots",
#'  subtitle = "Age is binned into categories and stacked",
#'  x_label = "Familiarity",
#'  y_label = "Number of Respondents",
#'  stack_label = "Age",
#'  stacked_type = "normal",
#'  # Arguments for the X-axis (familiarity with chatbots)
#'  x_map_values = familiarity_mapping,
#'  x_order = familiarity_order,
#'  # Arguments for the stacked variable (age)
#'  stack_breaks = age_numeric_breaks,         # Provide the numeric cut points for stack_var
#'  stack_bin_labels = age_bins, # Provide custom labels for the stack_var bins
#'  stack_order = age_order           # Order the stacks by these custom labels
#'  )

#' # Display the plot
#' algosoc_kai5

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
                              stacked_type = c("normal", "percent"),
                              tooltip_prefix = "",
                              tooltip_suffix = "",
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
        .stack_var_col = factor(.stack_var_col, levels = final_stack_order, ordered = is.ordered(.stack_var_col))
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
        .x_var_col = factor(.x_var_col, levels = final_x_order, ordered = is.ordered(.x_var_col))
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
  hchart_obj <- highcharter::hc_tooltip(
    hchart_obj,
    formatter = highcharter::JS(
      paste0(
        "function() {
          let value = this.y;
          let total = this.point.stackTotal;
          let percentage = (value / total * 100).toFixed(1);

          let tooltip_text = '<b>' + this.x + '</b><br/>' +
                             this.series.name + ': ' + \"", tooltip_prefix, "\" + value + \"", tooltip_suffix, "\" + '<br/>';

          if ('", stacked_type, "' === 'normal') {
            tooltip_text += 'Total: ' + total;
          } else if ('", stacked_type, "' === 'percent') {
            tooltip_text += 'Percentage: ' + percentage + '%';
          }

          return tooltip_text;
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
