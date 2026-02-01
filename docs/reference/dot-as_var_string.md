# Convert a variable argument to a string (supports both quoted and unquoted syntax)

Internal helper that enables tidy evaluation for variable parameters.
Accepts both `x_var = "degree"` (quoted) and `x_var = degree`
(unquoted).

## Usage

``` r
.as_var_string(var)
```

## Arguments

- var:

  A quosure captured with
  [`rlang::enquo()`](https://rlang.r-lib.org/reference/enquo.html)

## Value

Character string of the variable name, or NULL if the input was NULL

## Examples

``` r
if (FALSE) { # \dontrun{
# Inside a function:
my_func <- function(x_var) {
  x_var <- .as_var_string(rlang::enquo(x_var))
  # x_var is now always a character string
}

my_func("degree")  # returns "degree"
my_func(degree)    # returns "degree"
} # }
```
