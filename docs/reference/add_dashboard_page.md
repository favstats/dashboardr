# Add a page to the dashboard

Universal function for adding any type of page to the dashboard. Can
create landing pages, analysis pages, about pages, or any combination of
text and visualizations. All content is markdown-compatible.

## Usage

``` r
add_dashboard_page(
  proj,
  name,
  data = NULL,
  data_path = NULL,
  template = NULL,
  params = list(),
  visualizations = NULL,
  content = NULL,
  text = NULL,
  icon = NULL,
  is_landing_page = FALSE,
  tabset_theme = NULL,
  tabset_colors = NULL,
  navbar_align = c("left", "right"),
  overlay = FALSE,
  overlay_theme = c("light", "glass", "dark", "accent"),
  overlay_text = "Loading",
  overlay_duration = 2200,
  lazy_load_charts = NULL,
  lazy_load_margin = NULL,
  lazy_load_tabs = NULL,
  lazy_debug = NULL,
  pagination_separator = NULL
)
```

## Arguments

- proj:

  A dashboard_project object

- name:

  Page display name

- data:

  Optional data frame to save for this page. Can also be a named list of
  data frames for using multiple datasets:
  `list(survey = df1, demographics = df2)`

- data_path:

  Path to existing data file (alternative to data parameter). Can also
  be a named list of file paths for multiple datasets

- template:

  Optional custom template file path

- params:

  Parameters for template substitution

- visualizations:

  Content collection or list of visualization specs

- content:

  Alternative to visualizations - supports content collections

- text:

  Optional markdown text content for the page

- icon:

  Optional iconify icon shortcode (e.g., "ph:users-three")

- is_landing_page:

  Whether this should be the landing page (default: FALSE)

- tabset_theme:

  Optional tabset theme for this page (overrides dashboard-level theme)

- tabset_colors:

  Optional tabset colors for this page (overrides dashboard-level
  colors)

- navbar_align:

  Position of page in navbar: "left" (default) or "right"

- overlay:

  Whether to show a loading overlay on page load (default: FALSE)

- overlay_theme:

  Theme for loading overlay: "light", "glass", "dark", or "accent"
  (default: "light")

- overlay_text:

  Text to display in loading overlay (default: "Loading")

- overlay_duration:

  Duration in milliseconds for how long overlay stays visible (default:
  2200)

- lazy_load_charts:

  Override dashboard-level lazy loading setting for this page (default:
  NULL = inherit from dashboard)

- lazy_load_margin:

  Override viewport margin for lazy loading on this page (default: NULL
  = inherit from dashboard)

- lazy_load_tabs:

  Override tab-aware lazy loading for this page (default: NULL = inherit
  from dashboard)

- lazy_debug:

  Override debug mode for lazy loading on this page (default: NULL =
  inherit from dashboard)

- pagination_separator:

  Text to show in pagination navigation (e.g., "of" → "1 of 3"),
  default: NULL = inherit from dashboard

## Value

The updated dashboard_project object

The updated dashboard_project object

## Examples
