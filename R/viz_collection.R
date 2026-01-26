# =================================================================
# viz_collection
# =================================================================


#' Create a new visualization collection
#'
#' Initializes an empty collection for building up multiple visualizations
#' using the piping workflow. Optionally accepts custom display labels for
#' tab groups and default parameters that apply to all visualizations.
#'
#' @param data Optional data frame to use for all visualizations in this collection.
#'   This data will be used by add_viz() calls and can be used with preview().
#'   Can also be passed to add_page() which will use this as fallback if no
#'   page-level data is provided.
#' @param tabgroup_labels Named vector/list mapping tabgroup IDs to display names
#' @param ... Default parameters to apply to all subsequent add_viz() calls.
#'   Any parameter specified in add_viz() will override the default.
#'   Useful for setting common parameters like type, color_palette, stacked_type, etc.
#' @return A viz_collection object
#' @export
#' @examples
#' \dontrun{
#' # Create viz collection with data for preview
#' vizzes <- create_viz(data = mtcars) %>%
#'   add_viz(type = "histogram", x_var = "mpg", title = "MPG Distribution") %>%
#'   preview()
#'
#' # Create viz collection with custom group labels
#' vizzes <- create_viz(tabgroup_labels = c("demo" = "Demographics",
#'                                           "pol" = "Political Views"))
#'
#' # Create viz collection with shared defaults
#' vizzes <- create_viz(
#'   type = "stackedbars",
#'   stacked_type = "percent",
#'   color_palette = c("#d7191c", "#fdae61", "#2b83ba"),
#'   horizontal = TRUE,
#'   x_label = ""
#' ) %>%
#'   add_viz(title = "Wave 1", filter = ~ wave == 1) %>%  # Uses defaults
#'   add_viz(title = "Wave 2", filter = ~ wave == 2, horizontal = FALSE)  # Overrides horizontal
#' }
create_viz <- function(data = NULL, tabgroup_labels = NULL, ...) {
  defaults <- list(...)

  structure(list(
    items = list(),
    tabgroup_labels = tabgroup_labels,
    defaults = defaults,
    data = data
  ), class = c("content_collection", "viz_collection"))
}


#' Combine Visualization Collections with + Operator
#'
#' S3 method that allows combining two viz_collection objects using the `+` operator.
#' This is a convenient shorthand for \code{\link{combine_content}}.
#' Preserves all attributes including lazy loading settings.
#'
#' @param e1 First viz_collection object (left operand).
#' @param e2 Second viz_collection object (right operand).
#'
#' @return A new viz_collection containing all visualizations from both collections,
#'   with merged tabgroup labels and renumbered insertion indices.
#'
#' @details
#' The `+` operator provides an intuitive way to combine visualization collections:
#' \itemize{
#'   \item All visualizations from both collections are merged
#'   \item Tabgroup labels are combined (e2 labels take precedence for duplicates)
#'   \item Insertion indices are renumbered to maintain proper ordering
#'   \item All attributes (lazy loading, etc.) are preserved
#' }
#'
#' @seealso \code{\link{combine_content}} for the underlying function.
#'
#' @method + viz_collection
#' @export
#'
#' @examples
#' \dontrun{
#' # Create two separate visualization collections
#' viz1 <- create_viz() %>%
#'   add_viz(type = "histogram", x_var = "age", title = "Age Distribution")
#'
#' viz2 <- create_viz() %>%
#'   add_viz(type = "histogram", x_var = "income", title = "Income Distribution")
#'
#' # Combine using + operator
#' combined <- viz1 + viz2
#'
#' # Equivalent to:
#' combined <- combine_content(viz1, viz2)
#' }
`+.viz_collection` <- function(e1, e2) {
  # Validate inputs
  if (!is_content(e1)) {
    stop("Left operand must be a content collection")
  }
  if (missing(e2) || !is_content(e2)) {
    stop("Right operand must be a content collection")
  }

  # Delegate to combine_content() which handles all attribute preservation
  combine_content(e1, e2)
}

#' Combine Content Collections with + Operator
#'
#' S3 method for combining content_collection objects using `+`.
#' Preserves all attributes including lazy loading settings.
#'
#' @param e1 First content_collection
#' @param e2 Second content_collection
#' @return Combined content_collection
#' @method + content_collection
#' @export
`+.content_collection` <- function(e1, e2) {
  if (!is_content(e1)) {
    stop("Left operand must be a content collection")
  }
  if (missing(e2) || !is_content(e2)) {
    stop("Right operand must be a content collection")
  }

  combine_content(e1, e2)
}
#' Combine content collections (universal combiner)
#'
#' Universal function to combine content_collection or viz_collection objects.
#' Preserves all content types (visualizations, pagination markers, text blocks)
#' and collection-level attributes (lazy loading, etc.).
#'
#' @param ... One or more content_collection or viz_collection objects
#' @return Combined content_collection
#' @export
#' @examples
#' \dontrun{
#' # Combine multiple collections
#' all_viz <- demo_viz %>%
#'   combine_content(analysis_viz) %>%
#'   combine_content(summary_viz)
#'
#' # With pagination
#' paginated <- section1_viz %>%
#'   combine_content(section2_viz) %>%
#'   add_pagination() %>%
#'   combine_content(section3_viz)
#'
#' # Using + operator
#' combined <- viz1 + viz2 + viz3
#' }
combine_content <- function(...) {
  collections <- list(...)

  if (length(collections) == 0) {
    return(create_viz())
  }

  # Validate all are content collections
  for (i in seq_along(collections)) {
    if (!is_content(collections[[i]])) {
      stop("All arguments must be content collections")
    }
  }

  # Combine all items and renumber insertion indices
  combined_items <- list()
  combined_labels <- list()
  combined_defaults <- list()
  combined_attrs <- list()  # For extra attributes like lazy loading

  for (col in collections) {
    # Renumber indices to maintain global order
    offset <- length(combined_items)
    for (i in seq_along(col$items)) {
      item <- col$items[[i]]
      # Remove old insertion index and add new one
      item[[".insertion_index"]] <- NULL
      item[[".insertion_index"]] <- offset + i
      combined_items[[length(combined_items) + 1]] <- item
    }

    # Merge labels (later collections override)
    if (!is.null(col$tabgroup_labels)) {
      for (label_name in names(col$tabgroup_labels)) {
        combined_labels[[label_name]] <- col$tabgroup_labels[[label_name]]
      }
    }

    # Merge defaults (later collections override)
    if (!is.null(col$defaults) && length(col$defaults) > 0) {
      for (default_name in names(col$defaults)) {
        combined_defaults[[default_name]] <- col$defaults[[default_name]]
      }
    }

    # Merge any extra attributes (lazy loading, etc.) - later collections override
    # Only override if the value is not NULL (to preserve data from earlier collections)
    standard_names <- c("items", "tabgroup_labels", "defaults", "class")
    extra_attrs <- setdiff(names(col), standard_names)
    for (attr_name in extra_attrs) {
      if (!is.null(col[[attr_name]])) {
        combined_attrs[[attr_name]] <- col[[attr_name]]
      }
    }
  }

  # Sort by insertion index to maintain order
  if (length(combined_items) > 0) {
    sort_order <- order(sapply(combined_items, function(x) x$.insertion_index %||% Inf))
    combined_items <- combined_items[sort_order]
  }

  # Build result with all attributes
  result <- list(
    items = combined_items,
    tabgroup_labels = if (length(combined_labels) > 0) combined_labels else NULL,
    defaults = if (length(combined_defaults) > 0) combined_defaults else list()
  )

  # Add extra attributes
  for (attr_name in names(combined_attrs)) {
    result[[attr_name]] <- combined_attrs[[attr_name]]
  }

  structure(result, class = c("content_collection", "viz_collection"))
}

#' Combine visualization collections
#'
#' @description
#' This function has been superseded by [combine_content()]. It still works
#' but we recommend using `combine_content()` for new code as it handles
#' all content types and attributes more reliably.
#'
#' @param ... One or more viz_collection objects to combine
#' @return A combined viz_collection
#' @export
#' @examples
#' \dontrun{
#' viz1 <- create_viz() %>% add_viz(type = "histogram", x_var = "age")
#' viz2 <- create_viz() %>% add_viz(type = "histogram", x_var = "income")
#' combined <- combine_viz(viz1, viz2)  # Combines both
#' }
combine_viz <- function(...) {
  combine_content(...)
}

#' Sort visualizations by tabgroup hierarchy
#'
#' Internal helper to ensure nested tabs appear after their parent tabs.
#' Groups visualizations so that children appear immediately after their parent
#' at the same hierarchy level. For example:
#' - "sis" (Wave 1)
#' - "sis/age/item1" (Wave 1) - nested under first "sis"
#' - "sis" (Wave 2)
#' - "sis/age/item1" (Wave 2) - nested under second "sis"
#'
#' @param viz_list List of visualization specifications
#' @return Sorted list of visualizations


#' Parse tabgroup into normalized hierarchy
#'
#' Internal helper to parse tabgroup parameter from various formats into a
#' standardized character vector representing the hierarchy.
#'
#' @param tabgroup Can be:
#'   - NULL: no tabgroup
#'   - Character string: "level1" or "level1/level2/level3" (slash notation)
#'   - Named numeric vector: c("1" = "level1", "2" = "level2", "3" = "level3")
#' @return Character vector of hierarchy levels, or NULL
#' @noRd
.parse_tabgroup <- function(tabgroup) {
  if (is.null(tabgroup)) {
    return(NULL)
  }

  # Case 1: Character string - check for slash notation
  if (is.character(tabgroup)) {
    if (length(tabgroup) == 1) {
      # Single string - split by "/" if present
      if (grepl("/", tabgroup, fixed = TRUE)) {
        # Slash notation: "demographics/details/regional"
        levels <- strsplit(tabgroup, "/", fixed = TRUE)[[1]]
        levels <- trimws(levels)  # Remove whitespace
        levels <- levels[nzchar(levels)]  # Remove empty strings
        if (length(levels) == 0) {
          stop("tabgroup cannot be empty after parsing")
        }
        return(levels)
      } else {
        # Simple string: "demographics"
        return(tabgroup)
      }
    } else if (length(tabgroup) > 1) {
      # Named or unnamed vector of strings
      if (!is.null(names(tabgroup))) {
        # Named vector - check if names are numeric strings like "1", "2", "3"
        if (all(grepl("^[0-9]+$", names(tabgroup)))) {
          # Named numeric vector: c("1" = "demographics", "2" = "details")
          # Sort by numeric names
          sorted_idx <- order(as.integer(names(tabgroup)))
          return(as.character(tabgroup[sorted_idx]))
        }
      }
      # Fallback: use as-is (unnamed vector)
      return(as.character(tabgroup))
    }
  }

  stop("tabgroup must be either:\n",
       "  - A string: 'demographics' or 'demographics/details/regional'\n",
       "  - A named numeric vector: c('1' = 'demographics', '2' = 'details')")
}

#' Add a visualization to the collection
#'
#' Adds a single visualization specification to an existing collection.
#' Visualizations with the same tabgroup value will be organized into
#' tabs on the generated page. Supports nested tabsets through hierarchy notation.
#'
#' @param viz_collection A viz_collection object
#' @param type Visualization type: "stackedbar", "heatmap", "histogram", "timeline", "scatter", "bar"
#' @param ... Additional parameters passed to the visualization function
#' @param tabgroup Optional group ID for organizing related visualizations. Supports:
#'   - Simple string: `"demographics"` for a single tab group
#'   - Slash notation: `"demographics/details"` or `"demographics/details/regional"` for nested tabs
#'   - Named numeric vector: `c("1" = "demographics", "2" = "details", "3" = "regional")` for explicit hierarchy
#' @param title Display title for the visualization (shown above the chart)
#' @param title_tabset Optional tab label. If NULL, uses `title` for the tab label.
#'   Use this when you want a short tab name but a longer, descriptive visualization title.
#' @param text Optional markdown text to display above the visualization
#' @param icon Optional iconify icon shortcode for the visualization
#' @param text_position Position of text relative to visualization ("above" or "below")
#' @param height Optional height in pixels for highcharter visualizations (numeric value)
#' @param filter Optional filter expression to subset data for this visualization. Use formula syntax:
#'   `~ condition`. Examples: `~ wave == 1`, `~ age > 18`, `~ wave %in% c(1, 2, 3)`
#' @param data Optional dataset name when using multiple datasets. Can be:
#'   - NULL: Uses default dataset (or only dataset if single)
#'   - String: Name of dataset from named list (e.g., "survey", "demographics")
#' @return The updated viz_collection object
#' @export
#' @examples
#' \dontrun{
#' # Simple tabgroup
#' page1_viz <- create_viz() %>%
#'   add_viz(type = "stackedbar", x_var = "education", stack_var = "gender",
#'           title = "Education by Gender", tabgroup = "demographics")
#'
#' # Nested tabgroups using slash notation
#' page2_viz <- create_viz() %>%
#'   add_viz(type = "stackedbar", title = "Overview",
#'           tabgroup = "demographics") %>%
#'   add_viz(type = "stackedbar", title = "Details",
#'           tabgroup = "demographics/details")
#'
#' # Nested tabgroups using named numeric vector
#' page3_viz <- create_viz() %>%
#'   add_viz(type = "stackedbar", title = "Regional Details",
#'           tabgroup = c("1" = "demographics", "2" = "details", "3" = "regional"))
#'
#' # Filter data per visualization
#' page4_viz <- create_viz() %>%
#'   add_viz(type = "histogram", x_var = "response",
#'           title = "Wave 1", filter = ~ wave == 1) %>%
#'   add_viz(type = "histogram", x_var = "response",
#'           title = "Wave 2", filter = ~ wave == 2) %>%
#'   add_viz(type = "histogram", x_var = "response",
#'           title = "All Waves", filter = ~ wave %in% c(1, 2, 3))
#'
#' # Multiple datasets
#' page5_viz <- create_viz() %>%
#'   add_viz(type = "histogram", x_var = "age", data = "demographics") %>%
#'   add_viz(type = "histogram", x_var = "response", data = "survey") %>%
#'   add_viz(type = "histogram", x_var = "outcome", data = "outcomes")
#'
#' # Separate tab label from visualization title
#' page6_viz <- create_viz() %>%
#'   add_viz(
#'     type = "histogram",
#'     x_var = "age",
#'     tabgroup = "demographics",
#'     title_tabset = "Age",  # Short tab label
#'     title = "Age Distribution of Survey Respondents by Gender and Region"  # Long viz title
#'   )
#' }


#' Sort visualizations by tabgroup hierarchy
#'
#' Internal helper to ensure nested tabs appear after their parent tabs.
#' Groups visualizations so that children appear immediately after their parent
#' at the same hierarchy level. For example:
#' - "sis" (Wave 1)
#' - "sis/age/item1" (Wave 1) - nested under first "sis"
#' - "sis" (Wave 2)
#' - "sis/age/item1" (Wave 2) - nested under second "sis"
#'
#' @param viz_list List of visualization specifications
#' @return Sorted list of visualizations
#' @noRd
.sort_viz_by_tabgroup_hierarchy <- function(viz_list) {
  if (length(viz_list) == 0) {
    return(viz_list)
  }

  # SIMPLIFIED APPROACH: Just sort by insertion_index!
  # The hierarchy builder will handle grouping and nesting correctly.
  # We don't need to pre-sort by tabgroup hierarchy here.

  # Extract insertion indices (items ARE the specs with type="viz" mixed in)
  sort_order <- order(sapply(viz_list, function(v) v$.insertion_index %||% Inf))

  # Return sorted by insertion index
  viz_list[sort_order]
}

#' Parse tabgroup into normalized hierarchy
#'
#' Internal helper to parse tabgroup parameter from various formats into a
#' standardized character vector representing the hierarchy.
#'
#' @param tabgroup Can be:
#'   - NULL: no tabgroup
#'   - Character string: "level1" or "level1/level2/level3" (slash notation)
#'   - Named numeric vector: c("1" = "level1", "2" = "level2", "3" = "level3")
#' @return Character vector of hierarchy levels, or NULL


#' Add a visualization to the collection
#'
#' Adds a single visualization specification to an existing collection.
#' Visualizations with the same tabgroup value will be organized into
#' tabs on the generated page. Supports nested tabsets through hierarchy notation.
#'
#' @param viz_collection A viz_collection object
#' @param type Visualization type: "stackedbar", "heatmap", "histogram", "timeline", "scatter", "bar"
#' @param ... Additional parameters passed to the visualization function
#' @param tabgroup Optional group ID for organizing related visualizations. Supports:
#'   - Simple string: `"demographics"` for a single tab group
#'   - Slash notation: `"demographics/details"` or `"demographics/details/regional"` for nested tabs
#'   - Named numeric vector: `c("1" = "demographics", "2" = "details", "3" = "regional")` for explicit hierarchy
#' @param title Display title for the visualization (shown above the chart)
#' @param title_tabset Optional tab label. If NULL, uses `title` for the tab label.
#'   Use this when you want a short tab name but a longer, descriptive visualization title.
#' @param text Optional markdown text to display above the visualization
#' @param icon Optional iconify icon shortcode for the visualization
#' @param text_position Position of text relative to visualization ("above" or "below")
#' @param height Optional height in pixels for highcharter visualizations (numeric value)
#' @param filter Optional filter expression to subset data for this visualization. Use formula syntax:
#'   `~ condition`. Examples: `~ wave == 1`, `~ age > 18`, `~ wave %in% c(1, 2, 3)`
#' @param data Optional dataset name when using multiple datasets. Can be:
#'   - NULL: Uses default dataset (or only dataset if single)
#'   - String: Name of dataset from named list (e.g., "survey", "demographics")
#' @return The updated viz_collection object
#' @export
#' @examples
#' \dontrun{
#' # Simple tabgroup
#' page1_viz <- create_viz() %>%
#'   add_viz(type = "stackedbar", x_var = "education", stack_var = "gender",
#'           title = "Education by Gender", tabgroup = "demographics")
#'
#' # Nested tabgroups using slash notation
#' page2_viz <- create_viz() %>%
#'   add_viz(type = "stackedbar", title = "Overview",
#'           tabgroup = "demographics") %>%
#'   add_viz(type = "stackedbar", title = "Details",
#'           tabgroup = "demographics/details")
#'
#' # Nested tabgroups using named numeric vector
#' page3_viz <- create_viz() %>%
#'   add_viz(type = "stackedbar", title = "Regional Details",
#'           tabgroup = c("1" = "demographics", "2" = "details", "3" = "regional"))
#'
#' # Filter data per visualization
#' page4_viz <- create_viz() %>%
#'   add_viz(type = "histogram", x_var = "response",
#'           title = "Wave 1", filter = ~ wave == 1) %>%
#'   add_viz(type = "histogram", x_var = "response",
#'           title = "Wave 2", filter = ~ wave == 2) %>%
#'   add_viz(type = "histogram", x_var = "response",
#'           title = "All Waves", filter = ~ wave %in% c(1, 2, 3))
#'
#' # Multiple datasets
#' page5_viz <- create_viz() %>%
#'   add_viz(type = "histogram", x_var = "age", data = "demographics") %>%
#'   add_viz(type = "histogram", x_var = "response", data = "survey") %>%
#'   add_viz(type = "histogram", x_var = "outcome", data = "outcomes")
#'
#' # Separate tab label from visualization title
#' page6_viz <- create_viz() %>%
#'   add_viz(
#'     type = "histogram",
#'     x_var = "age",
#'     tabgroup = "demographics",
#'     title_tabset = "Age",  # Short tab label
#'     title = "Age Distribution of Survey Respondents by Gender and Region"  # Long viz title
#'   )
#' }
add_viz <- function(x, type = NULL, ..., tabgroup = NULL, title = NULL, title_tabset = NULL, text = NULL, icon = NULL, text_position = NULL, text_before_tabset = NULL, text_after_tabset = NULL, text_before_viz = NULL, text_after_viz = NULL, height = NULL, filter = NULL, data = NULL, drop_na_vars = FALSE) {
  UseMethod("add_viz")
}

#' @export
add_viz.page_object <- function(x, type = NULL, ..., tabgroup = NULL, title = NULL, title_tabset = NULL, text = NULL, icon = NULL, text_position = NULL, text_before_tabset = NULL, text_after_tabset = NULL, text_before_viz = NULL, text_after_viz = NULL, height = NULL, filter = NULL, data = NULL, drop_na_vars = FALSE) {
  page <- x
  
  # Build viz spec by merging with page defaults
  defaults <- page$viz_defaults
  
  viz_spec <- list(
    type = "viz",
    viz_type = type %||% defaults$type %||% "bar",
    title = title,
    title_tabset = title_tabset,
    tabgroup = tabgroup,
    text = text,
    icon = icon,
    text_position = text_position,
    text_before_tabset = text_before_tabset,
    text_after_tabset = text_after_tabset,
    text_before_viz = text_before_viz,
    text_after_viz = text_after_viz,
    height = height,
    filter = filter,
    data = data,
    drop_na_vars = if (is.null(drop_na_vars) || isFALSE(drop_na_vars)) defaults$drop_na_vars else drop_na_vars,
    color_palette = defaults$color_palette,
    weight_var = defaults$weight_var
  )
  
  # Add any extra parameters from ...
  extra <- list(...)
  for (nm in names(extra)) {
    viz_spec[[nm]] <- extra[[nm]]
  }

  page$.items <- c(page$.items, list(viz_spec))
  page
}

