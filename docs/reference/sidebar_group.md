# Create a sidebar group for hybrid navigation

Helper function to create a sidebar group configuration for use with
hybrid navigation. Each group can have its own styling and contains a
list of pages.

## Usage

``` r
sidebar_group(
  id,
  title,
  pages,
  style = NULL,
  background = NULL,
  foreground = NULL,
  border = NULL,
  alignment = NULL,
  collapse_level = NULL,
  pinned = NULL,
  tools = NULL
)
```

## Arguments

- id:

  Unique identifier for the sidebar group

- title:

  Display title for the sidebar group

- pages:

  Character vector of page names to include in this group

- style:

  Sidebar style (docked, floating, etc.) (optional)

- background:

  Background color (optional)

- foreground:

  Foreground color (optional)

- border:

  Show border (optional)

- alignment:

  Alignment (left, right) (optional)

- collapse_level:

  Collapse level for navigation (optional)

- pinned:

  Whether sidebar is pinned (optional)

- tools:

  List of tools to add to sidebar (optional)

## Value

List containing sidebar group configuration

## Examples

``` r
if (FALSE) { # \dontrun{
# Create a sidebar group for analysis pages
analysis_group <- sidebar_group(
  id = "analysis",
  title = "Data Analysis",
  pages = c("overview", "demographics", "findings"),
  style = "docked",
  background = "light"
)
} # }
```
