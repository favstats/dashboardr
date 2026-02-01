# Validate visualization specifications in a collection

Checks all visualization specs in a collection for common errors before
rendering. This includes verifying required parameters are present and
that specified column names exist in the data.

## Usage

``` r
validate_specs(collection, verbose = TRUE, data = NULL)
```

## Arguments

- collection:

  A content_collection, viz_collection, page_object, or
  dashboard_project

- verbose:

  Logical. If TRUE (default), prints validation results to console. If
  FALSE, returns silently with results as attributes.

- data:

  Optional data frame to validate column names against. If NULL, uses
  data attached to the collection.

## Value

Invisibly returns TRUE if all specs are valid, FALSE otherwise. When
FALSE, the return value has an "issues" attribute containing details
about validation errors.

## Details

This function is called automatically by
[`preview()`](https://favstats.github.io/dashboardr/reference/preview.md)
before rendering. You can also call it manually to check your
visualizations before attempting to render, which provides clearer error
messages than Quarto rendering errors.

Validation checks include:

- Required parameters for each visualization type (e.g., x_var for bar
  charts)

- Column existence in the data (when data is available)

- Suggestions for typos in column names

## Examples

``` r
if (FALSE) { # \dontrun{
# Create a collection with an error (missing required params)
# stackedbar requires either (x_var + stack_var) OR x_vars
viz <- create_viz(data = mtcars) %>%
  add_viz(type = "stackedbar", x_var = "cyl")  # Missing stack_var or x_vars

# Validate before previewing - will show helpful error
validate_specs(viz)

# Use in print with check parameter
print(viz, check = TRUE)

# Programmatic validation (silent)
result <- validate_specs(viz, verbose = FALSE)
if (!result) {
  print(attr(result, "issues"))
}
} # }
```
