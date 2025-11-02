# Generate a tutorial dashboard.

This function creates and renders a detailed tutorial dashboard
showcasing various features of the dashboardr package. It includes
examples of stacked bar charts, heatmaps, multiple pages, and custom
components.

## Usage

``` r
tutorial_dashboard(directory = "tutorial_dashboard")
```

## Arguments

- directory:

  Character string. Directory where the dashboard files will be created.
  Defaults to "tutorial_dashboard". Quarto will render HTML to
  directory/docs/.

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
} # }
```
