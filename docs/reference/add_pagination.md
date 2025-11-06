# Create a sidebar group for hybrid navigation

Helper function to create a sidebar group configuration for use with
hybrid navigation. Each group can have its own styling and contains a
list of pages.

## Usage

``` r
add_pagination(viz_collection)
```

## Arguments

- viz_collection:

  A viz_collection object

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

Updated viz_collection object

## Examples
