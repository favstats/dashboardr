# Apply a Professional Academic Theme to Dashboard

Returns a clean, professional theme suitable for academic and research
dashboards. Uses neutral colors and excellent typography for maximum
readability. All parameters can be overridden to customize the theme.

## Usage

``` r
theme_academic(accent_color = "#2563eb", navbar_style = "dark", ...)
```

## Arguments

- accent_color:

  Primary accent color (hex code). Default: "#2563eb" (blue)

- navbar_style:

  Style of the navbar. Options: "dark" (default), "light"

- ...:

  Additional theme parameters to override defaults. Can include any
  styling parameter like `navbar_bg_color`, `navbar_text_color`,
  `navbar_text_hover_color`, `mainfont`, `fontsize`, etc.

## Value

A named list of theme parameters that can be unpacked into
[`create_dashboard()`](https://favstats.github.io/dashboardr/reference/create_dashboard.md)

## Details

The academic theme provides:

- Clean, neutral color scheme

- Professional typography (Fira Sans + Source Code Pro)

- High readability settings

- Suitable for any academic institution

## Examples

``` r
if (FALSE) { # \dontrun{
# Use default academic theme
dashboard <- create_dashboard("academic_dashboard", "Research Dashboard") %>%
  apply_theme(theme_academic()) %>%
  add_page("Home", text = "# Welcome")

# Custom accent color and font
dashboard <- create_dashboard("my_university", "University Research") %>%
  apply_theme(theme_academic(
    accent_color = "#8B0000",
    mainfont = "Roboto",
    fontsize = "17px"
  ))
} # }
```
