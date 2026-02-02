# Extract filter_var values from content collection

Internal helper to detect filter_var columns from add_input() calls.
Used to enable automatic cross-tab filtering.

## Usage

``` r
.extract_filter_vars(content)
```

## Arguments

- content:

  A content_collection or list with sidebar/items

## Value

Character vector of unique filter_var values
