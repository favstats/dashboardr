# Find Quarto binary path

Searches PATH, the quarto R package, and the RStudio-bundled location.
If found outside PATH, adds the directory to PATH so child processes
(e.g. system2 calls) can also find it.

## Usage

``` r
.find_quarto_path()
```

## Value

Path to quarto binary, or "" if not found
