# Add a reset button to reset filters

Creates a button that resets specified inputs to their default values.
Can be used inside a sidebar pipeline (pass a sidebar_container as the
first argument) or standalone to generate the raw HTML.

## Usage

``` r
add_reset_button(
  sidebar_container = NULL,
  targets = NULL,
  label = "Reset Filters",
  size = "md"
)
```

## Arguments

- sidebar_container:

  A sidebar_container (created by add_sidebar()), or NULL for standalone
  HTML output.

- targets:

  Character vector of input IDs to reset, or NULL for all

- label:

  Button label

- size:

  Size variant: "sm", "md", or "lg"

## Value

Modified sidebar_container when piped, or HTML string when standalone.
