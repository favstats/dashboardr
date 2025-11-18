# =================================================================
# viz_collection
# =================================================================


#' Create a new visualization collection
#'
#' Initializes an empty collection for building up multiple visualizations
#' using the piping workflow. Optionally accepts custom display labels for
#' tab groups and default parameters that apply to all visualizations.
#'
#' @param tabgroup_labels Named vector/list mapping tabgroup IDs to display names
#' @param ... Default parameters to apply to all subsequent add_viz() calls.
#'   Any parameter specified in add_viz() will override the default.
#'   Useful for setting common parameters like type, color_palette, stacked_type, etc.
#' @return A viz_collection object
#' @export
#' @examples
#' \dontrun{
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
create_viz <- function(tabgroup_labels = NULL, ...) {
  defaults <- list(...)

  structure(list(
    items = list(),  # Unified storage for all content
    tabgroup_labels = tabgroup_labels,
    defaults = defaults
  ), class = c("content_collection", "viz_collection"))  # Both classes for backward compat
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
    standard_names <- c("items", "tabgroup_labels", "defaults", "class")
    extra_attrs <- setdiff(names(col), standard_names)
    for (attr_name in extra_attrs) {
      combined_attrs[[attr_name]] <- col[[attr_name]]
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
add_viz <- function(viz_collection, type = NULL, ..., tabgroup = NULL, title = NULL, title_tabset = NULL, text = NULL, icon = NULL, text_position = NULL, text_before_tabset = NULL, text_after_tabset = NULL, text_before_viz = NULL, text_after_viz = NULL, height = NULL, filter = NULL, data = NULL, drop_na_vars = FALSE) {
  # Validate first argument
  if (!is_content(viz_collection)) {
    stop("First argument must be a content collection")
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
  supported_types <- c("stackedbar", "stackedbars", "heatmap", "histogram", "timeline", "bar", "scatter")

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

  # Validate data parameter
  if (!is.null(data)) {
    if (!is.character(data) || length(data) != 1 || nchar(data) == 0) {
      stop("data must be a non-empty character string (dataset name) or NULL")
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
#' @export
print.viz_collection <- function(x, ...) {
  total <- length(x$items)
  
  # Check if this is a content collection or viz collection
  is_content_collection <- inherits(x, "content_collection")
  
  cat("\n")
  cat("╔══════════════════════════════════════════════════════════════════════════\n")
  if (is_content_collection) {
    cat("║ 📦 CONTENT COLLECTION\n")
  } else {
    cat("║ 📊 VISUALIZATION COLLECTION\n")
  }
  cat("╠══════════════════════════════════════════════════════════════════════════\n")
  if (is_content_collection) {
    cat("║ Total items: ", total, "\n", sep = "")
  } else {
    cat("║ Total visualizations: ", total, "\n", sep = "")
  }

  if (total == 0) {
    cat("║ (empty collection)\n")
    cat("╚══════════════════════════════════════════════════════════════════════════\n\n")
    return(invisible(x))
  }

  # Build hierarchical tree structure
  tree <- list()
  for (i in seq_along(x$items)) {
    v <- x$items[[i]]
    path <- if (is.null(v$tabgroup)) {
      c("(no tabgroup)")
    } else if (is.character(v$tabgroup) && length(v$tabgroup) > 0) {
      v$tabgroup
    } else {
      c("(no tabgroup)")
    }

    # Build path string for direct access
    if (length(path) == 1) {
      # Single level
      level_name <- path[1]
      if (is.null(tree[[level_name]])) {
        tree[[level_name]] <- list(.items = list(), .children = list())
      }
      tree[[level_name]]$.items[[length(tree[[level_name]]$.items) + 1]] <- v
    } else {
      # Multiple levels - build nested structure
      # First ensure all intermediate levels exist
      for (j in seq_len(length(path) - 1)) {
        level_path <- path[1:j]

        # Navigate to this level and ensure it exists
        if (j == 1) {
          if (is.null(tree[[level_path[1]]])) {
            tree[[level_path[1]]] <- list(.items = list(), .children = list())
          }
        } else {
          # Build nested access
          current <- tree[[level_path[1]]]$.children
          for (k in 2:(j-1)) {
            current <- current[[level_path[k]]]$.children
          }
          if (is.null(current[[level_path[j]]])) {
            current[[level_path[j]]] <- list(.items = list(), .children = list())
          }
        }
      }

      # Now add the item at the final level
      if (length(path) == 2) {
        # Two levels: tree[[path[1]]]$.children[[path[2]]]
        if (is.null(tree[[path[1]]]$.children[[path[2]]])) {
          tree[[path[1]]]$.children[[path[2]]] <- list(.items = list(), .children = list())
        }
        tree[[path[1]]]$.children[[path[2]]]$.items[[
          length(tree[[path[1]]]$.children[[path[2]]]$.items) + 1
        ]] <- v
      } else if (length(path) == 3) {
        # Three levels
        if (is.null(tree[[path[1]]]$.children[[path[2]]]$.children[[path[3]]])) {
          tree[[path[1]]]$.children[[path[2]]]$.children[[path[3]]] <- list(.items = list(), .children = list())
        }
        tree[[path[1]]]$.children[[path[2]]]$.children[[path[3]]]$.items[[
          length(tree[[path[1]]]$.children[[path[2]]]$.children[[path[3]]]$.items) + 1
        ]] <- v
      } else {
        # More than 3 levels - iterate (rare case)
        eval_str <- paste0("tree[[\"", path[1], "\"]]")
        for (j in 2:length(path)) {
          eval_str <- paste0(eval_str, "$.children[[\"", path[j], "\"]]")
        }
        eval_str_items <- paste0(eval_str, "$.items")

        # Ensure path exists
        if (is.null(eval(parse(text = eval_str)))) {
          assign_str <- paste0(eval_str, " <- list(.items = list(), .children = list())")
          eval(parse(text = assign_str))
        }

        # Add item
        current_items <- eval(parse(text = eval_str_items))
        current_items[[length(current_items) + 1]] <- v
        assign_str <- paste0(eval_str_items, " <- current_items")
        eval(parse(text = assign_str))
      }
    }
  }

  # Print tree recursively
  .print_tree_level <- function(node, prefix = "║ ", is_last_sibling = TRUE, parent_prefix = "║ ") {
    if (length(node) == 0) return()

    node_names <- setdiff(names(node), c(".items", ".children"))

    for (i in seq_along(node_names)) {
      name <- node_names[i]
      is_last <- (i == length(node_names))

      # Draw branch
      if (is_last) {
        cat(prefix, "└─ 📁 ", name, "\n", sep = "")
        new_prefix <- paste0(prefix, "   ")
      } else {
        cat(prefix, "├─ 📁 ", name, "\n", sep = "")
        new_prefix <- paste0(prefix, "│  ")
      }

      # Print items at this level
      items <- node[[name]]$.items
      children <- node[[name]]$.children

      has_children <- length(children) > 0

      if (length(items) > 0) {
        for (j in seq_along(items)) {
          v <- items[[j]]
          is_last_item <- (j == length(items)) && !has_children

          # Get visualization/content details
          # Check if this is a content block (has type field) or a visualization (has viz_type field)
          if (!is.null(v$type)) {
            # This is a content block or special marker
            type_icon <- switch(v$type,
              "pagination" = "📄",
              "text" = "📝",
              "image" = "🖼️",
              "video" = "🎥",
              "callout" = "💬",
              "divider" = "➖",
              "code" = "💻",
              "spacer" = "⬜",
              "gt" = "📋",
              "reactable" = "📋",
              "table" = "📋",
              "DT" = "📋",
              "iframe" = "🌐",
              "accordion" = "📂",
              "card" = "🗂️",
              "html" = "🔧",
              "quote" = "💭",
              "badge" = "🏷️",
              "metric" = "📊",
              "value_box" = "📦",
              "value_box_row" = "📦",
              "📄"  # default icon
            )
            
            type_label <- toupper(v$type)
            title_text <- if (!is.null(v$title)) paste0(": ", v$title) else ""
            filter_text <- ""
            badge_text <- ""
          } else if (!is.null(v$viz_type)) {
            # This is a visualization
            type_icon <- switch(v$viz_type,
              "timeline" = "📈",
              "stackedbar" = "📊",
              "stackedbars" = "📊",
              "heatmap" = "🗺️",
              "histogram" = "📉",
              "bar" = "📊",
              "scatter" = "📍",
              "📊"
            )

            type_label <- toupper(v$viz_type)
            title_text <- if (!is.null(v$title)) paste0(": ", v$title) else ""
            filter_text <- if (!is.null(v$filter)) " [filtered]" else ""

            # Add badges for text positioning
            text_badges <- c()
            if (!is.null(v$text_before_tabset) && nzchar(v$text_before_tabset)) {
              text_badges <- c(text_badges, "text-before-tabset")
            }
            if (!is.null(v$text_after_tabset) && nzchar(v$text_after_tabset)) {
              text_badges <- c(text_badges, "text-after-tabset")
            }
            if (!is.null(v$text_before_viz) && nzchar(v$text_before_viz)) {
              text_badges <- c(text_badges, "text-before-viz")
            }
            if (!is.null(v$text_after_viz) && nzchar(v$text_after_viz)) {
              text_badges <- c(text_badges, "text-after-viz")
            }

            badge_text <- if (length(text_badges) > 0) {
              paste0(" [", paste(text_badges, collapse = ", "), "]")
            } else {
              ""
            }
          } else {
            # Unknown item type
            type_icon <- "❓"
            type_label <- "UNKNOWN"
            title_text <- ""
            filter_text <- ""
            badge_text <- ""
          }

          if (is_last_item) {
            cat(new_prefix, "└─ ", type_icon, " ", type_label, title_text, filter_text, badge_text, "\n", sep = "")
          } else {
            cat(new_prefix, "├─ ", type_icon, " ", type_label, title_text, filter_text, badge_text, "\n", sep = "")
          }
        }
      }

      # Recursively print children
      if (has_children) {
        .print_tree_level(children, new_prefix, TRUE, new_prefix)
      }
    }
  }

  cat("║\n")
  cat("║ STRUCTURE:\n")
  .print_tree_level(tree, "║ ")

  cat("╚══════════════════════════════════════════════════════════════════════════\n\n")
  invisible(x)
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

