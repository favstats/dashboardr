
# ===================================================================
# Dashboard Publishing Functions
# ===================================================================

#' Publish dashboard to GitHub Pages or GitLab Pages
#'
#' This function automates the process of publishing a dashboard to GitHub Pages
#' or GitLab Pages. It handles git initialization, remote setup, and deployment
#' configuration.
#'
#' @param dashboard_path Path to the generated dashboard directory
#' @param platform Platform to publish to: "github" or "gitlab"
#' @param repo_name Name for the repository (defaults to dashboard directory name)
#' @param username GitHub/GitLab username (optional, will prompt if not provided)
#' @param private Whether to create a private repository (default: FALSE)
#' @param open_browser Whether to open the published dashboard in browser (default: TRUE)
#' @param commit_message Git commit message (default: "Deploy dashboard")
#' @param branch Branch to deploy from (default: "main")
#' @param docs_subdir Subdirectory containing the docs (default: "docs")
#' @param include_data Whether to include data files in the repository (default: FALSE)
#'
#' @return Invisibly returns the repository URL
#' @export
#'
#' @examples
#' \dontrun{
#' # After generating a dashboard
#' dashboard <- create_dashboard("my_dashboard") %>%
#'   add_page("Analysis", data = my_data, visualizations = my_viz) %>%
#'   generate_dashboard()
#'
#' # Publish to GitHub Pages
#' publish_dashboard("my_dashboard", platform = "github", username = "myusername")
#'
#' # Publish to GitLab Pages
#' publish_dashboard("my_dashboard", platform = "gitlab", username = "myusername")
#' }
publish_dashboard <- function(dashboard_path,
                             platform = c("github", "gitlab"),
                             repo_name = NULL,
                             username = NULL,
                             private = FALSE,
                             open_browser = FALSE,
                             commit_message = "Deploy dashboard",
                             branch = "main",
                             docs_subdir = "docs",
                             include_data = FALSE) {

  platform <- match.arg(platform)

  # Validate dashboard path
  if (!dir.exists(dashboard_path)) {
    stop("Dashboard directory does not exist: ", dashboard_path)
  }

  # Check if docs directory exists
  docs_path <- file.path(dashboard_path, docs_subdir)
  if (!dir.exists(docs_path)) {
    stop("Docs directory not found: ", docs_path,
         "\nMake sure to run generate_dashboard() first")
  }

  # Check if docs directory has content (at least one HTML file)
  html_files <- list.files(docs_path, pattern = "\\.html$", full.names = FALSE)
  if (length(html_files) == 0) {
    stop("Docs directory is empty or contains no HTML files: ", docs_path,
         "\nMake sure to run generate_dashboard() with render = TRUE first")
  }

  # Set default repo name
  if (is.null(repo_name)) {
    repo_name <- basename(normalizePath(dashboard_path))
  }

  # Get username if not provided
  if (is.null(username)) {
    username <- .get_username_interactive(platform)
  }

  cat("🚀 Publishing dashboard to ", platform, " Pages...\n", sep = "")
  cat("📁 Dashboard: ", dashboard_path, "\n", sep = "")
  cat("📦 Repository: ", username, "/", repo_name, "\n", sep = "")
  cat("🌐 Platform: ", platform, "\n\n", sep = "")

  # Step 1: Check for data files and warn user
  .check_data_files(dashboard_path, include_data)

  # Step 2: Initialize git repository
  .init_git_repo(dashboard_path)

  # Step 3: Create .gitignore
  .create_gitignore(dashboard_path, include_data)

  # Step 3: Create repository on platform
  repo_url <- .create_remote_repo(dashboard_path, platform, username, repo_name, private)

  # Step 4: Configure for Pages deployment
  .configure_pages_deployment(dashboard_path, platform, branch, docs_subdir)

  # Step 5: Commit and push
  .commit_and_push(dashboard_path, commit_message, branch)

  # Step 6: Get deployment URL
  deployment_url <- .get_deployment_url(platform, username, repo_name)

  cat("\n🎉 Dashboard published successfully!\n")
  cat("══════════════════════════════════════════════════\n")
  cat("🌐 Dashboard URL: ", deployment_url, "\n", sep = "")
  cat("📝 Repository: ", repo_url, "\n", sep = "")
  cat("\n⏱️  IMPORTANT: GitHub Pages deployment takes 2-5 minutes\n")
  cat("   Your dashboard will be available at the URL above once deployed\n")
  cat("   You can check deployment status in your repository's Actions tab\n\n")

  if (open_browser) {
    cat("🌐 Opening repository in browser (not dashboard - it's still building)...\n")
    .open_url(repo_url)
  } else {
    cat("💡 Tip: Visit the repository URL to monitor deployment progress\n")
  }

  invisible(deployment_url)
}

#' Get username interactively
#' @param platform Platform name
#' @return Username as string
#' @noRd
.get_username_interactive <- function(platform) {
  cat("Please enter your ", platform, " username:\n", sep = "")
  username <- readline("Username: ")

  if (is.null(username) || nchar(trimws(username)) == 0) {
    stop("Username is required for publishing")
  }

  trimws(username)
}

#' Initialize git repository using gert
#' @param path Dashboard path
#' @noRd
.init_git_repo <- function(path) {
  cat("📝 Initializing git repository...\n")

  # Check if already a git repo
  if (dir.exists(file.path(path, ".git"))) {
    cat("   ✓ Git repository already exists\n")
    return(invisible(TRUE))
  }

  # Check if gert is available
  if (!requireNamespace("gert", quietly = TRUE)) {
    cat("   ⚠️  gert package not available. Please install it:\n")
    cat("      install.packages('gert')\n")
    cat("   📝 Falling back to system git...\n")
    return(.init_git_repo_system(path))
  }

  tryCatch({
    # Initialize git repository using gert
    gert::git_init(path)

    # Set default branch to main
    gert::git_branch_create("main", path)

    cat("   ✓ Git repository initialized\n")
  }, error = function(e) {
    cat("   ⚠️  gert failed, falling back to system git...\n")
    .init_git_repo_system(path)
  })

  invisible(TRUE)
}

#' Initialize git repository using system git (fallback)
#' @param path Dashboard path
#' @noRd
.init_git_repo_system <- function(path) {
  old_wd <- getwd()
  setwd(path)
  on.exit(setwd(old_wd), add = TRUE)

  tryCatch({
    # Initialize git repository
    system2("git", c("init"), stdout = TRUE, stderr = TRUE)

    # Set default branch to main
    system2("git", c("branch", "-M", "main"), stdout = TRUE, stderr = TRUE)

    cat("   ✓ Git repository initialized\n")
  }, error = function(e) {
    stop("Failed to initialize git repository: ", e$message)
  })

  invisible(TRUE)
}

