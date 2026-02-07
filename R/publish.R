# ===================================================================
# Dashboard Publishing Functions
# ===================================================================

#' Publish dashboard to GitHub Pages
#'
#' This function automates the process of publishing a dashboard to GitHub Pages.
#' It handles git initialization, .gitignore setup, GitHub repository creation,
#' and GitHub Pages configuration using usethis functions.
#'
#' When \code{ask = TRUE} (the default), the function guides you through a 3-step
#' interactive confirmation process:
#' \enumerate{
#'   \item \strong{File Review}: Shows you the files that will be published and opens
#'     a folder so you can verify nothing unintended is included
#'   \item \strong{Repository Privacy}: Asks whether to create a private or public repository
#'   \item \strong{Confirm Publish}: Final confirmation before publishing to GitHub
#' }
#'
#' @section What Gets Published:
#' Typically, you only need to publish:
#' \itemize{
#'   \item The \code{docs/} folder (auto-generated HTML, CSS, JS files)
#'   \item Optionally, your R scripts (just for reproducibility)
#' }
#'
#' By default, common data file extensions (.csv, .rds, .xlsx, .sav, .dta) are
#' automatically excluded via .gitignore. Use \code{usethis::use_git_ignore()} to
#' exclude additional files you don't want to publish.
#'
#' @param message Initial commit message (default: "Initial commit")
#' @param restart Whether to restart RStudio after git initialization (default: FALSE)
#' @param organisation GitHub organisation name (optional, for org repositories)
#' @param private Whether to create a private repository. When \code{NULL} (default)
#'   and \code{ask = TRUE}, you will be prompted interactively. Set to \code{TRUE}
#'   or \code{FALSE} to skip the prompt.
#' @param protocol Transfer protocol: "https" or "ssh" (default: "https")
#' @param branch Branch to deploy from (default: uses git default branch)
#' @param path Path containing the site files (default: "/docs")
#' @param ask Whether to use the interactive confirmation workflow (default: TRUE).
#'   When \code{TRUE}, guides you through file review and confirmation steps.
#'   Set to \code{FALSE} to skip all prompts (not recommended for first-time use).
#' @param ... Additional arguments passed to \code{usethis::use_github()}
#'
#' @return Invisibly returns TRUE if published successfully, FALSE if cancelled
#' @export
#'
#' @examples
#' \dontrun{
#' # After generating a dashboard, navigate to the dashboard directory
#' # and publish it (interactive mode):
#' setwd("my_dashboard")
#' publish_dashboard()
#'
#' # Publish to an organization
#' publish_dashboard(organisation = "my-org")
#'
#' # Create a private repository (skip privacy prompt)
#' publish_dashboard(private = TRUE)
#'
#' # Skip all prompts (use with caution)
#' publish_dashboard(ask = FALSE, private = FALSE)
#' }
publish_dashboard <- function(message = "Initial commit",
                             restart = FALSE,
                             organisation = NULL,
                             private = NULL,
                             protocol = c("https", "ssh"),
                             branch = usethis::git_default_branch(),
                             path = "/docs",
                             ask = TRUE,
                             ...) {
  
  protocol <- match.arg(protocol)
  
  cat("\n")
  cat("\u2554\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2557\n")
  cat("\u2551          \U0001f4e4 Publishing Dashboard to GitHub Pages             \u2551\n")
  cat("\u255a\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u255d\n\n")
  
 # Run interactive confirmation workflow if ask = TRUE
  if (ask) {
    confirmation <- .run_interactive_confirmation(private = private)
    
    if (!confirmation$proceed) {
      return(invisible(FALSE))
    }
    
    # Update private from user's choice
    private <- confirmation$private
  }
  
  # Handle case where private is still NULL (ask = FALSE and no explicit value)
  if (is.null(private)) {
    private <- FALSE
  }
  
  # Step 1: Initialize git repository and setup .gitignore
  cat("\U0001f4dd Step 1/3: Setting up Git repository...\n\n")
  .setup_git_repo(message = message, restart = restart)
  
  # Step 2: Create GitHub repository
  cat("\n\U0001f680 Step 2/3: Creating GitHub repository...\n\n")
  usethis::use_github(
    organisation = organisation,
    private = private,
    protocol = protocol,
    ...
  )
  
  # Step 3: Configure GitHub Pages
  cat("\n\U0001f310 Step 3/3: Configuring GitHub Pages...\n\n")
  usethis::use_github_pages(
    branch = branch,
    path = path
  )
  
  cat("\n")
  cat("\u2554\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2557\n")
  cat("\u2551          \U0001f389 Dashboard Published Successfully!                \u2551\n")
  cat("\u255a\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u255d\n\n")
  cat("\U0001f4a1 Next steps:\n")
  cat("   \u2022 Your dashboard URL is shown above\n")
  cat("   \u2022 Wait 2-5 minutes for deployment to complete\n")
  cat("   \u2022 Visit the URL to see your live dashboard\n")
  cat("   \u2022 Share the URL with others!\n\n")
  cat("\U0001f4dd To update your dashboard later, use:\n")
  cat("   update_dashboard(message = \"Your update message\")\n\n")
  
  invisible(TRUE)
}

