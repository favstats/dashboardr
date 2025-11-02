# Print Dashboard Project

Displays a comprehensive summary of a dashboard project, including
metadata, features, pages, visualizations, and integrations.

## Usage

``` r
# S3 method for class 'dashboard_project'
print(x, ...)
```

## Arguments

- x:

  A dashboard_project object created by
  [`create_dashboard`](https://favstats.github.io/dashboardr/reference/create_dashboard.md).

- ...:

  Additional arguments (currently ignored).

## Value

Invisibly returns the input object `x`.

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
