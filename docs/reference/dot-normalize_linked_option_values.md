# Normalize linked option values for a parent value

Validates and coerces child option values for a given parent value in a
linked input configuration.

## Usage

``` r
.normalize_linked_option_values(values, parent_value)
```

## Arguments

- values:

  Character vector of child options for one parent value.

- parent_value:

  The parent value these options belong to.

## Value

Character vector of cleaned, unique child option values.