#' Update dashboard on GitHub
#'
#' Convenience function to add, commit, and push changes to GitHub.
#' Works from the current working directory.
#'
#' @param files Files to add. Can be:
#'   \itemize{
#'     \item \code{"."} to add all changes (default)
#'     \item A character vector of specific file paths
#'     \item A glob pattern (e.g., "*.R", "docs/*")
#'   }
#' @param message Commit message (default: "Update dashboard")
#' @param ask Whether to ask for confirmation before pushing (default: TRUE)
#'
#' @return Invisibly returns TRUE
#' @export
#'
#' @examples
#' \dontrun{
#' # Update all changes (will ask for confirmation)
#' update_dashboard()
#'
#' # Update with custom message
#' update_dashboard(message = "Fix navbar styling")
#'
#' # Update specific files
#' update_dashboard(files = c("docs/index.html", "docs/styles.css"))
#'
#' # Skip confirmation prompt
#' update_dashboard(ask = FALSE)
#' }
update_dashboard <- function(files = ".", message = "Update dashboard", ask = TRUE) {
  
  cat("\n")
  cat("\u2554\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2557\n")
  cat("\u2551          \U0001f504 Updating Dashboard on GitHub                     \u2551\n")
  cat("\u255a\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u255d\n\n")
  
  # Add files
  cat("\U0001f4dd Adding changed files...\n")
  added_files <- gert::git_add(files)
  if (nrow(added_files) > 0) {
    cat("   \u2713 Staged", nrow(added_files), "file(s)\n\n")
  } else {
    cat("   \u2139 No changes detected\n\n")
  }
  
  # Commit changes
  cat("\U0001f4be Committing changes...\n")
  gert::git_commit(message)
  cat("   \u2713 Committed with message:", shQuote(message), "\n\n")
  
  # Ask for confirmation before pushing
  if (ask) {
    cat("\u2753 Ready to push changes to GitHub?\n\n")
    
    # Show what will be pushed
    if (nrow(added_files) > 0) {
      cat("   Files to be pushed:\n")
      for (i in seq_len(min(10, nrow(added_files)))) {
        cat("   \u2022", added_files$file[i], "\n")
      }
      if (nrow(added_files) > 10) {
        cat("   ... and", nrow(added_files) - 10, "more file(s)\n")
      }
      cat("\n")
    }
    
    response <- readline("   Push to GitHub? (yes/no): ")
    
    if (!tolower(trimws(response)) %in% c("yes", "y")) {
      cat("\n\u274c Push cancelled. Your changes are committed locally but not pushed.\n")
      cat("   Run update_dashboard() again when ready to push.\n\n")
      return(invisible(FALSE))
    }
    cat("\n")
  }
  
  # Push to remote
  cat("\U0001f680 Pushing to GitHub...\n")
  gert::git_push()
  cat("   \u2713 Successfully pushed to GitHub\n\n")
  
  # Get repository info for final message
  repo_info <- tryCatch({
    gert::git_remote_list()
  }, error = function(e) NULL)
  
  cat("\u2554\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2557\n")
  cat("\u2551          \u2705 Dashboard Updated Successfully!                  \u2551\n")
  cat("\u255a\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u255d\n\n")
  
  # Extract and display the dashboard URL
  if (!is.null(repo_info) && nrow(repo_info) > 0) {
    repo_url <- repo_info$url[1]
    # Extract username and repo name from URL (handle both HTTPS and SSH)
    # Remove .git suffix if present
    repo_url_clean <- sub("\\.git$", "", repo_url)
    url_parts <- regmatches(repo_url_clean, regexec("github\\.com[:/]([^/]+)/(.+)$", repo_url_clean))[[1]]
    if (length(url_parts) == 3) {
      username <- url_parts[2]
      repo_name <- url_parts[3]
      dashboard_url <- paste0("https://", username, ".github.io/", repo_name, "/")
      
      cat("\U0001f310 Your dashboard will update at:\n")
      cat("   ", dashboard_url, "\n\n")
      
      cat("\u23f1\ufe0f  Changes will be live in 1-2 minutes.\n")
      cat("   Refresh your browser to see the updates.\n\n")
    }
  }
  
  invisible(TRUE)
}

