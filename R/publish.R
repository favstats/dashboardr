# ===================================================================
# Dashboard Publishing Functions
# ===================================================================

#' Publish dashboard to GitHub Pages
#'
#' This function automates the process of publishing a dashboard to GitHub Pages.
#' It handles git initialization, .gitignore setup, GitHub repository creation,
#' and GitHub Pages configuration using usethis functions.
#'
#' @param message Initial commit message (default: "Initial commit")
#' @param restart Whether to restart RStudio after git initialization (default: FALSE)
#' @param organisation GitHub organisation name (optional, for org repositories)
#' @param private Whether to create a private repository (default: FALSE)
#' @param protocol Transfer protocol: "https" or "ssh" (default: "https")
#' @param branch Branch to deploy from (default: uses git default branch)
#' @param path Path containing the site files (default: "/docs")
#' @param ... Additional arguments passed to \code{usethis::use_github()}
#'
#' @return Invisibly returns TRUE
#' @export
#'
#' @examples
#' \dontrun{
#' # After generating a dashboard, navigate to the dashboard directory
#' # and publish it:
#' setwd("my_dashboard")
#' publish_dashboard()
#'
#' # Publish to an organization
#' publish_dashboard(organisation = "my-org")
#'
#' # Create a private repository
#' publish_dashboard(private = TRUE)
#' }
publish_dashboard <- function(message = "Initial commit",
                             restart = FALSE,
                             organisation = NULL,
                             private = FALSE,
                             protocol = c("https", "ssh"),
                             branch = usethis::git_default_branch(),
                             path = "/docs",
                             ...) {
  
  protocol <- match.arg(protocol)
  
  cat("\n")
  cat("╔══════════════════════════════════════════════════════════════╗\n")
  cat("║          📤 Publishing Dashboard to GitHub Pages             ║\n")
  cat("╚══════════════════════════════════════════════════════════════╝\n\n")
  
  # Step 1: Initialize git repository and setup .gitignore
  cat("📝 Step 1/3: Setting up Git repository...\n\n")
  .setup_git_repo(message = message, restart = restart)
  
  # Step 2: Create GitHub repository
  cat("\n🚀 Step 2/3: Creating GitHub repository...\n\n")
  usethis::use_github(
    organisation = organisation,
    private = private,
    protocol = protocol,
    ...
  )
  
  # Step 3: Configure GitHub Pages
  cat("\n🌐 Step 3/3: Configuring GitHub Pages...\n\n")
  usethis::use_github_pages(
    branch = branch,
    path = path
  )
  
  cat("\n")
  cat("╔══════════════════════════════════════════════════════════════╗\n")
  cat("║          🎉 Dashboard Published Successfully!                ║\n")
  cat("╚══════════════════════════════════════════════════════════════╝\n\n")
  cat("💡 Next steps:\n")
  cat("   • Your dashboard URL is shown above\n")
  cat("   • Wait 2-5 minutes for deployment to complete\n")
  cat("   • Visit the URL to see your live dashboard\n")
  cat("   • Share the URL with others!\n\n")
  cat("📝 To update your dashboard later, use:\n")
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
  cat("╔══════════════════════════════════════════════════════════════╗\n")
  cat("║          🔄 Updating Dashboard on GitHub                     ║\n")
  cat("╚══════════════════════════════════════════════════════════════╝\n\n")
  
  # Add files
  cat("📝 Adding changed files...\n")
  added_files <- gert::git_add(files)
  if (nrow(added_files) > 0) {
    cat("   ✓ Staged", nrow(added_files), "file(s)\n\n")
  } else {
    cat("   ℹ No changes detected\n\n")
  }
  
  # Commit changes
  cat("💾 Committing changes...\n")
  gert::git_commit(message)
  cat("   ✓ Committed with message:", shQuote(message), "\n\n")
  
  # Ask for confirmation before pushing
  if (ask) {
    cat("❓ Ready to push changes to GitHub?\n\n")
    
    # Show what will be pushed
    if (nrow(added_files) > 0) {
      cat("   Files to be pushed:\n")
      for (i in seq_len(min(10, nrow(added_files)))) {
        cat("   •", added_files$file[i], "\n")
      }
      if (nrow(added_files) > 10) {
        cat("   ... and", nrow(added_files) - 10, "more file(s)\n")
      }
      cat("\n")
    }
    
    response <- readline("   Push to GitHub? (yes/no): ")
    
    if (!tolower(trimws(response)) %in% c("yes", "y")) {
      cat("\n❌ Push cancelled. Your changes are committed locally but not pushed.\n")
      cat("   Run update_dashboard() again when ready to push.\n\n")
      return(invisible(FALSE))
    }
    cat("\n")
  }
  
  # Push to remote
  cat("🚀 Pushing to GitHub...\n")
  gert::git_push()
  cat("   ✓ Successfully pushed to GitHub\n\n")
  
  # Get repository info for final message
  repo_info <- tryCatch({
    gert::git_remote_list()
  }, error = function(e) NULL)
  
  cat("╔══════════════════════════════════════════════════════════════╗\n")
  cat("║          ✅ Dashboard Updated Successfully!                  ║\n")
  cat("╚══════════════════════════════════════════════════════════════╝\n\n")
  
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
      
      cat("🌐 Your dashboard will update at:\n")
      cat("   ", dashboard_url, "\n\n")
      
      cat("⏱️  Changes will be live in 1-2 minutes.\n")
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

  needs_init <- !usethis:::uses_git()

  if (needs_init) {
    usethis:::ui_bullets(c(v = "Initialising Git repo."))
    usethis:::git_init()

    if (usethis:::is_positron()) {
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
  if (usethis:::git_uncommitted(untracked = TRUE)) {
    usethis:::git_ask_commit(message, untracked = TRUE)
  }

  # Only restart if explicitly requested and not in Positron
  if (needs_init && restart && !usethis:::is_positron()) {
    usethis:::restart_rstudio("A restart of RStudio is required to activate the Git pane.")
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
