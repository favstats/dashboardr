# Create a new content/visualization collection (alias for create_viz)

This is an alias for
[`create_viz`](https://favstats.github.io/dashboardr/reference/create_viz.md) -
both functions are identical. Use whichever name makes more sense for
your use case. The returned collection can be built up with any
combination of add_viz(), add_text(), and add_image().

## Usage

``` r
create_content(tabgroup_labels = NULL, ...)
```

## Arguments

- tabgroup_labels:

  Named vector/list mapping tabgroup IDs to display names

- ...:

  Default parameters to apply to all subsequent add_viz() calls

## Value

A content_collection (also a viz_collection for compatibility)

## Details

Note: Both names return the same object with both "content_collection"
and "viz_collection" classes for backward compatibility.

## Examples

``` r
if (FALSE) { # \dontrun{
# These are equivalent:
content <- create_content() %>%
  add_text("# Title") %>%
  add_viz(type = "histogram", x_var = "age")

content <- create_viz() %>%
  add_text("# Title") %>%
  add_viz(type = "histogram", x_var = "age")
} # }
```
