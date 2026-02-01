# Apply a Modern Tech Theme to Dashboard

Returns a sleek, modern theme suitable for tech companies and data
science teams. Features bold colors and contemporary typography. All
parameters can be overridden.

## Usage

``` r
theme_modern(style = c("blue", "purple", "green", "orange", "white"), ...)
```

## Arguments

- style:

  Style variant. Options: "blue" (default), "purple", "green", "orange",
  "white"

- ...:

  Additional theme parameters to override defaults. Can include any
  styling parameter like `navbar_bg_color`, `navbar_text_color`,
  `navbar_text_hover_color`, `mainfont`, `fontsize`, etc.

## Value

A named list of theme parameters

## Examples

``` r
if (FALSE) { # \dontrun{
# Use default modern blue theme
dashboard <- create_dashboard("tech_dashboard", "Data Science Dashboard") %>%
  apply_theme(theme_modern()) %>%
  add_page("Analytics", visualizations = my_viz)

# Purple variant with custom font
dashboard <- create_dashboard("purple_dashboard", "Analytics Dashboard") %>%
  apply_theme(theme_modern(style = "purple", mainfont = "Inter", fontsize = "18px")) %>%
  add_page("Data", data = my_data)

# White navbar
dashboard <- create_dashboard("clean_dashboard", "Clean Dashboard") %>%
  apply_theme(theme_modern(style = "white")) %>%
  add_page("Home", text = "# Welcome")
} # }
```
