# Normalize a filter_var value to a character vector

Internal helper to coerce various filter_var representations (character,
factor, symbol, language) to a character vector.

## Usage

``` r
.normalize_filter_var_value(x)
```

## Arguments

- x:

  A filter_var value (character, factor, symbol, or language object)

## Value

Character vector of unique filter_var values
