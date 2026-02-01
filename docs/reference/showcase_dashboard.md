# Generate a showcase dashboard demonstrating all dashboardr features.

This function creates and renders a comprehensive showcase dashboard
that demonstrates the full breadth of the dashboardr package. It
includes multiple visualization types, tabset grouping, standalone
charts, and various page layouts.

## Usage

``` r
showcase_dashboard(directory = "showcase_dashboard", open = "browser")
```

## Arguments

- directory:

  Character string. Directory where the dashboard files will be created.
  Defaults to "showcase_dashboard". Quarto will render HTML to
  directory/docs/.

- open:

  Logical or character. Whether to open the dashboard after rendering.
  Use TRUE or "browser" to open in browser (default), FALSE to not open.
  Default is "browser".

## Value

Invisibly returns the dashboard_project object.

## Details

The showcase dashboard uses General Social Survey (GSS) data to
demonstrate:

- Multiple tabset groups (Demographics, Politics, Social Issues)

- Stacked bar charts with custom styling

- Heatmaps with custom color palettes

- Standalone charts without tabsets

- Text-only pages with card layouts

- Mixed content pages (text + visualizations)

- Custom icons throughout

- All advanced dashboard features

This dashboard is more comprehensive than the tutorial dashboard and
showcases the full power of dashboardr for creating complex, multi-page
dashboards.

## Examples

``` r
if (FALSE) { # \dontrun{
# Run the showcase dashboard (requires Quarto CLI and 'gssr' package)
showcase_dashboard()

# Specify custom directory
showcase_dashboard(directory = "my_showcase")

# Don't open browser
showcase_dashboard(open = FALSE)
} # }
```
