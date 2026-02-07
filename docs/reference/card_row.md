# Display cards in a Bootstrap row

Helper function to display multiple cards in a responsive Bootstrap row
layout.

## Usage

``` r
card_row(..., cols = 2, class = NULL)
```

## Arguments

- ...:

  Card objects to display

- cols:

  Number of columns per row (default: 2)

- class:

  Additional CSS classes for the row

## Value

HTML div element with Bootstrap row classes containing the cards

## Examples

``` r
if (FALSE) { # \dontrun{
# Display two cards in a row
card_row(card1, card2)

# Display three cards in a row (3 columns)
card_row(card1, card2, card3, cols = 3)
} # }
```
