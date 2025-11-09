#' Handle NA Values in Survey Data
#'
#' @param data Data frame
#' @param var_name String. Column name to process
#' @param include_na Logical. Treat NAs as explicit category?
#' @param na_label String. Label for NA values
#' @param custom_order Optional character vector for ordering
#'
#' @return Data frame with processed column
#' @keywords internal
handle_na_for_plotting <- function(data, var_name, include_na = FALSE,
                                   na_label = "(Missing)",
                                   custom_order = NULL) {

  # Get the column data and convert to character
  col_data <- data[[var_name]]
  temp_var <- as.character(col_data)

  if (include_na) {
    # Replace NA with custom label
    if (any(is.na(temp_var))) {
      temp_var[is.na(temp_var)] <- na_label
    }

    # Get unique values
    unique_vals <- unique(temp_var)

    if (!is.null(custom_order)) {
      # Use custom order if provided
      if (!na_label %in% custom_order && na_label %in% unique_vals) {
        custom_order <- c(custom_order, na_label)
      }
      valid_order <- custom_order[custom_order %in% unique_vals]
      remaining <- setdiff(unique_vals, valid_order)
      levels <- c(valid_order, remaining)
    } else {
      # Auto-order with NA label at end
      unique_vals_no_na <- setdiff(unique_vals, na_label)

      # Sort numeric-like strings numerically if possible
      if (all(grepl("^-?[0-9]+(\\.[0-9]+)?$", unique_vals_no_na))) {
        # All values are numeric, sort numerically
        unique_vals_no_na <- as.character(sort(as.numeric(unique_vals_no_na)))
      } else {
        # Contains non-numeric values, sort alphabetically
        unique_vals_no_na <- sort(unique_vals_no_na)
      }

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
      result <- factor(temp_var, levels = custom_order)
    } else {
      result <- factor(temp_var)
    }
  }

  return(result)
}


#' Validate NA Handling Parameters
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
