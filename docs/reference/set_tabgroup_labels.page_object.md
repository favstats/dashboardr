# Set tabgroup labels for a page

Customize tab labels with icons or different text.

## Usage

``` r
set_tabgroup_labels.page_object(page, ...)
```

## Arguments

- page:

  A page_object

- ...:

  Named arguments where names are tabgroup IDs and values are display
  labels

## Value

The updated page_object

## Examples

``` r
if (FALSE) { # \dontrun{
create_page("Analysis", data = gss, type = "bar") %>%
  add_viz(x_var = "degree", tabgroup = "demographics") %>%
  add_viz(x_var = "happy", tabgroup = "wellbeing") %>%
  set_tabgroup_labels(
    demographics = "{{< iconify ph:users-fill >}} Demographics",
    wellbeing = "{{< iconify ph:heart-fill >}} Wellbeing"
  )
} # }
```
