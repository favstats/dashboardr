# Process template file with variable substitution

Internal function that reads a template file and substitutes template
variables with provided parameter values.

## Usage

``` r
.process_template(template_path, params, output_dir)
```

## Arguments

- template_path:

  Path to the template file

- params:

  Named list of parameters for substitution

- output_dir:

  Output directory (not used but kept for compatibility)

## Value

Character vector of processed template lines, or NULL if template not
found
