# =================================================================
# nse_helpers
# =================================================================

.capture_nse_defaults <- function(dot_args_raw,
                                  call_env,
                                  var_params,
                                  var_vector_params = character()) {
  if (is.null(dot_args_raw)) {
    return(list())
  }

  defaults <- lapply(names(dot_args_raw), function(nm) {
    val <- dot_args_raw[[nm]]

    if (nm %in% var_params && is.symbol(val)) {
      # Single column params use NSE symbol -> string conversion.
      as.character(val)
    } else if (nm %in% var_vector_params) {
      # Vector params evaluate to actual values.
      if (is.call(val) && identical(val[[1]], as.symbol("c"))) {
        vapply(as.list(val)[-1], function(x) {
          if (is.symbol(x)) {
            as.character(x)
          } else if (is.character(x)) {
            x
          } else {
            eval(x, envir = call_env)
          }
        }, character(1))
      } else {
        eval(val, envir = call_env)
      }
    } else {
      eval(val, envir = call_env)
    }
  })

  names(defaults) <- names(dot_args_raw)
  defaults
}

.default_viz_var_params <- function() {
  c(
    "x_var", "y_var", "group_var", "stack_var", "weight_var",
    "time_var", "region_var", "value_var", "color_var", "size_var",
    "join_var", "click_var", "subgroup_var", "from_var", "to_var",
    "low_var", "high_var"
  )
}

.default_page_var_params <- function() {
  c(
    "x_var", "y_var", "group_var", "stack_var",
    "region_var", "value_var", "color_var", "size_var",
    "join_var", "click_var", "subgroup_var"
  )
}

.default_vector_var_params <- function() {
  c("x_vars", "tooltip_vars")
}
