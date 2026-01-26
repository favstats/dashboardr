# Knitr print method for dashboard projects

Automatically renders dashboard projects as a preview in knitr
documents. Shows a combined view of all pages or the landing page.

## Usage

``` r
# S3 method for class 'dashboard_project'
knit_print(x, ..., options = NULL)
```

## Arguments

- x:

  A dashboard_project

- ...:

  Additional arguments

- options:

  Knitr chunk options

## Value

A knitr asis_output object containing the rendered HTML
