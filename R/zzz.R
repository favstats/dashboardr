# Package-level environment for internal state (avoids global env assignments)
.dashboardr_pkg_env <- new.env(parent = emptyenv())

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

#' Find Quarto binary path
#'
#' Searches PATH, the quarto R package, and the RStudio-bundled location.
#' If found outside PATH, adds the directory to PATH so child processes
#' (e.g. system2 calls) can also find it.
#' @return Path to quarto binary, or "" if not found
#' @keywords internal
.find_quarto_path <- function() {
  # 1. Check PATH
  q <- Sys.which("quarto")
  if (nzchar(q)) return(as.character(q))

  # 2. Check quarto R package

  if (requireNamespace("quarto", quietly = TRUE)) {
    qp <- tryCatch(quarto::quarto_path(), error = function(e) NULL)
    if (!is.null(qp) && nzchar(qp) && file.exists(qp)) {
      # Add to PATH for child processes
      Sys.setenv(PATH = paste(dirname(qp), Sys.getenv("PATH"), sep = ":"))
      return(qp)
    }
  }

  # 3. Check RStudio-bundled Quarto (macOS)
  rstudio_quarto <- "/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto"
  if (file.exists(rstudio_quarto)) {
    Sys.setenv(PATH = paste(dirname(rstudio_quarto), Sys.getenv("PATH"), sep = ":"))
    return(rstudio_quarto)
  }

  ""
}

#' Check Quarto version
#' 
#' @description Internal function to check if Quarto >= 1.4 is installed
#' @return TRUE if Quarto >= 1.4 is available, FALSE otherwise (with warning)
#' @keywords internal
check_quarto_version <- function() {
  # Check if quarto is available
  quarto_path <- .find_quarto_path()
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
