# Publish dashboard to GitHub Pages or GitLab Pages

This function automates the process of publishing a dashboard to GitHub
Pages or GitLab Pages. It handles git initialization, remote setup, and
deployment configuration.

This function automates the process of publishing a dashboard to GitHub
Pages or GitLab Pages. It handles git initialization, remote setup, and
deployment configuration.

## Usage

``` r
publish_dashboard(
  dashboard_path,
  platform = c("github", "gitlab"),
  repo_name = NULL,
  username = NULL,
  private = FALSE,
  open_browser = FALSE,
  commit_message = "Deploy dashboard",
  branch = "main",
  docs_subdir = "docs",
  include_data = FALSE
)

publish_dashboard(
  dashboard_path,
  platform = c("github", "gitlab"),
  repo_name = NULL,
  username = NULL,
  private = FALSE,
  open_browser = FALSE,
  commit_message = "Deploy dashboard",
  branch = "main",
  docs_subdir = "docs",
  include_data = FALSE
)
```

## Arguments

- dashboard_path:

  Path to the generated dashboard directory

- platform:

  Platform to publish to: "github" or "gitlab"

- repo_name:

  Name for the repository (defaults to dashboard directory name)

- username:

  GitHub/GitLab username (optional, will prompt if not provided)

- private:

  Whether to create a private repository (default: FALSE)

- open_browser:

  Whether to open the published dashboard in browser (default: TRUE)

- commit_message:

  Git commit message (default: "Deploy dashboard")

- branch:

  Branch to deploy from (default: "main")

- docs_subdir:

  Subdirectory containing the docs (default: "docs")

- include_data:

  Whether to include data files in the repository (default: FALSE)

## Value

Invisibly returns the repository URL

Invisibly returns the repository URL

## Examples

``` r
if (FALSE) { # \dontrun{
# After generating a dashboard
dashboard <- create_dashboard("my_dashboard") %>%
  add_page("Analysis", data = my_data, visualizations = my_viz) %>%
  generate_dashboard()

# Publish to GitHub Pages
publish_dashboard("my_dashboard", platform = "github", username = "myusername")

# Publish to GitLab Pages
publish_dashboard("my_dashboard", platform = "gitlab", username = "myusername")
} # }
if (FALSE) { # \dontrun{
# After generating a dashboard
dashboard <- create_dashboard("my_dashboard") %>%
  add_page("Analysis", data = my_data, visualizations = my_viz) %>%
  generate_dashboard()

# Publish to GitHub Pages
publish_dashboard("my_dashboard", platform = "github", username = "myusername")

# Publish to GitLab Pages
publish_dashboard("my_dashboard", platform = "gitlab", username = "myusername")
} # }
```
