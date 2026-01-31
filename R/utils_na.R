#' Handle NA Values in Survey Data
#'
#' @param data Data frame
#' @param var_name String. Column name to process
#' @param include_na Logical. Treat NAs as explicit category?
#' @param na_label String. Label for NA values
#' @param custom_order Optional character vector for ordering
#'
#' @return Factor vector with processed values
#' @keywords internal
handle_na_for_plotting <- function(data, var_name, include_na = FALSE,
                                   na_label = "(Missing)",
                                   custom_order = NULL) {

  # Get the column data
  col_data <- data[[var_name]]
  
  # Check if it's already a factor and preserve its levels if no custom_order
  is_factor <- is.factor(col_data)

  existing_levels <- if (is_factor) levels(col_data) else NULL
  
  # Check if original data is numeric BEFORE character conversion

  # This ensures we sort numerically even for edge cases (scientific notation, etc.)
  is_originally_numeric <- is.numeric(col_data) && !is_factor
  
  # Convert to character for manipulation
  temp_var <- as.character(col_data)

  # Helper function to sort values (numeric or alphabetic)
  sort_values <- function(vals) {
    if (length(vals) == 0) return(vals)
    
    if (is_originally_numeric) {
      # Original column was numeric - sort using original numeric values
      # Match back to original data for proper numeric sorting
      numeric_vals <- unique(col_data[!is.na(col_data)])
      return(as.character(sort(numeric_vals)))
    } else if (all(grepl("^-?[0-9]+(\\.[0-9]+)?$", vals))) {
      # String values that look numeric - parse and sort numerically
      return(as.character(sort(as.numeric(vals))))
    } else {
      # Non-numeric - sort alphabetically
      return(sort(vals))
    }
  }

  if (include_na) {
    # Replace NA with custom label
    if (any(is.na(temp_var))) {
      temp_var[is.na(temp_var)] <- na_label
    }

    # Get unique values
    unique_vals <- unique(temp_var)

    if (!is.null(custom_order)) {
      # Use custom order if provided (overrides existing factor levels)
      if (!na_label %in% custom_order && na_label %in% unique_vals) {
        custom_order <- c(custom_order, na_label)
      }
      valid_order <- custom_order[custom_order %in% unique_vals]
      remaining <- setdiff(unique_vals, valid_order)
      levels <- c(valid_order, remaining)
    } else if (!is.null(existing_levels)) {
      # Preserve existing factor levels and add NA label at end if needed
      if (na_label %in% unique_vals && !na_label %in% existing_levels) {
        levels <- c(existing_levels, na_label)
      } else {
        levels <- existing_levels
      }
      # Add any new values not in original levels
      remaining <- setdiff(unique_vals, levels)
      if (length(remaining) > 0) {
        levels <- c(levels, remaining)
      }
    } else {
      # Auto-order with NA label at end
      unique_vals_no_na <- setdiff(unique_vals, na_label)

      # Sort values (numerically if originally numeric, otherwise alphabetically)
      unique_vals_no_na <- sort_values(unique_vals_no_na)

      # Put NA label at the end
      levels <- if (na_label %in% unique_vals) {
        c(unique_vals_no_na, na_label)
      } else {
        unique_vals_no_na
      }
    }

    result <- factor(temp_var, levels = levels)
  } else {
    # Standard factor conversion
    if (!is.null(custom_order)) {
      # Use custom order if explicitly provided
      result <- factor(temp_var, levels = custom_order)
    } else if (!is.null(existing_levels)) {
      # Preserve existing factor levels
      result <- factor(temp_var, levels = existing_levels)
    } else {
      # Create factor with proper ordering
      unique_vals <- unique(temp_var[!is.na(temp_var)])
      sorted_levels <- sort_values(unique_vals)
      result <- factor(temp_var, levels = sorted_levels)
    }
  }

  return(result)
}


#' Validate NA Handling Parameters
#' 
#' @param include_na Logical. Whether to include NAs
#' @param na_label Character. Label for NA values
#' @param param_name Character. Name of parameter for error messages
#' 
#' @return Validated na_label
#' @keywords internal
validate_na_params <- function(include_na, na_label, param_name = "na_label") {
  if (!is.logical(include_na)) {
    stop("`include_na` must be logical (TRUE/FALSE)", call. = FALSE)
  }

  if (!is.character(na_label) || length(na_label) != 1) {
    stop(paste0("`", param_name, "` must be a single character string"),
         call. = FALSE)
  }

  if (na_label == "") {
    warning(paste0("`", param_name, "` is empty string - using '(Missing)' instead"),
            call. = FALSE)
    na_label <- "(Missing)"
  }

  return(na_label)
}

