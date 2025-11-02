# Add Multiple Visualizations at Once

Convenience function to add multiple visualizations in a loop by
expanding vector parameters. Automatically detects which parameters
should be expanded to create multiple visualizations. This is useful
when creating many similar visualizations that differ only in one or two
parameters.

Convenience function to add multiple visualizations in a loop by
expanding vector parameters. Automatically detects which parameters
should be expanded to create multiple visualizations. This is useful
when creating many similar visualizations that differ only in one or two
parameters.

## Usage

``` r
add_vizzes(
  viz_collection,
  ...,
  .tabgroup_template = NULL,
  .title_template = NULL
)
```

## Arguments

- viz_collection:

  A viz_collection object from create_viz()

- ...:

  Visualization parameters. Parameters with multiple values will be
  expanded to create multiple visualizations. Common parameters with
  single values will be applied to all visualizations.

- .tabgroup_template:

  Optional. Template string for tabgroup with `{i}` placeholder for the
  iteration index (e.g., `"skills/age/item{i}"`). You can also use
  parameter names in the template (e.g., `"skills/{response_var}"`). If
  NULL, tabgroup must be provided as a vector of the same length as
  expandable parameters.

- .title_template:

  Optional. Template string for title with `{i}` placeholder.

## Value

The updated viz_collection object with multiple visualizations added

The updated viz_collection object with multiple visualizations added

## Details

The function identifies "expandable" parameters (response_var, x_var,
y_var, stack_var, questions) and creates one visualization per value.
Other parameters are applied to all visualizations. All expandable
vector parameters must have the same length.

Templates use glue syntax:

- `{i}` is replaced with the iteration number (1, 2, 3, ...)

- `{param_name}` is replaced with the current value of that parameter

The function identifies "expandable" parameters (response_var, x_var,
y_var, stack_var, questions) and creates one visualization per value.
Other parameters are applied to all visualizations. All expandable
vector parameters must have the same length.

Templates use glue syntax:

- `{i}` is replaced with the iteration number (1, 2, 3, ...)

- `{param_name}` is replaced with the current value of that parameter

## Examples
