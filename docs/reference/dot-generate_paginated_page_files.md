# Generate multiple QMD files for a paginated page

Internal function that splits a paginated page into multiple QMD files
and writes them with appropriate navigation controls.

## Usage

``` r
.generate_paginated_page_files(
  page,
  page_name,
  base_page_file,
  output_dir,
  theme
)
```

## Arguments

- page:

  Page object

- page_name:

  Name of the page

- base_page_file:

  Path to the main page file (e.g., "analysis.qmd")

- output_dir:

  Output directory

- theme:

  Quarto theme name

## Value

Invisible NULL
