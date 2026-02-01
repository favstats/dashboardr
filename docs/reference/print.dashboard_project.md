# Create iconify icon shortcode

Helper function to generate iconify icon shortcodes for use in pages and
visualizations.

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

- icon_name:

  Icon name in format "collection:name" (e.g., "ph:users-three")

## Value

Iconify shortcode string

Invisibly returns the input object `x`.

## Details

The print method displays:

- Project metadata (title, author, description)

- Output directory

- Enabled features (sidebar, search, themes, Shiny, Observable)

- Integrations (GitHub, Twitter, LinkedIn, Analytics)

- Page structure with properties:

  - Landing page indicator

  - Loading overlay indicator

  - Right-aligned navbar indicator

  - Associated datasets

  - Nested visualization hierarchies

## Examples
