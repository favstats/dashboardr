# Create a page object

Creates a standalone page object that can be populated with content and
later added to a dashboard. Pages can have visualizations added directly
(without creating separate content objects), making this the simplest
way to build dashboards.

## Usage

``` r
create_page(
  name,
  data = NULL,
  data_path = NULL,
  type = NULL,
  color_palette = NULL,
  icon = NULL,
  is_landing_page = FALSE,
  navbar_align = c("left", "right"),
  tabset_theme = NULL,
  tabset_colors = NULL,
  overlay = FALSE,
  overlay_theme = c("light", "glass", "dark", "accent"),
  overlay_text = "Loading",
  overlay_duration = 2200,
  lazy_load_charts = NULL,
  lazy_load_margin = NULL,
  lazy_load_tabs = NULL,
  lazy_debug = NULL,
  pagination_separator = NULL,
  time_var = NULL,
  weight_var = NULL,
  filter = NULL,
  drop_na_vars = NULL,
  shared_first_level = TRUE,
  ...
)
```

## Arguments

- name:

  Page display name (required)

- data:

  Data frame for this page. All visualizations on this page will
  automatically use this data (no need to specify data separately).

- data_path:

  Path to existing data file (alternative to data parameter)

- type:

  Default visualization type for add_viz() calls (e.g., "bar",
  "histogram", "stackedbar")

- color_palette:

  Default color palette for all visualizations on this page

- icon:

  Optional iconify icon shortcode (e.g., "ph:users-three",
  "ph:chart-line")

- is_landing_page:

  Whether this should be the landing page (default: FALSE)

- navbar_align:

  Position of page in navbar: "left" (default) or "right"

- tabset_theme:

  Optional tabset theme for this page

- tabset_colors:

  Optional tabset colors for this page

- overlay:

  Whether to show a loading overlay on page load (default: FALSE)

- overlay_theme:

  Theme for loading overlay: "light", "glass", "dark", or "accent"

- overlay_text:

  Text to display in loading overlay (default: "Loading")

- overlay_duration:

  Duration in milliseconds for overlay (default: 2200)

- lazy_load_charts:

  Override dashboard-level lazy loading for this page

- lazy_load_margin:

  Override viewport margin for lazy loading

- lazy_load_tabs:

  Override tab-aware lazy loading for this page

- lazy_debug:

  Override debug mode for lazy loading

- pagination_separator:

  Text for pagination navigation (e.g., "of" -\> "1 of 3")

- time_var:

  Name of the time/x-axis column for input filters

- weight_var:

  Name of weight variable for weighted visualizations (applies to all
  viz)

- filter:

  Filter expression for subsetting data (e.g., ~ year \>= 2020)

- drop_na_vars:

  Default for dropping NA values in visualizations

- shared_first_level:

  Logical. When TRUE (default), multiple first-level tabgroups will
  share a single tabset. When FALSE, each first-level tabgroup is
  rendered as a separate section (stacked vertically).

- ...:

  Additional default parameters passed to all add_viz() calls

## Value

A page_object that can be modified with add_viz(), add_text(), etc.

## Examples

``` r
if (FALSE) { # \dontrun{
# SIMPLE: Add visualizations directly to the page!
# No need to create separate content objects
analysis <- create_page("Analysis", data = gss, type = "bar") %>%
  add_viz(x_var = "degree", title = "Education") %>%
  add_viz(x_var = "race", title = "Race") %>%
  add_viz(x_var = "happy", title = "Happiness", type = "stackedbar", stack_var = "sex")

# LANDING PAGE: Just add text
home <- create_page("Home", icon = "ph:house-fill", is_landing_page = TRUE) %>%
  add_text("# Welcome!", "", "Explore our data dashboard.") %>%
  add_callout("Data updated weekly", type = "tip")

# MIXED: Combine direct viz with pre-built content
trends <- create_page("Trends", data = gss) %>%
  add_viz(x_var = "year", y_var = "happy", type = "timeline") %>%
  add_content(detailed_analysis)  # Add pre-built content too

# PREVIEW: See what the page looks like before adding to dashboard
analysis %>% preview()

# BUILD DASHBOARD
create_dashboard(title = "My Dashboard") %>%
  add_pages(home, analysis, trends) %>%
  generate_dashboard()
} # }
```
