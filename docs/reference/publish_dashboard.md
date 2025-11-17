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
  private = FALSE,
  protocol = c("https", "ssh"),
  branch = usethis::git_default_branch(),
  path = "/docs",
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

  Whether to create a private repository (default: FALSE)

- protocol:

  Transfer protocol: "https" or "ssh" (default: "https")

- branch:

  Branch to deploy from (default: uses git default branch)

- path:

  Path containing the site files (default: "/docs")

- ...:

  Additional arguments passed to
  [`usethis::use_github()`](https://usethis.r-lib.org/reference/use_github.html)

## Value

Invisibly returns TRUE

## Examples

``` r
if (FALSE) { # \dontrun{
# After generating a dashboard, navigate to the dashboard directory
# and publish it:
setwd("my_dashboard")
publish_dashboard()

# Publish to an organization
publish_dashboard(organisation = "my-org")

# Create a private repository
publish_dashboard(private = TRUE)
} # }
```
