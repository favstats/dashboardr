# Generate global setup chunk for QMD files

Creates a comprehensive setup chunk that includes libraries, data
loading, and global settings to avoid repetition in individual
visualizations.

## Usage

``` r
.generate_global_setup_chunk(page)
```

## Arguments

- page:

  Page object containing data_path and visualizations

## Value

Character vector of setup chunk lines
