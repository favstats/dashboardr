# Generate pagination navigation controls (internal function for dashboard creation)

Creates theme-aware navigation controls for multi-page dashboards. Now
generates clean R code chunks instead of raw HTML.

## Usage

``` r
.generate_pagination_nav(
  page_num,
  total_pages,
  base_name,
  theme = NULL,
  position = "bottom",
  separator_text = "/"
)
```

## Arguments

- page_num:

  Current page number

- total_pages:

  Total number of pages

- base_name:

  Base filename (e.g., "analysis" for analysis.qmd)

- theme:

  Quarto theme name (for styling, currently unused but kept for
  compatibility)

- position:

  Position of navigation: "top", "bottom" (default: "bottom")

- separator_text:

  Text to show between page number and total (default: "/", kept for
  backward compatibility)

## Value

Character vector of R code chunk lines
