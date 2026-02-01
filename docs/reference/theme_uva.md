# Apply UvA Theme to Dashboard (Alias)

Alias for
[`theme_ascor()`](https://favstats.github.io/dashboardr/reference/theme_ascor.md).
Returns University of Amsterdam branding parameters.

## Usage

``` r
theme_uva(navbar_style = "dark")
```

## Arguments

- navbar_style:

  Style of the navbar. Options: "dark" (default), "light". Dark style
  works best with UvA red.

## Value

A named list of theme parameters

## Examples

``` r
if (FALSE) { # \dontrun{
# Pipe UvA theme into dashboard
dashboard <- create_dashboard("uva_dashboard", "UvA Research Dashboard") %>%
  apply_theme(theme_uva()) %>%
  add_page("Home", text = "# Welcome")
} # }
```
