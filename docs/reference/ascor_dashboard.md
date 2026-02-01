# Generate an ASCoR-themed dashboard for the University of Amsterdam

This function creates and renders a professional dashboard with ASCoR
(Amsterdam School of Communication Research) and University of Amsterdam
branding. The dashboard showcases the dashboardr package with UvA
colors, styling, and branding.

## Usage

``` r
ascor_dashboard(directory = "ascor_dashboard")
```

## Arguments

- directory:

  Character string. Directory where the dashboard files will be created.
  Defaults to "ascor_dashboard". Quarto will render HTML to
  directory/docs/.

## Value

Invisibly returns the dashboard_project object.

## Details

The ASCoR dashboard features:

- UvA red (#CB0D0D) as primary branding color

- Professional typography with Inter font

- ASCoR logo in the navbar (if logo file is provided)

- Clean, academic styling appropriate for research communication

- Example visualizations using General Social Survey data

## Examples

``` r
if (FALSE) { # \dontrun{
# Run the ASCoR dashboard (requires Quarto CLI and 'gssr' package)
ascor_dashboard()

# Specify custom directory
ascor_dashboard(directory = "my_ascor_dashboard")
} # }
```
