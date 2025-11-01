# Process visualizations into organized specs with tab groups

Unified internal function that handles both viz_collection and plain
list inputs, organizing visualizations into standalone items and tab
groups based on their tabgroup parameter.

## Usage

``` r
.process_visualizations(viz_input, data_path, tabgroup_labels = NULL)
```

## Arguments

- viz_input:

  Either a viz_collection object or a plain list of visualization specs

- data_path:

  Path to the data file for this page (will be attached to each viz)

- tabgroup_labels:

  Optional named list/vector of custom display labels for tab groups

## Value

List of processed visualization specs, with standalone visualizations
first, followed by tab group objects

## Details

This function handles both viz_collection objects and plain lists of
visualization specifications. It:

- Attaches data_path to each visualization

- Groups visualizations by their tabgroup parameter

- Converts single-item groups to standalone visualizations with group
  titles

- Creates tab group objects for multi-item groups

- Applies custom tab group labels if provided