#' @export
add_viz.default <- function(x, type = NULL, ..., tabgroup = NULL, title = NULL, title_tabset = NULL, text = NULL, icon = NULL, text_position = NULL, text_before_tabset = NULL, text_after_tabset = NULL, text_before_viz = NULL, text_after_viz = NULL, height = NULL, filter = NULL, data = NULL, drop_na_vars = FALSE) {
  viz_collection <- x
  
  # Validate first argument
  if (!is_content(viz_collection)) {
    stop("First argument must be a content collection or page_object")
  }

  # Get explicitly provided arguments (not defaults)
  call_args <- as.list(match.call())[-1]  # Remove function name
  call_args$viz_collection <- NULL  # Remove viz_collection from the list

  # Get defaults from viz_collection
  # Note: Don't use %||% as it may have unexpected behavior with lists
  if (is.null(viz_collection$defaults)) {
    defaults <- list()
  } else {
    defaults <- viz_collection$defaults
  }

  # Get additional parameters from ...
  dot_args <- list(...)

  # Merge parameters: explicitly provided > dots > defaults
  # Start with defaults
  merged_params <- defaults

  # Override with dot args
  for (name in names(dot_args)) {
    merged_params[[name]] <- dot_args[[name]]
  }

  # Override with explicitly provided named parameters
  if ("type" %in% names(call_args)) merged_params$type <- type
  if ("tabgroup" %in% names(call_args)) merged_params$tabgroup <- tabgroup
  if ("title" %in% names(call_args)) merged_params$title <- title
  if ("title_tabset" %in% names(call_args)) merged_params$title_tabset <- title_tabset
  if ("text" %in% names(call_args)) merged_params$text <- text
  if ("icon" %in% names(call_args)) merged_params$icon <- icon
  if ("text_position" %in% names(call_args)) merged_params$text_position <- text_position
  if ("text_before_tabset" %in% names(call_args)) merged_params$text_before_tabset <- text_before_tabset
  if ("text_after_tabset" %in% names(call_args)) merged_params$text_after_tabset <- text_after_tabset
  if ("text_before_viz" %in% names(call_args)) merged_params$text_before_viz <- text_before_viz
  if ("text_after_viz" %in% names(call_args)) merged_params$text_after_viz <- text_after_viz
  if ("height" %in% names(call_args)) merged_params$height <- height
  if ("filter" %in% names(call_args)) merged_params$filter <- filter
  if ("data" %in% names(call_args)) merged_params$data <- data
  if ("drop_na_vars" %in% names(call_args)) {
    merged_params$drop_na_vars <- drop_na_vars
  }

  # Extract final values from merged_params
  # NOTE: Use [[]] instead of $ to avoid partial matching (text_before_viz would match $text!)
  type <- merged_params[["type"]]
  tabgroup <- merged_params[["tabgroup"]]
  title <- merged_params[["title"]]
  title_tabset <- merged_params[["title_tabset"]]
  text <- merged_params[["text"]]
  icon <- merged_params[["icon"]]
  text_position <- merged_params[["text_position"]] %||% "above"
  text_before_tabset <- merged_params[["text_before_tabset"]]
  text_after_tabset <- merged_params[["text_after_tabset"]]
  text_before_viz <- merged_params[["text_before_viz"]]
  text_after_viz <- merged_params[["text_after_viz"]]
  height <- merged_params[["height"]]
  filter <- merged_params[["filter"]]
  data <- merged_params[["data"]]
  
  # Fall back to collection-level data if data is NULL and collection$data is a string (dataset name)
  # (String dataset names can serve as defaults for all viz items)
  if (is.null(data) && !is.null(viz_collection$data) && is.character(viz_collection$data)) {
    data <- viz_collection$data
  }
  
  # Note: Using if/else instead of %||% due to unexpected behavior with FALSE values
  drop_na_vars <- if (is.null(merged_params[["drop_na_vars"]])) FALSE else merged_params[["drop_na_vars"]]

  # Backward compatibility: map text parameter to text_before_viz or text_after_viz
  if (!is.null(text) && nzchar(text)) {
    if (text_position == "above") {
      # If text_before_viz not explicitly set, use text
      if (is.null(text_before_viz)) {
        text_before_viz <- text
      }
    } else {
      # text_position == "below"
      if (is.null(text_after_viz)) {
        text_after_viz <- text
      }
    }
  }

  # Now apply merged_params from dots to the ... parameters
  dot_args <- merged_params[!names(merged_params) %in% c("type", "tabgroup", "title", "title_tabset", "text", "icon", "text_position", "text_before_tabset", "text_after_tabset", "text_before_viz", "text_after_viz", "height", "filter", "data", "drop_na_vars")]

  # Validate supported visualization types
  supported_types <- c("map", "treemap", "stackedbar", "stackedbars", "heatmap", "histogram", "timeline", "bar", "scatter")

  # Validate type parameter
  if (is.null(type) || !is.character(type) || length(type) != 1 || nchar(type) == 0) {
    .stop_with_hint("type", supported_types, "add_viz(type = \"histogram\", x_var = \"age\")")
  }

  if (!type %in% supported_types) {
    .stop_with_suggestion("type", type, supported_types)
  }

  # Parse and validate tabgroup parameter
  tabgroup_parsed <- NULL
  if (!is.null(tabgroup)) {
    tabgroup_parsed <- tryCatch(
      .parse_tabgroup(tabgroup),
      error = function(e) {
        stop("Invalid tabgroup format: ", e$message, call. = FALSE)
      }
    )
  }

  # Validate title parameter
  if (!is.null(title)) {
    if (!is.character(title) || length(title) != 1) {
      stop("title must be a character string or NULL")
    }
  }

  # Validate text parameter (backward compatibility)
  if (!is.null(text)) {
    if (!is.character(text) || length(text) != 1) {
      stop("text must be a character string or NULL")
    }
  }

  # Validate new text positioning parameters
  if (!is.null(text_before_tabset)) {
    if (!is.character(text_before_tabset) || length(text_before_tabset) != 1) {
      stop("text_before_tabset must be a character string or NULL")
    }
  }
  if (!is.null(text_after_tabset)) {
    if (!is.character(text_after_tabset) || length(text_after_tabset) != 1) {
      stop("text_after_tabset must be a character string or NULL")
    }
  }
  if (!is.null(text_before_viz)) {
    if (!is.character(text_before_viz) || length(text_before_viz) != 1) {
      stop("text_before_viz must be a character string or NULL")
    }
  }
  if (!is.null(text_after_viz)) {
    if (!is.character(text_after_viz) || length(text_after_viz) != 1) {
      stop("text_after_viz must be a character string or NULL")
    }
  }

  # Validate icon parameter
  if (!is.null(icon)) {
    if (!is.character(icon) || length(icon) != 1) {
      stop("icon must be a character string or NULL")
    }
    # Validate icon format (should be "collection:name" or already formatted shortcode)
    if (!grepl("^[a-zA-Z0-9_-]+:[a-zA-Z0-9_-]+$", icon) &&
        !grepl("\\{\\{< iconify", icon, fixed = TRUE)) {
      warning("Icon '", icon, "' should be in format 'collection:name' (e.g., 'ph:users-three') ",
              "or a pre-formatted iconify shortcode")
    }
  }

  # Validate text_position
  if (!text_position %in% c("above", "below")) {
    stop("text_position must be either 'above' or 'below'")
  }

  # Validate height parameter
  if (!is.null(height)) {
    if (!is.numeric(height) || length(height) != 1 || height <= 0) {
      stop("height must be a positive numeric value or NULL")
    }
  }

  # Validate filter parameter
  if (!is.null(filter)) {
    if (!inherits(filter, "formula")) {
      stop("filter must be a formula (e.g., ~ wave == 1) or NULL")
    }
    if (length(filter) != 2) {
      stop("filter formula must have the form ~ condition (one-sided formula)")
    }
  }

  # Validate and process data parameter
  # data can be: NULL (inherit from collection), character (dataset name), or data.frame
  data_is_dataframe <- FALSE
  if (!is.null(data)) {
    if (is.data.frame(data)) {
      # Data frame passed directly - store in spec
      data_is_dataframe <- TRUE
    } else if (is.character(data) && length(data) == 1 && nchar(data) > 0) {
      # Dataset name (existing behavior)
      data_is_dataframe <- FALSE
    } else {
      stop("data must be a data frame, a non-empty character string (dataset name), or NULL")
    }
  }

  # Bundle all parameters into a spec
  viz_spec <- c(
    list(
      type = "viz",  # Mark as viz content type
      viz_type = type,  # Store actual viz type (histogram, bar, etc)
      tabgroup = tabgroup_parsed,
      title = title,
      title_tabset = title_tabset,
      text = text,  # Store original text parameter for backward compatibility
      icon = icon,
      text_position = text_position,
      text_before_tabset = text_before_tabset,
      text_after_tabset = text_after_tabset,
      text_before_viz = text_before_viz,
      text_after_viz = text_after_viz,
      height = height,
      filter = filter,
      data = data,
      data_is_dataframe = data_is_dataframe,
      drop_na_vars = drop_na_vars
    ),
    dot_args  # Add remaining parameters from defaults/dots
  )

  # Add insertion index to preserve order
  insertion_idx <- length(viz_collection$items) + 1
  viz_spec$.insertion_index <- insertion_idx

  # Append to the collection using unified $items
  viz_collection$items <- c(viz_collection$items, list(viz_spec))

  viz_collection
}

#' Add Multiple Visualizations at Once
#'
#' @description
#' Convenience function to add multiple visualizations in a loop by expanding
#' vector parameters. Automatically detects which parameters should be expanded
#' to create multiple visualizations. This is useful when creating many similar
#' visualizations that differ only in one or two parameters.
#'
#' @param viz_collection A viz_collection object from create_viz()
#' @param ... Visualization parameters. Parameters with multiple values will be
#'   expanded to create multiple visualizations. Common parameters with single
#'   values will be applied to all visualizations.
#' @param .tabgroup_template Optional. Template string for tabgroup with `{i}` placeholder
#'   for the iteration index (e.g., `"skills/age/item{i}"`). You can also use
#'   parameter names in the template (e.g., `"skills/{response_var}"`).
#'   If NULL, tabgroup must be provided as a vector of the same length as expandable parameters.
#' @param .title_template Optional. Template string for title with `{i}` placeholder.
#'
#' @details
#' The function identifies "expandable" parameters (response_var, x_var, y_var,
#' stack_var, questions) and creates one visualization per value. Other parameters
#' are applied to all visualizations. All expandable vector parameters must have
#' the same length.
#'
#' Templates use glue syntax:
#' - `{i}` is replaced with the iteration number (1, 2, 3, ...)
#' - `{param_name}` is replaced with the current value of that parameter
#'
#' @return The updated viz_collection object with multiple visualizations added
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Basic expansion - create 3 timeline visualizations
#' viz <- create_viz(type = "timeline", time_var = "wave", chart_type = "line") |>
#'   add_vizzes(
#'     response_var = c("SInfo1", "SInfo2", "SInfo3"),
#'     group_var = "AgeGroup",  # Same for all
#'     .tabgroup_template = "skills/age/item{i}"
#'   )
#'
#' # Parallel expansion - titles match the variables
#' viz <- create_viz(type = "stackedbar") |>
#'   add_vizzes(
#'     x_var = c("Age", "Gender", "Education"),
#'     title = c("By Age", "By Gender", "By Education"),
#'     .tabgroup_template = "demographics/demo{i}"
#'   )
#'
#' # Use variable names in template
#' viz <- create_viz(type = "timeline") |>
#'   add_vizzes(
#'     response_var = c("SInfo1", "SInfo2", "SInfo3"),
#'     .tabgroup_template = "skills/{response_var}"
#'   )
#'
#' # Helper function pattern
#' add_all_questions <- function(viz, vars, group_var, tbgrp, demographic, wave) {
#'   wave_path <- tolower(gsub(" ", "", wave))
#'   viz |> add_vizzes(
#'     response_var = vars,
#'     group_var = group_var,
#'     .tabgroup_template = glue::glue("{tbgrp}/{wave_path}/{demographic}/item{{i}}")
#'   )
#' }
#'
#' viz <- create_viz(type = "timeline", time_var = "wave") |>
#'   add_all_questions(
#'     vars = c("var1", "var2", "var3"),
#'     group_var = "AgeGroup",
#'     tbgrp = "skills",
#'     demographic = "age",
#'     wave = "Over Time"
#'   )
#' }


#' Add Multiple Visualizations at Once
#'
#' @description
#' Convenience function to add multiple visualizations in a loop by expanding
#' vector parameters. Automatically detects which parameters should be expanded
#' to create multiple visualizations. This is useful when creating many similar
#' visualizations that differ only in one or two parameters.
#'
#' @param viz_collection A viz_collection object from create_viz()
#' @param ... Visualization parameters. Parameters with multiple values will be
#'   expanded to create multiple visualizations. Common parameters with single
#'   values will be applied to all visualizations.
#' @param .tabgroup_template Optional. Template string for tabgroup with `{i}` placeholder
#'   for the iteration index (e.g., `"skills/age/item{i}"`). You can also use
#'   parameter names in the template (e.g., `"skills/{response_var}"`).
#'   If NULL, tabgroup must be provided as a vector of the same length as expandable parameters.
#' @param .title_template Optional. Template string for title with `{i}` placeholder.
#'
#' @details
#' The function identifies "expandable" parameters (response_var, x_var, y_var,
#' stack_var, questions) and creates one visualization per value. Other parameters
#' are applied to all visualizations. All expandable vector parameters must have
#' the same length.
#'
#' Templates use glue syntax:
#' - `{i}` is replaced with the iteration number (1, 2, 3, ...)
#' - `{param_name}` is replaced with the current value of that parameter
#'
#' @return The updated viz_collection object with multiple visualizations added
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Basic expansion - create 3 timeline visualizations
#' viz <- create_viz(type = "timeline", time_var = "wave", chart_type = "line") |>
#'   add_vizzes(
#'     response_var = c("SInfo1", "SInfo2", "SInfo3"),
#'     group_var = "AgeGroup",  # Same for all
#'     .tabgroup_template = "skills/age/item{i}"
#'   )
#'
#' # Parallel expansion - titles match the variables
#' viz <- create_viz(type = "stackedbar") |>
#'   add_vizzes(
#'     x_var = c("Age", "Gender", "Education"),
#'     title = c("By Age", "By Gender", "By Education"),
#'     .tabgroup_template = "demographics/demo{i}"
#'   )
#'
#' # Use variable names in template
#' viz <- create_viz(type = "timeline") |>
#'   add_vizzes(
#'     response_var = c("SInfo1", "SInfo2", "SInfo3"),
#'     .tabgroup_template = "skills/{response_var}"
#'   )
#'
#' # Helper function pattern
#' add_all_questions <- function(viz, vars, group_var, tbgrp, demographic, wave) {
#'   wave_path <- tolower(gsub(" ", "", wave))
#'   viz |> add_vizzes(
#'     response_var = vars,
#'     group_var = group_var,
#'     .tabgroup_template = glue::glue("{tbgrp}/{wave_path}/{demographic}/item{{i}}")
#'   )
#' }
#'
#' viz <- create_viz(type = "timeline", time_var = "wave") |>
#'   add_all_questions(
#'     vars = c("var1", "var2", "var3"),
#'     group_var = "AgeGroup",
#'     tbgrp = "skills",
#'     demographic = "age",
#'     wave = "Over Time"
#'   )
#' }
add_vizzes <- function(viz_collection, ...,
                       .tabgroup_template = NULL,
                       .title_template = NULL) {

  # Validate first argument
  if (!is_content(viz_collection)) {
    stop("First argument must be a content collection", call. = FALSE)
  }

  # Get parameters
  params <- list(...)

  # Define which parameters trigger expansion (primary viz parameters)
  EXPANDABLE_PARAMS <- c("response_var", "x_var", "y_var", "stack_var",
                         "questions", "group_var", "title")

  # Find expandable params that have vectors (length > 1)
  expandable <- intersect(names(params), EXPANDABLE_PARAMS)
  vector_params <- expandable[sapply(params[expandable], length) > 1]

  # Check if we have anything to expand
  if (length(vector_params) == 0) {
    stop("No expandable parameters found with length > 1. ",
         "Use add_viz() for single visualizations. ",
         "Expandable parameters: ", paste(EXPANDABLE_PARAMS, collapse = ", "),
         call. = FALSE)
  }

  # Get number of iterations from first expandable param
  n <- length(params[[vector_params[1]]])

  # Validate all vector params have same length
  lengths <- sapply(params[vector_params], length)
  if (!all(lengths == n)) {
    stop("All expandable vector parameters must have the same length. Found: ",
         paste(names(lengths), "=", lengths, collapse = ", "), call. = FALSE)
  }

  # Special handling for tabgroup if provided as vector
  if ("tabgroup" %in% names(params) && length(params$tabgroup) == n) {
    # Tabgroup is a vector matching expansion length - treat specially
    tabgroup_vector <- params$tabgroup
    params$tabgroup <- NULL  # Remove from params
  } else {
    tabgroup_vector <- NULL
  }

  # Loop and call add_viz() for each iteration
  for (i in seq_len(n)) {
    # Build params for this iteration
    iter_params <- lapply(names(params), function(nm) {
      p <- params[[nm]]
      if (nm %in% vector_params) {
        p[[i]]  # Extract i-th value for expandable params
      } else {
        p  # Use same value for all (including color_palette, etc.)
      }
    })
    names(iter_params) <- names(params)

    # Handle tabgroup template or vector
    if (!is.null(.tabgroup_template)) {
      # Use template with glue - convert list to environment for glue
      template_data <- c(list(i = i), iter_params)
      template_env <- list2env(template_data, parent = emptyenv())
      iter_params$tabgroup <- as.character(glue::glue(.tabgroup_template, .envir = template_env))
    } else if (!is.null(tabgroup_vector)) {
      # Use pre-provided tabgroup vector
      iter_params$tabgroup <- tabgroup_vector[[i]]
    }
    # else: tabgroup might be in iter_params already as a single value

    # Handle title template
    if (!is.null(.title_template)) {
      template_data <- c(list(i = i), iter_params)
      template_env <- list2env(template_data, parent = emptyenv())
      iter_params$title <- as.character(glue::glue(.title_template, .envir = template_env))
    }

    # Call the existing add_viz() function!
    # Use do.call to pass all params including ...
    viz_collection <- do.call(add_viz, c(list(viz_collection), iter_params))
  }

  viz_collection
}

#' Set or update tabgroup display labels
#'
#' Updates the display labels for tab groups in a visualization collection.
#' Useful when you want to change the section headers after creating the collection.
#'
#' @param viz_collection A viz_collection object
#' @param labels Named character vector or list mapping tabgroup IDs to labels (deprecated, use ... instead)
#' @param ... Named arguments where names are tabgroup IDs and values are display labels
#' @return The updated viz_collection
#' @export
#' @examples
#' \dontrun{
#' # New style: direct key-value pairs (recommended)
#' vizzes <- create_viz() %>%
#'   add_viz(type = "heatmap", tabgroup = "demo") %>%
#'   set_tabgroup_labels(demo = "Demographic Breakdowns", age = "Age Groups")
#'
#' # Old style: still supported for backwards compatibility
#' vizzes <- create_viz() %>%
#'   add_viz(type = "heatmap", tabgroup = "demo") %>%
#'   set_tabgroup_labels(list(demo = "Demographic Breakdowns"))
#' }
set_tabgroup_labels <- function(viz_collection, labels = NULL, ...) {
  if (!is_content(viz_collection)) {
    stop("First argument must be a content collection")
  }

  # Get key-value pairs from ...
  dots <- list(...)

  # Backwards compatibility: if labels is provided (not NULL), use it
  # Otherwise, use the ... arguments
  if (!is.null(labels)) {
    # Old style: labels is a list or vector
    viz_collection$tabgroup_labels <- labels
  } else if (length(dots) > 0) {
    # New style: direct key-value pairs
    viz_collection$tabgroup_labels <- dots
  } else {
    stop("Either provide 'labels' argument or key-value pairs via ...")
  }

  viz_collection
}