#' Check for data files and warn user
#' @param path Dashboard path
#' @param include_data Whether to include data files
#' @noRd
.check_data_files <- function(path, include_data) {
  cat("🔍 Checking for data files...\n")

  # Define comprehensive data file patterns
  data_patterns <- c(
    # R Data Files
    "*.rds", "*.RData", "*.rda", "*.RDS", "*.RDATA", "*.RDA",
    # CSV and Delimited Files
    "*.csv", "*.tsv", "*.txt", "*.dat", "*.tab",
    # Excel Files
    "*.xlsx", "*.xls", "*.xlsm", "*.xlsb",
    # Database Files
    "*.db", "*.sqlite", "*.sqlite3", "*.mdb", "*.accdb",
    # Statistical Software Files
    "*.sav", "*.dta", "*.sas7bdat", "*.por", "*.zsav",
    # JSON and XML (but exclude config files)
    "*.json", "*.xml",
    # Archive Files
    "*.zip", "*.tar", "*.tar.gz", "*.gz", "*.bz2", "*.7z", "*.rar",
    # Large Files
    "*.parquet", "*.feather", "*.fst", "*.h5", "*.hdf5"
  )

  # Find all data files
  data_files <- character(0)
  for (pattern in data_patterns) {
    # Convert glob pattern to regex
    regex_pattern <- gsub("\\*", ".*", pattern)
    # Make sure it matches the full filename, not just part of it
    regex_pattern <- paste0("^", regex_pattern, "$")

    files <- list.files(path, pattern = regex_pattern,
                       recursive = TRUE, full.names = FALSE, ignore.case = TRUE)
    data_files <- c(data_files, files)
  }

  # Also check for data directories
  data_dirs <- c("data", "datasets", "raw_data", "processed_data", "output_data")
  for (dir in data_dirs) {
    if (dir.exists(file.path(path, dir))) {
      data_files <- c(data_files, paste0(dir, "/"))
    }
  }

  # Check for large files (>10MB) that might be data
  large_files <- .find_large_files(path, size_mb = 10)
  if (length(large_files) > 0) {
    data_files <- c(data_files, large_files)
  }

  # Remove duplicates and sort
  data_files <- unique(sort(data_files))

  # Filter out common config files and Quarto-generated files that are not data
  config_files <- c("_quarto.yml", "quarto.yml", ".gitignore", "README.md", "LICENSE",
                   "DESCRIPTION", "NAMESPACE", "Makefile", "Dockerfile", ".dockerignore",
                   "index.html", "sitemap.xml", ".nojekyll")
  data_files <- data_files[!data_files %in% config_files]

  # Also filter out docs/search.json specifically (Quarto search index)
  data_files <- data_files[!grepl("^docs/search\\.json$", data_files)]

  if (length(data_files) > 0) {
    if (!include_data) {
      cat("   ⚠️  Found ", length(data_files), " data file(s) that will be EXCLUDED:\n", sep = "")
      for (file in head(data_files, 10)) {  # Show first 10
        cat("      - ", file, "\n", sep = "")
      }
      if (length(data_files) > 10) {
        cat("      ... and ", length(data_files) - 10, " more\n", sep = "")
      }
      cat("\n   🔒 Data files are excluded by default for security and size reasons\n")
      cat("   💡 To include data files, use: include_data = TRUE\n")
      cat("   ⚠️  WARNING: Only include data if you have permission to share it publicly\n\n")
    } else {
      cat("   ⚠️  Found ", length(data_files), " data file(s) that will be INCLUDED:\n", sep = "")
      for (file in head(data_files, 10)) {  # Show first 10
        cat("      - ", file, "\n", sep = "")
      }
      if (length(data_files) > 10) {
        cat("      ... and ", length(data_files) - 10, " more\n", sep = "")
      }
      cat("\n   ⚠️  WARNING: Data files will be committed to the repository!\n")
      cat("   🔒 Make sure you have permission to share this data publicly\n")
      cat("   💡 Consider using a private repository for sensitive data\n\n")
    }
  } else {
    cat("   ✓ No data files detected\n")
  }

  invisible(data_files)
}

#' Find large files that might be data
#' @param path Directory path
#' @param size_mb Minimum size in MB
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

