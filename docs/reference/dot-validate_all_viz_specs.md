# Validate all visualization specs in a collection

Internal function that validates all viz specs in a content/viz
collection. Collects all validation issues and reports them together.

## Usage

``` r
.validate_all_viz_specs(collection, data = NULL, stop_on_error = TRUE)
```

## Arguments

- collection:

  A content_collection or viz_collection object

- data:

  Optional data frame to validate column names against

- stop_on_error:

  If TRUE, stops on first error. If FALSE, collects all issues.

## Value

If stop_on_error=FALSE, returns a list with `valid` (logical), `issues`
(list of issues by item). If stop_on_error=TRUE and invalid, throws an
error.
