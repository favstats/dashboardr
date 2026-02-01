# Combine content collections using + operator

Allows combining content and visualization collections using the `+`
operator. This provides a clean, intuitive syntax for building dashboard
content.

S3 method for combining content_collection objects using `+`. Preserves
all attributes including lazy loading settings.

## Usage

``` r
# S3 method for class 'content_collection'
e1 + e2

# S3 method for class 'content_collection'
e1 + e2
```

## Arguments

- e1:

  First content_collection

- e2:

  Second content_collection

## Value

A merged content_collection containing items from both

Combined content_collection

## Examples

``` r
if (FALSE) { # \dontrun{
# Combine content and visualizations
combined <- content + viz

# Or the other way around
combined <- viz + content

# Chain multiple combinations
combined <- text_content + charts + more_content
} # }
```
