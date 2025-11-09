# Generate a tutorial dashboard.

This function creates and renders a detailed tutorial dashboard
showcasing various features of the dashboardr package. It includes
examples of stacked bar charts, heatmaps, multiple pages, and custom
components.

## Usage

``` r
tutorial_dashboard(directory = "tutorial_dashboard", open = "browser")
```

## Arguments

- directory:

  Character string. Directory where the dashboard files will be created.
  Defaults to "tutorial_dashboard". Quarto will render HTML to
  directory/docs/.

- open:

  Logical or character. Whether to open the dashboard after rendering.
  Use TRUE or "browser" to open in browser (default), FALSE to not open.
  Default is "browser".

## Value

Invisibly returns the dashboard_project object.

## Details

The dashboard uses data from the General Social Survey (GSS) to
demonstrate visualization and layout options.

## Examples

``` r
if (FALSE) { # \dontrun{
# Run the tutorial dashboard (requires Quarto CLI and 'gssr' package)
tutorial_dashboard()

# Specify custom directory
tutorial_dashboard(directory = "my_tutorial")

# Don't open browser
tutorial_dashboard(open = FALSE)
} # }
```
