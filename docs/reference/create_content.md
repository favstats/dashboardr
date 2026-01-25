# Create a new content/visualization collection (alias for create_viz)

This is an alias for
[`create_viz`](https://favstats.github.io/dashboardr/reference/create_viz.md) -
both functions are identical. Use whichever name makes more sense for
your use case. The returned collection can be built up with any
combination of add_viz(), add_text(), and add_image().

## Usage

``` r
create_content(data = NULL, tabgroup_labels = NULL, ...)
```

## Arguments

- data:

  Optional data frame to use for all visualizations in this collection.
  This data will be used by add_viz() calls and can be used with
  preview().

- tabgroup_labels:

  Named vector/list mapping tabgroup IDs to display names

- ...:

  Default parameters to apply to all subsequent add_viz() calls. Common
  defaults include: type, color_palette, stacked_type, horizontal, etc.
  Any parameter that can be passed to add_viz() can be set as a default
  here.

## Value

A content_collection (also a viz_collection for compatibility)

## Details

Note: Both names return the same object with both "content_collection"
and "viz_collection" classes for backward compatibility.

## Examples

``` r
if (FALSE) { # \dontrun{
# Create content with inline data for preview
content <- create_content(data = mtcars) %>%
  add_text("# MPG Analysis") %>%
  add_viz(type = "histogram", x_var = "mpg") %>%
  preview()

# Set shared defaults like type - all add_viz() calls inherit these
content <- create_content(
  data = survey_df,
  type = "stackedbar",
  stacked_type = "percent",
  horizontal = TRUE
) %>%
  add_viz(x_var = "age", stack_var = "response", tabgroup = "Age") %>%
  add_viz(x_var = "gender", stack_var = "response", tabgroup = "Gender")

# These are equivalent:
content <- create_content() %>%
  add_text("# Title") %>%
  add_viz(type = "histogram", x_var = "age")

content <- create_viz() %>%
  add_text("# Title") %>%
  add_viz(type = "histogram", x_var = "age")
} # }
```
