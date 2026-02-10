# Normalize backend aliases

Accepts legacy/backend aliases and returns canonical backend names.

## Usage

``` r
.normalize_backend(backend, warn_alias = FALSE)
```

## Arguments

- backend:

  Character backend value.

- warn_alias:

  Logical. If TRUE, emits a warning when an alias is used.
