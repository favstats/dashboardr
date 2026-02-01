# Apply a Clean Theme to Dashboard

Returns an ultra-clean, minimalist theme with maximum focus on content.
Perfect for portfolios, reports, and clean presentations. All parameters
can be overridden to customize the theme.

## Usage

``` r
theme_clean(...)
```

## Arguments

- ...:

  Additional theme parameters to override defaults. Can include any
  styling parameter like `navbar_bg_color`, `navbar_text_color`,
  `navbar_text_hover_color`, `mainfont`, `fontsize`, etc.

## Value

A named list of theme parameters

## Examples

``` r
if (FALSE) { # \dontrun{
# Use default clean theme
dashboard <- create_dashboard("clean_dashboard", "Clean Report") %>%
  apply_theme(theme_clean()) %>%
  add_page("Report", text = "# Executive Summary")

# Customize with wider layout and different font
dashboard <- create_dashboard("custom_clean", "Custom Report") %>%
  apply_theme(theme_clean(
    mainfont = "Inter",
    max_width = "1200px",
    fontsize = "18px"
  ))
} # }
```
