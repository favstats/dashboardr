# Embed cross-tab data for client-side filtering

Internal helper that extracts cross-tab attributes from a visualization
and embeds them as JavaScript for client-side filtering. Used by
generated QMD code when interactive inputs are present.

## Usage

``` r
.embed_cross_tab(result)
```

## Arguments

- result:

  A visualization result (highchart object)

## Value

The result wrapped with cross-tab JavaScript if applicable
