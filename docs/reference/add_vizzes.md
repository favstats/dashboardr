# Add Multiple Visualizations at Once

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

## Details

The function identifies "expandable" parameters (response_var, x_var,
y_var, stack_var, questions) and creates one visualization per value.
Other parameters are applied to all visualizations. All expandable
vector parameters must have the same length.

Templates use glue syntax:

- `{i}` is replaced with the iteration number (1, 2, 3, ...)

- `{param_name}` is replaced with the current value of that parameter

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic expansion - create 3 timeline visualizations
viz <- create_viz(type = "timeline", time_var = "wave", chart_type = "line") |>
  add_vizzes(
    response_var = c("SInfo1", "SInfo2", "SInfo3"),
    group_var = "AgeGroup",  # Same for all
    .tabgroup_template = "skills/age/item{i}"
  )

# Parallel expansion - titles match the variables
viz <- create_viz(type = "stackedbar") |>
  add_vizzes(
    x_var = c("Age", "Gender", "Education"),
    title = c("By Age", "By Gender", "By Education"),
    .tabgroup_template = "demographics/demo{i}"
  )

# Use variable names in template
viz <- create_viz(type = "timeline") |>
  add_vizzes(
    response_var = c("SInfo1", "SInfo2", "SInfo3"),
    .tabgroup_template = "skills/{response_var}"
  )

# Helper function pattern
add_all_questions <- function(viz, vars, group_var, tbgrp, demographic, wave) {
  wave_path <- tolower(gsub(" ", "", wave))
  viz |> add_vizzes(
    response_var = vars,
    group_var = group_var,
    .tabgroup_template = glue::glue("{tbgrp}/{wave_path}/{demographic}/item{{i}}")
  )
}

viz <- create_viz(type = "timeline", time_var = "wave") |>
  add_all_questions(
    vars = c("var1", "var2", "var3"),
    group_var = "AgeGroup",
    tbgrp = "skills",
    demographic = "age",
    wave = "Over Time"
  )
} # }
```
