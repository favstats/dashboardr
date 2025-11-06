# Generate pagination navigation controls

Creates theme-aware navigation controls for multi-page dashboards.
Includes Previous/Next buttons and page indicator.

## Usage

``` r
.generate_pagination_nav(
  page_num,
  total_pages,
  base_name,
  theme = NULL,
  separator_text = "of"
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

  Quarto theme name (for styling)

- separator_text:

  Text to show between page number and total (default: "of")

## Value

Character vector of HTML/CSS lines
