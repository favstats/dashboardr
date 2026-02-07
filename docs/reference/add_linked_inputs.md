# Add linked parent-child inputs (cascading dropdowns)

Creates two linked select inputs where the child's available options
depend on the parent's current selection. Use inside a sidebar (after
[`add_sidebar()`](https://favstats.github.io/dashboardr/reference/add_sidebar.md)).

## Usage

``` r
add_linked_inputs(x, parent, child, type = "select")
```

## Arguments

- x:

  A sidebar_container (from
  [`add_sidebar()`](https://favstats.github.io/dashboardr/reference/add_sidebar.md)).

- parent:

  List with: `id`, `label`, `options`; optionally `default_selected`,
  `filter_var`.

- child:

  List with: `id`, `label`, `options_by_parent` (named list mapping each
  parent value to a character vector of child options); optionally
  `filter_var`.

- type:

  Input type for parent: `"select"` (default) or `"radio"`.

## Value

The modified sidebar_container for piping.

## Examples

``` r
if (FALSE) { # \dontrun{
add_sidebar() %>%
  add_linked_inputs(
    parent = list(id = "dimension", label = "Dimension",
                  options = c("AI", "Safety", "Digital Health")),
    child = list(id = "question", label = "Question",
                 options_by_parent = list(
                   "AI" = c("Overall", "Using AI Tools"),
                   "Safety" = c("Overall", "Passwords", "Phishing"),
                   "Digital Health" = c("Overall", "Screen Time")
                 ))
  ) %>%
  end_sidebar()
} # }
```
