# Generate unique R chunk label for a visualization

Internal function that creates a unique, descriptive R chunk label based
on the visualization specification. Uses tabgroup, variable names,
title, or type to create meaningful labels.

## Usage

``` r
.generate_chunk_label(spec, spec_name = NULL)
```

## Arguments

- spec:

  Visualization specification object

- spec_name:

  Optional name for the specification

## Value

Character string with sanitized chunk label
