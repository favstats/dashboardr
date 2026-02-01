# Print Dashboard Project

Displays a comprehensive summary of a dashboard project, including
metadata, features, pages, visualizations, and integrations.

## Usage

``` r
.show_dashboard_summary(
  proj,
  output_dir,
  elapsed_time = NULL,
  build_info = NULL,
  show_progress = TRUE
)
```

## Arguments

- proj:

  A dashboard_project object

- output_dir:

  Path to the output directory

- x:

  A dashboard_project object created by
  [`create_dashboard`](https://favstats.github.io/dashboardr/reference/create_dashboard.md).

- ...:

  Additional arguments (currently ignored).

## Value

Invisibly returns the input object `x`.

Invisible NULL

## Details

The print method displays:

- Project metadata (title, author, description)

- Output directory

- Enabled features (sidebar, search, themes, Shiny, Observable)

- Integrations (GitHub, Twitter, LinkedIn, Analytics)

- Page structure with properties:

  - 🏠 Landing page indicator

  - ⏳ Loading overlay indicator

  - → Right-aligned navbar indicator

  - 💾 Associated datasets

  - Nested visualization hierarchies

Show beautiful dashboard summary

Internal function that displays a comprehensive summary of the generated
dashboard files and provides helpful guidance to users.
