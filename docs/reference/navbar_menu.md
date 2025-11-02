# Create a navbar dropdown menu

Creates a dropdown menu in the navbar without requiring sidebar groups.
This is a simple nested menu structure.

## Usage

``` r
navbar_menu(text, pages, icon = NULL)
```

## Arguments

- text:

  Display text for the dropdown menu button

- pages:

  Character vector of page names to include in the dropdown

- icon:

  Optional icon for the menu button

## Value

List containing navbar menu configuration

## Examples

``` r
if (FALSE) { # \dontrun{
# Create a simple dropdown menu
dimensions_menu <- navbar_menu(
  text = "Dimensions",
  pages = c("Strategic Information", "Critical Information"),
  icon = "ph:book"
)

dashboard <- create_dashboard(
  navbar_sections = list(dimensions_menu)
)
} # }
```