# ===================================================================
# Internal Helper Functions
# ===================================================================

#' Setup git repository with comprehensive .gitignore
#'
#' Internal function that initializes a git repository and sets up
#' a comprehensive .gitignore file with data file exclusions and
#' large file detection.
#'
#' @param message Initial commit message
#' @param restart Whether to restart RStudio (default: FALSE)
#' @noRd
.setup_git_repo <- function(message = "Initial commit", restart = FALSE) {

  needs_init <- !tryCatch({ gert::git_find("."); TRUE }, error = function(e) FALSE)

  if (needs_init) {
    cli::cli_alert_success("Initialising Git repo.")
    gert::git_init(".")

    if (nzchar(Sys.getenv("POSITRON"))) {
      Sys.sleep(1)
    }
  }

  # Get comprehensive gitignore patterns
  git_ignore_lines <- .get_gitignore_patterns()

  # Add dynamically detected large files
  large_files <- .find_large_files(".", size_mb = 10)
  if (length(large_files) > 0) {
    git_ignore_lines <- c(git_ignore_lines, "", "# Large files (>10MB)", large_files)
  }

  # Add to .gitignore
  usethis::use_git_ignore(git_ignore_lines)

  # Commit if there are uncommitted changes
  if (nrow(gert::git_status()) > 0) {
    if (interactive()) {
      changed <- gert::git_status()
      cli::cli_alert_info("There are {nrow(changed)} uncommitted file(s).")
      answer <- utils::menu(c("Yes", "No"), title = "Do you want to commit them?")
      if (identical(answer, 1L)) {
        gert::git_add(".")
        gert::git_commit(message)
        cli::cli_alert_success("Committed with message: {.val {message}}")
      }
    } else {
      gert::git_add(".")
      gert::git_commit(message)
    }
  }

  # Only restart if explicitly requested and not in Positron
  if (needs_init && restart && !nzchar(Sys.getenv("POSITRON"))) {
    if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
      message("A restart of RStudio is required to activate the Git pane.")
      rstudioapi::restartSession()
    }
  }

  invisible(TRUE)
}

#' Get comprehensive gitignore patterns
#'
#' Returns a vector of gitignore patterns for R, Quarto, OS files,
#' and comprehensive data file exclusions.
#'
#' @return Character vector of gitignore patterns
#' @noRd
.get_gitignore_patterns <- function() {
  c(
    "# R",
    ".Rproj.user",
    ".Rhistory",
    ".RData",
    ".Ruserdata",
    "*.Rproj",
    "",
    "# Quarto",
    ".quarto/",
    "",
    "# OS",
    ".DS_Store",
    "Thumbs.db",
    "",
    "# IDE",
    ".vscode/",
    ".idea/",
    "",
    "# Temporary files",
    "*.tmp",
    "*.temp",
    "*.log",
    "",
    "# DATA FILES - EXCLUDED BY DEFAULT",
    "# Uncomment specific lines below if you want to include certain data types",
    "",
    "# R Data Files",
    "*.rds",
    "*.RData",
    "*.rda",
    "*.RDS",
    "*.RDATA",
    "*.RDA",
    "",
    "# CSV and Delimited Files",
    "*.csv",
    "*.tsv",
    "*.txt",
    "*.dat",
    "*.tab",
    "",
    "# Excel Files",
    "*.xlsx",
    "*.xls",
    "*.xlsm",
    "*.xlsb",
    "",
    "# Database Files",
    "*.db",
    "*.sqlite",
    "*.sqlite3",
    "*.mdb",
    "*.accdb",
    "",
    "# Statistical Software Files",
    "*.sav",
    "*.dta",
    "*.sas7bdat",
    "*.por",
    "*.zsav",
    "",
    "# JSON and XML",
    "*.json",
    "*.xml",
    "*.yaml",
    "*.yml",
    "",
    "# Archive Files",
    "*.zip",
    "*.tar",
    "*.tar.gz",
    "*.gz",
    "*.bz2",
    "*.7z",
    "*.rar",
    "",
    "# Large Files (typically data)",
    "*.parquet",
    "*.feather",
    "*.fst",
    "*.h5",
    "*.hdf5",
    "",
    "# Data Directories",
    "data/",
    "datasets/",
    "raw_data/",
    "processed_data/",
    "output_data/",
    "",
    "# Backup Files",
    "*~",
    "*.bak",
    "*.backup",
    "*.orig"
  )
}

