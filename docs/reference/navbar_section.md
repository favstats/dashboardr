# Create a navbar section for hybrid navigation

Helper function to create a navbar section that links to a sidebar group
for hybrid navigation. This creates dropdown-style navigation.

## Usage

``` r
navbar_section(text, sidebar_id, icon = NULL)
```

## Arguments

- text:

  Display text for the navbar item

- sidebar_id:

  ID of the sidebar group to link to

- icon:

  Optional icon for the navbar item

## Value

List containing navbar section configuration

## Examples

``` r
if (FALSE) { # \dontrun{
# Create navbar sections that link to sidebar groups
analysis_section <- navbar_section("Analysis", "analysis", "ph:chart-bar")
reference_section <- navbar_section("Reference", "reference", "ph:book")
} # }
```
