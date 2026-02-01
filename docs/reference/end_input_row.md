# End an input row

Closes an input row and returns to the parent content collection. Must
be called after add_input_row() and all add_input() calls.

## Usage

``` r
end_input_row(row_container)
```

## Arguments

- row_container:

  Input row container object

## Value

The parent content_collection for further piping

## Examples

``` r
if (FALSE) { # \dontrun{
content <- create_content() %>%
  add_input_row() %>%
    add_input(input_id = "filter1", filter_var = "var1", options = c("A", "B")) %>%
    add_input(input_id = "filter2", filter_var = "var2", options = c("X", "Y")) %>%
  end_input_row() %>%
  add_text("Content after the input row...")
} # }
```
