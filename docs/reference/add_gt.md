# Add gt table

Add gt table

## Usage

``` r
add_gt(content, gt_object, caption = NULL, tabgroup = NULL, show_when = NULL)
```

## Arguments

- content:

  A content_collection object

- gt_object:

  A gt table object (from gt::gt()) OR a data frame (will be
  auto-converted)

- caption:

  Optional caption

- tabgroup:

  Optional tabgroup for organizing content (character vector for nested
  tabs)

- show_when:

  One-sided formula controlling conditional display based on input
  values.

## Value

Updated content_collection

## Examples

``` r
if (FALSE) { # \dontrun{
# Option 1: Pass a styled gt object
my_table <- gt::gt(mtcars) %>%
  gt::tab_header(title = "Cars") %>%
  gt::fmt_number(columns = everything(), decimals = 1)

content <- create_content() %>%
  add_gt(my_table)
  
# Option 2: Pass a data frame (auto-converted)
content <- create_content() %>%
  add_gt(mtcars, caption = "Motor Trend Cars")
} # }
```
