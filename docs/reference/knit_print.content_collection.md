# Knitr print method for content collections

Automatically renders content collections as interactive visualizations
when output in knitr documents (vignettes, pkgdown articles, R
Markdown). If no data is attached to the collection, shows the structure
instead.

## Usage

``` r
# S3 method for class 'content_collection'
knit_print(x, ...)
```

## Arguments

- x:

  A content_collection or viz_collection object

- ...:

  Additional arguments (currently ignored)

## Value

A knitr asis_output object containing the rendered HTML

## Details

This method enables "show the viz" behavior in documents while
preserving the structure print for console debugging. Simply output a
collection with inline data to see the rendered visualization:

    create_viz(data = mtcars) 
      add_viz(type = "histogram", x_var = "mpg")
    # Renders as interactive chart in documents!
