# Open a conditional-visibility wrapper

Emits an opening `<div>` with the `data-show-when` attribute so that
`show_when.js` can show/hide the enclosed content based on input state.

## Usage

``` r
show_when_open(condition_json)
```

## Arguments

- condition_json:

  A JSON string describing the condition (e.g.
  `'{"var":"time_period","op":"in","val":["Wave 1","Wave 2"]}'`).

## Value

Called for its side-effect ([`cat()`](https://rdrr.io/r/base/cat.html)).

## Details

This is used in generated `.qmd` chunks – users typically do not need to
call it directly.
