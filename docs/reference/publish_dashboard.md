# Publish dashboard to GitHub Pages

This function automates the process of publishing a dashboard to GitHub
Pages. It handles git initialization, .gitignore setup, GitHub
repository creation, and GitHub Pages configuration using usethis
functions.

## Usage

``` r
publish_dashboard(
  message = "Initial commit",
  restart = FALSE,
  organisation = NULL,
  private = NULL,
  protocol = c("https", "ssh"),
  branch = usethis::git_default_branch(),
  path = "/docs",
  ask = TRUE,
  ...
)
```

## Arguments

- message:

  Initial commit message (default: "Initial commit")

- restart:

  Whether to restart RStudio after git initialization (default: FALSE)

- organisation:

  GitHub organisation name (optional, for org repositories)

- private:

  Whether to create a private repository. When `NULL` (default) and
  `ask = TRUE`, you will be prompted interactively. Set to `TRUE` or
  `FALSE` to skip the prompt.

- protocol:

  Transfer protocol: "https" or "ssh" (default: "https")

- branch:

  Branch to deploy from (default: uses git default branch)

- path:

  Path containing the site files (default: "/docs")

- ask:

  Whether to use the interactive confirmation workflow (default: TRUE).
  When `TRUE`, guides you through file review and confirmation steps.
  Set to `FALSE` to skip all prompts (not recommended for first-time
  use).

- ...:

  Additional arguments passed to
  [`usethis::use_github()`](https://usethis.r-lib.org/reference/use_github.html)

## Value

Invisibly returns TRUE if published successfully, FALSE if cancelled

## Details

When `ask = TRUE` (the default), the function guides you through a
3-step interactive confirmation process:

1.  **File Review**: Shows you the files that will be published and
    opens a folder so you can verify nothing unintended is included

2.  **Repository Privacy**: Asks whether to create a private or public
    repository

3.  **Confirm Publish**: Final confirmation before publishing to GitHub

## What Gets Published

Typically, you only need to publish:

- The `docs/` folder (auto-generated HTML, CSS, JS files)

- Optionally, your R scripts (just for reproducibility)

By default, common data file extensions (.csv, .rds, .xlsx, .sav, .dta)
are automatically excluded via .gitignore. Use
[`usethis::use_git_ignore()`](https://usethis.r-lib.org/reference/use_git_ignore.html)
to exclude additional files you don't want to publish.

## Examples

``` r
if (FALSE) { # \dontrun{
# After generating a dashboard, navigate to the dashboard directory
# and publish it (interactive mode):
setwd("my_dashboard")
publish_dashboard()

# Publish to an organization
publish_dashboard(organisation = "my-org")

# Create a private repository (skip privacy prompt)
publish_dashboard(private = TRUE)

# Skip all prompts (use with caution)
publish_dashboard(ask = FALSE, private = FALSE)
} # }
```
