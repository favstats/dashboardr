# Create a navbar dropdown menu

Creates a dropdown menu in the navbar without requiring sidebar groups.
This is a simple nested menu structure.

## Usage

``` r
navbar_menu(text, pages, icon = NULL, align = c("left", "right"))
```

## Arguments

- text:

  Display text for the dropdown menu button

- pages:

  Character vector of page names to include in the dropdown

- icon:

  Optional icon for the menu button

- align:

  Where to place the menu in the navbar: "left" (default) or "right"

## Value

List containing navbar menu configuration

## Examples

``` r
if (FALSE) { # \dontrun{
# Create a simple dropdown menu (left-aligned by default)
dimensions_menu <- navbar_menu(
  text = "Dimensions",
  pages = c("Strategic Information", "Critical Information"),
  icon = "ph:book"
)

# Create a right-aligned menu
more_info_menu <- navbar_menu(
  text = "More Info",
  pages = c("About", "Wave 1"),
  icon = "ph:info",
  align = "right"
)

dashboard <- create_dashboard(
  navbar_sections = list(dimensions_menu, more_info_menu)
)
} # }
```
