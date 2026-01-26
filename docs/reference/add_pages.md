# Add multiple pages to a dashboard

Adds one or more page objects to a dashboard.

## Usage

``` r
add_pages(proj, ...)
```

## Arguments

- proj:

  A dashboard_project object

- ...:

  One or more page_objects to add

## Value

The updated dashboard_project object

## Examples

``` r
if (FALSE) { # \dontrun{
home <- create_page("Home", is_landing_page = TRUE) %>%
  add_text("# Welcome!")

analysis <- create_page("Analysis", data = gss, type = "bar") %>%
  add_viz(x_var = "degree", title = "Education") %>%
  add_viz(x_var = "race", title = "Race")

create_dashboard(title = "My Dashboard") %>%
  add_pages(home, analysis) %>%
  generate_dashboard()
} # }
```
