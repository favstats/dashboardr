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
#' @param na_label Optional string. Custom label for NA values. Defaults to "(Missing)".
#' @param color Optional string or vector of colors for the bars.
#' @param x_map_values Optional named list to recode raw `x_var` values
#'   before binning.
#' @param x_order Optional character vector to order the factor levels
#'   of the binned variable.
#' @param include_na Logical. If TRUE, treats NA as explicit category.
#' @param weight_var Optional string. Name of a weight variable to use for
#'   weighted aggregation. When provided, counts are computed as the sum of
#'   weights instead of simple counts.
#'
#' @return A `highcharter` histogram (column) plot object.
#'
#' @examples
#'
#' #We will work with data from the GSS. The GSS dataset (`gssr`) is a dependency of
#' #our `dashboardr` package.
#'
#' #Filter to recent years and select relevant variables
#' #TODO: some of the examples look off for example plot 4 and 5
#' gss_recent <- gss_all %>%
#'   filter(year >= 2010) %>%
#'   select(age, degree, happy, sex, race, year)
#'
#' # Example 1: Basic histogram of age distribution
#' plot1 <- create_histogram(
#'   data = gss_recent,
#'   x_var = "age",
#'   title = "Age Distribution in GSS Data (2010+)",
#'   subtitle = "General Social Survey respondents",
#'   x_label = "Age (years)",
#'   y_label = "Number of Respondents",
#'   bins = 15,
#'   color = "hotpink"
#' )
#' plot1
#'
#' # Example 2: Education levels with custom mapping and ordering
#' # First check the unique values
#' # unique(gss_recent$degree) # "Lt High School", "High School", "Junior College", "Bachelor", "Graduate"
#'
#' education_order <- c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate")
#'
#' plot2 <- create_histogram(
#'   data = gss_recent,
#'   x_var = "degree",
#'   title = "Educational Attainment Distribution",
#'   subtitle = "GSS respondents 2010-present",
#'   x_label = "Highest Degree Completed",
#'   y_label = "Count",
#'   histogram_type = "count",
#'   x_order = education_order,
#'   include_na = TRUE,
#' )
#' plot2
#'
#' # Example 3: Happiness levels as percentages with custom labels
#' happiness_map <- list(
#'   "Very Happy" = "Very Happy!",
#'   "Pretty Happy" = "Pretty Happy",
#'   "Not Too Happy" = "Not Too Happy :|"
#' )
#'
#' plot3 <- create_histogram(
#'   data = gss_recent,
#'   x_var = "happy",
#'   title = "Self-Reported Happiness Levels",
#'   subtitle = "Percentage distribution among GSS respondents",
#'   x_label = "Happiness Level",
#'   y_label = "Percentage of Respondents",
#'   histogram_type = "percent",
#'   x_map_values = happiness_map,
#'   tooltip_suffix = "%",
#'   include_na = TRUE,
#'   na_label = "No Response",
#' )
#' plot3
#'
#' # Example 4: Age binning with custom breaks and labels
#' age_breaks <- c(18, 30, 45, 60, 75, Inf)
#' age_labels <- c("18-29", "30-44", "45-59", "60-74", "75+")
#'
#' plot4 <- create_histogram(
#'   data = gss_recent,
#'   x_var = "age",
#'   title = "Age Groups in GSS Sample",
#'   subtitle = "Custom age categories",
#'   x_label = "Age Group",
#'   y_label = "Number of Respondents",
#'   bin_breaks = age_breaks,
#'   bin_labels = age_labels,
#'   tooltip_prefix = "Count: ",
#'   x_tooltip_suffix = " years old",
#'   color = "seagreen1"
#' )
#' plot4
#'
#' # Example 5: Using pre-aggregated data
#' # Create aggregated data first
#' race_counts <- gss_recent %>%
#'   count(race, name = "respondent_count") %>%
#'   filter(!is.na(race))
#'
#' plot5 <- create_histogram(
#'   data = race_counts,
#'   x_var = "race",
#'   y_var = "respondent_count",  # Use pre-computed counts
#'   title = "Racial Distribution in GSS Sample",
#'   subtitle = "Based on pre-aggregated data",
#'   x_label = "Race/Ethnicity",
#'   y_label = "Number of Respondents",
#' )
#' plot5
#'
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
#'    \item **Binning:**
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
create_histogram <- function(data,
                             x_var,
                             y_var = NULL,
                             title = NULL,
                             subtitle = NULL,
                             x_label = NULL,
                             y_label = NULL,
                             histogram_type = c("count", "percent"),
                             tooltip_prefix = "",
                             tooltip_suffix = "",
                             x_tooltip_suffix = "",
                             bins = NULL,
                             bin_breaks = NULL,
                             bin_labels = NULL,
                             include_na = FALSE,
                             na_label = "(Missing)",
                             color = NULL,
                             x_map_values = NULL,
                             x_order = NULL,
                             weight_var = NULL) {
  histogram_type <- match.arg(histogram_type)

  # INPUT VALIDATION
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  if (missing(x_var) || is.null(x_var)) {
    dashboardr:::.stop_with_hint("x_var", example = "create_histogram(data, x_var = \"age\")")
  }
  if (!x_var %in% names(data)) {
    stop(paste0("Column '", x_var, "' not found in data."), call. = FALSE)
  }

  # DATA PREP
  df <- tibble::as_tibble(data)
  # Recode haven_labelled if present
  if (inherits(df[[x_var]], "haven_labelled")) {
    df <- df |>
      dplyr::mutate(
        # strip labels to numeric
        !!rlang::sym(x_var) := as.numeric(unclass(!!rlang::sym(x_var)))
      )
  }
  # Map raw values if requested (before binning)
  if (!is.null(x_map_values)) {
    if (!is.list(x_map_values) || is.null(names(x_map_values))) {
      stop("`x_map_values` must be a named list.", call. = FALSE)
    }
    df <- df |>
      dplyr::mutate(
        !!rlang::sym(x_var) := dplyr::recode(
          as.character(!!rlang::sym(x_var)),
          !!!x_map_values
        )
      )
    warning("Applied x_map_values before binning.", call. = FALSE)
  }
  # BINNING
  # Compute breaks if only bins provided
  if (is.null(bin_breaks) && !is.null(bins)) {
    if (!is.numeric(df[[x_var]])) {
      stop("`x_var` must be numeric to compute `bins`.", call. = FALSE)
    }
    bin_breaks <- hist(
      df[[x_var]],
      plot = FALSE,
      breaks = bins
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
             call. = FALSE
        )
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
  # Factor & explicit NA handling
  df <- df |>
    dplyr::mutate(
      .x_factor = if (include_na) {
        # Convert to character first to handle NAs explicitly
        temp_var <- as.character(!!rlang::sym(x_plot_var))
        # Replace NA with custom label
        temp_var[is.na(temp_var)] <- na_label
        # Convert to factor
        factor(temp_var)
      } else {
        # Standard factor conversion, NAs will be dropped during counting
        factor(!!rlang::sym(x_plot_var))
      }
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

  # Store the levels of the factor BEFORE aggregation for later use in complete()
  # This ensures all potential categories are present
  factor_levels_for_completion <- levels(df$.x_factor)

  # AGGREGATION
  if (is.null(y_var)) {
    if (!is.null(weight_var)) {
      # Use weights for aggregation
      if (!weight_var %in% names(df)) {
        stop("`weight_var` '", weight_var, "' not found in data.", call. = FALSE)
      }
      df <- df |>
        dplyr::group_by(.x_factor, .drop = FALSE) |>
        dplyr::summarise(n = sum(!!rlang::sym(weight_var), na.rm = TRUE), .groups = "drop") |>
        # IMPORTANT: Use complete to ensure all factor levels are present, even with 0 count
        tidyr::complete(.x_factor = factor(factor_levels_for_completion,
                                           levels = factor_levels_for_completion),
                        fill = list(n = 0))
    } else {
      # Standard counting without weights
      df <- df |>
        dplyr::count(.x_factor, name = "n") |>
        # IMPORTANT: Use complete to ensure all factor levels are present, even with 0 count
        tidyr::complete(.x_factor = factor(factor_levels_for_completion,
                                           levels = factor_levels_for_completion),
                        fill = list(n = 0))
    }
  } else {
    if (!y_var %in% names(df)) {
      stop("`y_var` not found in data.", call. = FALSE)
    }
    df <- df |>
      dplyr::rename(n = !!rlang::sym(y_var)) |>
      # Ensure all factor levels are present even when using pre-computed y_var
      tidyr::complete(.x_factor = factor(factor_levels_for_completion,
                                         levels = factor_levels_for_completion),
                      fill = list(n = 0))
  }

  # Re-apply factor levels after complete() to maintain order and structure
  df <- df |>
    dplyr::mutate(.x_factor = factor(.x_factor, levels = factor_levels_for_completion))

  # Extract data for direct series addition
  # This creates a named vector or list where names are categories and values are counts
  series_data <- setNames(df$n, as.character(df$.x_factor))

  # HIGHCHARTER
  hc <- highcharter::highchart()
  # Titles
  if (!is.null(title)) hc <- hc %>% highcharter::hc_title(text = title)
  if (!is.null(subtitle)) hc <- hc %>% highcharter::hc_subtitle(text = subtitle)

  # ─── Axis labels & categories ─────────────────────────────────────────────
  final_x <- x_label %||% x_var
  default_y <- if (histogram_type == "percent") "Percentage" else "Count"
  final_y <- y_label %||% default_y

  # Define stacking and format based on histogram_type
  stacking <- if (histogram_type == "percent") "percent" else NULL
  fmt <- if (histogram_type == "percent") "{point.percentage:.1f}%" else "{y}"

  # Pass the categories to the x-axis
  hc <- hc %>%
    highcharter::hc_xAxis(
      categories = levels(df$.x_factor), # Still use the factor levels for categories
      title = list(text = final_x)
    ) %>%
    highcharter::hc_yAxis(
      title = list(text = final_y)
    )

  # Manually add the series data as a column type
  hc <- hc %>%
    highcharter::hc_add_series(
      name = "Count", # Or whatever makes sense for the series legend
      data = as.numeric(series_data), # Convert to numeric vector
      type = "column"
    ) %>%
    # Apply plot options globally for column charts
    highcharter::hc_plotOptions(
      column = list(
        stacking = stacking,
        dataLabels = list(
          enabled = TRUE,
          format = fmt,
          style = list(textOutline = "none")
        ),
        pointPadding = 0,
        groupPadding = 0,
        borderWidth = 0,
        pointWidth = 50, # Explicitly set bar width
        pointPlacement = "on", # Ensures bars are centered on category ticks
        maxPointWidth = 80
      )
    )

  # ─── TOOLTIP ───────────────────────────────────────────────────────────────
  pre <- if (tooltip_prefix == "") "" else tooltip_prefix
  suf <- if (tooltip_suffix == "") "" else tooltip_suffix
  xsuf <- if (x_tooltip_suffix == "") "" else x_tooltip_suffix

  # Corrected sprintf format string and arguments
  tooltip_fn <- sprintf(
    "function() {
       // here we pull the label directly
       var cat = this.point.category;
       var val = %s;
       return '<b>' + cat + '%s</b><br/>' +
              '%s' + val + '%s';
     }",
    if (histogram_type == "percent") {
      "this.percentage.toFixed(1) + '%'"
    } else {
      "this.y"
    },
    xsuf, # Fills the first %s for cat + '%s' (x_tooltip_suffix)
    pre,  # Fills the second %s for '%s' + val (tooltip_prefix)
    suf   # Fills the third %s for val + '%s' (tooltip_suffix)
  )

  hc <- hc %>% highcharter::hc_tooltip(formatter = highcharter::JS(tooltip_fn))

  # Color palette (applied to the series)
  if (!is.null(color)) hc <- hc %>% highcharter::hc_colors(color)

  return(hc)
}
