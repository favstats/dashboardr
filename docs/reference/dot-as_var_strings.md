# Convert multiple variable arguments to strings (for x_vars vector)

Internal helper for parameters that accept vectors of variable names.
Supports `x_vars = c("var1", "var2")` and `x_vars = c(var1, var2)`.

## Usage

``` r
.as_var_strings(vars)
```

## Arguments

- vars:

  A quosure captured with
  [`rlang::enquo()`](https://rlang.r-lib.org/reference/enquo.html)

## Value

Character vector of variable names, or NULL if input was NULL
