# Validate a single visualization specification

Internal function that validates a visualization spec against its
requirements. Checks for missing required parameters and optionally
validates column existence.

## Usage

``` r
.validate_viz_spec(spec, data = NULL, item_index = NULL, stop_on_error = TRUE)
```

## Arguments

- spec:

  List containing the visualization specification

- data:

  Optional data frame to validate column names against

- item_index:

  Optional index of the item in the collection (for error messages)

- stop_on_error:

  If TRUE, stops with an error. If FALSE, returns list of issues.

## Value

If stop_on_error=FALSE, returns a list with `valid` (logical) and
`issues` (character vector). If stop_on_error=TRUE and invalid, throws
an error with helpful message.
