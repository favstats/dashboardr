# Print Visualization Collection

Displays a formatted summary of a visualization collection, including
hierarchical tabgroup structure, visualization types, titles, filters,
and defaults.

## Usage

``` r
# S3 method for class 'viz_collection'
print(x, render = FALSE, check = FALSE, ...)
```

## Arguments

- x:

  A viz_collection object created by
  [`create_viz`](https://favstats.github.io/dashboardr/reference/create_viz.md).

- render:

  If TRUE and data is attached, opens a preview in the viewer instead of
  showing the structure. Default is FALSE.

- check:

  Logical. If TRUE, validates all visualization specs before printing.
  Useful for catching errors early before attempting to render.

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

Use `print(x, render = TRUE)` to open a preview in the viewer instead of
showing the structure. This is useful for quick visualization in the
console.

Use `print(x, check = TRUE)` to validate all visualization specs before
printing. This catches missing required parameters and invalid column
names early, providing clearer error messages than Quarto rendering
errors.
