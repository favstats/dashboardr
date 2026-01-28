# Package startup messages and checks

.onAttach <- function(libname, pkgname) {

  # Check if gssr is installed (needed for tutorials/demos)
  if (!requireNamespace("gssr", quietly = TRUE)) {
    packageStartupMessage(
      "Note: The 'gssr' package is needed for tutorials and demos.\n",
      "Install it with:\n",
      "  install.packages('gssr', repos = c('https://kjhealy.r-universe.dev', 'https://cloud.r-project.org'))"
    )
  }
}

#' Check Quarto version
#' 
#' @description Internal function to check if Quarto >= 1.4 is installed
#' @return TRUE if Quarto >= 1.4 is available, FALSE otherwise (with warning)
#' @keywords internal
check_quarto_version <- function() {
  # Check if quarto is available
  quarto_path <- Sys.which("quarto")
  if (quarto_path == "") {
    warning(
      "Quarto is not installed or not found in PATH.\n",
      "Rendering requires Quarto >= 1.4\n",
      "Download Quarto from: https://quarto.org/docs/download/",
      call. = FALSE
    )
    return(FALSE)
  }
  
  # Get version
  tryCatch({
    version_output <- system2("quarto", "--version", stdout = TRUE, stderr = TRUE)
    version_str <- version_output[1]
    
    # Parse version (e.g., "1.4.553" -> c(1, 4, 553))
    version_parts <- as.numeric(strsplit(version_str, "\\.")[[1]])
    major <- version_parts[1]
    minor <- version_parts[2]
    
    if (major < 1 || (major == 1 && minor < 4)) {
      warning(
        "Quarto version ", version_str, " is installed, but rendering requires Quarto >= 1.4\n",
        "Please update Quarto from: https://quarto.org/docs/download/",
        call. = FALSE
      )
      return(FALSE)
    }
    
    TRUE
  }, error = function(e) {
    # If we can't check version, just warn and continue
    warning("Could not verify Quarto version. Rendering requires Quarto >= 1.4", call. = FALSE)
    FALSE
  })
}
