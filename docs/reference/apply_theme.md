# Apply Theme to Dashboard

Applies a theme to an existing dashboard_project object or returns theme
parameters for use in
[`create_dashboard()`](https://favstats.github.io/dashboardr/reference/create_dashboard.md).
Supports piping for easy theme application. You can override any theme
parameter by passing it as an additional argument.

## Usage

``` r
apply_theme(proj = NULL, theme, ...)
```

## Arguments

- proj:

  Optional. A dashboard_project object to apply the theme to. If NULL,
  returns the theme parameters as a list.

- theme:

  A theme list (e.g., from
  [`theme_ascor()`](https://favstats.github.io/dashboardr/reference/theme_ascor.md),
  [`theme_academic()`](https://favstats.github.io/dashboardr/reference/theme_academic.md),
  etc.)

- ...:

  Additional parameters to override theme defaults. Can include any of:
  `navbar_bg_color`, `navbar_text_color`, `navbar_text_hover_color`,
  `mainfont`, `fontsize`, `fontcolor`, `linkcolor`, `monofont`,
  `monobackgroundcolor`, `linestretch`, `backgroundcolor`, `max_width`,
  `margin_left`, `margin_right`, `margin_top`, `margin_bottom`

## Value

If proj is provided, returns the modified dashboard_project object. If
proj is NULL, returns the theme list.

## Examples

``` r
if (FALSE) { # \dontrun{
# Method 1: Pipe theme directly into dashboard (EASIEST!)
dashboard <- create_dashboard("my_dashboard", "My Research") %>%
  apply_theme(theme_ascor()) %>%
  add_page("Home", text = "# Welcome", is_landing_page = TRUE)

# Method 2: Override specific theme parameters
dashboard <- create_dashboard("tech_dash", "Tech Dashboard") %>%
  apply_theme(theme_modern("purple"), mainfont = "Roboto", fontsize = "18px") %>%
  add_page("Data", visualizations = my_viz)

# Method 3: Get theme parameters only
ascor_params <- apply_theme(theme = theme_ascor())

# Method 4: Customize multiple parameters
dashboard <- create_dashboard("custom", "Custom Dashboard") %>%
  apply_theme(
    theme_clean(),
    mainfont = "Inter",
    fontsize = "18px",
    linkcolor = "#8B0000",
    max_width = "1400px"
  )
} # }
```
