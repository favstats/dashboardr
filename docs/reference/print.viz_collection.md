# Print Visualization Collection

Displays a formatted summary of a visualization collection, including
hierarchical tabgroup structure, visualization types, titles, filters,
and defaults.

## Usage

``` r
# S3 method for class 'viz_collection'
print(x, ...)
```

## Arguments

- x:

  A viz_collection object created by
  [`create_viz`](https://favstats.github.io/dashboardr/reference/create_viz.md).

- ...:

  Additional arguments (currently ignored).

## Value

Invisibly returns the input object `x`.

## Details

The print method displays:

- Total number of visualizations

- Default parameters (if set)

- Hierarchical tree structure showing tabgroup organization

- Visualization types with emoji indicators

- Filter status for each visualization