#' Find large files that might be data
#'
#' Scans the directory for files larger than the specified size.
#'
#' @param path Directory path
#' @param size_mb Minimum size in MB (default: 10)
#' @return Character vector of relative file paths
#' @noRd
.find_large_files <- function(path, size_mb = 10) {
  all_files <- list.files(path, recursive = TRUE, full.names = TRUE, all.files = TRUE)
  large_files <- character(0)

  for (file in all_files) {
    if (file.exists(file) && !dir.exists(file)) {
      file_size <- file.size(file) / (1024 * 1024)  # Convert to MB
      if (file_size > size_mb) {
        # Get relative path
        rel_path <- gsub(paste0("^", path, "/?"), "", file)
        large_files <- c(large_files, rel_path)
      }
    }
  }

  large_files
}

# ===================================================================
# Interactive Publishing Helper Functions
# ===================================================================

#' Get files that would be committed (respecting .gitignore)
#'
#' Returns a list of files that git would track, excluding ignored files.
#'
#' @param base_path Base directory path
#' @return Character vector of file paths
#' @noRd
.get_committable_files <- function(base_path = ".") {
  # Get all files recursively

  all_files <- list.files(base_path, recursive = TRUE, all.files = FALSE, full.names = FALSE)
  

  # Check if .gitignore exists and read patterns
  gitignore_path <- file.path(base_path, ".gitignore")
  if (file.exists(gitignore_path)) {
    gitignore_patterns <- readLines(gitignore_path, warn = FALSE)
    # Filter out comments and empty lines
    gitignore_patterns <- gitignore_patterns[!grepl("^\\s*#", gitignore_patterns)]
    gitignore_patterns <- gitignore_patterns[nchar(trimws(gitignore_patterns)) > 0]
    
    # Convert gitignore patterns to regex and filter files
    for (pattern in gitignore_patterns) {
      pattern <- trimws(pattern)
      if (nchar(pattern) == 0) next
      
      # Convert glob pattern to regex
      regex_pattern <- .glob_to_regex(pattern)
      
      # Filter out matching files
      all_files <- all_files[!grepl(regex_pattern, all_files, perl = TRUE)]
    }
  }
  
  # Also exclude common non-file entries
  all_files <- all_files[!grepl("^\\.git/", all_files)]
  all_files <- all_files[!grepl("^\\.dashboardr_review/", all_files)]
  
  all_files
}

#' Convert glob pattern to regex
#'
#' @param pattern Glob pattern
#' @return Regex pattern
#' @noRd
.glob_to_regex <- function(pattern) {
  # Escape regex special characters except * and ?

  pattern <- gsub("\\.", "\\\\.", pattern)
  pattern <- gsub("\\[", "\\\\[", pattern)
  pattern <- gsub("\\]", "\\\\]", pattern)
  pattern <- gsub("\\(", "\\\\(", pattern)

  pattern <- gsub("\\)", "\\\\)", pattern)
  pattern <- gsub("\\+", "\\\\+", pattern)
  pattern <- gsub("\\^", "\\\\^", pattern)
  pattern <- gsub("\\$", "\\\\$", pattern)
  
  # Handle directory patterns (ending with /)
  if (grepl("/$", pattern)) {
    pattern <- sub("/$", "", pattern)
    pattern <- paste0("(^|/)", pattern, "(/|$)")
  } else if (!grepl("/", pattern)) {
    # Pattern without / matches anywhere in path
    pattern <- paste0("(^|/)", pattern, "($|/)?")
  }
  
  # Convert glob wildcards to regex
  pattern <- gsub("\\*\\*", ".*", pattern)  # ** matches everything including /

  pattern <- gsub("\\*", "[^/]*", pattern)   # * matches everything except /
  pattern <- gsub("\\?", ".", pattern)       # ? matches single character
  
  pattern
}

