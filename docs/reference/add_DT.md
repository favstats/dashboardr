# Add DT datatable

Add DT datatable

## Usage

``` r
add_DT(
  content,
  table_data,
  options = NULL,
  tabgroup = NULL,
  filter_vars = NULL,
  show_when = NULL,
  ...
)
```

## Arguments

- content:

  A content_collection object

- table_data:

  A DT datatable object (from DT::datatable()) OR a data frame/matrix
  (will be auto-converted)

- options:

  List of DT options (only used if passing a data frame)

- tabgroup:

  Optional tabgroup for organizing content (character vector for nested
  tabs)

- filter_vars:

  Optional character vector of input filter variables to apply to this
  block.

- show_when:

  One-sided formula controlling conditional display based on input
  values.

- ...:

  Additional arguments passed to DT::datatable() (only used if passing a
  data frame)

## Value

Updated content_collection

## Examples

``` r
if (FALSE) { # \dontrun{
# Option 1: Pass a styled DT object
my_dt <- DT::datatable(
  mtcars,
  options = list(pageLength = 10),
  filter = 'top',
  rownames = FALSE
)

content <- create_content() %>%
  add_DT(my_dt)
  
# Option 2: Pass a data frame with options
content <- create_content() %>%
  add_DT(mtcars, options = list(pageLength = 5, scrollX = TRUE))
} # }
```