#' Create a single visualization specification
#'
#' Helper function to create individual viz specs that can be combined
#' into a list or used directly in add_page().
#'
#' @param type Visualization type
#' @param ... Additional parameters
#' @param tabgroup Optional group ID
#' @param title Display title
#' @return A list containing the visualization specification
#' @export
#' @examples
#' \dontrun{
#' viz1 <- spec_viz(type = "heatmap", x_var = "party", y_var = "ideology")
#' viz2 <- spec_viz(type = "histogram", x_var = "age")
#' page_viz <- list(viz1, viz2)
#' }


#' Create a single visualization specification
#'
#' Helper function to create individual viz specs that can be combined
#' into a list or used directly in add_page().
#'
#' @param type Visualization type
#' @param ... Additional parameters
#' @param tabgroup Optional group ID
#' @param title Display title
#' @return A list containing the visualization specification
#' @export
#' @examples
#' \dontrun{
#' viz1 <- spec_viz(type = "heatmap", x_var = "party", y_var = "ideology")
#' viz2 <- spec_viz(type = "histogram", x_var = "age")
#' page_viz <- list(viz1, viz2)
#' }
spec_viz <- function(type, ..., tabgroup = NULL, title = NULL) {
  list(
    type = type,
    tabgroup = tabgroup,
    title = title,
    ...
  )
}

# ===================================================================
# Core Dashboard Functions
# ===================================================================

#' Create a new dashboard project
#'
#' Initializes a dashboard project object that can be built up using
#' the piping workflow with add_landingpage() and add_page().
#'
#' @param output_dir Directory for generated files
#' @param title Overall title for the dashboard site
#' @param logo Optional logo filename (will be copied to output directory)
#' @param favicon Optional favicon filename (will be copied to output directory)
#' @param github GitHub repository URL (optional)
#' @param twitter Twitter profile URL (optional)
#' @param linkedin LinkedIn profile URL (optional)
#' @param email Email address (optional)
#' @param website Website URL (optional)
#' @param search Enable search functionality (default: TRUE)
#' @param theme Bootstrap theme (cosmo, flatly, journal, etc.) (optional)
#' @param custom_css Path to custom CSS file (optional)
#' @param custom_scss Path to custom SCSS file (optional)
#' @param author Author name for the site (optional)
#' @param description Site description for SEO (optional)
#' @param page_footer Custom footer text (optional)
#' @param date Site creation/update date (optional)
#' @param sidebar Enable/disable global sidebar (default: FALSE)
#' @param sidebar_style Sidebar style (floating, docked, etc.) (optional)
#' @param sidebar_background Sidebar background color (optional)
#' @param navbar_style Navbar style (default, dark, light) (optional)
#' @param navbar_brand Custom brand text (optional)
#' @param navbar_toggle Mobile menu toggle behavior (optional)
#' @param math Enable/disable math rendering (katex, mathjax) (optional)
#' @param code_folding Code folding behavior (none, show, hide) (optional)
#' @param code_tools Code tools (copy, download, etc.) (optional)
#' @param toc Table of contents (floating, left, right) (optional)
#' @param toc_depth TOC depth level (default: 3)
#' @param google_analytics Google Analytics ID (optional)
#' @param plausible Plausible analytics domain (optional)
#' @param gtag Google Tag Manager ID (optional)
#' @param value_boxes Enable value box styling (default: FALSE)
#' @param metrics_style Metrics display style (optional)
#' @param shiny Enable Shiny interactivity (default: FALSE)
#' @param observable Enable Observable JS (default: FALSE)
#' @param jupyter Enable Jupyter widgets (default: FALSE)
#' @param publish_dir Custom publish directory (optional)
#' @param github_pages GitHub Pages configuration (optional)
#' @param netlify Netlify deployment settings (optional)
#' @param allow_inside_pkg Allow output directory inside package (default FALSE)
#' @param warn_before_overwrite Warn before overwriting existing files (default TRUE)
#' @param sidebar_groups List of sidebar groups for hybrid navigation (optional)
#' @param navbar_sections List of navbar sections that link to sidebar groups (optional)
#' @return A dashboard_project object
#' @export
#' @examples
#' \dontrun{
#' # Basic dashboard
#' dashboard <- create_dashboard("my_dashboard", "My Analysis Dashboard")
#'
#' # Comprehensive dashboard with all features
#' dashboard <- create_dashboard(
#'   "my_dashboard",
#'   "My Analysis Dashboard",
#'   logo = "logo.png",
#'   github = "https://github.com/username/repo",
#'   twitter = "https://twitter.com/username",
#'   theme = "cosmo",
#'   author = "Dr. Jane Smith",
#'   description = "Comprehensive data analysis dashboard",
#'   page_footer = "© 2024 Company Name",
#'   sidebar = TRUE,
#'   toc = "floating",
#'   google_analytics = "GA-XXXXXXXXX",
#'   value_boxes = TRUE,
#'   shiny = TRUE
#' )
#' }


#' Print Visualization Collection
#'
#' Displays a formatted summary of a visualization collection, including hierarchical
#' tabgroup structure, visualization types, titles, filters, and defaults.
#'
#' @param x A viz_collection object created by \code{\link{create_viz}}.
#' @param render If TRUE and data is attached, opens a preview in the viewer
#'   instead of showing the structure. Default is FALSE.
#' @param ... Additional arguments (currently ignored).
#'
#' @return Invisibly returns the input object \code{x}.
#'
#' @details
#' The print method displays:
#' \itemize{
#'   \item Total number of visualizations
#'   \item Default parameters (if set)
#'   \item Hierarchical tree structure showing tabgroup organization
#'   \item Visualization types with emoji indicators
#'   \item Filter status for each visualization
#' }
#'
#' Use \code{print(x, render = TRUE)} to open a preview in the viewer instead
#' of showing the structure. This is useful for quick visualization in the console.
#'
#' @export
print.viz_collection <- function(x, render = FALSE, ...) {
 # If render = TRUE and data is attached, open preview instead
  if (render && !is.null(x$data)) {
    preview(x, open = TRUE, quarto = FALSE)
    return(invisible(x))
  }

  total <- length(x$items)
  is_content_collection <- inherits(x, "content_collection")
  collection_type <- if (is_content_collection) "Content Collection" else "Visualization Collection"

  # Header - use cat for capturable output, cli for styling
  rule_char <- cli::symbol$line
  header_text <- cli::style_bold(collection_type)
  rule_width <- max(0, 80 - nchar(collection_type) - 4)
  cat("-- ", header_text, " ", strrep(rule_char, rule_width), "\n", sep = "")

  if (total == 0) {
    cat(cli::symbol$warning, " Empty collection\n", sep = "")
    return(invisible(x))
  }

  # Summary line with icons
  has_data <- !is.null(x$data)
  data_info <- if (has_data) {
    if (is.data.frame(x$data)) {
      paste0(cli::symbol$tick, " data: ", nrow(x$data), " rows x ", ncol(x$data), " cols")
    } else {
      paste0(cli::symbol$tick, " data: attached")
    }
  } else {
    cli::col_silver(paste0(cli::symbol$cross, " no data"))
  }
  cat(cli::col_cyan(total), " items | ", data_info, "\n\n", sep = "")

  # Build hierarchical tree structure
  tree <- .build_print_tree(x$items)

  # Print the tree using cli
 .print_cli_tree(tree, x$items)

  invisible(x)
}

#' Build tree structure for printing
#' @noRd
.build_print_tree <- function(items) {
  tree <- list()
  for (i in seq_along(items)) {
    v <- items[[i]]
    v$.index <- i  # Store original index

    # Get path parts - handle both vector and string formats
    if (is.null(v$tabgroup)) {
      path_parts <- "(ungrouped)"
    } else if (is.character(v$tabgroup) && length(v$tabgroup) > 0) {
      if (length(v$tabgroup) > 1) {
        # Already a vector (e.g., c("Demographics", "Age"))
        path_parts <- v$tabgroup
      } else {
        # Single string - split by /
        path_parts <- strsplit(v$tabgroup, "/")[[1]]
      }
    } else {
      path_parts <- "(ungrouped)"
    }

    # Use recursive helper to add item at correct path
    tree <- .update_tree(tree, path_parts, v)
  }
  tree
}

#' Update tree with item at path (recursive)
#' @noRd
.update_tree <- function(tree, path_parts, item) {
  # Guard against empty or invalid path_parts
  if (length(path_parts) == 0 || is.null(path_parts)) {
    path_parts <- "(ungrouped)"
  }
  
  # Filter out empty strings
  path_parts <- path_parts[nchar(path_parts) > 0]
  if (length(path_parts) == 0) {
    path_parts <- "(ungrouped)"
  }
  
  part <- path_parts[1]

  # Ensure this node exists
  if (is.null(tree[[part]])) {
    tree[[part]] <- list(.items = list(), .children = list())
  }

  if (length(path_parts) == 1) {
    # This is the final destination - add item here
    tree[[part]]$.items <- c(tree[[part]]$.items, list(item))
  } else {
    # More path parts remain - recurse into children
    tree[[part]]$.children <- .update_tree(
      tree[[part]]$.children,
      path_parts[-1],
      item
    )
  }
  tree
}

#' Print tree using cli with proper indentation
#' @noRd
.print_cli_tree <- function(tree, all_items, indent = 0) {
  node_names <- setdiff(names(tree), c(".items", ".children"))

  for (i in seq_along(node_names)) {
    name <- node_names[i]
    node <- tree[[name]]

    # Count contents for this tab
    items <- node$.items
    children <- node$.children
    content_summary <- .count_tab_contents(items, children)

    indent_str <- strrep("  ", indent)
    
    # For "(ungrouped)" items, don't show a tab header - just print items directly
    if (name == "(ungrouped)") {
      if (length(items) > 0) {
        for (j in seq_along(items)) {
          v <- items[[j]]
          .print_item_cat(v, indent)
        }
      }
    } else {
      # Print tab label with contents summary and pointer icon
      tab_icon <- cli::symbol$pointer
      tab_label <- cli::col_blue("[Tab]")
      tab_name <- cli::style_bold(cli::col_cyan(name))
      content_info <- cli::col_silver(paste0(" (", content_summary, ")"))
      cat(indent_str, tab_icon, " ", tab_label, " ", tab_name, content_info, "\n", sep = "")

      # Print items at this level
      item_indent <- indent + 1

      if (length(items) > 0) {
        for (j in seq_along(items)) {
          v <- items[[j]]
          .print_item_cat(v, item_indent)
        }
      }

      # Recursively print children
      if (length(children) > 0) {
        .print_cli_tree(children, all_items, item_indent)
      }
    }
  }
}

#' Count contents of a tab for summary display
#' @noRd
.count_tab_contents <- function(items, children) {
  # Count direct items by type - handle empty case
  if (length(items) == 0) {
    viz_count <- 0
    text_count <- 0
    other_count <- 0
  } else {
    viz_count <- sum(vapply(items, function(x) !is.null(x$viz_type), logical(1)))
    text_count <- sum(vapply(items, function(x) !is.null(x$type) && x$type == "text", logical(1)))
    other_count <- length(items) - viz_count - text_count
  }

  # Count nested tabs
  tab_count <- length(setdiff(names(children), c(".items", ".children")))

  parts <- c()
  if (tab_count > 0) parts <- c(parts, paste0(tab_count, " tab", if (tab_count > 1) "s" else ""))
  if (viz_count > 0) parts <- c(parts, paste0(viz_count, " viz", if (viz_count > 1) "s" else ""))
  if (text_count > 0) parts <- c(parts, paste0(text_count, " text"))
  if (other_count > 0) parts <- c(parts, paste0(other_count, " other"))

  if (length(parts) == 0) return("empty")
  paste(parts, collapse = ", ")
}

#' Print a single item using cat with cli styling
#' @noRd
.print_item_cat <- function(v, indent = 0) {
  indent_str <- strrep("  ", indent)

  # Determine item type and details
  if (!is.null(v$viz_type)) {
    # Visualization - show [Viz] label + type + title + variables
    viz_type <- v$viz_type
    title <- v$title %||% "(untitled)"
    x_var <- v$x_var %||% NULL
    y_var <- v$y_var %||% NULL
    stack_var <- v$stack_var %||% NULL

    # Build variable info
    var_parts <- c()
    if (!is.null(x_var)) var_parts <- c(var_parts, paste0("x=", x_var))
    if (!is.null(y_var)) var_parts <- c(var_parts, paste0("y=", y_var))
    if (!is.null(stack_var)) var_parts <- c(var_parts, paste0("stack=", stack_var))
    var_info <- if (length(var_parts) > 0) paste0(" ", cli::col_silver(paste(var_parts, collapse = ", "))) else ""

    # Filter info
    filter_info <- if (!is.null(v$filter)) cli::col_yellow(" +filter") else ""

    # Type label and viz type with bullet icon
    viz_icon <- cli::symbol$bullet
    type_label <- cli::col_green("[Viz]")
    viz_badge <- cli::col_magenta(viz_type)

    cat(indent_str, viz_icon, " ", type_label, " ", cli::style_bold(title), " ", cli::col_silver("("), viz_badge, cli::col_silver(")"), var_info, filter_info, "\n", sep = "")

  } else if (!is.null(v$type)) {
    # Content block - show appropriate label
    content_type <- v$type
    title <- v$title %||% ""

    # Map content type to display label, color and icon
    type_info <- switch(content_type,
      "text" = list(label = "[Text]", color = cli::col_yellow, icon = cli::symbol$info),
      "callout" = list(label = "[Callout]", color = cli::col_yellow, icon = cli::symbol$warning),
      "image" = list(label = "[Image]", color = cli::col_blue, icon = cli::symbol$circle_filled),
      "accordion" = list(label = "[Accordion]", color = cli::col_yellow, icon = cli::symbol$menu),
      "card" = list(label = "[Card]", color = cli::col_blue, icon = cli::symbol$square_small_filled),
      "divider" = list(label = "[Divider]", color = cli::col_silver, icon = cli::symbol$line),
      "code" = list(label = "[Code]", color = cli::col_magenta, icon = cli::symbol$bullet),
      "pagination" = list(label = "[PageBreak]", color = cli::col_red, icon = cli::symbol$arrow_right),
      list(label = paste0("[", content_type, "]"), color = cli::col_white, icon = cli::symbol$bullet)
    )

    type_label <- type_info$color(type_info$label)
    content_icon <- type_info$icon

    if (nchar(title) > 0) {
      cat(indent_str, content_icon, " ", type_label, " ", title, "\n", sep = "")
    } else {
      cat(indent_str, content_icon, " ", type_label, "\n", sep = "")
    }
  } else {
    cat(indent_str, cli::symbol$cross, " ", cli::col_red("<UNKNOWN>"), "\n", sep = "")
  }
}

# ===================================================================
# Hybrid Navigation Helper Functions
# ===================================================================

#' Create a sidebar group for hybrid navigation
#'
#' Helper function to create a sidebar group configuration for use with
#' hybrid navigation. Each group can have its own styling and contains
#' a list of pages.
#'
#' @param id Unique identifier for the sidebar group
#' @param title Display title for the sidebar group
#' @param pages Character vector of page names to include in this group
#' @param style Sidebar style (docked, floating, etc.) (optional)
#' @param background Background color (optional)
#' @param foreground Foreground color (optional)
#' @param border Show border (optional)
#' @param alignment Alignment (left, right) (optional)
#' @param collapse_level Collapse level for navigation (optional)
#' @param pinned Whether sidebar is pinned (optional)
#' @param tools List of tools to add to sidebar (optional)
#' @return List containing sidebar group configuration
#' @export
#' @examples
#' \dontrun{
#' # Create a sidebar group for analysis pages
#' analysis_group <- sidebar_group(
#'   id = "analysis",
#'   title = "Data Analysis",
#'   pages = c("overview", "demographics", "findings"),
#'   style = "docked",
#'   background = "light"
#' )
#' }

# ===================================================================
# Pagination
# ===================================================================

#' Add pagination break to visualization collection
#'
#' Insert a pagination marker that splits the visualization collection into
#' separate HTML pages. Each section will be rendered as its own page file
#' (e.g., analysis.html, analysis_p2.html, analysis_p3.html) with automatic
#' Previous/Next navigation between them.
#'
#' This provides TRUE performance benefits - each page loads independently,
#' dramatically reducing initial render time and file size for large dashboards.
#'
#' @param viz_collection A viz_collection object
#' @param position Position for pagination controls: "bottom" (sticky at bottom),
#'   "top" (inline with page title), "both" (top and bottom), or NULL (default - uses
#'   dashboard-level setting from create_dashboard). Per-page override of the dashboard default.
#' @return Updated viz_collection object
#' @export
#' @examples
#' \dontrun{
#' # Split 150 charts into 3 pages of 50 each
#' vizzes <- create_viz()
#'
#' # Page 1: Charts 1-50
#' for (i in 1:50) vizzes <- vizzes %>% add_viz(type = "bar", x_var = "cyl")
#'
#' vizzes <- vizzes %>% add_pagination()  # Split here
#'
#' # Page 2: Charts 51-100
#' for (i in 51:100) vizzes <- vizzes %>% add_viz(type = "bar", x_var = "gear")
#'
#' vizzes <- vizzes %>% add_pagination()  # Split here
#'
#' # Page 3: Charts 101-150
#' for (i in 101:150) vizzes <- vizzes %>% add_viz(type = "bar", x_var = "hp")
#'
#' # Use in dashboard
#' dashboard %>%
#'   add_page("Analysis", visualizations = vizzes)
#' }
add_pagination <- function(viz_collection, position = NULL) {

  # Validate first argument
  if (!is_content(viz_collection)) {
    stop("First argument must be a content collection", call. = FALSE)
  }

  # Validate position if provided (NULL means use dashboard default)
  if (!is.null(position)) {
    position <- match.arg(position, c("bottom", "top", "both"))
  }

  # Add pagination marker to collection
  # If position is NULL, the dashboard default will be used during generation
  pagination_item <- list(
    type = "pagination",
    pagination_break = TRUE,
    pagination_position = position  # Can be NULL - means use dashboard default
  )

  # Add to items
  viz_collection$items <- c(viz_collection$items, list(pagination_item))

  viz_collection
}


# ===================================================================
# Preview Function
# ===================================================================

