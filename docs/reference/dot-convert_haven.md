# Convert haven_labelled columns to factors

Internal helper that converts haven_labelled columns to factors for
filtering. Used in generated QMD files when data might contain
haven-style labels.

## Usage

``` r
.convert_haven(df)
```

## Arguments

- df:

  A data frame

## Value

The data frame with haven_labelled columns converted to factors