#' Create comprehensive .gitignore file
#' @param path Dashboard path
#' @param include_data Whether to include data files (default: FALSE)
#' @noRd
.create_gitignore <- function(path, include_data = FALSE) {
  gitignore_path <- file.path(path, ".gitignore")

  if (file.exists(gitignore_path)) {
    cat("   ✓ .gitignore already exists\n")
    return(invisible(TRUE))
  }

  gitignore_content <- c(
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
    "*.log"
  )

  # Add comprehensive data exclusions unless explicitly included
  if (!include_data) {
    data_exclusions <- c(
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
    gitignore_content <- c(gitignore_content, data_exclusions)
  } else {
    # If data is included, add a warning comment
    warning_content <- c(
      "",
      "# WARNING: Data files are being included in this repository",
      "# Make sure this is intentional and that you have permission to share this data",
      "# Consider using a private repository for sensitive data"
    )
    gitignore_content <- c(gitignore_content, warning_content)
  }

  writeLines(gitignore_content, gitignore_path)
  cat("   ✓ .gitignore created\n")

  invisible(TRUE)
}

#' Create remote repository
#' @param path Dashboard path
#' @param platform Platform name
#' @param username Username
#' @param repo_name Repository name
#' @param private Whether private
#' @return Repository URL
#' @noRd
.create_remote_repo <- function(path, platform, username, repo_name, private) {
  cat("📦 Creating ", platform, " repository...\n", sep = "")

  repo_url <- if (platform == "github") {
    paste0("https://github.com/", username, "/", repo_name, ".git")
  } else {
    paste0("https://gitlab.com/", username, "/", repo_name, ".git")
  }

  # Check if usethis is available
  if (!requireNamespace("usethis", quietly = TRUE)) {
    cat("   ⚠️  usethis package not available. Please install it:\n")
    cat("      install.packages('usethis')\n")
    cat("   📝 Manual steps required:\n")
    cat("      1. Create repository at: ", repo_url, "\n", sep = "")
    cat("      2. Add remote: git remote add origin ", repo_url, "\n", sep = "")
    return(repo_url)
  }

  # Try to create repository using GitHub API
  tryCatch({
    .create_github_repo_simple(path, username, repo_name, private)
    cat("   ✓ Repository created successfully\n")
  }, error = function(e) {
    cat("   ⚠️  Could not create repository automatically:\n")
    cat("      Error: ", e$message, "\n", sep = "")
    cat("   📝 Please create repository manually:\n")
    cat("      URL: ", repo_url, "\n", sep = "")
    cat("   💡 Quick setup options:\n")
    cat("      1. Web interface: Visit https://github.com/new\n")
    cat("         - Repository name: ", repo_name, "\n", sep = "")
    cat("         - Visibility: ", if(private) "Private" else "Public", "\n", sep = "")
    cat("         - Don't initialize with README, .gitignore, or license\n")
    cat("      2. Then run these commands in your dashboard directory:\n")
    cat("         git remote add origin ", repo_url, "\n", sep = "")
    cat("         git push -u origin main\n", sep = "")
    cat("   🔧 Alternative: Use GitHub CLI if installed:\n")
    cat("         gh repo create ", username, "/", repo_name, " --", if(private) "private" else "public", " --source=. --remote=origin --push\n", sep = "")
  })

  invisible(repo_url)
}

#' Create GitHub repository using simple API approach
#' @param path Dashboard path
#' @param username GitHub username
#' @param repo_name Repository name
#' @param private Whether repository should be private
#' @noRd
.create_github_repo_simple <- function(path, username, repo_name, private) {
  # Check if httr is available
  if (!requireNamespace("httr", quietly = TRUE)) {
    stop("httr package is required for GitHub API calls. Please install it: install.packages('httr')")
  }

  # Get GitHub token from environment or usethis
  token <- Sys.getenv("GITHUB_PAT")
  if (token == "") {
    # Try to get token from usethis
    if (requireNamespace("usethis", quietly = TRUE)) {
      tryCatch({
        token <- usethis::gh_token()
      }, error = function(e) {
        stop("No GitHub token found. Please set GITHUB_PAT environment variable or run usethis::create_github_token()")
      })
    } else {
      stop("No GitHub token found. Please set GITHUB_PAT environment variable")
    }
  }

  # GitHub API endpoint
  url <- "https://api.github.com/user/repos"

  # Repository data
  repo_data <- list(
    name = repo_name,
    description = paste("Dashboard created with dashboardr package"),
    private = private,
    auto_init = FALSE
  )

  # Make API request
  response <- httr::POST(
    url,
    httr::add_headers(
      Authorization = paste("token", token),
      "User-Agent" = "dashboardr-package"
    ),
    httr::content_type_json(),
    body = jsonlite::toJSON(repo_data, auto_unbox = TRUE)
  )

  # Check response
  if (httr::status_code(response) == 201) {
    # Repository created successfully, add remote
    repo_url <- paste0("https://github.com/", username, "/", repo_name, ".git")

    # Add or update remote using gert or system git
    if (requireNamespace("gert", quietly = TRUE)) {
      tryCatch({
        # Check if remote already exists
        remotes <- gert::git_remote_list(repo = path)
        if (nrow(remotes) > 0 && any(remotes$name == "origin")) {
          # Update existing remote
          gert::git_remote_set_url("origin", repo_url, repo = path)
        } else {
          # Add new remote
          gert::git_remote_add("origin", repo_url, repo = path)
        }
      }, error = function(e) {
        # If gert fails, try system git
        old_wd <- getwd()
        setwd(path)
        on.exit(setwd(old_wd), add = TRUE)
        # Check if remote exists and update or add
        existing_remotes <- system2("git", c("remote", "-v"), stdout = TRUE, stderr = TRUE)
        if (length(existing_remotes) > 0 && any(grepl("origin", existing_remotes))) {
          system2("git", c("remote", "set-url", "origin", repo_url), stdout = TRUE, stderr = TRUE)
        } else {
          system2("git", c("remote", "add", "origin", repo_url), stdout = TRUE, stderr = TRUE)
        }
      })
    } else {
      old_wd <- getwd()
      setwd(path)
      on.exit(setwd(old_wd), add = TRUE)
      # Check if remote exists and update or add
      existing_remotes <- system2("git", c("remote", "-v"), stdout = TRUE, stderr = TRUE)
      if (length(existing_remotes) > 0 && any(grepl("origin", existing_remotes))) {
        system2("git", c("remote", "set-url", "origin", repo_url), stdout = TRUE, stderr = TRUE)
      } else {
        system2("git", c("remote", "add", "origin", repo_url), stdout = TRUE, stderr = TRUE)
      }
    }

    cat("   ✓ Remote origin added/updated\n")

    return(invisible(TRUE))
  } else if (httr::status_code(response) == 422) {
    # Repository already exists - this is actually fine, just add the remote
    repo_url <- paste0("https://github.com/", username, "/", repo_name, ".git")

    # Add or update remote using gert or system git
    if (requireNamespace("gert", quietly = TRUE)) {
      tryCatch({
        # Check if remote already exists
        remotes <- gert::git_remote_list(repo = path)
        if (nrow(remotes) > 0 && any(remotes$name == "origin")) {
          # Update existing remote
          gert::git_remote_set_url("origin", repo_url, repo = path)
        } else {
          # Add new remote
          gert::git_remote_add("origin", repo_url, repo = path)
        }
      }, error = function(e) {
        # If gert fails, try system git
        old_wd <- getwd()
        setwd(path)
        on.exit(setwd(old_wd), add = TRUE)
        # Check if remote exists and update or add
        existing_remotes <- system2("git", c("remote", "-v"), stdout = TRUE, stderr = TRUE)
        if (length(existing_remotes) > 0 && any(grepl("origin", existing_remotes))) {
          system2("git", c("remote", "set-url", "origin", repo_url), stdout = TRUE, stderr = TRUE)
        } else {
          system2("git", c("remote", "add", "origin", repo_url), stdout = TRUE, stderr = TRUE)
        }
      })
    } else {
      old_wd <- getwd()
      setwd(path)
      on.exit(setwd(old_wd), add = TRUE)
      # Check if remote exists and update or add
      existing_remotes <- system2("git", c("remote", "-v"), stdout = TRUE, stderr = TRUE)
      if (length(existing_remotes) > 0 && any(grepl("origin", existing_remotes))) {
        system2("git", c("remote", "set-url", "origin", repo_url), stdout = TRUE, stderr = TRUE)
      } else {
        system2("git", c("remote", "add", "origin", repo_url), stdout = TRUE, stderr = TRUE)
      }
    }

    cat("   ✓ Repository already exists, remote origin added/updated\n")

    return(invisible(TRUE))
  } else {
    # Parse error message
    error_content <- httr::content(response, "text")
    error_msg <- "Unknown error"
    tryCatch({
      error_json <- jsonlite::fromJSON(error_content)
      if ("message" %in% names(error_json)) {
        error_msg <- error_json$message
      }
    }, error = function(e) {
      error_msg <- error_content
    })

    stop("GitHub API error (", httr::status_code(response), "): ", error_msg)
  }
}

#' Add remote if it doesn't exist
#' @param path Dashboard path
#' @param repo_url Repository URL
#' @noRd
.add_remote_if_needed <- function(path, repo_url) {
  # Check if gert is available
  if (!requireNamespace("gert", quietly = TRUE)) {
    return(invisible(FALSE))
  }

  tryCatch({
    # Check if remote exists
    remotes <- gert::git_remote_list(repo = path)
    if (nrow(remotes) == 0 || !any(remotes$name == "origin")) {
      # Add remote
      gert::git_remote_add("origin", repo_url, repo = path)
      cat("   ✓ Remote origin added\n")
    }
  }, error = function(e) {
    # Silent fail - remote might already exist or other issue
  })

  invisible(TRUE)
}

#' Configure Pages deployment
#' @param path Dashboard path
#' @param platform Platform name
#' @param branch Branch name
#' @param docs_subdir Docs subdirectory
#' @noRd
.configure_pages_deployment <- function(path, platform, branch, docs_subdir) {
  cat("⚙️  Configuring ", platform, " Pages deployment...\n", sep = "")

  if (platform == "github") {
    .configure_github_pages(path, branch, docs_subdir)
  } else {
    .configure_gitlab_pages(path, branch, docs_subdir)
  }

  invisible(TRUE)
}

#' Configure GitHub Pages
#' @param path Dashboard path
#' @param branch Branch name
#' @param docs_subdir Docs subdirectory
#' @noRd
.configure_github_pages <- function(path, branch, docs_subdir) {
  # Ensure the directory exists
  if (!dir.exists(path)) {
    stop("Dashboard directory does not exist: ", path)
  }

  # Create .nojekyll file to prevent Jekyll processing
  nojekyll_path <- file.path(path, ".nojekyll")
  if (!file.exists(nojekyll_path)) {
    writeLines("", nojekyll_path)
    cat("   ✓ .nojekyll file created\n")
  }

  # Create GitHub Actions workflow for deployment
  workflow_dir <- file.path(path, ".github", "workflows")
  if (!dir.exists(workflow_dir)) {
    dir.create(workflow_dir, recursive = TRUE)
  }

  workflow_content <- c(
    "name: Deploy to GitHub Pages",
    "",
    "on:",
    "  push:",
    "    branches: [ ", branch, " ]",
    "  workflow_dispatch:",
    "",
    "permissions:",
    "  contents: read",
    "  pages: write",
    "  id-token: write",
    "",
    "concurrency:",
    "  group: \"pages\"",
    "  cancel-in-progress: false",
    "",
    "jobs:",
    "  deploy:",
    "    environment:",
    "      name: github-pages",
    "      url: ${{ steps.deployment.outputs.page_url }}",
    "    runs-on: ubuntu-latest",
    "    steps:",
    "      - name: Checkout",
    "        uses: actions/checkout@v4",
    "      - name: Setup Pages",
    "        uses: actions/configure-pages@v4",
    "      - name: Upload artifact",
    "        uses: actions/upload-pages-artifact@v3",
    "        with:",
    "          path: ", docs_subdir,
    "      - name: Deploy to GitHub Pages",
    "        id: deployment",
    "        uses: actions/deploy-pages@v4"
  )

  workflow_file <- file.path(workflow_dir, "deploy.yml")
  writeLines(workflow_content, workflow_file)
  cat("   ✓ GitHub Actions workflow created\n")
}

#' Configure GitLab Pages
#' @param path Dashboard path
#' @param branch Branch name
#' @param docs_subdir Docs subdirectory
#' @noRd
.configure_gitlab_pages <- function(path, branch, docs_subdir) {
  # Create .gitlab-ci.yml
  gitlab_ci_content <- c(
    "pages:",
    "  stage: deploy",
    "  script:",
    "    - echo 'Deploying to GitLab Pages'",
    "  artifacts:",
    "    paths:",
    "      - ", docs_subdir,
    "  only:",
    "    - ", branch
  )

  gitlab_ci_path <- file.path(path, ".gitlab-ci.yml")
  writeLines(gitlab_ci_content, gitlab_ci_path)
  cat("   ✓ .gitlab-ci.yml created\n")
}

#' Commit and push changes using gert
#' @param path Dashboard path
#' @param commit_message Commit message
#' @param branch Branch name
#' @noRd
.commit_and_push <- function(path, commit_message, branch) {
  cat("📤 Committing and pushing changes...\n")

  # Check if gert is available
  if (!requireNamespace("gert", quietly = TRUE)) {
    cat("   ⚠️  gert package not available. Please install it:\n")
    cat("      install.packages('gert')\n")
    cat("   📝 Falling back to system git...\n")
    return(.commit_and_push_system(path, commit_message, branch))
  }

  tryCatch({
    # Check if there are changes to commit
    status <- gert::git_status(path)
    if (nrow(status) == 0) {
      cat("   ℹ️  No changes to commit\n")
      # Still try to push if there are commits but no changes
      remotes <- gert::git_remote_list(repo = path)
      if (nrow(remotes) > 0 && any(remotes$name == "origin")) {
        tryCatch({
          gert::git_push(remote = "origin", repo = path)
          cat("   ✓ Pushed existing commits to remote\n")
        }, error = function(e) {
          cat("   ⚠️  Push failed. Please check manually:\n")
          cat("      git push -u origin ", branch, "\n", sep = "")
          cat("      Error: ", e$message, "\n", sep = "")
        })
      }
      return(invisible(TRUE))
    }

    # Add all files
    gert::git_add(".", repo = path)

    # Commit changes
    gert::git_commit(commit_message, repo = path)
    cat("   ✓ Changes committed\n")

    # Check if remote exists
    remotes <- gert::git_remote_list(repo = path)
    if (nrow(remotes) == 0 || !any(remotes$name == "origin")) {
      cat("   ⚠️  No remote origin found. Please add remote manually:\n")
      cat("      git remote add origin <repository-url>\n")
      cat("      git push -u origin ", branch, "\n", sep = "")
    } else {
      # Push to remote
      tryCatch({
        gert::git_push(remote = "origin", repo = path)
        cat("   ✓ Changes pushed to remote\n")
      }, error = function(e) {
        cat("   ⚠️  Push failed. Trying to set upstream branch...\n")
        tryCatch({
          gert::git_push(remote = "origin", refspec = paste0("refs/heads/", branch, ":refs/heads/", branch), repo = path)
          cat("   ✓ Changes pushed to remote with upstream set\n")
        }, error = function(e2) {
          cat("   ⚠️  Push failed. Please check manually:\n")
          cat("      git push -u origin ", branch, "\n", sep = "")
          cat("      Error: ", e2$message, "\n", sep = "")
        })
      })
    }

  }, error = function(e) {
    cat("   ⚠️  gert failed, falling back to system git...\n")
    .commit_and_push_system(path, commit_message, branch)
  })

  invisible(TRUE)
}

#' Commit and push changes using system git (fallback)
#' @param path Dashboard path
#' @param commit_message Commit message
#' @param branch Branch name
#' @noRd
.commit_and_push_system <- function(path, commit_message, branch) {
  # Change to dashboard directory
  old_wd <- getwd()
  setwd(path)
  on.exit(setwd(old_wd), add = TRUE)

  tryCatch({
    # Add all files
    system2("git", c("add", "."), stdout = TRUE, stderr = TRUE)

    # Check if there are changes to commit
    status_result <- system2("git", c("status", "--porcelain"), stdout = TRUE)
    if (length(status_result) == 0 || all(status_result == "")) {
      cat("   ℹ️  No changes to commit\n")
      return(invisible(TRUE))
    }

    # Commit changes
    system2("git", c("commit", "-m", shQuote(commit_message)),
            stdout = TRUE, stderr = TRUE)
    cat("   ✓ Changes committed\n")

    # Check if remote exists before pushing
    remotes <- system2("git", c("remote", "-v"), stdout = TRUE, stderr = TRUE)
    if (length(remotes) == 0 || !any(grepl("origin", remotes))) {
      cat("   ⚠️  No remote origin found. Please add remote manually:\n")
      cat("      git remote add origin <repository-url>\n")
      cat("      git push -u origin ", branch, "\n", sep = "")
    } else {
      # Push to remote
      push_result <- system2("git", c("push", "-u", "origin", branch),
                            stdout = TRUE, stderr = TRUE)
      if (length(push_result) > 0 && any(grepl("pushed|Pushed", push_result))) {
        cat("   ✓ Changes pushed to remote\n")
      } else {
        cat("   ⚠️  Push may have failed. Please check manually:\n")
        cat("      git push -u origin ", branch, "\n", sep = "")
      }
    }

  }, error = function(e) {
    cat("   ⚠️  Could not commit/push automatically:\n")
    cat("      Error: ", e$message, "\n", sep = "")
    cat("   📝 Manual steps:\n")
    cat("      git add .\n")
    cat("      git commit -m \"", commit_message, "\"\n", sep = "")
    cat("      git push -u origin ", branch, "\n", sep = "")
  })

  invisible(TRUE)
}

#' Get deployment URL
#' @param platform Platform name
#' @param username Username
#' @param repo_name Repository name
#' @return Deployment URL
#' @noRd
.get_deployment_url <- function(platform, username, repo_name) {
  if (platform == "github") {
    paste0("https://", username, ".github.io/", repo_name)
  } else {
    paste0("https://", username, ".gitlab.io/", repo_name)
  }
}

#' Open URL in browser
#' @param url URL to open
#' @noRd
.open_url <- function(url) {
  if (interactive()) {
    tryCatch({
      utils::browseURL(url)
      cat("🌐 Opening dashboard in browser...\n")
    }, error = function(e) {
      cat("⚠️  Could not open browser automatically\n")
      cat("   Please visit: ", url, "\n", sep = "")
    })
  }
}




# ===================================================================
# Pipe Operator Support
# ===================================================================

# Import pipe operator from magrittr for fluent workflows
`%>%` <- magrittr::`%>%`

# ===================================================================
# Dashboard Publishing Functions
# ===================================================================

#' Publish dashboard to GitHub Pages or GitLab Pages
#'
#' This function automates the process of publishing a dashboard to GitHub Pages
#' or GitLab Pages. It handles git initialization, remote setup, and deployment
#' configuration.
#'
#' @param dashboard_path Path to the generated dashboard directory
#' @param platform Platform to publish to: "github" or "gitlab"
#' @param repo_name Name for the repository (defaults to dashboard directory name)
#' @param username GitHub/GitLab username (optional, will prompt if not provided)
#' @param private Whether to create a private repository (default: FALSE)
#' @param open_browser Whether to open the published dashboard in browser (default: TRUE)
#' @param commit_message Git commit message (default: "Deploy dashboard")
#' @param branch Branch to deploy from (default: "main")
#' @param docs_subdir Subdirectory containing the docs (default: "docs")
#' @param include_data Whether to include data files in the repository (default: FALSE)
#'
#' @return Invisibly returns the repository URL
#' @export
#'
#' @examples
#' \dontrun{
#' # After generating a dashboard
#' dashboard <- create_dashboard("my_dashboard") %>%
#'   add_page("Analysis", data = my_data, visualizations = my_viz) %>%
#'   generate_dashboard()
#'
#' # Publish to GitHub Pages
#' publish_dashboard("my_dashboard", platform = "github", username = "myusername")
#'
#' # Publish to GitLab Pages
#' publish_dashboard("my_dashboard", platform = "gitlab", username = "myusername")
#' }
publish_dashboard <- function(dashboard_path,
                             platform = c("github", "gitlab"),
                             repo_name = NULL,
                             username = NULL,
                             private = FALSE,
                             open_browser = FALSE,
                             commit_message = "Deploy dashboard",
                             branch = "main",
                             docs_subdir = "docs",
                             include_data = FALSE) {

  platform <- match.arg(platform)

  # Validate dashboard path
  if (!dir.exists(dashboard_path)) {
    stop("Dashboard directory does not exist: ", dashboard_path)
  }

  # Check if docs directory exists
  docs_path <- file.path(dashboard_path, docs_subdir)
  if (!dir.exists(docs_path)) {
    stop("Docs directory not found: ", docs_path,
         "\nMake sure to run generate_dashboard() first")
  }

  # Check if docs directory has content (at least one HTML file)
  html_files <- list.files(docs_path, pattern = "\\.html$", full.names = FALSE)
  if (length(html_files) == 0) {
    stop("Docs directory is empty or contains no HTML files: ", docs_path,
         "\nMake sure to run generate_dashboard() with render = TRUE first")
  }

  # Set default repo name
  if (is.null(repo_name)) {
    repo_name <- basename(normalizePath(dashboard_path))
  }

  # Get username if not provided
  if (is.null(username)) {
    username <- .get_username_interactive(platform)
  }

  cat("🚀 Publishing dashboard to ", platform, " Pages...\n", sep = "")
  cat("📁 Dashboard: ", dashboard_path, "\n", sep = "")
  cat("📦 Repository: ", username, "/", repo_name, "\n", sep = "")
  cat("🌐 Platform: ", platform, "\n\n", sep = "")

  # Step 1: Check for data files and warn user
  .check_data_files(dashboard_path, include_data)

  # Step 2: Initialize git repository
  .init_git_repo(dashboard_path)

  # Step 3: Create .gitignore
  .create_gitignore(dashboard_path, include_data)

  # Step 3: Create repository on platform
  repo_url <- .create_remote_repo(dashboard_path, platform, username, repo_name, private)

  # Step 4: Configure for Pages deployment
  .configure_pages_deployment(dashboard_path, platform, branch, docs_subdir)

  # Step 5: Commit and push
  .commit_and_push(dashboard_path, commit_message, branch)

  # Step 6: Get deployment URL
  deployment_url <- .get_deployment_url(platform, username, repo_name)

  cat("\n🎉 Dashboard published successfully!\n")
  cat("══════════════════════════════════════════════════\n")
  cat("🌐 Dashboard URL: ", deployment_url, "\n", sep = "")
  cat("📝 Repository: ", repo_url, "\n", sep = "")
  cat("\n⏱️  IMPORTANT: GitHub Pages deployment takes 2-5 minutes\n")
  cat("   Your dashboard will be available at the URL above once deployed\n")
  cat("   You can check deployment status in your repository's Actions tab\n\n")

  if (open_browser) {
    cat("🌐 Opening repository in browser (not dashboard - it's still building)...\n")
    .open_url(repo_url)
  } else {
    cat("💡 Tip: Visit the repository URL to monitor deployment progress\n")
  }

  invisible(deployment_url)
}

#' Get username interactively
#' @param platform Platform name
#' @return Username as string
#' @noRd
.get_username_interactive <- function(platform) {
  cat("Please enter your ", platform, " username:\n", sep = "")
  username <- readline("Username: ")

  if (is.null(username) || nchar(trimws(username)) == 0) {
    stop("Username is required for publishing")
  }

  trimws(username)
}

#' Initialize git repository using gert
#' @param path Dashboard path
#' @noRd
.init_git_repo <- function(path) {
  cat("📝 Initializing git repository...\n")

  # Check if already a git repo
  if (dir.exists(file.path(path, ".git"))) {
    cat("   ✓ Git repository already exists\n")
    return(invisible(TRUE))
  }

  # Check if gert is available
  if (!requireNamespace("gert", quietly = TRUE)) {
    cat("   ⚠️  gert package not available. Please install it:\n")
    cat("      install.packages('gert')\n")
    cat("   📝 Falling back to system git...\n")
    return(.init_git_repo_system(path))
  }

  tryCatch({
    # Initialize git repository using gert
    gert::git_init(path)

    # Set default branch to main
    gert::git_branch_create("main", path)

    cat("   ✓ Git repository initialized\n")
  }, error = function(e) {
    cat("   ⚠️  gert failed, falling back to system git...\n")
    .init_git_repo_system(path)
  })

  invisible(TRUE)
}

#' Initialize git repository using system git (fallback)
#' @param path Dashboard path
#' @noRd
.init_git_repo_system <- function(path) {
  old_wd <- getwd()
  setwd(path)
  on.exit(setwd(old_wd), add = TRUE)

  tryCatch({
    # Initialize git repository
    system2("git", c("init"), stdout = TRUE, stderr = TRUE)

    # Set default branch to main
    system2("git", c("branch", "-M", "main"), stdout = TRUE, stderr = TRUE)

    cat("   ✓ Git repository initialized\n")
  }, error = function(e) {
    stop("Failed to initialize git repository: ", e$message)
  })

  invisible(TRUE)
}

#' Check for data files and warn user
#' @param path Dashboard path
#' @param include_data Whether to include data files
#' @noRd
.check_data_files <- function(path, include_data) {
  cat("🔍 Checking for data files...\n")

  # Define comprehensive data file patterns
  data_patterns <- c(
    # R Data Files
    "*.rds", "*.RData", "*.rda", "*.RDS", "*.RDATA", "*.RDA",
    # CSV and Delimited Files
    "*.csv", "*.tsv", "*.txt", "*.dat", "*.tab",
    # Excel Files
    "*.xlsx", "*.xls", "*.xlsm", "*.xlsb",
    # Database Files
    "*.db", "*.sqlite", "*.sqlite3", "*.mdb", "*.accdb",
    # Statistical Software Files
    "*.sav", "*.dta", "*.sas7bdat", "*.por", "*.zsav",
    # JSON and XML (but exclude config files)
    "*.json", "*.xml",
    # Archive Files
    "*.zip", "*.tar", "*.tar.gz", "*.gz", "*.bz2", "*.7z", "*.rar",
    # Large Files
    "*.parquet", "*.feather", "*.fst", "*.h5", "*.hdf5"
  )

  # Find all data files
  data_files <- character(0)
  for (pattern in data_patterns) {
    # Convert glob pattern to regex
    regex_pattern <- gsub("\\*", ".*", pattern)
    # Make sure it matches the full filename, not just part of it
    regex_pattern <- paste0("^", regex_pattern, "$")

    files <- list.files(path, pattern = regex_pattern,
                       recursive = TRUE, full.names = FALSE, ignore.case = TRUE)
    data_files <- c(data_files, files)
  }

  # Also check for data directories
  data_dirs <- c("data", "datasets", "raw_data", "processed_data", "output_data")
  for (dir in data_dirs) {
    if (dir.exists(file.path(path, dir))) {
      data_files <- c(data_files, paste0(dir, "/"))
    }
  }

  # Check for large files (>10MB) that might be data
  large_files <- .find_large_files(path, size_mb = 10)
  if (length(large_files) > 0) {
    data_files <- c(data_files, large_files)
  }

  # Remove duplicates and sort
  data_files <- unique(sort(data_files))

  # Filter out common config files and Quarto-generated files that are not data
  config_files <- c("_quarto.yml", "quarto.yml", ".gitignore", "README.md", "LICENSE",
                   "DESCRIPTION", "NAMESPACE", "Makefile", "Dockerfile", ".dockerignore",
                   "index.html", "sitemap.xml", ".nojekyll")
  data_files <- data_files[!data_files %in% config_files]

  # Also filter out docs/search.json specifically (Quarto search index)
  data_files <- data_files[!grepl("^docs/search\\.json$", data_files)]

  if (length(data_files) > 0) {
    if (!include_data) {
      cat("   ⚠️  Found ", length(data_files), " data file(s) that will be EXCLUDED:\n", sep = "")
      for (file in head(data_files, 10)) {  # Show first 10
        cat("      - ", file, "\n", sep = "")
      }
      if (length(data_files) > 10) {
        cat("      ... and ", length(data_files) - 10, " more\n", sep = "")
      }
      cat("\n   🔒 Data files are excluded by default for security and size reasons\n")
      cat("   💡 To include data files, use: include_data = TRUE\n")
      cat("   ⚠️  WARNING: Only include data if you have permission to share it publicly\n\n")
    } else {
      cat("   ⚠️  Found ", length(data_files), " data file(s) that will be INCLUDED:\n", sep = "")
      for (file in head(data_files, 10)) {  # Show first 10
        cat("      - ", file, "\n", sep = "")
      }
      if (length(data_files) > 10) {
        cat("      ... and ", length(data_files) - 10, " more\n", sep = "")
      }
      cat("\n   ⚠️  WARNING: Data files will be committed to the repository!\n")
      cat("   🔒 Make sure you have permission to share this data publicly\n")
      cat("   💡 Consider using a private repository for sensitive data\n\n")
    }
  } else {
    cat("   ✓ No data files detected\n")
  }

  invisible(data_files)
}

#' Find large files that might be data
#' @param path Directory path
#' @param size_mb Minimum size in MB
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

#' Create comprehensive .gitignore file
#' @param path Dashboard path
#' @param include_data Whether to include data files (default: FALSE)
#' @noRd
.create_gitignore <- function(path, include_data = FALSE) {
  gitignore_path <- file.path(path, ".gitignore")

  if (file.exists(gitignore_path)) {
    cat("   ✓ .gitignore already exists\n")
    return(invisible(TRUE))
  }

  gitignore_content <- c(
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
    "*.log"
  )

  # Add comprehensive data exclusions unless explicitly included
  if (!include_data) {
    data_exclusions <- c(
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
    gitignore_content <- c(gitignore_content, data_exclusions)
  } else {
    # If data is included, add a warning comment
    warning_content <- c(
      "",
      "# WARNING: Data files are being included in this repository",
      "# Make sure this is intentional and that you have permission to share this data",
      "# Consider using a private repository for sensitive data"
    )
    gitignore_content <- c(gitignore_content, warning_content)
  }

  writeLines(gitignore_content, gitignore_path)
  cat("   ✓ .gitignore created\n")

  invisible(TRUE)
}

#' Create remote repository
#' @param path Dashboard path
#' @param platform Platform name
#' @param username Username
#' @param repo_name Repository name
#' @param private Whether private
#' @return Repository URL
#' @noRd
.create_remote_repo <- function(path, platform, username, repo_name, private) {
  cat("📦 Creating ", platform, " repository...\n", sep = "")

  repo_url <- if (platform == "github") {
    paste0("https://github.com/", username, "/", repo_name, ".git")
  } else {
    paste0("https://gitlab.com/", username, "/", repo_name, ".git")
  }

  # Check if usethis is available
  if (!requireNamespace("usethis", quietly = TRUE)) {
    cat("   ⚠️  usethis package not available. Please install it:\n")
    cat("      install.packages('usethis')\n")
    cat("   📝 Manual steps required:\n")
    cat("      1. Create repository at: ", repo_url, "\n", sep = "")
    cat("      2. Add remote: git remote add origin ", repo_url, "\n", sep = "")
    return(repo_url)
  }

  # Try to create repository using GitHub API
  tryCatch({
    .create_github_repo_simple(path, username, repo_name, private)
    cat("   ✓ Repository created successfully\n")
  }, error = function(e) {
    cat("   ⚠️  Could not create repository automatically:\n")
    cat("      Error: ", e$message, "\n", sep = "")
    cat("   📝 Please create repository manually:\n")
    cat("      URL: ", repo_url, "\n", sep = "")
    cat("   💡 Quick setup options:\n")
    cat("      1. Web interface: Visit https://github.com/new\n")
    cat("         - Repository name: ", repo_name, "\n", sep = "")
    cat("         - Visibility: ", if(private) "Private" else "Public", "\n", sep = "")
    cat("         - Don't initialize with README, .gitignore, or license\n")
    cat("      2. Then run these commands in your dashboard directory:\n")
    cat("         git remote add origin ", repo_url, "\n", sep = "")
    cat("         git push -u origin main\n", sep = "")
    cat("   🔧 Alternative: Use GitHub CLI if installed:\n")
    cat("         gh repo create ", username, "/", repo_name, " --", if(private) "private" else "public", " --source=. --remote=origin --push\n", sep = "")
  })

  invisible(repo_url)
}

#' Create GitHub repository using simple API approach
#' @param path Dashboard path
#' @param username GitHub username
#' @param repo_name Repository name
#' @param private Whether repository should be private
#' @noRd
.create_github_repo_simple <- function(path, username, repo_name, private) {
  # Check if httr is available
  if (!requireNamespace("httr", quietly = TRUE)) {
    stop("httr package is required for GitHub API calls. Please install it: install.packages('httr')")
  }

  # Get GitHub token from environment or usethis
  token <- Sys.getenv("GITHUB_PAT")
  if (token == "") {
    # Try to get token from usethis
    if (requireNamespace("usethis", quietly = TRUE)) {
      tryCatch({
        token <- usethis::gh_token()
      }, error = function(e) {
        stop("No GitHub token found. Please set GITHUB_PAT environment variable or run usethis::create_github_token()")
      })
    } else {
      stop("No GitHub token found. Please set GITHUB_PAT environment variable")
    }
  }

  # GitHub API endpoint
  url <- "https://api.github.com/user/repos"

  # Repository data
  repo_data <- list(
    name = repo_name,
    description = paste("Dashboard created with dashboardr package"),
    private = private,
    auto_init = FALSE
  )

  # Make API request
  response <- httr::POST(
    url,
    httr::add_headers(
      Authorization = paste("token", token),
      "User-Agent" = "dashboardr-package"
    ),
    httr::content_type_json(),
    body = jsonlite::toJSON(repo_data, auto_unbox = TRUE)
  )

  # Check response
  if (httr::status_code(response) == 201) {
    # Repository created successfully, add remote
    repo_url <- paste0("https://github.com/", username, "/", repo_name, ".git")

    # Add or update remote using gert or system git
    if (requireNamespace("gert", quietly = TRUE)) {
      tryCatch({
        # Check if remote already exists
        remotes <- gert::git_remote_list(repo = path)
        if (nrow(remotes) > 0 && any(remotes$name == "origin")) {
          # Update existing remote
          gert::git_remote_set_url("origin", repo_url, repo = path)
        } else {
          # Add new remote
          gert::git_remote_add("origin", repo_url, repo = path)
        }
      }, error = function(e) {
        # If gert fails, try system git
        old_wd <- getwd()
        setwd(path)
        on.exit(setwd(old_wd), add = TRUE)
        # Check if remote exists and update or add
        existing_remotes <- system2("git", c("remote", "-v"), stdout = TRUE, stderr = TRUE)
        if (length(existing_remotes) > 0 && any(grepl("origin", existing_remotes))) {
          system2("git", c("remote", "set-url", "origin", repo_url), stdout = TRUE, stderr = TRUE)
        } else {
          system2("git", c("remote", "add", "origin", repo_url), stdout = TRUE, stderr = TRUE)
        }
      })
    } else {
      old_wd <- getwd()
      setwd(path)
      on.exit(setwd(old_wd), add = TRUE)
      # Check if remote exists and update or add
      existing_remotes <- system2("git", c("remote", "-v"), stdout = TRUE, stderr = TRUE)
      if (length(existing_remotes) > 0 && any(grepl("origin", existing_remotes))) {
        system2("git", c("remote", "set-url", "origin", repo_url), stdout = TRUE, stderr = TRUE)
      } else {
        system2("git", c("remote", "add", "origin", repo_url), stdout = TRUE, stderr = TRUE)
      }
    }

    cat("   ✓ Remote origin added/updated\n")

    return(invisible(TRUE))
  } else if (httr::status_code(response) == 422) {
    # Repository already exists - this is actually fine, just add the remote
    repo_url <- paste0("https://github.com/", username, "/", repo_name, ".git")

    # Add or update remote using gert or system git
    if (requireNamespace("gert", quietly = TRUE)) {
      tryCatch({
        # Check if remote already exists
        remotes <- gert::git_remote_list(repo = path)
        if (nrow(remotes) > 0 && any(remotes$name == "origin")) {
          # Update existing remote
          gert::git_remote_set_url("origin", repo_url, repo = path)
        } else {
          # Add new remote
          gert::git_remote_add("origin", repo_url, repo = path)
        }
      }, error = function(e) {
        # If gert fails, try system git
        old_wd <- getwd()
        setwd(path)
        on.exit(setwd(old_wd), add = TRUE)
        # Check if remote exists and update or add
        existing_remotes <- system2("git", c("remote", "-v"), stdout = TRUE, stderr = TRUE)
        if (length(existing_remotes) > 0 && any(grepl("origin", existing_remotes))) {
          system2("git", c("remote", "set-url", "origin", repo_url), stdout = TRUE, stderr = TRUE)
        } else {
          system2("git", c("remote", "add", "origin", repo_url), stdout = TRUE, stderr = TRUE)
        }
      })
    } else {
      old_wd <- getwd()
      setwd(path)
      on.exit(setwd(old_wd), add = TRUE)
      # Check if remote exists and update or add
      existing_remotes <- system2("git", c("remote", "-v"), stdout = TRUE, stderr = TRUE)
      if (length(existing_remotes) > 0 && any(grepl("origin", existing_remotes))) {
        system2("git", c("remote", "set-url", "origin", repo_url), stdout = TRUE, stderr = TRUE)
      } else {
        system2("git", c("remote", "add", "origin", repo_url), stdout = TRUE, stderr = TRUE)
      }
    }

    cat("   ✓ Repository already exists, remote origin added/updated\n")

    return(invisible(TRUE))
  } else {
    # Parse error message
    error_content <- httr::content(response, "text")
    error_msg <- "Unknown error"
    tryCatch({
      error_json <- jsonlite::fromJSON(error_content)
      if ("message" %in% names(error_json)) {
        error_msg <- error_json$message
      }
    }, error = function(e) {
      error_msg <- error_content
    })

    stop("GitHub API error (", httr::status_code(response), "): ", error_msg)
  }
}

#' Add remote if it doesn't exist
#' @param path Dashboard path
#' @param repo_url Repository URL
#' @noRd
.add_remote_if_needed <- function(path, repo_url) {
  # Check if gert is available
  if (!requireNamespace("gert", quietly = TRUE)) {
    return(invisible(FALSE))
  }

  tryCatch({
    # Check if remote exists
    remotes <- gert::git_remote_list(repo = path)
    if (nrow(remotes) == 0 || !any(remotes$name == "origin")) {
      # Add remote
      gert::git_remote_add("origin", repo_url, repo = path)
      cat("   ✓ Remote origin added\n")
    }
  }, error = function(e) {
    # Silent fail - remote might already exist or other issue
  })

  invisible(TRUE)
}

#' Configure Pages deployment
#' @param path Dashboard path
#' @param platform Platform name
#' @param branch Branch name
#' @param docs_subdir Docs subdirectory
#' @noRd
.configure_pages_deployment <- function(path, platform, branch, docs_subdir) {
  cat("⚙️  Configuring ", platform, " Pages deployment...\n", sep = "")

  if (platform == "github") {
    .configure_github_pages(path, branch, docs_subdir)
  } else {
    .configure_gitlab_pages(path, branch, docs_subdir)
  }

  invisible(TRUE)
}

#' Configure GitHub Pages
#' @param path Dashboard path
#' @param branch Branch name
#' @param docs_subdir Docs subdirectory
#' @noRd
.configure_github_pages <- function(path, branch, docs_subdir) {
  # Ensure the directory exists
  if (!dir.exists(path)) {
    stop("Dashboard directory does not exist: ", path)
  }

  # Create .nojekyll file to prevent Jekyll processing
  nojekyll_path <- file.path(path, ".nojekyll")
  if (!file.exists(nojekyll_path)) {
    writeLines("", nojekyll_path)
    cat("   ✓ .nojekyll file created\n")
  }

  # Create GitHub Actions workflow for deployment
  workflow_dir <- file.path(path, ".github", "workflows")
  if (!dir.exists(workflow_dir)) {
    dir.create(workflow_dir, recursive = TRUE)
  }

  workflow_content <- c(
    "name: Deploy to GitHub Pages",
    "",
    "on:",
    "  push:",
    "    branches: [ ", branch, " ]",
    "  workflow_dispatch:",
    "",
    "permissions:",
    "  contents: read",
    "  pages: write",
    "  id-token: write",
    "",
    "concurrency:",
    "  group: \"pages\"",
    "  cancel-in-progress: false",
    "",
    "jobs:",
    "  deploy:",
    "    environment:",
    "      name: github-pages",
    "      url: ${{ steps.deployment.outputs.page_url }}",
    "    runs-on: ubuntu-latest",
    "    steps:",
    "      - name: Checkout",
    "        uses: actions/checkout@v4",
    "      - name: Setup Pages",
    "        uses: actions/configure-pages@v4",
    "      - name: Upload artifact",
    "        uses: actions/upload-pages-artifact@v3",
    "        with:",
    "          path: ", docs_subdir,
    "      - name: Deploy to GitHub Pages",
    "        id: deployment",
    "        uses: actions/deploy-pages@v4"
  )

  workflow_file <- file.path(workflow_dir, "deploy.yml")
  writeLines(workflow_content, workflow_file)
  cat("   ✓ GitHub Actions workflow created\n")
}

#' Configure GitLab Pages
#' @param path Dashboard path
#' @param branch Branch name
#' @param docs_subdir Docs subdirectory
#' @noRd
.configure_gitlab_pages <- function(path, branch, docs_subdir) {
  # Create .gitlab-ci.yml
  gitlab_ci_content <- c(
    "pages:",
    "  stage: deploy",
    "  script:",
    "    - echo 'Deploying to GitLab Pages'",
    "  artifacts:",
    "    paths:",
    "      - ", docs_subdir,
    "  only:",
    "    - ", branch
  )

  gitlab_ci_path <- file.path(path, ".gitlab-ci.yml")
  writeLines(gitlab_ci_content, gitlab_ci_path)
  cat("   ✓ .gitlab-ci.yml created\n")
}

#' Commit and push changes using gert
#' @param path Dashboard path
#' @param commit_message Commit message
#' @param branch Branch name
#' @noRd
.commit_and_push <- function(path, commit_message, branch) {
  cat("📤 Committing and pushing changes...\n")

  # Check if gert is available
  if (!requireNamespace("gert", quietly = TRUE)) {
    cat("   ⚠️  gert package not available. Please install it:\n")
    cat("      install.packages('gert')\n")
    cat("   📝 Falling back to system git...\n")
    return(.commit_and_push_system(path, commit_message, branch))
  }

  tryCatch({
    # Check if there are changes to commit
    status <- gert::git_status(path)
    if (nrow(status) == 0) {
      cat("   ℹ️  No changes to commit\n")
      # Still try to push if there are commits but no changes
      remotes <- gert::git_remote_list(repo = path)
      if (nrow(remotes) > 0 && any(remotes$name == "origin")) {
        tryCatch({
          gert::git_push(remote = "origin", repo = path)
          cat("   ✓ Pushed existing commits to remote\n")
        }, error = function(e) {
          cat("   ⚠️  Push failed. Please check manually:\n")
          cat("      git push -u origin ", branch, "\n", sep = "")
          cat("      Error: ", e$message, "\n", sep = "")
        })
      }
      return(invisible(TRUE))
    }

    # Add all files
    gert::git_add(".", repo = path)

    # Commit changes
    gert::git_commit(commit_message, repo = path)
    cat("   ✓ Changes committed\n")

    # Check if remote exists
    remotes <- gert::git_remote_list(repo = path)
    if (nrow(remotes) == 0 || !any(remotes$name == "origin")) {
      cat("   ⚠️  No remote origin found. Please add remote manually:\n")
      cat("      git remote add origin <repository-url>\n")
      cat("      git push -u origin ", branch, "\n", sep = "")
    } else {
      # Push to remote
      tryCatch({
        gert::git_push(remote = "origin", repo = path)
        cat("   ✓ Changes pushed to remote\n")
      }, error = function(e) {
        cat("   ⚠️  Push failed. Trying to set upstream branch...\n")
        tryCatch({
          gert::git_push(remote = "origin", refspec = paste0("refs/heads/", branch, ":refs/heads/", branch), repo = path)
          cat("   ✓ Changes pushed to remote with upstream set\n")
        }, error = function(e2) {
          cat("   ⚠️  Push failed. Please check manually:\n")
          cat("      git push -u origin ", branch, "\n", sep = "")
          cat("      Error: ", e2$message, "\n", sep = "")
        })
      })
    }

  }, error = function(e) {
    cat("   ⚠️  gert failed, falling back to system git...\n")
    .commit_and_push_system(path, commit_message, branch)
  })

  invisible(TRUE)
}

#' Commit and push changes using system git (fallback)
#' @param path Dashboard path
#' @param commit_message Commit message
#' @param branch Branch name
#' @noRd
.commit_and_push_system <- function(path, commit_message, branch) {
  # Change to dashboard directory
  old_wd <- getwd()
  setwd(path)
  on.exit(setwd(old_wd), add = TRUE)

  tryCatch({
    # Add all files
    system2("git", c("add", "."), stdout = TRUE, stderr = TRUE)

    # Check if there are changes to commit
    status_result <- system2("git", c("status", "--porcelain"), stdout = TRUE)
    if (length(status_result) == 0 || all(status_result == "")) {
      cat("   ℹ️  No changes to commit\n")
      return(invisible(TRUE))
    }

    # Commit changes
    system2("git", c("commit", "-m", shQuote(commit_message)),
            stdout = TRUE, stderr = TRUE)
    cat("   ✓ Changes committed\n")

    # Check if remote exists before pushing
    remotes <- system2("git", c("remote", "-v"), stdout = TRUE, stderr = TRUE)
    if (length(remotes) == 0 || !any(grepl("origin", remotes))) {
      cat("   ⚠️  No remote origin found. Please add remote manually:\n")
      cat("      git remote add origin <repository-url>\n")
      cat("      git push -u origin ", branch, "\n", sep = "")
    } else {
      # Push to remote
      push_result <- system2("git", c("push", "-u", "origin", branch),
                            stdout = TRUE, stderr = TRUE)
      if (length(push_result) > 0 && any(grepl("pushed|Pushed", push_result))) {
        cat("   ✓ Changes pushed to remote\n")
      } else {
        cat("   ⚠️  Push may have failed. Please check manually:\n")
        cat("      git push -u origin ", branch, "\n", sep = "")
      }
    }

  }, error = function(e) {
    cat("   ⚠️  Could not commit/push automatically:\n")
    cat("      Error: ", e$message, "\n", sep = "")
    cat("   📝 Manual steps:\n")
    cat("      git add .\n")
    cat("      git commit -m \"", commit_message, "\"\n", sep = "")
    cat("      git push -u origin ", branch, "\n", sep = "")
  })

  invisible(TRUE)
}

#' Get deployment URL
#' @param platform Platform name
#' @param username Username
#' @param repo_name Repository name
#' @return Deployment URL
#' @noRd
.get_deployment_url <- function(platform, username, repo_name) {
  if (platform == "github") {
    paste0("https://", username, ".github.io/", repo_name)
  } else {
    paste0("https://", username, ".gitlab.io/", repo_name)
  }
}

#' Open URL in browser
#' @param url URL to open
#' @noRd
.open_url <- function(url) {
  if (interactive()) {
    tryCatch({
      utils::browseURL(url)
      cat("🌐 Opening dashboard in browser...\n")
    }, error = function(e) {
      cat("⚠️  Could not open browser automatically\n")
      cat("   Please visit: ", url, "\n", sep = "")
    })
  }
}
