# End a value box row

Closes a value box row and returns to the parent content collection.
Must be called after add_value_box_row() and all add_value_box() calls.

## Usage

``` r
end_value_box_row(row_container)
```

## Arguments

- row_container:

  Value box row container object

## Examples

``` r
if (FALSE) { # \dontrun{
content <- create_content() %>%
  add_value_box_row() %>%
    add_value_box(title = "Users", value = "1,234") %>%
    add_value_box(title = "Revenue", value = "€56K") %>%
  end_value_box_row() %>%
  add_text("More content after the row...")
} # }
```