#' Preview any dashboardr object
#'
#' Universal preview function that renders any dashboardr object to HTML and 
#' displays it in the RStudio Viewer pane or browser. Supports dashboard_project,
#' page_object, content_collection, viz_collection, and individual content_block
#' objects. Useful for developing and testing dashboards without building the 
#' entire project.
#'
#' @param collection A dashboardr object to preview. Can be any of:
#'   \itemize{
#'     \item \code{dashboard_project} - previews all pages with full styling
#'     \item \code{page_object} - previews a single page
#'     \item \code{content_collection} or \code{viz_collection} - previews content/visualizations
#'     \item \code{content_block} - previews a single content block (text, callout, etc.)
#'   }
#'   For collections with visualizations, data must be attached via the \code{data}
#'   parameter in \code{create_viz()}/\code{create_content()}.
#' @param title Optional title for the preview document (default: "Preview")
#' @param open Whether to automatically open the result in viewer/browser (default: TRUE)
#' @param clean Whether to clean up temporary files after viewing (default: FALSE)
#' @param quarto Whether to use Quarto for rendering (default: FALSE).
#'   When FALSE (default), uses direct R rendering which is faster and doesn't require Quarto.
#'   When TRUE, creates a full Quarto document (useful for testing tabsets/icons).
#' @param theme Bootstrap theme for Quarto preview (default: "cosmo", only used when quarto=TRUE)
#' @param path Optional path to save the preview. If NULL (default), uses a temp
#'   directory. Can be a directory path (preview.html will be created inside) or
#'   a file path ending in .html.
#' @param page Optional page name to preview (only used for dashboard_project objects).
#'   When NULL, previews all pages. When specified, previews only the named page.
#'
#' @return Invisibly returns the path to the generated HTML file.
#'
#' @details
#' The preview function has two modes:
#'
#' **Direct mode (quarto = FALSE, default):**
#' \itemize{
#'   \item Directly calls visualization functions with the attached data
#'   \item Renders all content blocks (text, callouts, cards, tables, etc.)
#'   \item Includes interactive elements (inputs, modals) with CDN dependencies
#'   \item Wraps results in a styled HTML page using htmltools
#'   \item Fast and doesn't require Quarto installation
#'   \item Best for quick iteration during development
#' }
#'
#' **Quarto mode (quarto = TRUE):**
#' \itemize{
#'   \item Creates a temporary Quarto document
#'   \item Renders with full Quarto features (tabsets, icons, theming)
#'   \item Applies dashboard styling (navbar colors, fonts, tabset themes)
#'   \item Requires Quarto to be installed
#'   \item Best for testing final dashboard appearance
#' }
#'
#' **Supported content types:**
#' Text/display: text, html, quote, badge, metric
#' Layout: divider, spacer, card, accordion  
#' Media: image, video, iframe
#' Tables: gt, reactable, DT, table
#' Interactive: input, input_row, modal
#' Value boxes: value_box, value_box_row
#'
#' @export
#' @examples
#' \dontrun{
#' # Preview a dashboard project
#' my_dashboard %>% preview()
#' my_dashboard %>% preview(page = "Analysis")  # Preview specific page
#' my_dashboard %>% preview(quarto = TRUE)  # Full Quarto rendering
#'
#' # Preview a page object
#' create_page("Analysis", data = mtcars) %>%
#'   add_viz(type = "histogram", x_var = "mpg") %>%
#'   preview()
#'
#' # Preview a visualization collection
#' create_viz(data = mtcars) %>%
#'   add_viz(type = "histogram", x_var = "mpg", title = "MPG Distribution") %>%
#'   preview()
#'
#' # Preview with Quarto for full features (required for tabsets!)
#' create_viz(data = mtcars) %>%
#'   add_viz(type = "histogram", x_var = "mpg", tabgroup = "MPG") %>%
#'   add_viz(type = "histogram", x_var = "hp", tabgroup = "HP") %>%
#'   preview(quarto = TRUE)
#'
#' # Preview content blocks
#' create_content() %>%
#'   add_text("# Hello World") %>%
#'   add_callout("Important note", type = "tip") %>%
#'   preview()
#'
#' # Save preview to specific location
#' my_viz %>% preview(path = "~/Desktop/my_preview.html")
#'
#' # Preview without opening (just render)
#' html_path <- my_viz %>% preview(open = FALSE)
#' }
preview <- function(collection, title = "Preview", open = TRUE, clean = FALSE,
                    quarto = FALSE, theme = "cosmo", path = NULL, page = NULL) {
  
  # If we're in a knitr context, return the object for knit_print to handle
  if (isTRUE(getOption("knitr.in.progress"))) {
    return(collection)
  }
  
  # Handle dashboard_project objects
  if (inherits(collection, "dashboard_project")) {
    return(.preview_dashboard_project(collection, title = title, open = open, 
                                       clean = clean, quarto = quarto, 
                                       theme = theme, path = path, page = page))
  }
  
  # Handle content_block objects (standalone blocks like add_text("hello"))
  if (is_content_block(collection)) {
    collection <- .wrap_content_block(collection)
  }
  
  # Handle page_objects
  if (inherits(collection, "page_object")) {
    collection <- .page_to_content(collection)
    if (title == "Preview") {
      title <- paste("Page:", collection$name %||% "Preview")
    }
  }
  
  # Validate collection
  if (!is_content(collection)) {
    stop("collection must be a dashboard_project, page_object, content_collection, viz_collection, or content_block", call. = FALSE)
  }

  # Check for items
  if (length(collection$items) == 0) {
    stop("Collection is empty. Add content with add_viz(), add_text(), etc. before previewing.", call. = FALSE)
  }
  
 # Check if there are visualizations that need data
  has_viz <- any(sapply(collection$items, function(item) {
    !is.null(item$viz_type) || (!is.null(item$type) && item$type == "viz")
  }))
  
  # Only require data if there are visualizations
  if (has_viz && is.null(collection$data)) {
    stop("No data attached to collection. Use create_viz(data = df) or create_content(data = df) to attach data for visualizations.", call. = FALSE)
  }

  # Check for features that require Quarto (non-null and non-empty)
  has_tabgroups <- any(sapply(collection$items, function(item) {
    !is.null(item$tabgroup) && nchar(item$tabgroup) > 0
  }))
  has_icons <- any(sapply(collection$items, function(item) !is.null(item$icon)))
  
  if (!quarto && (has_tabgroups || has_icons) && interactive()) {
    features <- c()
    if (has_tabgroups) features <- c(features, "tabgroups/tabsets")
    if (has_icons) features <- c(features, "icons")
    warning(
      "Your collection uses ", paste(features, collapse = " and "), 
      " which require Quarto to render properly.\n",
      "Use preview(quarto = TRUE) for full tabset support, or remove tabgroup arguments for direct preview.",
      call. = FALSE
    )
  }

  # Parse path parameter
  preview_dir <- NULL
  output_filename <- "preview.html"
  
  if (!is.null(path)) {
    path <- normalizePath(path.expand(path), mustWork = FALSE)
    if (grepl("\\.html$", path, ignore.case = TRUE)) {
      # Path is a file
      preview_dir <- dirname(path)
      output_filename <- basename(path)
    } else {
      # Path is a directory
      preview_dir <- path
    }
    # Create directory if needed
    if (!dir.exists(preview_dir)) {
      dir.create(preview_dir, recursive = TRUE, showWarnings = FALSE)
    }
  }

  # Use appropriate preview mode
  if (quarto) {
    html_file <- .preview_quarto(collection, title, theme, clean, preview_dir, output_filename)
  } else {
    html_file <- .preview_direct(collection, title, clean, preview_dir, output_filename)
  }

  # Open in viewer
  if (open) {
    # Try RStudio Viewer first
    if (requireNamespace("rstudioapi", quietly = TRUE) && 
        rstudioapi::isAvailable() && 
        rstudioapi::hasFun("viewer")) {
      rstudioapi::viewer(html_file)
    } else {
      # Fallback to browser
      utils::browseURL(html_file)
    }
  }

  invisible(html_file)
}

#' Direct preview using htmltools (no Quarto required)
#' @noRd
.preview_direct <- function(collection, title, clean, preview_dir = NULL, output_filename = "preview.html") {
  data <- collection$data
  
  # Create temp directory for preview if not specified
  if (is.null(preview_dir)) {
    preview_dir <- file.path(tempdir(), paste0("dashboardr_preview_", format(Sys.time(), "%Y%m%d_%H%M%S")))
  }
  dir.create(preview_dir, recursive = TRUE, showWarnings = FALSE)
  
  # Check for interactive elements
  has_inputs <- .collection_has_inputs(collection)
  has_modals <- .collection_has_modals(collection)
  
  # Render all items (content blocks AND visualizations)
  content_widgets <- list()
  
  for (i in seq_along(collection$items)) {
    item <- collection$items[[i]]
    
    # Check if it's a visualization
    is_viz <- !is.null(item$viz_type) || (!is.null(item$type) && item$type == "viz")
    
    if (is_viz) {
      # Render visualization
      viz_type <- item$viz_type %||% item$type
      
      viz_result <- tryCatch({
        .render_viz_direct(item, data)
      }, error = function(e) {
        htmltools::div(
          style = "padding: 20px; background: #fee; border: 1px solid #c00; border-radius: 4px;",
          htmltools::h4(paste0("Error rendering: ", item$title %||% viz_type)),
          htmltools::p(e$message)
        )
      })
      
      # Wrap with title if present
      if (!is.null(item$title)) {
        viz_result <- htmltools::tagList(
          htmltools::h3(item$title),
          viz_result
        )
      }
      
      content_widgets[[length(content_widgets) + 1]] <- htmltools::div(
        style = "margin-bottom: 30px;",
        viz_result
      )
    } else {
      # Render content block
      block_result <- tryCatch({
        .render_content_block_direct(item, preview_dir)
      }, error = function(e) {
        htmltools::div(
          style = "padding: 10px; background: #fff3e0; border: 1px solid #ff9800; border-radius: 4px;",
          htmltools::p(paste0("Error rendering content: ", e$message))
        )
      })
      
      if (!is.null(block_result)) {
        content_widgets[[length(content_widgets) + 1]] <- htmltools::div(
          style = "margin-bottom: 20px;",
          block_result
        )
      }
    }
  }
  
  # Build comprehensive CSS
  css <- .get_preview_css()
  
  # Build HTML page
  html_content <- htmltools::tagList(
    htmltools::tags$head(
      htmltools::tags$title(title),
      htmltools::tags$meta(charset = "utf-8"),
      htmltools::tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
      # Choices.js for inputs
      if (has_inputs) htmltools::tagList(
        htmltools::tags$link(
          rel = "stylesheet",
          href = "https://cdn.jsdelivr.net/npm/choices.js@10.2.0/public/assets/styles/choices.min.css"
        ),
        htmltools::tags$script(
          src = "https://cdn.jsdelivr.net/npm/choices.js@10.2.0/public/assets/scripts/choices.min.js"
        )
      ),
      htmltools::tags$style(htmltools::HTML(css)),
      if (has_modals) htmltools::tags$style(htmltools::HTML(.get_modal_css()))
    ),
    htmltools::tags$body(
      htmltools::h1(title),
      htmltools::div(
        class = "viz-container",
        content_widgets
      ),
      if (has_modals) htmltools::tags$script(htmltools::HTML(.get_modal_js())),
      if (has_inputs) htmltools::tags$script(htmltools::HTML(.get_input_init_js()))
    )
  )
  
  # Save to HTML file
  html_file <- file.path(preview_dir, output_filename)
  htmltools::save_html(html_content, html_file, libdir = "lib")
  
  if (!clean && interactive()) {
    message("Preview files saved to: ", preview_dir)
  }
  
  html_file
}


#' Check if collection has input elements
#' @noRd
.collection_has_inputs <- function(collection) {
  for (item in collection$items) {
    if (!is.null(item$type) && item$type %in% c("input", "input_row")) {
      return(TRUE)
    }
  }
  FALSE
}


#' Check if collection has modal elements
#' @noRd
.collection_has_modals <- function(collection) {
  for (item in collection$items) {
    if (!is.null(item$type) && item$type == "modal") {
      return(TRUE)
    }
  }
  FALSE
}


