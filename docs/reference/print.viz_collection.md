# Create a new dashboard project

Initializes a dashboard project object that can be built up using the
piping workflow with add_landingpage() and add_page().

## Usage

``` r
# S3 method for class 'viz_collection'
print(x, render = FALSE, ...)
```

## Arguments

- x:

  A viz_collection object created by
  [`create_viz`](https://favstats.github.io/dashboardr/reference/create_viz.md).

- render:

  If TRUE and data is attached, opens a preview in the viewer instead of
  showing the structure. Default is FALSE.

- ...:

  Additional arguments (currently ignored).

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

## Value

A dashboard_project object

Invisibly returns the input object `x`.

## Details

The print method displays:

- Total number of visualizations

- Default parameters (if set)

- Hierarchical tree structure showing tabgroup organization

- Visualization types with emoji indicators

- Filter status for each visualization

Use `print(x, render = TRUE)` to open a preview in the viewer instead of
showing the structure. This is useful for quick visualization in the
console.

## Examples
