# Add "Powered by dashboardr" branding to footer

Adds a subtle, sleek "Powered by dashboardr" badge with logo to the
bottom-right of the page footer. Integrates seamlessly with existing
footer content.

## Usage

``` r
add_powered_by_dashboardr(dashboard, size = "small", style = "default")
```

## Arguments

- dashboard:

  A dashboard project created with `create_dashboard`

- size:

  Size of the branding: "small" (default), "medium", or "large"

- style:

  Style variant: "default", "minimal", or "badge"

## Value

Updated dashboard project with dashboardr branding in footer

## Examples

``` r
if (FALSE) { # \dontrun{
dashboard <- create_dashboard("my_dash", "My Dashboard") %>%
  add_page(name = "Home", text = "Welcome!") %>%
  add_powered_by_dashboardr()

# With custom size
dashboard <- create_dashboard("my_dash") %>%
  add_powered_by_dashboardr(size = "medium", style = "badge")
} # }
```
