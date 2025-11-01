# Convert R objects to proper R code strings for generating .qmd files

Internal function that converts R objects into properly formatted R code
strings for inclusion in generated Quarto markdown files. Handles
various data types and preserves special cases like data references.

## Usage

``` r
.serialize_arg(arg, arg_name = NULL)
```

## Arguments

- arg:

  The R object to serialize

- arg_name:

  Optional name of the argument (for debugging)

## Value

Character string containing properly formatted R code

## Details

This function handles:

- NULL values → "NULL"

- Character strings → quoted strings with escaped quotes

- Numeric values → unquoted numbers

- Logical values → "TRUE"/"FALSE"

- Named lists → "list(name1 = value1, name2 = value2)"

- Unnamed lists → "list(value1, value2)"

- Special identifiers like "data" → unquoted

- Complex objects → deparsed representation