#' Create temporary review folder with files to be committed
#'
#' Creates a folder at .dashboardr_review/ containing copies of all files
#' that would be committed (respecting .gitignore).
#'
#' @param base_path Base directory path
#' @return Path to the review folder
#' @noRd
.create_review_folder <- function(base_path = ".") {
  review_path <- file.path(base_path, ".dashboardr_review")
  

  # Clean up if exists
  if (dir.exists(review_path)) {
    unlink(review_path, recursive = TRUE)
  }
  
  # Create the review folder
  dir.create(review_path, recursive = TRUE)
  
  # Get files that would be committed
  files_to_copy <- .get_committable_files(base_path)
  
  # Copy files maintaining directory structure
  for (file in files_to_copy) {
    src <- file.path(base_path, file)
    dst <- file.path(review_path, file)
    
    # Create parent directory if needed
    dst_dir <- dirname(dst)
    if (!dir.exists(dst_dir)) {
      dir.create(dst_dir, recursive = TRUE)
    }
    
    # Copy the file
    if (file.exists(src) && !dir.exists(src)) {
      file.copy(src, dst, overwrite = TRUE)
    }
  }
  
  # Add .gitignore to the review folder itself so it's not committed
  usethis::use_git_ignore(".dashboardr_review/")
  
  normalizePath(review_path)
}

#' Open folder in system file browser
#'
#' Opens the specified folder in Finder (macOS), Explorer (Windows),
#' or the default file manager (Linux).
#'
#' @param path Path to the folder to open
#' @return Invisibly returns TRUE
#' @noRd
.open_folder_in_browser <- function(path) {
  path <- normalizePath(path, mustWork = FALSE)
  
  os <- Sys.info()["sysname"]
  
  if (os == "Darwin") {
    # macOS
    system2("open", path)
  } else if (os == "Windows") {
    # Windows - use explorer.exe via system2
    system2("explorer", path)
  } else {
    # Linux and others
    system2("xdg-open", path)
  }
  
  invisible(TRUE)
}

#' Print file tree to console
#'
#' Displays a simplified summary of files - top-level folders with counts
#' and root-level files.
#'
#' @param path Path to the directory
#' @return Invisibly returns the number of files
#' @noRd
.print_file_tree <- function(path) {
  files <- list.files(path, recursive = TRUE, all.files = FALSE)
  n_files <- length(files)
  
  cat("\n")
  cat("   Files to be committed (", n_files, " total):\n", sep = "")
  cat("   ", strrep("-", 40), "\n", sep = "")
  
  if (n_files > 0) {
    # Get top-level directories and their file counts
    top_level <- sapply(strsplit(files, "/"), `[`, 1)
    
    # Separate directories from root files
    root_files <- files[!grepl("/", files)]
    dir_files <- files[grepl("/", files)]
    
    # Count files per top-level directory
    if (length(dir_files) > 0) {
      dir_names <- sapply(strsplit(dir_files, "/"), `[`, 1)
      dir_counts <- table(dir_names)
      
      for (dir in sort(names(dir_counts))) {
        cat("   ", dir, "/  (", dir_counts[dir], " files)\n", sep = "")
      }
    }
    
    # Show root-level files (these are important to see)
    if (length(root_files) > 0) {
      cat("\n   Root files:\n")
      for (f in sort(root_files)) {
        cat("   ", f, "\n", sep = "")
      }
    }
  } else {
    cat("   (no files found)\n")
  }
  
  cat("   ", strrep("-", 40), "\n\n", sep = "")
  
  invisible(n_files)
}

#' Display pre-review instructions
#'
#' Shows brief instructions before file review.
#'
#' @return Invisibly returns TRUE
#' @noRd
.display_pre_review_info <- function() {
  cat("\n")
  cat("In the next step, you can review the files that will be published.\n\n")
  
  cat("Typically, you only need:\n")
  cat("   \u2022 docs/  folder (auto-generated HTML, CSS, JS files)\n")
  cat("   \u2022 Optionally: your R scripts (just for reproducibility)\n\n")
  
  cat("By default, data files (.csv, .rds, .xlsx, etc.) are excluded\n")
  cat("via .gitignore. To exclude additional files, use:\n")
  cat("   usethis::use_git_ignore(c(\"file.csv\", \"folder/\"))\n\n")
  
  invisible(TRUE)
}

