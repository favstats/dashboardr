# Enable Input Filter Functionality

Adds input filter CSS and JavaScript to enable interactive filtering of
Highcharts visualizations via multi-select dropdowns. Uses Choices.js
for a polished multi-select experience.

## Usage

``` r
enable_inputs(linked = FALSE, show_when = FALSE, url_params = FALSE)
```

## Arguments

- linked:

  If TRUE, also include script for linked (cascading) parent-child
  select inputs. Set automatically when the page uses
  [`add_linked_inputs()`](https://favstats.github.io/dashboardr/reference/add_linked_inputs.md).

- show_when:

  If TRUE, also include script for conditional viz visibility
  (`show_when` in
  [`add_viz()`](https://favstats.github.io/dashboardr/reference/add_viz.md)).
  Set automatically when the page uses it.

- url_params:

  If TRUE, also include script for URL parameter support.

## Value

HTML tags to include input filter functionality

## Examples

``` r
if (FALSE) { # \dontrun{
# In your dashboard page content:
enable_inputs()
enable_inputs(linked = TRUE)  # when using add_linked_inputs()
enable_inputs(show_when = TRUE)  # when using show_when in add_viz()
} # }
```
