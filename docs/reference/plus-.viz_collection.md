# Combine Visualization Collections with + Operator

S3 method that allows combining two viz_collection objects using the `+`
operator. This is a convenient shorthand for
[`combine_viz`](https://favstats.github.io/dashboardr/reference/combine_viz.md).

## Usage

``` r
# S3 method for class 'viz_collection'
e1 + e2
```

## Arguments

- e1:

  First viz_collection object (left operand).

- e2:

  Second viz_collection object (right operand).

## Value

A new viz_collection containing all visualizations from both
collections, with merged tabgroup labels and renumbered insertion
indices.

## Details

The `+` operator provides an intuitive way to combine visualization
collections:

- All visualizations from both collections are merged

- Tabgroup labels are combined (e2 labels take precedence for
  duplicates)

- Insertion indices are renumbered to maintain proper ordering

## See also

[`combine_viz`](https://favstats.github.io/dashboardr/reference/combine_viz.md)
for the underlying function.

## Examples

``` r
if (FALSE) { # \dontrun{
# Create two separate visualization collections
viz1 <- create_viz() %>%
  add_viz(type = "histogram", x_var = "age", title = "Age Distribution")

viz2 <- create_viz() %>%
  add_viz(type = "histogram", x_var = "income", title = "Income Distribution")

# Combine using + operator
combined <- viz1 + viz2

# Equivalent to:
combined <- combine_viz(viz1, viz2)
} # }
```
