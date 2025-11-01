# Create a dashboard

Initializes a dashboard project object that can be built up using the
piping workflow with add_landingpage() and add_page().

## Usage

``` r
create_dashboard(
  output_dir = "site",
  title = "Dashboard",
  logo = NULL,
  favicon = NULL,
  github = NULL,
  twitter = NULL,
  linkedin = NULL,
  email = NULL,
  website = NULL,
  search = TRUE,
  theme = NULL,
  custom_css = NULL,
  custom_scss = NULL,
  author = NULL,
  description = NULL,
  page_footer = NULL,
  date = NULL,
  sidebar = FALSE,
  sidebar_style = "docked",
  sidebar_background = "light",
  sidebar_foreground = NULL,
  sidebar_border = TRUE,
  sidebar_alignment = "left",
  sidebar_collapse_level = 2,
  sidebar_pinned = FALSE,
  sidebar_tools = NULL,
  sidebar_contents = NULL,
  breadcrumbs = TRUE,
  page_navigation = FALSE,
  back_to_top = FALSE,
  reader_mode = FALSE,
  repo_url = NULL,
  repo_actions = NULL,
  navbar_style = NULL,
  navbar_brand = NULL,
  navbar_toggle = NULL,
  math = NULL,
  code_folding = NULL,
  code_tools = NULL,
  toc = NULL,
  toc_depth = 3,
  google_analytics = NULL,
  plausible = NULL,
  gtag = NULL,
  value_boxes = FALSE,
  metrics_style = NULL,
  page_layout = NULL,
  shiny = FALSE,
  observable = FALSE,
  jupyter = FALSE,
  publish_dir = NULL,
  github_pages = NULL,
  netlify = NULL,
  allow_inside_pkg = FALSE,
  warn_before_overwrite = TRUE,
  sidebar_groups = NULL,
  navbar_sections = NULL
)

create_dashboard(
  output_dir = "site",
  title = "Dashboard",
  logo = NULL,
  favicon = NULL,
  github = NULL,
  twitter = NULL,
  linkedin = NULL,
  email = NULL,
  website = NULL,
  search = TRUE,
  theme = NULL,
  custom_css = NULL,
  custom_scss = NULL,
  author = NULL,
  description = NULL,
  page_footer = NULL,
  date = NULL,
  sidebar = FALSE,
  sidebar_style = "docked",
  sidebar_background = "light",
  sidebar_foreground = NULL,
  sidebar_border = TRUE,
  sidebar_alignment = "left",
  sidebar_collapse_level = 2,
  sidebar_pinned = FALSE,
  sidebar_tools = NULL,
  sidebar_contents = NULL,
  breadcrumbs = TRUE,
  page_navigation = FALSE,
  back_to_top = FALSE,
  reader_mode = FALSE,
  repo_url = NULL,
  repo_actions = NULL,
  navbar_style = NULL,
  navbar_brand = NULL,
  navbar_toggle = NULL,
  math = NULL,
  code_folding = NULL,
  code_tools = NULL,
  toc = NULL,
  toc_depth = 3,
  google_analytics = NULL,
  plausible = NULL,
  gtag = NULL,
  value_boxes = FALSE,
  metrics_style = NULL,
  page_layout = NULL,
  shiny = FALSE,
  observable = FALSE,
  jupyter = FALSE,
  publish_dir = NULL,
  github_pages = NULL,
  netlify = NULL,
  allow_inside_pkg = FALSE,
  warn_before_overwrite = TRUE,
  sidebar_groups = NULL,
  navbar_sections = NULL
)
```

## Arguments

- output_dir:

  Directory for generated files

- title:

  Overall title for the dashboard site

- logo:

  Optional logo filename (will be copied to output directory)

- favicon:

  Optional favicon filename (will be copied to output directory)

- github:

  GitHub repository URL (optional)

- twitter:

  Twitter profile URL (optional)

- linkedin:

  LinkedIn profile URL (optional)

- email:

  Email address (optional)

- website:

  Website URL (optional)

- search:

  Enable search functionality (default: TRUE)

- theme:

  Bootstrap theme (cosmo, flatly, journal, etc.) (optional)

- custom_css:

  Path to custom CSS file (optional)

- custom_scss:

  Path to custom SCSS file (optional)

- author:

  Author name for the site (optional)

- description:

  Site description for SEO (optional)

- page_footer:

  Custom footer text (optional)

- date:

  Site creation/update date (optional)

- sidebar:

  Enable/disable global sidebar (default: FALSE)

- sidebar_style:

  Sidebar style (floating, docked, etc.) (optional)

- sidebar_background:

  Sidebar background color (optional)

- navbar_style:

  Navbar style (default, dark, light) (optional)

- navbar_brand:

  Custom brand text (optional)

- navbar_toggle:

  Mobile menu toggle behavior (optional)

- math:

  Enable/disable math rendering (katex, mathjax) (optional)

- code_folding:

  Code folding behavior (none, show, hide) (optional)

- code_tools:

  Code tools (copy, download, etc.) (optional)

- toc:

  Table of contents (floating, left, right) (optional)

- toc_depth:

  TOC depth level (default: 3)

- google_analytics:

  Google Analytics ID (optional)

- plausible:

  Plausible analytics domain (optional)

- gtag:

  Google Tag Manager ID (optional)

- value_boxes:

  Enable value box styling (default: FALSE)

- metrics_style:

  Metrics display style (optional)

- shiny:

  Enable Shiny interactivity (default: FALSE)

- observable:

  Enable Observable JS (default: FALSE)

- jupyter:

  Enable Jupyter widgets (default: FALSE)

- publish_dir:

  Custom publish directory (optional)

- github_pages:

  GitHub Pages configuration (optional)

- netlify:

  Netlify deployment settings (optional)

- allow_inside_pkg:

  Allow output directory inside package (default FALSE)

- warn_before_overwrite:

  Warn before overwriting existing files (default TRUE)

- sidebar_groups:

  List of sidebar groups for hybrid navigation (optional)

- navbar_sections:

  List of navbar sections that link to sidebar groups (optional)

- data:

  A data.frame or a named list of data.frames (for multi-page site).

- dashboard_name:

  Name for the dashboard (used when `site = FALSE`).

- site:

  If TRUE, scaffold a website with index + dashboards.

- render:

  If TRUE, render HTML with Quarto immediately.

- open:

  If TRUE, open the rendered HTML in your browser (forces render).

## Value

A dashboard_project object

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic dashboard
dashboard <- create_dashboard("my_dashboard", "My Analysis Dashboard")

# Comprehensive dashboard with all features
dashboard <- create_dashboard(
  "my_dashboard",
  "My Analysis Dashboard",
  logo = "logo.png",
  github = "https://github.com/username/repo",
  twitter = "https://twitter.com/username",
  theme = "cosmo",
  author = "Dr. Jane Smith",
  description = "Comprehensive data analysis dashboard",
  page_footer = "© 2024 Company Name",
  sidebar = TRUE,
  toc = "floating",
  google_analytics = "GA-XXXXXXXXX",
  value_boxes = TRUE,
  shiny = TRUE
)
} # }
```
