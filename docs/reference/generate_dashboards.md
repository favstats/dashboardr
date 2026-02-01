# Process visualizations into organized specs with tab groups

Unified internal function that handles both viz_collection and plain
list inputs, organizing visualizations into standalone items and tab
groups based on their tabgroup parameter.

## Usage

``` r
generate_dashboards(
  dashboards,
  render = TRUE,
  open = FALSE,
  continue_on_error = TRUE,
  show_progress = TRUE,
  quiet = FALSE,
  linked = FALSE
)
```

## Arguments

- dashboards:

  Named list of dashboard_project objects created with
  create_dashboard(). When `linked = TRUE`, the first dashboard is the
  main/parent and others are sub-dashboards that will be output into
  subdirectories of the main's docs folder.

- render:

  Whether to render each dashboard to HTML (default TRUE)

- open:

  Whether to open the main dashboard after generation (default FALSE)

- continue_on_error:

  Continue generating remaining dashboards if one fails (default TRUE)

- show_progress:

  Whether to show progress for each dashboard (default TRUE)

- quiet:

  Whether to suppress output (default FALSE)

- linked:

  Whether dashboards are linked (default FALSE). When TRUE:

  - First dashboard is treated as the main/parent dashboard

  - Other dashboards are output to subdirectories of main's docs folder

  - Use list names as subdirectory names (e.g., list(main = ..., US =
    ..., DE = ...))

  - Click navigation like `click_url_template = "\{iso2c\}/index.html"`
    will work

- viz_input:

  Either a viz_collection object or a plain list of visualization specs

- data_path:

  Path to the data file for this page (will be attached to each viz)

- tabgroup_labels:

  Optional named list/vector of custom display labels for tab groups

## Value

List of processed visualization specs, with standalone visualizations
first, followed by tab group objects

Invisibly returns a list of results, one per dashboard, containing:

- `success`: logical, whether generation succeeded

- `title`: dashboard title

- `output_dir`: output directory path

- `error`: error message if failed (only present on failure)

- `duration`: generation time in seconds

## Details

Build a hierarchy key from a tabgroup vector Generate multiple
dashboards

Generates a list of dashboard projects in batch, with progress tracking
and error handling. Useful for generating many related dashboards (e.g.,
one per country, per topic, etc.) in a single workflow.

## Examples

``` r
if (FALSE) { # \dontrun{
# Linked dashboards with map navigation
main_db <- create_dashboard("Main", output_dir = "project") %>%
  add_page("Map", data = summary_data, 
           visualizations = create_viz() %>% 
             add_viz(type = "map", click_url_template = "{iso2c}/index.html"))

us_db <- create_dashboard("US Details", output_dir = "project/US") %>%
  add_page("Analysis", data = us_data)

de_db <- create_dashboard("DE Details", output_dir = "project/DE") %>%
  add_page("Analysis", data = de_data)

# Generate with linked = TRUE - outputs go to project/docs/, project/docs/US/, etc.
generate_dashboards(
  list(main = main_db, US = us_db, DE = de_db),
  linked = TRUE
)
} # }
```
