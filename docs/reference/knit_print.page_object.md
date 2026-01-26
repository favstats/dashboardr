# Knitr print method for page objects

Automatically renders page objects as interactive content in knitr
documents. Converts the page to a content collection and renders it.

## Usage

``` r
# S3 method for class 'page_object'
knit_print(x, ..., options = NULL)
```

## Arguments

- x:

  A page_object

- ...:

  Additional arguments

- options:

  Knitr chunk options

## Value

A knitr asis_output object containing the rendered HTML
