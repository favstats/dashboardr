# Handle NA Values in Survey Data

Handle NA Values in Survey Data

## Usage

``` r
handle_na_for_plotting(
  data,
  var_name,
  include_na = FALSE,
  na_label = "(Missing)",
  custom_order = NULL
)
```

## Arguments

- data:

  Data frame

- var_name:

  String. Column name to process

- include_na:

  Logical. Treat NAs as explicit category?

- na_label:

  String. Label for NA values

- custom_order:

  Optional character vector for ordering

## Value

Factor vector with processed values
