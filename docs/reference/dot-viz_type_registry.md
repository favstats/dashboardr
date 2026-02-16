# Viz type registry

Returns the canonical mapping from viz type names to their function
names, including aliases (e.g., "donut" -\> "viz_pie").

## Usage

``` r
.viz_type_registry()
```

## Value

Named list where each element has `fn` (function name string).
