# Generate R code for typed visualizations

Internal function that generates R code for specific visualization types
(stackedbar, heatmap, histogram, timeline) by mapping type names to
function names and serializing parameters.

## Usage

``` r
.generate_typed_viz(spec)
```

## Arguments

- spec:

  Visualization specification list containing type and parameters

## Value

Character vector of R code lines for the visualization

## Details

This function:

- Maps visualization types to function names (e.g., "stackedbar" →
  "create_stackedbar")

- Excludes internal parameters (type, data_path, tabgroup, text, icon,
  text_position)

- Serializes all other parameters using .serialize_arg()

- Formats the function call with proper indentation
