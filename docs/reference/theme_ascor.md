# Apply ASCoR/UvA Theme to Dashboard

Returns a list of styling parameters that apply University of Amsterdam
and ASCoR (Amsterdam School of Communication Research) branding to a
dashboard. Can be used with
[`apply_theme()`](https://favstats.github.io/dashboardr/reference/apply_theme.md)
for piping or unpacked into
[`create_dashboard()`](https://favstats.github.io/dashboardr/reference/create_dashboard.md).
All parameters can be overridden to customize the theme.

## Usage

``` r
theme_ascor(navbar_style = "dark", ...)
```

## Arguments

- navbar_style:

  Style of the navbar. Options: "dark" (default), "light". Dark style
  works best with UvA red.

- ...:

  Additional theme parameters to override defaults. Can include any
  styling parameter like `navbar_bg_color`, `navbar_text_color`,
  `navbar_text_hover_color`, `mainfont`, `fontsize`, etc.

## Value

A named list of theme parameters that can be unpacked into
[`create_dashboard()`](https://favstats.github.io/dashboardr/reference/create_dashboard.md)

## Details

The ASCoR theme includes:

- UvA red (#CB0D0D) as primary brand color

- Professional Fira Sans font for body text

- Fira Code for code blocks

- Optimal readability settings

- Clean, academic styling

## Examples

``` r
if (FALSE) { # \dontrun{
# Method 1: Use default ASCoR theme
dashboard <- create_dashboard("my_dashboard", "My Research Dashboard") %>%
  apply_theme(theme_ascor()) %>%
  add_page("Home", text = "# Welcome", is_landing_page = TRUE)

# Method 2: Override specific parameters
dashboard <- create_dashboard("custom", "Custom ASCoR Dashboard") %>%
  apply_theme(theme_ascor(
    fontsize = "18px",
    max_width = "1400px",
    mainfont = "Inter"
  ))
} # }
```
