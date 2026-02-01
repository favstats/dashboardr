# Create pagination navigation controls for a dashboard page

Creates navigation controls for multi-page dashboards with Previous/Next
buttons and page indicator. Use this in your QMD file to add clean
pagination without embedding HTML directly.

## Usage

``` r
create_pagination_nav(page_num, total_pages, base_name, position = "top")
```

## Arguments

- page_num:

  Current page number

- total_pages:

  Total number of pages

- base_name:

  Base filename (e.g., "knowledge" for knowledge.qmd, knowledge_p2.qmd,
  etc.)

- position:

  Position of navigation: "top", "bottom", or "both" (default: "top")

## Value

An htmltools tag object containing the pagination HTML and JavaScript

## Examples

``` r
if (FALSE) { # \dontrun{
# In a Quarto document R chunk with results='asis':
dashboardr::create_pagination_nav(1, 3, "knowledge", "top")

# For both top and bottom:
dashboardr::create_pagination_nav(1, 3, "knowledge", "both")
} # }
```
