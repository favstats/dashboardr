# Add pagination break to visualization collection

Insert a pagination marker that splits the visualization collection into
separate HTML pages. Each section will be rendered as its own page file
(e.g., analysis.html, analysis_p2.html, analysis_p3.html) with automatic
Previous/Next navigation between them.

## Usage

``` r
add_pagination(viz_collection, position = NULL)

add_pagination.page_object(viz_collection, position = NULL)
```

## Arguments

- viz_collection:

  A viz_collection object

- position:

  Position for pagination controls: "bottom" (sticky at bottom), "top"
  (inline with page title), "both" (top and bottom), or NULL (default -
  uses dashboard-level setting from create_dashboard). Per-page override
  of the dashboard default.

## Value

Updated viz_collection object

## Details

This provides TRUE performance benefits - each page loads independently,
dramatically reducing initial render time and file size for large
dashboards.

## Examples

``` r
if (FALSE) { # \dontrun{
# Split 150 charts into 3 pages of 50 each
vizzes <- create_viz()

# Page 1: Charts 1-50
for (i in 1:50) vizzes <- vizzes %>% add_viz(type = "bar", x_var = "cyl")

vizzes <- vizzes %>% add_pagination()  # Split here

# Page 2: Charts 51-100
for (i in 51:100) vizzes <- vizzes %>% add_viz(type = "bar", x_var = "gear")

vizzes <- vizzes %>% add_pagination()  # Split here

# Page 3: Charts 101-150
for (i in 101:150) vizzes <- vizzes %>% add_viz(type = "bar", x_var = "hp")

# Use in dashboard
dashboard %>%
  add_page("Analysis", visualizations = vizzes)
} # }
```
