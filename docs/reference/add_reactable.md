# Add reactable table

Add reactable table

## Usage

``` r
add_reactable(content, reactable_object)
```

## Arguments

- content:

  A content_collection object

- reactable_object:

  A reactable object (from reactable::reactable()) OR a data frame (will
  be auto-converted)

## Value

Updated content_collection

## Examples

``` r
if (FALSE) { # \dontrun{
# Option 1: Pass a styled reactable object
my_table <- reactable::reactable(
  mtcars,
  columns = list(mpg = reactable::colDef(name = "MPG")),
  searchable = TRUE,
  striped = TRUE
)

content <- create_content() %>%
  add_reactable(my_table)
  
# Option 2: Pass a data frame (auto-converted with defaults)
content <- create_content() %>%
  add_reactable(mtcars)
} # }
```
