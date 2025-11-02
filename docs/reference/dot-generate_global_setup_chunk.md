# Collect unique filters from all visualizations

Collect unique filters from all visualizations

## Usage

``` r
.generate_global_setup_chunk(page)
```

## Arguments

- page:

  Page object containing data_path and visualizations

- visualizations:

  List of visualization specifications

## Value

List of unique filter formulas with generated names, including source
dataset Generate global setup chunk for QMD files

Creates a comprehensive setup chunk that includes libraries, data
loading, filtered datasets, and global settings to avoid repetition in
individual visualizations.

Character vector of setup chunk lines
