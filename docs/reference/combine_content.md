# Combine content collections (universal combiner)

Universal function to combine content_collection or viz_collection
objects. Preserves all content types (visualizations, pagination
markers, text blocks) and collection-level attributes (lazy loading,
etc.).

## Usage

``` r
combine_content(...)
```

## Arguments

- ...:

  One or more content_collection or viz_collection objects

## Value

Combined content_collection

## Examples

``` r
if (FALSE) { # \dontrun{
# Combine multiple collections
all_viz <- demo_viz %>%
  combine_content(analysis_viz) %>%
  combine_content(summary_viz)

# With pagination
paginated <- section1_viz %>%
  combine_content(section2_viz) %>%
  add_pagination() %>%
  combine_content(section3_viz)

# Using + operator
combined <- viz1 + viz2 + viz3
} # }
```
