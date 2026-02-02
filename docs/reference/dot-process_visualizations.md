# This function handles both viz_collection objects and plain lists of visualization specifications. It:

- Attaches data_path to each visualization

- Groups visualizations by their tabgroup parameter (supports nested
  hierarchies)

- Converts single-item groups to standalone visualizations with group
  titles

- Creates tab group objects for multi-item groups

- Applies custom tab group labels if provided

- Attaches cross_tab_filter_vars for client-side filtering when inputs
  are present

This function handles both viz_collection objects and plain lists of
visualization specifications. It:

- Attaches data_path to each visualization

- Groups visualizations by their tabgroup parameter (supports nested
  hierarchies)

- Converts single-item groups to standalone visualizations with group
  titles

- Creates tab group objects for multi-item groups

- Applies custom tab group labels if provided

- Attaches cross_tab_filter_vars for client-side filtering when inputs
  are present

## Usage

``` r
.process_visualizations(
  viz_input,
  data_path,
  tabgroup_labels = NULL,
  shared_first_level = TRUE,
  filter_vars = NULL
)
```

## Arguments

- filter_vars:

  Character vector of filter_var values from add_input() calls
  (optional)