#' Get comprehensive CSS for preview
#' @noRd
.get_preview_css <- function() {
  "
  body { 
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    max-width: 1200px; 
    margin: 0 auto; 
    padding: 20px;
    background: #fafafa;
  }
  h1 { color: #333; border-bottom: 2px solid #007bff; padding-bottom: 10px; }
  h3 { color: #555; margin-top: 0; }
  .viz-container { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
  
  /* Callouts */
  .callout { 
    padding: 15px 20px; 
    border-left: 4px solid; 
    margin: 15px 0; 
    border-radius: 0 4px 4px 0;
  }
  .callout-note { background: #e3f2fd; border-color: #2196f3; }
  .callout-tip { background: #e8f5e9; border-color: #4caf50; }
  .callout-warning { background: #fff3e0; border-color: #ff9800; }
  .callout-caution { background: #fce4ec; border-color: #e91e63; }
  .callout-important { background: #fbe9e7; border-color: #ff5722; }
  
  /* Cards */
  .card { 
    border: 1px solid #ddd; 
    border-radius: 8px; 
    padding: 20px; 
    margin: 15px 0;
    background: white;
  }
  .card-header { font-weight: 600; margin-bottom: 10px; font-size: 1.1em; }
  .card-footer { border-top: 1px solid #eee; padding-top: 10px; margin-top: 15px; color: #666; font-size: 0.9em; }
  
  /* Accordion */
  .accordion { margin: 15px 0; border: 1px solid #ddd; border-radius: 4px; }
  .accordion-header { 
    background: #f5f5f5; 
    padding: 12px 15px; 
    cursor: pointer;
    font-weight: 500;
    user-select: none;
  }
  .accordion-header:hover { background: #eee; }
  .accordion-content { padding: 15px; border-top: 1px solid #ddd; }
  
  /* Value boxes */
  .value-box { 
    background: linear-gradient(135deg, #007bff 0%, #0056b3 100%);
    color: white;
    padding: 20px;
    border-radius: 8px;
    text-align: center;
  }
  .value-box-value { font-size: 2.5em; font-weight: 700; }
  .value-box-label { opacity: 0.9; margin-top: 5px; }
  
  /* Badges */
  .badge { 
    display: inline-block;
    padding: 4px 10px;
    border-radius: 20px;
    font-size: 12px;
    font-weight: 500;
  }
  .badge-success { background: #4caf50; color: white; }
  .badge-warning { background: #ff9800; color: white; }
  .badge-danger { background: #f44336; color: white; }
  .badge-info { background: #2196f3; color: white; }
  .badge-primary { background: #007bff; color: white; }
  
  /* Metrics */
  .metric { 
    display: inline-block;
    padding: 15px 25px;
    background: #f5f5f5;
    border-radius: 8px;
    text-align: center;
    margin: 5px;
  }
  .metric-value { font-size: 1.8em; font-weight: 700; color: #007bff; }
  .metric-label { color: #666; font-size: 0.9em; margin-top: 5px; }
  
  /* Quotes */
  blockquote { 
    border-left: 4px solid #007bff;
    margin: 20px 0;
    padding: 10px 20px;
    background: #f9f9f9;
    font-style: italic;
  }
  blockquote cite { display: block; margin-top: 10px; color: #666; font-style: normal; }
  
  /* Dividers */
  .divider { border: none; border-top: 1px solid #ddd; margin: 20px 0; }
  .divider-thick { border-top-width: 3px; }
  .divider-dashed { border-top-style: dashed; }
  .divider-dotted { border-top-style: dotted; }
  
  /* Code */
  code, pre { 
    font-family: 'Fira Code', Consolas, Monaco, 'Courier New', monospace;
    background: #f5f5f5;
  }
  code { padding: 2px 6px; border-radius: 3px; }
  pre { padding: 15px; overflow-x: auto; border-radius: 4px; }
  
  /* Images */
  img { max-width: 100%; height: auto; border-radius: 4px; }
  .image-caption { text-align: center; color: #666; font-size: 0.9em; margin-top: 8px; }
  
  /* Iframe and video */
  iframe { border: none; width: 100%; border-radius: 4px; }
  video { max-width: 100%; border-radius: 4px; }
  
  /* Tables */
  table { width: 100%; border-collapse: collapse; margin: 15px 0; }
  th, td { padding: 10px 12px; text-align: left; border-bottom: 1px solid #ddd; }
  th { background: #f5f5f5; font-weight: 600; }
  tr:hover { background: #fafafa; }
  
  /* Inputs */
  .input-filter-container { margin: 15px 0; }
  .input-filter-container label { display: block; margin-bottom: 5px; font-weight: 500; }
  .input-filter { width: 100%; }
  "
}


#' Get JS to initialize Choices.js inputs
#' @noRd
.get_input_init_js <- function() {
  "
  document.addEventListener('DOMContentLoaded', function() {
    document.querySelectorAll('.choices-input').forEach(function(el) {
      if (typeof Choices !== 'undefined') {
        new Choices(el, {
          removeItemButton: true,
          searchEnabled: true,
          placeholder: true,
          placeholderValue: 'Select...'
        });
      }
    });
  });
  "
}

#' Render a single visualization directly
#' @noRd
.render_viz_direct <- function(item, data) {
  viz_type <- item$viz_type %||% item$type
  
  # Apply filter if present
  if (!is.null(item$filter)) {
    filter_expr <- item$filter[[2]]
    data <- dplyr::filter(data, !!filter_expr)
  }
  
  # Build arguments for the viz function
  # Remove internal parameters
  internal_params <- c("type", "viz_type", "tabgroup", "title", "title_tabset", 
                       "text", "icon", "text_position", "text_before_tabset", 
                       "text_after_tabset", "text_before_viz", "text_after_viz",
                       "height", "filter", "has_data", "data_path", "data_is_dataframe",
                       ".insertion_index", ".min_index", "nested_children", "drop_na_vars")
  
  viz_args <- item[!names(item) %in% internal_params]
  
  # If data param is a string (dataset name), use the actual data
  if (is.null(viz_args$data) || is.character(viz_args$data)) {
    viz_args$data <- data
  }
  
  # Call the appropriate visualization function
  viz_fn <- switch(viz_type,
    "histogram" = create_histogram,
    "stackedbar" = create_stackedbar,
    "stackedbars" = create_stackedbars,
    "heatmap" = create_heatmap,
    "bar" = create_bar,
    "scatter" = create_scatter,
    "timeline" = create_timeline,
    "map" = create_map,
    "treemap" = create_treemap,
    NULL
  )
  
 if (is.null(viz_fn)) {
    stop("Unknown visualization type: ", viz_type, call. = FALSE)
  }
  
  # Call the function with arguments
  result <- do.call(viz_fn, viz_args)
  
  # Apply height if specified
  if (!is.null(item$height)) {
    if (inherits(result, "highchart")) {
      result <- highcharter::hc_size(result, height = item$height)
    }
    result <- htmltools::div(
      style = paste0("height: ", item$height, "px; min-height: ", item$height, "px;"),
      result
    )
  }
  
  result
}


#' Render a content block directly to HTML
#' @noRd
.render_content_block_direct <- function(block, preview_dir = NULL) {
  if (is.null(block)) return(NULL)
  
  # Handle content collections (nested items)
  if (is_content(block)) {
    widgets <- list()
    for (item in block$items) {
      item_html <- .render_content_block_direct(item, preview_dir)
      if (!is.null(item_html)) {
        widgets[[length(widgets) + 1]] <- item_html
      }
    }
    return(htmltools::tagList(widgets))
  }
  
  # Get block type
  block_type <- block$type
  if (is.null(block_type)) return(NULL)
  
  # Dispatch to appropriate renderer
  switch(block_type,
    "text" = .render_text_block_direct(block),
    "callout" = .render_callout_block_direct(block),
    "image" = .render_image_block_direct(block),
    "divider" = .render_divider_block_direct(block),
    "code" = .render_code_block_direct(block),
    "spacer" = .render_spacer_block_direct(block),
    "card" = .render_card_block_direct(block),
    "accordion" = .render_accordion_block_direct(block),
    "iframe" = .render_iframe_block_direct(block),
    "video" = .render_video_block_direct(block),
    "html" = .render_html_block_direct(block),
    "quote" = .render_quote_block_direct(block),
    "badge" = .render_badge_block_direct(block),
    "metric" = .render_metric_block_direct(block),
    "value_box" = .render_value_box_block_direct(block),
    "value_box_row" = .render_value_box_row_block_direct(block),
    "gt" = .render_gt_block_direct(block),
    "reactable" = .render_reactable_block_direct(block),
    "DT" = .render_dt_block_direct(block),
    "table" = .render_table_block_direct(block),
    "input" = .render_input_block_direct(block),
    "input_row" = .render_input_row_block_direct(block),
    "modal" = .render_modal_block_direct(block),
    "viz" = NULL,  # Handled separately
    NULL
  )
}


#' Render text block
#' @noRd
.render_text_block_direct <- function(block) {
  text <- block$content %||% block$text %||% ""
  html_content <- .render_markdown_to_html(text)
  htmltools::div(htmltools::HTML(html_content))
}


#' Render callout block
#' @noRd
.render_callout_block_direct <- function(block) {
  type <- block$callout_type %||% "note"
  title <- block$title
  text <- block$text %||% block$content %||% ""
  
  htmltools::div(
    class = paste("callout", paste0("callout-", type)),
    if (!is.null(title)) htmltools::strong(title),
    htmltools::p(text)
  )
}


#' Render image block
#' @noRd
.render_image_block_direct <- function(block) {
  htmltools::tagList(
    htmltools::tags$img(
      src = block$src,
      alt = block$alt %||% "",
      style = paste0(
        "max-width: 100%;",
        if (!is.null(block$width)) paste0(" width: ", block$width, ";") else ""
      )
    ),
    if (!is.null(block$caption)) {
      htmltools::div(class = "image-caption", block$caption)
    }
  )
}


#' Render divider block
#' @noRd
.render_divider_block_direct <- function(block) {
  style <- block$style %||% "default"
  class <- paste("divider", if (style != "default") paste0("divider-", style) else "")
  htmltools::tags$hr(class = class)
}


#' Render code block
#' @noRd
.render_code_block_direct <- function(block) {
  lang <- block$language %||% "r"
  code <- block$code %||% ""
  
  htmltools::tagList(
    if (!is.null(block$filename)) {
      htmltools::div(
        style = "background: #e0e0e0; padding: 5px 10px; border-radius: 4px 4px 0 0; font-size: 12px;",
        block$filename
      )
    },
    htmltools::tags$pre(
      style = if (!is.null(block$filename)) "margin-top: 0; border-radius: 0 0 4px 4px;",
      htmltools::tags$code(class = paste0("language-", lang), code)
    ),
    if (!is.null(block$caption)) {
      htmltools::div(style = "font-size: 12px; color: #666; margin-top: 5px;", block$caption)
    }
  )
}


#' Render spacer block
#' @noRd
.render_spacer_block_direct <- function(block) {
  height <- block$height %||% "2rem"
  htmltools::div(style = paste0("height: ", height, ";"))
}


#' Render card block
#' @noRd
.render_card_block_direct <- function(block) {
  # Card body can be in text, content, or body field
  body_content <- block$text %||% block$content %||% block$body %||% ""
  
  htmltools::div(
    class = "card",
    if (!is.null(block$header) || !is.null(block$title)) {
      htmltools::div(class = "card-header", block$header %||% block$title)
    },
    htmltools::div(class = "card-body", 
      htmltools::HTML(.render_markdown_to_html(body_content))
    ),
    if (!is.null(block$footer)) {
      htmltools::div(
        class = "card-footer",
        style = "border-top: 1px solid #ddd; padding-top: 10px; color: #666; font-size: 0.9em;",
        block$footer
      )
    }
  )
}


#' Render accordion block
#' @noRd
.render_accordion_block_direct <- function(block) {
  open <- isTRUE(block$open)
  id <- paste0("accordion-", sample(100000:999999, 1))
  
  htmltools::div(
    class = paste("accordion", if (open) "open" else ""),
    id = id,
    htmltools::div(
      class = "accordion-header",
      onclick = paste0("this.parentElement.classList.toggle('open')"),
      block$title %||% "Click to expand"
    ),
    htmltools::div(
      class = "accordion-content",
      style = if (open) "display: block;" else "display: none;",
      htmltools::HTML(.render_markdown_to_html(block$text %||% block$content %||% ""))
    )
  )
}


#' Render iframe block
#' @noRd
.render_iframe_block_direct <- function(block) {
  htmltools::tags$iframe(
    src = block$src %||% block$url,
    width = block$width %||% "100%",
    height = block$height %||% "500px",
    style = "border: none;"
  )
}


#' Render video block
#' @noRd
.render_video_block_direct <- function(block) {
  htmltools::tagList(
    htmltools::tags$video(
      controls = NA,
      width = block$width %||% "100%",
      height = block$height,
      htmltools::tags$source(src = block$src, type = "video/mp4")
    ),
    if (!is.null(block$caption)) {
      htmltools::div(class = "image-caption", block$caption)
    }
  )
}


#' Render HTML block
#' @noRd
.render_html_block_direct <- function(block) {
  htmltools::HTML(block$html %||% block$content %||% "")
}


#' Render quote block
#' @noRd
.render_quote_block_direct <- function(block) {
  quote_text <- block$quote %||% block$text %||% block$content %||% ""
  attribution <- block$attribution %||% block$citation %||% block$cite
  
  htmltools::tags$blockquote(
    htmltools::p(quote_text),
    if (!is.null(attribution)) {
      htmltools::tags$cite(paste0("— ", attribution))
    }
  )
}


#' Render badge block
#' @noRd
.render_badge_block_direct <- function(block) {
  type <- block$badge_type %||% block$type_style %||% "info"
  htmltools::span(
    class = paste("badge", paste0("badge-", type)),
    block$text %||% block$label %||% ""
  )
}


#' Render metric block
#' @noRd
.render_metric_block_direct <- function(block) {
  htmltools::div(
    class = "metric",
    htmltools::div(class = "metric-value", block$value),
    htmltools::div(class = "metric-label", block$label %||% block$title %||% "")
  )
}


#' Render value box block
#' @noRd
.render_value_box_block_direct <- function(block) {
  bg_color <- block$color %||% block$bg_color %||% "#007bff"
  
  htmltools::div(
    class = "value-box",
    style = paste0("background: ", bg_color, ";"),
    htmltools::div(class = "value-box-value", block$value),
    htmltools::div(class = "value-box-label", block$title %||% block$label %||% ""),
    if (!is.null(block$caption)) {
      htmltools::div(style = "font-size: 0.8em; opacity: 0.8; margin-top: 5px;", block$caption)
    }
  )
}


#' Render value box row block
#' @noRd
.render_value_box_row_block_direct <- function(block) {
  boxes <- block$boxes %||% list()
  
  htmltools::div(
    style = "display: flex; gap: 15px; flex-wrap: wrap;",
    lapply(boxes, function(box) {
      htmltools::div(
        style = "flex: 1; min-width: 150px;",
        .render_value_box_block_direct(box)
      )
    })
  )
}


#' Render gt table block
#' @noRd
.render_gt_block_direct <- function(block) {
  gt_obj <- block$gt_object %||% block$object
  
  if (is.null(gt_obj)) {
    return(htmltools::div(style = "color: #999;", "[gt table placeholder]"))
  }
  
  # If it's a data frame, convert to gt
  if (is.data.frame(gt_obj)) {
    if (requireNamespace("gt", quietly = TRUE)) {
      gt_obj <- gt::gt(gt_obj)
    } else {
      return(.render_table_block_direct(list(data = gt_obj, caption = block$caption)))
    }
  }
  
  # Render gt object
  if (requireNamespace("gt", quietly = TRUE) && inherits(gt_obj, "gt_tbl")) {
    tryCatch({
      htmltools::HTML(as.character(gt::as_raw_html(gt_obj)))
    }, error = function(e) {
      htmltools::div(style = "color: red;", paste("Error rendering gt table:", e$message))
    })
  } else {
    htmltools::div(style = "color: #999;", "[gt table - gt package not available]")
  }
}


#' Render reactable block
#' @noRd
.render_reactable_block_direct <- function(block) {
  tbl <- block$reactable_object %||% block$object
  
  if (is.null(tbl)) {
    return(htmltools::div(style = "color: #999;", "[reactable placeholder]"))
  }
  
  # If it's a data frame, convert to reactable
  if (is.data.frame(tbl)) {
    if (requireNamespace("reactable", quietly = TRUE)) {
      tbl <- reactable::reactable(tbl)
    } else {
      return(.render_table_block_direct(list(data = tbl)))
    }
  }
  
  # Render reactable
  if (requireNamespace("reactable", quietly = TRUE) && inherits(tbl, "reactable")) {
    tbl
  } else {
    htmltools::div(style = "color: #999;", "[reactable - package not available]")
  }
}


#' Render DT block
#' @noRd
.render_dt_block_direct <- function(block) {
  data <- block$table_data %||% block$data
  options <- block$options %||% list()
  
  if (is.null(data)) {
    return(htmltools::div(style = "color: #999;", "[DataTable placeholder]"))
  }
  
  if (requireNamespace("DT", quietly = TRUE)) {
    tryCatch({
      DT::datatable(data, options = options)
    }, error = function(e) {
      .render_table_block_direct(list(data = data))
    })
  } else {
    .render_table_block_direct(list(data = data))
  }
}


#' Render basic table block
#' @noRd
.render_table_block_direct <- function(block) {
  data <- block$table_object %||% block$data
  caption <- block$caption
  
  if (is.null(data)) {
    return(htmltools::div(style = "color: #999;", "[Table placeholder]"))
  }
  
  # If it's a data frame, render as HTML table
  if (is.data.frame(data)) {
    # Limit rows for preview
    if (nrow(data) > 20) {
      data <- data[1:20, ]
    }
    
    header_row <- htmltools::tags$tr(
      lapply(names(data), function(col) htmltools::tags$th(col))
    )
    
    body_rows <- lapply(1:nrow(data), function(i) {
      htmltools::tags$tr(
        lapply(data[i, ], function(val) htmltools::tags$td(as.character(val)))
      )
    })
    
    htmltools::tagList(
      if (!is.null(caption)) htmltools::tags$caption(caption),
      htmltools::tags$table(
        style = "width: 100%; border-collapse: collapse; margin: 15px 0;",
        htmltools::tags$thead(
          style = "background: #f5f5f5;",
          header_row
        ),
        htmltools::tags$tbody(body_rows)
      )
    )
  } else {
    htmltools::div(style = "color: #999;", "[Table data not available]")
  }
}


#' Render input block
#' @noRd
.render_input_block_direct <- function(block) {
  id <- block$id %||% paste0("input-", sample(100000:999999, 1))
  label <- block$label %||% "Select"
  options <- block$options %||% c()
  
  # Build select element
  select_options <- lapply(options, function(opt) {
    htmltools::tags$option(value = opt, opt)
  })
  
  htmltools::div(
    class = "input-filter-container",
    style = "margin: 15px 0;",
    htmltools::tags$label(`for` = id, style = "display: block; margin-bottom: 5px; font-weight: 500;", label),
    htmltools::tags$select(
      id = id,
      class = "input-filter choices-input",
      multiple = if (isTRUE(block$multiple)) NA else NULL,
      style = "width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;",
      select_options
    )
  )
}


#' Render input row block
#' @noRd
.render_input_row_block_direct <- function(block) {
  inputs <- block$inputs %||% list()
  
  htmltools::div(
    style = "display: flex; gap: 15px; flex-wrap: wrap; margin: 15px 0;",
    lapply(inputs, function(input) {
      htmltools::div(
        style = "flex: 1; min-width: 200px;",
        .render_input_block_direct(input)
      )
    })
  )
}


#' Render modal block
#' @noRd
.render_modal_block_direct <- function(block) {
  id <- block$id %||% paste0("modal-", sample(100000:999999, 1))
  title <- block$title
  content <- block$content %||% block$body %||% ""
  
  htmltools::div(
    id = id,
    class = "modal-overlay",
    htmltools::div(
      class = "modal-content",
      htmltools::span(class = "modal-close", htmltools::HTML("&times;")),
      if (!is.null(title)) htmltools::h3(title),
      htmltools::div(htmltools::HTML(.render_markdown_to_html(content)))
    )
  )
}


#' Quarto-based preview (original implementation)
#' @noRd
.preview_quarto <- function(collection, title, theme, clean, preview_dir = NULL, output_filename = "preview.html", styling = NULL) {
  # Check for Quarto
  quarto_path <- Sys.which("quarto")
  if (quarto_path == "") {
    stop("Quarto is required for quarto=TRUE but was not found on PATH. ",
         "Please install Quarto from https://quarto.org/docs/get-started/ ",
         "or use preview(quarto = FALSE) for direct rendering.", call. = FALSE)
  }

  # Create temp directory for preview if not specified
  if (is.null(preview_dir)) {
    preview_dir <- file.path(tempdir(), paste0("dashboardr_preview_", format(Sys.time(), "%Y%m%d_%H%M%S")))
  }
  dir.create(preview_dir, recursive = TRUE, showWarnings = FALSE)

  # Save data to preview directory
  data_file <- file.path(preview_dir, "data.rds")
  saveRDS(collection$data, data_file)
  
  # Generate custom SCSS if styling provided
  scss_files <- c()
  if (!is.null(styling)) {
    if (!is.null(styling$tabset_theme) && styling$tabset_theme != "none") {
      theme_scss_name <- paste0("tabset_", styling$tabset_theme, ".scss")
      theme_scss_path <- system.file("extdata", "themes", theme_scss_name, package = "dashboardr")
      if (file.exists(theme_scss_path)) {
        file.copy(theme_scss_path, file.path(preview_dir, theme_scss_name), overwrite = TRUE)
        scss_files <- c(scss_files, theme_scss_name)
      }
    }
    
    # Generate custom theme SCSS
    if (!is.null(styling$navbar_bg_color) || !is.null(styling$mainfont)) {
      preview_scss <- .generate_preview_scss(styling)
      writeLines(preview_scss, file.path(preview_dir, "_preview_theme.scss"))
      scss_files <- c(scss_files, "_preview_theme.scss")
    }
  }

  # Process visualizations to group by tabgroup (this creates proper tabset structure)
  # This is the same processing that happens in full dashboard generation
  viz_specs <- .process_visualizations(collection, data_path = "data.rds")
  
  # If no viz specs after processing (e.g., only content blocks), handle gracefully
  if (is.null(viz_specs) || length(viz_specs) == 0) {
    viz_specs <- lapply(collection$items, function(item) {
      item$has_data <- TRUE
      item$data_path <- "data.rds"
      item
    })
  }

  # Generate Quarto document content
  qmd_lines <- c(
    "---",
    paste0("title: \"", title, "\""),
    "format:",
    "  html:"
  )
  
  # Add theme with optional SCSS files
  if (length(scss_files) > 0) {
    qmd_lines <- c(qmd_lines, "    theme:")
    qmd_lines <- c(qmd_lines, paste0("      - ", theme))
    for (scss_file in scss_files) {
      qmd_lines <- c(qmd_lines, paste0("      - ", scss_file))
    }
  } else {
    qmd_lines <- c(qmd_lines, paste0("    theme: ", theme))
  }
  
  qmd_lines <- c(qmd_lines,
    "    self-contained: true",
    "execute:",
    "  echo: false",
    "  warning: false",
    "  message: false",
    "---",
    "",
    "```{r setup, include=FALSE}",
    "library(dashboardr)",
    "library(highcharter)",
    "library(dplyr)",
    "library(tidyr)",
    "",
    "# Load data",
    "data <- readRDS('data.rds')",
    "```",
    ""
  )
  
  # Generate content for all items (content blocks AND visualizations)
  for (item in collection$items) {
    # Check if it's a visualization
    is_viz <- !is.null(item$viz_type) || (!is.null(item$type) && item$type == "viz")
    
    if (!is_viz && !is.null(item$type)) {
      # Generate QMD for content block
      block_qmd <- .generate_block_qmd(item)
      if (!is.null(block_qmd)) {
        qmd_lines <- c(qmd_lines, block_qmd, "")
      }
    }
  }

  # Generate visualization chunks using internal function
  viz_content <- .generate_viz_from_specs(viz_specs, lazy_load_charts = FALSE, lazy_load_tabs = FALSE)
  qmd_lines <- c(qmd_lines, viz_content)

  # Write Quarto document (name based on output filename)
  qmd_basename <- sub("\\.html$", ".qmd", output_filename, ignore.case = TRUE)
  qmd_file <- file.path(preview_dir, qmd_basename)
  writeLines(qmd_lines, qmd_file)

  # Render the document
  html_file <- file.path(preview_dir, output_filename)
  
  old_wd <- getwd()
  on.exit(setwd(old_wd), add = TRUE)
  setwd(preview_dir)
  
  result <- tryCatch({
    system2(quarto_path, args = c("render", qmd_basename), 
            stdout = TRUE, stderr = TRUE)
  }, error = function(e) {
    stop("Failed to render preview: ", e$message, call. = FALSE)
  })
  
  # Check if HTML was generated
  if (!file.exists(html_file)) {
    # Show the error output
    cat("Quarto render output:\n")
    cat(result, sep = "\n")
    stop("Preview rendering failed. Check the output above for errors.", call. = FALSE)
  }

  if (!clean && interactive()) {
    message("Preview files saved to: ", preview_dir)
  }

  html_file
}


#' Wrap a content_block in a content_collection for preview
#' @noRd
.wrap_content_block <- function(block) {
  collection <- create_content()
  collection$items <- list(block)
  collection
}


#' Preview a dashboard_project
#' @noRd
.preview_dashboard_project <- function(proj, title = "Preview", open = TRUE, 
                                        clean = FALSE, quarto = FALSE, 
                                        theme = NULL, path = NULL, page = NULL) {
  
  # Validate project has pages

  if (length(proj$pages) == 0) {
    stop("Dashboard has no pages. Add pages with add_page() before previewing.", call. = FALSE)
  }
  
  # Use dashboard title if not specified
  if (title == "Preview") {
    title <- proj$title %||% "Dashboard Preview"
  }
  
  # Use dashboard theme if not specified
  if (is.null(theme)) {
    theme <- proj$theme %||% "cosmo"
  }
  
  # Filter to specific page if requested
  pages_to_preview <- proj$pages
  if (!is.null(page)) {
    # Case-insensitive page matching
    page_lower <- tolower(page)
    page_names_lower <- tolower(names(proj$pages))
    
    if (!page_lower %in% page_names_lower) {
      available <- paste(names(proj$pages), collapse = ", ")
      stop("Page '", page, "' not found. Available pages: ", available, call. = FALSE)
    }
    
    # Get the actual page name with correct case
    actual_name <- names(proj$pages)[page_names_lower == page_lower]
    pages_to_preview <- proj$pages[actual_name]
    title <- paste("Preview:", actual_name)
  }
  
  # Parse path parameter
  preview_dir <- NULL
  output_filename <- "preview.html"
  
  if (!is.null(path)) {
    path <- normalizePath(path.expand(path), mustWork = FALSE)
    if (grepl("\\.html$", path, ignore.case = TRUE)) {
      preview_dir <- dirname(path)
      output_filename <- basename(path)
    } else {
      preview_dir <- path
    }
    if (!dir.exists(preview_dir)) {
      dir.create(preview_dir, recursive = TRUE, showWarnings = FALSE)
    }
  }
  
  # Create temp directory if not specified
  if (is.null(preview_dir)) {
    preview_dir <- file.path(tempdir(), paste0("dashboardr_preview_", format(Sys.time(), "%Y%m%d_%H%M%S")))
    dir.create(preview_dir, recursive = TRUE, showWarnings = FALSE)
  }
  
  # Use appropriate preview mode
  if (quarto) {
    html_file <- .preview_dashboard_quarto(proj, pages_to_preview, title, theme, 
                                            clean, preview_dir, output_filename)
  } else {
    html_file <- .preview_dashboard_direct(proj, pages_to_preview, title, 
                                            clean, preview_dir, output_filename)
  }
  
  # Open in viewer
  if (open) {
    if (requireNamespace("rstudioapi", quietly = TRUE) && 
        rstudioapi::isAvailable() && 
        rstudioapi::hasFun("viewer")) {
      rstudioapi::viewer(html_file)
    } else {
      utils::browseURL(html_file)
    }
  }
  
  invisible(html_file)
}


#' Preview dashboard using htmltools (direct mode)
#' @noRd
.preview_dashboard_direct <- function(proj, pages, title, clean, preview_dir, output_filename) {
  
  # Build styling from dashboard project
  styling <- .build_preview_styling(proj)
  
  # Build page content
  page_widgets <- list()
  
  for (page_name in names(pages)) {
    page <- pages[[page_name]]
    
    # Page header
    page_header <- htmltools::div(
      style = "margin-top: 40px; margin-bottom: 20px; padding-bottom: 10px; border-bottom: 2px solid #ddd;",
      htmltools::h2(
        style = paste0("margin: 0; color: ", styling$text_color, ";"),
        if (!is.null(page$icon)) htmltools::span(style = "margin-right: 10px;", page$icon) else NULL,
        page_name
      ),
      if (!is.null(page$is_landing_page) && page$is_landing_page) {
        htmltools::span(
          style = "display: inline-block; background: #e3f2fd; color: #1565c0; padding: 2px 8px; border-radius: 4px; font-size: 12px; margin-left: 10px;",
          "Landing Page"
        )
      }
    )
    
    page_widgets[[length(page_widgets) + 1]] <- page_header
    
    # Render page text content
    if (!is.null(page$text) && nzchar(page$text)) {
      text_html <- .render_markdown_to_html(page$text)
      page_widgets[[length(page_widgets) + 1]] <- htmltools::div(
        style = "margin-bottom: 20px;",
        htmltools::HTML(text_html)
      )
    }
    
    # Render content blocks
    if (!is.null(page$content_blocks)) {
      for (block in page$content_blocks) {
        if (is.null(block)) next
        
        block_html <- .render_content_block_direct(block, preview_dir)
        if (!is.null(block_html)) {
          page_widgets[[length(page_widgets) + 1]] <- htmltools::div(
            style = "margin-bottom: 20px;",
            block_html
          )
        }
      }
    }
    
    # Render visualizations if data is available
    if (!is.null(page$visualizations) && !is.null(page$data_path)) {
      # Try to load data and render visualizations
      data_file <- file.path(proj$output_dir %||% ".", page$data_path)
      if (file.exists(data_file)) {
        data <- readRDS(data_file)
        for (viz_spec in page$visualizations) {
          viz_html <- tryCatch({
            .render_viz_direct(viz_spec, data)
          }, error = function(e) {
            htmltools::div(
              style = "padding: 20px; background: #fee; border: 1px solid #c00; border-radius: 4px;",
              htmltools::h4("Error rendering visualization"),
              htmltools::p(e$message)
            )
          })
          
          if (!is.null(viz_spec$title)) {
            viz_html <- htmltools::tagList(
              htmltools::h3(viz_spec$title),
              viz_html
            )
          }
          
          page_widgets[[length(page_widgets) + 1]] <- htmltools::div(
            style = "margin-bottom: 30px;",
            viz_html
          )
        }
      }
    }
  }
  
  # Check if we have interactive elements that need assets
  has_inputs <- .has_interactive_inputs(pages)
  has_modals <- .has_interactive_modals(pages)
  
  # Build the full HTML page
  html_content <- htmltools::tagList(
    htmltools::tags$head(
      htmltools::tags$title(title),
      htmltools::tags$meta(charset = "utf-8"),
      htmltools::tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
      # Include font from Google Fonts if specified
      if (!is.null(proj$mainfont) && proj$mainfont != "system-ui") {
        htmltools::tags$link(
          href = paste0("https://fonts.googleapis.com/css2?family=", gsub(" ", "+", proj$mainfont), ":wght@400;500;600;700&display=swap"),
          rel = "stylesheet"
        )
      },
      # Choices.js for inputs
      if (has_inputs) htmltools::tagList(
        htmltools::tags$link(
          rel = "stylesheet",
          href = "https://cdn.jsdelivr.net/npm/choices.js@10.2.0/public/assets/styles/choices.min.css"
        ),
        htmltools::tags$script(
          src = "https://cdn.jsdelivr.net/npm/choices.js@10.2.0/public/assets/scripts/choices.min.js"
        )
      ),
      htmltools::tags$style(htmltools::HTML(styling$css)),
      # Modal CSS if needed
      if (has_modals) htmltools::tags$style(htmltools::HTML(.get_modal_css()))
    ),
    htmltools::tags$body(
      htmltools::div(
        class = "preview-container",
        htmltools::h1(title),
        htmltools::div(class = "content-wrapper", page_widgets)
      ),
      # Modal JS if needed
      if (has_modals) htmltools::tags$script(htmltools::HTML(.get_modal_js()))
    )
  )
  
  # Save to HTML file
  html_file <- file.path(preview_dir, output_filename)
  htmltools::save_html(html_content, html_file, libdir = "lib")
  
  if (!clean && interactive()) {
    message("Preview files saved to: ", preview_dir)
  }
  
  html_file
}


#' Preview dashboard using Quarto
#' @noRd
.preview_dashboard_quarto <- function(proj, pages, title, theme, clean, preview_dir, output_filename) {
  
  # Check for Quarto
  quarto_path <- Sys.which("quarto")
  if (quarto_path == "") {
    stop("Quarto is required for quarto=TRUE but was not found on PATH. ",
         "Please install Quarto from https://quarto.org/docs/get-started/ ",
         "or use preview(quarto = FALSE) for direct rendering.", call. = FALSE)
  }
  
  # Copy tabset theme SCSS if needed
  if (!is.null(proj$tabset_theme) && proj$tabset_theme != "none") {
    theme_scss_name <- paste0("tabset_", proj$tabset_theme, ".scss")
    theme_scss_path <- system.file("extdata", "themes", theme_scss_name, package = "dashboardr")
    if (file.exists(theme_scss_path)) {
      file.copy(theme_scss_path, file.path(preview_dir, theme_scss_name), overwrite = TRUE)
    }
  }
  
  # Generate theme customization SCSS
  if (!is.null(proj$navbar_bg_color) || !is.null(proj$navbar_text_color) || 
      !is.null(proj$mainfont) || !is.null(proj$fontsize)) {
    theme_scss <- .generate_preview_scss(proj)
    writeLines(theme_scss, file.path(preview_dir, "_preview_theme.scss"))
  }
  
  # Build QMD content
  qmd_lines <- c(
    "---",
    paste0("title: \"", title, "\""),
    "format:",
    "  html:",
    paste0("    theme:"),
    paste0("      - ", theme)
  )
  
  # Add tabset theme if specified
  if (!is.null(proj$tabset_theme) && proj$tabset_theme != "none") {
    theme_scss_name <- paste0("tabset_", proj$tabset_theme, ".scss")
    if (file.exists(file.path(preview_dir, theme_scss_name))) {
      qmd_lines <- c(qmd_lines, paste0("      - ", theme_scss_name))
    }
  }
  
  # Add custom theme SCSS if we generated it
  if (file.exists(file.path(preview_dir, "_preview_theme.scss"))) {
    qmd_lines <- c(qmd_lines, "      - _preview_theme.scss")
  }
  
  qmd_lines <- c(qmd_lines,
    "    self-contained: true",
    "execute:",
    "  echo: false",
    "  warning: false",
    "  message: false",
    "---",
    "",
    "```{r setup, include=FALSE}",
    "library(dashboardr)",
    "library(highcharter)",
    "library(dplyr)",
    "library(tidyr)",
    "```",
    ""
  )
  
  # Generate content for each page
  for (page_name in names(pages)) {
    page <- pages[[page_name]]
    
    qmd_lines <- c(qmd_lines, "", paste0("## ", page_name), "")
    
    # Add text content
    if (!is.null(page$text) && nzchar(page$text)) {
      qmd_lines <- c(qmd_lines, page$text, "")
    }
    
    # Process content blocks and visualizations
    if (!is.null(page$content_blocks)) {
      for (block in page$content_blocks) {
        if (is.null(block)) next
        
        block_qmd <- .generate_block_qmd(block)
        if (!is.null(block_qmd)) {
          qmd_lines <- c(qmd_lines, block_qmd, "")
        }
      }
    }
    
    # Handle visualizations
    if (!is.null(page$visualizations) && !is.null(page$data_path)) {
      # Save data to preview directory
      data_file <- file.path(proj$output_dir %||% ".", page$data_path)
      if (file.exists(data_file)) {
        preview_data_file <- file.path(preview_dir, paste0(page_name, "_data.rds"))
        file.copy(data_file, preview_data_file, overwrite = TRUE)
        
        viz_content <- .generate_viz_from_specs(page$visualizations, 
                                                 lazy_load_charts = FALSE, 
                                                 lazy_load_tabs = FALSE)
        # Replace data path reference
        viz_content <- gsub("data\\.rds", paste0(page_name, "_data.rds"), viz_content)
        qmd_lines <- c(qmd_lines, viz_content)
      }
    }
  }
  
  # Write QMD file
  qmd_basename <- sub("\\.html$", ".qmd", output_filename, ignore.case = TRUE)
  qmd_file <- file.path(preview_dir, qmd_basename)
  writeLines(qmd_lines, qmd_file)
  
  # Render
  html_file <- file.path(preview_dir, output_filename)
  
  old_wd <- getwd()
  on.exit(setwd(old_wd), add = TRUE)
  setwd(preview_dir)
  
  result <- tryCatch({
    system2(quarto_path, args = c("render", qmd_basename), 
            stdout = TRUE, stderr = TRUE)
  }, error = function(e) {
    stop("Failed to render preview: ", e$message, call. = FALSE)
  })
  
  if (!file.exists(html_file)) {
    cat("Quarto render output:\n")
    cat(result, sep = "\n")
    stop("Preview rendering failed. Check the output above for errors.", call. = FALSE)
  }
  
  if (!clean && interactive()) {
    message("Preview files saved to: ", preview_dir)
  }
  
  html_file
}


#' Build CSS styling from dashboard project
#' @noRd
.build_preview_styling <- function(proj) {
  # Default colors
  bg_color <- proj$backgroundcolor %||% "#fafafa"
  text_color <- proj$fontcolor %||% "#333"
  link_color <- proj$linkcolor %||% "#007bff"
  navbar_bg <- proj$navbar_bg_color %||% "#007bff"
  navbar_text <- proj$navbar_text_color %||% "#fff"
  
  # Fonts
  main_font <- proj$mainfont %||% "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
  font_size <- proj$fontsize %||% "16px"
  mono_font <- proj$monofont %||% "Consolas, Monaco, 'Courier New', monospace"
  
  # Max width
  max_width <- proj$max_width %||% "1200px"
  
  css <- paste0("
    body { 
      font-family: ", main_font, ";
      font-size: ", font_size, ";
      background: ", bg_color, ";
      color: ", text_color, ";
      margin: 0;
      padding: 0;
    }
    .preview-container {
      max-width: ", max_width, "; 
      margin: 0 auto; 
      padding: 20px;
    }
    h1 { 
      color: ", navbar_bg, "; 
      border-bottom: 3px solid ", navbar_bg, "; 
      padding-bottom: 15px;
      margin-bottom: 30px;
    }
    h2 { color: ", text_color, "; }
    h3 { color: #555; margin-top: 0; }
    a { color: ", link_color, "; }
    code, pre { 
      font-family: ", mono_font, ";
      background: #f5f5f5;
      padding: 2px 6px;
      border-radius: 3px;
    }
    pre { padding: 15px; overflow-x: auto; }
    .content-wrapper { 
      background: white; 
      padding: 30px; 
      border-radius: 8px; 
      box-shadow: 0 2px 8px rgba(0,0,0,0.1); 
    }
    .callout { 
      padding: 15px 20px; 
      border-left: 4px solid; 
      margin: 15px 0; 
      border-radius: 0 4px 4px 0;
    }
    .callout-note { background: #e3f2fd; border-color: #2196f3; }
    .callout-tip { background: #e8f5e9; border-color: #4caf50; }
    .callout-warning { background: #fff3e0; border-color: #ff9800; }
    .callout-caution { background: #fce4ec; border-color: #e91e63; }
    .callout-important { background: #fbe9e7; border-color: #ff5722; }
    .card { 
      border: 1px solid #ddd; 
      border-radius: 8px; 
      padding: 20px; 
      margin: 15px 0;
      background: white;
    }
    .card-header { font-weight: 600; margin-bottom: 10px; }
    .accordion { margin: 15px 0; }
    .accordion-header { 
      background: #f5f5f5; 
      padding: 12px 15px; 
      cursor: pointer;
      border-radius: 4px;
      font-weight: 500;
    }
    .accordion-content { padding: 15px; display: none; }
    .accordion.open .accordion-content { display: block; }
    .value-box { 
      background: linear-gradient(135deg, ", navbar_bg, " 0%, ", navbar_bg, "dd 100%);
      color: white;
      padding: 20px;
      border-radius: 8px;
      text-align: center;
    }
    .value-box-value { font-size: 2.5em; font-weight: 700; }
    .value-box-label { opacity: 0.9; }
    .badge { 
      display: inline-block;
      padding: 4px 10px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 500;
    }
    .badge-success { background: #4caf50; color: white; }
    .badge-warning { background: #ff9800; color: white; }
    .badge-danger { background: #f44336; color: white; }
    .badge-info { background: #2196f3; color: white; }
    .metric { 
      display: inline-block;
      padding: 15px 25px;
      background: #f5f5f5;
      border-radius: 8px;
      text-align: center;
      margin: 5px;
    }
    .metric-value { font-size: 1.8em; font-weight: 700; color: ", navbar_bg, "; }
    .metric-label { color: #666; font-size: 0.9em; }
    blockquote { 
      border-left: 4px solid ", navbar_bg, ";
      margin: 20px 0;
      padding: 10px 20px;
      background: #f9f9f9;
      font-style: italic;
    }
    .divider { 
      border: none;
      border-top: 1px solid #ddd;
      margin: 20px 0;
    }
    .divider-thick { border-top-width: 3px; }
    .divider-dashed { border-top-style: dashed; }
    .divider-dotted { border-top-style: dotted; }
    img { max-width: 100%; height: auto; }
    .image-caption { 
      text-align: center; 
      color: #666; 
      font-size: 0.9em; 
      margin-top: 8px; 
    }
    iframe { border: none; width: 100%; }
    video { max-width: 100%; }
  ")
  
  list(
    css = css,
    text_color = text_color,
    bg_color = bg_color,
    navbar_bg = navbar_bg
  )
}


#' Generate SCSS for Quarto preview with dashboard styling
#' @noRd
.generate_preview_scss <- function(proj) {
  scss_lines <- c("/*-- scss:rules --*/", "")
  
  # Navbar colors
  if (!is.null(proj$navbar_bg_color)) {
    scss_lines <- c(scss_lines, 
      paste0(".navbar { background-color: ", proj$navbar_bg_color, " !important; }"))
  }
  if (!is.null(proj$navbar_text_color)) {
    scss_lines <- c(scss_lines,
      paste0(".navbar-brand, .nav-link { color: ", proj$navbar_text_color, " !important; }"))
  }
  
  # Font settings
  if (!is.null(proj$mainfont)) {
    scss_lines <- c(scss_lines,
      paste0("body { font-family: '", proj$mainfont, "', sans-serif; }"))
  }
  if (!is.null(proj$fontsize)) {
    scss_lines <- c(scss_lines,
      paste0("body { font-size: ", proj$fontsize, "; }"))
  }
  if (!is.null(proj$fontcolor)) {
    scss_lines <- c(scss_lines,
      paste0("body { color: ", proj$fontcolor, "; }"))
  }
  if (!is.null(proj$linkcolor)) {
    scss_lines <- c(scss_lines,
      paste0("a { color: ", proj$linkcolor, "; }"))
  }
  if (!is.null(proj$backgroundcolor)) {
    scss_lines <- c(scss_lines,
      paste0("body { background-color: ", proj$backgroundcolor, "; }"))
  }
  
  paste(scss_lines, collapse = "\n")
}


#' Check if pages have input elements
#' @noRd
.has_interactive_inputs <- function(pages) {
  for (page in pages) {
    if (!is.null(page$content_blocks)) {
      for (block in page$content_blocks) {
        if (!is.null(block$type) && block$type %in% c("input", "input_row")) {
          return(TRUE)
        }
        # Check nested items in content collections
        if (is_content(block) && !is.null(block$items)) {
          for (item in block$items) {
            if (!is.null(item$type) && item$type %in% c("input", "input_row")) {
              return(TRUE)
            }
          }
        }
      }
    }
  }
  FALSE
}


#' Check if pages have modal elements
#' @noRd
.has_interactive_modals <- function(pages) {
  for (page in pages) {
    if (!is.null(page$content_blocks)) {
      for (block in page$content_blocks) {
        if (!is.null(block$type) && block$type == "modal") {
          return(TRUE)
        }
        if (is_content(block) && !is.null(block$items)) {
          for (item in block$items) {
            if (!is.null(item$type) && item$type == "modal") {
              return(TRUE)
            }
          }
        }
      }
    }
  }
  FALSE
}


#' Get modal CSS for direct preview
#' @noRd
.get_modal_css <- function() {
  "
  .modal-overlay {
    display: none;
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0,0,0,0.7);
    z-index: 1000;
    justify-content: center;
    align-items: center;
  }
  .modal-overlay.active { display: flex; }
  .modal-content {
    background: white;
    padding: 30px;
    border-radius: 12px;
    max-width: 800px;
    max-height: 90vh;
    overflow-y: auto;
    position: relative;
  }
  .modal-close {
    position: absolute;
    top: 10px;
    right: 15px;
    font-size: 24px;
    cursor: pointer;
    color: #666;
  }
  .modal-close:hover { color: #000; }
  "
}


#' Get modal JS for direct preview
#' @noRd
.get_modal_js <- function() {
  "
  document.addEventListener('DOMContentLoaded', function() {
    // Handle modal links
    document.querySelectorAll('a[href^=\"#\"]').forEach(function(link) {
      link.addEventListener('click', function(e) {
        var target = document.querySelector(link.getAttribute('href'));
        if (target && target.classList.contains('modal-overlay')) {
          e.preventDefault();
          target.classList.add('active');
        }
      });
    });
    
    // Close modal on overlay click or close button
    document.querySelectorAll('.modal-overlay').forEach(function(modal) {
      modal.addEventListener('click', function(e) {
        if (e.target === modal || e.target.classList.contains('modal-close')) {
          modal.classList.remove('active');
        }
      });
    });
    
    // Close on escape
    document.addEventListener('keydown', function(e) {
      if (e.key === 'Escape') {
        document.querySelectorAll('.modal-overlay.active').forEach(function(m) {
          m.classList.remove('active');
        });
      }
    });
  });
  "
}


#' Render markdown text to HTML
#' @noRd
#' @param text Markdown text to convert
#' @param toc_safe If TRUE (default), headers are rendered as styled divs 
#'   instead of h1/h2/h3 tags to avoid polluting the document's table of contents
.render_markdown_to_html <- function(text, toc_safe = TRUE) {
  if (requireNamespace("commonmark", quietly = TRUE)) {
    html <- commonmark::markdown_html(text)
    
    # If toc_safe, convert h1-h6 tags to styled divs to avoid TOC pollution
    if (toc_safe) {
      html <- .headers_to_divs(html)
    }
    html
  } else {
    # Basic fallback - use styled divs instead of actual h tags
    if (toc_safe) {
      text <- gsub("^### (.+)$", '<div class="preview-h3" style="font-size: 1.17em; font-weight: bold; margin: 1em 0 0.5em;">\\1</div>', text, perl = TRUE)
      text <- gsub("^## (.+)$", '<div class="preview-h2" style="font-size: 1.5em; font-weight: bold; margin: 1em 0 0.5em;">\\1</div>', text, perl = TRUE)
      text <- gsub("^# (.+)$", '<div class="preview-h1" style="font-size: 2em; font-weight: bold; margin: 0.67em 0;">\\1</div>', text, perl = TRUE)
    } else {
      text <- gsub("^### (.+)$", "<h3>\\1</h3>", text, perl = TRUE)
      text <- gsub("^## (.+)$", "<h2>\\1</h2>", text, perl = TRUE)
      text <- gsub("^# (.+)$", "<h1>\\1</h1>", text, perl = TRUE)
    }
    text <- gsub("\\*\\*(.+?)\\*\\*", "<strong>\\1</strong>", text, perl = TRUE)
    text <- gsub("\\*(.+?)\\*", "<em>\\1</em>", text, perl = TRUE)
    paste0("<p>", gsub("\n\n", "</p><p>", text), "</p>")
  }
}

#' Convert HTML headers to styled divs (for TOC-safe rendering)
#' @noRd
.headers_to_divs <- function(html) {
  # Replace h1-h6 with styled divs that look the same but don't appear in TOC
  html <- gsub('<h1([^>]*)>([^<]*)</h1>', 
               '<div class="preview-h1" style="font-size: 2em; font-weight: bold; margin: 0.67em 0;"\\1>\\2</div>', 
               html, perl = TRUE)
  html <- gsub('<h2([^>]*)>([^<]*)</h2>', 
               '<div class="preview-h2" style="font-size: 1.5em; font-weight: bold; margin: 0.83em 0;"\\1>\\2</div>', 
               html, perl = TRUE)
  html <- gsub('<h3([^>]*)>([^<]*)</h3>', 
               '<div class="preview-h3" style="font-size: 1.17em; font-weight: bold; margin: 1em 0;"\\1>\\2</div>', 
               html, perl = TRUE)
  html <- gsub('<h4([^>]*)>([^<]*)</h4>', 
               '<div class="preview-h4" style="font-size: 1em; font-weight: bold; margin: 1.33em 0;"\\1>\\2</div>', 
               html, perl = TRUE)
  html <- gsub('<h5([^>]*)>([^<]*)</h5>', 
               '<div class="preview-h5" style="font-size: 0.83em; font-weight: bold; margin: 1.67em 0;"\\1>\\2</div>', 
               html, perl = TRUE)
  html <- gsub('<h6([^>]*)>([^<]*)</h6>', 
               '<div class="preview-h6" style="font-size: 0.67em; font-weight: bold; margin: 2.33em 0;"\\1>\\2</div>', 
               html, perl = TRUE)
  html
}


#' Generate QMD content for a content block
#' @noRd
.generate_block_qmd <- function(block) {
  if (is.null(block$type)) return(NULL)
  
  switch(block$type,
    "text" = block$content %||% block$text,
    "callout" = .generate_callout_qmd(block),
    "divider" = "---",
    "code" = paste0("```", block$language %||% "r", "\n", block$code, "\n```"),
    "html" = block$html %||% block$content,
    "quote" = paste0("> ", block$text, if (!is.null(block$citation)) paste0("\n> — ", block$citation) else ""),
    "image" = paste0("![", block$alt %||% "", "](", block$src, ")"),
    NULL
  )
}


#' Generate callout QMD
#' @noRd
.generate_callout_qmd <- function(block) {
  type <- block$callout_type %||% "note"
  title <- block$title %||% ""
  c(
    paste0("::: {.callout-", type, "}"),
    if (nzchar(title)) paste0("## ", title),
    block$text,
    ":::"
  )
}


#' Add "Powered by dashboardr" branding to footer
#'
#' Adds a subtle, sleek "Powered by dashboardr" badge with logo to the bottom-right
#' of the page footer. Integrates seamlessly with existing footer content.
#'
#' @param dashboard A dashboard project created with \code{create_dashboard}
#' @param size Size of the branding: "small" (default), "medium", or "large"
#' @param style Style variant: "default", "minimal", or "badge"
#'
#' @return Updated dashboard project with dashboardr branding in footer
#' @export
#'
#' @examples
#' \dontrun{
#' dashboard <- create_dashboard("my_dash", "My Dashboard") %>%
#'   add_page(name = "Home", text = "Welcome!") %>%
#'   add_powered_by_dashboardr()
#'
#' # With custom size
#' dashboard <- create_dashboard("my_dash") %>%
#'   add_powered_by_dashboardr(size = "medium", style = "badge")
#' }
add_powered_by_dashboardr <- function(dashboard, size = "small", style = "default") {
  if (!inherits(dashboard, "dashboard_project")) {
    stop("First argument must be a dashboard project created with create_dashboard()")
  }

  # Validate inputs
  size <- match.arg(size, c("small", "medium", "large"))
  style <- match.arg(style, c("default", "minimal", "badge"))

  # Define size parameters
  sizes <- list(
    small = list(font_size = "0.75rem", logo_size = "16px", opacity = "0.6"),
    medium = list(font_size = "0.875rem", logo_size = "20px", opacity = "0.7"),
    large = list(font_size = "1rem", logo_size = "24px", opacity = "0.8")
  )

  size_params <- sizes[[size]]

  # Logo URL - use the actual dashboardr logo from GitHub
  logo_url <- "https://raw.githubusercontent.com/favstats/dashboardr/refs/heads/main/man/figures/logo.svg"

  # Create the dashboardr badge HTML based on style
  if (style == "minimal") {
    branding_html <- paste0(
      '<span style="font-size: ', size_params$font_size, '; ',
      'opacity: ', size_params$opacity, '; ',
      'color: inherit; ',
      'font-weight: 400;">',
      'Built with <a href="https://favstats.github.io/dashboardr/" ',
      'style="color: inherit; text-decoration: none; font-weight: 500;" ',
      'target="_blank" rel="noopener">dashboardr</a>',
      '</span>'
    )
  } else if (style == "badge") {
    branding_html <- paste0(
      '<a href="https://favstats.github.io/dashboardr/" ',
      'target="_blank" rel="noopener" ',
      'style="display: inline-flex; align-items: center; gap: 0.35rem; ',
      'padding: 0.25rem 0.5rem; ',
      'background: rgba(0, 0, 0, 0.05); ',
      'border-radius: 4px; ',
      'font-size: ', size_params$font_size, '; ',
      'color: inherit; ',
      'text-decoration: none; ',
      'opacity: ', size_params$opacity, '; ',
      'transition: opacity 0.2s ease, background 0.2s ease;" ',
      'onmouseover="this.style.opacity=\'1\'; this.style.background=\'rgba(0, 0, 0, 0.08)\';" ',
      'onmouseout="this.style.opacity=\'', size_params$opacity, '\'; this.style.background=\'rgba(0, 0, 0, 0.05)\';">',
      '<img src="', logo_url, '" ',
      'alt="dashboardr logo" ',
      'style="width: ', size_params$logo_size, '; height: ', size_params$logo_size, '; ',
      'object-fit: contain;" />',
      '<span style="font-weight: 500;">Powered by dashboardr</span>',
      '</a>'
    )
  } else { # default style
    branding_html <- paste0(
      '<span style="display: inline-flex; align-items: center; gap: 0.35rem; ',
      'font-size: ', size_params$font_size, '; ',
      'opacity: ', size_params$opacity, '; ',
      'color: inherit;">',
      'Powered by ',
      '<a href="https://favstats.github.io/dashboardr/" ',
      'style="display: inline-flex; align-items: center; gap: 0.25rem; ',
      'color: inherit; text-decoration: none; font-weight: 500; ',
      'transition: opacity 0.2s ease;" ',
      'target="_blank" rel="noopener" ',
      'onmouseover="this.style.opacity=\'1\';" ',
      'onmouseout="this.style.opacity=\'', size_params$opacity, '\';">',
      '<img src="', logo_url, '" ',
      'alt="dashboardr logo" ',
      'style="width: ', size_params$logo_size, '; height: ', size_params$logo_size, '; ',
      'object-fit: contain;" />',
      'dashboardr',
      '</a>',
      '</span>'
    )
  }

  # Handle existing footer
  if (is.null(dashboard$page_footer)) {
    # No existing footer - just add branding to right
    dashboard$page_footer <- list(
      structure = "structured",
      right = branding_html
    )
  } else if (is.character(dashboard$page_footer)) {
    # Simple text footer - convert to structured with text on left, branding on right
    dashboard$page_footer <- list(
      structure = "structured",
      left = dashboard$page_footer,
      right = branding_html
    )
  } else if (is.list(dashboard$page_footer) &&
             !is.null(dashboard$page_footer$structure) &&
             dashboard$page_footer$structure == "structured") {
    # Already structured - only add branding if right is empty
    if (is.null(dashboard$page_footer$right) || dashboard$page_footer$right == "") {
      dashboard$page_footer$right <- branding_html
    } else {
      message("Footer right section already occupied. Dashboardr branding not added.")
    }
  } else {
    # Unknown structure - play it safe and just add to right
    dashboard$page_footer <- list(
      structure = "structured",
      right = branding_html
    )
  }

  dashboard
}


# =============================================================================
# knit_print methods for auto-rendering in knitr documents
# =============================================================================

#' Knitr print method for content collections
#'
#' Automatically renders content collections as interactive visualizations
#' when output in knitr documents (vignettes, pkgdown articles, R Markdown).
#' If no data is attached to the collection, shows the structure instead.
#'
#' @param x A content_collection or viz_collection object
#' @param ... Additional arguments (currently ignored)
#'
#' @return A knitr asis_output object containing the rendered HTML
#'
#' @details
#' This method enables "show the viz" behavior in documents while preserving

#' the structure print for console debugging. Simply output a collection with
#' inline data to see the rendered visualization:
#'
#' \preformatted{
#' create_viz(data = mtcars) %>%
#'   add_viz(type = "histogram", x_var = "mpg")
#' # Renders as interactive chart in documents!
#' }
#'
#' @exportS3Method knitr::knit_print
knit_print.content_collection <- function(x, ..., options = NULL) {
  # Check if there are visualizations that need data
  has_viz <- any(sapply(x$items, function(item) {
    !is.null(item$viz_type) || (!is.null(item$type) && item$type == "viz")
  }))
  
  # If no data AND has visualizations, show structure instead
  if (is.null(x$data) && has_viz) {
    # No data but has viz - show structure as formatted text with colors converted to HTML
    old_num_ansi <- getOption("cli.num_colors")
    options(cli.num_colors = 256)  # Enable colors for capture
    on.exit(options(cli.num_colors = old_num_ansi), add = TRUE)
    
    structure_output <- paste(utils::capture.output(print(x)), collapse = "\n")
    
    # Convert ANSI color codes to HTML using fansi
    html_output <- fansi::sgr_to_html(structure_output, classes = TRUE)
    
    # Add CSS for fansi color classes (ANSI 256 color palette)
    css <- "<style>
      .fansi-color-001 { color: #dc2626; }  /* red */
      .fansi-color-002 { color: #16a34a; }  /* green */
      .fansi-color-003 { color: #ca8a04; }  /* yellow */
      .fansi-color-004 { color: #2563eb; }  /* blue */
      .fansi-color-005 { color: #a855f7; }  /* magenta/purple */
      .fansi-color-006 { color: #0891b2; }  /* cyan */
      .fansi-color-007 { color: #f5f5f5; }  /* white */
      .fansi-color-008 { color: #6b7280; }  /* gray/silver */
    </style>"
    
    return(knitr::asis_output(paste0(css, "<pre style='background-color: #f8f9fa; padding: 12px; border-radius: 6px; overflow-x: auto; font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;'><code>", html_output, "</code></pre>")))
  }

  # Check if any items have tabgroups (non-null and non-empty)
  has_tabgroups <- any(sapply(x$items, function(item) {
    !is.null(item$tabgroup) && nchar(item$tabgroup) > 0
  }))

  if (has_tabgroups) {
    # Render with working tabs (charts render visible, then tabs applied)
    html_output <- .render_tabbed_simple(x, options)
  } else {
    # Render stacked (no tabs)
    html_output <- .render_stacked_knitr(x, options)
  }

  # Wrap output in a bordered preview container for visual distinction
  wrapped_output <- htmltools::div(
    style = paste0(
      "border: 2px solid #e1e4e8; ",
      "border-radius: 8px; ",
      "padding: 20px; ",
      "margin: 16px 0; ",
      "background-color: #fafbfc;"
    ),
    htmltools::div(
      style = paste0(
        "font-size: 0.75em; ",
        "color: #6a737d; ",
        "font-weight: 600; ",
        "text-transform: uppercase; ",
        "letter-spacing: 0.5px; ",
        "margin-bottom: 12px; ",
        "padding-bottom: 8px; ",
        "border-bottom: 1px solid #e1e4e8;"
      ),
      "Preview"
    ),
    html_output
  )

  # Use knitr's built-in handling for shiny.tag.list
  knitr::knit_print(wrapped_output, options = options, ...)
}

#' Render a single item to HTML (viz or text content)
#' @noRd
.render_item_html <- function(item, data, options = NULL) {
  item_type <- item$type %||% ""
  
  if (!is.null(item$viz_type) || item_type == "viz") {
    # Visualization
    viz_result <- tryCatch(.render_viz_direct(item, data), error = function(e) NULL)
    if (!is.null(viz_result) && inherits(viz_result, "htmlwidget")) {
      widget_html <- htmlwidgets:::toHTML(viz_result, standalone = FALSE, knitrOptions = options)
      title_html <- if (!is.null(item$title) && nchar(item$title) > 0) {
        htmltools::tags$div(class = "preview-h4", style = "font-size: 1em; font-weight: bold; margin: 10px 0;", item$title)
      } else NULL
      return(htmltools::tagList(title_html, widget_html, htmltools::tags$div(style = "margin-bottom: 15px;")))
    }
    
  } else if (item_type == "text") {
    # Text block
    text_content <- item$text
    if (is.list(text_content)) text_content <- unlist(text_content)
    if (length(text_content) > 0) {
      md_html <- paste(text_content, collapse = "\n\n")
      return(htmltools::tags$div(
        style = "margin: 15px 0;",
        htmltools::HTML(.render_markdown_to_html(md_html))
      ))
    }
    
  } else if (item_type == "callout") {
    # Callout
    callout_type <- item$callout_type %||% "note"
    callout_colors <- list(
      note = list(bg = "#e7f3ff", border = "#0969da", icon = "i"),
      tip = list(bg = "#d4edda", border = "#28a745", icon = "*"),
      warning = list(bg = "#fff3cd", border = "#ffc107", icon = "!"),
      caution = list(bg = "#fff3cd", border = "#fd7e14", icon = "!"),
      important = list(bg = "#f8d7da", border = "#dc3545", icon = "!")
    )
    colors <- callout_colors[[callout_type]] %||% callout_colors$note
    callout_title <- item$title %||% toupper(callout_type)
    callout_text <- item$text
    if (is.list(callout_text)) callout_text <- paste(unlist(callout_text), collapse = " ")
    
    return(htmltools::tags$div(
      style = sprintf("background: %s; border-left: 4px solid %s; padding: 12px 16px; margin: 15px 0; border-radius: 4px;", 
                      colors$bg, colors$border),
      htmltools::tags$strong(paste(colors$icon, callout_title)),
      htmltools::tags$p(style = "margin: 8px 0 0 0;", callout_text)
    ))
    
  } else if (item_type == "divider") {
    return(htmltools::tags$hr(style = "margin: 30px 0; border: 0; border-top: 2px solid #dee2e6;"))
    
  } else if (item_type == "image") {
    img_src <- item$src %||% item$path %||% ""
    img_caption <- item$caption %||% ""
    if (nchar(img_src) > 0) {
      return(htmltools::tags$figure(
        style = "margin: 20px 0; text-align: center;",
        htmltools::tags$img(src = img_src, style = "max-width: 100%; height: auto;", alt = img_caption),
        if (nchar(img_caption) > 0) htmltools::tags$figcaption(style = "color: #6c757d; font-style: italic; margin-top: 8px;", img_caption)
      ))
    }
    
  } else if (item_type == "accordion") {
    acc_title <- item$title %||% "Details"
    acc_text <- item$text
    if (is.list(acc_text)) acc_text <- paste(unlist(acc_text), collapse = " ")
    return(htmltools::tags$details(
      style = "margin: 15px 0; border: 1px solid #dee2e6; border-radius: 4px; padding: 10px;",
      htmltools::tags$summary(style = "cursor: pointer; font-weight: bold;", acc_title),
      htmltools::tags$p(style = "margin: 10px 0 0 0;", acc_text)
    ))
    
  } else if (item_type == "card") {
    card_title <- item$title %||% ""
    card_text <- item$text
    if (is.list(card_text)) card_text <- paste(unlist(card_text), collapse = " ")
    return(htmltools::tags$div(
      style = "background: #f8f9fa; border: 1px solid #dee2e6; border-radius: 8px; padding: 16px; margin: 15px 0;",
      if (nchar(card_title) > 0) htmltools::tags$div(class = "preview-h5", style = "font-size: 0.83em; font-weight: bold; margin: 0 0 10px 0;", card_title),
      htmltools::tags$p(style = "margin: 0;", card_text)
    ))
  }
  
  NULL
}

#' Render stacked content for knitr (visualizations AND text content)
#' @noRd
.render_stacked_knitr <- function(collection, options = NULL) {
  data <- collection$data
  html_parts <- list()
  current_tabgroup <- NULL

  for (item in collection$items) {
    # Add tabgroup header if changed (use div instead of h3 to avoid TOC pollution)
    tabgroup <- item$tabgroup
    if (!is.null(tabgroup) && nchar(tabgroup) > 0 && !identical(tabgroup, current_tabgroup)) {
      html_parts <- c(html_parts, list(
        htmltools::tags$div(
          class = "preview-h3",
          style = "font-size: 1.17em; font-weight: bold; margin-top: 25px; margin-bottom: 15px; padding-bottom: 8px; border-bottom: 2px solid #dee2e6;",
          tabgroup
        )
      ))
      current_tabgroup <- tabgroup
    }

    # Render the item using the helper function
    item_html <- .render_item_html(item, data, options)
    if (!is.null(item_html)) {
      html_parts <- c(html_parts, list(item_html))
    }
  }

  if (length(html_parts) == 0) {
    return(htmltools::HTML("<p>No content to render.</p>"))
  }

  do.call(htmltools::tagList, html_parts)
}

#' Render tabbed widgets - simple approach that works with Highcharts
#' All panes render visible first, then JS hides inactive ones after charts load
#' @noRd
.render_tabbed_simple <- function(collection, options = NULL) {
  data <- collection$data

  # Group items by tabgroup
  groups <- list()
  for (item in collection$items) {
    tabgroup <- item$tabgroup %||% "(ungrouped)"
    if (is.null(groups[[tabgroup]])) groups[[tabgroup]] <- list()
    groups[[tabgroup]] <- c(groups[[tabgroup]], list(item))
  }

  tab_id <- paste0("dtabs-", substr(digest::digest(Sys.time()), 1, 8))

  # Tab buttons
  tab_buttons <- lapply(seq_along(groups), function(i) {
    htmltools::tags$button(
      type = "button",
      class = if (i == 1) "dtab-btn dtab-active" else "dtab-btn",
      `data-tab` = paste0(tab_id, "-", i),
      names(groups)[i]
    )
  })

  # Tab panes - ALL visible initially so Highcharts can render
  tab_panes <- lapply(seq_along(groups), function(i) {
    items <- groups[[names(groups)[i]]]

    pane_content <- lapply(items, function(item) {
      .render_item_html(item, data, options)
    })

    htmltools::tags$div(
      class = "dtab-pane",
      id = paste0(tab_id, "-", i),
      `data-visible` = if (i == 1) "true" else "false",
      pane_content
    )
  })

  # CSS and JS for tabs
  styles <- htmltools::tags$style(htmltools::HTML(sprintf("
    #%s .dtab-btn {
      padding: 8px 16px; margin-right: 4px; border: 1px solid #dee2e6;
      background: #f8f9fa; cursor: pointer; border-radius: 4px 4px 0 0;
    }
    #%s .dtab-btn.dtab-active { background: white; border-bottom-color: white; font-weight: bold; }
    #%s .dtab-pane { padding: 15px 0; }
    #%s .dtab-pane[data-visible='false'] { display: none; }
  ", tab_id, tab_id, tab_id, tab_id)))

  script <- htmltools::tags$script(htmltools::HTML(sprintf("
    (function() {
      // Wait for Highcharts to render, then hide inactive panes
      setTimeout(function() {
        document.querySelectorAll('#%s .dtab-pane[data-visible=\"false\"]').forEach(function(p) {
          p.style.display = 'none';
        });
      }, 500);

      // Tab click handler
      document.querySelectorAll('#%s .dtab-btn').forEach(function(btn) {
        btn.addEventListener('click', function() {
          var tabId = this.getAttribute('data-tab');
          // Update buttons
          document.querySelectorAll('#%s .dtab-btn').forEach(function(b) { b.classList.remove('dtab-active'); });
          this.classList.add('dtab-active');
          // Update panes
          document.querySelectorAll('#%s .dtab-pane').forEach(function(p) {
            p.style.display = p.id === tabId ? 'block' : 'none';
            p.setAttribute('data-visible', p.id === tabId ? 'true' : 'false');
          });
          // Reflow Highcharts
          if (typeof Highcharts !== 'undefined') {
            Highcharts.charts.forEach(function(c) { if (c) c.reflow(); });
          }
        });
      });
    })();
  ", tab_id, tab_id, tab_id, tab_id)))

  htmltools::tagList(
    htmltools::tags$div(
      id = tab_id,
      style = "margin: 20px 0;",
      htmltools::tags$div(class = "dtab-buttons", style = "border-bottom: 1px solid #dee2e6; margin-bottom: 10px;", tab_buttons),
      htmltools::tags$div(class = "dtab-content", tab_panes)
    ),
    styles,
    script
  )
}

#' Render tabbed widgets for knitr using Bootstrap 5 tabs
#' @noRd
.render_tabbed_knitr <- function(collection, options = NULL) {
  data <- collection$data

  # Group items by tabgroup
  groups <- list()
  for (item in collection$items) {
    tabgroup <- item$tabgroup %||% "(no tab)"
    if (is.null(groups[[tabgroup]])) {
      groups[[tabgroup]] <- list()
    }
    groups[[tabgroup]] <- c(groups[[tabgroup]], list(item))
  }

  # Generate unique ID for this tab set
  tab_id <- paste0("tabs-", substr(digest::digest(Sys.time()), 1, 8))

  # Build tab navigation
  nav_items <- lapply(seq_along(groups), function(i) {
    group_name <- names(groups)[i]
    tab_pane_id <- paste0(tab_id, "-", i)
    active_class <- if (i == 1) " active" else ""
    selected <- if (i == 1) "true" else "false"

    htmltools::tags$li(
      class = "nav-item",
      role = "presentation",
      htmltools::tags$button(
        class = paste0("nav-link", active_class),
        id = paste0(tab_pane_id, "-tab"),
        `data-bs-toggle` = "tab",
        `data-bs-target` = paste0("#", tab_pane_id),
        type = "button",
        role = "tab",
        `aria-controls` = tab_pane_id,
        `aria-selected` = selected,
        group_name
      )
    )
  })

  nav_tabs <- htmltools::tags$ul(
    class = "nav nav-tabs",
    id = tab_id,
    role = "tablist",
    nav_items
  )

  # Build tab panes
  panes <- lapply(seq_along(groups), function(i) {
    group_name <- names(groups)[i]
    items <- groups[[group_name]]
    tab_pane_id <- paste0(tab_id, "-", i)
    active_class <- if (i == 1) " show active" else ""

    # Render widgets in this pane
    pane_content <- lapply(items, function(item) {
      viz_result <- tryCatch({
        .render_viz_direct(item, data)
      }, error = function(e) NULL)

      if (!is.null(viz_result) && inherits(viz_result, "htmlwidget")) {
        widget_html <- htmlwidgets:::toHTML(viz_result, standalone = FALSE, knitrOptions = options)
        title_html <- if (!is.null(item$title)) {
          htmltools::tags$div(class = "preview-h4", style = "font-size: 1em; font-weight: bold; margin: 10px 0;", item$title)
        } else NULL

        htmltools::tagList(title_html, widget_html, htmltools::tags$div(style = "margin-bottom: 15px;"))
      } else {
        NULL
      }
    })

    htmltools::tags$div(
      class = paste0("tab-pane fade", active_class),
      id = tab_pane_id,
      role = "tabpanel",
      `aria-labelledby` = paste0(tab_pane_id, "-tab"),
      pane_content
    )
  })

  tab_content <- htmltools::tags$div(
    class = "tab-content",
    id = paste0(tab_id, "-content"),
    panes
  )

  # Include Bootstrap 5 CSS/JS for tabs (from CDN)
  bootstrap_deps <- htmltools::tagList(
    htmltools::tags$link(
      rel = "stylesheet",
      href = "https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css"
    ),
    htmltools::tags$script(
      src = "https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"
    )
  )

  # JavaScript to reflow Highcharts when tabs are shown
  # This is needed because charts in hidden tabs have zero size
  reflow_script <- htmltools::tags$script(htmltools::HTML(sprintf("
    document.addEventListener('DOMContentLoaded', function() {
      // Reflow charts in the first active tab
      setTimeout(function() {
        if (typeof Highcharts !== 'undefined') {
          Highcharts.charts.forEach(function(chart) {
            if (chart) chart.reflow();
          });
        }
      }, 100);

      // Reflow charts when switching tabs
      var tabEl = document.querySelectorAll('#%s button[data-bs-toggle=\"tab\"]');
      tabEl.forEach(function(tab) {
        tab.addEventListener('shown.bs.tab', function(event) {
          setTimeout(function() {
            if (typeof Highcharts !== 'undefined') {
              Highcharts.charts.forEach(function(chart) {
                if (chart) chart.reflow();
              });
            }
          }, 50);
        });
      });
    });
  ", tab_id)))

  htmltools::tagList(
    bootstrap_deps,
    htmltools::tags$div(
      style = "margin: 20px 0;",
      nav_tabs,
      tab_content
    ),
    reflow_script
  )
}

#' @exportS3Method knitr::knit_print
knit_print.viz_collection <- knit_print.content_collection

#' Knitr print method for page objects
#'
#' Automatically renders page objects as interactive content in knitr documents.
#' Converts the page to a content collection and renders it.
#'
#' @param x A page_object
#' @param ... Additional arguments
#' @param options Knitr chunk options
#' @return A knitr asis_output object containing the rendered HTML
#' @exportS3Method knitr::knit_print
knit_print.page_object <- function(x, ..., options = NULL) {
  # Convert page to content collection
  collection <- .page_to_content(x)
  
  # Delegate to content_collection knit_print

  knit_print.content_collection(collection, ..., options = options)
}

#' Knitr print method for dashboard projects
#'
#' Automatically renders dashboard projects as a preview in knitr documents.
#' Shows a combined view of all pages or the landing page.
#'
#' @param x A dashboard_project
#' @param ... Additional arguments
#' @param options Knitr chunk options
#' @return A knitr asis_output object containing the rendered HTML
#' @exportS3Method knitr::knit_print
knit_print.dashboard_project <- function(x, ..., options = NULL) {
  # If no pages, show structure
  if (length(x$pages) == 0) {
    return(knitr::asis_output("<p><em>Dashboard has no pages yet.</em></p>"))
  }
  
  # Render ALL pages with tabs
  page_names <- names(x$pages)
  tab_id <- paste0("dashboard-preview-", sample(1000:9999, 1))
  
  # Build page tabs and content
  page_tabs <- lapply(seq_along(page_names), function(i) {
    page_name <- page_names[i]
    is_active <- i == 1
    htmltools::tags$button(
      class = paste0("dtab-btn", if (is_active) " active" else ""),
      `data-target` = paste0(tab_id, "-page-", i),
      style = paste0(
        "padding: 8px 16px; ",
        "border: none; ",
        "background: ", if (is_active) "#0969da" else "#f1f3f5", "; ",
        "color: ", if (is_active) "white" else "#333", "; ",
        "cursor: pointer; ",
        "border-radius: 4px; ",
        "margin-right: 4px; ",
        "font-size: 0.9em;"
      ),
      page_name
    )
  })
  
  page_contents <- lapply(seq_along(page_names), function(i) {
    page_name <- page_names[i]
    page <- x$pages[[page_name]]
    is_active <- i == 1
    
    # Dashboard pages have different structure than page_objects:
    # - visualizations (list of viz specs)
    # - content_blocks (list of content blocks)
    # - text (raw markdown text)
    # - data_path (path to data, not actual data)
    
    page_html_parts <- list()
    
    # Render text content first
    if (!is.null(page$text) && nzchar(page$text)) {
      page_html_parts <- c(page_html_parts, list(
        htmltools::div(
          style = "margin-bottom: 15px;",
          htmltools::HTML(.render_markdown_to_html(page$text))
        )
      ))
    }
    
    # Render content blocks
    if (!is.null(page$content_blocks) && length(page$content_blocks) > 0) {
      for (block in page$content_blocks) {
        if (is.null(block)) next
        block_html <- .render_content_block_direct(block)
        if (!is.null(block_html)) {
          page_html_parts <- c(page_html_parts, list(block_html))
        }
      }
    }
    
    # Render visualizations (need data from data_path or embedded)
    if (!is.null(page$visualizations) && length(page$visualizations) > 0) {
      # Try to load data if data_path exists
      page_data <- NULL
      if (!is.null(page$data_path)) {
        data_file <- if (is.list(page$data_path)) page$data_path[[1]] else page$data_path
        # Data files are stored in the dashboard's output directory
        if (!is.null(x$output_dir)) {
          full_data_path <- file.path(x$output_dir, data_file)
          if (file.exists(full_data_path)) {
            page_data <- tryCatch(readRDS(full_data_path), error = function(e) NULL)
          }
        }
        # Also try the path directly in case it's already absolute
        if (is.null(page_data) && file.exists(data_file)) {
          page_data <- tryCatch(readRDS(data_file), error = function(e) NULL)
        }
      }
      
      if (!is.null(page_data)) {
        # Create a collection from viz specs and render
        collection <- create_viz(data = page_data)
        collection$items <- page$visualizations
        
        has_tabgroups <- any(sapply(page$visualizations, function(item) {
          !is.null(item$tabgroup) && nchar(item$tabgroup) > 0
        }))
        
        viz_html <- if (has_tabgroups) {
          .render_tabbed_simple(collection, options)
        } else {
          .render_stacked_knitr(collection, options)
        }
        page_html_parts <- c(page_html_parts, list(viz_html))
      } else {
        # No data available - show placeholder
        page_html_parts <- c(page_html_parts, list(
          htmltools::div(
            style = "padding: 20px; background: #f8f9fa; border-radius: 8px; text-align: center; color: #666;",
            htmltools::em(paste0(length(page$visualizations), " visualization(s) - data not available for inline preview"))
          )
        ))
      }
    }
    
    # If nothing to render
    if (length(page_html_parts) == 0) {
      page_html_parts <- list(htmltools::HTML("<p><em>Empty page</em></p>"))
    }
    
    htmltools::tags$div(
      class = "dtab-pane",
      id = paste0(tab_id, "-page-", i),
      `data-visible` = if (is_active) "true" else "false",
      style = if (!is_active) "display: none;" else "",
      do.call(htmltools::tagList, page_html_parts)
    )
  })
  
  # Tab switching JavaScript
  tab_js <- htmltools::tags$script(htmltools::HTML(sprintf("
    (function() {
      var container = document.getElementById('%s');
      if (!container) return;
      var buttons = container.querySelectorAll('.dtab-btn');
      buttons.forEach(function(btn) {
        btn.addEventListener('click', function() {
          var target = this.getAttribute('data-target');
          // Update buttons
          buttons.forEach(function(b) {
            b.classList.remove('active');
            b.style.background = '#f1f3f5';
            b.style.color = '#333';
          });
          this.classList.add('active');
          this.style.background = '#0969da';
          this.style.color = 'white';
          // Update panes
          container.querySelectorAll('.dtab-pane').forEach(function(pane) {
            pane.style.display = 'none';
          });
          var targetPane = document.getElementById(target);
          if (targetPane) targetPane.style.display = 'block';
          // Reflow charts
          setTimeout(function() {
            if (typeof Highcharts !== 'undefined') {
              Highcharts.charts.forEach(function(c) { if (c) c.reflow(); });
            }
          }, 50);
        });
      });
    })();
  ", tab_id)))
  
  # Wrap in preview container
  wrapped_output <- htmltools::div(
    id = tab_id,
    style = paste0(
      "border: 2px solid #e1e4e8; ",
      "border-radius: 8px; ",
      "padding: 20px; ",
      "margin: 16px 0; ",
      "background-color: #fafbfc;"
    ),
    htmltools::div(
      style = paste0(
        "font-size: 0.75em; ",
        "color: #6a737d; ",
        "font-weight: 600; ",
        "text-transform: uppercase; ",
        "letter-spacing: 0.5px; ",
        "margin-bottom: 12px; ",
        "padding-bottom: 8px; ",
        "border-bottom: 1px solid #e1e4e8;"
      ),
      paste0("Dashboard Preview: ", x$title)
    ),
    htmltools::div(
      style = "margin-bottom: 15px;",
      do.call(htmltools::tagList, page_tabs)
    ),
    do.call(htmltools::tagList, page_contents),
    tab_js
  )
  
  knitr::knit_print(wrapped_output, options = options, ...)
}

#' Helper to check if collection has visualizations that need data
#' @noRd
has_viz_needing_data <- function(collection) {
  any(sapply(collection$items, function(item) {
    !is.null(item$viz_type) || (!is.null(item$type) && item$type == "viz")
  }))
}

#' Show collection structure (even with data attached)
#'
#' Forces display of the collection structure instead of rendering visualizations.
#' Useful when you want to inspect the structure of a collection that has data
#' attached, or when documenting the collection's organization.
#'
#' @param x A content_collection or viz_collection object
#' @return In knitr: formatted HTML output. In console: invisible(x) after printing.
#' @export
#'
#' @examples
#' \dontrun{
#' # In a vignette or R Markdown, pipe into print() to see the tree
#' # even when data is attached:
#' create_viz(data = mtcars, type = "bar") %>%
#'   add_viz(x_var = "cyl", title = "Cylinders") %>%
#'   print()
#' }
show_structure <- function(x) {

  # This is an alias for print() - kept for backwards compatibility
  # In knitr context, print() shows structure because it returns invisible(x)
  # which prevents knit_print auto-rendering
  print(x)
}



#' Render a content collection inline as HTML
#'
#' Internal function that generates self-contained HTML for a collection,
#' handling single visualizations, multiple stacked visualizations, and
#' tabgroups using Bootstrap 5 tabs.
#'
#' @param collection A content_collection with data attached
#' @return An htmltools tagList
#' @noRd
.render_collection_inline <- function(collection) {
  data <- collection$data

  if (is.null(data)) {
    return(htmltools::div(
      style = "padding: 10px; background: #fff3cd; border: 1px solid #ffc107; border-radius: 4px;",
      htmltools::p("No data attached to collection. Use create_viz(data = df) to attach data.")
    ))
  }

  # Check if any items have tabgroups (non-null and non-empty)
  has_tabgroups <- any(sapply(collection$items, function(item) {
    !is.null(item$tabgroup) && nchar(item$tabgroup) > 0
  }))

  if (has_tabgroups) {
    # Process visualizations to group by tabgroup
    processed <- .process_visualizations(collection, data_path = NULL)
    return(.render_tabgroup_inline(processed, data))
  } else {
    # No tabgroups - just render items stacked
    return(.render_stacked_inline(collection$items, data))
  }
}


#' Render items stacked (no tabgroups)
#' @noRd
.render_stacked_inline <- function(items, data) {
  viz_widgets <- list()

  for (i in seq_along(items)) {
    item <- items[[i]]

    # Check if this is a viz item
    is_viz <- !is.null(item$viz_type) || (!is.null(item$type) && item$type == "viz")

    if (is_viz) {
      # Render the visualization
      viz_result <- tryCatch({
        .render_viz_direct(item, data)
      }, error = function(e) {
        htmltools::div(
          style = "padding: 10px; background: #f8d7da; border: 1px solid #f5c6cb; border-radius: 4px;",
          htmltools::strong(paste0("Error: ", item$title %||% item$viz_type)),
          htmltools::p(e$message)
        )
      })

      # Add title if present (but minimal - just the chart title, not a wrapper)
      if (!is.null(item$title)) {
        viz_result <- htmltools::tagList(
          htmltools::tags$div(
            class = "preview-h4",
            style = "font-size: 1em; font-weight: 500; color: #333; margin: 0 0 10px 0;",
            item$title
          ),
          viz_result
        )
      }

      viz_widgets[[length(viz_widgets) + 1]] <- htmltools::div(
        style = "margin-bottom: 20px;",
        viz_result
      )
    } else if (!is.null(item$type) && item$type == "text") {
      # Handle text blocks
      viz_widgets[[length(viz_widgets) + 1]] <- htmltools::div(
        style = "margin-bottom: 15px;",
        htmltools::HTML(item$content %||% "")
      )
    }
  }

  htmltools::tagList(viz_widgets)
}


#' Collect widgets from a collection for knitr rendering
#' @noRd
.collect_widgets_for_knitr <- function(collection) {
  data <- collection$data
  widgets <- list()

  for (item in collection$items) {
    # Check if this is a viz item
    is_viz <- !is.null(item$viz_type) || (!is.null(item$type) && item$type == "viz")

    if (is_viz) {
      # Render the visualization
      viz_result <- tryCatch({
        .render_viz_direct(item, data)
      }, error = function(e) {
        NULL
      })

      if (!is.null(viz_result) && inherits(viz_result, "htmlwidget")) {
        # Create title HTML if present
        title_html <- ""
        if (!is.null(item$title)) {
          title_html <- paste0("<h4 style='margin: 0 0 10px 0; font-weight: 500; color: #333;'>",
                               htmltools::htmlEscape(item$title), "</h4>")
        }
        widgets[[length(widgets) + 1]] <- list(title = title_html, widget = viz_result)
      }
    }
  }

  widgets
}


#' Render collection for knitr output with proper widget dependencies
#' @noRd
.render_collection_for_knitr <- function(collection) {
  data <- collection$data

  if (is.null(data)) {
    return(knitr::asis_output(
      "<div style='padding: 10px; background: #fff3cd; border: 1px solid #ffc107; border-radius: 4px;'>
       <p>No data attached to collection. Use create_viz(data = df) to attach data.</p>
       </div>"
    ))
  }

  # Collect all widgets
  widgets <- list()
  html_parts <- list()

  for (i in seq_along(collection$items)) {
    item <- collection$items[[i]]

    # Check if this is a viz item
    is_viz <- !is.null(item$viz_type) || (!is.null(item$type) && item$type == "viz")

    if (is_viz) {
      # Render the visualization - this returns an htmlwidget
      viz_result <- tryCatch({
        .render_viz_direct(item, data)
      }, error = function(e) {
        NULL
      })

      if (!is.null(viz_result) && inherits(viz_result, "htmlwidget")) {
        # Add title if present
        title_html <- ""
        if (!is.null(item$title)) {
          title_html <- paste0("<h4 style='margin: 0 0 10px 0; font-weight: 500; color: #333;'>",
                               htmltools::htmlEscape(item$title), "</h4>")
        }

        # Store the widget and its title
        widgets[[length(widgets) + 1]] <- list(
          title = title_html,
          widget = viz_result
        )
      }
    } else if (!is.null(item$type) && item$type == "text") {
      # Text blocks - add as HTML
      html_parts[[length(html_parts) + 1]] <- htmltools::div(
        style = "margin-bottom: 15px;",
        htmltools::HTML(item$content %||% "")
      )
    }
  }

  # If we have widgets, render them one by one with knitr::knit_print
  if (length(widgets) > 0) {
    # Create a tagList that includes widgets properly
    # Each widget will be rendered with its dependencies
    result_list <- list()

    for (w in widgets) {
      result_list[[length(result_list) + 1]] <- htmltools::div(
        style = "margin-bottom: 20px;",
        htmltools::HTML(w$title),
        w$widget
      )
    }

    # Also add any text parts
    for (hp in html_parts) {
      result_list[[length(result_list) + 1]] <- hp
    }

    # Return as a browsable tagList - this tells knitr to handle dependencies
    output <- htmltools::tagList(result_list)
    htmltools::browsable(output)
  } else if (length(html_parts) > 0) {
    knitr::asis_output(as.character(htmltools::tagList(html_parts)))
  } else {
    knitr::asis_output("<p>No content to render.</p>")
  }
}


#' Render tabgroups using Bootstrap 5 tabs
#' @noRd
.render_tabgroup_inline <- function(processed_specs, data) {
  # Generate unique ID for this tabset
  tabset_id <- paste0("tabs_", substr(digest::digest(Sys.time()), 1, 8))

  # Check structure of processed_specs
  # If it's a list with type = "tabgroup", it's a single tabgroup
  # Otherwise it might be multiple items

  all_widgets <- list()

  for (spec in processed_specs) {
    if (!is.null(spec$type) && spec$type == "tabgroup") {
      # This is a tabgroup - render as Bootstrap tabs
      tabgroup_html <- .render_single_tabgroup(spec, data, tabset_id)
      all_widgets[[length(all_widgets) + 1]] <- tabgroup_html
    } else if (!is.null(spec$viz_type) || (!is.null(spec$type) && spec$type == "viz")) {
      # Single viz without tabgroup
      viz_result <- tryCatch({
        .render_viz_direct(spec, data)
      }, error = function(e) {
        htmltools::div(
          style = "padding: 10px; background: #f8d7da; border: 1px solid #f5c6cb; border-radius: 4px;",
          htmltools::p(e$message)
        )
      })

      if (!is.null(spec$title)) {
        viz_result <- htmltools::tagList(
          htmltools::tags$div(class = "preview-h4", style = "font-size: 1em; font-weight: 500; margin: 0 0 10px 0;", spec$title),
          viz_result
        )
      }

      all_widgets[[length(all_widgets) + 1]] <- htmltools::div(
        style = "margin-bottom: 20px;",
        viz_result
      )
    }
  }

  # Add Bootstrap tab JavaScript (for when not in a Bootstrap page)
  bootstrap_js <- htmltools::tags$script(htmltools::HTML("
    document.addEventListener('DOMContentLoaded', function() {
      // Bootstrap 5 tab activation
      var tabElems = document.querySelectorAll('[data-bs-toggle=\"tab\"]');
      tabElems.forEach(function(tabElem) {
        tabElem.addEventListener('click', function(e) {
          e.preventDefault();
          var target = this.getAttribute('href') || this.getAttribute('data-bs-target');
          // Deactivate all tabs in this group
          var tabList = this.closest('.nav-tabs');
          tabList.querySelectorAll('.nav-link').forEach(function(link) {
            link.classList.remove('active');
          });
          // Activate clicked tab
          this.classList.add('active');
          // Hide all panes
          var tabContent = tabList.nextElementSibling;
          if (tabContent && tabContent.classList.contains('tab-content')) {
            tabContent.querySelectorAll('.tab-pane').forEach(function(pane) {
              pane.classList.remove('show', 'active');
            });
            // Show target pane
            var targetPane = tabContent.querySelector(target);
            if (targetPane) {
              targetPane.classList.add('show', 'active');
            }
          }
        });
      });
    });
  "))

  htmltools::tagList(all_widgets, bootstrap_js)
}


#' Render a single tabgroup as Bootstrap tabs
#' @noRd
.render_single_tabgroup <- function(tabgroup_spec, data, base_id) {
  visualizations <- tabgroup_spec$visualizations %||% list()

  if (length(visualizations) == 0) {
    return(htmltools::div())
  }

  # Generate tab IDs
  tab_ids <- paste0(base_id, "_", seq_along(visualizations))

  # Build tab navigation
  nav_items <- list()
  for (i in seq_along(visualizations)) {
    viz <- visualizations[[i]]
    tab_label <- viz$title_tabset %||% viz$title %||% paste0("Tab ", i)
    is_active <- (i == 1)

    nav_items[[i]] <- htmltools::tags$li(
      class = "nav-item",
      htmltools::tags$a(
        class = paste("nav-link", if (is_active) "active" else ""),
        `data-bs-toggle` = "tab",
        href = paste0("#", tab_ids[i]),
        role = "tab",
        tab_label
      )
    )
  }

  # Build tab panes
  tab_panes <- list()
  for (i in seq_along(visualizations)) {
    viz <- visualizations[[i]]
    is_active <- (i == 1)

    # Check if this viz has nested children (nested tabgroups)
    if (!is.null(viz$nested_children) && length(viz$nested_children) > 0) {
      # Recursively render nested tabgroups
      pane_content <- .render_tabgroup_inline(viz$nested_children, data)
    } else {
      # Render the visualization
      pane_content <- tryCatch({
        .render_viz_direct(viz, data)
      }, error = function(e) {
        htmltools::div(
          style = "padding: 10px; background: #f8d7da; border: 1px solid #f5c6cb; border-radius: 4px;",
          htmltools::p(e$message)
        )
      })
    }

    tab_panes[[i]] <- htmltools::div(
      class = paste("tab-pane fade", if (is_active) "show active" else ""),
      id = tab_ids[i],
      role = "tabpanel",
      style = "padding: 15px 0;",
      pane_content
    )
  }

  # Add header if tabgroup has a name (top-level tabgroup)
  header <- NULL
  if (!is.null(tabgroup_spec$name) && nchar(tabgroup_spec$name) > 0) {
    header <- htmltools::tags$div(
      class = "preview-h3",
      style = "font-size: 1.17em; font-weight: 500; color: #333; margin: 0 0 15px 0;",
      tabgroup_spec$name
    )
  }

  # Combine into tabset
  htmltools::div(
    style = "margin-bottom: 25px;",
    header,
    htmltools::tags$ul(
      class = "nav nav-tabs",
      role = "tablist",
      style = "border-bottom: 1px solid #dee2e6; margin-bottom: 0;",
      nav_items
    ),
    htmltools::div(
      class = "tab-content",
      tab_panes
    )
  )
}

