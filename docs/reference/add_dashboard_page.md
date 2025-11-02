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
  text = NULL,
  icon = NULL,
  is_landing_page = FALSE,
  tabset_theme = NULL,
  tabset_colors = NULL,
  navbar_align = c("left", "right"),
  overlay = FALSE,
  overlay_theme = c("light", "glass", "dark", "accent"),
  overlay_text = "Loading"
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

  viz_collection or list of visualization specs

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

## Value

The updated dashboard_project object

## Examples

``` r
if (FALSE) { # \dontrun{
# Landing page
dashboard <- create_dashboard("test") %>%
  add_page("Welcome", text = "# Welcome\n\nThis is the main page.", is_landing_page = TRUE)

# Analysis page with data and visualizations
dashboard <- dashboard %>%
  add_page("Demographics", data = survey_data, visualizations = demo_viz)

# Text-only about page
dashboard <- dashboard %>%
  add_page("About", text = "# About This Study\n\nThis dashboard shows...")

# Mixed content page
dashboard <- dashboard %>%
  add_page("Results", text = "# Key Findings\n\nHere are the results:",
           visualizations = results_viz, icon = "ph:chart-line")
} # }
```
