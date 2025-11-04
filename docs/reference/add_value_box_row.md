# Start a value box row

Creates a container for value boxes that will be displayed in a
horizontal row. The boxes will wrap responsively on smaller screens. Use
pipeable syntax with end_value_box_row():

## Usage

``` r
add_value_box_row(content)
```

## Arguments

- content:

  Content collection object

## Examples

``` r
if (FALSE) { # \dontrun{
content <- create_content() %>%
  add_value_box_row() %>%
    add_value_box(title = "Users", value = "1,234", bg_color = "#2E86AB") %>%
    add_value_box(title = "Revenue", value = "€56K", bg_color = "#F18F01") %>%
    add_value_box(title = "Growth", value = "+23%", bg_color = "#A23B72") %>%
  end_value_box_row()
} # }
```
