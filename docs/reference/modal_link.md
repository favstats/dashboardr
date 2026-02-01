# Create Modal Link

Creates a hyperlink that opens content in a modal dialog instead of
navigating to a new page. You can also use regular markdown syntax:
`[Link Text](#modal-id)` and it will automatically open as a modal.

## Usage

``` r
modal_link(text, modal_id, class = NULL)
```

## Arguments

- text:

  Link text to display

- modal_id:

  ID of the modal content div

- class:

  Additional CSS classes for the link

## Value

HTML link element

## Examples

``` r
if (FALSE) { # \dontrun{
modal_link("View Details", "details-modal")
modal_link("See Chart", "chart1", class = "btn btn-primary")

# Or in markdown:
# [View Details](#details-modal)
} # }
```