#' Clean up review folder
#'
#' Removes the temporary .dashboardr_review folder.
#'
#' @param base_path Base directory path
#' @return Invisibly returns TRUE
#' @noRd
.cleanup_review_folder <- function(base_path = ".") {
  review_path <- file.path(base_path, ".dashboardr_review")
  
  if (dir.exists(review_path)) {
    unlink(review_path, recursive = TRUE)
  }
  
  invisible(TRUE)
}

#' Run interactive confirmation workflow
#'
#' Guides the user through a streamlined confirmation process before publishing.
#'
#' @param private Current private setting (NULL means ask interactively)
#' @return A list with components:
#'   \item{proceed}{Whether to proceed with publishing}
#'   \item{private}{Final private setting}
#' @noRd
.run_interactive_confirmation <- function(private = NULL) {
  
  # ===== STEP 1: Pre-review info and ask to proceed =====
  cat("\n\U0001f4cb Step 1/3: File Review\n")
  cat(strrep("-", 40), "\n", sep = "")
  
 .display_pre_review_info()
  
  response <- readline("   Ready to review files? (yes/no): ")
  
  if (!tolower(trimws(response)) %in% c("yes", "y")) {
    cat("\n\u274c Cancelled. Run publish_dashboard() when ready.\n\n")
    return(list(proceed = FALSE, private = private))
  }
  
  # Create review folder and show files
  cat("\n\U0001f4c2 Preparing file review...\n")
  review_path <- .create_review_folder(".")
  
  # Print file tree
  .print_file_tree(review_path)
  
  # Open folder in browser
  cat("\U0001f4c2 Opening folder: ", review_path, "\n\n")
  .open_folder_in_browser(review_path)
  
  cat("\u26a0\ufe0f  Please verify these are the files you want to publish.\n")
  cat("   Make sure there's nothing you didn't intend to include.\n\n")
  
  response <- readline("   Confirm these files are OK to publish? (yes/no): ")
  
  if (!tolower(trimws(response)) %in% c("yes", "y")) {
    cat("\n\u274c Cancelled. To exclude files, use:\n")
    cat("   usethis::use_git_ignore(c(\"file.csv\", \"folder/\"))\n\n")
    .cleanup_review_folder(".")
    return(list(proceed = FALSE, private = private))
  }
  
  # ===== STEP 2: Repository Privacy Choice =====
  if (is.null(private)) {
    cat("\n\U0001f512 Step 2/3: Repository Privacy\n")
    cat(strrep("-", 40), "\n\n", sep = "")
    
    cat("PUBLIC:  Anyone can see your code. Free GitHub Pages.\n")
    cat("PRIVATE: Only you can see code. Pages requires paid plan.\n\n")
    
    response <- readline("   Create a PRIVATE repository? (yes/no): ")
    
    private <- tolower(trimws(response)) %in% c("yes", "y")
    cat("   \u2713 Repository will be ", if (private) "PRIVATE" else "PUBLIC", "\n", sep = "")
  }
  
  # ===== STEP 3: Final Confirmation =====
  cat("\n\U0001f680 Step 3/3: Confirm Publish\n")
  cat(strrep("-", 40), "\n\n", sep = "")
  
  cat("This will:\n")
  cat("   \u2022 Create a ", if (private) "private" else "public", " GitHub repository\n", sep = "")
  cat("   \u2022 Push your files to GitHub\n")
  cat("   \u2022 Enable GitHub Pages\n\n")
  
  response <- readline("   Publish to GitHub? (yes/no): ")
  
  if (!tolower(trimws(response)) %in% c("yes", "y")) {
    cat("\n\u274c Cancelled. Run publish_dashboard() when ready.\n\n")
    .cleanup_review_folder(".")
    return(list(proceed = FALSE, private = private))
  }
  
  # Clean up review folder before proceeding
  .cleanup_review_folder(".")
  
  cat("\n\u2713 Proceeding with publishing...\n\n")
  
  list(proceed = TRUE, private = private)
}
