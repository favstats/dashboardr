# Add content collection(s) to a page

Add one or more pre-built content collections (from
create_viz/create_content) to a page. Use this when you have complex
content built separately.

## Usage

``` r
add_content(page, ...)
```

## Arguments

- page:

  A page_object created by create_page()

- ...:

  One or more content collections (from create_viz/create_content)

## Value

The updated page_object

## Examples

``` r
if (FALSE) { # \dontrun{
# Add a single collection
page %>% add_content(my_viz)

# Add multiple collections at once
page %>% add_content(viz1, viz2, viz3)
} # }
```
